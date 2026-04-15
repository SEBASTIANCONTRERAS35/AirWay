#!/usr/bin/env python3
"""
AirWay — Entrena modelos de predicción PM2.5 para CDMX.

Entrena 3 modelos (horizonte 1h, 3h, 6h) usando GradientBoosting.
Exporta:
  - models/*.pkl  (para servir en Django backend)
  - feature_importance.csv (para análisis y presentación)
  - metrics.json (RMSE, MAE, R² por horizonte)

Usa scikit-learn (GradientBoostingRegressor) como baseline confiable.
Si LightGBM está instalado, lo usa automáticamente (mejor rendimiento).
"""

import os
import sys
import json
import warnings
import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "backend-api", "models")
TRAIN_PATH = os.path.join(SCRIPT_DIR, "train_pm25_cdmx.csv")
TEST_PATH = os.path.join(SCRIPT_DIR, "test_pm25_cdmx.csv")

# Horizontes de predicción
HORIZONS = [1, 3, 6]

# Columnas que NO son features (son targets o metadata)
EXCLUDE_COLS = [
    "pm25_target_1h", "pm25_target_3h", "pm25_target_6h",
    "location",  # Si se usaron múltiples ubicaciones
]

# Hiperparámetros (optimizados para PM2.5 CDMX según literatura)
PARAMS_SKLEARN = {
    "n_estimators": 500,
    "max_depth": 6,
    "learning_rate": 0.1,
    "subsample": 0.8,
    "min_samples_leaf": 10,
    "min_samples_split": 20,
    "random_state": 42,
}

PARAMS_LGBM = {
    "n_estimators": 500,
    "max_depth": 6,
    "learning_rate": 0.1,
    "subsample": 0.8,
    "colsample_bytree": 0.8,
    "min_child_samples": 20,
    "reg_alpha": 0.1,
    "reg_lambda": 1.0,
    "random_state": 42,
    "verbose": -1,
    "n_jobs": -1,
}


def load_data():
    """Carga y prepara datos de entrenamiento y test."""
    print("Cargando datos...")
    train = pd.read_csv(TRAIN_PATH)
    test = pd.read_csv(TEST_PATH)
    print(f"  Train: {train.shape}")
    print(f"  Test:  {test.shape}")
    return train, test


def get_features(df):
    """Obtiene lista de features (todo excepto targets y metadata)."""
    return [c for c in df.columns if c not in EXCLUDE_COLS]


def get_model_class():
    """Intenta usar LightGBM, fallback a scikit-learn."""
    try:
        from lightgbm import LGBMRegressor
        print("  Usando LightGBM (mejor rendimiento)")
        return LGBMRegressor, PARAMS_LGBM, "lightgbm"
    except ImportError:
        from sklearn.ensemble import GradientBoostingRegressor
        print("  Usando scikit-learn GradientBoosting (LightGBM no disponible)")
        return GradientBoostingRegressor, PARAMS_SKLEARN, "sklearn"


def train_horizon(train_df, test_df, features, horizon, ModelClass, params):
    """Entrena un modelo para un horizonte específico."""
    target = f"pm25_target_{horizon}h"

    # Preparar datos
    X_train = train_df[features].copy()
    y_train = train_df[target].copy()
    X_test = test_df[features].copy()
    y_test = test_df[target].copy()

    # Eliminar filas con NaN en features
    train_mask = X_train.notna().all(axis=1) & y_train.notna()
    test_mask = X_test.notna().all(axis=1) & y_test.notna()

    X_train = X_train[train_mask]
    y_train = y_train[train_mask]
    X_test = X_test[test_mask]
    y_test = y_test[test_mask]

    # Rellenar NaN restantes con mediana (por si acaso)
    for col in X_train.columns:
        median_val = X_train[col].median()
        X_train[col] = X_train[col].fillna(median_val)
        X_test[col] = X_test[col].fillna(median_val)

    print(f"\n  Train: {len(X_train)} filas, Test: {len(X_test)} filas")

    # Entrenar
    model = ModelClass(**params)
    model.fit(X_train, y_train)

    # Predecir
    y_pred_train = model.predict(X_train)
    y_pred_test = model.predict(X_test)

    # Métricas
    from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

    train_rmse = np.sqrt(mean_squared_error(y_train, y_pred_train))
    test_rmse = np.sqrt(mean_squared_error(y_test, y_pred_test))
    test_mae = mean_absolute_error(y_test, y_pred_test)
    test_r2 = r2_score(y_test, y_pred_test)

    # Errores por rangos de AQI
    low_mask = y_test <= 35  # Bueno (AQI ≤ ~100)
    high_mask = y_test > 35  # Elevado
    rmse_low = np.sqrt(mean_squared_error(y_test[low_mask], y_pred_test[low_mask])) if low_mask.sum() > 0 else 0
    rmse_high = np.sqrt(mean_squared_error(y_test[high_mask], y_pred_test[high_mask])) if high_mask.sum() > 0 else 0

    metrics = {
        "horizon": f"{horizon}h",
        "train_rmse": round(train_rmse, 2),
        "test_rmse": round(test_rmse, 2),
        "test_mae": round(test_mae, 2),
        "test_r2": round(test_r2, 4),
        "rmse_low_pm25": round(rmse_low, 2),
        "rmse_high_pm25": round(rmse_high, 2),
        "train_samples": len(X_train),
        "test_samples": len(X_test),
    }

    print(f"  Train RMSE: {train_rmse:.2f} µg/m³")
    print(f"  Test  RMSE: {test_rmse:.2f} µg/m³")
    print(f"  Test  MAE:  {test_mae:.2f} µg/m³")
    print(f"  Test  R²:   {test_r2:.4f}")
    print(f"  RMSE (PM2.5 ≤35): {rmse_low:.2f} | RMSE (PM2.5 >35): {rmse_high:.2f}")

    # Feature importance
    if hasattr(model, "feature_importances_"):
        importance = sorted(
            zip(features, model.feature_importances_),
            key=lambda x: x[1],
            reverse=True,
        )
    else:
        importance = []

    return model, metrics, importance


