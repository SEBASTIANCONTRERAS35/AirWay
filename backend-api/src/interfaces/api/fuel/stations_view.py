"""
Endpoints de gasolineras.

- POST /api/v1/fuel/stations_on_route
- GET  /api/v1/fuel/stations_near?lat=&lon=&fuel_type=magna&radius_m=1500
- GET  /api/v1/fuel/cheapest_on_route?...   (conveniencia; interno usa el POST)
"""
import logging

from rest_framework import status as http_status
from rest_framework.response import Response
from rest_framework.views import APIView

from application.fuel.station_service import StationService

logger = logging.getLogger(__name__)


class StationsOnRouteView(APIView):
    """
    POST /api/v1/fuel/stations_on_route
    Body: { "polyline": "...", "buffer_m": 500, "fuel_type": "magna", "limit": 5 }
    """

    def post(self, request):
        data = request.data or {}
        polyline_str = data.get("polyline")
        logger.info("POST /fuel/stations_on_route polyline_len=%d fuel=%s buffer=%s",
                    len(polyline_str or ""), data.get("fuel_type"), data.get("buffer_m"))
        if not polyline_str:
            logger.warning("stations_on_route 400 missing polyline")
            return Response({"error": "polyline required"}, status=http_status.HTTP_400_BAD_REQUEST)

        fuel_type = data.get("fuel_type", "magna")
        try:
            buffer_m = int(data.get("buffer_m", 500))
            limit = int(data.get("limit", 5))
        except (TypeError, ValueError):
            return Response({"error": "buffer_m and limit must be integers"},
                            status=http_status.HTTP_400_BAD_REQUEST)

        stations = StationService.stations_near_route(
            encoded_polyline=polyline_str,
            buffer_m=buffer_m,
            fuel_type=fuel_type,
            limit=limit,
        )
        avg = StationService.average_price(fuel_type)
        for s in stations:
            s["savings_per_liter"] = round(avg - s["price"], 2) if avg > 0 else 0.0

        logger.info("stations_on_route 200 count=%d avg=%.2f", len(stations), avg)
        return Response({
            "fuel_type": fuel_type,
            "average_price": avg,
            "count": len(stations),
            "stations": stations,
        })


class StationsNearPointView(APIView):
    """
    GET /api/v1/fuel/stations_near?lat=19.43&lon=-99.13&radius_m=1500&fuel_type=magna&limit=5
    """

    def get(self, request):
        try:
            lat = float(request.query_params.get("lat"))
            lon = float(request.query_params.get("lon"))
        except (TypeError, ValueError):
            logger.warning("stations_near 400 bad lat/lon")
            return Response({"error": "lat/lon required"}, status=http_status.HTTP_400_BAD_REQUEST)

        fuel_type = request.query_params.get("fuel_type", "magna")
        try:
            radius_m = int(request.query_params.get("radius_m", 1500))
            limit = int(request.query_params.get("limit", 5))
        except ValueError:
            radius_m, limit = 1500, 5

        stations = StationService.stations_near_point(
            lat=lat, lon=lon, radius_m=radius_m,
            fuel_type=fuel_type, limit=limit,
        )
        avg = StationService.average_price(fuel_type)
        for s in stations:
            s["savings_per_liter"] = round(avg - s["price"], 2) if avg > 0 else 0.0

        logger.info("GET /fuel/stations_near lat=%.4f lon=%.4f found=%d avg=%.2f",
                    lat, lon, len(stations), avg)
        return Response({
            "fuel_type": fuel_type,
            "average_price": avg,
            "count": len(stations),
            "stations": stations,
        })
