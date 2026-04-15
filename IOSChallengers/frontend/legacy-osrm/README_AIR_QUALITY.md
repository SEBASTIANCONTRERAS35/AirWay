# 🌍 AcessNet - Air Quality Routing System

## Resumen Ejecutivo

AcessNet ahora incluye un **sistema de ruteo inteligente** que balancea **tiempo de viaje** y **calidad del aire** para recomendar las mejores rutas. Utilizando datos de las APIs de NASA (MODIS, GEOS-FP), la app analiza la calidad del aire a lo largo de cada ruta posible y aplica un algoritmo de scoring multi-criterio para seleccionar la ruta óptima según las preferencias del usuario.

---

## ✨ Características Principales

### 🎯 Sistema de Scoring Multi-criterio
- **Tiempo de viaje**: Score basado en rapidez de la ruta
- **Calidad del aire**: Score basado en AQI, PM2.5, y otros contaminantes
- **Ponderación flexible**: Usuario puede ajustar la importancia de cada factor

### 🌫️ Análisis de Calidad del Aire
- **AQI (Air Quality Index)**: 0-500 scale
- **PM2.5 & PM10**: Partículas en μg/m³
- **NO₂, O₃, CO, SO₂**: Gases contaminantes
- **AOD**: Aerosol Optical Depth (NASA MODIS)

### 📊 Visualización Avanzada
- Badges visuales de calidad del aire (colores por nivel)
- Indicadores de riesgo para la salud
- Scores circulares 0-100
- Comparación entre rutas alternativas

### ⚙️ Modos de Preferencia
1. **Fastest** (⚡): Solo velocidad, ignora calidad del aire
2. **Cleanest Air** (🌿): Solo calidad del aire, ignora tiempo
3. **Balanced** (⚖️): 50% tiempo + 50% aire
4. **Health Optimized** (❤️): 30% tiempo + 70% aire (para personas con condiciones respiratorias)
5. **Custom** (🎛️): Pesos personalizados por el usuario

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                    iOS App (AcessNet)                    │
├─────────────────────────────────────────────────────────┤
│  1. Apple MapKit MKDirections                           │
│     ↓ Obtiene 2-3 rutas alternativas con polylines      │
├─────────────────────────────────────────────────────────┤
│  2. RouteManager + AirQualityAPIService                 │
│     ↓ Samplea coordenadas cada 150m                     │
│     ↓ Envía batch request al backend                    │
├─────────────────────────────────────────────────────────┤
│  3. Backend API (Python/Node.js)                        │
│     ↓ Consulta NASA APIs para cada coordenada          │
│     ↓ Calcula estadísticas (avg AQI, PM2.5, etc.)      │
├─────────────────────────────────────────────────────────┤
│  4. NASA Data Sources                                   │
│     • MODIS Aerosol Optical Depth                       │
│     • GEOS-FP PM2.5 Forecast                           │
│     • LANCE Near Real-Time Data                         │
├─────────────────────────────────────────────────────────┤
│  5. Scoring Algorithm (iOS)                             │
│     ↓ Normaliza scores de tiempo y aire                │
│     ↓ Aplica ponderación según preferencia             │
│     ↓ Score = α·tiempo + β·calidad_aire                │
├─────────────────────────────────────────────────────────┤
│  6. UI Components                                       │
│     ↓ EnhancedRouteInfoCard con badges AQI             │
│     ↓ Polyline coloreado según AQI                     │
│     ↓ Comparación visual entre rutas                   │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Estructura de Archivos

