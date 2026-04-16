"""
Servicio de inferencia ContingencyCast.

Carga modelos entrenados y devuelve pronósticos h+24, h+48, h+72 con:
- Probabilidad calibrada de contingencia Fase 1 O3
- Intervalo de confianza 80% del valor de O3_max esperado
- Drivers principales (features que más empujaron la predicción)
- Explicación corta en español

Fuente de features en tiempo real:
- RAMA últimas 168h (via Open-Meteo air-quality API como fallback cuando no hay RAMA live)
- Open-Meteo forecast meteorológico próximas 72h

Uso:
    from application.ml.inference import ContingencyPredictor

    pred = ContingencyPredictor()
    forecast = pred.predict_now(lat=19.4326, lon=-99.1332)
    # → {"forecasts": [{"horizon_h": 24, "prob_fase1_o3": 0.78, ...}], ...}
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
import requests
from xgboost import XGBClassifier, XGBRegressor

from application.ml.config import (
    CDMX_CENTER,
    FORECAST_HORIZONS,
    MODELS_DIR,
    OPENMETEO_AIRQUALITY_URL,
    OPENMETEO_ARCHIVE_URL,
    THRESHOLD_O3_FASE1_PPB,
)
from application.ml.features import add_all_features, feature_columns
from application.ml.train_quantile import probability_of_exceedance

logger = logging.getLogger("inference")


# =========================================================================
# Data fetchers en tiempo real
# =========================================================================

def fetch_recent_meteo(lat: float, lon: float, hours_back: int = 168) -> pd.DataFrame:
    """Últimas N horas de meteo + próximas 72h de forecast (para features de futuro)."""
    now = datetime.now(timezone.utc)
    past_start = (now - timedelta(hours=hours_back + 24)).date().isoformat()
    past_end = now.date().isoformat()

    past_vars = [
        "temperature_2m",
        "relative_humidity_2m",
        "dew_point_2m",
        "surface_pressure",
        "pressure_msl",
        "precipitation",
        "cloud_cover",
        "wind_speed_10m",
        "wind_direction_10m",
        "shortwave_radiation",
        "cape",
        "temperature_850hPa",
        "temperature_500hPa",
        "boundary_layer_height",
    ]

    r = requests.get(
        OPENMETEO_ARCHIVE_URL,
        params={
            "latitude": lat,
            "longitude": lon,
            "start_date": past_start,
            "end_date": past_end,
            "hourly": ",".join(past_vars),
            "timezone": "America/Mexico_City",
            "windspeed_unit": "ms",
        },
        timeout=60,
    )
    r.raise_for_status()
    df = pd.DataFrame(r.json()["hourly"])
    df = df.rename(columns={"time": "timestamp"})
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    return df


def fetch_recent_air_quality(lat: float, lon: float, hours_back: int = 168) -> pd.DataFrame:
    """Open-Meteo Air Quality — usa proxies de modelos CAMS cuando no hay RAMA live."""
    r = requests.get(
        OPENMETEO_AIRQUALITY_URL,
        params={
            "latitude": lat,
            "longitude": lon,
            "hourly": "ozone,pm2_5,pm10,nitrogen_dioxide,sulphur_dioxide,carbon_monoxide,uv_index",
            "past_hours": hours_back,
            "forecast_hours": 1,   # una hora actual
            "timezone": "America/Mexico_City",
        },
        timeout=60,
    )
    r.raise_for_status()
    df = pd.DataFrame(r.json()["hourly"])
    df = df.rename(columns={"time": "timestamp"})
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    # Mapear a nomenclatura RAMA
    df = df.rename(columns={
        "ozone": "O3_max",
        "pm2_5": "PM25_max",
        "pm10": "PM10_max",
        "nitrogen_dioxide": "NO2_max",
        "sulphur_dioxide": "SO2_max",
        "carbon_monoxide": "CO_max",
    })
    # Duplicamos _avg = _max (solo tenemos 1 valor por celda del modelo)
    for pol in ["O3", "PM25", "PM10", "NO2", "SO2", "CO"]:
        if f"{pol}_max" in df.columns:
            df[f"{pol}_avg"] = df[f"{pol}_max"]
    return df


# =========================================================================
# Predictor
# =========================================================================

@dataclass
class HorizonForecast:
    horizon_h: int
    prob_fase1_o3: float
    prob_uncalibrated: float
    o3_expected: float
    o3_ci80: list[float]
    top_drivers: list[dict[str, Any]] = field(default_factory=list)


@dataclass
class ForecastResponse:
    timestamp: str
    location: dict[str, float]
    forecasts: list[HorizonForecast]
    model_version: str
    explanation_hint: str


class ContingencyPredictor:
    """Carga modelos y hace inferencia."""

    def __init__(self, models_dir: Path = MODELS_DIR):
        self.models_dir = models_dir
        self.quantile_models: dict[int, dict[float, XGBRegressor]] = {}
        self.classifiers: dict[int, XGBClassifier] = {}
        self.calibrators: dict[int, Any] = {}
        self.metas: dict[int, dict] = {}
        self._load()

    def _load(self):
        for h in FORECAST_HORIZONS:
            meta_path = self.models_dir / f"quantile_h{h}_meta.json"
            if not meta_path.exists():
                logger.warning(f"h+{h}: meta no existe, saltando")
                continue

            meta = json.loads(meta_path.read_text())
            self.metas[h] = meta

            # Cuantiles
            self.quantile_models[h] = {}
            for q in meta["quantiles"]:
                m = XGBRegressor()
                m.load_model(str(self.models_dir / f"xgb_q{int(q * 100)}_h{h}.json"))
                self.quantile_models[h][q] = m

            # Classifier
            clf = XGBClassifier()
            clf.load_model(str(self.models_dir / f"xgb_clf_h{h}.json"))
            self.classifiers[h] = clf

            # Calibrator
            cal_path = self.models_dir / f"calibrator_h{h}.joblib"
            if cal_path.exists():
                self.calibrators[h] = joblib.load(cal_path)

            logger.info(f"✓ cargado modelo h+{h}")

    def _predict_horizon(
        self,
        row: pd.Series,
        horizon: int,
    ) -> HorizonForecast:
        features = self.metas[horizon]["features"]
        alpha = self.metas[horizon].get("ensemble_alpha", 0.5)

        # XGBoost requiere tipos numéricos. Los merges outer y NaN dejan columnas
        # como object; forzamos float64 con coerción a NaN.
        X = row.reindex(features).to_frame().T
        X = X.apply(pd.to_numeric, errors="coerce").astype("float64")

        # Cuantiles
        q10 = float(self.quantile_models[horizon][0.10].predict(X)[0])
        q50 = float(self.quantile_models[horizon][0.50].predict(X)[0])
        q90 = float(self.quantile_models[horizon][0.90].predict(X)[0])

        prob_from_quantile = probability_of_exceedance(q10, q50, q90, THRESHOLD_O3_FASE1_PPB)
        prob_from_clf = float(self.classifiers[horizon].predict_proba(X)[0, 1])

        ensemble = alpha * prob_from_clf + (1 - alpha) * prob_from_quantile

        if horizon in self.calibrators:
            prob_calibrated = float(self.calibrators[horizon].transform([ensemble])[0])
        else:
            prob_calibrated = ensemble

        # Top drivers: feature_importance × |z-score del valor actual|
        importance = self.classifiers[horizon].feature_importances_
        values = X.iloc[0].values
        # Z-score grosero: cuánto se aleja de la media (sin estandarización completa por simplicidad)
        contribution = np.abs(values - np.nanmean(values)) * importance
        top_idx = np.argsort(-contribution)[:5]
        top_drivers = [
            {
                "feature": features[i],
                "value": float(values[i]) if not np.isnan(values[i]) else None,
                "importance": float(importance[i]),
            }
            for i in top_idx
        ]

        return HorizonForecast(
            horizon_h=horizon,
            prob_fase1_o3=round(prob_calibrated, 3),
            prob_uncalibrated=round(ensemble, 3),
            o3_expected=round(q50, 1),
            o3_ci80=[round(q10, 1), round(q90, 1)],
            top_drivers=top_drivers,
        )

    def predict_from_row(self, features_row: pd.Series) -> ForecastResponse:
        """Dado un row de features ya construido, devuelve pronóstico multi-horizon."""
        forecasts = []
        for h in FORECAST_HORIZONS:
            if h not in self.quantile_models:
                continue
            forecasts.append(self._predict_horizon(features_row, h))

        return ForecastResponse(
            timestamp=datetime.now(timezone.utc).isoformat(),
            location={"lat": CDMX_CENTER["lat"], "lon": CDMX_CENTER["lon"]},
            forecasts=forecasts,
            model_version="quantile_v1",
            explanation_hint=self._explanation_hint(forecasts),
        )

    def predict_now(
        self,
        lat: float = CDMX_CENTER["lat"],
        lon: float = CDMX_CENTER["lon"],
    ) -> ForecastResponse:
        """Construye features del momento actual y hace pronóstico."""
        logger.info(f"fetching data para ({lat}, {lon})")

        meteo = fetch_recent_meteo(lat, lon, hours_back=168)
        aq = fetch_recent_air_quality(lat, lon, hours_back=168)

        df = meteo.merge(aq, on="timestamp", how="outer").sort_values("timestamp").reset_index(drop=True)

        # dT/dz si no vino
        if "temperature_2m" in df.columns and "temperature_850hPa" in df.columns:
            df["dT_dz_850"] = df["temperature_2m"] - df["temperature_850hPa"]
            df["inversion_flag"] = (df["dT_dz_850"] > 0).astype(int)

        # Features completos
        df_feat = add_all_features(df)

        # Fila más reciente con todos los lags poblados
        latest = df_feat.iloc[-1]
        return self.predict_from_row(latest)

    @staticmethod
    def _explanation_hint(forecasts: list[HorizonForecast]) -> str:
        """Genera un hint corto en español para que el iOS Foundation Models pueda expandir."""
        if not forecasts:
            return "Sin datos suficientes."

        next24 = forecasts[0]
        if next24.prob_fase1_o3 > 0.7:
            return f"Alta probabilidad de Fase 1 O3 mañana ({int(next24.prob_fase1_o3 * 100)}%)."
        elif next24.prob_fase1_o3 > 0.4:
            return f"Moderada probabilidad ({int(next24.prob_fase1_o3 * 100)}%) mañana — monitoreo."
        return f"Baja probabilidad ({int(next24.prob_fase1_o3 * 100)}%) — día estable esperado."


# Singleton para reutilizar modelos cargados
_predictor_instance: ContingencyPredictor | None = None


def get_predictor() -> ContingencyPredictor:
    global _predictor_instance
    if _predictor_instance is None:
        _predictor_instance = ContingencyPredictor()
    return _predictor_instance
