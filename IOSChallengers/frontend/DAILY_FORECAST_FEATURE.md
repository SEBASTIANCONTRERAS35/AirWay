# Daily Forecast Feature - Pronóstico Diario de Calidad del Aire

## 📊 Nueva Funcionalidad Implementada

Se ha creado una vista completa de pronóstico diario de calidad del aire que muestra información detallada para los próximos 5 días, basada en las imágenes de referencia proporcionadas.

## 🗂️ Archivos Creados

### 1. **DailyForecast.swift**
Ubicación: `UI/AcessNet/Shared/Models/DailyForecast.swift`

**Modelos de datos:**
- `DailyForecast`: Datos diarios (AQI, PM2.5, PM10, NO2, O3, clima)
- `HourlyAQIData`: Datos por hora para el gráfico de barras
- `TipCategory`: Categorías de consejos (Running, Cycling, Health, Indoor)

**Datos de muestra incluidos:**
- 5 días de pronóstico (Thu 02 - Mon 06)
- 12 horas de datos para el gráfico
- 4 categorías de consejos con iconos

### 2. **DailyForecastView.swift**
Ubicación: `UI/AcessNet/Features/AirQuality/Views/DailyForecastView.swift`

**Vista principal completa con:**
- Header con tabs (DAY / MONTH)
- Selector de días con scroll horizontal
- Card principal con métricas AQI
- Indicador circular de AQI (gauge)
- Gráfico de barras horario
- Sección de tips por categoría
- Información meteorológica
- Sección "More Info" con estadísticas anuales

## 🎨 Componentes Visuales

### Header y Navegación
```swift
- Tabs: DAY / MONTH
- Botón de regreso (chevron.left)
- Fondo azul oscuro (#0D1B3E)
```

### Day Selector
```swift
- Scroll horizontal con 5 días
- Indicador de color (verde/amarillo)
- Formato: "THU 02", "FRI 03", etc.
- Día seleccionado destacado
```

### Main AQI Card
```swift
- Location: TLALPAN
- Quality Level: High
- Métricas: AQI, NO2, PM2.5, PM10, O3
- Circular gauge con gradiente
- Fondo: #1E3A5F
```

### Hourly Bar Chart
```swift
- 12 barras representando horas del día
- Colores basados en nivel de AQI
- Línea indicadora de hora actual
- Labels de tiempo (0:00, 2:00, 4:00, etc.)
- Altura: 200pt
```

### Tips by Category
```swift
4 categorías con iconos:
- Running (figure.run) - Verde
- Cycling (bicycle) - Azul
- Health (heart.fill) - Rojo
- Indoor (house.fill) - Morado
```

### Weather Section
```swift
4 métricas horizontales:
- Temperatura (cloud.rain.fill)
- Viento (wind)
- UV Index (umbrella.fill)
- Humedad (drop.fill)
```

### More Info Section
```swift
3 estadísticas:
- Best day of the year: 37 AQI
- Annual average: 63 AQI
- Worst peak of the year: 99 AQI
```

## 🔄 Navegación Implementada

### Desde AQI Home View:

**Opción 1: Botón de Acceso Rápido** (Nuevo)
- Ubicado entre AQI Card y PM Indicators
- Card con gradiente azul
- Texto: "5-Day Forecast"
- Descripción: "View detailed daily air quality predictions"
- Chevron derecho

**Opción 2: Tab "Daily" en Weather Forecast**
- En la sección inferior de AQI Home
- Card clickeable con icono de calendario
- Texto: "View Daily Forecast"
- Descripción: "Tap to see 5-day forecast"

## 📱 Flujo de Usuario

```
AQI Home View
    │
    ├─→ [Botón "5-Day Forecast"]
    │       │
    │       └─→ Daily Forecast View
    │
    └─→ [Tab "Daily" en Weather Forecast]
            │
            └─→ Daily Forecast View
```

## 🎯 Características Destacadas

### 1. **Gráfico de Barras Animado**
- Colores dinámicos basados en AQI
- Scroll suave
- Indicador de tiempo actual
- Gradientes de nivel de calidad

### 2. **Circular AQI Gauge**
- Arco de progreso de 0-150
- Gradiente multicolor (verde → amarillo → naranja → rojo)
- Punto indicador amarillo
- Valor central grande

### 3. **Day Selector Interactivo**
- Selección de día con animación
- Actualiza automáticamente todas las métricas
- Indicador de calidad con punto de color

### 4. **Responsive Design**
- Scroll vertical para todo el contenido
- Componentes adaptables
- Material design con glassmorphism
- Sombras y bordes sutiles

## 📊 Datos de Muestra

### Días de la Semana:
```swift
THU 02: AQI 45 (Good)
FRI 03: AQI 53 (Moderate)
SAT 04: AQI 53 (Moderate) ← Seleccionado por defecto
SUN 05: AQI 37 (Good)
MON 06: AQI 42 (Good)
```

### Gráfico Horario (12 puntos):
```swift
0:00 → 35 AQI
2:00 → 40 AQI
4:00 → 45 AQI
6:00 → 50 AQI
8:00 → 55 AQI
10:00 → 60 AQI
12:00 → 58 AQI
14:00 → 55 AQI
16:00 → 52 AQI
18:00 → 48 AQI (Hora actual)
20:00 → 45 AQI
22:00 → 40 AQI
```

## 🎨 Paleta de Colores

```swift
Background:
  - #0D1B3E (Azul oscuro superior)
  - #1A2847 (Azul medio)
  - #0D1B3E (Azul oscuro inferior)

Cards: #1E3A5F (Azul medio)

Borders: White 20% opacity

Shadows: Black 30% opacity

Text: White (varios niveles de opacidad)
```

## 🚀 Próximas Mejoras Sugeridas

1. **Tab "MONTH"**: Implementar vista mensual
2. **Detalles de Tips**: Modal con consejos completos al tocar categoría
3. **Gráficos Avanzados**: Agregar gráficos de línea para tendencias
4. **Comparación**: Comparar datos entre días
5. **Exportar**: Compartir pronóstico como imagen
6. **Notificaciones**: Alertas para días con mala calidad del aire
7. **Favoritos**: Guardar ubicaciones favoritas
8. **Histórico**: Ver datos históricos del mismo período

## 🔧 Integración con API

Para conectar con API real, modificar:

```swift
// En DailyForecast.swift
static let sampleWeek: [DailyForecast] = [...]

// Reemplazar con:
static func fetchWeekForecast(location: String) async throws -> [DailyForecast] {
    // Llamada a API (OpenAQ, IQAir, etc.)
}
```

## 📱 Compatibilidad

- ✅ iOS 17+
- ✅ SwiftUI
- ✅ Dark mode ready
- ✅ Landscape compatible
- ✅ iPad optimizado (con adaptaciones)

## 🎬 Animaciones Incluidas

- Spring animation en selección de día
- Fade in/out en cambio de tabs
- Smooth scroll en gráficos
- Pulse en indicador de tiempo

---

✨ **Resultado**: Vista completa de pronóstico diario con todas las secciones de las imágenes de referencia, completamente funcional y navegable desde la vista principal.
