# 🌍 Air Quality Routing System - Implementation Guide

## ✅ Status: IMPLEMENTED (Fase iOS completa)

La implementación del sistema de ruteo con calidad del aire está **COMPLETA** en el lado de iOS. La app ahora puede:
- ✅ Calcular múltiples rutas usando Apple MapKit
- ✅ Analizar la calidad del aire de cada ruta (usando Mock Service o tu backend)
- ✅ Aplicar scoring multi-criterio balanceando tiempo y calidad del aire
- ✅ Mostrar badges visuales con AQI, PM2.5, y riesgo de salud
- ✅ Recomendar la mejor ruta según preferencias del usuario

---

## 📁 Archivos Creados/Modificados

### ✨ Nuevos Archivos

1. **`AirQualityModels.swift`** - Modelos de datos
   - `AQILevel`: Niveles de calidad del aire (Good, Moderate, Unhealthy, etc.)
   - `HealthRisk`: Evaluación de riesgo (Low, Medium, High, Very High)
   - `AirQualityPoint`: Datos de calidad en un punto (AQI, PM2.5, PM10, etc.)
   - `AirQualitySegment`: Segmento de ruta con datos de aire
   - `AirQualityRouteAnalysis`: Análisis completo de una ruta
   - Modelos de Request/Response para API

2. **`AirQualityAPIService.swift`** - Cliente HTTP
   - Servicio singleton para comunicación con backend
   - Métodos: `analyzeRoute()`, `getAirQuality()`, `getBatchAirQuality()`
   - **MockAirQualityAPIService**: Servicio simulado para testing sin backend
   - Manejo de errores robusto

3. **`ScoredRoute.swift`** - Modelo de ruta scored
   - `ScoredRoute`: Ruta con scoring de tiempo + aire
   - `RouteScoring`: Motor de cálculo de scores
   - `RouteComparison`: Comparación entre dos rutas
   - Extensiones de `RoutePreference` con pesos y nombres

4. **`AirQualityBadge.swift`** - Componentes UI
   - `AirQualityBadge`: Badge visual de AQI
   - `HealthRiskBadge`: Badge de riesgo de salud
   - `RouteScoreBadge`: Score circular 0-100
   - `PM25Indicator`: Indicador de partículas PM2.5
   - `RouteComparisonView`: Vista de comparación
   - `AirQualityRouteSummary`: Resumen completo

### 🔧 Archivos Modificados

1. **`RouteModels.swift`**
   - Extendido `RoutePreference` enum con nuevas opciones:
     - `cleanestAir`: 100% calidad del aire
     - `balanced`: 50% tiempo + 50% aire
     - `healthOptimized`: 30% tiempo + 70% aire
     - `customWeighted`: Pesos personalizados
   - Agregada propiedad `requiresAirQualityData`

2. **`RouteManager.swift`**
   - Agregadas propiedades `currentScoredRoute` y `alternateScoredRoutes`
   - Nuevo método `performAirQualityScoring()`: Análisis de calidad del aire
   - Nuevo método `samplePolylineCoordinates()`: Sampling de polyline
   - Integración del `AirQualityAPIService`
   - Modo Mock activado por defecto (cambiar a `false` para usar backend real)

3. **`RouteInfoCard.swift`**
   - Añadido `EnhancedRouteInfoCard`: Card con datos de calidad del aire
   - Muestra AQI, PM2.5, health risk badges
   - Muestra scores de tiempo, aire, y combinado
   - Comparación opcional con rutas alternativas

---

## 🚀 Cómo Usar el Sistema

### Paso 1: Configurar la preferencia de ruta

```swift
let routeManager = RouteManager()

// Opción 1: Modo balanceado (50% tiempo + 50% aire)
routeManager.setPreference(.balanced)

// Opción 2: Priorizar salud (30% tiempo + 70% aire)
routeManager.setPreference(.healthOptimized)

// Opción 3: Solo aire limpio
routeManager.setPreference(.cleanestAir)

// Opción 4: Pesos personalizados
routeManager.setPreference(.customWeighted(timeWeight: 0.6, airQualityWeight: 0.4))
```

### Paso 2: Calcular ruta

```swift
// Calcular ruta desde origen a destino
routeManager.calculateRoute(
    from: userLocation,
    to: destinationCoordinate
)
```

### Paso 3: Acceder a la ruta scored

```swift
// Observar la ruta calculada
@Published var currentScoredRoute: ScoredRoute?

// En la vista
if let scoredRoute = routeManager.currentScoredRoute {
    print("📍 Ruta seleccionada:")
    print("   - Distancia: \(scoredRoute.routeInfo.distanceFormatted)")
    print("   - Tiempo: \(scoredRoute.routeInfo.timeFormatted)")
    print("   - AQI promedio: \(Int(scoredRoute.averageAQI))")
    print("   - Score combinado: \(Int(scoredRoute.combinedScore))/100")
    print("   - \(scoredRoute.scoreDescription)")
}
```

