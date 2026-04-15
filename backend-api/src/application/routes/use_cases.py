from .exposure import ExposureService

class ComputeRouteUseCase:
    def __init__(self, router_client, grid_provider):
        self.router = router_client
        self.exposure = ExposureService(grid_provider)

    def handle(self, origin, dest, mode, optimize, depart_at, aqi_threshold=None):
        profile = "foot" if mode in ("walk","run") else "bike"
        routes = self.router.route([origin, dest], profile=profile, alternatives=1)
        scored=[]
        for r in routes:
            exp, max_aqi, segs = self.exposure.score_polyline(r["geometry"], mode, depart_at)
            item = {
              "polyline": r["geometry"],
              "distance_km": round(r["distance"]/1000.0,2),
              "duration_min": round(r["duration"]/60.0,1),
              "exposure_index": exp,
              "max_aqi_on_path": max_aqi,
              "segments": segs
            }
            if aqi_threshold and max_aqi>aqi_threshold: item["exposure_index"] *= 10
            scored.append(item)

        # Con un solo resultado, "best" es ese; mantenemos la firma
        best = scored[0]
        return best, []