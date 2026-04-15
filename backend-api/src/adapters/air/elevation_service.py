# adapters/air/elevation_service.py
"""
Servicio de elevación usando Open-Meteo Elevation API.
- Sin API key, sin registro
- Resolución 90m (Copernicus DEM GLO-90)
- Soporta batch de coordenadas en un solo request
- Caché permanente (la altitud de un punto no cambia)
"""
import requests
import logging
from django.core.cache import cache

logger = logging.getLogger(__name__)

ELEVATION_API_URL = "https://api.open-meteo.com/v1/elevation"

# Caché largo: la altitud no cambia
ELEVATION_CACHE_TTL = 86400  # 24 horas


class ElevationService:
    """Obtiene altitud en metros sobre el nivel del mar para coordenadas."""

    def get_elevation(self, lat: float, lon: float) -> float:
        """Obtiene altitud de un solo punto."""
        elevations = self.get_elevations([(lat, lon)])
        return elevations[0] if elevations else 0.0

    def get_elevations(self, coords: list) -> list:
        """
        Obtiene altitudes de múltiples puntos en un solo request.

        Args:
            coords: lista de tuplas [(lat, lon), ...]

        Returns:
            lista de altitudes en metros [2350.0, 2780.0, ...]
        """
        if not coords:
            return []

        # Intentar obtener del caché
        cached_results = []
        uncached_indices = []
        for i, (lat, lon) in enumerate(coords):
            key = f"elev:{lat:.4f}:{lon:.4f}"
            cached = cache.get(key)
            if cached is not None:
                cached_results.append((i, cached))
            else:
                uncached_indices.append(i)

        # Si todo estaba en caché, devolver directo
        if not uncached_indices:
            return [v for _, v in sorted(cached_results)]

        # Preparar request para coordenadas no cacheadas
        uncached_coords = [coords[i] for i in uncached_indices]
        lats = ",".join(f"{c[0]:.4f}" for c in uncached_coords)
        lons = ",".join(f"{c[1]:.4f}" for c in uncached_coords)

        try:
            params = {"latitude": lats, "longitude": lons}
            r = requests.get(ELEVATION_API_URL, params=params, timeout=5)
            r.raise_for_status()
            data = r.json()

            elevations = data.get("elevation", [])

            # Guardar en caché
            for j, elev in enumerate(elevations):
                idx = uncached_indices[j]
                lat, lon = coords[idx]
                key = f"elev:{lat:.4f}:{lon:.4f}"
                cache.set(key, float(elev), timeout=ELEVATION_CACHE_TTL)
                cached_results.append((idx, float(elev)))

        except requests.exceptions.RequestException as e:
            logger.error(f"Elevation API error: {e}")
            # Fallback: asumir 0m para los que faltan
            for idx in uncached_indices:
                if not any(i == idx for i, _ in cached_results):
                    cached_results.append((idx, 0.0))

        # Ordenar por índice original y devolver
        cached_results.sort(key=lambda x: x[0])
        return [v for _, v in cached_results]

    def enrich_stations_with_elevation(self, stations: list, user_lat: float, user_lon: float) -> tuple:
        """
        Agrega altitud a cada estación y al punto del usuario en un solo batch.

        Returns:
            (user_elevation, stations_con_elevation)
        """
        if not stations:
            return 0.0, stations

        # Armar lista de coordenadas: usuario + todas las estaciones
        coords = [(user_lat, user_lon)]
        for s in stations:
            coords.append((s.get("lat", 0), s.get("lon", 0)))

        elevations = self.get_elevations(coords)

        user_elevation = elevations[0] if elevations else 0.0

        # Asignar elevación a cada estación
        for i, s in enumerate(stations):
            s["elevation_m"] = elevations[i + 1] if i + 1 < len(elevations) else 0.0

        return user_elevation, stations
