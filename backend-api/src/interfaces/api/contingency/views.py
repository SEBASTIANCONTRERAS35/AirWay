# backend/interfaces/api/contingency/views.py
#
# ContingencyCast — Endpoint de pronóstico probabilístico de contingencias
# ambientales en la ZMVM.
#
# Devuelve para horizontes h+24, h+48, h+72:
#   - Probabilidad calibrada de Fase 1 O3 (según umbral CAMe 154 ppb)
#   - Valor esperado + intervalo de confianza 80% (q10, q50, q90)
#   - Top drivers para generar explicación en cliente
#
# Ventaja vs SEDEMA: SEDEMA solo pronostica 24h, actualiza 1 vez al día.
# Nosotros: 72h, probabilidad calibrada, cada request.
#
import logging
from datetime import datetime, timezone
from typing import Any

from rest_framework import status as http_status
from rest_framework.response import Response
from rest_framework.views import APIView

from application.ml.config import CDMX_CENTER
from application.ml.inference import get_predictor

logger = logging.getLogger(__name__)


def _recommendations(prob: float, hologram: str | None = None) -> list[str]:
    """Acciones sugeridas según probabilidad + perfil del usuario."""
    recs: list[str] = []

    if prob >= 0.7:
        recs.append("Carga gasolina HOY (posible Doble Hoy No Circula mañana).")
        recs.append("Considera home office o carpool.")
        recs.append("Lleva cubrebocas N95 si sales al exterior.")
        if hologram == "2":
            recs.insert(0, "Tu auto (holograma 2) NO circulará mañana.")
        elif hologram in {"0", "00"}:
            recs.append("Aunque tengas holograma 0/00, en contingencia también te restringen.")
    elif prob >= 0.4:
        recs.append("Monitoreo activo: la probabilidad puede subir en próximas horas.")
        recs.append("Ten plan B para transporte mañana.")
    else:
        recs.append("Día estable esperado. Actividades normales.")

    return recs


class ContingencyForecastView(APIView):
    """
    GET /api/v1/contingency/forecast?lat=19.4326&lon=-99.1332&hologram=2

    Query params:
        lat, lon     — coordenadas (default: CDMX Centro)
        hologram     — "0", "00", "1", "2" (opcional, para personalizar recomendaciones)
    """

    def get(self, request):
        try:
            lat = float(request.query_params.get("lat", CDMX_CENTER["lat"]))
            lon = float(request.query_params.get("lon", CDMX_CENTER["lon"]))
        except (TypeError, ValueError):
            return Response(
                {"error": "Parámetros inválidos. Usa 'lat' y 'lon' numéricos."},
                status=http_status.HTTP_400_BAD_REQUEST,
            )

        hologram = request.query_params.get("hologram")

        try:
            predictor = get_predictor()
            result = predictor.predict_now(lat=lat, lon=lon)
        except FileNotFoundError as exc:
            logger.error(f"Modelos no entrenados: {exc}")
            return Response(
                {
                    "error": "Modelos de pronóstico no disponibles.",
                    "hint": "Entrena los modelos: python -m application.ml.train_quantile",
                },
                status=http_status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        except Exception as exc:
            logger.exception("Error en inferencia")
            return Response(
                {"error": f"Error en inferencia: {exc}"},
                status=http_status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        forecasts_payload: list[dict[str, Any]] = []
        for hf in result.forecasts:
            forecasts_payload.append(
                {
                    "horizon_h": hf.horizon_h,
                    "prob_fase1_o3": hf.prob_fase1_o3,
                    "prob_uncalibrated": hf.prob_uncalibrated,
                    "o3_expected_ppb": hf.o3_expected,
                    "o3_ci80_ppb": hf.o3_ci80,
                    "top_drivers": hf.top_drivers,
                    "recommendations": _recommendations(hf.prob_fase1_o3, hologram),
                }
            )

        return Response(
            {
                "timestamp": result.timestamp,
                "location": result.location,
                "forecasts": forecasts_payload,
                "explanation_hint": result.explanation_hint,
                "model_version": result.model_version,
                "disclaimer": (
                    "Pronóstico estimado basado en modelos de machine learning. "
                    "No sustituye el aviso oficial de la Comisión Ambiental de la Megalópolis (CAMe)."
                ),
            }
        )


class ContingencyHealthView(APIView):
    """Check de disponibilidad del modelo."""

    def get(self, request):
        try:
            predictor = get_predictor()
            horizons_loaded = list(predictor.quantile_models.keys())
            return Response(
                {
                    "status": "ready" if horizons_loaded else "not_loaded",
                    "horizons_h": horizons_loaded,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                }
            )
        except Exception as exc:
            return Response(
                {"status": "error", "error": str(exc)},
                status=http_status.HTTP_503_SERVICE_UNAVAILABLE,
            )
