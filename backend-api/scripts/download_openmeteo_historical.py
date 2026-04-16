#!/usr/bin/env python3
"""
Descarga histórico horario de Open-Meteo (ERA5-based) para CDMX Centro.

Endpoint: https://archive-api.open-meteo.com/v1/archive
Sin API key. Sin registro.

Variables:
- Temperatura 2m, humedad relativa, punto de rocío
- Presión superficial y MSL
- Precipitación, cobertura nubosa (3 niveles)
- Viento 10m y 100m (speed + direction)
- Radiación (shortwave, direct, diffuse)
- Temperatura a 850 hPa y 500 hPa (para gradiente vertical / inversión)
- CAPE (estabilidad atmosférica)

Divide en chunks de 2 años para evitar timeouts/limits.

Uso:
    cd backend-api
    python scripts/download_openmeteo_historical.py

Tiempo estimado: 3-8 minutos. Tamaño: ~15 MB.
"""
from __future__ import annotations

import logging
import sys
import time
from pathlib import Path

import pandas as pd
import requests

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))
from application.ml.config import (  # noqa: E402
    CDMX_CENTER,
    OPENMETEO_ARCHIVE_URL,
    OPENMETEO_FILE,
    RAW_DIR,
)

# Variables de superficie (API archive soporta todas estas)
SURFACE_VARS = [
    "temperature_2m",
    "relative_humidity_2m",
    "dew_point_2m",
    "apparent_temperature",
    "precipitation",
    "rain",
    "snowfall",
    "surface_pressure",
    "pressure_msl",
    "cloud_cover",
    "cloud_cover_low",
    "cloud_cover_mid",
    "cloud_cover_high",
    "wind_speed_10m",
    "wind_speed_100m",
    "wind_direction_10m",
    "wind_direction_100m",
    "wind_gusts_10m",
    "shortwave_radiation",
    "direct_radiation",
    "diffuse_radiation",
    "cape",
    "boundary_layer_height",  # proxy PBLH si está disponible
]

# Variables a niveles de presión (para detectar inversión térmica).
# IMPORTANTE: /v1/archive NO las expone para México (devuelve null silenciosamente).
# Se descargan desde historical-forecast-api, disponible desde 2022.
# Para 2015-2021 se dejan como NaN — XGBoost maneja missing nativamente.
PRESSURE_VARS = [
    "temperature_850hPa",
    "temperature_700hPa",
    "temperature_500hPa",
    "wind_speed_850hPa",
    "wind_speed_500hPa",
    "geopotential_height_850hPa",
    "geopotential_height_500hPa",
]

OPENMETEO_HISTFORECAST_URL = "https://historical-forecast-api.open-meteo.com/v1/forecast"

# Chunks de años para /v1/archive (surface vars, 1940+)
CHUNKS = [
    ("2015-01-01", "2017-12-31"),
    ("2018-01-01", "2020-12-31"),
    ("2021-01-01", "2023-12-31"),
    ("2024-01-01", "2026-04-15"),
]

# Chunks para historical-forecast-api (pressure levels, desde 2022)
CHUNKS_HIST_FORECAST = [
    ("2022-01-01", "2023-12-31"),
    ("2024-01-01", "2026-04-15"),
]


def setup_logger() -> logging.Logger:
    logger = logging.getLogger("openmeteo_dl")
    logger.setLevel(logging.INFO)
    if not logger.handlers:
        h = logging.StreamHandler(sys.stdout)
        h.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
        logger.addHandler(h)
    return logger


def _fetch(url: str, params: dict, logger: logging.Logger, label: str) -> pd.DataFrame:
    logger.info(f"→ {label}")
    t0 = time.time()
    resp = requests.get(url, params=params, timeout=300)
    resp.raise_for_status()
    data = resp.json()
    df = pd.DataFrame(data["hourly"])
    df["time"] = pd.to_datetime(df["time"])
    logger.info(f"✓ {label}: {len(df):,} filas en {time.time() - t0:.1f}s")
    return df


