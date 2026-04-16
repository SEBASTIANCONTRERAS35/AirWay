"""
Feature engineering para ContingencyCast.

Transforma el dataset unificado (RAMA + Open-Meteo) en una matriz lista para ML.

Features generados:
    - Lags de contaminantes (1, 3, 6, 12, 24, 48, 72, 168h)
    - Rolling statistics (mean, max, std en ventanas de 6, 12, 24, 72h)
    - Tendencias (diferencias respecto a horas pasadas)
    - Encoding cíclico de hora/día/mes (sin/cos)
    - Interacciones fotoquímicas (T × radiación, PBLH × viento)
    - Inversión térmica (dT_dz, flag binario)
    - Estancamiento (viento bajo)
    - Banderas estacionales (temporada ozono, PM, fin de semana)
    - Targets (y_24h, y_48h, y_72h) = contingencia probable en próximas N horas

Uso:
    from application.ml.features import add_all_features, TARGETS, FEATURES

    df = pd.read_parquet(DATASET_FILE)
    df_feat = add_all_features(df)
    X = df_feat[FEATURES]
    y = df_feat[TARGETS[24]]   # target binario para h+24
"""
from __future__ import annotations

import logging
from pathlib import Path

import numpy as np
import pandas as pd

from application.ml.config import (
    DATASET_FILE,
    FEATURES_FILE,
    FORECAST_HORIZONS,
    OZONE_SEASON_MONTHS,
    PM_SEASON_MONTHS,
    THRESHOLD_O3_FASE1_PPB,
    THRESHOLD_PM25_FASE1_UGM3,
)

logger = logging.getLogger("features")


# =========================================================================
# Constantes de feature engineering
# =========================================================================

LAG_HOURS = [1, 3, 6, 12, 24, 48, 72, 168]
ROLLING_WINDOWS = [6, 12, 24, 72]
KEY_POLLUTANTS = ["O3", "PM25", "PM10", "NO2", "CO"]

# Targets generados (nombres usados por downstream)
TARGETS = {h: f"y_{h}h" for h in FORECAST_HORIZONS}


# =========================================================================
# Transformaciones individuales
# =========================================================================

def add_pollutant_lags(df: pd.DataFrame) -> pd.DataFrame:
    """Agrega lags temporales de pollutants key."""
    df = df.copy()
    for pol in KEY_POLLUTANTS:
        for stat in ["max", "avg"]:
            col = f"{pol}_{stat}"
            if col in df.columns:
                for lag in LAG_HOURS:
                    df[f"{col}_lag_{lag}"] = df[col].shift(lag)
    return df


def add_rolling_stats(df: pd.DataFrame) -> pd.DataFrame:
    """Rolling mean/max/std sobre ventanas."""
    df = df.copy()
    for pol in KEY_POLLUTANTS:
        col = f"{pol}_max"
        if col not in df.columns:
            continue
        for w in ROLLING_WINDOWS:
            df[f"{col}_roll_mean_{w}"] = df[col].rolling(w, min_periods=1).mean()
            df[f"{col}_roll_max_{w}"] = df[col].rolling(w, min_periods=1).max()
            df[f"{col}_roll_std_{w}"] = df[col].rolling(w, min_periods=2).std()
    return df


def add_trend_features(df: pd.DataFrame) -> pd.DataFrame:
    """Diferencias (tendencias) 3h y 24h."""
    df = df.copy()
    for pol in KEY_POLLUTANTS:
        col = f"{pol}_max"
        if col in df.columns:
            df[f"{col}_trend_3h"] = df[col] - df[col].shift(3)
            df[f"{col}_trend_24h"] = df[col] - df[col].shift(24)
    return df


