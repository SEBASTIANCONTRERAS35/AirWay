"""
StationService: búsqueda de gasolineras cercanas a una ruta (polyline).

Sin PostGIS: usa Haversine + buffer simple sobre dataset en memoria.
Adecuado para <10k estaciones (todo CDMX cabe).
"""
import logging
import math
from functools import lru_cache

import polyline

from adapters.fuel.profeco_scraper import ProfecoScraper

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def _load_stations() -> list[dict]:
    """
    Carga estaciones una sola vez (fallback + cache). En producción, este cache
    se invalida por el Celery task que reescribe el JSON cada 24h.
    """
    scraper = ProfecoScraper()
    stations = scraper.fetch_cached_or_fallback()
    # Filtra estaciones sin geocoding (del PDF live)
    return [s for s in stations if s.get("lat") is not None and s.get("lon") is not None]


class StationService:
    """Búsqueda y comparación de gasolineras."""

    EARTH_RADIUS_M = 6371000

    # ── Distancia ────────────────────────────────────────────────────────────
    @classmethod
    def _haversine_m(cls, lat1, lon1, lat2, lon2):
        from math import radians, sin, cos, atan2, sqrt
        dlat = radians(lat2 - lat1)
        dlon = radians(lon2 - lon1)
        a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
        return 2 * cls.EARTH_RADIUS_M * atan2(sqrt(a), sqrt(1 - a))

    @classmethod
    def _min_distance_to_polyline_m(cls, station_lat, station_lon, pts):
        """Retorna la distancia mínima entre la estación y cualquier punto del polyline."""
        if not pts:
            return float("inf")
        return min(
            cls._haversine_m(station_lat, station_lon, lat, lon)
            for lat, lon in pts
        )

    # ── API pública ──────────────────────────────────────────────────────────
    @classmethod
    def stations_near_point(cls, lat: float, lon: float, radius_m: int = 1500,
                            fuel_type: str = "magna", limit: int = 5) -> list[dict]:
        """Top N gasolineras más baratas dentro de radius_m del punto."""
        logger.info("station_service.near_point lat=%.4f lon=%.4f radius=%dm fuel=%s limit=%d",
                    lat, lon, radius_m, fuel_type, limit)
        stations = _load_stations()
        nearby = []
        for s in stations:
            d = cls._haversine_m(lat, lon, s["lat"], s["lon"])
            if d <= radius_m:
                price = s.get(fuel_type)
                if price is None:
                    continue
                nearby.append({**s, "distance_m": int(d), "price": price, "fuel_type": fuel_type})
        nearby.sort(key=lambda x: x["price"])
        result = nearby[:limit]
        logger.info("station_service.near_point found=%d cheapest=%s",
                    len(result), result[0].get("brand") if result else None)
        return result

    @classmethod
    def stations_near_route(cls, encoded_polyline: str, buffer_m: int = 500,
                            fuel_type: str = "magna", limit: int = 5) -> list[dict]:
        """
        Top N gasolineras más baratas cuya distancia mínima al polyline es <= buffer_m.
        """
        logger.info("station_service.near_route buffer=%dm fuel=%s limit=%d polyline_len=%d",
                    buffer_m, fuel_type, limit, len(encoded_polyline or ""))
        pts = None
        for precision in (5, 6):
            try:
                candidate = polyline.decode(encoded_polyline, precision=precision)
                if candidate and len(candidate) > 1:
                    pts = candidate
                    break
            except Exception:
                continue
        if not pts:
            logger.warning("station_service.near_route polyline decode failed")
            return []

        # Sample pts cada ~200m para acelerar (si la polyline tiene cientos de nodos)
        sampled = pts[::max(1, len(pts) // 100)]

        stations = _load_stations()
        nearby = []
        for s in stations:
            d = cls._min_distance_to_polyline_m(s["lat"], s["lon"], sampled)
            if d <= buffer_m:
                price = s.get(fuel_type)
                if price is None:
                    continue
                nearby.append({**s, "distance_m": int(d), "price": price, "fuel_type": fuel_type})
        nearby.sort(key=lambda x: x["price"])
        result = nearby[:limit]
        logger.info("station_service.near_route total_stations=%d matched=%d limited=%d",
                    len(stations), len(nearby), len(result))
        return result

    @classmethod
    def average_price(cls, fuel_type: str = "magna") -> float:
        """Precio promedio del dataset actual para un combustible."""
        stations = _load_stations()
        prices = [s.get(fuel_type) for s in stations if s.get(fuel_type) is not None]
        if not prices:
            return 0.0
        return round(sum(prices) / len(prices), 2)

    @classmethod
    def cheapest_on_route(cls, encoded_polyline: str, buffer_m: int = 500,
                          fuel_type: str = "magna") -> dict | None:
        """Retorna la estación más barata en la ruta + savings vs promedio."""
        matches = cls.stations_near_route(encoded_polyline, buffer_m=buffer_m,
                                          fuel_type=fuel_type, limit=1)
        if not matches:
            return None
        best = matches[0]
        avg = cls.average_price(fuel_type)
        best["savings_per_liter"] = round(avg - best["price"], 2) if avg > 0 else 0.0
        best["average_price"] = avg
        return best
