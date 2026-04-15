# adapters/air/waqi_provider.py
"""
Proveedor de calidad del aire usando WAQI (World Air Quality Index).
- Token gratuito (https://aqicn.org/data-platform/token)
- Cobertura global: +11,000 estaciones
- Datos en tiempo real
- Hasta 1000 req/seg
"""
import os
import requests
import logging
from math import radians, sin, cos, atan2, sqrt
from datetime import datetime, timezone
from django.core.cache import cache

logger = logging.getLogger(__name__)

WAQI_API_BASE = "https://api.waqi.info"


def _haversine_m(lat1, lon1, lat2, lon2):
    """Distancia en metros entre dos puntos (haversine)."""
    R = 6371000
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    return 2 * R * atan2(sqrt(a), sqrt(1 - a))


def _extract(iaqi: dict, param: str):
    """Extrae valor de un contaminante del formato iaqi de WAQI."""
    entry = iaqi.get(param)
    if entry and isinstance(entry, dict):
        return entry.get("v")
    return None


class WAQIProvider:
    """Obtiene AQI desde WAQI (estaciones de monitoreo reales)."""

    def __init__(self, ttl=300):
        self.ttl = ttl
        self.token = os.environ.get("WAQI_TOKEN", "")

    def get_aqi_cell(self, lat: float, lon: float, when: datetime) -> dict:
        """Método legacy: devuelve 1 estación (la más cercana)."""
        stations = self.get_stations_nearby(lat, lon, radius_km=10)
        if stations:
            return stations[0]
        return {"aqi": 0, "pm25": None, "o3": None, "no2": None, "source": "waqi", "source_type": "station"}

    def get_stations_nearby(self, lat: float, lon: float, radius_km: float = 10) -> list:
        """
        Obtiene TODAS las estaciones en un radio usando el endpoint de bounding box.
        Devuelve lista ordenada por distancia al punto del usuario.

        Retorna: [{aqi, lat, lon, name, distance_m, source, source_type, ...}, ...]
        """
        key = f"waqi_bbox:{lat:.2f}:{lon:.2f}:{radius_km}"
        cached = cache.get(key)
        if cached:
            return cached

        if not self.token:
            logger.warning("WAQI_TOKEN no configurado")
            return []

        try:
            # Convertir centro + radio a bounding box
            delta_lat = radius_km / 111.0
            delta_lon = radius_km / (111.0 * cos(radians(lat)))
            lat1 = lat - delta_lat
            lon1 = lon - delta_lon
            lat2 = lat + delta_lat
            lon2 = lon + delta_lon

            url = f"{WAQI_API_BASE}/map/bounds/"
            params = {
                "latlng": f"{lat1},{lon1},{lat2},{lon2}",
                "token": self.token,
            }

            logger.info(f"WAQI bbox request: {lat1:.3f},{lon1:.3f} → {lat2:.3f},{lon2:.3f}")
            r = requests.get(url, params=params, timeout=10)
            r.raise_for_status()
            body = r.json()

            if body.get("status") != "ok":
                logger.warning(f"WAQI bbox status: {body.get('status')}")
                return []

            raw_stations = body.get("data", [])
            stations = []

            for s in raw_stations:
                # Parsear AQI — puede ser string, int, o "-" (sin datos)
                raw_aqi = s.get("aqi")
                if raw_aqi is None or raw_aqi == "-" or raw_aqi == "":
                    continue
                try:
                    aqi = int(raw_aqi)
                except (ValueError, TypeError):
                    continue

                if aqi <= 0:
                    continue

                s_lat = float(s.get("lat", 0))
                s_lon = float(s.get("lon", 0))
                distance = _haversine_m(lat, lon, s_lat, s_lon)

                # Filtrar por radio real (el bbox es un rectángulo, puede incluir esquinas fuera)
                if distance > radius_km * 1000:
                    continue

                station_info = s.get("station", {})
                stations.append({
                    "aqi": aqi,
                    "lat": s_lat,
                    "lon": s_lon,
                    "name": station_info.get("name", "Unknown"),
                    "distance_m": round(distance),
                    "source": "waqi",
                    "source_type": "station",
                    "uid": s.get("uid"),
                    # WAQI bbox no devuelve contaminantes individuales
                    "pm25": None,
                    "pm10": None,
                    "no2": None,
                    "o3": None,
                })

            # Ordenar por distancia
            stations.sort(key=lambda x: x["distance_m"])
            logger.info(f"WAQI bbox: {len(stations)} estaciones en {radius_km}km")

            cache.set(key, stations, timeout=self.ttl)
            return stations

        except requests.exceptions.RequestException as e:
            logger.error(f"WAQI bbox error: {e}")
            return []
