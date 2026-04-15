# adapters/air/openaq_grid_provider.py
"""
Proveedor de calidad del aire usando OpenAQ v3.
- API key gratuita
- Red abierta de estaciones de monitoreo
- Datos históricos y en tiempo real
"""
import os
import requests
import logging
from datetime import datetime, timezone
from concurrent.futures import ThreadPoolExecutor, as_completed
from django.core.cache import cache

logger = logging.getLogger(__name__)

OPENAQ_API_BASE = "https://api.openaq.org/v3"
MAX_STATION_DETAIL_CALLS = 5  # Limitar llamadas de detalle para no exceder rate limit


def _aqi_from_pm25(pm25: float) -> int:
    """Convierte PM2.5 (µg/m³) a AQI usando breakpoints EPA."""
    if pm25 <= 12.0:   return int((50 / 12.0) * pm25)
    if pm25 <= 35.4:   return int(50 + (pm25 - 12.1) * 50 / (35.4 - 12.1))
    if pm25 <= 55.4:   return int(100 + (pm25 - 35.5) * 50 / (55.4 - 35.5))
    if pm25 <= 150.4:  return int(150 + (pm25 - 55.5) * 50 / (150.4 - 55.5))
    if pm25 <= 250.4:  return int(200 + (pm25 - 150.5) * 100 / (250.4 - 150.5))
    return 301


def _aqi_from_pollutants(values: dict) -> int:
    subs = []
    pm25 = values.get("pm25")
    if pm25 is not None:
        subs.append(_aqi_from_pm25(pm25))
    return max(subs) if subs else 0


class OpenAQGridProvider:
    """Proveedor OpenAQ con soporte multi-estación."""

    def __init__(self, radius_m=15000, ttl=300):
        self.radius_m = radius_m
        self.ttl = ttl
        self.headers = {"X-API-Key": os.environ.get("OPENAQ_API_KEY", "")}

    def get_aqi_cell(self, lat: float, lon: float, when: datetime) -> dict:
        """Método legacy: devuelve 1 estación (la más cercana)."""
        stations = self.get_stations_nearby(lat, lon)
        if stations:
            return stations[0]
        return {"aqi": 0, "pm25": None, "o3": None, "no2": None, "source": "openaq", "source_type": "station"}

    def get_stations_nearby(self, lat: float, lon: float, radius_m: int = None) -> list:
        """
        Obtiene múltiples estaciones cercanas con sus mediciones.
        Devuelve lista ordenada por distancia.

        Retorna: [{aqi, lat, lon, name, distance_m, pm25, no2, o3, ...}, ...]
        """
        radius = radius_m or self.radius_m
        key = f"openaq_multi:{lat:.2f}:{lon:.2f}:{radius}"
        cached = cache.get(key)
        if cached:
            return cached

        try:
            # Paso 1: Buscar todas las ubicaciones en el radio
            locations_url = f"{OPENAQ_API_BASE}/locations"
            params = {
                "coordinates": f"{lat},{lon}",
                "radius": radius,
                "limit": 10,
            }

            r = requests.get(locations_url, params=params, headers=self.headers, timeout=10)
            r.raise_for_status()
            results = r.json().get("results", [])

            if not results:
                logger.info("OpenAQ: no locations found")
                return []

            # Ordenar por distancia y limitar llamadas de detalle
            results.sort(key=lambda x: x.get("distance", 99999))
            to_detail = results[:MAX_STATION_DETAIL_CALLS]

            # Paso 2: Obtener mediciones de las N más cercanas en paralelo
            stations = []
            with ThreadPoolExecutor(max_workers=MAX_STATION_DETAIL_CALLS) as executor:
                futures = {
                    executor.submit(self._fetch_station_detail, loc): loc
                    for loc in to_detail
                }
                for future in as_completed(futures):
                    loc = futures[future]
                    try:
                        station = future.result()
                        if station and station.get("aqi", 0) > 0:
                            stations.append(station)
                    except Exception as e:
                        logger.error(f"OpenAQ station detail error: {e}")

            stations.sort(key=lambda x: x["distance_m"])
            logger.info(f"OpenAQ: {len(stations)} estaciones con datos en {radius}m")

            cache.set(key, stations, timeout=self.ttl)
            return stations

        except requests.exceptions.RequestException as e:
            logger.error(f"OpenAQ locations error: {e}")
            return []

    def _fetch_station_detail(self, location: dict) -> dict:
        """Obtiene mediciones de una estación individual."""
        location_id = location["id"]
        location_name = location.get("name", "Unknown")
        distance = location.get("distance", 0)
        coords = location.get("coordinates", {})

        # Mapear sensores
        sensor_map = {}
        for sensor in location.get("sensors", []):
            sid = sensor.get("id")
            pname = sensor.get("parameter", {}).get("name")
            if sid and pname:
                sensor_map[sid] = pname

        # Obtener mediciones más recientes
        try:
            latest_url = f"{OPENAQ_API_BASE}/locations/{location_id}/latest"
            r = requests.get(latest_url, headers=self.headers, timeout=10)
            r.raise_for_status()
            measurements = r.json().get("results", [])

            values = {}
            for m in measurements:
                sensor_id = m.get("sensorsId")
                value = m.get("value")
                param_name = sensor_map.get(sensor_id)
                if param_name and value is not None and param_name not in values:
                    values[param_name] = value

        except requests.exceptions.RequestException as e:
            logger.error(f"OpenAQ latest error for {location_name}: {e}")
            values = {}

        aqi = _aqi_from_pollutants(values)

        return {
            "aqi": aqi,
            "lat": coords.get("latitude", 0),
            "lon": coords.get("longitude", 0),
            "name": location_name,
            "distance_m": round(distance),
            "source": "openaq",
            "source_type": "station",
            "pm25": values.get("pm25"),
            "pm10": values.get("pm10"),
            "no2": values.get("no2"),
            "o3": values.get("o3"),
            "so2": values.get("so2"),
            "co": values.get("co"),
        }
