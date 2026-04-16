# IDEA 5: PREDICCION AQI CON CREATEML — GUIA DE IMPLEMENTACION COMPLETA

> **Objetivo**: Entrenar un modelo de ML que prediga PM2.5 a 1h, 3h y 6h usando datos historicos de CDMX, desplegarlo on-device con CoreML, y conectarlo con el sistema PPI existente para crear predicciones de salud personalizadas.
>
> **Tiempo estimado**: 3-4 horas (hackathon)
> **Prerequisitos**: macOS con Xcode 15+, Python 3.8+, pip

---

## TABLA DE CONTENIDOS

1. [Arquitectura general](#1-arquitectura-general)
2. [Paso 1: Descargar datos historicos](#2-paso-1-descargar-datos-historicos)
3. [Paso 2: Generar CSV de entrenamiento](#3-paso-2-generar-csv-de-entrenamiento)
4. [Paso 3: Entrenar modelo en CreateML](#4-paso-3-entrenar-modelo-en-createml)
5. [Paso 4: Integrar CoreML en el proyecto iOS](#5-paso-4-integrar-coreml-en-el-proyecto-ios)
6. [Paso 5: Conectar con el PPI Score existente](#6-paso-5-conectar-con-el-ppi-score-existente)
7. [Paso 6: UI - Mostrar predicciones](#7-paso-6-ui-mostrar-predicciones)
8. [Archivos existentes relevantes](#8-archivos-existentes-relevantes)
9. [Features optimos para prediccion PM2.5](#9-features-optimos)
10. [Limitaciones y gotchas](#10-limitaciones-y-gotchas)
11. [Alternativa: Entrenar con Python + coremltools](#11-alternativa-python)
12. [Como la prediccion mejora el PPI Score](#12-conexion-con-ppi)

---

## 1. ARQUITECTURA GENERAL

```
ENTRENAMIENTO (pre-hackathon)
=============================
Open-Meteo API (historico)     Python Script
  - Air Quality 2023-2025  -->  merge + feature  -->  CSV  -->  CreateML GUI  -->  .mlmodel
  - Weather 2023-2025           engineering                     (Boosted Tree)

INFERENCIA (en la app)
=============================
Open-Meteo API (actual)                                      
  - Weather forecast      \                                   
  - Current AQI           --> PM25PredictionService.swift --> prediccion PM2.5
Backend Django                  (CoreML on-device)              |
  - AirQualityAPIService /                                      |
                                                                v
                                                    PPI Context (backend)
                                                      - Dosis-respuesta
                                                      - PPI predicho
                                                      - Comparar con PPI real (Watch)
```

---

## 2. PASO 1: DESCARGAR DATOS HISTORICOS

### APIs de Open-Meteo (gratis, sin API key)

**Air Quality historico:**
```
https://air-quality-api.open-meteo.com/v1/air-quality
```

**Weather historico:**
```
https://archive-api.open-meteo.com/v1/archive
```

### Script Python completo

Crear archivo `scripts/download_training_data.py`:

```python
#!/usr/bin/env python3
"""
Descarga datos historicos de calidad del aire y clima de CDMX
desde Open-Meteo (gratis, sin API key) y genera CSV para CreateML.
"""

import requests
import pandas as pd
import numpy as np
import time
import os

# ── Configuracion ──────────────────────────────────────────
LAT = 19.4326      # CDMX centro
LON = -99.1332
TZ = "America/Mexico_City"
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# Periodos a descargar (Open-Meteo limita ~2 anos por request)
PERIODS = [
    ("2023-01-01", "2023-12-31"),
    ("2024-01-01", "2024-12-31"),
    ("2025-01-01", "2025-12-31"),
]


def download_air_quality(start_date, end_date):
    """Descarga datos horarios de calidad del aire."""
    url = (
        f"https://air-quality-api.open-meteo.com/v1/air-quality"
        f"?latitude={LAT}&longitude={LON}"
        f"&hourly=pm2_5,pm10,nitrogen_dioxide,ozone,carbon_monoxide,sulphur_dioxide,dust"
        f"&start_date={start_date}&end_date={end_date}"
        f"&timezone={TZ}"
    )
    print(f"  Descargando AQ: {start_date} -> {end_date}...")
    r = requests.get(url)
    r.raise_for_status()
    return pd.DataFrame(r.json()["hourly"])


def download_weather(start_date, end_date):
    """Descarga datos horarios de clima."""
    url = (
        f"https://archive-api.open-meteo.com/v1/archive"
        f"?latitude={LAT}&longitude={LON}"
        f"&hourly=temperature_2m,relative_humidity_2m,dew_point_2m,"
        f"surface_pressure,wind_speed_10m,wind_direction_10m,"
        f"wind_gusts_10m,precipitation,rain,cloud_cover,"
        f"shortwave_radiation,direct_radiation"
        f"&start_date={start_date}&end_date={end_date}"
        f"&timezone={TZ}"
    )
    print(f"  Descargando Weather: {start_date} -> {end_date}...")
    r = requests.get(url)
    r.raise_for_status()
    return pd.DataFrame(r.json()["hourly"])


def main():
    print("=" * 60)
    print("DESCARGA DE DATOS PARA AIRWAY - PREDICCION PM2.5")
    print("=" * 60)

    # ── 1. Descargar datos ──
    aq_frames = []
    wx_frames = []

    for start, end in PERIODS:
        aq_frames.append(download_air_quality(start, end))
        time.sleep(1)  # Respetar rate limit
        wx_frames.append(download_weather(start, end))
        time.sleep(1)

    aq_df = pd.concat(aq_frames, ignore_index=True)
    wx_df = pd.concat(wx_frames, ignore_index=True)

    aq_df.rename(columns={"time": "datetime"}, inplace=True)
    wx_df.rename(columns={"time": "datetime"}, inplace=True)

    print(f"\nAir Quality: {len(aq_df)} filas")
    print(f"Weather: {len(wx_df)} filas")

    # ── 2. Merge en datetime ──
    merged = pd.merge(aq_df, wx_df, on="datetime", how="inner")
    print(f"Merged: {len(merged)} filas")

    # ── 3. Feature Engineering ──
    merged["datetime"] = pd.to_datetime(merged["datetime"])
    merged["hour"] = merged["datetime"].dt.hour
    merged["day_of_week"] = merged["datetime"].dt.dayofweek  # 0=Lunes
    merged["month"] = merged["datetime"].dt.month
    merged["is_weekend"] = (merged["day_of_week"] >= 5).astype(int)

    # Season (CDMX: seca Nov-Abr, lluvias May-Oct)
    merged["is_dry_season"] = merged["month"].apply(
        lambda m: 1 if m in [11, 12, 1, 2, 3, 4] else 0
    )

    # Lag features (CRITICOS para prediccion temporal)
    for lag in [1, 2, 3, 6, 12, 24]:
        merged[f"pm25_lag_{lag}h"] = merged["pm2_5"].shift(lag)

    # Rolling statistics
    for window in [3, 6, 12, 24]:
        merged[f"pm25_rolling_mean_{window}h"] = (
            merged["pm2_5"].rolling(window).mean()
        )
    merged["pm25_rolling_std_6h"] = merged["pm2_5"].rolling(6).std()
    merged["pm25_rolling_std_24h"] = merged["pm2_5"].rolling(24).std()

    # Delta (tendencia reciente)
    merged["pm25_delta_1h"] = merged["pm2_5"] - merged["pm2_5"].shift(1)
    merged["pm25_delta_3h"] = merged["pm2_5"] - merged["pm2_5"].shift(3)

    # Maximo reciente (detectar spikes)
    merged["pm25_max_24h"] = merged["pm2_5"].rolling(24).max()

    # ── 4. Targets: PM2.5 futuro ──
    for horizon in [1, 3, 6]:
        merged[f"pm25_target_{horizon}h"] = merged["pm2_5"].shift(-horizon)

    # ── 5. Limpiar ──
    # Eliminar datetime (CreateML no entiende datetime como feature)
    merged.drop(columns=["datetime"], inplace=True)

    # Eliminar filas con NaN (de lags, rolling, targets)
    before = len(merged)
    merged.dropna(inplace=True)
    print(f"Despues de dropna: {len(merged)} filas ({before - len(merged)} eliminadas)")

    # ── 6. Split temporal (80/20) ──
    split_idx = int(len(merged) * 0.8)
    train = merged.iloc[:split_idx]
    test = merged.iloc[split_idx:]

    print(f"\nTrain: {len(train)} filas")
    print(f"Test:  {len(test)} filas")
    print(f"Columnas ({len(merged.columns)}): {list(merged.columns)}")

    # ── 7. Guardar ──
    train_path = os.path.join(OUTPUT_DIR, "train_pm25_cdmx.csv")
    test_path = os.path.join(OUTPUT_DIR, "test_pm25_cdmx.csv")
    full_path = os.path.join(OUTPUT_DIR, "full_pm25_cdmx.csv")

    train.to_csv(train_path, index=False)
    test.to_csv(test_path, index=False)
    merged.to_csv(full_path, index=False)

    print(f"\nArchivos guardados:")
    print(f"  {train_path}")
    print(f"  {test_path}")
    print(f"  {full_path}")

    # ── 8. Estadisticas ──
    print(f"\n── Estadisticas PM2.5 ──")
    print(f"  Media:   {merged['pm2_5'].mean():.1f} ug/m3")
    print(f"  Mediana: {merged['pm2_5'].median():.1f} ug/m3")
    print(f"  Std:     {merged['pm2_5'].std():.1f} ug/m3")
    print(f"  Max:     {merged['pm2_5'].max():.1f} ug/m3")
    print(f"  Min:     {merged['pm2_5'].min():.1f} ug/m3")
    print(f"\nListo! Abre CreateML y carga train_pm25_cdmx.csv")


if __name__ == "__main__":
    main()
```

### Ejecutar:
```bash
cd /Users/emiliocontreras/Downloads/SpaceApps
mkdir -p scripts
# Copiar el script arriba a scripts/download_training_data.py
pip install requests pandas numpy
python scripts/download_training_data.py
```

### Output esperado:
- `scripts/train_pm25_cdmx.csv` (~20,000 filas, ~40 columnas)
- `scripts/test_pm25_cdmx.csv` (~5,000 filas)
- `scripts/full_pm25_cdmx.csv` (todo junto)

---

## 3. PASO 2: GENERAR CSV DE ENTRENAMIENTO

El script anterior ya genera el CSV con todas las features. Aqui esta la estructura exacta de columnas:

### Columnas del CSV

**Temporales (4)**:
| Columna | Tipo | Rango | Descripcion |
|---------|------|-------|-------------|
| `hour` | Int | 0-23 | Hora del dia |
| `day_of_week` | Int | 0-6 | 0=Lunes, 6=Domingo |
| `month` | Int | 1-12 | Mes |
| `is_weekend` | Int | 0-1 | 1 si sabado/domingo |
| `is_dry_season` | Int | 0-1 | 1 si Nov-Abr (CDMX) |

**Meteorologicas (12)**:
| Columna | Tipo | Unidad | Por que importa |
|---------|------|--------|-----------------|
| `temperature_2m` | Double | C | Inversiones atrapan contaminantes |
| `relative_humidity_2m` | Double | % | Crecimiento higroscopico de PM2.5 |
| `dew_point_2m` | Double | C | Contenido de humedad (mas estable que RH) |
| `surface_pressure` | Double | hPa | Proxy de estabilidad atmosferica |
| `wind_speed_10m` | Double | km/h | Dispersion; viento bajo = acumulacion |
| `wind_direction_10m` | Double | grados | Identifica fuentes upwind |
| `wind_gusts_10m` | Double | km/h | Mezcla turbulenta |
| `precipitation` | Double | mm | Deposicion humeda (lavado) |
| `rain` | Double | mm | Lluvia especificamente |
| `cloud_cover` | Double | % | Fotoquimica (formacion O3) |
| `shortwave_radiation` | Double | W/m2 | Reacciones fotoquimicas |
| `direct_radiation` | Double | W/m2 | Radiacion directa |

**Contaminantes actuales (7)**:
| Columna | Tipo | Unidad |
|---------|------|--------|
| `pm2_5` | Double | ug/m3 |
| `pm10` | Double | ug/m3 |
| `nitrogen_dioxide` | Double | ug/m3 |
| `ozone` | Double | ug/m3 |
| `carbon_monoxide` | Double | ug/m3 |
| `sulphur_dioxide` | Double | ug/m3 |
| `dust` | Double | ug/m3 |

**Lag features (6)**:
| Columna | Descripcion |
|---------|-------------|
| `pm25_lag_1h` | PM2.5 hace 1 hora |
| `pm25_lag_2h` | PM2.5 hace 2 horas |
| `pm25_lag_3h` | PM2.5 hace 3 horas |
| `pm25_lag_6h` | PM2.5 hace 6 horas |
| `pm25_lag_12h` | PM2.5 hace 12 horas |
| `pm25_lag_24h` | PM2.5 hace 24 horas (mismo hora ayer) |

**Rolling statistics (8)**:
| Columna | Descripcion |
|---------|-------------|
| `pm25_rolling_mean_3h` | Media movil 3 horas |
| `pm25_rolling_mean_6h` | Media movil 6 horas |
| `pm25_rolling_mean_12h` | Media movil 12 horas |
| `pm25_rolling_mean_24h` | Media movil 24 horas |
| `pm25_rolling_std_6h` | Desviacion estandar 6h |
| `pm25_rolling_std_24h` | Desviacion estandar 24h |
| `pm25_delta_1h` | Cambio respecto a 1h antes |
| `pm25_delta_3h` | Cambio respecto a 3h antes |
| `pm25_max_24h` | Maximo en ultimas 24h |

**Targets (3)** — columnas a predecir:
| Columna | Descripcion |
|---------|-------------|
| `pm25_target_1h` | PM2.5 en 1 hora (target principal) |
| `pm25_target_3h` | PM2.5 en 3 horas |
| `pm25_target_6h` | PM2.5 en 6 horas |

### Requisitos del formato CSV para CreateML

1. UTF-8, header en primera fila
2. Sin columna de indice
3. Sin columna datetime (ya removida)
4. Nombres de columna sin espacios (usar underscores)
5. Solo numeros (Int o Double, auto-detectados)
6. CreateML maneja valores faltantes en Boosted Trees (surrogate splits)

---

## 4. PASO 3: ENTRENAR MODELO EN CREATEML

### Opcion A: GUI de CreateML (recomendada para hackathon)

1. **Abrir CreateML**: Xcode > Open Developer Tool > Create ML
2. **New Document** > seleccionar **Tabular Regression**
3. **Nombre**: `PM25Predictor1h`
4. **Training Data**: Arrastrar `train_pm25_cdmx.csv`
5. **Target**: Seleccionar `pm25_target_1h`
6. **Features**: Automatico (usa todas las columnas excepto target). IMPORTANTE: Desmarcar `pm25_target_3h` y `pm25_target_6h` (son targets de otros modelos, no features)
7. **Algorithm**: **Boosted Tree**
8. **Parameters**:
   - Max Depth: `6`
   - Max Iterations: `500`
   - Step Size (learning rate): `0.1`
   - Subsample: `0.8`
   - Early Stopping Rounds: `10`
9. **Train**: Click play (< 60 seg en Mac con Apple Silicon)
10. **Evaluate**: Arrastrar `test_pm25_cdmx.csv` en el tab Evaluation
11. **Exportar**: Output tab > Get > Guardar como `PM25Predictor1h.mlmodel`

**Repetir para 3h y 6h** cambiando el target.

### Metricas esperadas (RMSE):
| Horizonte | RMSE esperado | Calidad |
|-----------|--------------|---------|
| 1 hora | 5-15 ug/m3 | Bueno |
| 3 horas | 10-25 ug/m3 | Aceptable |
| 6 horas | 15-35 ug/m3 | Desafiante |

### Opcion B: Programatico en Swift Playground

```swift
import CreateML
import Foundation

let trainURL = URL(fileURLWithPath: "/path/to/train_pm25_cdmx.csv")
let testURL = URL(fileURLWithPath: "/path/to/test_pm25_cdmx.csv")

let trainData = try MLDataTable(contentsOf: trainURL)
let testData = try MLDataTable(contentsOf: testURL)

// Remover targets que no son el actual
var featureColumns = trainData.columnNames.filter {
    !["pm25_target_1h", "pm25_target_3h", "pm25_target_6h"].contains($0)
}

let regressor = try MLBoostedTreeRegressor(
    trainingData: trainData,
    targetColumn: "pm25_target_1h",
    featureColumns: featureColumns,
    parameters: MLBoostedTreeRegressor.ModelParameters(
        maxDepth: 6,
        maxIterations: 500,
        minLossReduction: 0,
        minChildWeight: 1,
        stepSize: 0.1,
        subsample: 0.8,
        earlyStoppingRounds: 10
    )
)

// Evaluar
let metrics = regressor.evaluation(on: testData)
print("RMSE: \(metrics.rootMeanSquaredError)")
print("Max Error: \(metrics.maximumError)")

// Guardar
let modelURL = URL(fileURLWithPath: "/path/to/PM25Predictor1h.mlmodel")
try regressor.write(to: modelURL)
```

---

## 5. PASO 4: INTEGRAR COREML EN EL PROYECTO iOS

### 5.1 Agregar modelo a Xcode

1. Arrastrar `PM25Predictor1h.mlmodel` al proyecto `AcessNet` en Xcode
2. Verificar que aparece en el target `AcessNet`
3. Xcode auto-genera la clase `PM25Predictor1h`
4. **Clean build**: Cmd+Shift+K, luego Cmd+B

### 5.2 Crear PM25PredictionService.swift

Archivo: `frontend/AcessNet/Core/Services/PM25PredictionService.swift`

```swift
//
//  PM25PredictionService.swift
//  AcessNet
//
//  On-device PM2.5 prediction using CoreML.
//  Trained on 3 years of CDMX data (Open-Meteo + weather).
//
//  Features: temporal + meteorological + lag + rolling stats
//  Output: predicted PM2.5 (ug/m3) for 1h, 3h, 6h ahead
//
//  Integration: feeds into PPI Context for predictive health scoring.
//

import CoreML
import Foundation

// MARK: - Prediction Service

class PM25PredictionService {

    static let shared = PM25PredictionService()

    private let model1h: PM25Predictor1h?
    // private let model3h: PM25Predictor3h?  // Si entrenas modelos adicionales
    // private let model6h: PM25Predictor6h?

    // Validation RMSE (reemplazar con el valor real despues de entrenar)
    private let validationRMSE: Double = 10.0

    // Historial reciente para calcular lags y rolling stats
    private var recentPM25: [(value: Double, date: Date)] = []
    private let maxHistoryHours = 25 // Necesitamos 24h de historia

    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine

        self.model1h = try? PM25Predictor1h(configuration: config)
    }

    // MARK: - Public API

    /// Predecir PM2.5 para 1 hora adelante
    func predict(
        currentPM25: Double,
        weather: WeatherInput,
        pollutants: PollutantInput
    ) -> PM25PredictionResult? {

        guard let model = model1h else { return nil }

        // Actualizar historial
        addToHistory(value: currentPM25)

        // Calcular features derivadas
        let lags = calculateLags()
        let rolling = calculateRolling()
        let deltas = calculateDeltas()

        let now = Date()
        let calendar = Calendar.current

        // Construir input (nombres DEBEN coincidir con columnas del CSV)
        do {
            let input = PM25Predictor1hInput(
                hour: Double(calendar.component(.hour, from: now)),
                day_of_week: Double(calendar.component(.weekday, from: now) - 1),
                month: Double(calendar.component(.month, from: now)),
                is_weekend: calendar.isDateInWeekend(now) ? 1.0 : 0.0,
                is_dry_season: isDrySeason(month: calendar.component(.month, from: now)) ? 1.0 : 0.0,
                temperature_2m: weather.temperature,
                relative_humidity_2m: weather.humidity,
                dew_point_2m: weather.dewPoint,
                surface_pressure: weather.pressure,
                wind_speed_10m: weather.windSpeed,
                wind_direction_10m: weather.windDirection,
                wind_gusts_10m: weather.windGusts,
                precipitation: weather.precipitation,
                rain: weather.rain,
                cloud_cover: weather.cloudCover,
                shortwave_radiation: weather.solarRadiation,
                direct_radiation: weather.directRadiation,
                pm2_5: currentPM25,
                pm10: pollutants.pm10,
                nitrogen_dioxide: pollutants.no2,
                ozone: pollutants.o3,
                carbon_monoxide: pollutants.co,
                sulphur_dioxide: pollutants.so2,
                dust: pollutants.dust,
                pm25_lag_1h: lags.lag1h,
                pm25_lag_2h: lags.lag2h,
                pm25_lag_3h: lags.lag3h,
                pm25_lag_6h: lags.lag6h,
                pm25_lag_12h: lags.lag12h,
                pm25_lag_24h: lags.lag24h,
                pm25_rolling_mean_3h: rolling.mean3h,
                pm25_rolling_mean_6h: rolling.mean6h,
                pm25_rolling_mean_12h: rolling.mean12h,
                pm25_rolling_mean_24h: rolling.mean24h,
                pm25_rolling_std_6h: rolling.std6h,
                pm25_rolling_std_24h: rolling.std24h,
                pm25_delta_1h: deltas.delta1h,
                pm25_delta_3h: deltas.delta3h,
                pm25_max_24h: rolling.max24h
            )

            let output = try model.prediction(input: input)
            let predicted = max(0, output.pm25_target_1h) // PM2.5 no puede ser negativo

            // Calcular confianza basada en RMSE de validacion
            let confidence = calculateConfidence(predicted: predicted)

            return PM25PredictionResult(
                predictedPM25: predicted,
                predictedAQI: pm25ToAQI(predicted),
                forecastHours: 1,
                confidence: confidence,
                lower95: max(0, predicted - 1.96 * validationRMSE),
                upper95: predicted + 1.96 * validationRMSE,
                timestamp: now
            )

        } catch {
            print("CoreML prediction error: \(error)")
            return nil
        }
    }

    // MARK: - History Management

    func addToHistory(value: Double) {
        recentPM25.append((value: value, date: Date()))
        // Mantener solo ultimas 25 horas
        let cutoff = Date().addingTimeInterval(-Double(maxHistoryHours) * 3600)
        recentPM25.removeAll { $0.date < cutoff }
    }

    // MARK: - Feature Calculations

    private func calculateLags() -> LagFeatures {
        let now = Date()
        return LagFeatures(
            lag1h: valueAtHoursAgo(1, from: now),
            lag2h: valueAtHoursAgo(2, from: now),
            lag3h: valueAtHoursAgo(3, from: now),
            lag6h: valueAtHoursAgo(6, from: now),
            lag12h: valueAtHoursAgo(12, from: now),
            lag24h: valueAtHoursAgo(24, from: now)
        )
    }

    private func calculateRolling() -> RollingFeatures {
        let values = recentPM25.map { $0.value }
        return RollingFeatures(
            mean3h: mean(of: values.suffix(3)),
            mean6h: mean(of: values.suffix(6)),
            mean12h: mean(of: values.suffix(12)),
            mean24h: mean(of: values.suffix(24)),
            std6h: std(of: values.suffix(6)),
            std24h: std(of: values.suffix(24)),
            max24h: values.suffix(24).max() ?? 0
        )
    }

    private func calculateDeltas() -> DeltaFeatures {
        let current = recentPM25.last?.value ?? 0
        return DeltaFeatures(
            delta1h: current - (valueAtHoursAgo(1, from: Date())),
            delta3h: current - (valueAtHoursAgo(3, from: Date()))
        )
    }

    private func valueAtHoursAgo(_ hours: Int, from date: Date) -> Double {
        let target = date.addingTimeInterval(-Double(hours) * 3600)
        let tolerance: TimeInterval = 1800 // 30 min tolerance
        let match = recentPM25.first { abs($0.date.timeIntervalSince(target)) < tolerance }
        return match?.value ?? recentPM25.last?.value ?? 0
    }

    // MARK: - Math Helpers

    private func mean(of values: ArraySlice<Double>) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func std(of values: ArraySlice<Double>) -> Double {
        guard values.count > 1 else { return 0 }
        let avg = mean(of: values)
        let variance = values.reduce(0) { $0 + ($1 - avg) * ($1 - avg) } / Double(values.count - 1)
        return sqrt(variance)
    }

    private func isDrySeason(month: Int) -> Bool {
        [11, 12, 1, 2, 3, 4].contains(month)
    }

    // MARK: - Confidence

    private func calculateConfidence(predicted: Double) -> Double {
        // Confianza inversamente proporcional a la incertidumbre relativa
        let relativeUncertainty = validationRMSE / max(predicted, 1.0)
        return max(0, min(1.0, 1.0 - relativeUncertainty / 2.0))
    }

    // MARK: - PM2.5 to AQI Conversion (EPA US)

    func pm25ToAQI(_ pm25: Double) -> Int {
        let breakpoints: [(pmLo: Double, pmHi: Double, aqiLo: Double, aqiHi: Double)] = [
            (0.0, 12.0, 0, 50),
            (12.1, 35.4, 51, 100),
            (35.5, 55.4, 101, 150),
            (55.5, 150.4, 151, 200),
            (150.5, 250.4, 201, 300),
            (250.5, 350.4, 301, 400),
            (350.5, 500.4, 401, 500)
        ]
        for bp in breakpoints {
            if pm25 >= bp.pmLo && pm25 <= bp.pmHi {
                let aqi = ((bp.aqiHi - bp.aqiLo) / (bp.pmHi - bp.pmLo)) * (pm25 - bp.pmLo) + bp.aqiLo
                return Int(round(aqi))
            }
        }
        return 500
    }
}

// MARK: - Supporting Types

struct WeatherInput {
    let temperature: Double
    let humidity: Double
    let dewPoint: Double
    let pressure: Double
    let windSpeed: Double
    let windDirection: Double
    let windGusts: Double
    let precipitation: Double
    let rain: Double
    let cloudCover: Double
    let solarRadiation: Double
    let directRadiation: Double
}

struct PollutantInput {
    let pm10: Double
    let no2: Double
    let o3: Double
    let co: Double
    let so2: Double
    let dust: Double
}

struct PM25PredictionResult {
    let predictedPM25: Double      // ug/m3
    let predictedAQI: Int          // 0-500
    let forecastHours: Int         // 1, 3, o 6
    let confidence: Double         // 0-1
    let lower95: Double            // Intervalo inferior 95%
    let upper95: Double            // Intervalo superior 95%
    let timestamp: Date

    var aqiCategory: String {
        switch predictedAQI {
        case 0...50: return "Bueno"
        case 51...100: return "Moderado"
        case 101...150: return "Insalubre (sensibles)"
        case 151...200: return "Insalubre"
        case 201...300: return "Muy insalubre"
        default: return "Peligroso"
        }
    }
}

struct LagFeatures {
    let lag1h, lag2h, lag3h, lag6h, lag12h, lag24h: Double
}

struct RollingFeatures {
    let mean3h, mean6h, mean12h, mean24h: Double
    let std6h, std24h: Double
    let max24h: Double
}

struct DeltaFeatures {
    let delta1h, delta3h: Double
}
```

---

## 6. PASO 5: CONECTAR CON EL PPI SCORE EXISTENTE

### Como funciona la conexion

Tu backend ya tiene coeficientes dosis-respuesta en `ppi/views.py`:

```python
DOSE_RESPONSE = {
    "spo2_drop_per_pm25": 0.010,       # -0.01% SpO2 por cada ug/m3
    "hrv_decrease_pct_per_pm25": 0.09,  # -0.09% HRV por cada ug/m3
    "hr_increase_per_pm25": 0.084,      # +0.084 bpm por cada ug/m3
    "resp_increase_pct_per_pm25": 0.035, # +0.035% resp por cada ug/m3
}
```

Con el PM2.5 predicho, puedes calcular el PPI futuro:

```
PM2.5 predicho (1h) = 85 ug/m3
  → SpO2 drop esperado = 85 * 0.010 = 0.85%
  → HRV decrease esperado = 85 * 0.09 = 7.65%
  → HR increase esperado = 85 * 0.084 = 7.14 bpm
  → Resp increase esperado = 85 * 0.035 = 2.98%
  
→ PPI estimado futuro = sigmoid(deltas) ≈ 48 (Moderate)
```

### Nuevo endpoint sugerido en backend

Archivo: `backend-api/src/interfaces/api/ppi/views.py` (agregar)

```python
class PPIForecastView(APIView):
    """
    GET /api/v1/ppi/forecast?lat=19.43&lon=-99.13&pm25_predicted=85
    
    Dado un PM2.5 predicho (del modelo CoreML del iPhone),
    estima que PPI tendra el usuario en el futuro.
    """
    def get(self, request):
        lat = float(request.query_params.get("lat"))
        lon = float(request.query_params.get("lon"))
        pm25_pred = float(request.query_params.get("pm25_predicted", 0))
        
        # Usar los mismos coeficientes del PPI Context
        impact = _estimate_biometric_impact(
            {"pm25": {"value": pm25_pred}},
            aqi=int(pm25_pred * 2)  # Estimacion rough
        )
        ppi_est = _estimate_ppi_range(impact)
        
        return Response({
            "pm25_predicted": pm25_pred,
            "ppi_forecast": ppi_est,
            "expected_impact": impact,
            "recommendation": _ppi_recommendation(
                int(pm25_pred * 2),
                ppi_est["risk_level"]
            ),
        })
```

### O calcularlo directamente en el iPhone (sin backend)

```swift
// Agregar a PM25PredictionService.swift

struct PPIForecast {
    let estimatedPPI: Int           // 0-100
    let estimatedPPIAsthmatic: Int  // Con multiplicador
    let riskLevel: String           // "low", "moderate", "high", "very_high"
    let spo2DropEstimate: Double
    let hrvDecreaseEstimate: Double
    let hrIncreaseEstimate: Double
}

extension PM25PredictionService {

    /// Predecir PPI futuro basado en PM2.5 predicho
    func predictPPI(fromPredictedPM25 pm25: Double) -> PPIForecast {
        // Coeficientes del paper (mismos que ppi/views.py)
        let spo2Drop = pm25 * 0.010
        let hrvDecrease = pm25 * 0.09
        let hrIncrease = pm25 * 0.084
        let respIncrease = pm25 * 0.035

        // Sigmoid mapping (mismos midpoints que PPIScoreEngine.swift)
        let spo2Score = sigmoid(spo2Drop, midpoint: 3.0, steepness: 1.2) * 100
        let hrvScore = sigmoid(hrvDecrease, midpoint: 25.0, steepness: 0.07) * 100
        let hrScore = sigmoid(hrIncrease, midpoint: 12.0, steepness: 0.20) * 100
        let respScore = sigmoid(respIncrease, midpoint: 20.0, steepness: 0.08) * 100

        // Pesos (mismos que PPIScoreEngine)
        let ppi = spo2Score * 0.35 + hrvScore * 0.30 + hrScore * 0.20 + respScore * 0.15
        let ppiClamped = min(100, max(0, Int(round(ppi))))

        let riskLevel: String
        switch ppiClamped {
        case 0..<25: riskLevel = "low"
        case 25..<50: riskLevel = "moderate"
        case 50..<75: riskLevel = "high"
        default: riskLevel = "very_high"
        }

        return PPIForecast(
            estimatedPPI: ppiClamped,
            estimatedPPIAsthmatic: min(100, Int(Double(ppiClamped) * 1.5)),
            riskLevel: riskLevel,
            spo2DropEstimate: spo2Drop,
            hrvDecreaseEstimate: hrvDecrease,
            hrIncreaseEstimate: hrIncrease
        )
    }

    private func sigmoid(_ x: Double, midpoint: Double, steepness: Double) -> Double {
        let raw = 1.0 / (1.0 + exp(-steepness * (x - midpoint)))
        let floor = 1.0 / (1.0 + exp(-steepness * (0 - midpoint)))
        let ceiling = 1.0 / (1.0 + exp(-steepness * (100 - midpoint)))
        return max(0, min(1, (raw - floor) / (ceiling - floor)))
    }
}
```

---

## 7. PASO 6: UI - MOSTRAR PREDICCIONES

### Donde integrar en la app existente

El archivo `DailyForecastView.swift` (1808 lineas) ya tiene toda la estructura UI para forecast. Actualmente usa datos de ejemplo (`DailyForecast.sampleData`).

**Punto de integracion**: Reemplazar `sampleData` con predicciones reales del modelo.

### Agregar card de prediccion ML en RouteInfoCard

En `Features/Map/Components/RouteInfoCard.swift`, agregar una seccion:

```swift
// Dentro de RouteInfoCard
VStack(alignment: .leading, spacing: 8) {
    HStack {
        Image(systemName: "brain")
        Text("Prediccion IA")
            .font(.subheadline.bold())
        Spacer()
        ConfidenceBadge(confidence: prediction.confidence)
    }
    
    HStack {
        VStack(alignment: .leading) {
            Text("En 1 hora")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(prediction.predictedAQI)")
                .font(.title2.bold())
                .foregroundColor(colorForAQI(prediction.predictedAQI))
        }
        
        Spacer()
        
        VStack(alignment: .leading) {
            Text("PPI estimado")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(ppiForecast.estimatedPPI)")
                .font(.title2.bold())
                .foregroundColor(colorForPPI(ppiForecast.estimatedPPI))
        }
        
        Spacer()
        
        VStack(alignment: .trailing) {
            Text("Riesgo")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(ppiForecast.riskLevel.capitalized)
                .font(.subheadline.bold())
        }
    }
    
    // Etiqueta "Prediccion IA" vs "Medido"
    HStack {
        Image(systemName: "sparkles")
            .font(.caption2)
        Text("Prediccion IA — Confianza \(Int(prediction.confidence * 100))%")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
}
```

---

## 8. ARCHIVOS EXISTENTES RELEVANTES

### Backend (Python/Django)

| Archivo | Que hace | Conexion con Idea 5 |
|---------|---------|---------------------|
| `adapters/air/openmeteo_provider.py` | Fetch de Open-Meteo (ya tiene `get_forecast()`) | Los datos de forecast alimentan features del modelo |
| `application/air/aggregator.py` | IDW multi-fuente con confianza | Datos actuales que sirven como input del modelo |
| `application/routes/exposure.py` | Calcula dosis de exposicion por ruta | La prediccion mejora el calculo de dosis futura |
| `interfaces/api/ppi/views.py` | Estimaciones dosis-respuesta para PPI | Coeficientes que convierten PM2.5 predicho -> PPI futuro |
| `adapters/ai/llm_service.py` | Analisis con Gemini LLM | Puede recibir prediccion ML como input adicional |

### Frontend iOS (Swift)

| Archivo | Que hace | Conexion con Idea 5 |
|---------|---------|---------------------|
| `Core/Services/AirQualityAPIService.swift` | Comunicacion con backend Django | Extender para obtener weather data para features |
| `Core/Services/RouteOptimizer.swift` | Optimizacion de rutas | Usar prediccion para scoring de rutas futuras |
| `Shared/Models/AirQualityModels.swift` | Modelos de datos (AirQualityPoint) | Ya tiene pm25, pm10, no2, o3, co, so2 |
| `Shared/Models/DailyForecast.swift` | Modelos de forecast | Extender con campos de prediccion ML |
| `Features/AirQuality/Views/DailyForecastView.swift` | UI de forecast (1808 lineas) | Mostrar predicciones ML aqui |
| `Features/Health/Views/PPIDashboardView.swift` | Dashboard PPI en iPhone | Mostrar PPI predicho vs PPI actual |

### Watch (Swift)

| Archivo | Que hace | Conexion con Idea 5 |
|---------|---------|---------------------|
| `Services/PPIScoreEngine.swift` | Motor PPI (sigmoid + Holt smoothing) | PPI predicho usa los mismos sigmoids y pesos |
| `Views/PPIScoreView.swift` | Visualizacion PPI en Watch | Podria mostrar tendencia PPI predicha |
| `Complication/PPIComplication.swift` | Complicacion watch face | Mostrar flecha de tendencia basada en prediccion |

---

## 9. FEATURES OPTIMOS

### Ranking por importancia (literatura ML + dominio)

| Rank | Feature | Importancia | Razon |
|------|---------|-------------|-------|
| 1 | `pm25_lag_1h` | Critica | PM2.5 es altamente autocorrelacionado |
| 2 | `pm25_lag_3h` | Critica | Tendencia a corto plazo |
| 3 | `pm25_rolling_mean_6h` | Critica | Regimen de contaminacion reciente |
| 4 | `pm25_lag_24h` | Alta | Ciclo diurno (misma hora ayer) |
| 5 | `hour` | Alta | Ciclo diurno (trafico, fotoquimica) |
| 6 | `wind_speed_10m` | Alta | Dispersion; viento bajo = acumulacion |
| 7 | `temperature_2m` | Alta | Inversiones termicas atrapan contaminantes |
| 8 | `relative_humidity_2m` | Media-Alta | Crecimiento higroscopico de PM2.5 |
| 9 | `surface_pressure` | Media | Proxy de estabilidad atmosferica |
| 10 | `wind_direction_10m` | Media | Fuentes upwind |
| 11 | `month` / `is_dry_season` | Media | Temporada seca CDMX = mas PM2.5 |
| 12 | `pm25_delta_1h` | Media | Tendencia inmediata |
| 13 | `pm25_max_24h` | Media | Detectar spikes recientes |

### NO incluir
- `datetime` string (CreateML no lo entiende)
- `latitude`/`longitude` (constantes para modelo single-city)
- Los otros targets (`pm25_target_3h` cuando entrenas para `pm25_target_1h`)

---

## 10. LIMITACIONES Y GOTCHAS

### Open-Meteo
- Datos historicos desde ~2022 (air quality)
- Resolucion espacial ~11-45km (modelo CAMS)
- Datos con 2-5 dias de retraso
- Rate limit: ~10,000 req/dia (gratis)

### CreateML
- **NO exporta feature importance** desde la GUI
- **NO da intervalos de confianza nativos** — usar RMSE como proxy
- **NO hace hyperparameter search** — ajustar manualmente
- **Solo validation split**, no cross-validation
- Los nombres de columna en el CSV **DEBEN coincidir exactamente** con los nombres usados en prediccion

### CoreML
- `MLModel.prediction()` es thread-safe pero puede bloquear — usar async
- Si pasas NaN/nil para un feature, la prediccion falla — siempre imputar
- Despues de agregar/reemplazar `.mlmodel`, hacer Clean Build (Cmd+Shift+K)
- La clase auto-generada tiene properties con los mismos nombres que las columnas del CSV

### Especificas de PM2.5 en CDMX
- Temporada seca (Nov-Abr) = PM2.5 significativamente mas alto
- Inversiones termicas frecuentes (valle rodeado de montanas)
- Popocatepetl puede causar spikes que el modelo no predice bien
- Evaluar SIEMPRE con split temporal (ultimo 20% cronologico), nunca random

---

## 11. ALTERNATIVA: PYTHON + COREMLTOOLS

Si quieres entrenar con scikit-learn y convertir a CoreML:

```python
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.metrics import mean_squared_error
import coremltools as ct
import numpy as np

# Cargar datos
train = pd.read_csv("scripts/train_pm25_cdmx.csv")
test = pd.read_csv("scripts/test_pm25_cdmx.csv")

# Features y target
target = "pm25_target_1h"
exclude = ["pm25_target_1h", "pm25_target_3h", "pm25_target_6h"]
features = [c for c in train.columns if c not in exclude]

X_train, y_train = train[features], train[target]
X_test, y_test = test[features], test[target]

# Entrenar
model = GradientBoostingRegressor(
    n_estimators=500,
    max_depth=6,
    learning_rate=0.1,
    subsample=0.8,
    random_state=42
)
model.fit(X_train, y_train)

# Evaluar
y_pred = model.predict(X_test)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))
print(f"RMSE: {rmse:.2f} ug/m3")

# Feature importance
importance = sorted(
    zip(features, model.feature_importances_),
    key=lambda x: x[1], reverse=True
)
print("\nTop 10 features:")
for feat, imp in importance[:10]:
    print(f"  {feat}: {imp:.4f}")

# Convertir a CoreML
coreml_model = ct.converters.sklearn.convert(
    model,
    input_features=features,
    output_feature_names="pm25_target_1h"
)
coreml_model.author = "AirWay Team"
coreml_model.short_description = "PM2.5 1h prediction for Mexico City"
coreml_model.save("PM25Predictor1h.mlmodel")
print("\nModelo guardado: PM25Predictor1h.mlmodel")
```

Instalar: `pip install scikit-learn coremltools`

Ventaja: obtienes feature importance + mas control sobre hyperparameters.

---

## 12. COMO LA PREDICCION MEJORA EL PPI SCORE

### Actualmente: PPI es REACTIVO
```
Aire contaminado → tu cuerpo reacciona → Watch detecta → PPI sube → alerta
                                                                    (tarde)
```

### Con prediccion: PPI es PREDICTIVO
```
Modelo predice PM2.5 futuro → dosis-respuesta → PPI estimado futuro → alerta PREVENTIVA
                                                                       (a tiempo)
```

### Los 4 superpoderes que desbloquea

**1. PPI Forecast**: "En 2 horas tu PPI sera ~58 (High). Sal antes de las 5pm."

**2. PPI por Ruta**:
```
Ruta A: PM2.5 promedio predicho 120 → PPI estimado 52 (High)
Ruta B: PM2.5 promedio predicho 65  → PPI estimado 18 (Low)
```

**3. Calibracion personal**: Acumular pares (PM2.5 real, PPI real) para aprender la sensibilidad especifica del usuario.

**4. Deteccion de anomalias**: Si PPI predicho = 25 pero PPI real = 70, algo inusual pasa (contaminante no medido, enfermedad incipiente, o sensor fallando).

### Frase para los jueces:
> "AirWay no solo te dice como esta el aire — predice como se SENTIRA tu cuerpo en las proximas horas y te deja decidir que hacer con esa informacion."

---

## CHECKLIST RAPIDO PARA EL HACKATHON

- [ ] Correr `download_training_data.py` (5 min)
- [ ] Verificar CSV tiene ~20K+ filas y ~40 columnas
- [ ] Abrir CreateML > Tabular Regression > cargar train CSV
- [ ] Target: `pm25_target_1h`, Algorithm: Boosted Tree
- [ ] Train (< 60 seg) > evaluar con test CSV > anotar RMSE
- [ ] Exportar `.mlmodel` > arrastrar a Xcode
- [ ] Clean Build (Cmd+Shift+K, Cmd+B)
- [ ] Agregar `PM25PredictionService.swift`
- [ ] Conectar con `DailyForecastView` o `RouteInfoCard`
- [ ] Agregar `predictPPI()` para PPI predictivo
- [ ] Actualizar `validationRMSE` con el valor real
- [ ] Probar en simulador: prediccion aparece con confianza

---

> **Documento generado**: 15 de Abril de 2026
> **Para usar en**: Proxima sesion de implementacion
> **Autocontenido**: SI — incluye scripts, codigo, endpoints, y archivos exactos
