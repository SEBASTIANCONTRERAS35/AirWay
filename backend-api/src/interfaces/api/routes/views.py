# backend/interfaces/api/routes/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status as http_status
from datetime import datetime, timezone

from adapters.router.osrm_client import OSRMClient
from adapters.air.openaq_grid_provider import OpenAQGridProvider
from application.routes.exposure import ExposureService


class HealthCheckView(APIView):
    """Health check endpoint for Docker."""
    def get(self, request):
        return Response({"status": "healthy"}, status=http_status.HTTP_200_OK)


class CurrentAQIView(APIView):
    """
    Devuelve el AQI actual de una ubicación específica.
    GET /api/v1/air/current?lat=19.4326&lon=-99.1332
    """
    def get(self, request):
        try:
            lat = float(request.query_params.get("lat"))
            lon = float(request.query_params.get("lon"))
        except (TypeError, ValueError):
            return Response(
                {"error": "Parámetros inválidos. Usa 'lat' y 'lon'."},
                status=http_status.HTTP_400_BAD_REQUEST
            )

        air = OpenAQGridProvider()
        when = datetime.now(timezone.utc)
        
        try:
            data = air.get_aqi_cell(lat, lon, when)
            
            # Categoría de AQI
            print("aqi: ", data.get("aqi"))
            aqi = data.get("aqi", 0)
            if aqi <= 50:
                category = "Bueno"
                color = "#00e400"
                message = "La calidad del aire es satisfactoria"
            elif aqi <= 100:
                category = "Moderado"
                color = "#ffff00"
                message = "La calidad del aire es aceptable"
            elif aqi <= 150:
                category = "Dañino para grupos sensibles"
                color = "#ff7e00"
                message = "Grupos sensibles pueden experimentar efectos"
            elif aqi <= 200:
                category = "Dañino"
                color = "#ff0000"
                message = "Todos pueden experimentar efectos en la salud"
            elif aqi <= 300:
                category = "Muy dañino"
                color = "#8f3f97"
                message = "Alerta de salud: todos pueden experimentar efectos graves"
            else:
                category = "Peligroso"
                color = "#7e0023"
                message = "Alerta de salud de emergencia"

            return Response({
                "location": {
                    "lat": lat,
                    "lon": lon
                },
                "timestamp": when.isoformat(),
                "aqi": aqi,
                "category": category,
                "color": color,
                "message": message,
                "pollutants": {
                    "pm25": data.get("pm25"),
                    "o3": data.get("o3"),
                    "no2": data.get("no2"),
                }
            })
        except Exception as e:
            return Response(
                {"error": f"Error al obtener datos de calidad del aire: {str(e)}"},
                status=http_status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class OptimalRouteView(APIView):
    """
    Devuelve una única ruta óptima: balance entre distancia y contaminación del aire.
    """
    def get(self, request):
        try:
            lat1 = float(request.query_params.get("origin_lat"))
            lon1 = float(request.query_params.get("origin_lon"))
            lat2 = float(request.query_params.get("dest_lat"))
            lon2 = float(request.query_params.get("dest_lon"))
        except (TypeError, ValueError):
            return Response({"error": "Parámetros inválidos. Usa origin_lat, origin_lon, dest_lat, dest_lon."}, status=400)

        mode = request.query_params.get("mode", "bike")
        alpha = float(request.query_params.get("alpha", 0.5))  # peso distancia
        beta  = float(request.query_params.get("beta", 0.5))   # peso contaminación
        depart_at = datetime.now(timezone.utc)

        # Clientes
        router = OSRMClient()
        air = OpenAQGridProvider()
        exposure = ExposureService(air)

        # Obtener rutas alternativas
        routes = router.route([(lon1, lat1), (lon2, lat2)], profile=mode, alternatives=3)
        if not routes:
            return Response({"error": "No se encontraron rutas alternativas."}, status=404)

        evaluations = []
        for r in routes:
            exp, max_aqi, segs = exposure.score_polyline(r["geometry"], mode, depart_at)
            avg_aqi = sum(s["aqi"] for s in segs) / len(segs) if segs else 0
            evaluations.append({
                "polyline": r["geometry"],
                "distance": r["distance"],
                "duration": r["duration"],
                "exposure_index": exp,
                "avg_aqi": avg_aqi,
            })

        # Normalización
        max_dist = max(e["distance"] for e in evaluations)
        max_exp = max(e["exposure_index"] for e in evaluations)
        min_dist = min(e["distance"] for e in evaluations)
        min_exp = min(e["exposure_index"] for e in evaluations)

        for e in evaluations:
            norm_dist = (e["distance"] - min_dist) / (max_dist - min_dist + 1e-9)
            norm_exp  = (e["exposure_index"] - min_exp) / (max_exp - min_exp + 1e-9)
            e["score"] = alpha * norm_dist + beta * norm_exp

        # Seleccionar la ruta con menor score combinado
        optimal = min(evaluations, key=lambda x: x["score"])

        return Response({
            "origin": [lon1, lat1],
            "destination": [lon2, lat2],
            "route": {
                "distance_km": round(optimal["distance"]/1000, 2),
                "duration_min": round(optimal["duration"]/60, 1),
                "exposure_index": round(optimal["exposure_index"], 1),
                "avg_aqi": round(optimal["avg_aqi"], 1),
                "score": round(optimal["score"], 3),
                "polyline": optimal["polyline"],
            },
            "weights": {"alpha_distance": alpha, "beta_air": beta},
            "explanation": (
                "Ruta óptima entre distancia y aire limpio "
                f"(α={alpha}, β={beta})"
            ),
        })