def add_cyclical_encoding(df: pd.DataFrame) -> pd.DataFrame:
    """Encoding sin/cos para hora, día de semana, día del año, mes."""
    df = df.copy()
    ts = df["timestamp"]

    df["hour_sin"] = np.sin(2 * np.pi * ts.dt.hour / 24)
    df["hour_cos"] = np.cos(2 * np.pi * ts.dt.hour / 24)

    df["dow_sin"] = np.sin(2 * np.pi * ts.dt.dayofweek / 7)
    df["dow_cos"] = np.cos(2 * np.pi * ts.dt.dayofweek / 7)

    df["doy_sin"] = np.sin(2 * np.pi * ts.dt.dayofyear / 365.25)
    df["doy_cos"] = np.cos(2 * np.pi * ts.dt.dayofyear / 365.25)

    df["month_sin"] = np.sin(2 * np.pi * ts.dt.month / 12)
    df["month_cos"] = np.cos(2 * np.pi * ts.dt.month / 12)

    return df


def add_wind_components(df: pd.DataFrame) -> pd.DataFrame:
    """Descompone viento en componentes u (E-W) y v (N-S)."""
    df = df.copy()
    if {"wind_speed_10m", "wind_direction_10m"}.issubset(df.columns):
        rad = np.radians(df["wind_direction_10m"])
        df["u_wind"] = df["wind_speed_10m"] * np.cos(rad)
        df["v_wind"] = df["wind_speed_10m"] * np.sin(rad)
        df["wdir_sin"] = np.sin(rad)
        df["wdir_cos"] = np.cos(rad)
    return df


def add_interactions(df: pd.DataFrame) -> pd.DataFrame:
    """Interacciones no-lineales clave para O3 y PM."""
    df = df.copy()

    # Fotoquímica: T × radiación drives ozone formation
    if {"temperature_2m", "shortwave_radiation"}.issubset(df.columns):
        df["T_x_rad"] = df["temperature_2m"] * df["shortwave_radiation"]

    # Ventilación: PBLH × viento dispersa la contaminación
    if {"boundary_layer_height", "wind_speed_10m"}.issubset(df.columns):
        df["vent_idx"] = df["boundary_layer_height"] * df["wind_speed_10m"]

    # Estancamiento: viento bajo + PBLH bajo = peor acumulación
    if {"wind_speed_10m", "boundary_layer_height"}.issubset(df.columns):
        df["stagnation"] = (
            (df["wind_speed_10m"] < 2) & (df["boundary_layer_height"] < 500)
        ).astype(int)
    elif "wind_speed_10m" in df.columns:
        df["stagnation"] = (df["wind_speed_10m"] < 2).astype(int)

    # Higroscopicidad: humedad alta infla partículas
    if "relative_humidity_2m" in df.columns:
        df["rh_above_75"] = (df["relative_humidity_2m"] > 75).astype(int)

    # Radiación al cuadrado (no-linealidad fotoquímica)
    if "shortwave_radiation" in df.columns:
        df["rad_squared"] = df["shortwave_radiation"] ** 2

    return df


def add_inversion_features(df: pd.DataFrame) -> pd.DataFrame:
    """Gradiente vertical de temperatura = detector de inversión térmica."""
    df = df.copy()
    if "dT_dz_850" not in df.columns and {"temperature_2m", "temperature_850hPa"}.issubset(df.columns):
        df["dT_dz_850"] = df["temperature_2m"] - df["temperature_850hPa"]
    if "inversion_flag" not in df.columns and "dT_dz_850" in df.columns:
        df["inversion_flag"] = (df["dT_dz_850"] > 0).astype(int)
    return df


def add_seasonal_flags(df: pd.DataFrame) -> pd.DataFrame:
    """Flags de temporada y calendario."""
    df = df.copy()
    month = df["timestamp"].dt.month
    dow = df["timestamp"].dt.dayofweek

    df["is_ozone_season"] = month.isin(OZONE_SEASON_MONTHS).astype(int)
    df["is_pm_season"] = month.isin(PM_SEASON_MONTHS).astype(int)
    df["is_weekend"] = (dow >= 5).astype(int)
    df["is_monday"] = (dow == 0).astype(int)

    return df