### Paso 4: Mostrar en UI

```swift
// Usar el EnhancedRouteInfoCard
if let scoredRoute = routeManager.currentScoredRoute {
    EnhancedRouteInfoCard(
        scoredRoute: scoredRoute,
        isCalculating: routeManager.isCalculating,
        onClear: { routeManager.clearRoute() },
        onStartNavigation: { /* iniciar navegación */ },
        showComparison: nil  // Opcional: comparar con otra ruta
    )
}
```

---

## 🎨 Componentes UI Disponibles

### AirQualityBadge
```swift
// Badge completo
AirQualityBadge(aqi: 75)

// Badge compacto
AirQualityBadge(aqi: 75, compact: true)
```

### HealthRiskBadge
```swift
HealthRiskBadge(healthRisk: .medium)
```

### RouteScoreBadge
```swift
RouteScoreBadge(score: 85)
```

### PM25Indicator
```swift
PM25Indicator(pm25: 25.3)
```

### AirQualityRouteSummary
```swift
AirQualityRouteSummary(scoredRoute: scoredRoute)
```

---

## 🧪 Testing sin Backend (Mock Mode)

El sistema viene con un **Mock Service** que genera datos simulados. Está **ACTIVADO por defecto**.

### Cómo funciona el Mock

```swift
// En RouteManager.swift (línea 44)
private var useMockService: Bool = true  // ⬅️ CAMBIAR A false CUANDO TENGAS BACKEND REAL
```

El Mock genera:
- AQI aleatorio entre 20-150
- PM2.5 proporcional al AQI
- Simula delay de red (0.5 segundos)
- Permite probar toda la funcionalidad sin backend

### Logs en consola

```
🌍 Analizando ruta con 25 coordenadas...
🧪 Mock: Generando datos simulados para 25 coordenadas
✅ Mock: AQI promedio 87
🏆 Mejor ruta seleccionada:
   - 5.2 km, 15 min
   - AQI promedio: 87
   - Score combinado: 78/100
   - Very Good Route
```

---

## 🔌 Integración con Backend Real

### Paso 1: Configurar URL del backend

Edita `AirQualityAPIService.swift`:

```swift
private var baseURL: String {
    #if DEBUG
    return "http://localhost:8000/api"  // ⬅️ Cambiar por tu URL local
    #else
    return "https://your-backend.com/api"  // ⬅️ Cambiar por tu URL producción
    #endif
}
```

### Paso 2: Desactivar Mock Mode

En `RouteManager.swift`:

```swift
init(useMockService: Bool = false) {  // ⬅️ Cambiar default a false
    self.useMockService = useMockService
    self.airQualityService = useMockService ? MockAirQualityAPIService() : AirQualityAPIService.shared
}
```

### Paso 3: Backend debe implementar estos endpoints

#### POST `/api/air-quality/analyze-route`

**Request:**
```json
{
  "coordinates": [
    {"latitude": 37.7749, "longitude": -122.4194},
    {"latitude": 37.7849, "longitude": -122.4094},
    ...
  ],
  "samplingIntervalMeters": 150
}
```

**Response:**
```json
{
  "routeId": "abc123",
  "analysis": {
    "id": "uuid",
    "segments": [
      {
        "id": "uuid",
        "startCoordinate": {"latitude": 37.7749, "longitude": -122.4194},
        "endCoordinate": {"latitude": 37.7849, "longitude": -122.4094},
        "distanceMeters": 150,
        "airQuality": {
          "id": "uuid",
          "coordinate": {"latitude": 37.7749, "longitude": -122.4194},
          "aqi": 65.5,
          "pm25": 18.2,
          "pm10": 32.1,
          "no2": 25.0,
          "o3": 45.0,
          "co": 0.5,
          "so2": 10.0,
          "aod": 0.25,
          "timestamp": "2025-01-15T10:30:00Z"
        }
      },
      ...
    ],
    "averageAQI": 72.3,
    "maxAQI": 95.0,
    "minAQI": 45.0,
    "averagePM25": 22.5,
    "averageHealthScore": 75.2,
    "overallHealthRisk": "Low",
    "timestamp": "2025-01-15T10:30:00Z"
  },
  "processingTimeMs": 450,
  "dataSource": "NASA-MODIS"
}
```

#### POST `/api/air-quality/point`

**Request:**
```json
{
  "latitude": 37.7749,
  "longitude": -122.4194,
  "includeExtendedMetrics": true
}
```

**Response:**
```json
{
  "airQuality": {
    "id": "uuid",
    "coordinate": {"latitude": 37.7749, "longitude": -122.4194},
    "aqi": 65.5,
    "pm25": 18.2,
    "pm10": 32.1,
    "timestamp": "2025-01-15T10:30:00Z"
  },
  "dataSource": "NASA-GEOS-FP",
  "cacheAge": 120
}
```

#### POST `/api/air-quality/batch`

