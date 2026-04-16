"""
Endpoints de comparación multimodal.

POST /api/v1/trip/compare
Body: {
  "origin": {"lat": 19.43, "lon": -99.13},
  "destination": {"lat": 19.38, "lon": -99.27},
  "vehicle": { ... VehicleProfile ... }          (opcional)
}
"""
import logging

from rest_framework import status as http_status
from rest_framework.response import Response
from rest_framework.views import APIView

from application.fuel import VehicleProfile
from application.routes.multimodal import MultimodalRouter
from adapters.ai.llm_service import LLMService

logger = logging.getLogger(__name__)


class TripCompareView(APIView):
    """Compara 4 modos de transporte (auto/metro/uber/bici)."""

    def post(self, request):
        data = request.data or {}
        logger.info("POST /trip/compare ai_insight=%s vehicle=%s",
                    data.get("include_ai_insight", True), bool(data.get("vehicle")))

        origin = data.get("origin") or {}
        dest = data.get("destination") or {}
        try:
            origin_tuple = (float(origin["lat"]), float(origin["lon"]))
            dest_tuple = (float(dest["lat"]), float(dest["lon"]))
        except (KeyError, TypeError, ValueError):
            logger.warning("trip.compare 400 missing origin/destination")
            return Response(
                {"error": "origin y destination con lat/lon son requeridos"},
                status=http_status.HTTP_400_BAD_REQUEST,
            )

        vehicle = None
        if data.get("vehicle"):
            try:
                vehicle = VehicleProfile.from_dict(data["vehicle"])
            except Exception as exc:
                logger.warning("trip.compare vehicle parse failed: %s; using default", exc)

        router = MultimodalRouter()
        result = router.compute_all(origin_tuple, dest_tuple, vehicle=vehicle)

        # Enriquecer con insight Gemini (opcional, con cache)
        if data.get("include_ai_insight", True):
            try:
                insight = self._llm_insight(result)
                if insight:
                    result["ai_insight"] = insight
                    logger.debug("trip.compare ai_insight: %s", insight[:80])
            except Exception as exc:
                logger.debug("trip.compare LLM insight failed: %s", exc)

        logger.info("trip.compare 200 rec=%s",
                    (result.get("recommendation") or {}).get("mode_suggested"))
        return Response(result)

    # ── LLM ──────────────────────────────────────────────────────────────────
    def _llm_insight(self, result: dict) -> str | None:
        """Prompt simple a Gemini. Cache por combinación modes/distance."""
        modes = result.get("modes", {})
        if not modes:
            return None

        auto = modes.get("auto", {})
        metro = modes.get("metro", {})
        uber = modes.get("uber", {})
        bici = modes.get("bici", {})

        prompt = f"""Eres Gemini en AirWay. Compara transporte CDMX.
AUTO: {auto.get('duration_min')} min, ${auto.get('total_cost_mxn')} MXN, {auto.get('co2_kg')} kg CO2.
METRO: {metro.get('duration_min')} min, ${metro.get('total_cost_mxn')} MXN.
UBER: {uber.get('duration_min')} min, ${uber.get('total_cost_mxn')} MXN.
BICI: {bici.get('duration_min')} min, {bici.get('calories_burned')} kcal.

Da 1 recomendación en 1 oración, tono mexicano cálido, considerando costo+salud+tiempo.
Sin emojis excesivos."""

        try:
            llm = LLMService()
            # Usar método simple del LLMService existente
            response = llm._call_gemini(prompt, max_output_tokens=80)
            if response:
                return str(response).strip()
        except Exception as exc:
            logger.debug("LLM call failed: %s", exc)
        return None
