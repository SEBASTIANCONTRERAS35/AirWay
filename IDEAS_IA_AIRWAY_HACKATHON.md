# IDEAS DE INTELIGENCIA ARTIFICIAL PARA AIRWAY
## Swift Changemakers Hackathon 2026 — Human-Centered AI
### Documento de Lluvia de Ideas Completa

> **Proyecto**: AirWay — Sistema de Navegacion Consciente de Calidad del Aire
> **Hackathon**: Swift Changemakers 2026, iOS Development Lab, UNAM
> **Tema**: Human-Centered AI (HCAI)
> **Fechas**: 20 y 21 de Abril de 2026
> **Equipo**: 3 personas (2 devs + 1 disenador)
> **Stack**: Swift/SwiftUI + Frameworks Apple + APIs publicas gratuitas

---

## TABLA DE CONTENIDOS

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Principios HCAI y Como AirWay los Cumple](#principios-hcai)
3. [CATEGORIA 1: IA Conversacional On-Device](#categoria-1-ia-conversacional-on-device)
4. [CATEGORIA 2: Vision por Computadora](#categoria-2-vision-por-computadora)
5. [CATEGORIA 3: Prediccion con ML On-Device](#categoria-3-prediccion-con-ml-on-device)
6. [CATEGORIA 4: UX de IA Centrada en el Humano](#categoria-4-ux-de-ia-centrada-en-el-humano)
7. [CATEGORIA 5: Visualizacion Emocional e Impacto](#categoria-5-visualizacion-emocional-e-impacto)
8. [CATEGORIA 6: Datos e IA Avanzada](#categoria-6-datos-e-ia-avanzada)
9. [CATEGORIA 7: Apple Watch](#categoria-7-apple-watch)
10. [CATEGORIA 8: AirPods](#categoria-8-airpods)
11. [CATEGORIA 9: Orquestacion Multi-Dispositivo](#categoria-9-orquestacion-multi-dispositivo)
12. [CATEGORIA 10: Ideas Moonshot / Experimentales](#categoria-10-ideas-moonshot-experimentales)
13. [APIs Gratuitas Confirmadas](#apis-gratuitas-confirmadas)
14. [Datos Cientificos Clave para el Pitch](#datos-cientificos-clave)
15. [Ranking Final: Top Ideas para el Hackathon](#ranking-final)
16. [Script de Demo Sugerido (10 min)](#script-de-demo)
17. [Fuentes y Referencias](#fuentes-y-referencias)

---

## RESUMEN EJECUTIVO

Este documento contiene **40+ ideas de inteligencia artificial** para integrar en AirWay, organizadas en 10 categorias. Cada idea incluye:

- Que es y como funciona
- Por que es relevante para HCAI
- Viabilidad para un hackathon de 2 dias
- Codigo de ejemplo cuando aplica
- Datos cientificos que la respaldan

Las ideas van desde implementaciones practicas (3-4 horas) hasta moonshots experimentales, permitiendo al equipo elegir la combinacion optima segun tiempo disponible y dispositivos de demo.

---

## PRINCIPIOS HCAI

AirWay se alinea naturalmente con los 5 principios de Human-Centered AI:

| Principio HCAI | Como AirWay lo Cumple |
|----------------|----------------------|
| **La IA apoya al humano** | No decide por ti, te da informacion para que TU decidas que ruta tomar |
| **Transparencia** | AR muestra POR QUE la IA recomienda una ruta (particulas visibles, AQI en mapa) |
| **Control humano** | El usuario elige entre 3 rutas (mas limpia, mas rapida, mas segura) |
| **Equidad y etica** | Democratiza datos de NASA que normalmente son inaccesibles para el publico |
| **Usabilidad** | Convierte datos cientificos abstractos en algo visual e intuitivo |

**Framework academico**: Ben Shneiderman (U. Maryland) establece que HCAI NO es un trade-off entre control humano y automatizacion — puedes tener AMBOS simultaneamente. AirWay implementa esto: alta automatizacion (ML, data fusion, routing) + alto control humano (el usuario siempre decide).

---

## CATEGORIA 1: IA CONVERSACIONAL ON-DEVICE

### IDEA 1: "AirWay Copilot" — Asistente conversacional on-device

**Que es**: Usar el Apple Foundation Models Framework (iOS 26) para que el usuario pregunte en lenguaje natural sobre calidad del aire.

**Preguntas que puede responder**:
- "Es seguro que mi hija juegue afuera esta tarde?"
- "Cuando es el mejor momento para correr hoy?"
- "Por que el aire esta peor hoy que ayer?"
- "Planifica mi ruta al trabajo evitando contaminacion"

**Implementacion**:
```swift
import FoundationModels

@Generable
struct AirQualityAdvice {
    var recommendation: String
    @Guide(.anyOf(["Seguro", "Precaucion", "Riesgo", "Peligro"]))
    var riskLevel: String
    var bestTimeWindow: String
}

let session = LanguageModelSession()
let prompt = """
AQI actual: \(currentAQI). PM2.5: \(pm25).
Perfil: asmatico, 35 anos.
Viento: \(windSpeed) desde \(windDirection).
Pronostico: AQI bajara a \(forecastAQI) para las 4pm.
Pregunta: \(userQuestion)
"""
let response = try await session.respond(to: prompt, generating: AirQualityAdvice.self)
```

**Detalles tecnicos**:
| Aspecto | Detalle |
|---------|---------|
| Costo | $0 — corre 100% en el dispositivo |
| Latencia | ~30 tokens/seg en iPhone 15 Pro |
| Modelo | ~3B parametros (mismo que Apple Intelligence) |
| Privacidad | Datos nunca salen del telefono |
| HCAI | El usuario pregunta y decide, la IA informa |
| Viabilidad hack | Alta — son ~20 lineas de Swift |
| Requisito | iOS 26, dispositivo con Apple Intelligence (A17 Pro / M1+) |

**Alineacion HCAI**: El usuario mantiene el control total — pregunta cuando quiere, la IA solo informa, nunca impone. Transparencia total sobre las fuentes de datos.

---

### IDEA 2: Explicaciones con LLM de por que eligio cada ruta

**Que es**: En vez de solo mostrar 3 rutas con numeros, el LLM on-device genera explicaciones en lenguaje natural.

**Ejemplo de output**:
> "Evite Eje Central porque el PM2.5 esta 3x mas alto por congestion vehicular. Elegi Reforma porque la cobertura arborea reduce particulas un 40%. Datos de: OpenAQ Estacion #2847, actualizado hace 5 min."

**Implementacion**:
```swift
@Generable
struct RouteExplanation {
    @Guide(description: "Explicacion de por que se eligio esta ruta")
    var reasoning: String
    @Guide(description: "Calle o zona que se evito y por que")
    var avoidedArea: String
    @Guide(description: "Beneficio cuantificado de esta ruta")
    var benefit: String
}
```

**Alineacion HCAI**: Transparencia maxima — la IA explica cada decision, no es una caja negra.

---

## CATEGORIA 2: VISION POR COMPUTADORA

### IDEA 3: "SnapAir" — Apunta tu camara, mide la calidad del aire

**Que es**: Papers de 2024-2025 demuestran que la camara de un smartphone puede estimar PM2.5 analizando la neblina con 87% de precision.

**Como funciona**: El modelo CoreML extrae features de la imagen:
- **Dark channel prior** — la intensidad minima revela el grosor de la neblina
- **Contraste local** — la contaminacion reduce el contraste proporcionalmente a la distancia
- **Atenuacion de color** — el aire contaminado desatura escenas hacia gris-azul
- **Decaimiento de saturacion** — la neblina reduce la saturacion de colores

**Implementacion**:
```swift
import Vision
import CoreML

// 1. Cargar modelo entrenado con dataset PM25Vision
let model = try VNCoreMLModel(for: AirQualityEstimator().model)

// 2. Crear request de clasificacion
let request = VNCoreMLRequest(model: model) { request, error in
    guard let results = request.results as? [VNClassificationObservation] else { return }
    let topResult = results.first!
    // topResult.identifier = "Unhealthy"
    // topResult.confidence = 0.87
}

// 3. Procesar frame de camara
let handler = VNImageRequestHandler(cvPixelBuffer: frame)
try handler.perform([request])
```

**Detalles tecnicos**:
| Aspecto | Detalle |
|---------|---------|
| Framework | Vision + VNCoreMLRequest |
| Dataset | PM25Vision benchmark (2025) |
| Tamano modelo | ~30MB con cuantizacion INT8 |
| FPS | 15+ en tiempo real |
| Precision | 87% en dia, menor de noche |
| HCAI | Empodera al ciudadano a ser su propio sensor |

**Alineacion HCAI**: Democratiza la medicion de calidad del aire — cada iPhone se convierte en un sensor. El usuario no depende de estaciones gubernamentales.

---

### IDEA 4: Deteccion de humo/smog con Vision Framework

**Que es**: Entrenar un clasificador binario (humo/no-humo) con CreateML.

**Implementacion**:
1. Usar dataset "Wildfire Smoke Detection" de Kaggle
2. Arrastrar imagenes a CreateML > Image Classifier
3. Exportar `.mlmodel`
4. Integrar con camara en tiempo real

**Alerta generada**:
> "Humo detectado en tu zona. AQI probablemente mas alto que el reportado por sensores. Considera cambiar de ruta."

**Viabilidad**: Alta — CreateML GUI hace todo el entrenamiento sin codigo ML.

---

## CATEGORIA 3: PREDICCION CON ML ON-DEVICE

### IDEA 5: Prediccion AQI con CreateML Tabular Regressor

**Que es**: Entrenar un modelo de prediccion de calidad del aire en la GUI de Xcode, sin escribir codigo ML.

**Proceso**:
1. Descargar datos historicos de CDMX (OpenAQ)
2. Crear CSV con columnas: `hora, dia_semana, temperatura, humedad, viento, pm25_actual, pm25_1h_antes, pm25_3h_antes, target_pm25`
3. Abrir CreateML en Xcode > Tabular Regressor > arrastrar CSV
4. CreateML auto-selecciona mejor algoritmo (Boosted Trees para estos datos)
5. Exportar `.mlmodel` > agregar al proyecto Xcode

**Uso en Swift**:
```swift
let prediction = try model.prediction(
    hour: 17,
    day_of_week: 2,
    temperature: 28.5,
    humidity: 45.0,
    wind_speed: 12.0,
    pm25_current: 85.0,
    pm25_1h_ago: 78.0,
    pm25_3h_ago: 62.0
)
// prediction.target_pm25 → 102.3
```

**Detalles tecnicos**:
| Aspecto | Detalle |
|---------|---------|
| Precision tipica | 85-92% para prediccion a 1 hora |
| Inferencia | ~0.03 segundos on-device |
| Algoritmos | Linear, Decision Tree, Boosted Trees, Random Forest |
| HCAI | Muestra confianza: "AQI 102 (confianza: 87%)" |
| Viabilidad hack | Alta — CreateML GUI hace todo |

**Alineacion HCAI**: La prediccion muestra su nivel de confianza y las fuentes de datos, permitiendo al usuario evaluar si confiar en ella.

---

### IDEA 6: Detector de anomalias para eventos de contaminacion

**Que es**: Un sistema que detecta patrones anormales de contaminacion antes de que aparezcan en reportes oficiales.

**Tipos de anomalias**:
| Tipo | Descripcion | Accion |
|------|-------------|--------|
| Spike subito | AQI sube 50+ puntos en 30 min | Posible incendio/accidente industrial |
| Anomalia espacial | Una zona diverge de areas circundantes | Fuente local de contaminacion |
| Anomalia temporal | AQI no sigue patron diario esperado | Algo inusual ocurriendo |
| Rotura de tendencia | Degradacion del baseline de un barrio | Alerta de largo plazo |

**Implementacion**: Autoencoder o Isolation Forest en CoreML.
- Input: perfil de AQI de 24 horas
- Output: error de reconstruccion > umbral = anomalia
- Tamano modelo: <1MB, inferencia: <10ms

**Flujo de alerta**:
```
Anomalia detectada → clasificar tipo → generar alerta via Foundation Models →
notificacion: "Calidad del aire cerca del centro ha aumentado inesperadamente.
Posible evento de emision industrial. Considera rutas alternativas."
```

**Alineacion HCAI**: Alerta temprana que da tiempo al humano de decidir, no impone acciones.

---

## CATEGORIA 4: UX DE IA CENTRADA EN EL HUMANO

### IDEA 7: "Panel de Transparencia" — IA explicable visualmente

**Que es**: Cuando AirWay sugiere una ruta, muestra un desglose visual de POR QUE.

**Diseno**:
```
+---------------------------------------------+
|  Por que esta ruta?                          |
|                                              |
|  * Evito Insurgentes (PM2.5: 142)            |
|  * Eligio Reforma (PM2.5: 48)               |
|  * Datos: OpenAQ Estacion #2847             |
|  * Actualizado: hace 5 min                   |
|  * Confianza: ========-- 82%                 |
|                                              |
|  Factores:                                   |
|  PM2.5 [========] alto impacto               |
|  Trafico [=====] medio                       |
|  Viento [==] bajo                            |
+---------------------------------------------+
```

**Patron UX**: "Explainable Rationale" del catalogo Shape of AI — mostrar contribucion de cada factor a la decision.

**Alineacion HCAI**: Principio #2 (Transparencia) en su forma mas pura. La IA no es caja negra.

---

### IDEA 8: "Breathing Persona" — La IA se adapta a TI

**Que es**: En el primer uso, 4 preguntas crean un perfil que ajusta TODA la app.

**Preguntas**:
1. Tienes asma u otra condicion respiratoria?
2. Estas embarazada?
3. Eres corredor/a o ciclista?
4. Cuidas ninos pequenos?

**Modelo de datos**:
```swift
struct BreathingPersona {
    let sensitivityMultiplier: Double  // 1.0 normal, 1.5 asma, 2.0 embarazo
    let alertThreshold: Int            // 100 normal, 75 asma, 50 embarazo
    let exerciseWindow: Bool           // activa recomendaciones de ejercicio
    let childMode: Bool                // alertas para ninos
}

// Uso: Un asmatico recibe alerta a AQI 75, no 100
let adjustedThreshold = baseThreshold * persona.sensitivityMultiplier
```

**Transformacion visual**: Cuando el perfil cambia, TODA la app se transforma:
- Asmatico: colores mas calidos/protectores aparecen antes
- Embarazada: umbrales mas estrictos, recomendaciones especificas
- Atleta: ventanas de ejercicio optimizadas

**Alineacion HCAI**: La IA se adapta al humano, no al reves. Personalizacion real.

---

### IDEA 9: "Override Humano" — La IA obedece al usuario

**Que es**: Si la IA sugiere evitar una calle, el usuario puede tocar "Yo se mejor" y la IA acepta.

**Flujo**:
1. IA sugiere ruta limpia
2. Usuario toca "Override: quiero la ruta rapida"
3. IA responde: "Entendido. Tu exposicion estimada a PM2.5 aumentara 35%. Monitoreare y te alertare si las condiciones empeoran."
4. IA registra el override para el historial de exposicion

**Por que es el MOMENTO HCAI de la demo**: La maquina se somete al juicio humano mientras informa transparentemente las consecuencias. Esto es exactamente lo que los jueces buscan.

**Alineacion HCAI**: Principio #3 (Control humano) en accion directa. La IA es herramienta, no autoridad.

---

### IDEA 10: "Espectro de Autonomia" — El usuario elige cuanta IA quiere

**Que es**: Un toggle con 3 niveles basado en el framework de Shneiderman.

| Modo | Comportamiento |
|------|---------------|
| **Solo datos** | Muestra AQI, sin recomendaciones |
| **Sugerir** | Recomienda rutas, el usuario elige (default) |
| **Auto-proteger** | Re-rutea automaticamente si AQI sube (requiere opt-in) |

**Implementacion**: Un `@AppStorage` que inyecta el modo en todo el flujo de routing y notificaciones.

**Alineacion HCAI**: Demuestra que automatizacion alta + control humano alto pueden coexistir. Principio central de Shneiderman.

---

### IDEA 11: "Medidor de Confianza" — Que tan segura esta la IA?

**Que es**: Cada prediccion muestra su nivel de certeza visual.

**Niveles**:
| Nivel | Indicador | Criterio |
|-------|-----------|----------|
| Alta | Anillo verde solido | 3+ sensores cercanos + satelite confirman, datos < 15 min |
| Media | Anillo amarillo punteado | Sensor mas cercano a 2km, interpolacion satelital |
| Baja | Anillo rojo discontinuo | Sin sensores, estimacion basada solo en modelo |

**Ejemplo en UI**:
> "AQI: 85 (Confianza: Alta — basado en 3 sensores y datos satelitales)"
> vs
> "AQI: 120 (Confianza: Baja — sensor mas cercano a 2km). Considera verificar en 15 min."

**Calculo de confianza**:
```swift
func calculateConfidence(sources: [DataSource]) -> ConfidenceLevel {
    let sensorCount = sources.filter { $0.type == .ground }.count
    let dataAge = sources.map { $0.age }.min() ?? .infinity
    let hasSatellite = sources.contains { $0.type == .satellite }
    
    if sensorCount >= 2 && dataAge < 900 && hasSatellite { return .high }
    if sensorCount >= 1 || (hasSatellite && dataAge < 1800) { return .medium }
    return .low
}
```

**Alineacion HCAI**: Mostrar incertidumbre es lo que separa IA responsable de IA sobreconfiada.

---

### IDEA 12: "Maquina del Tiempo del Aire" — Slider predictivo

**Que es**: Un slider que permite deslizar las proximas 8 horas y ver como cambiara el mapa.

**Experiencia**:
- Los circulos de color del grid se animan suavemente
- La IA narra: "A las 3pm, el trafico aumentara PM2.5 un 60% en Insurgentes. Recomiendo salir antes de las 2pm."
- El usuario "conduce" las predicciones con el dedo

**Implementacion**:
```swift
struct TimeSliderView: View {
    @State private var forecastHour: Double = 0
    
    var body: some View {
        VStack {
            Slider(value: $forecastHour, in: 0...8, step: 0.5)
            Text("Pronostico: \(formattedTime(hoursAhead: forecastHour))")
            
            MapView(aqiData: interpolatedData(at: forecastHour))
                .animation(.easeInOut, value: forecastHour)
        }
    }
}
```

**Alineacion HCAI**: El usuario literalmente controla las predicciones de la IA. Agencia total.

---

### IDEA 13: "Etiquetado Medido vs. Predicho"

**Que es**: En TODAS las vistas, distinguir visualmente datos observados de predicciones de IA.

**Diseno**:
- **Datos medidos**: Linea solida, marcadores rellenos, sin brillo
- **Predicciones IA**: Linea punteada, marcadores huecos, efecto glow sutil
- Etiqueta explicita: "Medido" vs "Prediccion IA"

**Alineacion HCAI**: El usuario siempre sabe que es un hecho observado vs una inferencia. Transparencia fundamental.

---

### IDEA 14: "Feedback Loop" — El usuario mejora la IA

**Que es**: Despues de cada ruta, preguntar: "Fue precisa esta evaluacion de calidad del aire?"

**Implementacion**: Thumbs up/down almacenado localmente. Demuestra colaboracion continua humano-IA.

**Alineacion HCAI**: La IA no es estatica — el humano la mejora con su retroalimentacion.

---

## CATEGORIA 5: VISUALIZACION EMOCIONAL E IMPACTO

### IDEA 15: "Pulmones Digitales" — Tu gemelo digital respirando

**Que es**: Una animacion de pulmones estilizados que respira segun la calidad del aire.

**Comportamiento**:
| AQI | Pulmones | Respiracion |
|-----|----------|-------------|
| 0-50 | Claros, color rosado | Suave, ritmica |
| 51-100 | Leve opacidad | Normal |
| 101-150 | Particulas visibles acumulandose | Laboriosa |
| 150+ | Oscuros, particulas densas | Irregular, pesada |

**Implementacion**: SwiftUI `Canvas` + `TimelineView`, parametros de animacion alimentados por AQI real.

**Impacto emocional**: "Esto es lo que le pasa a tus pulmones ahora mismo." Genera cambio de comportamiento real.

---

### IDEA 16: "Equivalencia en Cigarrillos"

**Que es**: Traducir datos abstractos de AQI a algo universalmente entendido.

**Formula**: 1 cigarrillo ~ 22 ug PM2.5 inhalados profundamente.

**Ejemplos**:
- AQI 135 por 8 horas caminando → "Hoy respiraste el equivalente a 6 cigarrillos en particulas"
- Ruta limpia vs ruta rapida → "Esta ruta te ahorra 2 cigarrillos de exposicion"

**Impacto**: La investigacion muestra que esta metrica genera cambio de comportamiento real porque todos entienden lo que significa un cigarrillo.

---

### IDEA 17: "Adaptacion Emocional del Color"

**Que es**: Toda la UI cambia sutilmente su temperatura de color segun la calidad del aire.

| AQI | Atmosfera Visual |
|-----|-----------------|
| 0-50 | Tonos frios, azul-verde, calma |
| 51-100 | Neutro, amarillo suave |
| 101-150 | Tonos calidos ambar, urgencia sutil |
| 150+ | Rojo profundo, sensacion de alerta |

**Implementacion**:
```swift
struct AirQualityTheme: EnvironmentKey {
    static func color(for aqi: Int) -> Color {
        switch aqi {
        case 0...50: return .mint
        case 51...100: return .yellow
        case 101...150: return .orange
        default: return .red
        }
    }
    
    static func gradient(for aqi: Int) -> LinearGradient {
        // Gradiente que se aplica como fondo de toda la app
        // Cambia suavemente con animacion
    }
}
```

**Alineacion HCAI**: Diseno emocional (Don Norman) — la app comunica a traves de sentimiento, no solo numeros. Apple Liquid Glass enfatiza responsividad ambiental.

---

## CATEGORIA 6: DATOS E IA AVANZADA

### IDEA 18: Fusion de datos inteligente con atencion

**Que es**: Reemplazar la formula estatica `fusedAQI = satellite * 0.3 + ground * 0.7` con pesos dinamicos que se adaptan al contexto.

**Pesos contextuales**:
| Contexto | Comportamiento |
|----------|---------------|
| Cerca de sensor OpenAQ | Peso terrestre sube a 0.9 |
| Sensor offline | Peso satelital sube automaticamente |
| Viento fuerte | Modelo de dispersion gana peso |
| Camara disponible | Estimacion visual complementa |
| Patron historico coincide | Modelo temporal gana peso |

**Interpretabilidad**: Los pesos de atencion SON la explicacion:
> "Esta prediccion es 60% sensor cercano, 30% satelite, 10% modelo meteorologico"

**Alineacion HCAI**: Transparencia tecnica — el usuario ve exactamente que datos influyen en cada prediccion.

---

### IDEA 19: "BreathScore" — Exposicion personalizada con Apple Watch

**Que es**: Combinar datos biometricos del Watch con datos de contaminacion para calcular exposicion REAL.

**Formula**:
```
Exposicion Personal = Concentracion (AirWay API)
                     x Tasa Respiratoria (Apple Watch)
                     x Nivel de Actividad (HealthKit)
                     x Duracion (CoreLocation)
                     x Factor Vulnerabilidad (perfil usuario)
```

**Dato clave**: Un corredor respirando 60L/min inhala 6x mas contaminantes que alguien caminando a 10L/min. Mismo AQI, exposicion vastamente diferente.

**Datos de HealthKit disponibles**:
- `respiratoryRate` — frecuencia respiratoria
- `heartRate` — proxy de esfuerzo
- `oxygenSaturation` — impacto en salud real
- `activeEnergyBurned` — nivel de actividad

---

### IDEA 20: "CommunityShield" — Reportes ciudadanos + IA

**Que es**: Los usuarios reportan observaciones subjetivas que la IA cruza con datos oficiales.

**Reportes con un tap**:
- "Estoy tosiendo aqui"
- "El aire huele mal"
- "Veo humo/neblina"
- "Aire se siente limpio"

**La IA cruza con datos**:
> "12 usuarios reportaron mala calidad cerca del Zocalo. Confirmado por sensor: PM2.5 = 85."

**Alineacion HCAI**: IA + ciencia ciudadana — humanos validan la IA y la IA valida a los humanos. Colaboracion bidireccional.

---

### IDEA 21: Red Neuronal de Grafos (GNN) para interpolacion espacial

**Que es**: Los sensores OpenAQ son escasos. Una GNN modela la ciudad como un grafo para estimar AQI en cada esquina.

**Arquitectura**:
- **Nodos** = intersecciones, parques, zonas industriales, ubicaciones de sensores
- **Aristas** = calles, ponderadas por volumen de trafico y distancia
- **Features** = tipo de uso de suelo, elevacion, densidad de edificios, proximidad a autopistas
- **Tarea** = Predecir AQI en cada nodo no monitoreado

**Resultado**: Convierte 5 lecturas de sensores en un mapa de contaminacion de 500 nodos.

**Tamano modelo**: ~2MB, inferencia naturalmente ligera.

---

### IDEA 22: Aprendizaje federado para inteligencia colectiva privada

**Que es**: Cada telefono entrena un modelo local con sus rutas/exposicion. Solo los pesos del modelo (no datos personales) se comparten.

**Arquitectura**:
```
Telefono A: entrena modelo local → pesos
Telefono B: entrena modelo local → pesos
                |                    |
                v                    v
        [Solo pesos del modelo enviados]
                |
                v
        [Agregacion FedAvg]
                |
                v
        [Modelo global mejorado → todos los telefonos]
```

**Lo que aprende cada modelo local**:
- Factores de correccion para su vecindario especifico
- Patrones temporales del area (hora pico de contaminacion)
- Feedback de calidad de ruta

**Alineacion HCAI**: Maximo nivel de privacidad — datos nunca salen del dispositivo. La comunidad mejora las predicciones para todos.

---

## CATEGORIA 7: APPLE WATCH

### Datos disponibles via HealthKit

| Sensor | Dato | Identificador HealthKit | Correlacion con contaminacion |
|--------|------|------------------------|-------------------------------|
| SpO2 | Oxigeno en sangre | `.oxygenSaturation` | -0.19% a -0.40% por cada 17 ug/m3 PM2.5 |
| HRV | Variabilidad cardiaca | `.heartRateVariabilitySDNN` | -2% a -6% SDNN por IQR de PM2.5 |
| HR | Frecuencia cardiaca | `.heartRate` / `.restingHeartRate` | +3.5 bpm por unidad de PM2.5 |
| Respiracion | Tasa respiratoria | `.respiratoryRate` | Corredores inhalan 6x mas contaminantes |
| VO2 Max | Capacidad aerobica | `.vo2Max` | Declive longitudinal por exposicion cronica |
| Temperatura | Temp. muneca nocturna | `.appleSleepingWristTemperature` | Inflamacion por PM2.5 = temp elevada |
| Sueno | Fases de sueno | `.sleepAnalysis` | PM2.5 reduce sueno profundo 3.2% |
| ECG | Electrocardiograma | `HKElectrocardiogramQuery` | PM2.5 aumenta riesgo AFib 38% |
| Ruido | dB ambiental | `.environmentalAudioExposure` | Co-ocurre con contaminacion por trafico |

---

### IDEA 23: "PPI Score" — Indice de Impacto Personal de Contaminacion

**Que es**: Un score en tiempo real que cuantifica como TU CUERPO esta reaccionando a la contaminacion AHORA MISMO.

**Algoritmo**:
```
PPI = w1 x DeltaSpO2 + w2 x DeltaHRV + w3 x DeltaHR + w4 x DeltaResp
```

Donde cada Delta es la desviacion de tu baseline personal (promedio 7 dias a la misma hora).

| Componente | Peso | Razon |
|------------|------|-------|
| SpO2 deviation | 0.35 | Indicador respiratorio mas directo |
| HRV deviation | 0.30 | Proxy del sistema nervioso autonomo |
| HR elevation | 0.20 | Respuesta de estres agudo |
| Respiratory rate | 0.15 | Senal de dificultad respiratoria |

**Visualizacion en Watch**: Numero simple (0-100) con color.
- Verde = tu cuerpo no muestra efectos
- Amarillo = efectos leves detectados
- Rojo = estres fisiologico significativo

**Para los jueces**: "No solo medimos la contaminacion del aire — medimos como TU cuerpo responde a ella."

---

### IDEA 24: "Presupuesto de Exposicion" — Activity Rings para contaminacion

**Que es**: Como los anillos de actividad de Apple, pero para contaminacion inhalada.

**Formula de dosis**:
```
Dosis Inhalada = Concentracion x Ventilacion x Tiempo x Factor_Deposito

Ventilacion por actividad:
- Sedentario:  6 L/min
- Caminando:  20 L/min
- Corriendo:  60 L/min
- Ciclismo:   40 L/min
```

**3 anillos**:
| Anillo | Que mide | Meta diaria |
|--------|----------|-------------|
| Rojo: Exposicion | ug PM2.5 inhalados hoy | Bajo limite OMS |
| Verde: Aire Limpio | Minutos en AQI < 50 | 120 min/dia |
| Azul: Rutas Limpias | Rutas tomadas via AirWay | 3 rutas/dia |

**Dato clave**: Un corredor que corre 30 min en AQI moderado gasta 10x mas presupuesto que alguien caminando 60 min. Mismo aire, exposicion radicalmente diferente.

---

### IDEA 25: "Alerta Convergente" — IA que fusiona cuerpo + ambiente

**Que es**: La IA no solo mira el aire O tu cuerpo — mira AMBOS juntos.

**Reglas inteligentes**:
```
SI (AQI > 100) Y (HRV_actual < baseline - 15%) ENTONCES
    → "Tu sistema nervioso YA esta estresado Y el aire es malo.
       Riesgo compuesto elevado. Busca aire limpio."

SI (AQI > 80) Y (SpO2 < 95%) ENTONCES
    → "Tu oxigeno en sangre esta bajo en esta zona.
       Recomendamos ir al interior."

SI (ejercicio_detectado) Y (AQI > 75) Y (HR > zona_3) ENTONCES
    → "Estas inhalando 6x mas contaminantes por el ejercicio intenso.
       Reduce la intensidad o cambia de zona."
```

**Modelo CoreML**: Classification model con inputs de AQI, HR, HRV, SpO2, actividad, hora, perfil de salud. Output: score de riesgo + recomendacion.

---

### IDEA 26: "Haptics como Sexto Sentido"

**Que es**: El Watch vibra de formas distintas segun la calidad del aire.

| AQI | Patron Haptico | Sensacion |
|-----|----------------|-----------|
| 0-50 (Bueno) | Nada | Silencio = aire limpio |
| 51-100 (Moderado) | Pulse suave cada 30s | "Estas bien, pero atento" |
| 101-150 (Insalubre) | `DirectionUp` cada 15s | "Esta subiendo" |
| 150+ (Peligroso) | `Failure` triple-tap | "Sal de aqui" |
| Transicion limpio a sucio | Intensidad gradual | "Estas entrando en zona mala" |

**9 tipos de haptic de WatchKit**: Notification, DirectionUp, DirectionDown, Success, Failure, Retry, Start, Stop, Click — un vocabulario tactil completo.

**Resultado**: Despues de unos dias, el usuario sabe la calidad del aire sin mirar ninguna pantalla.

---

### IDEA 27: "Maquina del Tiempo con Digital Crown"

**Que es**: Girar la Digital Crown para viajar en el tiempo por tu exposicion.

- **Giro derecha** → futuro: forecast de AQI proximas 8 horas
- **Giro izquierda** → pasado: ruta de hoy con segmentos coloreados
- **Tap en cualquier punto**: detalles completos

Ejemplo: "Martes 8:15 AM — Reforma e Insurgentes — AQI 142 — Corriendo (HR 156) — Dosis: 85 ug PM2.5"

---

### IDEA 28: "Rutas que se adaptan a TU cuerpo"

**Que es**: El RouteOptimizer incluye el estado de salud actual del usuario.

```swift
struct HealthAwareRouteScore {
    let baseScore: Double          // AQI + safety + efficiency
    let healthMultiplier: Double   // 1.0 normal, 1.5 si HRV bajo, 2.0 si SpO2 < 95%
    
    var finalScore: Double {
        baseScore * healthMultiplier
    }
}
```

Si tu HRV ya esta bajo, la IA automaticamente prioriza MAS la ruta limpia. Tu cuerpo ya esta comprometido — necesitas proteccion extra.

---

### IDEA 29: Complicacion "Breathability" en vivo

**Tipos de complicacion**:
| Tipo | Que muestra |
|------|-------------|
| Circular | Anillo que se llena segun exposicion acumulada |
| Esquina | AQI + flecha de tendencia (subiendo/bajando/estable) |
| Rectangular | Sparkline de las ultimas 6h + forecast |

**Diferenciador**: La complicacion nativa de Apple solo muestra datos city-wide de The Weather Channel. AirWay muestra datos personalizados, hiperlocales, y ajustados al perfil de salud.

---

### IDEA 30: "Coach Respiratorio Adaptativo" en el Watch

| AQI | Guia de respiracion via haptics |
|-----|------|
| < 50 | Respiraciones profundas, lentas — "Maximiza el aire limpio" |
| 50-100 | Ritmo normal, profundidad media |
| 100-150 | Respiraciones cortas, superficiales — "Respira suavemente" |
| > 150 | "Respira por la nariz, minimiza inhalacion. Busca interior." |

**Dato cientifico**: La ventilacion minuto (frecuencia x profundidad) es el multiplicador clave de dosis.

---

## CATEGORIA 8: AIRPODS

### Sensores y APIs disponibles

| API/Framework | iOS | Modelo AirPods | Datos |
|---|---|---|---|
| CMHeadphoneMotionManager | 14+ | Pro, Pro 2, Pro 3, Max | Actitud, rotacion, aceleracion |
| SoundAnalysis | 15+ | N/A (mic iPhone) | Clasificacion de sonidos |
| AVAudioEngine | 8+ | N/A (mic iPhone) | Niveles de decibeles |
| HealthKit audio exposure | 14+ | Pro 2, Pro 3 | dBA automaticos |
| Heart rate (AirPods Pro 3) | 19 | Pro 3 | BPM |
| Temperature (AirPods Pro 3) | 19 | Pro 3 | Grados C |
| CoreHaptics | 13+ | N/A (iPhone) | Patrones hapticos custom |

---

### IDEA 31: "Audio AR" — Escucha la contaminacion en 3D

**Que es**: Usando spatial audio con head tracking de AirPods Pro, crear una capa de "realidad aumentada auditiva".

**Diseno sonoro**:
| Calidad del Aire | Soundscape |
|-----------------|------------|
| Aire limpio | Pajaros, viento suave, agua — posicionado espacialmente |
| Contaminacion moderada | Zumbido grave sutil, trafico lejano |
| Contaminacion alta | Drone industrial opresivo, tono denso con reverb |
| Fuentes direccionales | Sonido negativo VIENE de la direccion de la autopista |

**Head tracking**: Giras la cabeza hacia la fuente de contaminacion → el sonido se hace mas fuerte. Giras away → se desvanece.

```swift
import CoreMotion

let headphoneMotion = CMHeadphoneMotionManager()
headphoneMotion.startDeviceMotionUpdates(to: .main) { motion, _ in
    guard let yaw = motion?.attitude.yaw else { return }
    // yaw = direccion de la cabeza
    // Calcular angulo relativo a fuente de contaminacion
    // Ajustar volumen/pan del sonido contaminante
}
```

**Resultado**: El usuario literalmente puede "escuchar" donde esta la contaminacion.

---

### IDEA 32: "SoundAnalysis" — AirPods como detector de trafico

**Que es**: Clasificar sonidos ambientales en tiempo real como proxy de contaminacion.

```swift
import SoundAnalysis

let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
// Detecta 300+ categorias: car_horn, siren, engine, construction, birds, wind
```

| Sonido detectado | Implicacion para AirWay |
|-----------------|------------------------|
| Bocinas + motores | Trafico denso → PM2.5 y NO2 elevados |
| Sirenas | Emergencia → calidad aire impredecible |
| Construccion | Polvo/particulas → PM10 alto |
| Pajaros + viento | Zona verde → aire probablemente limpio |

**Cruce con datos**:
> "SoundAnalysis detecto trafico pesado. Coincide con sensor: PM2.5 = 95. Recomendamos cambiar de ruta."

---

### IDEA 33: "Coach Respiratorio" con AirPods

**Que es**: Ejercicios de respiracion guiados por audio que se adaptan al aire actual.

| AQI | Audio Guide |
|-----|-------------|
| < 50 | Tonos suaves, ritmo lento — "Inhala profundo..." |
| 50-100 | Ritmo normal |
| 100-150 | "Respira suavemente, poca profundidad" |
| > 150 | "Respira por la nariz. Busca un lugar cerrado." |

Los AirPods guian con tonos y el Watch sincroniza con haptics.

---

### IDEA 34: "Navegacion por Audio Espacial"

**Que es**: En vez de mirar el mapa, los AirPods guian hacia aire limpio con sonido.

- Un tono agradable viene de la DIRECCION de la ruta limpia
- Un tono desagradable viene de la direccion contaminada
- Al girar la cabeza, el sonido se mueve (head tracking)

> "Sigue el sonido del agua" → te lleva por la ruta con mejor AQI.

---

### IDEA 35: AirPods Pro 3 — HR durante ejercicio + contaminacion

**Que es**: Usar el sensor optico de HR de AirPods Pro 3 para monitorear durante workouts.

- Monitorear HR en tiempo real via AirPods
- Si HR sube Y AQI es alto → alerta: "Tu corazon trabaja mas duro en este aire. Reduce la intensidad."
- Correlacionar HR con AQI para perfil personal de sensibilidad

---

## CATEGORIA 9: ORQUESTACION MULTI-DISPOSITIVO

### IDEA 36: "El Escudo Ambiental" — La Triada AirWay

**Que es**: iPhone + Apple Watch + AirPods trabajando como un sistema coordinado.

```
AIRWAY TRIAD

iPhone = EL CEREBRO
  - ML models (CoreML, Foundation Models)
  - Fetch NASA TEMPO + OpenAQ
  - Route calculation + data fusion
  - AR visualization

Apple Watch = EL GUARDIAN
  - Monitoreo continuo (HR, HRV, SpO2)
  - PPI Score en tiempo real
  - Haptic alerts + Complications
  - Presupuesto de Exposicion (anillos)

AirPods = EL GUIA
  - Audio AR de contaminacion
  - Navegacion por sonido espacial
  - SoundAnalysis (proxy trafico)
  - Coach respiratorio
```

**Escenario coordinado para la demo**:
1. iPhone detecta spike de AQI en la ruta
2. Watch envia haptic Failure + muestra PPI Score subiendo
3. AirPods: tono espacial guia hacia ruta alternativa
4. Watch muestra anillo de exposicion llenandose menos al cambiar de ruta
5. iPhone muestra: "Ruta ajustada. Ahorraste 45 ug de PM2.5."

---

## CATEGORIA 10: IDEAS MOONSHOT / EXPERIMENTALES

### IDEA 37: "Equivalencia en Cigarrillos" en el Watch

Complicacion que muestra en tiempo real: **"2.3 cigarrillos hoy"**

Basado en: 1 cigarrillo ~ 22 ug PM2.5 inhalados. Dosis acumulada del dia, ajustada por ventilacion.

> Nada motiva mas el cambio de comportamiento que ver cigarrillos acumularse en tu muneca.

---

### IDEA 38: Correlacion sueno + contaminacion nocturna

**Datos cruzados**:
```
AQI nocturno (ventana dormitorio) <-> Calidad de sueno (Watch)
                                        - Duracion sueno profundo
                                        - Frecuencia despertares
                                        - SpO2 nocturno
```

**Insight generado**:
> "Anoche el PM2.5 fue 89 cerca de tu casa. Tu sueno profundo fue 23% menor que tu promedio. Considera cerrar ventanas cuando AQI > 75."

**Evidencia**: Estudio con +1 millon de noches demostro que PM2.5 reduce sueno profundo.

---

### IDEA 39: Deteccion de tos como biomarcador

**Que es**: Usar microfono del iPhone/AirPods + ML para detectar episodios de tos.

**Precision**: Paper de Hyfe → 96% sensibilidad, 96% especificidad.

**Uso**:
> "Has tosido 12 veces en la ultima hora. El AQI en tu zona es 135. Quieres que te guie a una zona mas limpia?"

---

### IDEA 40: Gamificacion — "Clean Air Achievements"

| Badge | Como ganarlo |
|-------|-------------|
| Guardian Pulmonar | 7 dias seguidos bajo presupuesto |
| Corredor Consciente | 10 runs en AQI < 50 |
| Explorador Limpio | Descubrir 5 rutas limpias nuevas |
| Embajador del Aire | Compartir 10 alertas con amigos |
| Durmiente Protegido | 7 noches con ventana cerrada cuando AQI > 75 |

---

### IDEA 41: AR con dispersion de contaminacion realista

Extender las particulas AR para mostrar plumas direccionales usando datos de viento. La contaminacion fluye entre edificios como un rio visible.

---

### IDEA 42: Triangulacion de fuentes de contaminacion

Multiples reportes ciudadanos + direccion del viento + inferencia bayesiana = localizacion probable de la fuente de contaminacion.

---

### IDEA 43: Integracion con Siri via App Intents

Comandos de voz gratuitos:
- "Oye Siri, como esta el aire?"
- "Navega a mi trabajo por aire limpio"
- "Cual es mi exposicion de hoy?"

---

### IDEA 44: "Sonificacion del Aire" — Soundscape generativo

Crear un paisaje sonoro continuo que evoluciona con datos ambientales en tiempo real:

| Dato | Efecto Sonoro |
|------|--------------|
| PM2.5 | Controla granularidad — limpio=suave, contaminado=estatico |
| NO2 | Controla pitch — mas NO2=tono mas bajo, ominoso |
| O3 | Controla brillo — ozono moderado=sparkle, alto=aspero |
| Viento | Controla ritmo — viento=dinamico, calma=drone estancado |
| Temperatura | Controla calidez del timbre |

Despues de unos dias, sabes la calidad del aire sin ver la pantalla — la ESCUCHAS.

---

### IDEA 45: "Smart Mask Manager"

Para usuarios con mascarilla (N95/KN95), el Watch se convierte en gestor:
- Estimar saturacion del filtro por exposicion acumulada
- Alertar cuando cambiar mascarilla
- Cuando AQI alto y no se detecta mascarilla: sugerir usarla
- Trackear "horas protegidas" vs "horas desprotegidas"

---

### IDEA 46: "Micro Digital Twin" — Dispersion local de contaminacion

Modelo ligero (500m alrededor del usuario) que simula dispersion:
- Input: viento + geometria de edificios (MapKit 3D) + fuentes (calles)
- Output: campo de contaminacion estimado en grid 2D
- Prediccion: "Camina por el lado este de esta calle → 30% menos exposicion porque los edificios bloquean el viento de la autopista"

---

## APIS GRATUITAS CONFIRMADAS

### Datos de Calidad del Aire

| API | Datos | Limite gratis | Auth |
|-----|-------|--------------|------|
| **Open-Meteo Air Quality** | PM2.5, PM10, NO2, O3, forecast 5 dias | Ilimitado | Sin API key |
| **WAQI** | AQI real-time, 11,000+ estaciones | 1,000 req/seg | Token gratis |
| **OpenAQ v3** | Sensores terrestres, 65 paises | 60 req/min | API key gratis |
| **IQAir Community** | AQI + weather por ciudad | 500 req/dia | Gratis |
| **NASA Earthdata** | Satelite, datos historicos | Ilimitado | Cuenta gratis |
| **Open-Meteo Weather** | Viento, temp, humedad, UV | Ilimitado | Sin API key |

### IA / LLM

| API | Modelo | Limite gratis | Auth |
|-----|--------|--------------|------|
| **Google Gemini Flash-Lite** | Gemini 2.5 | 1,000 req/dia | Google account |
| **Groq** | Llama, Mixtral | 14,400 req/dia | Email |
| **OpenRouter** | 29 modelos gratis | 200 req/dia | Gratis |
| **Cerebras** | Ultra-rapido | 1M tokens/dia | Gratis |
| **DeepSeek** | V3, R1 | 5M tokens signup | Gratis |
| **Mistral** | Large, Small | 1B tokens/mes | Telefono |
| **Apple Foundation Models** | ~3B on-device | Ilimitado | $0, sin internet |

### On-Device (Sin costo, sin internet)

| Framework | Que hace |
|-----------|---------|
| **CoreML** | Inferencia de modelos ML |
| **CreateML** | Entrenar modelos en Xcode GUI |
| **Vision** | Clasificacion de imagenes, deteccion |
| **SoundAnalysis** | Clasificacion de sonidos (300+ categorias) |
| **NaturalLanguage** | Sentimiento, clasificacion de texto |
| **Apple MapKit** | Mapas, rutas, geocoding (ilimitado en iOS) |

---

## DATOS CIENTIFICOS CLAVE

Estadisticas para el pitch ante jueces (todas con papers publicados):

1. **"Un aumento IQR en PM2.5 eleva el riesgo de fibrilacion auricular 38%"** — npj Digital Medicine 2023
2. **"La exposicion a PM2.5 causa caidas de SpO2 en minutos, hasta -0.40% en pacientes EPOC en 1 hora"** — Science of the Total Environment 2020
3. **"HRV disminuye 5-6% por IQR de PM2.5 en individuos metabolicamente vulnerables"** — Estudio MESA
4. **"Metodos estandar subestiman exposicion personal a PM2.5 hasta 21%"** — JMIR 2025 Milan
5. **"Eficiencia de sueno cae 3.2% en quintiles de mayor exposicion"** — Estudio actigrafia
6. **"Mas de 1 millon de noches de datos wearable muestran que la contaminacion reduce sueno profundo"** — BMC Medicine 2023
7. **"Frecuencia cardiaca aumenta 3.5 bpm por unidad de PM2.5, con efectos pico 0-5 horas post-exposicion"** — Ecotoxicology 2024
8. **"IA de deteccion de tos logra 96% sensibilidad y especificidad desde microfonos"** — Hyfe ensayos clinicos
9. **"7 millones de muertes al ano por contaminacion del aire"** — OMS
10. **"99% de las personas respiran aire que excede limites de la OMS"** — OMS

---

## RANKING FINAL: TOP IDEAS PARA EL HACKATHON

### Tier 1: IMPRESCINDIBLES (Construir estas primero)

| # | Idea | Tiempo est. | Factor WOW | HCAI Score |
|---|------|-------------|------------|------------|
| 1 | AirWay Copilot (Foundation Models on-device) | 3-4h | Maximo | Maximo |
| 2 | Panel de Transparencia + Confianza | 2-3h | Muy alto | Maximo |
| 3 | Breathing Persona (perfiles vulnerabilidad) | 2-3h | Alto | Maximo |
| 4 | Override Humano + Espectro Autonomia | 2h | Muy alto | Maximo |
| 5 | Prediccion AQI con CreateML | 3-4h | Alto | Alto |

### Tier 2: DIFERENCIADORES FUERTES (Si hay tiempo)

| # | Idea | Tiempo est. | Factor WOW | HCAI Score |
|---|------|-------------|------------|------------|
| 6 | PPI Score (Apple Watch) | 3-4h | Muy alto | Maximo |
| 7 | Presupuesto de Exposicion (anillos) | 3-4h | Muy alto | Alto |
| 8 | Maquina del Tiempo (slider) | 2-3h | Muy alto | Alto |
| 9 | SoundAnalysis proxy trafico | 2h | Alto | Alto |
| 10 | SnapAir (camara → AQI) | 4-5h | Maximo | Maximo |

### Tier 3: EXTRAS IMPRESIONANTES

| # | Idea | Tiempo est. | Factor WOW | HCAI Score |
|---|------|-------------|------------|------------|
| 11 | Audio AR con AirPods | 4-5h | Maximo | Alto |
| 12 | Pulmones Digitales | 3h | Muy alto | Medio |
| 13 | Equivalencia cigarrillos | 1h | Alto | Medio |
| 14 | Adaptacion emocional color | 2h | Alto | Medio |
| 15 | Alerta Convergente (cuerpo+aire) | 3h | Muy alto | Maximo |

---

## SCRIPT DE DEMO SUGERIDO (10 MIN)

| Min | Que mostrar | Principio HCAI |
|-----|-------------|----------------|
| 0-1 | AR: 2,000 particulas flotando. "Esto respiras cada segundo." | Impacto emocional |
| 1-3 | Onboarding Breathing Persona: "Maria es asmatica" → app se transforma | La IA se adapta al humano |
| 3-5 | Pedir ruta → Panel de Transparencia → "Evite Insurgentes porque..." + Medidor de confianza | Transparencia |
| 5-6 | Override: Maria elige otra ruta → IA acepta y advierte consecuencias | Control humano |
| 6-7 | Slider Maquina del Tiempo → "A las 5pm empeora, sal antes" | IA predictiva explicable |
| 7-8 | Copilot: "Es seguro correr?" → respuesta personalizada on-device | IA conversacional |
| 8-9 | Watch: PPI Score + Presupuesto de Exposicion + "Evitaste 3 cigarrillos" | Wearable health |
| 9-10 | "IA que protege tus pulmones, respeta tus decisiones, y explica todo" | Cierre HCAI |

**Frase matadora para cerrar**:
> "Tu Apple Watch ya sabe tu frecuencia cardiaca, tu variabilidad, tu oxigeno en sangre, y tu respiracion. Tu iPhone ya sabe la calidad del aire. AirWay es la primera app que conecta esos dos mundos — porque lo que respiras y como responde tu cuerpo NO son problemas separados."

---

## FUENTES Y REFERENCIAS

### Papers Cientificos
- Short-term association between ambient air pollution and HRV: KORA S4 and FF4 studies (Springer, 2025)
- Particulate Air Pollution, Metabolic Syndrome, and HRV — MESA Study (PMC)
- Time course of SpO2 responding to short-term PM2.5 in elderly (Science of the Total Environment, 2020)
- Application of smart devices in investigating effects of air pollution on AF onset (npj Digital Medicine, 2023)
- Long-term and short-term effects of ambient air pollutants on sleep characteristics (BMC Medicine, 2023)
- Personalized health monitoring using explainable AI (Nature Scientific Reports, 2025)
- AirGPT: outperforms GPT-4o on air quality assessments (Nature npj Climate and Atmospheric Science, 2025)
- Wearable System for Personal Air Pollution Exposure Estimation (JMIR, 2025)
- SFDformer: spatio-temporal Fourier transformer for air quality (Frontiers in Environmental Science, 2025)
- FuXi-Air: 72-hour forecasts for 6 pollutants (npj Clean Air, 2026)
- Group-Aware GNN for spatial pollution interpolation (ACM, 2023)
- Federated Learning for Air Quality Monitoring (arXiv, 2025)
- Uncovering local AQI with smartphone images (Nature Scientific Reports, 2023)
- PM25Vision benchmark dataset (arXiv, 2025)
- Apple-Elevance Asthma Study (JAMA, 2025)
- Cough sound-based deep learning for COPD detection (npj Primary Care Respiratory Medicine, 2026)

### Documentacion Apple
- Foundation Models Framework (developer.apple.com/documentation/FoundationModels)
- CoreML (developer.apple.com/documentation/coreml)
- CreateML (developer.apple.com/documentation/createml)
- Vision Framework (developer.apple.com/documentation/vision)
- SoundAnalysis (developer.apple.com/documentation/soundanalysis)
- HealthKit (developer.apple.com/documentation/healthkit)
- CMHeadphoneMotionManager (developer.apple.com/documentation/coremotion/cmheadphonemotionmanager)
- CoreHaptics (developer.apple.com/documentation/corehaptics)
- WeatherKit (developer.apple.com/documentation/weatherkit)

### Frameworks HCAI
- Ben Shneiderman — Human-Centered AI (Oxford University Press)
- The Shape of AI — UX Patterns (shapeof.ai)
- Google People + AI Guidebook (pair.withgoogle.com)
- AIUX Design Guide — 36 Patterns (aiuxdesign.guide)

### APIs
- Open-Meteo Air Quality API (open-meteo.com/en/docs/air-quality-api)
- OpenAQ API v3 (docs.openaq.org)
- WAQI API (aqicn.org/api)
- NASA Earthdata (api.nasa.gov)
- Google Gemini API (ai.google.dev)
- Groq API (console.groq.com)

---

> **Documento generado**: 14 de Abril de 2026
> **Proyecto**: AirWay — Swift Changemakers Hackathon 2026
> **Tema**: Human-Centered AI
> **Total de ideas**: 46
> **Fuentes investigadas**: 170+ busquedas web, 50+ papers academicos
