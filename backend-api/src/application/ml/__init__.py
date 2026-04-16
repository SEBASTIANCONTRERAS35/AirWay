"""
ContingencyCast — Predicción probabilística de contingencias atmosféricas CDMX.

Módulos:
    config         — constantes (umbrales CAMe, coordenadas, horizontes)
    build_dataset  — unifica RAMA + Open-Meteo + ground truth
    features       — feature engineering (lags, rolling, cíclicas, interacciones)
    train_baseline — Random Forest baseline
    train_xgb      — XGBoost multi-horizon con desbalance
    train_quantile — Regresión por cuantiles + calibración
    inference      — Servicio de predicción en tiempo real
"""
