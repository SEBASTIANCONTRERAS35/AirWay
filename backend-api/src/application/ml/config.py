"""
Constantes del sistema ContingencyCast.
Basadas en PCAA 2019 (CAMe) vigente en 2026 y NOM-172-SEMARNAT-2023.
"""
from pathlib import Path

# =========================================================================
# Umbrales oficiales CAMe (Programa Contingencias Atmosféricas 2019)
# =========================================================================
# Fuente: http://www.aire.cdmx.gob.mx/descargas/ultima-hora/calidad-aire/pcaa/
#
# Una estación RAMA rebasando el umbral en 1h promedio = activación Fase 1.
# No es discrecional — es semi-automático.
# =========================================================================

THRESHOLD_O3_FASE1_PPB = 154      # >154 ppb O3 1h → Fase 1
THRESHOLD_O3_FASE2_PPB = 204      # >204 ppb O3 1h → Fase 2
THRESHOLD_PM25_FASE1_UGM3 = 97.4  # NowCast 12h PM2.5
THRESHOLD_PM10_FASE1_UGM3 = 215   # 24h promedio PM10

# Doble contingencia: O3 >150pts + PM2.5 >140pts (o viceversa)
THRESHOLD_DOBLE_O3 = 150
THRESHOLD_DOBLE_PM25 = 140

# =========================================================================
# Horizontes de pronóstico (horas)
# =========================================================================
FORECAST_HORIZONS = [24, 48, 72]

# =========================================================================
# Geografía CDMX
# =========================================================================
CDMX_CENTER = {"lat": 19.4326, "lon": -99.1332}
CDMX_BBOX = {
    "lat_min": 19.15, "lat_max": 19.60,
    "lon_min": -99.35, "lon_max": -98.95,
}

# Radio (km) para agregación FIRMS (incendios cercanos)
FIRMS_RADIUS_KM = 100

# =========================================================================
# Ventanas temporales
# =========================================================================
# Temporada de ozono (mar-jun): alta probabilidad Fase 1 O3
OZONE_SEASON_MONTHS = [2, 3, 4, 5, 6]
# Temporada de PM (dic-feb): inversiones térmicas invernales
PM_SEASON_MONTHS = [12, 1, 2]

# =========================================================================
# Paths
# =========================================================================
BASE_DIR = Path(__file__).resolve().parents[3]   # backend-api/
DATA_DIR = BASE_DIR / "data"
RAW_DIR = DATA_DIR / "raw"
PROCESSED_DIR = DATA_DIR / "processed"
MODELS_DIR = DATA_DIR / "models"

RAMA_DIR = RAW_DIR / "rama"
OPENMETEO_FILE = RAW_DIR / "openmeteo_historical.parquet"
CONTINGENCIAS_FILE = RAW_DIR / "contingencias_ground_truth.parquet"
DATASET_FILE = PROCESSED_DIR / "dataset.parquet"
FEATURES_FILE = PROCESSED_DIR / "features.parquet"

# =========================================================================
# URLs de datos públicos
# =========================================================================
RAMA_BASE_URL = "http://datosabiertos.aire.cdmx.gob.mx:8080/opendata/anuales_horarios_gz"
OPENMETEO_ARCHIVE_URL = "https://archive-api.open-meteo.com/v1/archive"
OPENMETEO_AIRQUALITY_URL = "https://air-quality-api.open-meteo.com/v1/air-quality"

# =========================================================================
# Model hyperparams
# =========================================================================
# Train/val/test split por fecha (time-based, NUNCA random en series temporales)
# Los archivos anuales RAMA solo van hasta 2024 inclusive.
# - Train: 2015-2022 (8 años, ~70%)
# - Val:   2023       (~12%)
# - Test:  2024       (~18%, año récord con más contingencias → evalúa caso real)
TRAIN_END = "2022-12-31"
VAL_END = "2023-12-31"
# Test: 2024-01-01 → 2024-12-12 (presente archivado)

# Target: rebase de 154 ppb O3 en alguna estación durante próximas N horas
TARGET_COLUMN_TEMPLATE = "y_{horizon}h"
