"""
Unifica RAMA + Open-Meteo + contingencias en un dataset horario para entrenar.

Pipeline:
    1. Lee todos los CSV.gz de RAMA (2015-2026)
    2. Pivota por contaminante: columnas avg/max por hora (agregando todas las estaciones)
    3. Hace inner join con Open-Meteo por timestamp
    4. Agrega flags de contingencias (ground truth)
    5. Guarda parquet listo para feature engineering

Salida: backend-api/data/processed/dataset.parquet
"""
from __future__ import annotations

import logging
import sys
from pathlib import Path

import pandas as pd

if __name__ == "__main__":  # permite correr directo con `python build_dataset.py`
    sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "src"))

from application.ml.config import (
    CONTINGENCIAS_FILE,
    DATASET_FILE,
    OPENMETEO_FILE,
    PROCESSED_DIR,
    RAMA_DIR,
)
from application.ml.rama_reader import read_rama_year

logger = logging.getLogger("build_dataset")


# Parámetros RAMA que nos interesan (nombres normalizados a mayúsculas)
POLLUTANTS = ["O3", "PM25", "PM10", "NO2", "NO", "NOX", "SO2", "CO", "CO2"]


def load_rama_all() -> pd.DataFrame:
    """Lee todos los archivos CSV.gz/zip disponibles de RAMA."""
    files = sorted(RAMA_DIR.glob("contaminantes_*.csv.gz"))
    if not files:
        raise FileNotFoundError(
            f"No hay archivos RAMA en {RAMA_DIR}. "
            f"Corre: python scripts/download_rama_historical.py"
        )

    frames = []
    for path in files:
        logger.info(f"Leyendo {path.name}")
        df = read_rama_year(path)
        if df.empty:
            continue
        # Filtrar solo contaminantes de interés
        df = df[df["parameter"].isin(POLLUTANTS)]
        frames.append(df)

    if not frames:
        raise RuntimeError("Ningún archivo RAMA pudo parsearse.")

    return pd.concat(frames, ignore_index=True)


def pivot_pollutants(rama: pd.DataFrame) -> pd.DataFrame:
    """
    Agrega todas las estaciones por hora. Genera:
      - <POL>_avg (promedio cross-estaciones)
      - <POL>_max (máximo cross-estaciones) <-- este es el que detona contingencia
      - <POL>_n   (cuántas estaciones reportaron)
    """
    agg = (
        rama.groupby(["timestamp", "parameter"])["value"]
        .agg(avg="mean", max="max", n="count")
        .reset_index()
    )

    # Pivota para obtener una columna por (pollutant, stat)
    avg = agg.pivot(index="timestamp", columns="parameter", values="avg").add_suffix("_avg")
    mx = agg.pivot(index="timestamp", columns="parameter", values="max").add_suffix("_max")
    n = agg.pivot(index="timestamp", columns="parameter", values="n").add_suffix("_n")

    result = pd.concat([avg, mx, n], axis=1).reset_index()
    return result


def add_contingency_labels(df: pd.DataFrame) -> pd.DataFrame:
    """Merge con contingencias por fecha. Crea columnas is_fase1_o3 / is_fase1_pm25."""
    df = df.copy()
    df["date"] = df["timestamp"].dt.date

    if not CONTINGENCIAS_FILE.exists():
        logger.warning(
            f"{CONTINGENCIAS_FILE} no existe. "
            f"Corre: python scripts/parse_contingencias_history.py"
        )
        df["is_fase1_o3"] = 0
        df["is_fase1_pm25"] = 0
        df["is_fase1"] = 0
        return df.drop(columns=["date"])

    cont = pd.read_parquet(CONTINGENCIAS_FILE)
    cont["date"] = pd.to_datetime(cont["date"]).dt.date

    o3_dates = set(cont[cont["type"].str.contains("O3", na=False)]["date"])
    pm_dates = set(cont[cont["type"].str.contains("PM", na=False)]["date"])

    df["is_fase1_o3"] = df["date"].isin(o3_dates).astype(int)
    df["is_fase1_pm25"] = df["date"].isin(pm_dates).astype(int)
    df["is_fase1"] = ((df["is_fase1_o3"] + df["is_fase1_pm25"]) > 0).astype(int)

    return df.drop(columns=["date"])


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    logger.info("=" * 60)
    logger.info("Construyendo dataset unificado")
    logger.info("=" * 60)

    # 1. RAMA
    rama = load_rama_all()
    logger.info(f"RAMA: {len(rama):,} observaciones raw")
    pivoted = pivot_pollutants(rama)
    logger.info(f"RAMA pivoteado: {len(pivoted):,} filas horarias × {pivoted.shape[1]} cols")

    # 2. Open-Meteo
    if not OPENMETEO_FILE.exists():
        raise FileNotFoundError(
            f"{OPENMETEO_FILE} no existe. "
            f"Corre: python scripts/download_openmeteo_historical.py"
        )
    meteo = pd.read_parquet(OPENMETEO_FILE)
    meteo = meteo.rename(columns={"time": "timestamp"})
    meteo["timestamp"] = pd.to_datetime(meteo["timestamp"])
    logger.info(f"Open-Meteo: {len(meteo):,} filas × {meteo.shape[1]} cols")

    # 3. Join
    df = pivoted.merge(meteo, on="timestamp", how="inner")
    df = df.sort_values("timestamp").reset_index(drop=True)
    logger.info(f"Join: {len(df):,} filas comunes")

    # 4. Labels
    df = add_contingency_labels(df)
    n_fase1 = df["is_fase1"].sum()
    pct = 100 * n_fase1 / len(df)
    logger.info(f"Contingencias: {n_fase1:,} horas marcadas ({pct:.2f}%)")

    # 5. Guardar
    df.to_parquet(DATASET_FILE, index=False)
    logger.info(f"✓ Guardado {DATASET_FILE} ({DATASET_FILE.stat().st_size / 1e6:.1f} MB)")
    logger.info(f"  Columnas: {df.shape[1]}")
    logger.info(f"  Rango: {df['timestamp'].min()} → {df['timestamp'].max()}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