**Request:**
```json
{
  "coordinates": [
    {"latitude": 37.7749, "longitude": -122.4194},
    {"latitude": 37.7849, "longitude": -122.4094},
    ...
  ],
  "includeExtendedMetrics": false
}
```

**Response:**
```json
{
  "points": [
    {
      "id": "uuid",
      "coordinate": {"latitude": 37.7749, "longitude": -122.4194},
      "aqi": 65.5,
      "pm25": 18.2,
      "timestamp": "2025-01-15T10:30:00Z"
    },
    ...
  ],
  "dataSource": "NASA-MODIS",
  "totalProcessingTimeMs": 850
}
```

---

## 📊 Algoritmo de Scoring Detallado

### Fórmula Principal

```
Score(ruta) = α × timeScore + β × airQualityScore

donde:
- α + β = 1.0 (pesos suman 100%)
- α = peso del tiempo
- β = peso de calidad del aire
```

### Normalización de Scores

**Time Score (0-100):**
```swift
timeScore = (tiempoMásRápido / tiempoActual) × 100
```
- Ruta más rápida → 100
- Ruta más lenta → valor menor

**Air Quality Score (0-100):**
```swift
airQualityScore = (1 - AQI/500) × 100
```
- AQI 0 → 100 (perfecto)
- AQI 500 → 0 (pésimo)

### Ejemplo de Cálculo

**Escenario:** 3 rutas disponibles, preferencia `balanced` (50% tiempo + 50% aire)

| Ruta | Tiempo | AQI | Time Score | Air Score | Combined Score |
|------|--------|-----|------------|-----------|----------------|
| 1    | 15 min | 120 | 100        | 76        | **88** ⭐      |
| 2    | 18 min | 45  | 83         | 91        | 87             |
| 3    | 20 min | 35  | 75         | 93        | 84             |

**Ruta seleccionada:** Ruta 1 (mejor score combinado)

---

## 🎯 Casos de Uso

### Caso 1: Usuario con asma (priorizar aire limpio)

```swift
routeManager.setPreference(.healthOptimized)  // 30% tiempo + 70% aire
```

**Resultado:** Sistema priorizará rutas con mejor aire, aunque sean un poco más lentas.

### Caso 2: Urgencia (priorizar velocidad)

```swift
routeManager.setPreference(.fastest)  // 100% tiempo
```

**Resultado:** Sistema ignora calidad del aire, solo busca ruta más rápida.

### Caso 3: Balance (usuario neutral)

```swift
routeManager.setPreference(.balanced)  // 50% tiempo + 50% aire
```

**Resultado:** Sistema balancea ambos factores equitativamente.

### Caso 4: Personalizado

```swift
routeManager.setPreference(.customWeighted(timeWeight: 0.7, airQualityWeight: 0.3))
```

**Resultado:** 70% peso al tiempo, 30% a calidad del aire.

---

## 🔍 Debugging y Logs

El sistema imprime logs detallados en consola:

```
✅ Apple Maps retornó 3 rutas
🌍 Iniciando análisis de calidad del aire para 3 rutas...
  Analizando ruta 1/3...
    - Polyline tiene 28 puntos muestreados
    - AQI promedio: 72
  Analizando ruta 2/3...
    - Polyline tiene 32 puntos muestreados
    - AQI promedio: 55
  Analizando ruta 3/3...
    - Polyline tiene 35 puntos muestreados
    - AQI promedio: 48
🏆 Mejor ruta seleccionada:
   - 5.2 km, 15 min
   - AQI promedio: 48
   - Score combinado: 92/100
   - Excellent Route
```

---

## ⚠️ Pendientes (Backend Team)

1. **Endpoint de análisis de rutas** (`/api/air-quality/analyze-route`)
2. **Integración con NASA APIs:**
   - NASA Earthdata LANCE (near real-time)
   - MODIS Aerosol Optical Depth
   - GEOS-FP PM2.5 Forecast
3. **Sistema de cache** (TTL 15-30 min)
4. **Batch processing** para múltiples coordenadas
5. **Rate limiting** y manejo de errores

---

## 📝 Notas Finales

- **Sampling de polyline**: Se toma 1 punto cada 150m para no sobrecargar el backend
- **Datos temporales**: Los datos de aire cambian lentamente, se puede cachear 15-30 min
- **Error handling**: Si falla el análisis de aire, la ruta se muestra sin datos de calidad del aire
- **Backward compatibility**: Las propiedades legacy `currentRoute` y `alternateRoutes` se mantienen actualizadas

---

## 🆘 Soporte

Si tienes dudas sobre la implementación:
1. Revisa los logs en consola
2. Verifica que Mock Mode esté activado para testing
3. Usa los Previews de SwiftUI para ver los componentes UI
4. Consulta los comentarios en el código fuente

**Última actualización:** Enero 2025
**Versión:** 1.0.0
**Status:** Production Ready (iOS) + Pending Backend Integration
