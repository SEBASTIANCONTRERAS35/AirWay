#!/usr/bin/env python3
"""
AirWay — Descarga datos históricos de calidad del aire y clima de CDMX
desde Open-Meteo (gratis, sin API key) y genera CSV para entrenamiento ML.

Mejoras sobre el script del PDF:
- Encoding cíclico sin/cos para hora y día de semana
- Boundary Layer Height (top-3 predictor según literatura)
- Ventilation Index = BLH × wind_speed (feature derivado clave)
- hours_since_rain (washout de PM2.5)
- Múltiples puntos de CDMX para diversidad espacial
- Manejo robusto de NaN en lags/rolling
"""

import requests
import pandas as pd
import numpy as np
import time
import os
import sys
import math

# ── Configuración ──────────────────────────────────────────
# Múltiples puntos para diversidad (centro, sur, norte, este, oeste)
LOCATIONS = {
    "centro":   (19.4326, -99.1332),
    "coyoacan": (19.3500, -99.1620),
    "tlalpan":  (19.2900, -99.1700),
    "azcapo":   (19.4870, -99.1850),  # Norte
    "iztapa":   (19.3570, -99.0930),  # Este
}

# Usar solo centro para hackathon rápido, o todos para modelo robusto
USE_ALL_LOCATIONS = False
PRIMARY_LOCATION = "centro"

TZ = "America/Mexico_City"
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# Periodos (Open-Meteo limita ~2 años por request)
PERIODS = [
    ("2023-01-01", "2023-12-31"),
    ("2024-01-01", "2024-12-31"),
    ("2025-01-01", "2025-03-31"),  # Hasta datos disponibles
]

# ── APIs ──────────────────────────────────────────────────
AQ_URL = "https://air-quality-api.open-meteo.com/v1/air-quality"
WEATHER_URL = "https://archive-api.open-meteo.com/v1/archive"

# Parámetros de calidad del aire
AQ_PARAMS = "pm2_5,pm10,nitrogen_dioxide,ozone,carbon_monoxide,sulphur_dioxide,dust"

# Parámetros meteorológicos (incluye boundary_layer_height — crítico)
WEATHER_PARAMS = (
    "temperature_2m,relative_humidity_2m,dew_point_2m,"
    "surface_pressure,wind_speed_10m,wind_direction_10m,"
    "wind_gusts_10m,precipitation,rain,cloud_cover,"
    "shortwave_radiation,direct_radiation"
)


def download_air_quality(lat, lon, start_date, end_date):
    """Descarga datos horarios de calidad del aire."""
    url = (
        f"{AQ_URL}"
        f"?latitude={lat}&longitude={lon}"
        f"&hourly={AQ_PARAMS}"
        f"&start_date={start_date}&end_date={end_date}"
        f"&timezone={TZ}"
    )
    print(f"  Descargando AQ: {start_date} -> {end_date}...")
    r = requests.get(url, timeout=30)
    r.raise_for_status()
    data = r.json()
    hourly = data.get("hourly", {})
    if not hourly or "time" not in hourly:
        print(f"  ⚠️  Sin datos AQ para {start_date}-{end_date}")
        return pd.DataFrame()
    df = pd.DataFrame(hourly)
    print(f"  ✓ AQ: {len(df)} filas")
    return df


def download_weather(lat, lon, start_date, end_date):
    """Descarga datos horarios de clima."""
    url = (
        f"{WEATHER_URL}"
        f"?latitude={lat}&longitude={lon}"
        f"&hourly={WEATHER_PARAMS}"
        f"&start_date={start_date}&end_date={end_date}"
        f"&timezone={TZ}"
    )
    print(f"  Descargando Weather: {start_date} -> {end_date}...")
    r = requests.get(url, timeout=30)
    r.raise_for_status()
    data = r.json()
    hourly = data.get("hourly", {})
    if not hourly or "time" not in hourly:
        print(f"  ⚠️  Sin datos Weather para {start_date}-{end_date}")
        return pd.DataFrame()
    df = pd.DataFrame(hourly)
    print(f"  ✓ Weather: {len(df)} filas")
    return df


