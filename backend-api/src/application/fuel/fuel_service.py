"""
FuelService: scorea un polyline y retorna estimación completa de combustible.

Gemelo estructural de ExposureService. Usa los mismos providers (Open-Meteo,
elevation_service) ya integrados.
"""
import logging
import math
import polyline

from .physics_model import estimate_fuel_liters, estimate_pesos_cost, DEFAULT_FUEL_PRICES_MXN_PER_L
from .vehicle_profile import VehicleProfile

logger = logging.getLogger(__name__)


class FuelService:
    """Calcula consumo de gasolina para un polyline dada un VehicleProfile."""

    def __init__(self, weather_provider=None, elevation_service=None):
        self.weather = weather_provider
        self.elevation = elevation_service

    # ── Geometría ────────────────────────────────────────────────────────────
    @staticmethod
    def _haversine_m(lat1, lon1, lat2, lon2):
        R = 6371000
        from math import radians, sin, cos, atan2, sqrt
        dlat = radians(lat2 - lat1)
        dlon = radians(lon2 - lon1)
        a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
        return 2 * R * atan2(sqrt(a), sqrt(1 - a))

    @staticmethod
    def _midpoint(pts):
        if not pts:
            return (19.4326, -99.1332)  # CDMX centro como fallback
        return pts[len(pts) // 2]

    # ── Geometría de la ruta ────────────────────────────────────────────────
    def _total_distance_km(self, pts):
        if len(pts) < 2:
            return 0.0
        total = 0.0
        for (lat1, lon1), (lat2, lon2) in zip(pts[:-1], pts[1:]):
            total += self._haversine_m(lat1, lon1, lat2, lon2)
        return total / 1000.0

    def _average_grade_pct(self, pts):
        """Estima pendiente promedio usando elevation_service si disponible."""
        if not self.elevation or len(pts) < 2:
            return 0.0
        try:
            start_elev = self.elevation.get_elevation(pts[0][0], pts[0][1])
            end_elev = self.elevation.get_elevation(pts[-1][0], pts[-1][1])
            if start_elev is None or end_elev is None:
                return 0.0
            distance_m = sum(
                self._haversine_m(p[0], p[1], q[0], q[1])
                for p, q in zip(pts[:-1], pts[1:])
            )
            if distance_m <= 0:
                return 0.0
            return ((end_elev - start_elev) / distance_m) * 100
        except Exception as exc:
            logger.debug("elevation failed: %s", exc)
            return 0.0

    def _estimate_stops(self, pts):
        """Heurística: 1 stop por cada 400m en zona urbana."""
        distance_km = self._total_distance_km(pts)
        return int(distance_km * 2.5)  # ~2.5 stops/km en CDMX

    def _estimate_avg_speed_kmh(self, distance_km, duration_min):
        if duration_min is None or duration_min <= 0:
            return 35.0  # default urbano CDMX
        return (distance_km / duration_min) * 60.0

    # ── API pública ──────────────────────────────────────────────────────────
    def score_polyline(
        self,
        encoded_polyline: str,
        vehicle: VehicleProfile,
        depart_at=None,
        duration_min: float = None,
        passengers: int = 1,
        fuel_price_override: float = None,
    ) -> dict:
        """
        Calcula estimación completa para un polyline codificado.
        """
        logger.info(
            "fuel_service.score_polyline vehicle=%s polyline_len=%d duration_min=%s",
            vehicle.display_name, len(encoded_polyline or ""), duration_min,
        )

        # Decodificar polyline (OSRM / Mapbox usa precisión 5 o 6)
        pts = None
        for precision in (5, 6):
            try:
                candidate = polyline.decode(encoded_polyline, precision=precision)
                if candidate and len(candidate) > 1:
                    pts = candidate
                    logger.debug("fuel_service.polyline decoded precision=%d points=%d", precision, len(pts))
                    break
            except Exception:
                continue
        if not pts:
            logger.warning("fuel_service.polyline decode failed; using empty path")
            pts = []

        distance_km = max(self._total_distance_km(pts), 0.1)
        avg_speed = self._estimate_avg_speed_kmh(distance_km, duration_min)
        avg_grade = self._average_grade_pct(pts)
        midpoint = self._midpoint(pts)
        stops = self._estimate_stops(pts)

        logger.debug(
            "fuel_service.route_features distance=%.2fkm avg_speed=%.1fkmh grade=%.2f%% stops=%d midpoint=%s",
            distance_km, avg_speed, avg_grade, stops, midpoint,
        )

        # Weather (si está disponible)
        weather = {}
        if self.weather:
            try:
                weather = self.weather.get_current_weather(midpoint[0], midpoint[1]) or {}
                logger.debug("fuel_service.weather temp=%s wind=%s",
                             weather.get("temperature_2m"), weather.get("wind_speed_10m"))
            except Exception as exc:
                logger.warning("fuel_service.weather fetch failed: %s", exc)

        temp_c = weather.get("temperature_2m", 20.0)
        wind_ms = weather.get("wind_speed_10m", 0.0) or 0.0
        wind_kmh = wind_ms * 3.6
        # Asume 50% del viento es de frente en promedio
        headwind_kmh = wind_kmh * 0.5

        physics = estimate_fuel_liters(
            distance_km=distance_km,
            vehicle=vehicle,
            avg_speed_kmh=avg_speed,
            avg_grade_pct=avg_grade,
            temperature_c=temp_c,
            wind_headwind_kmh=headwind_kmh,
            stops_count=stops,
            passengers=passengers,
        )

        # Costo en pesos
        if vehicle.is_electric:
            price_per_kwh = 2.85  # promedio CFE DAC-1 residencial 2026
            pesos_cost = physics.get("kwh", 0.0) * price_per_kwh
        else:
            pesos_cost = estimate_pesos_cost(physics["liters"], vehicle.fuel_type, fuel_price_override)

        logger.info(
            "fuel_service.score_polyline result L=%.2f $=%.2f CO2=%.2fkg distance=%.2fkm",
            physics.get("liters", 0), pesos_cost, physics.get("co2_kg", 0), distance_km,
        )

        return {
            **physics,
            "pesos_cost": round(pesos_cost, 2),
            "distance_km": round(distance_km, 2),
            "duration_min": round(duration_min, 1) if duration_min else None,
            "avg_speed_kmh": round(avg_speed, 1),
            "avg_grade_pct": round(avg_grade, 2),
            "stops_estimated": stops,
            "temperature_c": round(temp_c, 1) if temp_c else None,
            "vehicle_display": vehicle.display_name,
        }
