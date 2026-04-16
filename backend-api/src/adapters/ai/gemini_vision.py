"""
GeminiVisionClient: identificación de vehículos desde imágenes.

Usa Gemini 2.5 Flash con multimodal vision para extraer marca/modelo/odómetro
desde fotos del tablero, placa o vista exterior del auto.

Reusa la API key existente (env GEMINI_API_KEY).
"""
import base64
import json
import logging
import os
from typing import Optional

import requests

logger = logging.getLogger(__name__)

GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models"

VISION_PROMPT = """Analiza esta imagen de un vehículo mexicano. Puede ser:
- Tablero (dashboard / odómetro)
- Placa mexicana (7 caracteres)
- Vista exterior del auto
- Calcomanía Hoy No Circula (color holograma)

Responde SOLO con JSON válido (sin markdown, sin explicaciones extra):
{
  "type": "dashboard" | "plate" | "exterior" | "sticker" | "unknown",
  "make": "marca inferida o null",
  "model": "modelo inferido o null",
  "year_estimate": año_aproximado_o_null,
  "odometer_km": kilometraje_o_null,
  "plate_number": "placa_detectada_o_null",
  "holograma": "00|0|1|2|EXENTO|null",
  "confidence": 0.0_a_1.0,
  "notes": "observación breve"
}

Si no reconoces nada, responde con type=unknown y confidence bajo."""


class GeminiVisionClient:
    """Cliente minimal para vision usando Gemini REST API."""

    def __init__(self, model: Optional[str] = None, api_key: Optional[str] = None):
        self.api_key = api_key or os.environ.get("GEMINI_API_KEY", "")
        self.model = model or os.environ.get("GEMINI_VISION_MODEL", "gemini-2.5-flash")
        self.timeout = int(os.environ.get("GEMINI_VISION_TIMEOUT", "45"))

    def identify_vehicle(self, image_bytes: bytes = None, image_b64: str = None,
                          mime_type: str = "image/jpeg") -> dict:
        """
        Analiza una imagen y retorna identificación estructurada.
        Acepta bytes o base64.
        """
        if not self.api_key:
            logger.error("gemini_vision GEMINI_API_KEY not set")
            return self._error_response("GEMINI_API_KEY no configurada")

        if image_bytes is None and image_b64 is None:
            return self._error_response("image_bytes o image_b64 requerido")

        if image_b64 is None:
            image_b64 = base64.b64encode(image_bytes).decode("ascii")

        image_size_kb = len(image_b64) * 3 / 4 / 1024  # base64 → bytes approx
        logger.info("gemini_vision.identify_vehicle model=%s mime=%s size=%.1fKB timeout=%ds",
                    self.model, mime_type, image_size_kb, self.timeout)

        url = f"{GEMINI_API_URL}/{self.model}:generateContent?key={self.api_key}"

        payload = {
            "contents": [{
                "parts": [
                    {"inline_data": {"mime_type": mime_type, "data": image_b64}},
                    {"text": VISION_PROMPT},
                ]
            }],
            "generationConfig": {
                "responseMimeType": "application/json",
                "temperature": 0.2,
                "maxOutputTokens": 400,
            }
        }

        import time
        start_t = time.time()
        try:
            resp = requests.post(
                url, json=payload, timeout=self.timeout,
                headers={"Content-Type": "application/json"}
            )
            resp.raise_for_status()
            data = resp.json()
            elapsed_ms = (time.time() - start_t) * 1000
            logger.debug("gemini_vision HTTP %d in %.0fms", resp.status_code, elapsed_ms)
        except requests.exceptions.Timeout:
            logger.warning("gemini_vision timeout after %ds", self.timeout)
            return self._error_response("Gemini timeout")
        except requests.exceptions.HTTPError as exc:
            logger.warning("gemini_vision HTTP error status=%s: %s",
                           resp.status_code if 'resp' in dir() else '?', exc)
            return self._error_response(f"HTTP {resp.status_code}: {resp.text[:200]}")
        except Exception as exc:
            logger.exception("gemini_vision call failed")
            return self._error_response(str(exc))

        # Extraer texto
        try:
            candidates = data.get("candidates", [])
            if not candidates:
                logger.warning("gemini_vision empty candidates")
                return self._error_response("empty candidates from Gemini")
            parts = candidates[0].get("content", {}).get("parts", [])
            text = "".join(p.get("text", "") for p in parts).strip()
            if not text:
                return self._error_response("empty text from Gemini")
            parsed = json.loads(text)
            logger.info(
                "gemini_vision OK type=%s make=%s model=%s year=%s conf=%.2f",
                parsed.get("type"), parsed.get("make"), parsed.get("model"),
                parsed.get("year_estimate"), parsed.get("confidence") or 0,
            )
            return {"success": True, **parsed}
        except json.JSONDecodeError:
            logger.warning("gemini_vision invalid JSON response: %s", text[:200])
            return self._error_response(f"invalid JSON from Gemini: {text[:200]}")
        except Exception as exc:
            logger.exception("gemini_vision parse failed")
            return self._error_response(f"response parse failed: {exc}")

    @staticmethod
    def _error_response(msg: str) -> dict:
        return {
            "success": False,
            "error": msg,
            "type": "unknown",
            "confidence": 0.0,
            "notes": msg,
        }