def aqi_from_pm25(pm25):
    """Convierte PM2.5 (µg/m³) a AQI (EPA US)."""
    breakpoints = [
        (0.0, 12.0, 0, 50),
        (12.1, 35.4, 51, 100),
        (35.5, 55.4, 101, 150),
        (55.5, 150.4, 151, 200),
        (150.5, 250.4, 201, 300),
        (250.5, 350.4, 301, 400),
        (350.5, 500.4, 401, 500),
    ]
    for pm_lo, pm_hi, aqi_lo, aqi_hi in breakpoints:
        if pm25 <= pm_hi:
            return int(((aqi_hi - aqi_lo) / (pm_hi - pm_lo)) * (pm25 - pm_lo) + aqi_lo)
    return 500


def main():
    print("=" * 70)
    print("  AIRWAY — ENTRENAMIENTO DE MODELOS PM2.5")
    print("=" * 70)

    # Crear directorio de modelos
    os.makedirs(MODEL_DIR, exist_ok=True)
    print(f"\n  Modelos se guardarán en: {MODEL_DIR}")

    # Cargar datos
    train_df, test_df = load_data()

    # Features
    features = get_features(train_df)
    print(f"\n  Features ({len(features)}): {features[:10]}...")

    # Seleccionar modelo
    ModelClass, params, engine_name = get_model_class()

    # Entrenar por horizonte
    all_metrics = []
    all_importance = {}

    for horizon in HORIZONS:
        print(f"\n{'━' * 50}")
        print(f"  HORIZONTE: {horizon}h")
        print(f"{'━' * 50}")

        model, metrics, importance = train_horizon(
            train_df, test_df, features, horizon, ModelClass, params
        )

        # Guardar modelo
        import joblib
        model_path = os.path.join(MODEL_DIR, f"pm25_predictor_{horizon}h.pkl")
        joblib.dump(model, model_path)
        model_size = os.path.getsize(model_path) / (1024 * 1024)
        print(f"\n  💾 Modelo guardado: {model_path} ({model_size:.1f} MB)")

        all_metrics.append(metrics)
        all_importance[f"{horizon}h"] = importance[:20]  # Top 20

    # ── Guardar feature importance ──
    print(f"\n{'=' * 50}")
    print(f"  TOP 15 FEATURES (horizonte 1h)")
    print(f"{'=' * 50}")

    if "1h" in all_importance and all_importance["1h"]:
        importance_rows = []
        for i, (feat, imp) in enumerate(all_importance["1h"][:15]):
            bar = "█" * int(imp * 200)
            print(f"  {i+1:2d}. {feat:35s} {imp:.4f} {bar}")
            importance_rows.append({"feature": feat, "importance": imp})

        # Guardar CSV de importance
        imp_df = pd.DataFrame(importance_rows)
        imp_path = os.path.join(MODEL_DIR, "feature_importance.csv")
        imp_df.to_csv(imp_path, index=False)
        print(f"\n  📊 Feature importance: {imp_path}")

    # ── Guardar métricas ──
    metrics_path = os.path.join(MODEL_DIR, "metrics.json")
    with open(metrics_path, "w") as f:
        json.dump({
            "engine": engine_name,
            "horizons": all_metrics,
            "features_count": len(features),
            "features_list": features,
        }, f, indent=2)
    print(f"  📈 Métricas: {metrics_path}")

    # ── Guardar lista de features (necesaria para el backend) ──
    features_path = os.path.join(MODEL_DIR, "feature_names.json")
    with open(features_path, "w") as f:
        json.dump(features, f)
    print(f"  📋 Feature names: {features_path}")

    # ── Resumen final ──
    print(f"\n{'=' * 70}")
    print(f"  RESUMEN DE ENTRENAMIENTO")
    print(f"{'=' * 70}")
    print(f"\n  {'Horizonte':<12} {'RMSE':>8} {'MAE':>8} {'R²':>8} {'AQI equiv':>12}")
    print(f"  {'─' * 48}")
    for m in all_metrics:
        aqi_err = aqi_from_pm25(m["test_rmse"]) - aqi_from_pm25(0)
        quality = "🟢 Bueno" if m["test_rmse"] < 12 else "🟡 Aceptable" if m["test_rmse"] < 20 else "🟠 Mejorable"
        print(f"  {m['horizon']:<12} {m['test_rmse']:>7.2f} {m['test_mae']:>7.2f} {m['test_r2']:>7.4f}   {quality}")

    print(f"\n  Engine: {engine_name}")
    print(f"  Features: {len(features)}")
    print(f"  Train size: {all_metrics[0]['train_samples']}")
    print(f"  Test size: {all_metrics[0]['test_samples']}")

    print(f"\n✅ Modelos listos! Siguiente paso: integrar en Django backend")
    print(f"   Archivos en: {MODEL_DIR}/")


if __name__ == "__main__":
    main()
