# backend/adapters/air/openaq_grid_provider.py
import os
import requests
from datetime import datetime, timezone
from django.core.cache import cache
import logging

logger = logging.getLogger(__name__)

OPENAQ_API_BASE = "https://api.openaq.org/v3"

def _cell_id(lat, lon, res=0.005):  # ~500 m
    # redondeo simple para agrupar consultas cercanas
    from math import floor
    latq = round(lat / res) * res
    lonq = round(lon / res) * res
    return f"{latq:.3f}:{lonq:.3f}"

def _aqi_from_pm25(pm25: float) -> int:
    if pm25 <= 12.0:   return int((50/12.0)*pm25)
    if pm25 <= 35.4:   return int(50 + (pm25-12.1)*50/(35.4-12.1))
    if pm25 <= 55.4:   return int(100 + (pm25-35.5)*50/(55.4-35.5))
    if pm25 <= 150.4:  return int(150 + (pm25-55.5)*50/(150.4-55.5))
    if pm25 <= 250.4:  return int(200 + (pm25-150.5)*100/(250.4-150.5))
    return 301

def _aqi_from_pollutants(values: dict) -> int:
    subs = []
    pm25 = values.get("pm25")
    if pm25 is not None:
        subs.append(_aqi_from_pm25(pm25))
    return max(subs) if subs else 0

class OpenAQGridProvider:
    """Devuelve AQI aproximado en un punto/hora usando OpenAQ (MVP con caché)."""
    def __init__(self, radius_m=25000, ttl=300):
        self.radius_m = radius_m
        self.ttl = ttl

    def get_aqi_cell(self, lat: float, lon: float, when: datetime):
        when = (when or datetime.now(timezone.utc)).astimezone(timezone.utc)
        when = when.replace(minute=0, second=0, microsecond=0)
        key = f"grid:{_cell_id(lat, lon)}:{when.isoformat()}"
        cached = cache.get(key)
        if cached:
            logger.info(f"Cache hit for {key}")
            return cached

        headers = {
            "X-API-Key": os.environ.get("OPENAQ_API_KEY", "")
        }
        
        try:
            # Paso 1: Buscar ubicaciones cercanas
            locations_url = f"{OPENAQ_API_BASE}/locations"
            params = {
                "coordinates": f"{lat},{lon}",
                "radius": self.radius_m,
                "limit": 10,
            }
            
            logger.info(f"Requesting locations: {locations_url} with params: {params}")
            r = requests.get(locations_url, params=params, headers=headers, timeout=10)
            logger.info(f"Locations Response Status: {r.status_code}")
            r.raise_for_status()
            
            locations_data = r.json()
            logger.info(f"Locations Response: {locations_data}")
            
            results = locations_data.get("results", [])
            logger.info(f"Found {len(results)} locations")
            
            if not results:
                logger.warning("No locations found near coordinates")
                values = {}
            else:
                # Obtener la primera ubicación
                location = results[0]
                location_id = location["id"]
                location_name = location.get("name", "Unknown")
                distance = location.get("distance", "N/A")
                
                logger.info(f"Using location: {location_name} (ID: {location_id}), Distance: {distance}m")
                
                # Crear mapeo de sensor_id -> parameter_name
                sensor_map = {}
                for sensor in location.get("sensors", []):
                    sensor_id = sensor.get("id")
                    param_name = sensor.get("parameter", {}).get("name")
                    if sensor_id and param_name:
                        sensor_map[sensor_id] = param_name
                
                logger.info(f"Sensor mapping: {sensor_map}")
                
                # Paso 2: Obtener mediciones actuales
                latest_url = f"{OPENAQ_API_BASE}/locations/{location_id}/latest"
                logger.info(f"Requesting latest measurements: {latest_url}")
                
                r2 = requests.get(latest_url, headers=headers, timeout=10)
                logger.info(f"Latest measurements Response Status: {r2.status_code}")
                r2.raise_for_status()
                
                latest_data = r2.json()
                logger.info(f"Latest measurements Response: {latest_data}")
                
                # Extraer mediciones usando el mapeo de sensores
                measurements = latest_data.get("results", [])
                logger.info(f"Found {len(measurements)} measurements")
                
                values = {}
                for measurement in measurements:
                    sensor_id = measurement.get("sensorsId")
                    value = measurement.get("value")
                    param_name = sensor_map.get(sensor_id)
                    
                    if param_name and value is not None:
                        # Si ya existe el parámetro, usa el valor más reciente
                        if param_name not in values:
                            values[param_name] = value
                            logger.info(f"Mapped sensor {sensor_id} -> {param_name} = {value}")
                
                logger.info(f"Extracted values: {values}")
            
        except requests.exceptions.RequestException as e:
            logger.error(f"OpenAQ API request failed: {str(e)}")
            values = {}
        except Exception as e:
            logger.error(f"Unexpected error: {str(e)}", exc_info=True)
            values = {}

        aqi = _aqi_from_pollutants(values)
        logger.info(f"Calculated AQI: {aqi} from values: {values}")
        
        payload = {
            "aqi": aqi,
            "pm25": values.get("pm25"),
            "o3": values.get("o3"),
            "no2": values.get("no2"),
            "ai": None, "rain": 0.0, "pbl": 800.0, "wind": {"u": 0.0, "v": 0.0}
        }
        cache.set(key, payload, timeout=self.ttl)
        return payload