"""
Entrena XGBoost multi-horizon (h+24, h+48, h+72) para Fase 1 O3.

Mejoras sobre el baseline:
- `scale_pos_weight` = neg/pos (calculado del train) → maneja desbalance
- Early stopping en val con PR-AUC (no ROC-AUC)
- `hist` tree_method para speed
- Más árboles + más profundidad
- Sin drop de NaNs — XGBoost maneja missing nativamente

Uso:
    python -m application.ml.train_xgb
"""
from __future__ import annotations

import json
import logging
import sys
from pathlib import Path

import pandas as pd
from xgboost import XGBClassifier

if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "src"))

from application.ml.config import FEATURES_FILE, FORECAST_HORIZONS, MODELS_DIR
from application.ml.features import TARGETS, feature_columns
from application.ml.metrics import format_report, full_report
from application.ml.splits import time_split

logger = logging.getLogger("train_xgb")


def train_horizon(df_feat: pd.DataFrame, horizon: int) -> dict:
    target_col = TARGETS[horizon]
    features = feature_columns(df_feat)

    # Descarta filas sin lags completos (primeras 168h del dataset)
    min_history = 168
    df_clean = df_feat.iloc[min_history:].dropna(subset=[target_col])

    train, val, test = time_split(df_clean)

    X_train, y_train = train[features], train[target_col].values
    X_val, y_val = val[features], val[target_col].values
    X_test, y_test = test[features], test[target_col].values

    pos = int(y_train.sum())
    neg = int((1 - y_train).sum())
    if pos == 0:
        logger.error(f"[h+{horizon}] sin positivos en train, abortando")
        return {}

    raw_scale = neg / pos
    # Usa sqrt para moderar cuando desbalance no es extremo (dampens overcorrection)
    scale = min(raw_scale, max(1.0, raw_scale ** 0.5))
    pos_rate_pct = 100.0 * pos / (pos + neg)

    logger.info(
        f"[h+{horizon}] train={len(train):,} (pos={pos}, {pos_rate_pct:.1f}%, scale={scale:.2f}) "
        f"val={len(val):,} (pos={int(y_val.sum())}) test={len(test):,} (pos={int(y_test.sum())})"
    )

    can_early_stop = y_val.sum() > 0
    model = XGBClassifier(
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

    logger.info(
        f"[h+{horizon}] entrenando XGBoost con {len(features)} features "
        f"{'(early stopping)' if can_early_stop else '(sin early stop)'}..."
    )
    fit_kwargs = {"verbose": False}
    if can_early_stop:
        fit_kwargs["eval_set"] = [(X_val, y_val)]
    model.fit(X_train, y_train, **fit_kwargs)

    best_iter = model.best_iteration if hasattr(model, "best_iteration") else model.n_estimators
    logger.info(f"  best_iteration: {best_iter}")

    reports = {}
    for name, X, y in [("val", X_val, y_val), ("test", X_test, y_test)]:
        if y.sum() == 0:
            continue
        y_prob = model.predict_proba(X)[:, 1]
        rep = full_report(y, y_prob)
        reports[name] = rep
        logger.info(format_report(rep, name=f"h+{horizon} {name}"))

    model_path = MODELS_DIR / f"xgb_h{horizon}.json"
    model.save_model(str(model_path))
    # Guardar features para reproducir inferencia
    meta_path = MODELS_DIR / f"xgb_h{horizon}_meta.json"
    with meta_path.open("w") as f:
        json.dump(
            {
                "horizon": horizon,
                "features": features,
                "scale_pos_weight": scale,
                "best_iteration": int(best_iter),
            },
            f,
            indent=2,
        )

    logger.info(f"  ✓ guardado {model_path} + meta")

    # Top features
    imp_df = pd.DataFrame(
        {"feature": features, "importance": model.feature_importances_}
    ).sort_values("importance", ascending=False)
    top20 = imp_df.head(20).to_dict("records")
    logger.info(f"  top 10:\n{imp_df.head(10).to_string(index=False)}")

    return {
        "horizon": horizon,
        "n_features": len(features),
        "best_iteration": int(best_iter),
        "reports": reports,
        "top_features": top20,
        "model_path": str(model_path),
    }


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
    logger.info(f"Dataset: {len(df):,} filas × {df.shape[1]} cols")

    results = {}
    for h in FORECAST_HORIZONS:
        results[f"h+{h}"] = train_horizon(df, h)

    metrics_file = MODELS_DIR / "xgb_metrics.json"
    with metrics_file.open("w") as f:
        json.dump(results, f, indent=2, default=str)
    logger.info(f"✓ métricas en {metrics_file}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