def add_targets(df: pd.DataFrame) -> pd.DataFrame:
    """
    Target binario: ¿habrá contingencia Fase 1 en próximas H horas?

    Se activa por cualquier contaminante según PCAA 2019:
        y_{H}h = 1 si en las próximas H horas:
            max(O3) > 154 ppb  OR  max(PM2.5) > 97.4 µg/m³

    (Coincide con activación real CAMe: O3 Fase 1 O bien PM2.5 Fase 1.)
    """
    df = df.copy()
    if "O3_max" not in df.columns:
        logger.warning("O3_max no existe, no se pueden generar targets")
        return df

    for h in FORECAST_HORIZONS:
        # Futuro O3: max de t+1 a t+h
        future_o3 = (
            df["O3_max"].shift(-1).rolling(h, min_periods=1).max().shift(-(h - 1))
        )
        hit_o3 = future_o3 > THRESHOLD_O3_FASE1_PPB

        # Futuro PM2.5 (si existe)
        if "PM25_max" in df.columns:
            future_pm25 = (
                df["PM25_max"].shift(-1).rolling(h, min_periods=1).max().shift(-(h - 1))
            )
            hit_pm25 = future_pm25 > THRESHOLD_PM25_FASE1_UGM3
            df[TARGETS[h]] = (hit_o3 | hit_pm25).astype(int)
        else:
            df[TARGETS[h]] = hit_o3.astype(int)

    return df


# =========================================================================
# Pipeline completo
# =========================================================================

def add_all_features(df: pd.DataFrame) -> pd.DataFrame:
    """Aplica todas las transformaciones en orden."""
    logger.info("Feature engineering: start")
    df = df.sort_values("timestamp").reset_index(drop=True)

    df = add_pollutant_lags(df)
    logger.info(f"  + lags: {df.shape[1]} cols")

    df = add_rolling_stats(df)
    logger.info(f"  + rolling: {df.shape[1]} cols")

    df = add_trend_features(df)
    df = add_cyclical_encoding(df)
    df = add_wind_components(df)
    df = add_interactions(df)
    df = add_inversion_features(df)
    df = add_seasonal_flags(df)
    df = add_targets(df)
    logger.info(f"  final: {df.shape[1]} cols")

    return df


def feature_columns(df: pd.DataFrame) -> list[str]:
    """Lista de columnas usables como features (excluye target, timestamp, identifiers)."""
    excluded = set()
    excluded.update(TARGETS.values())
    excluded.update(["timestamp", "time", "date", "is_fase1", "is_fase1_o3", "is_fase1_pm25"])
    excluded.update([c for c in df.columns if c.startswith("y_")])

    return [
        c for c in df.columns
        if c not in excluded and pd.api.types.is_numeric_dtype(df[c])
    ]


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    if not DATASET_FILE.exists():
        raise FileNotFoundError(
            f"{DATASET_FILE} no existe. Corre: python -m application.ml.build_dataset"
        )

    df = pd.read_parquet(DATASET_FILE)
    logger.info(f"Input: {len(df):,} filas × {df.shape[1]} cols")

    df_feat = add_all_features(df)
    df_feat = df_feat.dropna(subset=[TARGETS[max(FORECAST_HORIZONS)]])
    logger.info(f"Output: {len(df_feat):,} filas × {df_feat.shape[1]} cols")

    for h in FORECAST_HORIZONS:
        pos = int(df_feat[TARGETS[h]].sum())
        pct = 100 * pos / len(df_feat)
        logger.info(f"  y_{h}h positivos: {pos:,} ({pct:.2f}%)")

    df_feat.to_parquet(FEATURES_FILE, index=False)
    logger.info(f"✓ Guardado {FEATURES_FILE} ({FEATURES_FILE.stat().st_size / 1e6:.1f} MB)")

    cols = feature_columns(df_feat)
    logger.info(f"  Features utilizables: {len(cols)}")

    return 0


if __name__ == "__main__":
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "src"))
    sys.exit(main())
