"""
VehicleVisionView: identifica vehículo desde foto usando Gemini Vision.

POST /api/v1/vehicle/identify_from_image
Body:
{
  "image": "base64_string",
  "mime_type": "image/jpeg"   (opcional)
}

Response:
{
  "success": bool,
  "type": "dashboard" | "plate" | "exterior" | "sticker" | "unknown",
  "make": "...",
  "model": "...",
  "year_estimate": 2018,
  "odometer_km": 120000,
  "confidence": 0.85,
  "matched_conuee": { ... }  // match del catálogo CONUEE si existe
}
"""
import base64
import logging

from rest_framework import status as http_status
from rest_framework.response import Response
from rest_framework.views import APIView

from adapters.ai.gemini_vision import GeminiVisionClient
from application.fuel.conuee_catalog import ConueeCatalog

logger = logging.getLogger(__name__)


class VehicleVisionView(APIView):
    """Identifica vehículo desde imagen JPEG/PNG."""

    def post(self, request):
        data = request.data or {}
        image_b64 = data.get("image")
        mime_type = data.get("mime_type", "image/jpeg")
        size_kb = (len(image_b64) * 3 / 4 / 1024) if image_b64 else 0
        logger.info("POST /vehicle/identify_from_image mime=%s size=%.1fKB", mime_type, size_kb)

        if not image_b64:
            logger.warning("vehicle_vision 400 missing image")
            return Response(
                {"error": "Campo 'image' (base64) es requerido"},
                status=http_status.HTTP_400_BAD_REQUEST
            )

        # Validar base64
        try:
            # Esto lanza excepción si no es base64 válido
            base64.b64decode(image_b64, validate=True)
        except Exception:
            logger.warning("vehicle_vision 400 invalid base64")
            return Response(
                {"error": "image debe ser base64 válido"},
                status=http_status.HTTP_400_BAD_REQUEST
            )

        client = GeminiVisionClient()
        result = client.identify_vehicle(image_b64=image_b64, mime_type=mime_type)

        # Enriquecer con CONUEE match si hay make/model
        if result.get("success") and result.get("make") and result.get("model"):
            match = ConueeCatalog.lookup(
                make=result["make"],
                model=result["model"],
                year=result.get("year_estimate"),
            )
            if match:
                result["matched_conuee"] = match
                logger.info("vehicle_vision CONUEE match: %s %s %d (%.1f km/L)",
                            match["make"], match["model"], match["year"], match["conuee_km_per_l"])

        logger.info("vehicle_vision 200 success=%s conf=%.2f",
                    result.get("success"), result.get("confidence") or 0)
        return Response(result)
