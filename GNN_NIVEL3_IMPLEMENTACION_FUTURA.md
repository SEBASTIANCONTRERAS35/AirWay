# GNN Nivel 3 — Plan de Implementación Futura para AirWay

> **Estado**: POSTERGADO — documento de referencia para implementación posterior al hackathon
> **Fecha**: 2026-04-16
> **Razón de postergar**: Trade-off riesgo/beneficio no favorable para el contexto actual del hackathon

---

## TABLA DE CONTENIDOS

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Análisis del proyecto actual](#2-análisis-del-proyecto-actual)
3. [Arquitectura propuesta](#3-arquitectura-propuesta)
4. [Investigación técnica](#4-investigación-técnica)
5. [Las 9 fases detalladas](#5-las-9-fases-detalladas)
6. [Dependencias y requisitos](#6-dependencias-y-requisitos)
7. [Implicaciones críticas](#7-implicaciones-críticas)
8. [Decisión: por qué se postergó](#8-decisión-por-qué-se-postergó)
9. [Roadmap para retomar](#9-roadmap-para-retomar)
10. [Referencias y fuentes](#10-referencias-y-fuentes)

---

## 1. RESUMEN EJECUTIVO

Propuesta para reemplazar el IDW actual (Inverse Distance Weighting con corrección por altitud, viento y outliers) con un **Graph Neural Network sofisticado** que combina 4 componentes del estado del arte:

1. **GAT baseline** (Graph Attention Network v2) — backbone del modelo
2. **IGNNK** (Inductive Graph Neural Network for Kriging) — training con subgrafos aleatorios
3. **AirPhyNet-lite** — physics-informed loss con advección-difusión atmosférica
4. **UQGNN** — Uncertainty quantification via Monte Carlo Dropout

### Ganancia esperada:
- RMSE: **12.45 → 6.12** (mejora ~51%)
- Predicciones en cualquier punto de CDMX, no solo estaciones
- Intervalos de confianza calibrados (p10, p90)

### Costo:
- 10-18 horas de implementación (estimación realista con debugging)
- +500MB de dependencias (torch, torch-geometric)
- Riesgo de OOM en Render free tier (512MB)

---

## 2. ANÁLISIS DEL PROYECTO ACTUAL

### 2.1 Estado del backend (Django)

**Django setup** (`backend-api/src/core/settings.py`):
- Django 5.1 con PostgreSQL
- Django REST Framework + CORS
- Redis cache (con fallback a LocMemCache)
- Database URL parsing para Render

**IDW actual** (`backend-api/src/application/air/aggregator.py`):
- Haversine distance calculation
- 4 factores de ponderación:
  - Inverse distance power (p=2)
  - Altitude correction (0.1-1.0x)
  - Wind factor (0.5-1.5x basado en bearing)
  - Outlier mitigation (0.2x para IQR outliers)
- IQR-based outlier detection (threshold 2.0x)
- IDW por contaminante: pm25, pm10, no2, o3, so2, co

**Infraestructura ML** (`backend-api/src/application/air/prediction_service.py`):
- Patrón Singleton para model loading
- 3 modelos .pkl: `pm25_predictor_{1h,3h,6h}.pkl` (2.7-3.0 MB cada uno)
- 49 features: 7 contaminantes + 12 weather + 6 cyclic temporal + 6 lags + 4 rolling means + 2 stds + deltas + max_24h
- Métricas actuales: R² = 0.85 (1h), 0.67 (3h), 0.52 (6h)

**Endpoints**:
```
GET /api/v1/air/current        - AQI de estación cercana
GET /api/v1/air/analysis       - Multi-source IDW + weather + Gemini
GET /api/v1/air/prediction     - ML forecasts 1h/3h/6h
GET /api/v1/air/heatmap        - Grid interpolation (IDW-based)
GET /api/v1/air/best-time      - Optimización temporal
GET /api/v1/routes/optimal     - OSRM + exposure scoring
```

### 2.2 Datos disponibles

- `train_pm25_cdmx.csv`: 15,740 filas × 52 columnas
- `full_pm25_cdmx.csv`: 19,675 filas
- Features: 7 pollutants + 19 meteorológicos + 23 lag/rolling/temporal

### 2.3 Data sources integrados

| Source | Provider | Endpoint | Output típico |
|--------|----------|----------|---|
| OpenAQ | `openaq_grid_provider.py` | `/locations`, `/latest` | 1-5 stations con todos los contaminantes |
| WAQI | `waqi_provider.py` | `/map/bounds/` | 2-20 stations, AQI only |
| Open-Meteo | `openmeteo_provider.py` | `/air-quality` | Model gridcell global |
| Elevation | `elevation_service.py` | `/v1/elevation` | 90m Copernicus DEM |
| Weather | `openmeteo_provider.py` | `/forecast` | Temp, humidity, wind |

**Deduplicación**: <500m proximity en `aggregator.py:384`

### 2.4 Integration points para GNN

**Nuevo endpoint sugerido**:
```python
# urls.py
path("air/gnn-interpolation", AirGNNView.as_view(), name="air-gnn")
```

**Reusable**:
- Station dict format establecido: `{aqi, lat, lon, name, distance_m, pm25, pm10, no2, o3, so2, co, elevation_m, altitude_factor, wind_factor, is_outlier}`
- `aggregator.get_combined()` ya fetcha en paralelo todas las fuentes
- Weather data cached
- Feature vector construction ya existe

**Nuevo código requerido**:
1. Graph construction con PyG
2. GNN model loading (singleton pattern)
3. Message passing layers
4. Node feature engineering adicional
5. Interpolation post-processing

---

## 3. ARQUITECTURA PROPUESTA

```
┌────────────────────────────────────────────────────────────────┐
│                   DATA LAYER                                    │
├────────────────────────────────────────────────────────────────┤
│ RAMA archivo         OpenAQ S3         Open-Meteo              │
│ (CSVs anuales        (bucket público   (ERA5 weather           │
│  10 años)            2015+)            archive)                │
│        ↓                 ↓                 ↓                   │
│ ╔════════════════════════════════════════════════════╗        │
│ ║  Training Dataset (~2.6M node-hour samples)        ║        │
│ ║  • 34 estaciones × 24 h/día × 365 días × 10 años   ║        │
│ ║  • Features estáticas: lat, lon, elev, land_use    ║        │
│ ║  • Features dinámicas: T, RH, WS, WD, BLH, AOD     ║        │
│ ║  • Features satelitales: Sentinel-5P, MODIS AOD    ║        │
│ ╚════════════════════════════════════════════════════╝        │
└────────────────────────────────────────────────────────────────┘
                           ↓
┌────────────────────────────────────────────────────────────────┐
│                  GRAPH CONSTRUCTION                             │
├────────────────────────────────────────────────────────────────┤
│ Nodos: 34 estaciones + 200-500 H3 grid cells (res 7-8)         │
│ Aristas: BallTree k-NN (k=6) + radius cutoff 30km              │
│ Edge features [3]:                                              │
│   • Gaussian distance decay: exp(-d²/2h²)                      │
│   • Wind alignment: dot(v, bearing)                            │
│   • Δ elevation (normalizado)                                  │
└────────────────────────────────────────────────────────────────┘
                           ↓
┌────────────────────────────────────────────────────────────────┐
│                  MODEL: GATv2 + IGNNK + Physics                 │
├────────────────────────────────────────────────────────────────┤
│ Layer 1: GATv2Conv(12, 64, heads=4, edge_dim=3)                │
│         GraphNorm(256) + ELU + Dropout(0.3)                    │
│ Layer 2: GATv2Conv(256, 64, heads=4, edge_dim=3)               │
│         GraphNorm(256) + ELU + Dropout(0.3)                    │
│ Layer 3: GATv2Conv(256, 1, heads=1)  → PM2.5                   │
│                                                                 │
│ Training strategy:                                              │
│   • IGNNK random subgraph masking (30% hidden per batch)       │
│   • Huber loss sobre nodos enmascarados                        │
│   • Soft physics loss: λ_phys · |advection - diffusion|        │
│   • λ_phys anneal 0 → 0.05 over 5 epochs                       │
│                                                                 │
│ Inference:                                                      │
│   • MC Dropout × 30 samples → mean, std (uncertainty)          │
│   • Inductive: puede predecir en cualquier coord (lat, lon)    │
└────────────────────────────────────────────────────────────────┘
                           ↓
┌────────────────────────────────────────────────────────────────┐
│                 DJANGO INTEGRATION                              │
├────────────────────────────────────────────────────────────────┤
│ GNNInterpolationService (singleton, patrón PredictionService)  │
│ Endpoint: GET /api/v1/air/gnn-interpolation                    │
│   Returns: {aqi, aqi_uncertainty, p10, p90, model_version}     │
│ Ensemble con IDW: final = 0.5·gnn + 0.5·idw (configurable)     │
└────────────────────────────────────────────────────────────────┘
```

---

## 4. INVESTIGACIÓN TÉCNICA

### 4.1 PyTorch Geometric — GATv2Conv + GraphNorm

**Decisión clave**: Usar `GATv2Conv` en vez de `GATConv`.
- GAT original (2018) tiene "static attention" — los mismos nodos siempre se atienden igual
- GATv2 (Brody et al. 2022) introduce "dynamic attention" — crítico con viento cambiante en CDMX

**GraphNorm** (Cai et al. 2021):
- BatchNorm no funciona con batch_size=1 (grafos pequeños)
- LayerNorm no preserva estructura de atención
- GraphNorm normaliza por grafo entero

**Hiperparámetros recomendados** (grafos 30-50 nodos):
| Param | Value |
|---|---|
| Optimizer | AdamW, weight_decay=5e-4 |
| LR | 5e-3, cosine schedule |
| Batch | full-batch (1 grafo/step) |
| Epochs | 300-800 con early stopping (patience=50) |
| Dropout | 0.3-0.5 |
| Loss | Huber (robusto a outliers) |
| Grad clip | clip_grad_norm_(1.0) |

**Compute**: N=50, hidden=64, heads=4 → ~50K params, <10MB RAM, 2-5ms/epoch en CPU

### 4.2 IGNNK (Inductive GNN for Kriging)

**Paper**: Wu et al., AAAI 2021 — "Inductive Graph Neural Networks for Spatiotemporal Kriging"
**Repo oficial**: https://github.com/Kaimaoge/IGNNK

**Mecanismo**:
1. Sample random subset S (70%) de sensores
2. Mask M (30% de S) como "virtual unsampled"
3. Reconstruir TODOS los signals (observed + masked)
4. Loss = MSE sobre reconstrucción completa

**Ventaja crítica**: Modelo aprende a **inferir valores en nodos sin sensor** — exactamente el caso de interpolación.

**Código simplificado** (basado en DCN - Diffusion Convolutional Networks):
```python
class IGNNK(nn.Module):
    def __init__(self, h, z, K):
        self.gcn1 = D_GCN(h, z, K)
        self.gcn2 = D_GCN(z, h, K, activation='linear')
        self.gcn3 = D_GCN(h, h, K, activation='linear')

    def forward(self, X, A_q, A_h):
        x = self.gcn1(X, A_q, A_h)
        x = self.gcn2(x, A_q, A_h)
        return self.gcn3(x + X, A_q, A_h)  # residual
```

### 4.3 AirPhyNet (Physics-informed GNN)

**Paper**: Han et al., ICLR 2024
**Repo**: https://github.com/kethmih/AirPhyNet

**Arquitectura**: RNN encoder → GNN-based ODE net (advection+diffusion) → decoder

**Ecuación PDE**: `∂C/∂t + v·∇C = D·∇²C`
- `∂C/∂t`: cambio temporal
- `v·∇C`: advección por viento
- `D·∇²C`: difusión turbulenta

**Implementación del loss residual**:
```python
def physics_residual(c_pred, t, wind_field, D, laplacian, flow_matrix):
    dC_dt = torch.autograd.grad(c_pred.sum(), t, create_graph=True)[0]
    advection = torch.einsum('ij,bj->bi', flow_matrix, c_pred)
    diffusion = torch.einsum('ij,bj->bi', laplacian, c_pred)
    return dC_dt + advection - D * diffusion

loss = F.huber_loss(c_pred, c_obs) + λ_phys * (physics_residual(...)**2).mean()
```

**Performance reportada**: 10% mejora MAE/RMSE vs STGCN/DCRNN en Beijing/Shenzhen
**Costo**: 2-3× más lento que vanilla GAT por ODE solver

**Decisión**: Para hackathon usar **physics loss soft** (no AirPhyNet completo con ODE solver). λ=0.05, anneal desde 0 en primeros 5 epochs.

### 4.4 Uncertainty Quantification

**Comparación de métodos**:
| Método | Epistemic | Aleatoric | Cost | Notes |
|---|---|---|---|---|
| MC Dropout | ✓ | ✗ | 1× train, 30× infer | **Recomendado** — simple, robusto |
| Deep Ensembles | ✓ | ✓ | N× train | Gold standard, 5-10 modelos |
| Bayesian GNN | ✓ | ✓ | 2-3× train | Difícil de tunear |
| ADF + MC Dropout | ✓ | ✓ | 1.5× | Best combined |

**Código MC Dropout**:
```python
def predict_with_uncertainty(model, graph, n_samples=30):
    model.train()  # ¡KEEP DROPOUT ACTIVE AT INFERENCE!
    predictions = []
    with torch.no_grad():
        for _ in range(n_samples):
            pred = model(graph.x, graph.edge_index, graph.edge_attr)
            predictions.append(pred)

    stack = torch.stack(predictions)
    return {
        'mean': stack.mean(0),
        'std': stack.std(0),
        'p10': stack.quantile(0.1, dim=0),
        'p90': stack.quantile(0.9, dim=0),
    }
```

### 4.5 Satellite Data Fusion

**Fuentes principales**:

1. **Sentinel-5P TROPOMI** (NO2, CO, SO2):
   - Best access: Google Earth Engine (`COPERNICUS/S5P/NRTI/L3_NO2`)
   - NRTI latency: ~3h, ~7km resolution
   - Band: `tropospheric_NO2_column_number_density` (mol/m²)

2. **MODIS AOD** (Aerosol Optical Depth):
   - Usar **MAIAC (MCD19A2)** — 1km daily, mejor resolución
   - GEE: `MODIS/061/MCD19A2_GRANULES`
   - Band: `Optical_Depth_055`
   - Latency: 1-2 días

3. **ESA WorldCover** (land use):
   - `ee.ImageCollection('ESA/WorldCover/v200').first()`
   - 10m, 11 clases
   - Cache TTL: 30 días (cambia lentamente)

**AOD → PM2.5**:
- No es ratio fijo: `PM2.5 ≈ AOD × f(BLH, RH, T, wind)`
- Correlación con raw AOD: 0.5-0.7
- Con corrections (BLH, RH): 0.85-0.95
- **Usar ML (no linear scaling)**

**Feature ranking (impacto en PM2.5)**:
1. MAIAC AOD (550 nm)
2. BLH + RH (ERA5)
3. TROPOMI NO2
4. NDVI (MOD13Q1)
5. WorldCover class
6. Wind u/v
7. Elevation (SRTM)

**Código GEE Python**:
```python
import ee
ee.Initialize()

pt = ee.Geometry.Point([lon, lat])
img = (ee.ImageCollection('MODIS/061/MCD19A2_GRANULES')
       .filterDate('2026-04-10', '2026-04-16')
       .select('Optical_Depth_055').mean())
val = img.sample(pt, scale=1000).first().get('Optical_Depth_055').getInfo()
```

**Estrategia de latencia**:
- Training: usar datos satelitales reales (delay OK)
- Inferencia real-time: usar lagged AOD (t-1, t-2 días)
- O: omitir satellite en inference, solo usar ground stations + weather

### 4.6 Datos históricos CDMX

**RAMA CDMX**:
- **URL directa**: `https://archivo.datos.cdmx.gob.mx/SEDEMA/aire_CDMX/RAMA/`
- Formato: `RAMA_YYYY.csv` (archivos anuales)
- Columnas: date, hour(1-24), station_id(3-letter), pollutant, value, unit
- Unidades: O3/NOx/SO2=ppb, CO=ppm, PM=µg/m³
- Missing: `-99` o blank
- Timezone: UTC-6 (no DST desde 2022)

**SINAICA (nacional)**:
- R package: `rsinaica` (no hay Python port oficial)
- Endpoint JSON: `sinaica.inecc.gob.mx`

**OpenAQ S3 Archive** (más fácil para Python):
- Bucket: `s3://openaq-data-archive` (público, us-east-1)
- Layout: `records/csv.gz/locationid={id}/year={YYYY}/month={MM}/location-{id}-{YYYYMMDD}.csv.gz`
- **Sin credenciales necesarias**:

```python
import boto3, pandas as pd

s3 = boto3.client('s3', region_name='us-east-1')
key = "records/csv.gz/locationid=2178/year=2025/month=01/location-2178-20250115.csv.gz"
s3.download_file("openaq-data-archive", key, "f.csv.gz")
df = pd.read_csv("f.csv.gz", compression="gzip")
```

**Volumen recomendado**:
- Mínimo: 12 meses (con augmentation)
- Ideal: 24-36 meses
- Óptimo: 10 años (2015-2025) = ~2.6M samples
- Memoria: <6GB GPU

**Data quality**:
- Expect 10-20% missing per station-pollutant-year
- Drop stations con <70% coverage
- Gap filling:
  1. Linear interpolation ≤3h
  2. Diurnal climatology 3-24h
  3. Spatial kriging >24h
  4. Masking token para GNN

**Train/val/test split (spatiotemporal)**:
- Chronological ONLY (no k-fold random)
- Ejemplo: train 2015-2022, val 2023, test 2024-2025
- Walk-forward con 6 folds para paper-grade

**Feature engineering**:

Por nodo (estáticas):
- lat, lon, elevation
- land_use % (OSM buffer 500m)
- distance to highway
- population density (INEGI AGEB)

Por nodo × hour (dinámicas):
- T, RH, P, WS, WD (sin/cos)
- PBL height (ERA5)
- solar radiation
- co-pollutants (O3 para predecir PM2.5)
- lags: t-1, t-24, t-168
- hour-of-day + day-of-week cyclic

Aristas:
- haversine distance
- wind-aligned distance (proyección en WD)
- elevation difference

**Augmentation**:
- Random subgraph sampling (drop 20-30% nodos/batch)
- Edge dropout 10-15%
- Temporal jitter ±1-2h
- Gaussian noise σ=0.05·std
- Mixup across stations
- MAE-style random masking 15% timesteps

---

## 5. LAS 9 FASES DETALLADAS

### FASE 1: Pipeline de datos RAMA históricos

**Tiempo**: 45-60 min
**Archivo**: `scripts/download_rama_data.py`

**Objetivo**: Descargar CSVs 2020-2025 de 34 estaciones RAMA CDMX.

**Logs obligatorios**:
```python
logger.info(f"Fetching RAMA {year}: {url}")
logger.info(f"  ✓ Downloaded {len(df)} rows, {df['station_id'].nunique()} stations")
logger.info(f"  Pollutants: {df['pollutant'].unique()}")
logger.info(f"  Coverage: {(df['value']!=-99).mean()*100:.1f}% non-missing")
logger.info(f"  Date range: {df['date'].min()} to {df['date'].max()}")
logger.warning(f"  Stations <70% coverage (excluded): {low_coverage_stations}")
```

**Output**:
- `scripts/data/rama_hourly_2020_2025.csv` (~4-6M filas)
- `scripts/data/rama_stations_metadata.csv` (34 filas)

---

### FASE 2: Construcción del grafo urbano

**Tiempo**: 60-90 min
**Archivo**: `scripts/build_graph.py`

**Código**:
```python
import torch
from torch_geometric.data import Data
from sklearn.neighbors import BallTree
import numpy as np
import h3

def build_cdmx_graph(stations_df, h3_resolution=7, k=6, max_km=30):
    logger.info(f"Building graph: {len(stations_df)} stations, H3 res={h3_resolution}")

    cdmx_bbox = h3.polygon_to_cells(CDMX_POLYGON, h3_resolution)
    h3_centers = np.array([h3.cell_to_latlng(c) for c in cdmx_bbox])
    logger.info(f"  H3 cells in bbox: {len(h3_centers)}")

    all_coords = np.vstack([stations_df[['lat','lon']].values, h3_centers])
    node_type = [0]*len(stations_df) + [1]*len(h3_centers)

    coords_rad = np.radians(all_coords)
    tree = BallTree(coords_rad, metric='haversine')
    dist, idx = tree.query(coords_rad, k=k+1)
    dist_km = dist[:, 1:] * 6371.0

    src, dst, edge_feats = [], [], []
    for i in range(len(all_coords)):
        for j, di in zip(idx[i, 1:], dist_km[i]):
            if di <= max_km:
                w_dist = np.exp(-(di**2) / (2 * 5.0**2))
                src.extend([i, j]); dst.extend([j, i])
                edge_feats.extend([[w_dist, 0.0, 0.0]] * 2)

    return Data(
        x=torch.zeros(len(all_coords), 12),
        edge_index=torch.tensor([src, dst], dtype=torch.long),
        edge_attr=torch.tensor(edge_feats, dtype=torch.float),
        pos=torch.tensor(all_coords, dtype=torch.float),
        node_type=torch.tensor(node_type, dtype=torch.long),
    )
```

**Logs esperados**:
```
🔷 Graph construction
  Stations: 34
  H3 cells (res 7): 287
  Total nodes: 321
  Edges: 3852 (avg degree: 12.0)
  Max distance: 30.0 km
  Isolated nodes: 0 ✓
  Connected components: 1 ✓
```

---

### FASE 3: Integración de datos satelitales (OPCIONAL)

**Tiempo**: 45-60 min
**Archivo**: `scripts/fetch_satellite_features.py`

**Decisión estratégica**: Satellite data tiene 1-3 días delay. Solo útil para training. Strategy:
- Training: usar con historical satellite data
- Inference: usar lagged AOD (t-1, t-2) o omitir

**Código base**:
```python
import ee
ee.Authenticate()
ee.Initialize()

def fetch_aod(lat, lon, date_range):
    pt = ee.Geometry.Point([lon, lat])
    img = (ee.ImageCollection('MODIS/061/MCD19A2_GRANULES')
           .filterDate(date_range[0], date_range[1])
           .select('Optical_Depth_055').mean())
    return img.sample(pt, scale=1000).first().get('Optical_Depth_055').getInfo()

def fetch_no2(lat, lon, date_range):
    pt = ee.Geometry.Point([lon, lat])
    img = (ee.ImageCollection('COPERNICUS/S5P/NRTI/L3_NO2')
           .filterDate(date_range[0], date_range[1])
           .select('tropospheric_NO2_column_number_density').mean())
    return img.sample(pt, scale=7000).first().getInfo()
```

**SKIP esta fase si el tiempo se aprieta** — el modelo funciona sin satellite features.

---

### FASE 4: GAT baseline entrenado (Nivel 2)

**Tiempo**: 60-90 min
**Archivo**: `backend-api/src/adapters/gnn/models.py`

**Código del modelo**:
```python
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch_geometric.nn import GATv2Conv, GraphNorm

class SpatialGAT(nn.Module):
    def __init__(self, in_dim=12, hidden=64, out_dim=1, heads=4, edge_dim=3, dropout=0.3):
        super().__init__()
        self.gat1 = GATv2Conv(in_dim, hidden, heads=heads, edge_dim=edge_dim,
                              dropout=dropout, add_self_loops=True)
        self.norm1 = GraphNorm(hidden * heads)
        self.gat2 = GATv2Conv(hidden * heads, hidden, heads=heads,
                              edge_dim=edge_dim, dropout=dropout)
        self.norm2 = GraphNorm(hidden * heads)
        self.gat3 = GATv2Conv(hidden * heads, out_dim, heads=1,
                              concat=False, edge_dim=edge_dim)

    def forward(self, x, edge_index, edge_attr, return_attention=False):
        x = F.elu(self.norm1(self.gat1(x, edge_index, edge_attr)))
        x = F.dropout(x, p=0.3, training=self.training)
        x = F.elu(self.norm2(self.gat2(x, edge_index, edge_attr)))
        x = F.dropout(x, p=0.3, training=self.training)
        return self.gat3(x, edge_index, edge_attr)
```

**Training loop**:
```python
def train_gat(model, data_loader, epochs=500, lr=5e-3):
    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=5e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)

    for epoch in range(epochs):
        model.train()
        total_loss = 0
        for batch_idx, batch in enumerate(data_loader):
            pred = model(batch.x, batch.edge_index, batch.edge_attr)
            loss = F.huber_loss(pred[batch.train_mask], batch.y[batch.train_mask])

            optimizer.zero_grad()
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            optimizer.step()
            total_loss += loss.item()

        scheduler.step()

        if epoch % 10 == 0:
            val_rmse = evaluate(model, val_loader)
            logger.info(f"Epoch {epoch:3d} | loss={total_loss/len(data_loader):.3f} | "
                       f"val_rmse={val_rmse:.3f} | lr={scheduler.get_last_lr()[0]:.2e}")
```

**Validación: Leave-One-Station-Out CV**:
```
Station held out: MER → RMSE 8.234
Station held out: UIZ → RMSE 9.102
...
Mean LOSO RMSE: 9.143 ± 1.823

📊 Comparison vs IDW:
     IDW actual:    RMSE 12.45 (baseline)
     GAT Nivel 2:   RMSE  9.14 (-26.6% ✓)
```

---

### FASE 5: IGNNK random subgraph sampling

**Tiempo**: 45-60 min
**Archivo**: `backend-api/src/adapters/gnn/ignnk.py`

**Código**:
```python
def ignnk_training_step(model, full_data, mask_ratio=0.3, sample_ratio=0.7):
    n_stations = (full_data.node_type == 0).sum().item()
    n_sample = int(n_stations * sample_ratio)
    n_mask = int(n_sample * mask_ratio)

    station_indices = torch.where(full_data.node_type == 0)[0]
    sampled = station_indices[torch.randperm(n_stations)[:n_sample]]
    masked = sampled[torch.randperm(n_sample)[:n_mask]]

    x_masked = full_data.x.clone()
    x_masked[masked, :7] = 0

    pred = model(x_masked, full_data.edge_index, full_data.edge_attr)
    loss = F.huber_loss(pred[sampled], full_data.y[sampled])
    return loss, masked
```

**Mejora esperada**: GAT 9.14 → IGNNK 7.01 (-23.3%)

---

### FASE 6: Physics-informed loss

**Tiempo**: 45-60 min
**Archivo**: `backend-api/src/adapters/gnn/physics.py`

**Código**:
```python
def physics_residual(c_pred, t, wind_field, D, laplacian, flow_matrix, dt=1.0):
    dC_dt = torch.diff(c_pred, dim=0) / dt
    advection = torch.einsum('ij,tj->ti', flow_matrix, c_pred[:-1])
    diffusion = D * torch.einsum('ij,tj->ti', laplacian, c_pred[:-1])
    return dC_dt + advection - diffusion

def combined_loss(c_pred, c_obs, wind, D, L, F_v, lambda_phys=0.05):
    data_loss = F.huber_loss(c_pred, c_obs)
    phys_loss = physics_residual(c_pred, None, wind, D, L, F_v).pow(2).mean()
    return data_loss + lambda_phys * phys_loss, data_loss.item(), phys_loss.item()
```

**λ anneal**:
```python
lambda_phys = min(0.05, 0.01 * epoch)
```

**Mejora esperada**: IGNNK 7.01 → IGNNK+Physics 6.12 (-12.7%)

---

### FASE 7: Uncertainty quantification

**Tiempo**: 30-45 min
**Archivo**: `backend-api/src/adapters/gnn/uncertainty.py`

**Código**:
```python
def predict_with_uncertainty(model, graph, n_samples=30):
    model.train()  # KEEP DROPOUT ACTIVE

    predictions = []
    with torch.no_grad():
        for _ in range(n_samples):
            pred = model(graph.x, graph.edge_index, graph.edge_attr)
            predictions.append(pred)

    stack = torch.stack(predictions)
    return {
        'mean': stack.mean(0),
        'std': stack.std(0),
        'p10': stack.quantile(0.1, dim=0),
        'p90': stack.quantile(0.9, dim=0),
    }
```

---

### FASE 8: Integración al backend Django

**Tiempo**: 60-75 min
**Archivos**:
- `backend-api/src/application/air/gnn_service.py`
- `backend-api/src/interfaces/api/routes/views.py`

**Singleton**:
```python
class GNNInterpolationService:
    _instance = None
    _model = None
    _graph = None
    _loaded = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._loaded:
            self._load_model()

    def _load_model(self):
        logger.info(f"Loading GNN model from {MODEL_PATH}")
        try:
            ckpt = torch.load(MODEL_PATH, map_location='cpu')
            self._model = SpatialGAT(**ckpt['config'])
            self._model.load_state_dict(ckpt['state_dict'])
            self._model.eval()
            self._graph = ckpt['graph_template']
            self._loaded = True
            logger.info(f"  ✓ GNN loaded: {sum(p.numel() for p in self._model.parameters())} params")
        except Exception as e:
            logger.error(f"  ❌ Failed to load GNN: {e}")

    def predict(self, lat, lon, current_stations, weather):
        logger.info(f"GNN predict: ({lat:.4f}, {lon:.4f})")
        graph = self._update_graph(current_stations, weather)
        graph = self._add_query_node(graph, lat, lon)
        result = predict_with_uncertainty(self._model, graph)
        query_idx = -1
        return {
            'aqi': float(result['mean'][query_idx]),
            'aqi_uncertainty': float(result['std'][query_idx]),
            'p10': float(result['p10'][query_idx]),
            'p90': float(result['p90'][query_idx]),
            'model_version': 'gnn-v3-full',
        }
```

**Endpoint**:
```python
class AirGNNInterpolationView(APIView):
    def get(self, request):
        lat = float(request.query_params.get("lat"))
        lon = float(request.query_params.get("lon"))

        logger.info(f"GNN endpoint: lat={lat}, lon={lon}")

        aggregator = AirQualityAggregator()
        data = aggregator.get_combined(lat, lon)

        gnn_service = GNNInterpolationService()
        gnn_result = gnn_service.predict(lat, lon, data['stations'], data.get('weather', {}))

        idw_aqi = data['combined_aqi']
        ensemble_aqi = int(0.5 * gnn_result['aqi'] + 0.5 * idw_aqi)

        logger.info(f"  IDW={idw_aqi}, GNN={gnn_result['aqi']:.0f}, Ensemble={ensemble_aqi}")

        return Response({
            'location': {'lat': lat, 'lon': lon},
            'idw_aqi': idw_aqi,
            'gnn_aqi': gnn_result['aqi'],
            'gnn_uncertainty': gnn_result['aqi_uncertainty'],
            'gnn_p10': gnn_result['p10'],
            'gnn_p90': gnn_result['p90'],
            'ensemble_aqi': ensemble_aqi,
            'model_version': gnn_result['model_version'],
        })
```

---

### FASE 9: Testing, métricas y deploy

**Tiempo**: 45 min

**Ablation study esperado**:
```
┌─────────────────────────────────────────────────────┐
│  Model          │ RMSE  │ MAE  │ R²   │ Time       │
├─────────────────┼───────┼──────┼──────┼────────────┤
│ IDW (baseline)  │ 12.45 │ 8.92 │ 0.61 │ instant    │
│ GAT Nivel 2     │  9.14 │ 6.78 │ 0.74 │ 12 min     │
│ + IGNNK         │  7.01 │ 5.23 │ 0.82 │ 18 min     │
│ + Physics       │  6.12 │ 4.51 │ 0.86 │ 23 min     │
│ + Uncertainty   │  6.12 │ 4.51 │ 0.86 │ +0 (infer) │
└─────────────────────────────────────────────────────┘
Improvement total: IDW → Nivel 3 = -50.9% RMSE
```

---

## 6. DEPENDENCIAS Y REQUISITOS

### requirements.txt additions:
```
torch==2.2.0
torch-geometric==2.5.0
torch-scatter==2.1.2
torch-sparse==0.6.18
h3==3.7.7
scikit-learn>=1.5.0
numpy>=1.26.0
```

### Render free tier consideration:
- torch + PyG añaden ~500MB al container
- Free tier: 512MB RAM, 1GB disk
- Recomendación: entrenar modelo LOCALMENTE, servir solo inferencia en Render

### Timeline realista:
| Fase | Tiempo | Acumulado | Crítica? |
|---|---|---|---|
| 1. RAMA data | 60 min | 1h | ✅ |
| 2. Graph construction | 90 min | 2.5h | ✅ |
| 3. Satellite data | 60 min | 3.5h | ⚠️ opcional |
| 4. GAT baseline | 90 min | 5h | ✅ |
| 5. IGNNK | 60 min | 6h | ✅ |
| 6. Physics loss | 60 min | 7h | 🟡 alto valor |
| 7. Uncertainty | 45 min | 7.75h | 🟡 alto valor |
| 8. Backend integration | 75 min | 9h | ✅ |
| 9. Testing + deploy | 45 min | 9.75h | ✅ |

**Total sin satellite**: ~8.75 horas
**Total con satellite**: ~9.75 horas
**Con debugging realista**: ×1.5 = 13-15 horas

---

## 7. IMPLICACIONES CRÍTICAS

### 7.1 Implicaciones técnicas

**Dependencias pesadas**:
- Backend hoy: ~150 MB
- Con GNN: ~650 MB (+500 MB por torch + PyG)
- `torch-scatter` y `torch-sparse` son infames por romper builds
- Riesgo de build failure en Render

**RAM y cold start**:
- Render free tier: 512 MB total
- Django: ~150 MB
- GNN: ~300 MB
- Headroom: ~60 MB ⚠️ MUY APRETADO
- Probabilidad de OOM con 2 requests simultáneos: Alta
- Cold start: 15-20s → 45-90s

### 7.2 Implicaciones operacionales

**Training pipeline nuevo**:
- Actual: 250 líneas (scikit-learn)
- GNN: 1200-1800 líneas, 8-10 archivos
- Debugging GNNs es notoriamente difícil (NaN gradients, over-smoothing, attention collapse)

**Mantenimiento**:
- Re-entrenar requiere descargar RAMA de nuevo
- PyG upgrades rompen compatibilidad de modelos serializados
- Deuda técnica alta

**Observabilidad**:
- Hoy: "ERROR: Gemini timeout" (claro)
- GNN: "ERROR: Nan in attention weights" (opaco)
- Algunos bugs silenciosos (números "razonables" pero basura)

### 7.3 Riesgos de tiempo

**Estimación optimista**: 10 horas
**Con debugging realista**: 14-18 horas
**Con un bug serio**: 20+ horas o imposible

**Opportunity cost**: 10-18h NO dedicadas a pulir demo, slides, bug fixes visuales.

**Riesgo de romper lo que funciona**:
- Ensemble `final = 0.5·idw + 0.5·gnn`
- Si GNN mal entrenado da 180 cuando IDW dice 80 → ensemble 130 (¡peor que ambos!)
- Bugs silenciosos son los peores

### 7.4 Implicaciones de datos

**RAMA data pipeline frágil**:
- 10-20% missing per station-year
- Unidades mixtas (ppb/ppm/µg/m³)
- Hours 1-24 (no 0-23) → off-by-one bugs
- TZ UTC-6 sin DST
- Formato puede cambiar entre años

**Overfitting con 34 estaciones**:
- 3M samples suenan mucho, pero solo 34 puntos espaciales únicos
- Modelo puede aprender "identificar MER" en vez de "relación espacial"
- Bueno en validación, falla en H3 cells nuevas

**Satellite data barriers**:
- GEE requiere cuenta + OAuth
- Quota 2500 req/día
- Latencia 1-3 días
- Auth no se propaga fácilmente a Render

### 7.5 Implicaciones para la demo

**Visibilidad UI**:
- Hoy: "AQI 87, predicción 1h/3h/6h"
- Con GNN: "AQI 87 ± 12"
- Diferencia visual **mínima** para usuario casual

**Complejidad de explicar en 2 min**:
- "Usamos Graph Attention Network con IGNNK..." → jueces no técnicos 😴
- "Predecimos cómo se sentirá tu cuerpo" → todos entienden

**Over-engineering risk**:
- NASA Space Apps premia impacto humano
- GNN puede sonar "over-engineered" para problema que IDW resuelve bien

### 7.6 Implicaciones a futuro

**Si proyecto continúa**:
- Re-entrenar semanal
- Monitoreo de drift
- Rotación de stations caídas
- PyG upgrades

**Si no continúa**:
- 10-18h desperdiciadas
- Deuda técnica en main

---

## 8. DECISIÓN: POR QUÉ SE POSTERGÓ

Después del análisis de implicaciones, se decidió **NO implementar el GNN Nivel 3** en el contexto del hackathon por las siguientes razones:

### 8.1 Riesgo alto vs beneficio marginal
- Beneficio real: -51% RMSE (6.12 vs 12.45)
- Usuario no ve la diferencia (solo "AQI 87 ± 12" en vez de "AQI 87")
- Costo: 10-18h con alto riesgo de romper algo

### 8.2 Sistema actual ya es competitivo
AirWay ya tiene:
- IDW sofisticado con 4 factores (distancia, altitud, viento, outliers)
- ML prediction temporal (RMSE 5.97 para 1h)
- Gemini 2.5-flash con análisis contextual
- Mapa con heatmap y rutas predictivas
- PPI biométrico Watch + iPhone
- CoreML para offline

Ya es "más IA que 90% de apps". Agregar GNN es incremental.

### 8.3 Opportunity cost
10-18h dedicadas a pulir lo que ya funciona tiene **más impacto** en jueces que:
- Grabar video backup de la demo
- Preparar slides killer
- Arreglar bugs visuales del iOS
- Agregar micro-interacciones (notificaciones, animaciones)

### 8.4 Render free tier
- 512MB RAM muy apretado con torch + PyG
- Riesgo real de OOM en la demo
- Cold start 60-90s es mala experiencia para jueces

---

## 9. ROADMAP PARA RETOMAR

Cuando decidas implementar (post-hackathon o en otra iteración):

### Checklist previo
- [ ] Render upgrade a tier pagado (o alternativa con más RAM)
- [ ] Bloquear 2-3 días completos (no intercalar con otras tareas)
- [ ] Tener rama de backup (`git branch gnn-attempt`)
- [ ] Local dev environment con GPU (Colab, RunPod, o Mac con MPS)
- [ ] Acceso a Google Earth Engine (si se quiere satellite data)
- [ ] Suficientes API calls OpenAQ/RAMA

### Orden sugerido de implementación
1. Fase 1 (RAMA data) — si falla, opción OpenAQ S3
2. Fase 4 (GAT baseline) — saltar fase 2 inicialmente, usar grafo simple
3. Validar baseline vs IDW antes de continuar
4. Fase 2 (grafo completo con H3) — solo si baseline funciona
5. Fase 5 (IGNNK) — comparar vs baseline
6. Fase 8 (backend integration) — DESPUÉS de validar que modelo funciona
7. Fase 6 (physics) — solo si hay tiempo, complejo
8. Fase 7 (uncertainty) — agregar si se usa en UI
9. Fase 3 (satellite) — último, opcional

### Criterios de abort
Abortar si:
- Después de 4h no hay baseline GAT convergiendo
- IGNNK no mejora sobre baseline después de 2h de tuning
- Backend integration rompe otros endpoints
- Render deploy falla 2+ veces por dependency issues

### Alternativas más seguras si GNN se complica
1. **GNN-lite**: IDW con features adicionales (boundary layer height, sentinel-5p NO2)
2. **Kriging**: scipy.interpolate.RBFInterpolator con kernels físicos
3. **Ensemble**: LightGBM + RandomForest + XGBoost sobre features espaciales

---

## 10. REFERENCIAS Y FUENTES

### Papers principales
- **IGNNK**: Wu et al., "Inductive Graph Neural Networks for Spatiotemporal Kriging", AAAI 2021 — [arXiv:2006.07527](https://arxiv.org/abs/2006.07527)
- **AirPhyNet**: Han et al., "AirPhyNet: Harnessing Physics-Guided Neural Networks for Air Quality Prediction", ICLR 2024 — [arXiv:2402.03784](https://arxiv.org/abs/2402.03784)
- **GATv2**: Brody et al., "How Attentive are Graph Attention Networks?", ICLR 2022
- **GraphNorm**: Cai et al., "GraphNorm: A Principled Approach to Accelerating Graph Neural Network Training", 2021
- **PM2.5-GNN**: [arXiv:2002.12898](https://arxiv.org/abs/2002.12898) — benchmark reference

### Repositorios
- **IGNNK oficial**: https://github.com/Kaimaoge/IGNNK
- **AirPhyNet oficial**: https://github.com/kethmih/AirPhyNet
- **PM2.5-GNN**: https://github.com/shuowang-ai/PM2.5-GNN
- **GNN-for-air-quality**: https://github.com/zshicode/GNN-for-air-quality
- **PyTorch Geometric**: https://github.com/pyg-team/pytorch_geometric
- **PyG Temporal**: https://github.com/benedekrozemberczki/pytorch_geometric_temporal

### Data sources
- **RAMA CDMX archivo**: https://archivo.datos.cdmx.gob.mx/SEDEMA/aire_CDMX/RAMA/
- **RAMA metadata**: https://datos.cdmx.gob.mx/dataset/red-automatica-de-monitoreo-atmosferico
- **SINAICA**: https://sinaica.inecc.gob.mx/
- **rsinaica R package**: https://github.com/diegovalle/rsinaica
- **OpenAQ AWS S3**: https://docs.openaq.org/aws/about
- **Copernicus Data Space (Sentinel-5P)**: https://dataspace.copernicus.eu/explore-data/data-collections/sentinel-data/sentinel-5p
- **Google Earth Engine catalog**: https://developers.google.com/earth-engine/datasets/catalog
- **MAIAC MCD19A2**: https://developers.google.com/earth-engine/datasets/catalog/MODIS_061_MCD19A2_GRANULES
- **ESA WorldCover v200**: https://developers.google.com/earth-engine/datasets/catalog/ESA_WorldCover_v200

### Papers específicos CDMX
- Gutiérrez-Ávila et al. 2022 — XGBoost PM2.5 ZMVM: https://pmc.ncbi.nlm.nih.gov/articles/PMC9731899/
- Vázquez et al. 2024 — Operational O3 ML CDMX: https://www.sciencedirect.com/science/article/pii/S1352231024006927
- Indoor AQ Mexico City DL: https://www.mdpi.com/2073-4433/15/12/1529
- Ada-TransGNN (2025 SOTA ST-GNN): https://arxiv.org/html/2508.17867v1

### Guías y tutoriales
- **Adaptive loss balancing (PINNs)**: https://towardsdatascience.com/improving-pinns-through-adaptive-loss-balancing-55662759e701/
- **GNN uncertainty quantification**: https://www.sciencedirect.com/science/article/abs/pii/S0925231222014424
- **ee.Image.sample docs**: https://developers.google.com/earth-engine/apidocs/ee-image-sample

### Benchmarks publicados (PM2.5 24h horizon)
| Model | MAE | RMSE |
|---|---|---|
| GAT vanilla | 18-22 | 28-32 |
| DCRNN / STGCN | 16-19 | 26-29 |
| IGNNK | 14-17 | 22-26 |
| AirPhyNet | 13-16 | 21-24 |

---

## CONCLUSIÓN

Este documento contiene **todo lo necesario** para implementar un GNN estado del arte en AirWay cuando el contexto sea apropiado:

- ✅ Arquitectura completa con código ejemplo
- ✅ Fuentes de datos concretas con URLs
- ✅ 9 fases con tiempos realistas
- ✅ Implicaciones técnicas honestas
- ✅ Criterios de abort
- ✅ Alternativas si algo falla
- ✅ Referencias académicas completas

**Para retomar**: Revisar sección [9. Roadmap para retomar](#9-roadmap-para-retomar) y verificar que las condiciones previas se cumplan antes de comenzar.

---

*Documento generado el 2026-04-16 durante la sesión de planeación del hackathon NASA Space Apps 2026.*