def fetch_chunk(start: str, end: str, logger: logging.Logger) -> pd.DataFrame:
    """Surface vars desde /v1/archive (toda la historia)."""
    params = {
        "latitude": CDMX_CENTER["lat"],
        "longitude": CDMX_CENTER["lon"],
        "start_date": start,
        "end_date": end,
        "hourly": ",".join(SURFACE_VARS),
        "timezone": "America/Mexico_City",
        "windspeed_unit": "ms",
        "temperature_unit": "celsius",
    }
    return _fetch(OPENMETEO_ARCHIVE_URL, params, logger, f"archive {start}→{end} ({len(SURFACE_VARS)} surface vars)")


def fetch_pressure_chunk(start: str, end: str, logger: logging.Logger) -> pd.DataFrame:
    """Pressure-level + boundary layer desde historical-forecast-api (2022+)."""
    params = {
        "latitude": CDMX_CENTER["lat"],
        "longitude": CDMX_CENTER["lon"],
        "start_date": start,
        "end_date": end,
        "hourly": ",".join(PRESSURE_VARS),
        "timezone": "America/Mexico_City",
        "windspeed_unit": "ms",
        "temperature_unit": "celsius",
    }
    return _fetch(
        OPENMETEO_HISTFORECAST_URL, params, logger,
        f"hist-forecast {start}→{end} ({len(PRESSURE_VARS)} pressure vars)"
    )


def main() -> int:
    logger = setup_logger()
    RAW_DIR.mkdir(parents=True, exist_ok=True)

    logger.info(f"Destino: {OPENMETEO_FILE}")
    logger.info(f"Coords: {CDMX_CENTER}")
    logger.info(f"Chunks: {len(CHUNKS)}")
    logger.info("-" * 60)

    # 1) Surface vars — toda la historia (archive-api)
    surface_chunks = []
    for start, end in CHUNKS:
        try:
            surface_chunks.append(fetch_chunk(start, end, logger))
        except requests.exceptions.RequestException as exc:
            logger.error(f"✗ surface chunk {start}-{end} falló: {exc}")
            return 1
    surface = pd.concat(surface_chunks, ignore_index=True).drop_duplicates("time")

    # 2) Pressure / PBLH — solo 2022+ (historical-forecast-api)
    pressure_chunks = []
    for start, end in CHUNKS_HIST_FORECAST:
        try:
            pressure_chunks.append(fetch_pressure_chunk(start, end, logger))
        except requests.exceptions.RequestException as exc:
            logger.warning(f"! pressure chunk {start}-{end} falló (se continúa): {exc}")
    pressure = (
        pd.concat(pressure_chunks, ignore_index=True).drop_duplicates("time")
        if pressure_chunks else pd.DataFrame(columns=["time"])
    )

    # 3) Merge — rows de 2015-2021 tendrán NaN en pressure vars
    df = surface.merge(pressure, on="time", how="left")
    df = df.sort_values("time").reset_index(drop=True)

    # Gradiente vertical — detecta inversión térmica (solo filas con 850hPa)
    if "temperature_850hPa" in df.columns:
        df["dT_dz_850"] = df["temperature_2m"] - df["temperature_850hPa"]
        df["inversion_flag"] = (df["dT_dz_850"] > 0).astype(int)

    df.to_parquet(OPENMETEO_FILE, index=False)
    logger.info("-" * 60)
    logger.info(f"✓ Guardado {len(df):,} filas, {df.shape[1]} columnas")
    logger.info(f"  Rango: {df['time'].min()} → {df['time'].max()}")
    logger.info(f"  Archivo: {OPENMETEO_FILE} ({OPENMETEO_FILE.stat().st_size / 1e6:.1f} MB)")

    if "inversion_flag" in df.columns:
        inv_pct = 100 * df["inversion_flag"].mean()
        logger.info(f"  Inversión térmica: {inv_pct:.1f}% de las horas")

    return 0


if __name__ == "__main__":
    sys.exit(main())
