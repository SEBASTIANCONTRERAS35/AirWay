"""
Endpoints HTTP para el módulo de combustible (GasolinaMeter).

Rutas registradas en /api/v1/:
- POST /fuel/estimate              → estimación para un polyline
- GET  /fuel/catalog               → lista de vehículos CONUEE (para autocomplete iOS)
- GET  /fuel/catalog/search        → búsqueda por query
- GET  /fuel/prices                → precios actuales de gasolina (MXN/L)
- POST /fuel/stations_on_route     → gasolineras en buffer de ruta (Fase 3)
- POST /fuel/optimal_departure     → mejor momento para salir (Fase 7)
"""
import logging
from datetime import datetime, timezone

from rest_framework import status as http_status
from rest_framework.response import Response
from rest_framework.views import APIView

from application.fuel import VehicleProfile, FuelService
from application.fuel.conuee_catalog import ConueeCatalog
from application.fuel.physics_model import DEFAULT_FUEL_PRICES_MXN_PER_L
from adapters.air.openmeteo_provider import OpenMeteoProvider
from adapters.air.elevation_service import ElevationService

logger = logging.getLogger(__name__)


# ── Helpers ─────────────────────────────────────────────────────────────────
def _parse_vehicle(payload: dict) -> VehicleProfile:
    """Construye VehicleProfile desde payload JSON con validación."""
    required = ["make", "model", "year"]
    missing = [k for k in required if k not in payload]
    if missing:
        raise ValueError(f"Faltan campos del vehículo: {missing}")
    return VehicleProfile.from_dict(payload)


def _fuel_service() -> FuelService:
    """Factory con deps cacheadas."""
    try:
        elev = ElevationService()
    except Exception:
        elev = None
    return FuelService(
        weather_provider=OpenMeteoProvider(),
        elevation_service=elev,
    )


# ── Endpoints ───────────────────────────────────────────────────────────────
class FuelEstimateView(APIView):
    """
    POST /api/v1/fuel/estimate

    Body:
    {
      "polyline": "encoded_string",
      "vehicle": { "make": "Nissan", "model": "Versa", "year": 2019,
                   "fuel_type": "magna", "conuee_km_per_l": 15.1, ... },
      "duration_min": 28.5,              (opcional, mejora estimación velocidad)
      "passengers": 1,                    (opcional)
      "depart_at": "2026-04-16T08:30:00-06:00",   (opcional)
      "fuel_price_override": 23.80        (opcional; usa Profeco si no se da)
    }
    """

    def post(self, request):
        data = request.data or {}
        polyline_str = data.get("polyline")
        logger.info("POST /fuel/estimate polyline_len=%d duration=%s passengers=%s",
                    len(polyline_str or ""), data.get("duration_min"), data.get("passengers"))

        if not polyline_str:
            logger.warning("fuel.estimate 400 missing polyline")
            return Response({"error": "polyline es requerido"}, status=http_status.HTTP_400_BAD_REQUEST)

        try:
            vehicle = _parse_vehicle(data.get("vehicle") or {})
        except (ValueError, KeyError) as exc:
            logger.warning("fuel.estimate 400 bad vehicle: %s", exc)
            return Response({"error": str(exc)}, status=http_status.HTTP_400_BAD_REQUEST)

        depart_at = None
        if data.get("depart_at"):
            try:
                depart_at = datetime.fromisoformat(data["depart_at"].replace("Z", "+00:00"))
            except ValueError:
                logger.debug("fuel.estimate invalid depart_at, ignoring")

        try:
            service = _fuel_service()
            result = service.score_polyline(
                encoded_polyline=polyline_str,
                vehicle=vehicle,
                depart_at=depart_at,
                duration_min=data.get("duration_min"),
                passengers=int(data.get("passengers") or 1),
                fuel_price_override=data.get("fuel_price_override"),
            )
            # Agregar metadata solicitada
            result["estimated_at"] = datetime.now(timezone.utc).isoformat()
            logger.info("fuel.estimate 200 L=%.2f $=%.2f CO2=%.2fkg",
                        result.get("liters", 0), result.get("pesos_cost", 0), result.get("co2_kg", 0))
            return Response(result)
        except Exception as exc:
            logger.exception("fuel.estimate 500 failed")
            return Response(
                {"error": f"Error interno: {exc}"},
                status=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class FuelCatalogView(APIView):
    """
    GET /api/v1/fuel/catalog          → todos los vehículos del catálogo
    GET /api/v1/fuel/catalog?make=... → modelos de una marca
    """

    def get(self, request):
        make = request.query_params.get("make")
        logger.info("GET /fuel/catalog make=%s", make)
        if make:
            models = ConueeCatalog.models_for_make(make)
            logger.debug("fuel.catalog returned %d models for make=%s", len(models), make)
            return Response({
                "make": make,
                "models": models,
            })
        all_vehicles = ConueeCatalog.all()
        logger.debug("fuel.catalog returned all=%d vehicles", len(all_vehicles))
        return Response({
            "makes": ConueeCatalog.makes(),
            "vehicles": all_vehicles,
        })


class FuelCatalogSearchView(APIView):
    """GET /api/v1/fuel/catalog/search?q=versa&limit=10"""

    def get(self, request):
        q = request.query_params.get("q", "")
        try:
            limit = int(request.query_params.get("limit", 10))
        except ValueError:
            limit = 10
        limit = max(1, min(limit, 50))
        results = ConueeCatalog.search(q, limit=limit)
        logger.info("GET /fuel/catalog/search q=%r limit=%d results=%d", q, limit, len(results))
        return Response({
            "query": q,
            "results": results,
        })


class FuelPricesView(APIView):
    """
    GET /api/v1/fuel/prices
    Devuelve precios actuales MXN/L por tipo de combustible.
    Fase 3 conectará este endpoint con scraper Profeco.
    """

    def get(self, request):
        # Default hardcoded (fuente: Profeco 13 abril 2026)
        prices = {
            "magna": DEFAULT_FUEL_PRICES_MXN_PER_L["magna"],
            "premium": DEFAULT_FUEL_PRICES_MXN_PER_L["premium"],
            "diesel": DEFAULT_FUEL_PRICES_MXN_PER_L["diesel"],
            "source": "Profeco QQP 13-abr-2026 (default hardcoded, Fase 3 live)",
            "updated_at": "2026-04-13T00:00:00-06:00",
            "currency": "MXN",
            "unit": "per_liter",
        }
        return Response(prices)
