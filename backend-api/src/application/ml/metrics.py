"""
Métricas especializadas para predicción de contingencias (clase desbalanceada).

Evita usar accuracy y ROC-AUC (inútiles con ~2% de positivos).
Prioriza métricas que la comunidad operacional de calidad del aire usa:
    POD, FAR, CSI (categóricas)
    PR-AUC, Brier, ECE (probabilísticas)
"""
from __future__ import annotations

from typing import Any

import numpy as np
from sklearn.metrics import (
    average_precision_score,
    brier_score_loss,
    confusion_matrix,
    f1_score,
)


def event_metrics(y_true: np.ndarray, y_prob: np.ndarray, threshold: float = 0.5) -> dict[str, float]:
    """
    Métricas categóricas a un umbral dado.

    POD (Probability of Detection / Recall):   TP / (TP + FN)
        → porcentaje de contingencias REALES que detectamos
    FAR (False Alarm Ratio):                   FP / (FP + TP)
        → porcentaje de nuestras alarmas que fueron falsas
    CSI (Critical Success Index):              TP / (TP + FP + FN)
        → balance POD/FAR, ignora true negatives (útil cuando TN domina)
    """
    y_pred = (y_prob > threshold).astype(int)
    tn, fp, fn, tp = confusion_matrix(y_true, y_pred, labels=[0, 1]).ravel()

    pod = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    far = fp / (fp + tp) if (fp + tp) > 0 else 0.0
    csi = tp / (tp + fp + fn) if (tp + fp + fn) > 0 else 0.0
    f1 = f1_score(y_true, y_pred, zero_division=0)

    return {
        "POD": float(pod),
        "FAR": float(far),
        "CSI": float(csi),
        "F1": float(f1),
        "TP": int(tp),
        "FP": int(fp),
        "FN": int(fn),
        "TN": int(tn),
    }


def probability_metrics(y_true: np.ndarray, y_prob: np.ndarray, n_bins: int = 10) -> dict[str, Any]:
    """
    Métricas probabilísticas (continuas sobre y_prob).

    PR-AUC: Area bajo la curva Precision-Recall (mejor que ROC con desbalance).
    Brier: MSE sobre probabilidades (strictly proper scoring rule).
    ECE:   Expected Calibration Error — diff entre prob. predicha y frecuencia real.
    """
    pr_auc = float(average_precision_score(y_true, y_prob)) if y_true.sum() > 0 else 0.0
    brier = float(brier_score_loss(y_true, y_prob))

    # Expected Calibration Error
    bins = np.linspace(0, 1, n_bins + 1)
    ece_val = 0.0
    reliability = []
    for i in range(n_bins):
        mask = (y_prob >= bins[i]) & (y_prob < bins[i + 1])
        if i == n_bins - 1:
            mask = mask | (y_prob == 1.0)
        if mask.sum() == 0:
            reliability.append({"bin": float((bins[i] + bins[i + 1]) / 2), "actual": None, "count": 0})
            continue
        bin_prob = float(y_prob[mask].mean())
        bin_actual = float(y_true[mask].mean())
        ece_val += (mask.sum() / len(y_true)) * abs(bin_prob - bin_actual)
        reliability.append({"bin": bin_prob, "actual": bin_actual, "count": int(mask.sum())})

    return {
        "PR-AUC": pr_auc,
        "Brier": brier,
        "ECE": float(ece_val),
        "reliability": reliability,
    }


def best_threshold(y_true: np.ndarray, y_prob: np.ndarray) -> tuple[float, dict[str, float]]:
    """Escanea umbrales 0.05–0.95 y devuelve el que maximiza CSI."""
    best_t, best_metrics = 0.5, {"CSI": -1.0}
    for t in np.linspace(0.05, 0.95, 19):
        m = event_metrics(y_true, y_prob, threshold=float(t))
        if m["CSI"] > best_metrics["CSI"]:
            best_t, best_metrics = float(t), m
    return best_t, best_metrics


def full_report(y_true: np.ndarray, y_prob: np.ndarray) -> dict[str, Any]:
    """Reporte completo: categóricas @ 0.5 y @ best_csi + probabilísticas."""
    m_half = event_metrics(y_true, y_prob, threshold=0.5)
    t_best, m_best = best_threshold(y_true, y_prob)
    m_prob = probability_metrics(y_true, y_prob)

    return {
        "at_threshold_0.5": m_half,
        "at_best_csi_threshold": {**m_best, "threshold": t_best},
        "probabilistic": m_prob,
        "n_samples": int(len(y_true)),
        "n_positive": int(y_true.sum()),
        "positive_rate": float(y_true.mean()),
    }


def format_report(report: dict[str, Any], name: str = "") -> str:
    """Pretty-print para logging."""
    m05 = report["at_threshold_0.5"]
    mbest = report["at_best_csi_threshold"]
    mp = report["probabilistic"]
    return (
        f"[{name}] n={report['n_samples']:,} pos={report['n_positive']:,} "
        f"({100 * report['positive_rate']:.1f}%)\n"
        f"  @0.5  POD={m05['POD']:.2f} FAR={m05['FAR']:.2f} CSI={m05['CSI']:.2f} "
        f"F1={m05['F1']:.2f}\n"
        f"  @best POD={mbest['POD']:.2f} FAR={mbest['FAR']:.2f} CSI={mbest['CSI']:.2f} "
        f"(t={mbest['threshold']:.2f})\n"
        f"  prob  PR-AUC={mp['PR-AUC']:.2f} Brier={mp['Brier']:.4f} ECE={mp['ECE']:.4f}"
    )