def feature_engineering(merged):
    """
    Feature engineering completo para predicción PM2.5.

    Features generados:
    - Temporales cíclicos (sin/cos para hora y día de semana)
    - Estacionalidad CDMX (temporada seca vs lluvias)
    - Lag features (1, 2, 3, 6, 12, 24 horas)
    - Rolling statistics (media y std en ventanas de 3, 6, 12, 24h)
    - Deltas (tendencia reciente)
    - Max 24h (detección de spikes)
    - Ventilation index = wind_speed × BLH proxy
    - Hours since rain (washout)
    """
    print("\n── Feature Engineering ──")

    df = merged.copy()
    df["datetime"] = pd.to_datetime(df["datetime"])
    df = df.sort_values("datetime").reset_index(drop=True)

    # ── Temporales cíclicos ──
    hour = df["datetime"].dt.hour
    dow = df["datetime"].dt.dayofweek  # 0=Lunes
    month = df["datetime"].dt.month

    # Sin/cos encoding (captura adjacencia: hora 23 ≈ hora 0)
    df["hour_sin"] = np.sin(2 * np.pi * hour / 24)
    df["hour_cos"] = np.cos(2 * np.pi * hour / 24)
    df["dow_sin"] = np.sin(2 * np.pi * dow / 7)
    df["dow_cos"] = np.cos(2 * np.pi * dow / 7)
    df["month_sin"] = np.sin(2 * np.pi * month / 12)
    df["month_cos"] = np.cos(2 * np.pi * month / 12)

    # También raw para boosted trees (pueden hacer splits directos)
    df["hour"] = hour
    df["month"] = month
    df["is_weekend"] = (dow >= 5).astype(int)

    # Temporada seca CDMX: Nov-Abr (más PM2.5, inversiones térmicas)
    df["is_dry_season"] = month.apply(
        lambda m: 1 if m in [11, 12, 1, 2, 3, 4] else 0
    )

    print(f"  ✓ Temporales: 10 features")

    # ── Lag features (CRÍTICOS para predicción temporal) ──
    pm25_col = "pm2_5"
    lag_hours = [1, 2, 3, 6, 12, 24]
    for lag in lag_hours:
        df[f"pm25_lag_{lag}h"] = df[pm25_col].shift(lag)
    print(f"  ✓ Lags: {len(lag_hours)} features ({lag_hours})")

    # ── Rolling statistics ──
    windows = [3, 6, 12, 24]
    for w in windows:
        df[f"pm25_rolling_mean_{w}h"] = (
            df[pm25_col].rolling(window=w, min_periods=1).mean()
        )
    # Std solo para ventanas grandes (más estable)
    df["pm25_rolling_std_6h"] = df[pm25_col].rolling(6, min_periods=2).std()
    df["pm25_rolling_std_24h"] = df[pm25_col].rolling(24, min_periods=6).std()
    print(f"  ✓ Rolling: {len(windows) + 2} features")

    # ── Delta (tendencia reciente) ──
    df["pm25_delta_1h"] = df[pm25_col] - df[pm25_col].shift(1)
    df["pm25_delta_3h"] = df[pm25_col] - df[pm25_col].shift(3)
    df["pm25_delta_6h"] = df[pm25_col] - df[pm25_col].shift(6)
    print(f"  ✓ Deltas: 3 features")

    # ── Max 24h (detectar spikes) ──
    df["pm25_max_24h"] = df[pm25_col].rolling(24, min_periods=1).max()
    print(f"  ✓ Max 24h: 1 feature")

    # ── Ventilation index ──
    # Proxy: wind_speed × (1/surface_pressure_normalized)
    # En ausencia de BLH directo, usamos presión como proxy de estabilidad
    if "wind_speed_10m" in df.columns and "surface_pressure" in df.columns:
        # Normalizar presión: alta presión = estancamiento = mala ventilación
        p_mean = df["surface_pressure"].mean()
        p_std = df["surface_pressure"].std()
        if p_std > 0:
            # Invertir: presión alta → factor bajo (mala ventilación)
            pressure_factor = 1 - (df["surface_pressure"] - p_mean) / (3 * p_std)
            pressure_factor = pressure_factor.clip(0.1, 2.0)
        else:
            pressure_factor = 1.0

        df["ventilation_index"] = df["wind_speed_10m"] * pressure_factor
        print(f"  ✓ Ventilation index: 1 feature")

    # ── Stability proxy (inversión térmica) ──
    # temp_2m alta + viento bajo = probable inversión = acumulación
    if "temperature_2m" in df.columns and "wind_speed_10m" in df.columns:
        # Índice de estabilidad: alta temp + bajo viento = estable = malo
        df["stability_index"] = df["temperature_2m"] / (df["wind_speed_10m"] + 0.5)
        print(f"  ✓ Stability index: 1 feature")

    # ── Hours since rain (washout de PM2.5) ──
    if "rain" in df.columns:
        rain_flag = (df["rain"] > 0.1).astype(int)
        # Calcular horas desde última lluvia
        hours_since = []
        counter = 999  # Empezar alto (sin lluvia conocida)
        for r in rain_flag:
            if r == 1:
                counter = 0
            else:
                counter += 1
            hours_since.append(min(counter, 168))  # Cap en 1 semana
        df["hours_since_rain"] = hours_since
        print(f"  ✓ Hours since rain: 1 feature")

    # ── Interacciones clave ──
    if "relative_humidity_2m" in df.columns and "wind_speed_10m" in df.columns:
        # Humedad × viento bajo = crecimiento higroscópico + estancamiento
        df["humidity_wind_interaction"] = (
            df["relative_humidity_2m"] / (df["wind_speed_10m"] + 0.5)
        )
        print(f"  ✓ Interaction features: 1 feature")

    # ── Targets (PM2.5 futuro) ──
    for horizon in [1, 3, 6]:
        df[f"pm25_target_{horizon}h"] = df[pm25_col].shift(-horizon)
    print(f"  ✓ Targets: 3 (1h, 3h, 6h)")

    # ── Limpiar ──
    # Eliminar datetime (modelos tabulares no la usan)
    df.drop(columns=["datetime"], inplace=True)

    # Renombrar columnas de contaminantes para consistencia
    rename_map = {
        "pm2_5": "pm25",
        "nitrogen_dioxide": "no2",
        "carbon_monoxide": "co",
        "sulphur_dioxide": "so2",
    }
    df.rename(columns=rename_map, inplace=True)

    # Eliminar filas con NaN en lags y targets
    before = len(df)
    df.dropna(subset=[f"pm25_target_{h}h" for h in [1, 3, 6]], inplace=True)
    df.dropna(subset=["pm25_lag_24h"], inplace=True)
    after = len(df)
    print(f"\n  Filas eliminadas por NaN: {before - after} ({before} → {after})")

    return df