```
AcessNet/
├── Core/
│   ├── Services/
│   │   ├── AirQualityAPIService.swift      ⭐ Cliente HTTP para backend
│   │   └── NotificationHandler.swift
│   ├── Managers/
│   │   └── LocationManager.swift
│   └── Extensions/
│       └── CLLocationCoordinate2D+Extensions.swift
├── Features/
│   └── Map/
│       ├── Services/
│       │   └── RouteManager.swift          ✏️ Modificado con scoring de aire
│       ├── Components/
│       │   ├── AirQualityBadge.swift       ⭐ Componentes UI de calidad del aire
│       │   ├── RouteInfoCard.swift         ✏️ Card mejorado con datos de aire
│       │   └── ...
│       └── Views/
│           └── ContentView.swift
└── Shared/
    └── Models/
        ├── AirQualityModels.swift          ⭐ Modelos de datos de calidad del aire
        ├── ScoredRoute.swift               ⭐ Modelo de ruta con scoring
        └── RouteModels.swift               ✏️ Extendido con nuevas preferencias
```

**Leyenda:**
- ⭐ = Archivo nuevo
- ✏️ = Archivo modificado

---

## 🚀 Quick Start

### 1. Testing con Mock Data (Sin Backend)

```swift
// RouteManager ya viene configurado con Mock activado
let routeManager = RouteManager(useMockService: true)

// Configurar preferencia
routeManager.setPreference(.balanced)

// Calcular ruta
routeManager.calculateRoute(
    from: userLocation,
    to: destinationCoordinate
)

// Observar resultado
@Published var currentScoredRoute: ScoredRoute?
```

### 2. Integración con Backend Real

```swift
// Paso 1: Cambiar URL en AirQualityAPIService.swift
private var baseURL: String {
    return "https://your-backend.com/api"
}

// Paso 2: Desactivar Mock
let routeManager = RouteManager(useMockService: false)

// Paso 3: Implementar endpoint en backend
// POST /api/air-quality/analyze-route
```

### 3. Uso en UI

```swift
// Mostrar ruta con datos de calidad del aire
if let scoredRoute = routeManager.currentScoredRoute {
    EnhancedRouteInfoCard(
        scoredRoute: scoredRoute,
        isCalculating: routeManager.isCalculating,
        onClear: { routeManager.clearRoute() },
        onStartNavigation: nil,
        showComparison: nil
    )
}
```

---

## 📊 Ejemplo de Uso Real

### Escenario: Usuario con asma busca ruta al trabajo

1. **Usuario selecciona destino**: "Oficina Central"
2. **Apple Maps retorna 3 rutas posibles**:
   - Ruta A (Autopista): 12 min, 8 km
   - Ruta B (Calle Principal): 15 min, 7.5 km
   - Ruta C (Barrio Residencial): 18 min, 9 km

3. **Sistema analiza calidad del aire**:
   - Ruta A: AQI 135 (tráfico pesado, zona industrial) ⚠️
   - Ruta B: AQI 85 (moderado)
   - Ruta C: AQI 45 (bueno, zona verde) ✅

4. **Scoring con preferencia "Health Optimized"** (30% tiempo + 70% aire):
   - Ruta A: Score 62 (rápida pero aire malo)
   - Ruta B: Score 78
   - Ruta C: Score **85** ⭐ (aire excelente compensa tiempo extra)

5. **Sistema recomienda Ruta C**:
   ```
   🏆 Best Route Selected
   9 km • 18 min
   AQI: 45 (Good)
   PM2.5: 12.5 μg/m³
   Risk: Low
   Score: 85/100 - Excellent Route

   📊 vs. fastest route:
   6 min slower, but 67% cleaner air ✨
   ```

---

## 🧪 Modo de Desarrollo

### Mock Service
El sistema incluye un **Mock Service** que genera datos simulados de calidad del aire. Esto permite desarrollar y probar sin tener el backend funcionando.

```swift
// Genera automáticamente:
- AQI aleatorio entre 20-150
- PM2.5 proporcional al AQI
- Timestamps realistas
- Simula latencia de red (0.5s)
```

### Logs de Debug
```
🌍 Analizando ruta con 28 coordenadas...
🧪 Mock: Generando datos simulados para 28 coordenadas
✅ Mock: AQI promedio 72
🏆 Mejor ruta seleccionada:
   - 5.2 km, 15 min
   - AQI promedio: 72
   - Score combinado: 82/100
   - Very Good Route
```

---

## 📡 API Requirements (Backend Team)

