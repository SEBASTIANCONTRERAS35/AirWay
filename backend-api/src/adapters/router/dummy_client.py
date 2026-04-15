import polyline, math

class DummyRouterClient:
    """
    Devuelve una “ruta” directa origen→destino (polyline6) con distancia/duración aproximadas.
    Útil para probar el flujo sin OSRM aún.
    """
    MODE_SPEED_KMH = {"walk": 4.8, "run": 9.0, "bike": 15.0}

    def _haversine_m(self, lat1, lon1, lat2, lon2):
        R=6371000; from math import radians, sin, cos, atan2, sqrt
        dlat=radians(lat2-lat1); dlon=radians(lon2-lon1)
        a=sin(dlat/2)**2+cos(radians(lat1))*cos(radians(lat2))*sin(dlon/2)**2
        return 2*R*atan2(sqrt(a), sqrt(1-a))

    def route(self, coords, profile="foot", alternatives=1):
        (lon1, lat1), (lon2, lat2) = coords
        dist = self._haversine_m(lat1, lon1, lat2, lon2)
        speed_kmh = self.MODE_SPEED_KMH["walk" if profile=="foot" else "bike"]
        dur_s = max(1, dist / (speed_kmh*1000/3600))
        geom = polyline.encode([(lat1,lon1),(lat2,lon2)], precision=6)
        return [{"geometry": geom, "distance": dist, "duration": dur_s}]