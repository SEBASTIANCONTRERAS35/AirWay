"""
Regresión por cuantiles + calibración isotónica.

Dos modelos de salida:

1) QuantileRegressor (XGBoost `reg:quantileerror`)
   Predice q10, q50, q90 del VALOR de O3_max en próximas N horas.
   Permite construir un intervalo de confianza del 80% sobre el valor.
   A partir de (q10, q50, q90) estimamos P(X > 154 ppb) vía interpolación PCHIP.

2) Calibrator (IsotonicRegression)
   Entrenado en val para mapear las probabilidades crudas del XGBClassifier
   a probabilidades bien calibradas (que el 78% signifique ~78% real).

Uso:
    python -m application.ml.train_quantile
"""
from __future__ import annotations

import json
import logging
import sys
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from scipy.interpolate import PchipInterpolator
from sklearn.isotonic import IsotonicRegression
from xgboost import XGBClassifier, XGBRegressor

if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "src"))

from application.ml.config import (
    FEATURES_FILE,
    FORECAST_HORIZONS,
    MODELS_DIR,
    THRESHOLD_O3_FASE1_PPB,
)
from application.ml.features import TARGETS, feature_columns
from application.ml.metrics import format_report, full_report
from application.ml.splits import time_split

logger = logging.getLogger("train_quantile")

QUANTILES = [0.10, 0.50, 0.90]


# =========================================================================
# Target continuo: valor de O3_max esperado en próximas H horas
# =========================================================================

def build_continuous_target(df: pd.DataFrame, horizon: int) -> pd.Series:
    """Máximo de O3_max en próximas H horas."""
    if "O3_max" not in df.columns:
        raise KeyError("O3_max no está en el DataFrame")
    return (
        df["O3_max"]
        .shift(-1)
        .rolling(horizon, min_periods=1)
        .max()
        .shift(-(horizon - 1))
    )


# =========================================================================
# Conversión (q10, q50, q90) → P(X > threshold)
# =========================================================================

def probability_of_exceedance(
    q10: float,
    q50: float,
    q90: float,
    threshold: float = THRESHOLD_O3_FASE1_PPB,
) -> float:
    """
    Estima P(X > threshold) a partir de 3 cuantiles predichos.

    Asume que la CDF del valor se puede interpolar monótonamente entre
    (q10, 0.10), (q50, 0.50), (q90, 0.90). Extrapola colas con gaussiana.
    """
    # Asegurar monotonía (XGBoost puede violarla en algunos puntos raros)
    vals = sorted([q10, q50, q90])
    qs = [0.10, 0.50, 0.90]

    # Extrapolación conservadora usando desviación estándar implícita
    sigma = max((vals[2] - vals[0]) / (2 * 1.28), 1.0)   # 1.28 ≈ z-score 90%
    q_tail_lo = vals[0] - 2.33 * sigma   # p=0.01
    q_tail_hi = vals[2] + 2.33 * sigma   # p=0.99

    xs = [q_tail_lo] + vals + [q_tail_hi]
    ys = [0.01] + qs + [0.99]

    # Asegurar estrictamente creciente
    for i in range(1, len(xs)):
        if xs[i] <= xs[i - 1]:
            xs[i] = xs[i - 1] + 1e-6

    interp = PchipInterpolator(xs, ys, extrapolate=True)
    p_leq = float(np.clip(interp(threshold), 0.0, 1.0))
    return 1.0 - p_leq


# =========================================================================
# Entrenamiento
# =========================================================================

def train_quantile_set(X_train, y_train, X_val, y_val) -> dict[float, XGBRegressor]:
    """Entrena 3 modelos, uno por cuantil."""
    # Para cuantiles el val siempre tiene valores continuos (no desbalance),
    # así que early stopping sí sirve.
    models = {}
    for q in QUANTILES:
        logger.info(f"  entrenando q={q}...")
        m = XGBRegressor(
            objective="reg:quantileerror",
            quantile_alpha=q,
            max_depth=6,
            learning_rate=0.05,
            n_estimators=1000,
            subsample=0.8,
            colsample_bytree=0.8,
            tree_method="hist",
            early_stopping_rounds=50,
            random_state=42,
            n_jobs=-1,
        )
        m.fit(X_train, y_train, eval_set=[(X_val, y_val)], verbose=False)
        models[q] = m
    return models


