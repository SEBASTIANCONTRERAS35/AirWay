"""
ProfecoScraper: descarga precios diarios de gasolina del PDF oficial
https://combustibles.profeco.gob.mx/qqpgasolina/YYYY/QQPGASOLINA_MMDDYY.pdf

Fase 3 — fallback seguro:
- Si PDF no disponible (fin de semana / cambio de formato), usa dataset JSON estático.
- Si pdfplumber no está instalado, también usa fallback.

Uso:
    scraper = ProfecoScraper()
    stations = scraper.fetch_today()  # retorna lista de dicts
"""
import json
import logging
from datetime import date
from functools import lru_cache
from pathlib import Path

logger = logging.getLogger(__name__)

_STATIONS_FALLBACK_PATH = (
    Path(__file__).resolve().parent.parent.parent / "data" / "fuel_stations_cdmx.json"
)


@lru_cache(maxsize=1)
def _load_fallback() -> list[dict]:
    try:
        with open(_STATIONS_FALLBACK_PATH, encoding="utf-8") as f:
            data = json.load(f)
        return data.get("stations", [])
    except Exception as exc:
        logger.warning("Failed to load fuel stations fallback: %s", exc)
        return []


class ProfecoScraper:
    """Descarga y parsea precios Profeco. Cae a fallback JSON si falla."""

    BASE_URL = "https://combustibles.profeco.gob.mx/qqpgasolina"

    def fetch_today(self) -> list[dict]:
        """Retorna lista de estaciones con estructura consistente."""
        try:
            return self._fetch_live()
        except Exception as exc:
            logger.warning("Profeco live fetch failed, using fallback: %s", exc)
            return _load_fallback()

    def fetch_cached_or_fallback(self) -> list[dict]:
        """Siempre retorna algo: live → cache → fallback JSON."""
        return self.fetch_today() or _load_fallback()

    # ── Live fetch ───────────────────────────────────────────────────────────
    def _fetch_live(self) -> list[dict]:
        """
        Intenta descargar y parsear el PDF del día.
        Si pdfplumber no disponible, raises para caer al fallback.
        """
        try:
            import requests
            import pdfplumber
            import io
        except ImportError as exc:
            raise RuntimeError(f"missing deps for live scrape: {exc}") from exc

        today = date.today()
        url = f"{self.BASE_URL}/{today.year}/QQPGASOLINA_{today.strftime('%m%d%y')}.pdf"

        logger.info("Fetching Profeco PDF: %s", url)
        resp = requests.get(url, timeout=30, headers={
            "User-Agent": "Mozilla/5.0 AirWay/1.0"
        })
        resp.raise_for_status()

        stations = []
        with pdfplumber.open(io.BytesIO(resp.content)) as pdf:
            for page in pdf.pages:
                for table in page.extract_tables() or []:
                    for row in table[1:]:
                        parsed = self._parse_row(row)
                        if parsed:
                            stations.append(parsed)

        if not stations:
            raise RuntimeError("PDF parse returned 0 stations")

        return stations

    @staticmethod
    def _parse_row(row) -> dict | None:
        """Parsea una fila del PDF Profeco. Estructura aproximada."""
        if not row or len(row) < 4:
            return None
        try:
            brand = (row[0] or "").strip()
            address = (row[1] or "").strip()
            magna = _safe_float(row[2])
            premium = _safe_float(row[3]) if len(row) > 3 else None
            diesel = _safe_float(row[4]) if len(row) > 4 else None
            if not brand or not address:
                return None
            return {
                "id": f"{brand}-{hash(address) & 0xFFFF:04x}",
                "brand": brand,
                "name": f"{brand} {address[:30]}",
                "address": address,
                "lat": None,   # geocodear aparte (Fase 3.1)
                "lon": None,
                "magna": magna,
                "premium": premium,
                "diesel": diesel,
            }
        except Exception as exc:
            logger.debug("row parse failed: %s", exc)
            return None


def _safe_float(value) -> float | None:
    if value is None:
        return None
    try:
        return float(str(value).replace(",", ".").strip())
    except (ValueError, TypeError):
        return None