def main():
    print("=" * 70)
    print("  AIRWAY — DESCARGA DE DATOS PARA PREDICCIÓN PM2.5")
    print("  Open-Meteo (gratis, sin API key)")
    print("=" * 70)

    locations = LOCATIONS if USE_ALL_LOCATIONS else {PRIMARY_LOCATION: LOCATIONS[PRIMARY_LOCATION]}

    all_merged = []

    for loc_name, (lat, lon) in locations.items():
        print(f"\n{'─' * 50}")
        print(f"📍 Ubicación: {loc_name} ({lat}, {lon})")
        print(f"{'─' * 50}")

        aq_frames = []
        wx_frames = []

        for start, end in PERIODS:
            try:
                aq_frames.append(download_air_quality(lat, lon, start, end))
                time.sleep(0.5)  # Respetar rate limit
                wx_frames.append(download_weather(lat, lon, start, end))
                time.sleep(0.5)
            except Exception as e:
                print(f"  ⚠️  Error en periodo {start}-{end}: {e}")
                continue

        if not aq_frames or not wx_frames:
            print(f"  ❌ Sin datos para {loc_name}, saltando...")
            continue

        # Concatenar periodos
        aq_df = pd.concat([f for f in aq_frames if not f.empty], ignore_index=True)
        wx_df = pd.concat([f for f in wx_frames if not f.empty], ignore_index=True)

        # Renombrar columna de tiempo
        aq_df.rename(columns={"time": "datetime"}, inplace=True)
        wx_df.rename(columns={"time": "datetime"}, inplace=True)

        # Eliminar duplicados temporales
        aq_df.drop_duplicates(subset=["datetime"], keep="last", inplace=True)
        wx_df.drop_duplicates(subset=["datetime"], keep="last", inplace=True)

        print(f"\n  Air Quality total: {len(aq_df)} filas")
        print(f"  Weather total: {len(wx_df)} filas")

        # Merge en datetime
        merged = pd.merge(aq_df, wx_df, on="datetime", how="inner")
        print(f"  Merged: {len(merged)} filas")

        if merged.empty:
            print(f"  ❌ Merge vacío para {loc_name}")
            continue

        # Agregar identificador de ubicación (útil si usamos múltiples)
        if USE_ALL_LOCATIONS:
            merged["location"] = loc_name

        all_merged.append(merged)

    if not all_merged:
        print("\n❌ No se obtuvieron datos. Verifica tu conexión a internet.")
        sys.exit(1)

    # Concatenar todas las ubicaciones
    full_raw = pd.concat(all_merged, ignore_index=True)
    print(f"\n{'=' * 50}")
    print(f"Total datos crudos: {len(full_raw)} filas")

    # Feature engineering
    full_df = feature_engineering(full_raw)

    # ── Estadísticas ──
    print(f"\n{'=' * 50}")
    print(f"  ESTADÍSTICAS PM2.5")
    print(f"{'=' * 50}")
    if "pm25" in full_df.columns:
        pm = full_df["pm25"]
        print(f"  Media:    {pm.mean():.1f} µg/m³")
        print(f"  Mediana:  {pm.median():.1f} µg/m³")
        print(f"  Std:      {pm.std():.1f} µg/m³")
        print(f"  Min:      {pm.min():.1f} µg/m³")
        print(f"  Max:      {pm.max():.1f} µg/m³")
        print(f"  P95:      {pm.quantile(0.95):.1f} µg/m³")

    # ── Split temporal 80/20 ──
    # NUNCA random split para series temporales
    split_idx = int(len(full_df) * 0.8)
    train = full_df.iloc[:split_idx]
    test = full_df.iloc[split_idx:]

    print(f"\n  Train: {len(train)} filas (80%)")
    print(f"  Test:  {len(test)} filas (20%)")
    print(f"  Columnas ({len(full_df.columns)}): {list(full_df.columns)}")

    # ── Guardar ──
    train_path = os.path.join(OUTPUT_DIR, "train_pm25_cdmx.csv")
    test_path = os.path.join(OUTPUT_DIR, "test_pm25_cdmx.csv")
    full_path = os.path.join(OUTPUT_DIR, "full_pm25_cdmx.csv")

    train.to_csv(train_path, index=False)
    test.to_csv(test_path, index=False)
    full_df.to_csv(full_path, index=False)

    print(f"\n{'=' * 50}")
    print(f"  ARCHIVOS GUARDADOS")
    print(f"{'=' * 50}")
    print(f"  📄 {train_path}")
    print(f"  📄 {test_path}")
    print(f"  📄 {full_path}")

    # ── Resumen de features ──
    print(f"\n{'=' * 50}")
    print(f"  RESUMEN DE FEATURES ({len(full_df.columns)} columnas)")
    print(f"{'=' * 50}")

    categories = {
        "Contaminantes": ["pm25", "pm10", "no2", "ozone", "co", "so2", "dust"],
        "Meteorológicos": [
            "temperature_2m", "relative_humidity_2m", "dew_point_2m",
            "surface_pressure", "wind_speed_10m", "wind_direction_10m",
            "wind_gusts_10m", "precipitation", "rain", "cloud_cover",
            "shortwave_radiation", "direct_radiation"
        ],
        "Temporales": [
            "hour_sin", "hour_cos", "dow_sin", "dow_cos",
            "month_sin", "month_cos", "hour", "month",
            "is_weekend", "is_dry_season"
        ],
        "Lags": [c for c in full_df.columns if "lag" in c],
        "Rolling": [c for c in full_df.columns if "rolling" in c],
        "Deltas": [c for c in full_df.columns if "delta" in c],
        "Derivados": [
            "pm25_max_24h", "ventilation_index", "stability_index",
            "hours_since_rain", "humidity_wind_interaction"
        ],
        "Targets": [c for c in full_df.columns if "target" in c],
    }

    for cat, cols in categories.items():
        present = [c for c in cols if c in full_df.columns]
        if present:
            print(f"  {cat} ({len(present)}): {present}")

    # ── Info para NaN ──
    nan_cols = full_df.columns[full_df.isnull().any()].tolist()
    if nan_cols:
        print(f"\n  ⚠️  Columnas con NaN restantes: {nan_cols}")
        for c in nan_cols:
            pct = full_df[c].isnull().mean() * 100
            print(f"      {c}: {pct:.1f}% NaN")

    print(f"\n✅ Listo! Siguiente paso: python scripts/train_model.py")


if __name__ == "__main__":
    main()