def train_calibrator(y_val: np.ndarray, y_val_prob: np.ndarray) -> IsotonicRegression:
    """Ajusta calibrador isotónico sobre las probabilidades de val."""
    iso = IsotonicRegression(out_of_bounds="clip", y_min=0.0, y_max=1.0)
    iso.fit(y_val_prob, y_val)
    return iso


def train_horizon(df_feat: pd.DataFrame, horizon: int) -> dict:
    target_bin = TARGETS[horizon]
    features = feature_columns(df_feat)

    # Target continuo
    df_feat = df_feat.copy()
    df_feat[f"y_cont_{horizon}h"] = build_continuous_target(df_feat, horizon)
    target_cont = f"y_cont_{horizon}h"

    # Descarta primeras 168h sin lags completos + filas sin target
    min_history = 168
    df_clean = df_feat.iloc[min_history:].dropna(subset=[target_bin, target_cont])
    train, val, test = time_split(df_clean)

    if len(train) == 0 or len(val) == 0:
        logger.error(f"[h+{horizon}] splits vacíos, abortando")
        return {}

    X_train, y_train_cont, y_train_bin = train[features], train[target_cont].values, train[target_bin].values
    X_val, y_val_cont, y_val_bin = val[features], val[target_cont].values, val[target_bin].values
    X_test, y_test_bin = test[features], test[target_bin].values

    logger.info(
        f"[h+{horizon}] train={len(train):,} val={len(val):,} test={len(test):,}"
    )

    # 1) Cuantiles
    logger.info(f"[h+{horizon}] entrenando cuantiles...")
    qmodels = train_quantile_set(X_train, y_train_cont, X_val, y_val_cont)

    # Predicciones de cuantiles en val → probabilidad de exceedance
    q10_val = qmodels[0.10].predict(X_val)
    q50_val = qmodels[0.50].predict(X_val)
    q90_val = qmodels[0.90].predict(X_val)

    prob_exceed_val = np.array([
        probability_of_exceedance(q10_val[i], q50_val[i], q90_val[i])
        for i in range(len(X_val))
    ])

    # 2) Clasificador base (mismos hyperparams que train_xgb.py)
    pos = int(y_train_bin.sum())
    neg = int((1 - y_train_bin).sum())
    raw_scale = neg / pos if pos > 0 else 1
    scale = min(raw_scale, max(1.0, raw_scale ** 0.5))
    can_early_stop = y_val_bin.sum() > 0
    logger.info(f"[h+{horizon}] entrenando clasificador (scale={scale:.2f})...")
    clf = XGBClassifier(
        objective="binary:logistic",
        eval_metric="aucpr",
        scale_pos_weight=scale,
        max_depth=5,
        learning_rate=0.05,
        n_estimators=500,
        subsample=0.8,
        colsample_bytree=0.8,
        reg_lambda=2.0,
        reg_alpha=0.1,
        min_child_weight=5,
        tree_method="hist",
        early_stopping_rounds=100 if can_early_stop else None,
        random_state=42,
        n_jobs=-1,
    )
    clf_fit_kwargs = {"verbose": False}
    if can_early_stop:
        clf_fit_kwargs["eval_set"] = [(X_val, y_val_bin)]
    clf.fit(X_train, y_train_bin, **clf_fit_kwargs)
    clf_prob_val = clf.predict_proba(X_val)[:, 1]

    # 3) Calibrador isotónico — solo si val tiene suficientes positivos,
    #    isotonic requiere muchas muestras para no sobre-ajustar. Si hay poco,
    #    es mejor mantener raw probs.
    calibrator = None
    MIN_POS_FOR_CALIBRATION = 500
    if int(y_val_bin.sum()) >= MIN_POS_FOR_CALIBRATION:
        calibrator = train_calibrator(y_val_bin, clf_prob_val)
        logger.info(f"[h+{horizon}] calibrador isotónico entrenado")
    else:
        logger.info(
            f"[h+{horizon}] sin calibrador (val pos={int(y_val_bin.sum())} < {MIN_POS_FOR_CALIBRATION})"
        )

    # 4) Ensemble: clasificador pesado más, quantile aporta señal complementaria
    alpha = 0.7   # classifier domina (tiene buenas métricas)
    ensemble_val = alpha * clf_prob_val + (1 - alpha) * prob_exceed_val
    calibrated_val = (
        calibrator.transform(ensemble_val) if calibrator is not None else ensemble_val
    )

    # Evaluación en test
    q10_test = qmodels[0.10].predict(X_test)
    q50_test = qmodels[0.50].predict(X_test)
    q90_test = qmodels[0.90].predict(X_test)
    prob_exceed_test = np.array([
        probability_of_exceedance(q10_test[i], q50_test[i], q90_test[i])
        for i in range(len(X_test))
    ])
    clf_prob_test = clf.predict_proba(X_test)[:, 1]
    ensemble_test = alpha * clf_prob_test + (1 - alpha) * prob_exceed_test
    calibrated_test = (
        calibrator.transform(ensemble_test) if calibrator is not None else ensemble_test
    )

    reports = {}
    if y_val_bin.sum() > 0:
        reports["val_raw"] = full_report(y_val_bin, ensemble_val)
        reports["val_calibrated"] = full_report(y_val_bin, calibrated_val)
        logger.info(format_report(reports["val_raw"], name=f"h+{horizon} val_raw"))
        logger.info(format_report(reports["val_calibrated"], name=f"h+{horizon} val_calib"))

    if y_test_bin.sum() > 0:
        reports["test_raw"] = full_report(y_test_bin, ensemble_test)
        reports["test_calibrated"] = full_report(y_test_bin, calibrated_test)
        logger.info(format_report(reports["test_raw"], name=f"h+{horizon} test_raw"))
        logger.info(format_report(reports["test_calibrated"], name=f"h+{horizon} test_calib"))

    # Guardar todo
    for q, m in qmodels.items():
        m.save_model(str(MODELS_DIR / f"xgb_q{int(q * 100)}_h{horizon}.json"))
    clf.save_model(str(MODELS_DIR / f"xgb_clf_h{horizon}.json"))
    if calibrator is not None:
        joblib.dump(calibrator, MODELS_DIR / f"calibrator_h{horizon}.joblib")

    meta = {
        "horizon": horizon,
        "features": features,
        "quantiles": QUANTILES,
        "ensemble_alpha": alpha,
        "has_calibrator": calibrator is not None,
        "scale_pos_weight": scale,
    }
    with (MODELS_DIR / f"quantile_h{horizon}_meta.json").open("w") as f:
        json.dump(meta, f, indent=2)

    logger.info(f"  ✓ guardados quantile + classifier + calibrator para h+{horizon}")

    return {"horizon": horizon, "reports": reports, "meta": meta}


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    if not FEATURES_FILE.exists():
        raise FileNotFoundError(
            f"{FEATURES_FILE} no existe. Corre: python -m application.ml.features"
        )
    MODELS_DIR.mkdir(parents=True, exist_ok=True)

    df = pd.read_parquet(FEATURES_FILE)
    logger.info(f"Dataset: {len(df):,} filas")

    results = {}
    for h in FORECAST_HORIZONS:
        results[f"h+{h}"] = train_horizon(df, h)

    with (MODELS_DIR / "quantile_metrics.json").open("w") as f:
        json.dump(results, f, indent=2, default=str)
    logger.info("✓ done")
    return 0


if __name__ == "__main__":
    sys.exit(main())
