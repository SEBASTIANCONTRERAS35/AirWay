"""
Time-based splits para series temporales.

NUNCA usar random split en pronóstico temporal — filtra información del futuro
al pasado y produce métricas infladas (data leakage).
"""
from __future__ import annotations

import pandas as pd

from application.ml.config import TRAIN_END, VAL_END


def time_split(df: pd.DataFrame, timestamp_col: str = "timestamp") -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Train: <=TRAIN_END, Val: (TRAIN_END, VAL_END], Test: >VAL_END."""
    df = df.sort_values(timestamp_col).reset_index(drop=True)
    train = df[df[timestamp_col] <= TRAIN_END]
    val = df[(df[timestamp_col] > TRAIN_END) & (df[timestamp_col] <= VAL_END)]
    test = df[df[timestamp_col] > VAL_END]
    return train, val, test