### Endpoint Principal

**POST** `/api/air-quality/analyze-route`

**Request:**
```json
{
  "coordinates": [
    {"latitude": 37.7749, "longitude": -122.4194},
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
    "segments": [...],
    "averageAQI": 72.3,
    "maxAQI": 95.0,
    "minAQI": 45.0,
    "averagePM25": 22.5,
    "overallHealthRisk": "Low"
  },
  "processingTimeMs": 450,
  "dataSource": "NASA-MODIS"
}
```

Ver documentación completa en `AIR_QUALITY_ROUTING_IMPLEMENTATION.md`

---

## 🎨 UI Components

### AirQualityBadge
Muestra AQI con colores según nivel:
- 🟢 0-50: Good
- 🟡 51-100: Moderate
- 🟠 101-150: Unhealthy for Sensitive Groups
- 🔴 151-200: Unhealthy
- 🟣 201-300: Very Unhealthy
- 🟤 301+: Hazardous

### HealthRiskBadge
Indicador visual de riesgo:
- ✅ Low
- ⚠️ Medium
- 🚨 High
- ☢️ Very High

### RouteScoreBadge
Score circular 0-100 con colores:
- 🟢 90-100: Excellent
- 🔵 75-89: Very Good
- 🟡 60-74: Good
- 🟠 40-59: Fair
- 🔴 0-39: Poor

---

## ⚖️ Algoritmo de Scoring

### Fórmula
```
Score(ruta) = α × normalizar(tiempo) + β × normalizar(AQI)

Normalización:
- timeScore = (tiempoMínimo / tiempoActual) × 100
- airScore = (1 - AQI/500) × 100
```

### Pesos por Preferencia
| Preferencia | α (tiempo) | β (aire) |
|-------------|-----------|----------|
| Fastest     | 100%      | 0%       |
| Cleanest Air| 0%        | 100%     |
| Balanced    | 50%       | 50%      |
| Health Opt. | 30%       | 70%      |
| Custom      | variable  | variable |

---

## 📈 Métricas y KPIs

El sistema puede trackear:
- Rutas calculadas con datos de aire
- Preferencia más usada por usuarios
- Tiempo promedio ahorrado vs. aire limpio ganado
- Usuarios con preferencia "Health Optimized" (posibles asmáticos/sensibles)

---

## 🔐 Seguridad y Privacidad

- ✅ No se almacenan coordenadas del usuario
- ✅ Requests a backend son efímeras
- ✅ Cache local con TTL de 30 min (datos de aire cambian lento)
- ✅ No se requiere autenticación para consultar calidad del aire

---

## 🌟 Próximas Mejoras

1. **Visualización de polyline por colores** según AQI
2. **Notificaciones** cuando ruta atraviesa zona de alta contaminación
3. **Historial** de rutas y exposición a contaminantes
4. **Modo nocturno** con algoritmo ajustado (menos tráfico, mejor aire)
5. **Predicción** de calidad del aire futura (usando forecasts de NASA)
6. **Compartir rutas** con métricas de salud

---

## 📚 Documentación Adicional

- `AIR_QUALITY_ROUTING_IMPLEMENTATION.md`: Guía completa de implementación
- Comentarios en código fuente (SwiftDoc format)
- SwiftUI Previews para cada componente

---

## 👥 Contribuidores

**iOS Development:**
- Sistema de scoring multi-criterio
- Integración con MapKit
- UI components con SwiftUI
- Mock service para testing

**Backend Team (Pendiente):**
- Endpoint de análisis de rutas
- Integración con NASA APIs
- Sistema de cache
- Rate limiting

---

## 📞 Soporte

Para preguntas o issues:
1. Revisar `AIR_QUALITY_ROUTING_IMPLEMENTATION.md`
2. Verificar logs en consola
3. Probar con Mock Mode activado
4. Consultar código fuente con comentarios

---

**Status:** ✅ iOS Implementation Complete | ⏳ Backend Integration Pending

**Versión:** 1.0.0

**Última actualización:** Enero 2025
