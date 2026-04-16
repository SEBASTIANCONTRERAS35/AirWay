"""Catálogo CONUEE en memoria para lookup por marca/modelo/año."""
import json
import logging
from functools import lru_cache
from pathlib import Path

logger = logging.getLogger(__name__)

_CATALOG_PATH = Path(__file__).resolve().parent.parent.parent / "data" / "conuee_vehicles_mx.json"


@lru_cache(maxsize=1)
def _load_catalog() -> list[dict]:
    """Carga el catálogo JSON una sola vez."""
    try:
        with open(_CATALOG_PATH, encoding="utf-8") as f:
            data = json.load(f)
        vehicles = data.get("vehicles", [])
        logger.info("conuee_catalog loaded %d vehicles from %s", len(vehicles), _CATALOG_PATH.name)
        return vehicles
    except Exception as exc:
        logger.error("conuee_catalog load failed from %s: %s", _CATALOG_PATH, exc)
        return []


class ConueeCatalog:
    """Lookup helper para matching vehículos."""

    @classmethod
    def all(cls) -> list[dict]:
        return _load_catalog()

    @classmethod
    def makes(cls) -> list[str]:
        """Lista única de marcas."""
        return sorted(set(v["make"] for v in _load_catalog()))

    @classmethod
    def models_for_make(cls, make: str) -> list[str]:
        make = make.lower().strip()
        return sorted(set(
            v["model"] for v in _load_catalog()
            if v["make"].lower() == make
        ))

    @classmethod
    def lookup(cls, make: str, model: str, year: int = None) -> dict | None:
        """Busca el vehículo más cercano (mismo make+model, año más próximo)."""
        logger.debug("conuee_catalog.lookup make=%s model=%s year=%s", make, model, year)
        make = (make or "").lower().strip()
        model = (model or "").lower().strip()
        candidates = [
            v for v in _load_catalog()
            if v["make"].lower() == make and v["model"].lower() == model
        ]
        if not candidates:
            # Fuzzy: solo por model
            candidates = [
                v for v in _load_catalog()
                if v["model"].lower() == model
            ]
            if candidates:
                logger.debug("conuee_catalog.lookup fuzzy match by model only, %d candidates", len(candidates))
        if not candidates:
            logger.info("conuee_catalog.lookup no match for %s %s", make, model)
            return None
        if year is None:
            result = candidates[0]
        else:
            result = min(candidates, key=lambda v: abs(v["year"] - int(year)))
        logger.info("conuee_catalog.lookup matched %s %s %d km/L=%.1f",
                    result["make"], result["model"], result["year"], result["conuee_km_per_l"])
        return result

    @classmethod
    def search(cls, query: str, limit: int = 10) -> list[dict]:
        """Búsqueda simple por substring."""
        q = (query or "").lower().strip()
        if not q:
            return _load_catalog()[:limit]
        matches = [
            v for v in _load_catalog()
            if q in v["make"].lower() or q in v["model"].lower()
        ]
        return matches[:limit]
