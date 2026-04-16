"""
Entrena Random Forest baseline para predicción de contingencia Fase 1 O3.

Diseñado para: correr rápido (<5 min), dar primera métrica, confirmar que el
pipeline completo (dataset → features → modelo → métricas) funciona.

Si esto da CSI > 0.25, podemos iterar. Si falla aquí, hay algo mal en los datos.

Uso:
    cd backend-api
    python -m application.ml.train_baseline
"""
from __future__ import annotations

import json
import logging
import sys
from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier

if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "src"))

from application.ml.config import FEATURES_FILE, FORECAST_HORIZONS, MODELS_DIR
from application.ml.features import TARGETS, feature_columns
from application.ml.metrics import format_report, full_report
from application.ml.splits import time_split

logger = logging.getLogger("train_baseline")


def train_horizon(df_feat: pd.DataFrame, horizon: int) -> dict:
    target_col = TARGETS[horizon]
    features = feature_columns(df_feat)

    # Descarta filas que no tengan suficiente historia para que los lags
    # (hasta 168h) estén poblados. Evita meter ruido artificial en train.
    min_history = 168
    df_clean = df_feat.iloc[min_history:].dropna(subset=[target_col])

    train, val, test = time_split(df_clean)

    logger.info(
        f"[h+{horizon}] train={len(train):,} val={len(val):,} test={len(test):,}"
    )

    X_train = train[features].fillna(-999)
    y_train = train[target_col].values
    X_val = val[features].fillna(-999)
    y_val = val[target_col].values
    X_test = test[features].fillna(-999)
    y_test = test[target_col].values

    if y_train.sum() == 0:
        logger.error(f"[h+{horizon}] sin positivos en train, abortando")
        return {}

    model = RandomForestClassifier(
        n_estimators=300,
        max_depth=15,
        class_weight="balanced",
        n_jobs=-1,
        random_state=42,
    )

    logger.info(f"[h+{horizon}] entrenando RF con {len(features)} features...")
    model.fit(X_train, y_train)

    reports = {}
    for name, X, y in [("val", X_val, y_val), ("test", X_test, y_test)]:
        if y.sum() == 0:
            logger.warning(f"  {name} sin positivos, saltando métrica")
            continue
        y_prob = model.predict_proba(X)[:, 1]
        rep = full_report(y, y_prob)
        reports[name] = rep
        logger.info(format_report(rep, name=f"h+{horizon} {name}"))

    model_path = MODELS_DIR / f"rf_baseline_h{horizon}.joblib"
    joblib.dump({"model": model, "features": features, "horizon": horizon}, model_path)
    logger.info(f"  ✓ guardado {model_path}")

    # Top 20 features por importance
    imp = (
        pd.DataFrame({"feature": features, "importance": model.feature_importances_})
        .sort_values("importance", ascending=False)
        .head(20)
    )
    logger.info(f"  top 10 features:\n{imp.head(10).to_string(index=False)}")

    return {
        "horizon": horizon,
        "n_features": len(features),
        "model_path": str(model_path),
        "reports": reports,
        "top_features": imp.to_dict("records"),
    }


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    if not FEATURES_FILE.exists():
        raise FileNotFoundError(
            f"{FEATURES_FILE} no existe. "
            f"Corre: python -m application.ml.features"
        )

    MODELS_DIR.mkdir(parents=True, exist_ok=True)

    df = pd.read_parquet(FEATURES_FILE)
    logger.info(f"Features dataset: {len(df):,} filas × {df.shape[1]} cols")

    results = {}
    for h in FORECAST_HORIZONS:
        results[f"h+{h}"] = train_horizon(df, h)

    metrics_file = MODELS_DIR / "rf_baseline_metrics.json"
    with metrics_file.open("w") as f:
        json.dump(results, f, indent=2, default=str)
    logger.info(f"✓ métricas guardadas en {metrics_file}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
