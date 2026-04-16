#!/usr/bin/env python3
"""
Descarga archivos horarios anuales de RAMA (SIMAT) 2015-2026.

Fuente: http://datosabiertos.aire.cdmx.gob.mx:8080/opendata/anuales_horarios_gz/
Cada archivo: contaminantes_YYYY.csv.gz — todas las estaciones RAMA, todas las horas.

Características:
- Resumable: si un año ya está en disco, no lo re-descarga.
- Valida gzip al terminar cada descarga.
- Log conciso con tamaño y fecha de cada archivo.

Uso:
    cd backend-api
    python scripts/download_rama_historical.py

Correr en background:
    nohup python scripts/download_rama_historical.py > rama_download.log 2>&1 &

Tiempo estimado: 30 min - 2 horas según conexión. Tamaño total: ~800 MB - 2 GB.
"""
from __future__ import annotations

import gzip
import logging
import sys
import time
from pathlib import Path

import requests

# Permitir importar config sin instalar el paquete
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))
from application.ml.config import RAMA_BASE_URL, RAMA_DIR  # noqa: E402

# Años a descargar. 2015+ cubre 12 años (suficiente para train/val/test).
# 2025 y 2026 aún no están publicados anualmente por CDMX (estos años en curso).
# Se bajarán via el endpoint diferente o diariamente durante inferencia.
YEARS = list(range(2015, 2025))

# Timeout por request (segundos). Archivos son 50-200 MB.
TIMEOUT = 600


def setup_logger() -> logging.Logger:
    logger = logging.getLogger("rama_download")
    logger.setLevel(logging.INFO)
    if not logger.handlers:
        h = logging.StreamHandler(sys.stdout)
        h.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
        logger.addHandler(h)
    return logger


def validate_archive(path: Path) -> bool:
    """
    Valida que el archivo sea un archivo comprimido legible.

    CDMX devuelve inconsistente: algunos años son gzip real (magic 1F 8B),
    otros (2022+) son ZIP con extensión engañosa .csv.gz (magic PK).
    Aceptamos ambos — el parser downstream los distingue.
    """
    try:
        with path.open("rb") as f:
            magic = f.read(4)
        # gzip: 1F 8B
        if magic[:2] == b"\x1f\x8b":
            with gzip.open(path, "rt", errors="replace") as f:
                f.read(1024)
            return True
        # zip: 50 4B 03 04
        if magic[:4] == b"PK\x03\x04":
            import zipfile
            with zipfile.ZipFile(path) as zf:
                names = zf.namelist()
                if not names:
                    return False
                with zf.open(names[0]) as f:
                    f.read(1024)
            return True
        return False
    except (OSError, EOFError, gzip.BadGzipFile, Exception):
        return False


# Alias para compatibilidad si algo más lo importaba
validate_gzip = validate_archive


def download_year(year: int, logger: logging.Logger) -> bool:
    url = f"{RAMA_BASE_URL}/contaminantes_{year}.csv.gz"
    out_path = RAMA_DIR / f"contaminantes_{year}.csv.gz"

    if out_path.exists():
        size_mb = out_path.stat().st_size / 1_000_000
        if validate_archive(out_path):
            logger.info(f"✓ {year}: ya existe ({size_mb:.1f} MB, válido)")
            return True
        logger.warning(f"✗ {year}: archivo corrupto, re-descargando")
        out_path.unlink()

    logger.info(f"→ {year}: descargando de {url}")
    start = time.time()
    try:
        with requests.get(url, timeout=TIMEOUT, stream=True) as resp:
            resp.raise_for_status()
            with out_path.open("wb") as f:
                for chunk in resp.iter_content(chunk_size=1_048_576):
                    if chunk:
                        f.write(chunk)
    except requests.exceptions.RequestException as exc:
        logger.error(f"✗ {year}: error HTTP — {exc}")
        if out_path.exists():
            out_path.unlink()
        return False

    elapsed = time.time() - start
    size_mb = out_path.stat().st_size / 1_000_000

    if not validate_archive(out_path):
        logger.error(f"✗ {year}: descarga OK pero archivo corrupto — borrado")
        out_path.unlink()
        return False

    logger.info(f"✓ {year}: {size_mb:.1f} MB en {elapsed:.0f}s")
    return True


def main() -> int:
    logger = setup_logger()
    RAMA_DIR.mkdir(parents=True, exist_ok=True)

    logger.info(f"Destino: {RAMA_DIR}")
    logger.info(f"Años: {YEARS[0]}-{YEARS[-1]} ({len(YEARS)} archivos)")
    logger.info("-" * 60)

    ok = sum(download_year(y, logger) for y in YEARS)

    logger.info("-" * 60)
    logger.info(f"Completado: {ok}/{len(YEARS)} archivos")

    if ok < len(YEARS):
        logger.warning("Algunos años fallaron. Revisa conexión y vuelve a correr.")
        return 1

    total_mb = sum(p.stat().st_size for p in RAMA_DIR.glob("*.csv.gz")) / 1_000_000
    logger.info(f"Tamaño total: {total_mb:.1f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
