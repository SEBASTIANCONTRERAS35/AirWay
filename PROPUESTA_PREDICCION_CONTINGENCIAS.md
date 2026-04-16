# AirWay — ContingencyCast: Predicción de Contingencias CDMX

**Propuesta técnica integral** · Hackathon Swift Changemakers 2026
**Target:** Predecir con 48-72h de anticipación la probabilidad de que CAMe declare Contingencia Ambiental Atmosférica (Fase 1, Fase 2, Doble Contingencia) en ZMVM.
**Ventaja competitiva vs. SEDEMA:** SEDEMA solo pronostica **24h**. Nosotros: **48-72h con probabilidad calibrada**.
**Fecha:** 16 de abril 2026

---

## Tabla de Contenido

1. [El problema y la oportunidad](#problema)
2. [Cómo funcionan las contingencias (lo que el modelo debe predecir)](#contingencias)
3. [Arquitectura del sistema](#arquitectura)
4. [Stack de Machine Learning](#stack-ml)
5. [Feature Engineering — Tabla maestra](#features)
6. [Datasets y pipeline de datos](#datasets)
7. [Métricas de evaluación](#metricas)
8. [UX iOS — Cómo presentarlo al usuario](#ux)
9. [Plan de implementación (2 días hackathon)](#plan)
10. [Riesgos y mitigaciones](#riesgos)
11. [Narrativa de pitch](#pitch)
12. [Fuentes](#fuentes)

---

## <a id="problema"></a>1. El problema y la oportunidad

### Pain point real (datos 2024-2026)

- **2024**: 12 contingencias (empata el récord de 1993).
- **2025**: 7-8 Fase 1 + 1 por PM2.5 + ondas de calor.
- **2026 ene-abr**: 10+ días de Fase 1, se **duplican** vs 2025. Proyección CAMe: hasta **15 días de Doble Hoy No Circula** en 2026.
- **Aviso actual**: CAMe decreta entre 14:00-17:00 y el Doble Hoy No Circula aplica al día siguiente 5:00 → **<15 horas de aviso efectivo**.
- **Afectados**: ~1.7 millones de vehículos adicionales, ~22 millones de habitantes.
- **Impacto económico 2024**: 832,799 millones MXN (2.5% del PIB) por degradación del aire (INEGI).

### ¿Por qué SEDEMA no lo hace ya?

SEDEMA tiene WRF-ARW + CMAQ con resolución 1 km², pero:
- Horizonte: **solo 24 horas**
- Actualización: **1 vez al día (09:00 AM)**
- No publica probabilidad de contingencia, solo valores puntuales
- No hay API REST pública (solo CSV + dashboard)
- Precisión no publicada abiertamente

### La brecha que AirWay llena

| Dimensión | SEDEMA oficial | AirWay ContingencyCast |
|---|---|---|
| Horizonte | 24h | **48-72h** |
| Actualización | 1/día | **1/hora** |
| Output | Valores O3, PM2.5 | **Probabilidad calibrada de Fase 1/2/Doble** |
| Acceso | Scraping CSV | **API REST + push iOS** |
| Personalización | Ninguna | Por usuario (tu ruta, tu auto, tu trabajo) |
| Acción | Lectura pasiva | **"Mañana 78% prob Fase 1 → plan B listo"** |

---

## <a id="contingencias"></a>2. Cómo funcionan las contingencias (target del modelo)

### Umbrales EXACTOS de activación (PCAA 2019, vigente)

| Fase | O3 (1h promedio) | PM10 (24h) | PM2.5 (NowCast 12h) |
|---|---|---|---|
| **Preventiva** | 140 pts Índice + pronóstico ≥70% | 135 pts | 135 pts |
| **Fase 1** | **>154 ppb / 150 pts** en ≥1 estación | **>150 pts** (~215 µg/m³) | **>150 pts** (~97-99 µg/m³) |
| **Fase 2** | >200 pts | >200 pts | >200 pts |
| **Doble** | O3 >150 pts **+** PM2.5 >140 pts (o viceversa) | | |

### Proceso de decisión (SEMI-AUTOMÁTICO)

1. **Quién decide**: CAMe (Comisión Ambiental de la Megalópolis)
2. **Cuándo revisan**: Cada ~5h (comunicados 10:00, 15:00, 20:00)
3. **Cómo activan**: **SEMI-AUTOMÁTICO** — si se rebasa umbral en ≥1 estación RAMA, se activa en la hora siguiente (no es discrecional)
4. **Geografía**: Puede ser regional (NE, SE, SO, NO, Centro) o ZMVM completa
5. **Ventana crítica**: Activación típica O3 es 14:00-17:00 (pico fotoquímico); PM2.5 es 22:00-09:00 (inversión nocturna)

### Restricciones activadas

**Fase 1 O3 (típica)**:
- Doble Hoy No Circula (suma engomado normal + engomado extra)
- Holograma 2: NO circula
- Industria: reducción 40% emisiones precursores
- Refinería Tula: tope 75% capacidad
- Evitar ejercicio outdoor 13:00-19:00

**Fase 2 (nunca activada desde 2017)**:
- Industria: 60% reducción
- **Suspensión de clases todos los niveles**
- Hornos artesanales: paro total
- Home office recomendado

### Casos detonantes reales 2025-2026 (para calibrar modelo)

| Fecha | Estación | Valor | Fase |
|---|---|---|---|
| 1 ene 2024 10:00 | Santiago Acahualtepec | 99.5 µg/m³ PM2.5 | Fase 1 PM2.5 |
| 18 mar 2025 | Gustavo A. Madero | 155 ppb O3 | Fase 1 O3 |
| 1 abr 2025 | — | 166 ppb O3 | Fase 1 O3 |
| 25 abr 2025 | Ajusco Medio | 159 ppb O3 | Fase 1 O3 |
| 10 mar 2026 | Acatlán | 159 ppb O3 | Fase 1 O3 |

### Lo que esto implica técnicamente

El target del modelo es **booleano**:

```python
y_target = 1 if (max_O3_1h_across_stations > 154 ppb) in next_24h else 0
```

Pero lo que queremos REALMENTE es `P(y_target = 1)` con calibración — no una decisión dura.

---

## <a id="arquitectura"></a>3. Arquitectura del sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                         CAPA DE DATOS                           │
├─────────────────────────────────────────────────────────────────┤
│  RAMA CSV horario        Open-Meteo forecast     TEMPO L3       │
│  aire.cdmx.gob.mx       air-quality API          NASA Earthdata │
│  (minuto a minuto)       (5 días, sin key)       (hora, NO2)    │
│                                                                 │
│  FIRMS fires             CAMS Global             Sentinel-5P    │
│  MAP_KEY gratis          (5 días forecast)       diario         │
│  VIIRS NRT               ECMWF                   NO2, SO2, CO   │
│                                                                 │
│  ERA5 PBLH               Calendarios             @CAMegalopolis │
│  capa de mezcla          HNC + festivos          Twitter scraper│
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA DE INGESTION (Airflow/Celery)           │
│  - Hourly pull de cada fuente                                   │
│  - Great Expectations validation                                │
│  - TimescaleDB (timescale hypertables)                          │
│  - S3 Parquet para satélite                                     │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                 CAPA DE FEATURE ENGINEERING                     │
│  - Lags (1,3,6,12,24,48,72,168h)                               │
│  - Rolling stats (mean, std, max)                               │
│  - Encoding cíclico (hora, día, mes)                            │
│  - Interacciones (T×rad, PBLH×wind)                             │
│  - Gradiente vertical (dT/dz) → inversión                       │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                 CAPA DE MODELOS ML                              │
│  ┌──────────────────┐  ┌────────────────────┐                  │
│  │ MODELO CONTINUO  │  │ MODELO EVENTO      │                  │
│  │ (regresión)      │  │ (clasificación)    │                  │
│  │                  │  │                    │                  │
│  │ XGBoost quantile │  │ XGBoost + SMOTE    │                  │
│  │ (q10, q50, q90)  │  │ focal loss         │                  │
│  │                  │  │                    │                  │
│  │ Output:          │  │ Output:            │                  │
│  │ O3(h+24,48,72)   │  │ P(Fase1) por hora  │                  │
│  │ con IC 80%       │  │ P(Fase2)           │                  │
│  │                  │  │ P(Doble Cont.)     │                  │
│  └──────────────────┘  └────────────────────┘                  │
│                            │                                   │
│  CONFORMAL PREDICTION ──┬──┘                                   │
│  (CQR para garantía 80% coverage)                              │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                 CAPA DE APLICACIÓN                              │
│  ┌──────────────────┐  ┌────────────────────┐                  │
│  │ Django REST API  │  │ Push Notifications │                  │
│  │ /forecast        │  │ APNS               │                  │
│  │ /contingency     │  │                    │                  │
│  │ /explanation     │  │                    │                  │
│  └──────────────────┘  └────────────────────┘                  │
│                            │                                   │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                 CAPA iOS                                        │
│  - ContingencyCastView (principal)                              │
│  - Widget Lock Screen (probabilidad siempre visible)            │
│  - Live Activity (cuando P > 50%)                               │
│  - Foundation Models (explicación natural)                      │
│  - Push proactivo 48h antes si P > 60%                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## <a id="stack-ml"></a>4. Stack de Machine Learning

### Tier 1: BASELINE (Día 1, 4-6h) — imprescindible

**Random Forest + XGBoost baseline**

```python
# Target: clasificación binaria contingencia en h+24
from sklearn.ensemble import RandomForestClassifier
from xgboost import XGBClassifier

# Baseline Random Forest (warm-up)
baseline = RandomForestClassifier(
    n_estimators=300,
    class_weight='balanced',   # crítico por desbalanceo
    max_depth=15,
    random_state=42
)

# Target XGBoost con scale_pos_weight
pos = (y_train == 1).sum()
neg = (y_train == 0).sum()
scale = neg / pos  # ej. ~50:1 (98% días sin contingencia)

model = XGBClassifier(
    objective='binary:logistic',
    scale_pos_weight=scale,
    max_depth=6,
    learning_rate=0.05,
    n_estimators=500,
    subsample=0.8,
    colsample_bytree=0.8,
    eval_metric='aucpr',  # PR-AUC > ROC para desbalance
    early_stopping_rounds=50
)
```

**Por qué:** Gradient boosting domina benchmarks de calidad del aire en horizontes ≤72h (MDPI Appl Sci 2024 CDMX). UNAM ICAyCC baseline: R²=0.73 a h+24 con WRF + ML. Nuestro objetivo mínimo: superar esto.

### Tier 2: TARGET (Día 2, 4-6h) — diferenciador

**XGBoost Quantile Regression + Conformal Prediction**

```python
# 3 modelos: q10, q50, q90 → intervalo 80%
from xgboost import XGBRegressor

def train_quantile(X, y, quantile):
    return XGBRegressor(
        objective='reg:quantileerror',
        quantile_alpha=quantile,
        n_estimators=500,
        max_depth=6,
        learning_rate=0.05
    ).fit(X, y)

m_q10 = train_quantile(X_train, y_train, 0.10)
m_q50 = train_quantile(X_train, y_train, 0.50)
m_q90 = train_quantile(X_train, y_train, 0.90)

# P(O3 > 154) vía interpolación monótona
from scipy.interpolate import PchipInterpolator

def p_exceedance(q10_hat, q50_hat, q90_hat, threshold=154):
    # Construye CDF puntual
    quantiles = [0.10, 0.50, 0.90]
    values = [q10_hat, q50_hat, q90_hat]
    cdf = PchipInterpolator(values, quantiles, extrapolate=True)
    p_leq = np.clip(cdf(threshold), 0, 1)
    return 1 - p_leq  # P(X > threshold)
```

**Conformal Prediction (para garantía estadística):**

```python
from mapie.regression import MapieQuantileRegressor

# CQR: intervalos con 80% coverage garantizado
mapie = MapieQuantileRegressor(
    estimator=m_q50,
    alpha=0.20,  # 1 - coverage
    method='quantile'
)
mapie.fit(X_train, y_train, X_calib=X_val, y_calib=y_val)
y_pred, y_intervals = mapie.predict(X_test)
# y_intervals: [n, 2] con límites inferior y superior CALIBRADOS
```

**Por qué conformal:** Garantía **distribution-free** de que el 80% de los intervalos contendrán el valor real. Único método con rigor matemático para comunicar incertidumbre al usuario.

### Tier 3: ASPIRACIONAL (solo si hay tiempo)

**iTransformer para multi-estación multi-contaminante** — ICLR 2024 Spotlight. Invierte atención axis → cada variate es token. PyTorch: `thuml/iTransformer`. ~100 líneas vía neuralforecast.

**E-STGCN (Extreme Spatiotemporal GCN)** — J Royal Stat Soc 2025. GCN + LSTM + módulo EVT con Peaks-Over-Threshold loss. Explícitamente diseñado para eventos extremos. GitHub: `mad-stat/E_STGCN`.

**Anti-recomendación para 2 días:** AirPhyNet (physics-informed, semanas de trabajo), Time-LLM (NeurIPS 2024 demostró que LLMs body añade poco vs baselines shallow), Bayesian NNs (hiperparámetros sensibles).

### Ensemble propuesto (simple pero potente)

```python
# Stacking: XGBoost (regresión q50) + XGBoost (clasificación) + Random Forest
final_prob = (
    0.5 * p_exceedance_from_quantile +
    0.3 * xgb_classifier.predict_proba()[:, 1] +
    0.2 * rf_baseline.predict_proba()[:, 1]
)
# Calibrar con Platt/Isotonic en val set
from sklearn.calibration import CalibratedClassifierCV
```

---

## <a id="features"></a>5. Feature Engineering — Tabla Maestra

### TOP 30 Features (priorizado por literatura SHAP)

| # | Feature | Fuente | Lag/Window | Tipo |
|---|---|---|---|---|
| 1 | `o3_lag_1h` | RAMA | 1h | Continua |
| 2 | `o3_lag_24h` | RAMA | 24h | Continua |
| 3 | `o3_roll_max_24h` | Derivada | 24h | Continua |
| 4 | `pm25_lag_1h` | RAMA | 1h | Continua |
| 5 | `pm25_lag_24h` | RAMA | 24h | Continua |
| 6 | `no2_lag_1h` | RAMA | 1h | Continua |
| 7 | `temp_2m` | Open-Meteo | 0h | Continua |
| 8 | `temp_850hPa` | Open-Meteo | 0h | Continua |
| 9 | `dT_dz` = T2m - T850hPa | Derivada | 0h | **INVERSIÓN** |
| 10 | `relative_humidity_2m` | Open-Meteo | 0h | Continua |
| 11 | `shortwave_radiation` | Open-Meteo | 0h | Continua |
| 12 | `uv_index` | Open-Meteo | 0h | Continua |
| 13 | `wind_speed_10m` | Open-Meteo | 0h | Continua |
| 14 | `wind_dir_sin` | Open-Meteo | 0h | Cíclica |
| 15 | `wind_dir_cos` | Open-Meteo | 0h | Cíclica |
| 16 | `surface_pressure` | Open-Meteo | 0h | Continua |
| 17 | `pblh` (altura capa mezcla) | ERA5 | 0h | **CRÍTICO CDMX** |
| 18 | `vent_idx` = PBLH × wind | Derivada | 0h | Dispersión |
| 19 | `stagnation_flag` | Derivada | 0h | Binaria |
| 20 | `T_x_rad` = T × radiación | Derivada | 0h | Interacción O3 |
| 21 | `tempo_no2_columnar` | TEMPO | 0-1h | Satelital |
| 22 | `modis_aod` | MODIS MAIAC | 1d | Proxy PM2.5 |
| 23 | `firms_hotspots_100km_72h` | FIRMS | 72h | Incendios |
| 24 | `cams_o3_forecast` | CAMS | 0h | Modelo físico |
| 25 | `hour_sin`, `hour_cos` | Derivada | 0h | Cíclica |
| 26 | `doy_sin`, `doy_cos` | Derivada | 0h | Cíclica |
| 27 | `is_ozone_season` | Calendario | 0h | Binaria |
| 28 | `is_weekend` | Calendario | 0h | Binaria |
| 29 | `days_since_last_fase1` | Derivada | — | Contador |
| 30 | `aqi_toluca_lag_6h` | SINAICA | 6h | Regional |

### Feature engineering crítico (código Python)

```python
import numpy as np
import pandas as pd

def engineer_features(df):
    """
    df: DataFrame con columnas por estación y por pollutante, indexed by hora.
    """
    # ===== Lags contaminantes =====
    for pollutant in ['o3', 'pm25', 'pm10', 'no2', 'co', 'so2']:
        for lag in [1, 3, 6, 12, 24, 48, 72, 168]:
            df[f'{pollutant}_lag_{lag}'] = df[pollutant].shift(lag)
    
    # ===== Rolling statistics =====
    for pollutant in ['o3', 'pm25']:
        for window in [6, 12, 24, 72]:
            df[f'{pollutant}_roll_mean_{window}'] = df[pollutant].rolling(window).mean()
            df[f'{pollutant}_roll_max_{window}'] = df[pollutant].rolling(window).max()
            df[f'{pollutant}_roll_std_{window}'] = df[pollutant].rolling(window).std()
    
    # ===== Tendencias =====
    df['o3_trend_3h'] = df['o3'] - df['o3'].shift(3)
    df['o3_trend_24h'] = df['o3'] - df['o3'].shift(24)
    
    # ===== Inversión térmica (gradiente vertical) =====
    df['dT_dz'] = df['temp_2m'] - df['temp_850hPa']
    df['inversion_flag'] = (df['dT_dz'] > 0).astype(int)
    
    # ===== Ventilación / estancamiento =====
    df['u_wind'] = df['wind_speed_10m'] * np.cos(np.radians(df['wind_dir']))
    df['v_wind'] = df['wind_speed_10m'] * np.sin(np.radians(df['wind_dir']))
    df['vent_idx'] = df['pblh'] * df['wind_speed_10m']
    df['stagnation'] = ((df['wind_speed_10m'] < 2) & (df['pblh'] < 500)).astype(int)
    
    # ===== Interacciones fotoquímicas (drivers de O3) =====
    df['T_x_rad'] = df['temp_2m'] * df['shortwave_radiation']
    df['T_x_uv'] = df['temp_2m'] * df['uv_index']
    df['rad_squared'] = df['shortwave_radiation'] ** 2
    
    # ===== Higroscopicidad (PM2.5) =====
    df['rh_squared'] = df['relative_humidity_2m'] ** 2
    df['rh_above_75'] = (df['relative_humidity_2m'] > 75).astype(int)
    
    # ===== Encoding cíclico (OBLIGATORIO, no usar int plano) =====
    df['hour_sin'] = np.sin(2 * np.pi * df.index.hour / 24)
    df['hour_cos'] = np.cos(2 * np.pi * df.index.hour / 24)
    df['doy_sin']  = np.sin(2 * np.pi * df.index.dayofyear / 365.25)
    df['doy_cos']  = np.cos(2 * np.pi * df.index.dayofyear / 365.25)
    df['wdir_sin'] = np.sin(np.radians(df['wind_dir']))
    df['wdir_cos'] = np.cos(np.radians(df['wind_dir']))
    
    # ===== Temporada ozono CDMX =====
    month = df.index.month
    df['is_ozone_season'] = ((month >= 2) & (month <= 6)).astype(int)
    df['is_pm_season'] = ((month == 12) | (month == 1) | (month == 2)).astype(int)
    df['is_weekend'] = (df.index.dayofweek >= 5).astype(int)
    
    # ===== Target (binario) =====
    # Predecir si en próximas 24h alguna estación rebasará 154 ppb
    df['y_target_24h'] = (
        df['o3'].shift(-24).rolling(24).max() > 154
    ).astype(int)
    
    return df
```

### Ranking de importancia esperado (SHAP literature)

1. `o3_lag_1h` (persistencia)
2. `o3_lag_24h` (patrón diario)
3. `temp_2m` + `T_x_rad` (fotoquímica)
4. `pblh` (dilución vertical)
5. `wind_speed_10m` + `vent_idx`
6. `relative_humidity_2m`
7. `dT_dz` (inversión)
8. `hour_sin/cos`
9. `tempo_no2_columnar`
10. `o3_roll_max_72h`

---

## <a id="datasets"></a>6. Datasets y Pipeline de Datos

### Fuentes primarias (todo gratis, sin autenticación corporativa)

| Dataset | Histórico | URL | Formato |
|---|---|---|---|
| **RAMA horario** | 1986-presente | `aire.cdmx.gob.mx/descargas/Opendata/...` | CSV.gz |
| **RAMA anuales** | 1986-presente | `datosabiertos.aire.cdmx.gob.mx:8080/opendata/anuales_horarios_gz/contaminantes_{YEAR}.csv.gz` | CSV.gz |
| **Catálogo estaciones** | — | `aire.cdmx.gob.mx/descargas/Opendata/Bases_publicas/Data%20Set/catalogos/cat_estacion.csv` | CSV |
| **Open-Meteo Historical** | 1940-presente | `/v1/archive` sin API key | JSON |
| **Open-Meteo Air Quality** | 5 días forecast | `/v1/air-quality` sin API key | JSON |
| **ERA5 reanalysis** | 1940-presente | `cds.climate.copernicus.eu` + `cdsapi` | NetCDF |
| **CAMS Global Forecast** | NRT + 5 días | `ads.atmosphere.copernicus.eu` | NetCDF |
| **TEMPO L3** | 2023-presente | `earthdata.nasa.gov/data/instruments/tempo` | NetCDF |
| **FIRMS API** | 2000-presente | `firms.modaps.eosdis.nasa.gov/api/area/csv/{KEY}/VIIRS_SNPP_NRT/...` | CSV |
| **Contingencias históricas** | 1993-presente | `aire.cdmx.gob.mx/descargas/ultima-hora/calidad-aire/pcaa/pcaa-historico-contingencias.pdf` | PDF (parsear) |
| **@CAMegalopolis** | 2014-presente | Twitter scraping | JSON |

### Script de descarga histórica (backfill)

```python
# backend-api/scripts/download_historical_rama.py
import requests
import pandas as pd
from pathlib import Path

YEARS = range(2015, 2027)  # 12 años para entrenamiento
BASE_URL = "http://datosabiertos.aire.cdmx.gob.mx:8080/opendata/anuales_horarios_gz"

def download_rama_year(year):
    url = f"{BASE_URL}/contaminantes_{year}.csv.gz"
    output = Path(f"data/raw/rama_{year}.csv.gz")
    if not output.exists():
        r = requests.get(url, timeout=60)
        r.raise_for_status()
        output.write_bytes(r.content)
    return pd.read_csv(output, compression='gzip')

all_data = pd.concat([download_rama_year(y) for y in YEARS])
all_data.to_parquet('data/processed/rama_2015_2026.parquet')
# ~10 GB compressed, ~100M rows
```

### Parser de contingencias históricas (ground truth)

```python
# backend-api/scripts/parse_contingencias_history.py
# Scrapea PDF oficial de CAMe + tweets @CAMegalopolis
import pdfplumber
import pandas as pd
import re

def parse_pcaa_pdf(pdf_path):
    events = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            # Regex para fechas + estación + valor
            pattern = r'(\d{1,2}\s+\w+\s+\d{4}).*?(\d+)\s*(?:ppb|µg/m³)'
            matches = re.findall(pattern, text)
            events.extend(matches)
    return pd.DataFrame(events, columns=['fecha', 'valor'])

# + Scraping tweets @CAMegalopolis vía Nitter / Twitter API
```

### Pipeline NRT (producción)

```python
# Airflow DAG simplificado
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import timedelta

dag = DAG(
    'aq_forecast_hourly',
    schedule_interval='0 * * * *',  # cada hora
    start_date=days_ago(1)
)

fetch_rama = PythonOperator(task_id='fetch_rama', ...)
fetch_openmeteo = PythonOperator(task_id='fetch_openmeteo', ...)
fetch_tempo = PythonOperator(task_id='fetch_tempo', ...)
fetch_firms = PythonOperator(task_id='fetch_firms', ...)
fetch_cams = PythonOperator(task_id='fetch_cams', ...)

engineer_features = PythonOperator(task_id='features', ...)
run_inference = PythonOperator(task_id='inference', ...)
push_to_api = PythonOperator(task_id='publish', ...)

[fetch_rama, fetch_openmeteo, fetch_tempo, fetch_firms, fetch_cams] \
    >> engineer_features >> run_inference >> push_to_api
```

---

## <a id="metricas"></a>7. Métricas de Evaluación

### Por qué NO usar accuracy ni ROC-AUC

- **Accuracy**: 98% "baseline" simplemente diciendo "no habrá contingencia" → inútil.
- **ROC-AUC**: poco sensible a rate de alarmas falsas en eventos raros.

### Métricas correctas

#### Categóricas (con threshold fijo de prob. ej. 50%)

```python
from sklearn.metrics import confusion_matrix, f1_score, precision_recall_curve, average_precision_score

def event_metrics(y_true, y_prob, threshold=0.5):
    y_pred = (y_prob > threshold).astype(int)
    tn, fp, fn, tp = confusion_matrix(y_true, y_pred).ravel()
    
    pod = tp / (tp + fn) if (tp + fn) > 0 else 0  # Probability of Detection
    far = fp / (fp + tp) if (fp + tp) > 0 else 0  # False Alarm Ratio
    csi = tp / (tp + fp + fn) if (tp + fp + fn) > 0 else 0  # Critical Success Index
    f1 = f1_score(y_true, y_pred)
    pr_auc = average_precision_score(y_true, y_prob)
    
    return {
        'POD': pod,       # % de contingencias reales detectadas (recall)
        'FAR': far,       # % de alarmas que fueron falsas
        'CSI': csi,       # balance POD-FAR, ignora true negatives
        'F1': f1,
        'PR-AUC': pr_auc  # única métrica robusta a clase desbalanceada
    }
```

#### Probabilísticas

```python
from sklearn.metrics import brier_score_loss
from scipy.stats import pointbiserialr

def prob_metrics(y_true, y_prob):
    brier = brier_score_loss(y_true, y_prob)
    
    # Reliability diagram
    bins = np.linspace(0, 1, 11)
    bin_centers = (bins[:-1] + bins[1:]) / 2
    bin_actual = []
    for i in range(10):
        mask = (y_prob >= bins[i]) & (y_prob < bins[i+1])
        bin_actual.append(y_true[mask].mean() if mask.sum() > 0 else np.nan)
    
    # ECE (Expected Calibration Error)
    ece = np.mean(np.abs(bin_centers - np.array(bin_actual)))
    
    return {
        'Brier': brier,    # <0.05 es excelente, <0.10 bueno
        'ECE': ece,        # error de calibración, <0.05 deseable
        'reliability': list(zip(bin_centers, bin_actual))
    }
```

### Targets de performance (para pitch)

| Métrica | Baseline ingenuo | Meta hackathon | SEDEMA (inferido) |
|---|---|---|---|
| POD @ h+24 | 0.50 | **>0.70** | ~0.65 |
| FAR @ h+24 | 0.60 | **<0.30** | ~0.40 |
| CSI @ h+24 | 0.25 | **>0.45** | ~0.35 |
| PR-AUC @ h+24 | 0.15 | **>0.50** | ~0.40 |
| Brier score | 0.08 | **<0.04** | ~0.06 |

### Benchmark MUST-BEAT: UNAM ICAyCC 2024

Publicación: Zavala-Romero et al. (Atmos Env 2024). R²=0.82 a h+1, 0.73 a h+24 en O3 valor continuo. Nuestro objetivo: superar en **h+48 y h+72** (horizonte que ellos no cubren).

---

## <a id="ux"></a>8. UX iOS — Cómo presentarlo al usuario

### Principios HCAI

1. **Incertidumbre visible**: nunca "mañana habrá contingencia". Siempre "78% de probabilidad".
2. **Acción concreta**: cada pantalla sugiere qué hacer ("mueve tu junta", "carga tu Suburban hoy", "lleva cubrebocas mañana").
3. **Contexto educativo**: botón "¿por qué?" que explica con Foundation Models los drivers.
4. **Control humano**: el usuario puede desactivar alertas, ajustar threshold personal.

### Pantalla principal: "ContingencyCast"

```
┌───────────────────────────────────────┐
│  📅 Pronóstico contingencia CDMX      │
│                                       │
│  ╭──────────────╮                    │
│  │     78%      │ ← gauge animado    │
│  │   Mañana     │   (se llena color) │
│  │ prob. Fase 1 │                    │
│  ╰──────────────╯                    │
│                                       │
│  Ventana crítica: Mar 17, 14:00-17:00│
│  Contaminante: O3 (Ozono)            │
│  Zona más probable: Suroeste         │
│                                       │
│  ¿Por qué?                            │
│  • Temperatura máx: 28°C (+3° vs avg)│
│  • Radiación UV: extrema (índice 10) │
│  • Viento débil: 2 m/s               │
│  • Inversión térmica detectada       │
│                                       │
│  ¿Qué hacer?                          │
│  ✓ Carga gasolina HOY (mañana doble  │
│    Hoy No Circula probable)          │
│  ✓ Llevar cubrebocas N95              │
│  ✓ Postponer ejercicio outdoor       │
│                                       │
│  [Configurar alertas] [Ver horas]    │
└───────────────────────────────────────┘
```

### Widget Lock Screen (siempre visible)

```
┌─────────────┐
│ ⚠️  72%     │
│ Contingencia│
│ en 36h      │
└─────────────┘
```

Colores dinámicos:
- 0-30%: Verde
- 30-60%: Amarillo
- 60-80%: Naranja
- 80-100%: Rojo (+ pulse animation)

### Live Activity (cuando P > 50%)

En Dynamic Island:
```
🔴  ContingencyCast: 78% mañana 14:00
```

Expandida:
```
┌──────────────────────────────────────┐
│ Probabilidad contingencia mañana:    │
│ ██████████████████░░░░  78%         │
│                                      │
│ Pico esperado: 14:00-17:00          │
│ Tu zona (Miguel Hidalgo): 82%        │
└──────────────────────────────────────┘
```

### Push proactivo (48h antes si P > 60%)

**Formato**: notificación rica con acciones.

```
[AirWay]
⚠️  Alta probabilidad contingencia viernes
72% prob. Fase 1 Ozono — Acciones recomendadas
[Ver plan] [Recordar 24h antes] [No molestar]
```

### Foundation Models: explicación natural

```swift
@Generable
struct ContingencyExplanation {
    let probability: Double
    let drivers: [String]          // ["Inversión térmica", "UV extrema"]
    let userActions: [String]       // ["Carga gasolina hoy", ...]
    let confidence: ConfidenceLevel // .low, .medium, .high
    let reasoning: String           // párrafo en español natural
}

enum ConfidenceLevel {
    case low, medium, high
}

// Uso
let session = LanguageModelSession(instructions: """
    Eres un meteorólogo especializado en calidad del aire en CDMX.
    Explica al usuario en español llano (primaria) por qué hay
    probabilidad de contingencia y qué debe hacer.
    NUNCA des certezas absolutas — siempre usa "probablemente",
    "probabilidad alta/baja", "modelo estima".
""")

let explanation = try await session.respond(
    to: """
    Datos actuales:
    - Probabilidad Fase 1 O3 mañana: 78%
    - IC 80%: [65%, 89%]
    - Drivers top: T=28°C, UV=10, viento=2m/s, inversión=SI
    - Usuario: vive Miguel Hidalgo, trabajo Roma Norte, auto holograma 2
    """,
    generating: ContingencyExplanation.self
)
```

### Personalización por usuario

```swift
struct UserContingencyProfile {
    let hologram: Hologram   // 0, 00, 1, 2, etc.
    let workCommute: Route?  // ruta típica casa-trabajo
    let hasKidsInSchool: Bool
    let hasOutdoorJob: Bool
    let runsOutside: Bool
    let hasRespiratoryCondition: Bool
    
    var impactThreshold: Double {
        // Umbral de prob a partir del cual NOTIFICAR al usuario
        // Gente sin holograma 2 = 70%
        // Gente con holograma 2 = 40% (más riesgo)
        // Padres = 50% (escuelas suspenden en Fase 2)
        if hologram == .two { return 0.40 }
        if hasKidsInSchool { return 0.50 }
        if hasOutdoorJob { return 0.45 }
        return 0.60
    }
}
```

---

## <a id="plan"></a>9. Plan de Implementación (2 días hackathon)

### Pre-hackathon (el viernes antes)

```bash
# 1. Descargar datos históricos (8h background)
python scripts/download_historical_rama.py  # 12 años
python scripts/download_openmeteo_historical.py
python scripts/parse_contingencias_pdf.py  # ground truth

# 2. Registrarse en APIs (15 min cada una)
# - NASA Earthdata (TEMPO + FIRMS)
# - Copernicus ADS (CAMS + ERA5)

# 3. Preparar entorno
pip install xgboost lightgbm mapie scikit-learn pandas numpy
pip install cdsapi earthaccess fsspec requests
```

### Sábado (Día 1) — 10h efectivas

**Hora 1-2: Data engineering** (1 dev)
- Parsear RAMA histórico + contingencias declaradas
- Join con Open-Meteo histórico
- Verificar ground truth contra fechas conocidas (mar 2025, abr 2025)

**Hora 1-3: Setup Django + Swift** (1 dev + diseñador)
- Django endpoint skeleton `/api/v1/contingency/forecast`
- Swift skeleton `ContingencyCastView.swift`
- Figma: 3 pantallas principales

**Hora 3-6: Modelo Baseline** (1 dev)
- Feature engineering completo (código arriba)
- Random Forest + XGBoost con scale_pos_weight
- Train en 10 años, validate en último año
- **Target: CSI > 0.40 a h+24**

**Hora 6-8: Integración con backend existente**
- Endpoint `/forecast` retornando JSON con:
  ```json
  {
    "timestamp": "2026-04-16T20:00:00Z",
    "forecasts": [
      { "horizon_h": 24, "prob_fase1_o3": 0.78, "ci80": [0.65, 0.89] },
      { "horizon_h": 48, "prob_fase1_o3": 0.45, "ci80": [0.30, 0.60] },
      { "horizon_h": 72, "prob_fase1_o3": 0.22, "ci80": [0.10, 0.35] }
    ],
    "drivers": ["T_high", "UV_extreme", "low_wind", "inversion"],
    "recommendations": [...]
  }
  ```

**Hora 8-10: UI iOS**
- `ContingencyCastView` con gauge animado
- Foundation Models para explicación natural
- Widget Lock Screen

### Domingo (Día 2) — 8h efectivas

**Hora 11-13: Modelo Target** (1 dev)
- XGBoost quantile regression (q10, q50, q90)
- Conformal prediction con MAPIE
- Calibración con Platt scaling

**Hora 11-13: Live Activity** (1 dev)
- ActivityKit setup
- Dynamic Island UI
- Push notifications proactivos 48h

**Hora 13-15: Personalización usuario**
- Onboarding con holograma + ruta + trabajo
- `UserContingencyProfile`
- Threshold personalizado de alerta

**Hora 15-17: Integración satelital ligera**
- TEMPO NO2 últimas 24h
- FIRMS incendios radio 100km
- Agregar como features al modelo final

**Hora 17-19: Demo, pulir, pitch**
- Grabar demo 3 min
- Slide deck: problema → solución → diferenciador → impacto
- Stress test con data real

**Hora 19-20: Ensayo pitch**

---

## <a id="riesgos"></a>10. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **Datos RAMA caídos** | Baja | Alta | Cache 24h local + fallback WAQI |
| **TEMPO/FIRMS requieren Earthdata login** | Media | Media | Backup: solo Open-Meteo + RAMA |
| **Modelo baseline no supera 0.40 CSI** | Media | Alta | Prepare random forest tuning manual |
| **Sobre-ajuste por data leakage** | Alta | Crítica | **Time-based split, NO shuffled split** |
| **Falsa alarma en demo por "mala suerte"** | Media | Alta | Demo con histórico (fechas conocidas) no en vivo |
| **APIs satelitales muy lentas** | Media | Media | Cache diario, no NRT en demo |
| **Foundation Models hallucina predicciones** | Alta | Alta | Structured output `@Generable` obligatorio, no libre |
| **Clases muy desbalanceadas** | Alta | Alta | scale_pos_weight + SMOTE + focal loss + PR-AUC metric |
| **Tiempo se acaba en día 2** | Alta | Alta | Priorizar: baseline funcional > quantile perfecto |

### Anti-patrones a evitar

1. **NO hacer train/test split random** — usar time-based cuts (train hasta 2024, val 2025, test 2026)
2. **NO reportar accuracy** — siempre POD/FAR/CSI/PR-AUC
3. **NO prometer certeza** — siempre "X% probabilidad"
4. **NO correr modelo en vivo en pitch** — pre-calculado con data histórica
5. **NO pedir API keys en demo** — mock + cache

### Fallback plan si ML falla

Si el modelo no llega a buenas métricas, pivotar a:
- **"Alerta temprana basada en reglas heurísticas"** (reglas explícitas del PCAA 2019)
- Ej: Si O3_lag_1h > 130 ppb + T_max_forecast > 26°C + wind < 3 m/s + is_ozone_season → alta probabilidad
- Esto no es ML pero es útil, defendible y funciona.

---

## <a id="pitch"></a>11. Narrativa de Pitch (3 minutos)

### Hook (30s)

> *"Imaginen: son las 10 de la noche del martes. Tienen una junta crítica en Polanco a las 8 AM mañana, agarrarán el auto. A las 6 AM reciben un push de AirWay: 'Se activó doble contingencia. Tu auto no puede circular hoy'.*
> 
> *Tardaron 2 horas en encontrar Uber. Se perdieron la junta.*
> 
> *Esto le pasa a 1.7 millones de personas en CDMX — 15 veces al año — porque SEDEMA solo pronostica con 24 horas."*

### Problema (30s)

> *"CAMe declara contingencia cuando el ozono rebasa 154 partes por billón. El 2024 hubo 12, el 2025 casi igual, el 2026 ya lleva 10 solo en 3 meses. Y siguen sin dar más de 24 horas de aviso."*
> 
> *"Las empresas pierden productividad, los papás no pueden organizar escuela, los Uber suben su tarifa 4x, y la gente simplemente no puede planear."*

### Solución (60s)

> *"AirWay ContingencyCast predice con 48 a 72 horas de anticipación la probabilidad calibrada de contingencia ambiental."*
> 
> *"Usamos XGBoost con quantile regression entrenado en 12 años de datos de las 34 estaciones RAMA. Integramos satélite NASA TEMPO para NO2 horario, FIRMS para incendios forestales, Open-Meteo para meteorología, y usamos conformal prediction para dar intervalos de confianza estadísticamente garantizados."*
> 
> *"El resultado: 'Mañana a las 15:00 hay 78% de probabilidad de Fase 1 Ozono en tu zona, con intervalo de 65 a 89%'. Más: Apple Intelligence te explica por qué, en español simple."*

### Diferenciador (30s)

> *"SEDEMA pronostica 24h, actualiza 1 vez al día, y no da probabilidades. Nosotros: 72 horas, cada hora, con certeza cuantificada."*
> 
> *"Y no es genérico — si tu auto es holograma 2, te alertamos al 40% de probabilidad porque tú sufres. Si tus hijos van a escuela, al 50% porque en Fase 2 cierran clases. Personalización real por tu riesgo."*

### Impacto (30s)

> *"Con 48 horas de anticipación: las empresas pueden autorizar home office. Los papás pueden organizar carpool. Los repartidores pueden cambiar rutas. Los albañiles pueden planear su medicación."*
> 
> *"22 millones de personas en la Megalópolis, un contingencia reduce 2.5% del PIB ambiental del país — 832 mil millones de pesos anuales."*
> 
> *"Esto es HCAI real: la IA no decide por ti, te da tiempo para decidir."*

---

## <a id="fuentes"></a>12. Fuentes

### Reglamentación y datos CDMX
- [PCAA histórico contingencias oficial](http://www.aire.cdmx.gob.mx/descargas/ultima-hora/calidad-aire/pcaa/pcaa-historico-contingencias.pdf)
- [Gaceta Oficial CDMX Programa Contingencias 2019](https://proyectos.sedema.cdmx.gob.mx/datos/storage/app/media/gacetas/GOCDMX_19-05-28_programacontingencias.pdf)
- [NOM-172-SEMARNAT-2023 DOF](https://www.dof.gob.mx/nota_detalle.php?codigo=5715154&fecha=25/01/2024)
- [Datos abiertos RAMA CDMX](https://datos.cdmx.gob.mx/dataset/red-automatica-de-monitoreo-atmosferico)
- [CAMe gob.mx](https://www.gob.mx/comisionambiental)

### ML / Papers 2024-2026
- [Zavala-Romero et al. 2024 Atmos Env - Operational O3 CDMX](https://www.sciencedirect.com/science/article/pii/S1352231024006927)
- [Sánchez Cerritos et al. 2024 - arXiv 2411.07259](https://arxiv.org/abs/2411.07259)
- [Martínez-Cadena et al. 2024 - Causal wavelet MCMA](https://arxiv.org/abs/2411.13568)
- [E-STGCN extreme spatiotemporal GCN](https://arxiv.org/html/2411.12258v1)
- [AirPhyNet ICLR 2024](https://arxiv.org/abs/2402.03784)
- [iTransformer ICLR 2024 Spotlight](https://arxiv.org/abs/2310.06625)
- [PatchTST ICLR 2023](https://arxiv.org/pdf/2211.14730)
- [X2-AQFormer npj Clean Air 2026](https://www.nature.com/articles/s44407-026-00058-5)
- [ML CDMX ozone MDPI 2024](https://www.mdpi.com/2076-3417/14/4/1408)
- [ML surface O3 CDMX 2025](https://www.mdpi.com/2073-4433/16/8/931)
- [Springer AQI contingencias Megalopolis 2025](https://link.springer.com/article/10.1007/s11869-025-01775-8)

### Técnicas ML
- [Quantile regression NO2 - Nature Sci Rep 2021](https://www.nature.com/articles/s41598-021-90063-3)
- [Conformal Prediction intro arXiv](https://arxiv.org/abs/2107.07511)
- [Modeling Extreme Events TS - KDD 2019](https://dl.acm.org/doi/10.1145/3292500.3330896)
- [MAPIE library conformal](https://mapie.readthedocs.io/)
- [Focal loss Ultralytics glossary](https://www.ultralytics.com/glossary/focal-loss)
- [TFB Time Series Forecasting Benchmark](https://github.com/decisionintelligence/TFB)

### Datos satelitales
- [TEMPO NASA NRT](https://www.earthdata.nasa.gov/data/instruments/tempo/near-real-time-data)
- [FIRMS API](https://firms.modaps.eosdis.nasa.gov/api/)
- [CAMS Copernicus ADS](https://ads.atmosphere.copernicus.eu/)
- [ERA5 reanalysis CDS](https://cds.climate.copernicus.eu/)
- [Open-Meteo Air Quality](https://open-meteo.com/en/docs/air-quality-api)
- [Open-Meteo Historical](https://open-meteo.com/en/docs/historical-weather-api)

### Métricas
- [POD FAR CSI AMS Glossary](https://glossary.ametsoc.org/wiki/POD,_FAR,_and_CSI)
- [Forecast Verification CAWCR](https://www.cawcr.gov.au/projects/verification/)
- [Brier score Wikipedia](https://en.wikipedia.org/wiki/Brier_score)

### Apple Intelligence iOS 26
- [Foundation Models Framework](https://developer.apple.com/documentation/FoundationModels)
- [Core ML on-device deployment WWDC24](https://developer.apple.com/videos/play/wwdc2024/10161/)
- [Core ML documentation](https://developer.apple.com/machine-learning/core-ml/)

### Estudios económicos
- [INEGI degradación ambiental 2024 - 832k MDP](https://lasillarota.com/negocios/2025/12/1/degradacion-del-aire-suelo-agua-le-cuestan-mexico-1382-billones-de-pesos-en-2024-571823.html)
- [1.7M vehículos fuera circulación contingencia](https://www.elimparcial.com/mexico/Contingencia-ambiental-Sacan-de-circulacion-1.7-millones-de-vehiculos-en-la-CDMX-20220330-0025.html)
- [Contingencias 2026 duplicadas El Sol México](https://oem.com.mx/elsoldemexico/metropoli/contingencias-ambientales-en-cdmx-2026-se-duplican-frente-a-2025-y-acumulan-10-dias-por-altos-niveles-de-ozono-28912966)

---

## Resumen ejecutivo — Decisiones clave

| Decisión | Escogido | Justificación |
|---|---|---|
| **Target** | Binario: Fase 1 O3 en h+24/48/72 | Umbral claro (154 ppb), base literatura |
| **Modelo principal** | XGBoost quantile (q10, q50, q90) | SOTA en benchmarks ≤72h, interpretable, rápido |
| **Incertidumbre** | Conformal Prediction (CQR) | Garantía distribution-free 80% coverage |
| **Imbalance** | scale_pos_weight + focal loss + SMOTE | Combinado probado en literatura |
| **Features críticos** | `o3_lag`, `T_x_rad`, `pblh`, `dT_dz`, `TEMPO_no2` | Rankings SHAP 2024-2025 |
| **Métrica principal** | CSI + PR-AUC + Brier | No accuracy (desbalance), no ROC-AUC |
| **Horizonte diferenciador** | 48-72h | SEDEMA solo da 24h |
| **UX clave** | Gauge probabilidad + explicación Foundation Models | Claridad + HCAI |
| **Personalización** | Threshold por holograma/familia/trabajo | Valor real por usuario |
| **Baseline mínimo** | Random Forest + features engineered | Funcional en 4-6h |
| **Fallback** | Reglas heurísticas del PCAA | Si ML falla, defendible |

**Implementable en 2 días con equipo de 2 devs + 1 diseñador. Ventana competitiva: 48-72h vs 24h de SEDEMA.**
