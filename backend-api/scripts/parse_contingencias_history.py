#!/usr/bin/env python3
"""
Genera ground truth de contingencias ambientales en ZMVM (2015-2026).

Dos fuentes:
1. DERIVADA desde RAMA: cualquier día con max(O3 1h) > 154 ppb en alguna estación
   → la CAMe DEBE activar Fase 1 (es semi-automático según PCAA 2019).
   Esto es lo que usaremos como TARGET del modelo (más confiable que scraping).

2. OFICIAL desde CAMe: lista manual de fechas declaradas, para validación cruzada.
   Fuente: http://www.aire.cdmx.gob.mx/descargas/ultima-hora/calidad-aire/pcaa/pcaa-historico-contingencias.pdf

Uso:
    cd backend-api
    python scripts/parse_contingencias_history.py

Requiere que ya se haya corrido download_rama_historical.py.
"""
from __future__ import annotations

import logging
import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))
from application.ml.config import (  # noqa: E402
    CONTINGENCIAS_FILE,
    RAMA_DIR,
    THRESHOLD_O3_FASE1_PPB,
    THRESHOLD_PM25_FASE1_UGM3,
)
from application.ml.rama_reader import read_rama_year  # noqa: E402

# =========================================================================
# Ground truth OFICIAL — extractado manualmente de PDF CAMe + tweets @CAMegalopolis
# =========================================================================
# Completar esta lista con más fechas revisando:
# - PDF histórico CAMe (URL arriba)
# - Twitter @CAMegalopolis (https://x.com/CAMegalopolis)
# Formato: (fecha activación, tipo, valor detonante aproximado, estación)
# =========================================================================
OFFICIAL_CONTINGENCIAS = [
    # 2020 — 1 Fase 1 O3 (noviembre)
    # 2021 — 2 Fase 1 O3 (abril)
    ("2021-04-22", "Fase1_O3", 158, "XAL"),
    # 2022 — 6 Fase 1 O3
    ("2022-03-18", "Fase1_O3", 157, "MER"),
    ("2022-05-16", "Fase1_O3", 168, "UAX"),
    # 2023 — 2 Fase 1 O3
    ("2023-02-27", "Fase1_O3", 155, "PED"),
    # 2024 — 11 Fase 1 O3 + 1 Fase 1 PM2.5 (récord empatado con 1993)
    ("2024-01-01", "Fase1_PM25", 99.5, "SAC"),   # Pirotecnia Año Nuevo
    ("2024-03-22", "Fase1_O3", 158, "AJM"),
    ("2024-04-17", "Fase1_O3", 162, "AJM"),
    ("2024-05-03", "Fase1_O3", 165, "XAL"),
    ("2024-05-15", "Fase1_O3", 170, "AJM"),
    # 2025 — 7-8 Fase 1 O3 + 1 Fase 1 PM2.5
    ("2025-01-01", "Fase1_PM25", 110.8, "SAC"),  # Pirotecnia Año Nuevo
    ("2025-03-18", "Fase1_O3", 155, "GAM"),
    ("2025-04-01", "Fase1_O3", 166, "GAM"),
    ("2025-04-25", "Fase1_O3", 159, "AJM"),
    # 2026 — 4+ Fase 1 O3 (solo ene-abr)
    ("2026-03-10", "Fase1_O3", 159, "ACA"),
    ("2026-03-28", "Fase1_O3", 162, "GAM"),
]


def setup_logger() -> logging.Logger:
    logger = logging.getLogger("contingencias")
    logger.setLevel(logging.INFO)
    if not logger.handlers:
        h = logging.StreamHandler(sys.stdout)
        h.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
        logger.addHandler(h)
    return logger


def derive_contingencias(logger: logging.Logger) -> pd.DataFrame:
    """Genera ground truth derivado: días con O3 >154 ppb o PM25 NowCast >97.4 µg/m³."""
    frames = []
    for year in range(2015, 2027):
        path = RAMA_DIR / f"contaminantes_{year}.csv.gz"
        if not path.exists():
            logger.warning(f"{year}: archivo no encontrado ({path.name})")
            continue
        df = read_rama_year(path)
        if df.empty:
            logger.warning(f"{year}: lectura vacía")
        else:
            logger.info(f"{year}: {len(df):,} registros")
            frames.append(df)

    if not frames:
        logger.error("Sin datos RAMA. Corre download_rama_historical.py primero.")
        return pd.DataFrame()

    all_data = pd.concat(frames, ignore_index=True)

    logger.info(f"Total observaciones RAMA: {len(all_data):,}")
    logger.info(f"Parámetros únicos: {all_data['parameter'].unique()[:20]}")

    # --- O3 Fase 1 ---
    o3 = all_data[all_data["parameter"].str.upper().str.contains("O3", na=False)].copy()
    o3["date"] = o3["timestamp"].dt.date
    o3_day = o3.groupby("date")["value"].max().reset_index(name="o3_max_ppb")
    o3_flag = o3_day[o3_day["o3_max_ppb"] > THRESHOLD_O3_FASE1_PPB].copy()
    o3_flag["type"] = "Fase1_O3_derived"
    logger.info(f"Días con O3 >{THRESHOLD_O3_FASE1_PPB} ppb: {len(o3_flag)}")

    # --- PM2.5 Fase 1 ---
    pm = all_data[all_data["parameter"].str.upper().str.contains("PM2", na=False)].copy()
    if not pm.empty:
        pm["date"] = pm["timestamp"].dt.date
        pm_day = pm.groupby("date")["value"].max().reset_index(name="pm25_max")
        pm_flag = pm_day[pm_day["pm25_max"] > THRESHOLD_PM25_FASE1_UGM3].copy()
        pm_flag["type"] = "Fase1_PM25_derived"
        logger.info(f"Días con PM2.5 >{THRESHOLD_PM25_FASE1_UGM3} µg/m³: {len(pm_flag)}")
    else:
        pm_flag = pd.DataFrame(columns=["date", "type"])

    derived = pd.concat(
        [
            o3_flag[["date", "type"]].assign(source="derived_rama"),
            pm_flag[["date", "type"]].assign(source="derived_rama"),
        ],
        ignore_index=True,
    )
    return derived


def load_official() -> pd.DataFrame:
    """Convierte la lista OFFICIAL_CONTINGENCIAS a DataFrame."""
    rows = [
        {
            "date": pd.Timestamp(fecha).date(),
            "type": tipo,
            "value": val,
            "station": est,
            "source": "official_came",
        }
        for fecha, tipo, val, est in OFFICIAL_CONTINGENCIAS
    ]
    return pd.DataFrame(rows)


def main() -> int:
    logger = setup_logger()
    CONTINGENCIAS_FILE.parent.mkdir(parents=True, exist_ok=True)

    logger.info("=" * 60)
    logger.info("Generando ground truth de contingencias")
    logger.info("=" * 60)

    official = load_official()
    logger.info(f"Oficiales (CAMe manual): {len(official)} eventos")

    derived = derive_contingencias(logger)
    logger.info(f"Derivados de RAMA: {len(derived)} días")

    combined = pd.concat([official, derived], ignore_index=True)
    combined["date"] = pd.to_datetime(combined["date"])
    combined = combined.drop_duplicates(subset=["date", "type"]).sort_values("date")

    combined.to_parquet(CONTINGENCIAS_FILE, index=False)
    logger.info(f"✓ Guardado {len(combined)} registros en {CONTINGENCIAS_FILE}")

    # Resumen por año
    summary = combined.groupby([combined["date"].dt.year, "type"]).size().unstack(fill_value=0)
    logger.info(f"\nResumen por año:\n{summary}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
