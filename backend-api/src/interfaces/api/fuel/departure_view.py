"""
DepartureOptimalView: endpoint para "mejor momento para salir".

POST /api/v1/fuel/optimal_departure
Body: {
  "origin": { "lat": 19.43, "lon": -99.13 },
  "destination": { "lat": 19.38, "lon": -99.27 },
  "vehicle": { ... },
  "earliest": "2026-04-16T07:00:00-06:00",
  "latest":   "2026-04-16T13:00:00-06:00",
  "step_min": 30,
  "user_profile": { "asthma": true, "age": 45 }
}
"""
import logging
from datetime import datetime

from rest_framework import status as http_status
from rest_framework.response import Response
from rest_framework.views import APIView

from application.fuel import VehicleProfile
from application.fuel.departure_optimizer import DepartureOptimizer

logger = logging.getLogger(__name__)


class OptimalDepartureView(APIView):
    def post(self, request):
        data = request.data or {}
        logger.info("POST /fuel/optimal_departure step=%s profile=%s",
                    data.get("step_min"), bool(data.get("user_profile")))
        try:
            origin = (float(data["origin"]["lat"]), float(data["origin"]["lon"]))
            dest = (float(data["destination"]["lat"]), float(data["destination"]["lon"]))
            earliest = _parse_datetime(data["earliest"])
            latest = _parse_datetime(data["latest"])
        except (KeyError, TypeError, ValueError) as exc:
            logger.warning("optimal_departure 400 bad payload: %s", exc)
            return Response(
                {"error": f"Payload inválido: {exc}"},
                status=http_status.HTTP_400_BAD_REQUEST,
            )

        vehicle = None
        if data.get("vehicle"):
            try:
                vehicle = VehicleProfile.from_dict(data["vehicle"])
            except Exception as exc:
                return Response(
                    {"error": f"vehicle inválido: {exc}"},
                    status=http_status.HTTP_400_BAD_REQUEST,
                )

        if vehicle is None:
            vehicle = VehicleProfile(
                make="Nissan", model="Versa", year=2019,
                conuee_km_per_l=15.1, engine_cc=1600,
            )

        step_min = int(data.get("step_min", 30))
        user_profile = data.get("user_profile") or {}

        optimizer = DepartureOptimizer()
        try:
            result = optimizer.suggest_windows(
                origin=origin,
                destination=dest,
                vehicle=vehicle,
                earliest=earliest,
                latest=latest,
                step_min=step_min,
                user_profile=user_profile,
            )
        except ValueError as exc:
            logger.warning("optimal_departure 400 validation: %s", exc)
            return Response({"error": str(exc)}, status=http_status.HTTP_400_BAD_REQUEST)
        except Exception as exc:
            logger.exception("optimal_departure 500 optimizer failed")
            return Response(
                {"error": f"Error interno: {exc}"},
                status=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        windows_n = len(result.get("windows") or [])
        best = result.get("best") or {}
        logger.info("optimal_departure 200 windows=%d best_at=%s best_score=%.1f",
                    windows_n, best.get("depart_at"), best.get("score") or 0)
        return Response(result)


def _parse_datetime(s: str) -> datetime:
    if isinstance(s, datetime):
        return s
    return datetime.fromisoformat(s.replace("Z", "+00:00"))
