# AirWay — Ideas IA para Poblaciones Vulnerables

**Hackathon Swift Changemakers 2026 · UNAM iOS Lab · Tema: HCAI**
**Fecha:** 16 de abril 2026
**Enfoque:** Valor para gente común, NO solo deportistas

---

## Tabla de Contenido

1. [Estado actual del proyecto](#estado-actual)
2. [Filosofía HCAI: centrar la vulnerabilidad](#filosofia-hcai)
3. [Ideas por población vulnerable](#ideas-por-poblacion)
   - [🤰 Embarazadas y recién nacidos](#embarazadas)
   - [👴 Adultos mayores (60+)](#adultos-mayores)
   - [👶 Niños y escuelas](#ninos-escuelas)
   - [👷 Trabajadores informales al aire libre](#trabajadores-informales)
   - [🏚️ Comunidades de bajos ingresos / cocina con leña](#bajos-ingresos)
   - [🚕 Conductores Uber / taxi / transporte](#conductores)
   - [♿ Personas con discapacidad / movilidad reducida](#discapacidad)
   - [🏥 Asma / EPOC / cardiopatías (ya parcialmente atendido)](#asma-epoc)
   - [🐕 Mascotas](#mascotas)
   - [🏠 Hogares (ventilación, indoor air quality)](#hogares)
4. [Ideas transversales](#ideas-transversales)
5. [Integración con datos gubernamentales mexicanos](#integracion-gobierno)
6. [Stack técnico recomendado (iOS 26)](#stack-tecnico)
7. [Priorización para hackathon (2 días)](#priorizacion)
8. [Apéndice: Fuentes](#fuentes)

---

## <a id="estado-actual"></a>1. Estado actual del proyecto AirWay

### Lo que YA está construido (no duplicar)

| Capa | Componente | Estado |
|---|---|---|
| **Backend** | Django REST + aggregator IDW multi-fuente (OpenAQ + WAQI + Open-Meteo) | ✅ |
| **Backend** | Gemini 2.0 Flash (análisis NL, recomendaciones) | ✅ |
| **Backend** | GradientBoosting PM2.5 (1h / 3h / 6h) | ✅ |
| **Backend** | Dose-response endpoint (`/api/v1/ppi/context`) | ✅ |
| **Backend** | Exposure service (ruta → dosis acumulada) | ✅ |
| **iPhone** | AQI Home + Daily Forecast + Mapa con rutas | ✅ |
| **iPhone** | AR: 2000 partículas PM2.5 @ 60 FPS | ✅ |
| **iPhone** | `VulnerabilityProfile`: asma, EPOC, CVD, diabetes, 65+, niños <14 | ✅ |
| **Apple Watch** | `PPIScoreEngine` con HR/HRV/SpO2/RR + Holt smoothing | ✅ |
| **Apple Watch** | `BaselineEngine` personalizado | ✅ |
| **Apple Watch** | `CigaretteEquivalenceEngine` (dosis → cigarrillos) | ✅ |

### Lo que NO tiene (= oportunidades IA nuevas)

| Gap | Oportunidad HCAI |
|---|---|
| ❌ **Foundation Models framework (iOS 26)** | LLM 3B on-device, privado, gratis, offline |
| ❌ **CoreML en-device** | Predicción hiperlocal sin backend |
| ❌ **Vision framework** | Foto → diagnóstico ambiental |
| ❌ **SoundAnalysis** | Audio tráfico → PM2.5 proxy |
| ❌ **State of Mind (iOS 26 HealthKit)** | Eco-ansiedad medible |
| ❌ **Federated learning** | Mejora colectiva sin tracking personal |
| ❌ **Embarazadas, informales, discapacidad** | 3 poblaciones >30% de MX sin cobertura |
| ❌ **Integración SIMAT/SINAICA/FIRMS/DENUE** | Cero APIs mexicanas oficiales conectadas |
| ❌ **Lenguas indígenas** | Náhuatl, Maya, Zapoteco (papers 2025) |
| ❌ **Indoor air quality** | Cocina de leña es el mayor asesino silencioso en MX |

---

## <a id="filosofia-hcai"></a>2. Filosofía HCAI: centrar la vulnerabilidad

El error común en apps de calidad del aire: **"toma decisiones por el usuario"**. IQAir, BreezoMeter, AirVisual asumen que todos somos iguales. La HCAI de Shneiderman exige:

1. **High control + high automation** — la IA sugiere, el humano decide.
2. **Trusted, safe, reliable** — incertidumbre visible, no certezas falsas.
3. **Preserva dignidad** — no decirle a un vendedor ambulante "quédate en casa".

**Regla operativa para AirWay**: Cada feature de IA debe pasar el test:
> ¿Una abuelita de Iztapalapa que no corre, no usa Watch, y cocina con leña, recibe valor medible y específico de esto?

Si la respuesta es NO, la feature es para clase media-alta bien-estar, no para HCAI real.

---

## <a id="ideas-por-poblacion"></a>3. Ideas por población vulnerable

### <a id="embarazadas"></a>🤰 Embarazadas y recién nacidos

**Contexto**: +12% riesgo parto prematuro por cada 10 µg/m³ PM2.5 (meta-análisis). Cada +1 µg/m³ PM2.5 prenatal = −0.38 puntos en lenguaje a 24 meses. Ginecólogos IMSS NO integran aire en consulta prenatal. ZERO apps con recomendaciones por trimestre.

#### 💡 Idea 47: **Modo Gestación — Recomendaciones por trimestre**
- **Quién beneficia**: 2.1M nacimientos/año en México.
- **Qué hace**: `VulnerabilityProfile` expandido con `pregnancyWeek: Int?`. Foundation Models genera recomendaciones específicas: 1er trimestre (organogénesis — evitar CO y VOCs), 2º (crecimiento pulmonar fetal — evitar PM2.5 picos), 3º (parto prematuro — evitar NO2 y O3).
- **Tech**: Foundation Models `@Generable` con prompt estructurado por trimestre.
- **Código base existente**: `VulnerabilityProfileView.swift` ya tiene el patrón de toggles.
- **HCAI**: No decide ("cancela consulta") — informa ("evita exposición >35 µg/m³ durante próximas 2h").

#### 💡 Idea 48: **Lactancia segura — Ventana para paseo con bebé**
- **Quién beneficia**: Madres con recién nacidos (0-12 meses).
- **Qué hace**: Modelo CoreML ligero (Random Forest sobre 24h de datos locales) predice ventanas de 2-3h con AQI < 50 para paseo. Notificación respetuosa: "Las próximas 3 horas el aire está bueno, ideal para paseo con bebé".
- **Tech**: CoreML `MLRegressor` + `UserNotifications` con `UNCalendarNotificationTrigger`.
- **Dato NASA**: TEMPO da NO2 hora a hora — clave para recién nacidos (su sistema inmune es sensible al NO2 >40 ppb).

#### 💡 Idea 49: **Integración con consulta prenatal digital**
- **Quién beneficia**: Embarazadas que usan Watch o iPhone durante el embarazo.
- **Qué hace**: Exporta a PDF un reporte semanal: exposición acumulada a PM2.5, O3, NO2 por trimestre + días de contingencia + recomendaciones para llevar a consulta ginecológica.
- **Tech**: PDFKit + HealthKit exposure history + FIRMS (si hubo incendios cerca).
- **Impacto**: Lleva la IA AL consultorio, no la aísla en la app.

#### 💡 Idea 50: **Mapa de calor "aire seguro para embarazo" hiperlocal**
- **Quién beneficia**: Embarazadas urbanas (CDMX, Monterrey donde rebasó CDMX en 2025).
- **Qué hace**: Usa TEMPO + RAMA + interpolación kriging para mostrar por manzana (no alcaldía) qué zonas tener AQI<50 >80% del tiempo. "Parques recomendados para caminar embarazada esta semana".
- **Tech**: Backend Django + PyKrige + React Native Maps con heatmap layer.

---

### <a id="adultos-mayores"></a>👴 Adultos mayores (60+)

**Contexto**: EPOC 7.8% adultos urbanos CDMX (PLATINO). Asilos INAPAM sin protocolo ambiental. Adultos con deterioro cognitivo no usan apps. UNAM advirtió 2025 sería peor por domos de calor.

#### 💡 Idea 51: **Modo Cuidador — Alertas delegadas**
- **Quién beneficia**: Hijos/nietos que cuidan a abuelos en otra alcaldía.
- **Qué hace**: "Seguir a abuelita" → cuando su zona (ej. Iztapalapa) supera AQI 100, el cuidador recibe push con acción sugerida y botón "Llamar" directo. Foundation Models genera el mensaje de WhatsApp/SMS adaptado al usuario ("Ma, cierra las ventanas y no salgas a comprar tortillas hasta las 4pm").
- **Tech**: CloudKit para sync cuidador↔dependiente + Foundation Models para mensaje personalizado.
- **HCAI**: El cuidador NO toma decisiones por el adulto mayor — le da información accionable.

#### 💡 Idea 52: **Asilos/casas de día — Dashboard institucional**
- **Quién beneficia**: Mundet DIF, INAPAM, residencias privadas.
- **Qué hace**: Vista multi-usuario para enfermeros: muestra exposición acumulada semanal por residente, alerta si algún residente con EPOC + ubicación con AQI>150 >2h. Exporta reporte para médico interno.
- **Tech**: SwiftUI iPad app (misma codebase) + backend Django multi-tenant.

#### 💡 Idea 53: **Integración con Apple Watch SE / bastón inteligente**
- **Quién beneficia**: Adultos mayores con Apple Watch SE (más accesible).
- **Qué hace**: Detección de caída (`CMMotionManager`) + si ocurre en día con AQI>150 o contingencia, el 911 recibe contexto ambiental. También: recordatorio suave de tomar broncodilatador cuando AQI cruza umbral personal.
- **Tech**: WatchKit + FallDetectionAPI (iOS 16+) + HealthKit.

#### 💡 Idea 54: **Modo Abuelita — UI simplificada + voz grande**
- **Quién beneficia**: Adultos 70+ con baja alfabetización digital.
- **Qué hace**: Modo con texto 200%, íconos grandes, solo 3 botones: "¿Cómo está el aire?", "¿Puedo salir?", "Llama a mi hijo". Foundation Models habla con Siri voice con frases cortas: "Aire contaminado hoy. Mejor espera a las 5 de la tarde".
- **Tech**: Dynamic Type + `AVSpeechSynthesizer` + Foundation Models simplificado.
- **HCAI puro**: Dignidad + control + accesibilidad.

---

### <a id="ninos-escuelas"></a>👶 Niños y escuelas

**Contexto**: 20% de la dosis diaria de carbón negro de un niño ocurre en ruta a la escuela. +17.4 µg/m³ PM2.5 = +8.8% sibilancias en asmáticos CDMX. Programa "Banderines CDMX" existe pero sin app. Niños varones más sensibles.

#### 💡 Idea 55: **¿Hay recreo afuera hoy? — App para maestros**
- **Quién beneficia**: 220,000 docentes CDMX + 1.2M alumnos escuelas públicas.
- **Qué hace**: Widget de iPad/iPhone para dirección escolar. Muestra "Recreo: SÍ/NO/CON PRECAUCIÓN" basado en:
  - RAMA estación más cercana (raw CSV `contaminantes_2026.csv.gz`)
  - Pronóstico próximas 2h (Open-Meteo)
  - Presencia de asmáticos registrados en plantel (input escolar)
  - Si NO: Foundation Models sugiere actividades indoor alternativas (yoga, lectura, film educativo).
- **Tech**: WidgetKit + backend con caché por CCT (Clave Centro Trabajo).

#### 💡 Idea 56: **Ruta escolar más limpia — "Safe Walk to School"**
- **Quién beneficia**: Padres de primaria CDMX/GDL/MTY.
- **Qué hace**: Dijkstra ya existente + penalización por PM2.5 + preferencia por rutas arboladas (inventario SEDEMA áreas verdes). Output: 2 rutas posibles con exposición estimada diferenciada. "Ruta A: 12 min, 45 µg/m³. Ruta B: 15 min, 28 µg/m³ (por camellón arbolado)".
- **Tech**: Extiende `RouteOptimizer.swift` existente + GeoJSON áreas verdes CDMX.

#### 💡 Idea 57: **Banderín Digital Escolar — Integración programa CDMX**
- **Quién beneficia**: Escuelas inscritas al programa SEDEMA/SEDU.
- **Qué hace**: Reemplaza el banderín físico con un display digital (Apple TV en patio o iPad entrada). Muestra color actual + pronóstico 6h + alerta visual (verde/amarillo/rojo/morado). Sincroniza con RAMA automáticamente.
- **Tech**: tvOS app ligera + Push Notifications escolares.
- **Civic impact**: Digitaliza un programa gubernamental existente.

#### 💡 Idea 58: **Detector de humo de tabaco cerca de escuelas (Vision)**
- **Quién beneficia**: Reportes ciudadanos anti-tabaquismo cerca escuelas.
- **Qué hace**: Cámara iPhone + Vision framework + modelo CoreML fine-tuned detecta humo visible + geolocaliza + reporte automatizado a SEDEMA/SSA. Protege niños caminando a escuela.
- **Tech**: `VNClassifyImageRequest` + MobileNetV2 custom + MapKit.
- **Fuente**: DeepVision paper (J. Building Eng., 2024).

#### 💡 Idea 59: **Modo Tarea — "No estudies cerca de ventana hoy"**
- **Quién beneficia**: Familias con niños en casa post-escuela.
- **Qué hace**: Detecta horario de tarea (habitual 4-7pm). Si AQI exterior > AQI estimado indoor (basado en ventilación del hogar registrada al onboarding), recomienda: "Cierra la ventana de la sala, aire indoor está 30% mejor ahora".
- **Tech**: Core ML regressor indoor/outdoor ratio + HealthKit sleep for context.

---

### <a id="trabajadores-informales"></a>👷 Trabajadores informales al aire libre — LA OPORTUNIDAD MAYOR

**Contexto**: 170,000 vendedores ambulantes CDMX (97.4% informalidad). Estudios 2024: 52% expectoración, 44.3% infecciones respiratorias recurrentes, 61.3% patrón espirométrico restrictivo. 500,000 albañiles expuestos a sílice sin EPP. Informales NO tienen incapacidad — no pueden "quedarse en casa".

#### 💡 Idea 60: **Modo Informal — Guía de supervivencia, no de evasión**
- **Quién beneficia**: Vendedores ambulantes, bolerías, lavadores de autos, músicos callejeros.
- **Qué hace**: Perfil específico que asume trabajo al aire libre 6-10h/día. Foundation Models NO dice "quédate en casa" — dice:
  - "Trabaja hoy entre 10am-1pm: AQI promedio 65. Evita 2-6pm: llegará a 140".
  - "Tu esquina en Eje Central está 25 µg/m³ peor que Av. Hidalgo — considera mover tu puesto si es posible".
  - "Usa cubrebocas N95 hoy: $35 en Farmacia del Ahorro más cercana (DENUE)".
- **Tech**: Foundation Models + `@Generable` + DENUE API para farmacias + RAMA por cuadra.
- **Dignidad**: No moraliza. Reconoce la realidad laboral.

#### 💡 Idea 61: **Mensajero en bici — Ventilación y rutas**
- **Quién beneficia**: Repartidores Rappi, DiDi, Uber Eats en bici/moto.
- **Qué hace**: Dado destino, sugiere ruta con menor exposición pico (peatonales, parques). Durante paro de luz en semáforo: "Levanta el pañuelo 30 segundos, camión de diésel adelante" (detección acústica de diésel con SoundAnalysis).
- **Tech**: `SNClassifySoundRequest` + Random Forest + ruta Dijkstra modo "bike" ya existente.
- **Paper**: Acoustic vehicle classification paper 2025 (R²≈0.93).

#### 💡 Idea 62: **Policía de tránsito — Rotación de esquinas**
- **Quién beneficia**: ~15,000 policías tránsito CDMX.
- **Qué hace**: Dashboard del turno: cada 2h sugiere rotar de esquina basado en exposición real medida. "Has estado 2h en Reforma/Juárez (PM2.5: 85). Rótate a Chapultepec (PM2.5: 42) los próximos 2h".
- **Tech**: Integración con sistema SSC (requeriría convenio) O app voluntaria con geofencing.

#### 💡 Idea 63: **Albañil / trabajador de construcción — Riesgo silicosis**
- **Quién beneficia**: 500,000 albañiles México (casos de silicosis emergente).
- **Qué hace**: Obra registrada = perfil "construcción". Sensor iPhone micrófono detecta sonidos de amoladora/sierra concreto (SoundAnalysis) = alerta: "Estás expuesto a sílice. Respirador P100 urgente". Seguimiento dosis semanal (el CoreML model estima mg/m³ vía patrón acústico).
- **Tech**: Custom `SNClassifySoundRequest` + on-device accumulator.
- **Impacto social**: Problema desatendido por NOM-023-STPS.

#### 💡 Idea 64: **Vendedor de tacos / puesto fijo — Cocina + contaminación**
- **Quién beneficia**: Taqueros, fruteros con plancha de carbón.
- **Qué hace**: Detecta que el puesto usa carbón/leña/gas con una foto (Vision) + cruza con AQI ambiental → dosis combinada indoor-al-aire-libre. Sugiere chimenea de extracción DIY low-cost, marca en mapa puestos con buena ventilación como "Healthy Taco Certified".
- **Tech**: `VNClassifyImageRequest` + backend certificación.

#### 💡 Idea 65: **Turno nocturno — Inversión térmica**
- **Quién beneficia**: Vigilantes, empleados 24h, mariachis.
- **Qué hace**: `CMAltimeter` detecta inversión térmica matutina (PM2.5 atrapada al nivel del suelo). Alerta específica para quienes trabajan de noche: "Al salir a las 6am, la contaminación será 2x peor que a las 2am. Considera cubrebocas antes de salir".
- **Tech**: `CMAltimeter` + weather API + personal schedule.

---

### <a id="bajos-ingresos"></a>🏚️ Comunidades de bajos ingresos / cocina con leña

**Contexto**: 28M mexicanos cocinan con leña (ENCEVI 2018). 4.85M hogares. Chiapas 49-51%, Oaxaca 46-48%. 1 de cada 4 SIN chimenea → PM2.5 interior 100x lo aceptable. 95% en barrios pobres CDMX dicen que el aire es "gran problema" pero apenas conocen el Índice.

#### 💡 Idea 66: **Modo Fogón — Cocina segura con leña**
- **Quién beneficia**: 4.85M hogares México rural e indígena.
- **Qué hace**: Onboarding pregunta "¿Cocinas con leña, carbón, gas, eléctrico?". Si leña:
  - Foto del fogón → Vision detecta si tiene chimenea o no (objeto `VNClassifyImageRequest`).
  - Sin chimenea: "Mejora tu salud con 3 pasos: 1) Cocina con puerta abierta, 2) Ventanas enfrentadas para corriente, 3) Cocina afuera si hay sol".
  - Con chimenea: solo recordatorio de limpieza.
- **Tech**: Vision + Foundation Models en español/náhuatl/maya.
- **Impacto salud**: 1.6M muertes/año globalmente por humo indoor (OMS).

#### 💡 Idea 67: **Lenguas indígenas — Náhuatl / Maya / Zapoteco**
- **Quién beneficia**: 7.4M mexicanos hablantes de lenguas indígenas.
- **Qué hace**: Backend con Llama 3.2 3B fine-tuned en AmericasNLP 2025 datasets. Usuario elige idioma. Todos los mensajes de la app (recomendaciones, alertas, Foundation Models output) se traducen en-device vía API privada.
- **Tech**: Llama 3.2 + AmericasNLP corpus (BLEU 55.86 Maya, 19.51 Bribri ya demostrados).
- **Fuente**: ACL Anthology 2025.americasnlp-1. Google Translate ya agregó Náhuatl/Maya/Zapoteco 2024.

#### 💡 Idea 68: **Mapa de justicia ambiental — CONEVAL + AQI**
- **Quién beneficia**: Público general, ONG, gobierno.
- **Qué hace**: Cruza CONEVAL Rezago Social AGEB 2020 (SHP) con RAMA PM2.5 histórico. Mapa que revela: "Iztapalapa tiene 3x más PM2.5 que Polanco Y 5x más pobreza". Visualización HCAI de desigualdad.
- **Tech**: Django + PostGIS + Mapbox.
- **Paper**: Cambridge "Is air pollution increasing in poorer localities of Mexico" (datos satelitales 15 años).

#### 💡 Idea 69: **Alfabetización en salud — "Explica como abuelita"**
- **Quién beneficia**: Baja escolaridad (solo 53% CDMX conocen el AQI).
- **Qué hace**: Modo "explícame sencillo" — Foundation Models reescribe cualquier recomendación técnica a español simple 6º grado. Ejemplo: "PM2.5: 85 µg/m³, NOM-025 anual" → "El aire tiene mucho polvo invisible, más del doble de lo seguro. Evita ejercicio al aire libre".
- **Tech**: Foundation Models con system prompt grado 6.
- **Métrica HCAI**: Tiempo de comprensión < 5 segundos (vs 30s del número crudo).

#### 💡 Idea 70: **Cocina solar / reforestación comunitaria — Gamificación cívica**
- **Quién beneficia**: Comunidades rurales organizadas.
- **Qué hace**: "Plantamos un árbol juntos" — usuarios en misma alcaldía/municipio acumulan puntos verdes. Cuando la alcaldía llega a 1000, AirWay dona (vía ONG socia) cocinas solares o árboles al programa local.
- **Tech**: CloudKit para grupos + integración ONG.

---

### <a id="conductores"></a>🚕 Conductores Uber / taxi / transporte público

**Contexto**: Taxistas 6.5 µg/m³ carbón negro (el más alto de profesionales). Picos >100 µg/m³ por 30 min. Cerrar ventanas y recircular = −50% exposición, pero nadie les dice.

#### 💡 Idea 71: **Modo Chofer — Recirculación inteligente**
- **Quién beneficia**: 140,000 taxistas CDMX + conductores Uber/DiDi.
- **Qué hace**: Detecta mediante `CMMotionActivityManager` que el usuario está en coche. Si AQI exterior >80 y velocidad <30 km/h (tráfico): notificación "Recircula ventilación ahora. Ahorrarás 50% de exposición".
- **Tech**: Transport mode detection (Random Forest 93.8% accuracy según Sensors 2022) + notificaciones persistentes tipo CarPlay.

#### 💡 Idea 72: **Pausas saludables — Salida de cabina**
- **Quién beneficia**: Conductores 10+ horas/día.
- **Qué hace**: Cada 2h, si el AQI ambiental es bueno (<50), sugiere pausa de 5 min con ejercicio respiratorio (box breathing). Si ambiental es malo, sugiere pausa en centro comercial/parque con filtración (DENUE).
- **Tech**: Foundation Models + DENUE búsqueda tipo "centro comercial".

#### 💡 Idea 73: **Reporte CarPlay — Sin mirar pantalla**
- **Quién beneficia**: Conductores que no pueden atender iPhone.
- **Qué hace**: Extensión CarPlay que muestra AQI en ruta como semáforo gigante. Si cambia a rojo (AQI>150), Siri habla: "Entrando a zona contaminada. Sube tus ventanas y recircula".
- **Tech**: CarPlay framework + Siri voice.

---

### <a id="discapacidad"></a>♿ Personas con discapacidad / movilidad reducida

**Contexto**: Silla de ruedas al nivel de escapes = más PM2.5. Sensibilidad química múltiple sin reconocimiento en México. ZERO apps mexicanas consideran ruta accesible + bajo aire.

#### 💡 Idea 74: **Ruta accesible + limpia**
- **Quién beneficia**: Usuarios de silla de ruedas, bastón, andador.
- **Qué hace**: Extiende `RouteOptimizer.swift` con layer de rampas + elevadores Metro + acera ancha (OpenStreetMap tags `wheelchair=yes`). Pondera además por AQI a nivel-silla (que es más alto que a nivel-peatón por 30-40% según estudios europeos).
- **Tech**: OSM + backend Dijkstra modificado.

#### 💡 Idea 75: **Asistente para sensibilidad química múltiple (SQM)**
- **Quién beneficia**: ~1% población con SQM reconocida (España tiene protocolo; México no).
- **Qué hace**: Lista de triggers personalizables (perfumes, detergentes, humo cigarro). Foto de producto (Vision OCR) detecta ingredientes problemáticos en etiqueta. Mapa de lugares seguros en CDMX.
- **Tech**: `VNRecognizeTextRequest` + base de datos ingredientes.

#### 💡 Idea 76: **Voz sobre aire — Lector de pantalla nativo**
- **Quién beneficia**: Personas con baja visión o ceguera.
- **Qué hace**: AirWay completamente navegable por VoiceOver con lenguaje descriptivo rico. "Entrando a Insurgentes Sur, aire moderado, partículas suben 30% en próxima hora".
- **Tech**: SwiftUI accessibility labels + dynamic speech output.

---

### <a id="asma-epoc"></a>🏥 Asma / EPOC / cardiopatías

**Contexto**: 8.5M mexicanos con asma (INER). 50,073 muertes prematuras 2021. Correlación más alta asma = CO, no PM2.5 (las apps no reportan CO). Ingresos hospitalarios por asma en la SEMANA siguiente a picos. Ya hay `VulnerabilityProfile` en AirWay.

#### 💡 Idea 77: **Predicción personal de crisis asmática**
- **Quién beneficia**: 8.5M asmáticos (ya contemplados pero sin predicción).
- **Qué hace**: CoreML on-device entrena modelo personal sobre 30 días de: HealthKit RR + SpO2 + AQI local + polen + humedad. Predice probabilidad de crisis en próximas 24-48h con precisión personalizada.
- **Tech**: `MLUpdateTask` (Core ML on-device training iOS 26).
- **Paper**: AirPredict (Frontiers Digital Health 2025) — especificidad 0.80-1.00 demostrada.
- **Integra con**: `PPIScoreEngine.swift` y dose-response ya existentes.

#### 💡 Idea 78: **Broncodilatador preventivo — Notificación antes de salir**
- **Quién beneficia**: Asmáticos con SmartInhaler Bluetooth.
- **Qué hace**: 30 min antes de la hora que usualmente el asmático sale, si AQI está peor que su umbral personal: "Considera Salbutamol preventivo antes de salir. Tu médico dijo 2 puffs; última vez usaste hace 6h".
- **Tech**: BLE + HealthKit medications + patrón temporal personal.

#### 💡 Idea 79: **CO alerter — El contaminante olvidado**
- **Quién beneficia**: Asmáticos (correlación CO > PM2.5 con ingresos).
- **Qué hace**: Panel específico "CO" con datos RAMA (que sí mide CO). Alerta cuando CO cruza 9 ppm (OMS 8h avg).
- **Tech**: Ya tienes datos — solo faltaba la vista dedicada.

#### 💡 Idea 80: **Detector de tos — SoundAnalysis**
- **Quién beneficia**: EPOC 7.8% adultos CDMX.
- **Qué hace**: Micrófono pasivo (con consentimiento explícito) detecta tos nocturna mediante `SNClassifySoundRequest` (Hyfe validado 2025). Correlaciona con AQI exposición del día anterior → panel "Tu tos sube cuando el NO2 supera 60 ppb".
- **Tech**: `SNClassifySoundRequest` + Hyfe-style classifier.
- **Privacy**: On-device only, no audio leaves phone.

---

### <a id="mascotas"></a>🐕 Mascotas

**Contexto**: Razas braquicéfalas (pug, bulldog, bóxer) mayor riesgo. Monterrey 245 µg/m³ PM10 = perros enfermos documentados 2025. Nadie avisa a dueños.

#### 💡 Idea 81: **Modo Perro — Ventana óptima para paseo**
- **Quién beneficia**: 19M hogares con perro en México.
- **Qué hace**: Perfil "mi perro" con raza + edad + respiración normal. Recomendación específica por raza (braquicéfalos más sensibles). Ventana diaria óptima para paseo (AQI + temperatura — evitar medio día).
- **Tech**: Foundation Models + tabla de sensibilidad por raza.

#### 💡 Idea 82: **Detector de jadeo anormal (cámara)**
- **Quién beneficia**: Dueños de perros braquicéfalos en ciudades contaminadas.
- **Qué hace**: Video de 10 segundos del perro. Vision framework detecta frecuencia respiratoria anormal (>40 rpm en reposo = alerta). Sugiere revisión veterinaria.
- **Tech**: `VNAnimalBodyPoseObservation` + frecuencia de movimiento torácico.

---

### <a id="hogares"></a>🏠 Hogares — Indoor Air Quality

**Contexto**: Ninguna app mexicana responde "¿Abro la ventana?". Literatura global: AQI<25 abre, 25-50 ráfagas, >50 cierra.

#### 💡 Idea 83: **"¿Abro la ventana?" — La pregunta de oro**
- **Quién beneficia**: TODOS.
- **Qué hace**: Pantalla principal con respuesta SI/NO/DEPENDE basada en:
  - AQI exterior actual + tendencia 1h
  - Humedad + temperatura
  - Lluvia reciente (mejor ventana)
  - Viento (dispersión)
- Foundation Models genera explicación 1 línea: "SÍ abre 15 min. Acaba de llover y el viento está dispersando".
- **Tech**: WidgetKit + Live Activities + WeatherKit.
- **Métrica impacto**: Respuesta ciudadana medible — 1000 aperturas diarias evitan X kg PM2.5 indoor.

#### 💡 Idea 84: **Auditoría de ventilación por foto**
- **Quién beneficia**: Familias urbanas CDMX.
- **Qué hace**: Usuario fotografía cocina/sala. Vision detecta: presencia de campana extractora, ventanas, purificador HEPA, plantas. Foundation Models genera plan: "Tu cocina tiene gas pero no extractor. Riesgo: NO2 2x OMS. Solución: extractor DIY con ventilador de $180 (Amazon link)".
- **Tech**: Vision multimodal + Foundation Models.
- **Paper**: Arbabi et al. J. Building Eng. 2024.

#### 💡 Idea 85: **Plantas purificadoras — Identificador**
- **Quién beneficia**: Usuarios que quieren reducir VOCs indoor.
- **Qué hace**: Foto de planta → identifica especie (Core ML con PlantNet fine-tuned) → confirma si es purificadora (potus, sansevieria, ficus) y cuántas necesitas para tu m² de sala.
- **Tech**: PlantNet + Foundation Models para cálculo.

#### 💡 Idea 86: **Indoor / Outdoor ratio estimator**
- **Quién beneficia**: Cualquier ocupante de vivienda urbana.
- **Qué hace**: CoreML modelo que estima PM2.5 indoor basado en: outdoor PM2.5 + tipo de vivienda (input onboarding) + tiempo desde última ventilación. Sin sensor — solo datos ya disponibles.
- **Tech**: `MLRegressor` entrenado con literatura I/O ratios.

---

## <a id="ideas-transversales"></a>4. Ideas transversales (sirven a TODAS las poblaciones)

### 🧠 IA on-device (Foundation Models iOS 26)

#### 💡 Idea 87: **Asistente conversacional "Abuelita AI"**
- Chat embebido con Foundation Models 3B (on-device, gratis, offline, privado).
- Preguntas típicas: "¿Puedo salir a comprar tortillas?", "¿Está bien que mi niño juegue en el parque?", "¿Por qué mi abuela tose más hoy?".
- Tool calling: llama RAMA, TEMPO, Open-Meteo, ENSANUT.
- Grounded en el perfil del usuario (VulnerabilityProfile existente).

#### 💡 Idea 88: **Resumen semanal dictado**
- Foundation Models + `AVSpeechSynthesizer` cada domingo narra: "Esta semana respiraste aire equivalente a 4 cigarrillos. Lunes fue el peor día. Mejor momento fue sábado 8am".
- Acción: "¿Quieres que te recuerde evitar salir a estas horas la próxima semana?".

### 🎤 SoundAnalysis creativo

#### 💡 Idea 89: **Traffic noise → PM2.5 estimator**
- Micrófono de iPhone clasifica ruido de tráfico (diésel vs gasolina vs híbrido) y estima PM2.5 local con R²≈0.93.
- Llena huecos donde no hay estación RAMA cercana.
- Paper: Acoustic classification of vehicle fuel types (2025).

#### 💡 Idea 90: **Alarm clock climático**
- Alarma que en vez de sonido despertador anuncia contexto del día: "Buenos días, AQI 45 hoy, moderado. Tu trayecto al trabajo tardará 22 min — ve por Reforma mejor, 30 µg/m³ menos".
- Foundation Models + WeatherKit + geofencing.

### 👁 Vision creativo

#### 💡 Idea 91: **Foto del cielo → AQI estimator**
- Usuario toma foto hacia el cielo. CLIP + Core ML mapean a PM2.5.
- Útil donde no hay estaciones (rural) o para validar sensación vs datos oficiales.
- Paper: AQE-Net (Remote Sensing 2022) y hackAIR dataset.

#### 💡 Idea 92: **Quema al aire libre — Reporte ciudadano**
- Foto de humo/hoguera/quema de basura → clasificador + geolocalización → push a Protección Civil.
- Convierte ciudadanos en red de sensores distribuida.

### 💬 Anti-misinformation

#### 💡 Idea 93: **Detector de fake news de contaminación**
- Usuario pega mensaje WhatsApp dudoso. RAG con datos SEMARNAT/SINAICA/OMS → veredicto: VERDADERO / FALSO / NO VERIFICABLE + fuentes.
- Paper: BMC Public Health 2025 AI misinformation.

### 📣 Acción política

#### 💡 Idea 94: **Carta auto-generada a diputado**
- Foundation Models redacta carta formal en español legal: "Estimado Dip. [X], en mi colonia [RAMA estación] hemos rebasado NOM-025 los últimos [Y] días. Solicito acción...".
- mailto: deep-link con plantilla lista.
- Inédito en CDMX según Inside Climate News 2025.

#### 💡 Idea 95: **Mapa de denuncia ciudadana**
- Tipo 311: foto + geotag + categoría (quema, escape excesivo, fábrica) → aggregate en mapa público.
- Pressure tool para gobierno local.
- Modelo VAYU (UNDP India).

### 🌐 Eco-ansiedad (Nuevo iOS 26 HealthKit)

#### 💡 Idea 96: **"State of Mind" climático**
- iOS 26 HealthKit tiene `stateOfMind`. AirWay lee el estado + correlaciona con días de alerta ambiental.
- Si detecta pattern de ansiedad climática (eco-ansiedad): ofrece coaching con Foundation Models basado en Good Grief Network 10-step (marco validado).
- GUARDRAIL: NO crea dependencia, no simula terapeuta. Apunta a recursos locales IMSS/psicólogos.
- Paper: Psychiatric Services 2024 "Digital Mental Health Innovations + Climate Change".

### 📊 Federated learning

#### 💡 Idea 97: **Red neuronal colectiva sin comprometer privacidad**
- Cada iPhone entrena mini-modelo local. Solo gradientes van al backend.
- Backend (Flower/PySyft) agrega → modelo global más preciso cada semana.
- Paper: IEEE Geo. RS 2025 "Multimodal Federated Learning for Air Quality".

### 🔬 Dosímetro personal

#### 💡 Idea 98: **Mi AirScore semanal**
- Cumulative exposure = dosis semanal normalizada. Visualización tipo Apple Activity rings.
- Tres anillos: PM2.5 (meta OMS 5 µg/m³ anual), O3 (meta 100 µg/m³ 8h), NO2 (meta 10 µg/m³ anual).
- Comparación con vecinos (anónimo agregado) para motivación social.

### 🎨 Visualización emocional

#### 💡 Idea 99: **Cielo-metrómetro — Live Activity**
- Live Activity en Lock Screen que muestra cielo animado con tono emocional según AQI. Cielo azul limpio = calma. Cielo amarillo/gris = precaución. Cielo púrpura = alarma.
- Dynamic Island en iPhone 15+ con emoji contextual.

#### 💡 Idea 100: **Sonido del aire (sonificación)**
- Canción ambient generada dinámicamente según AQI: notas más agudas + disonancia aumenta con PM2.5.
- Opción: reemplaza el sonido de alarma/despertador.
- Accesibilidad para personas con daltonismo.

---

## <a id="integracion-gobierno"></a>5. Integración con datos gubernamentales mexicanos

**Stack de APIs cero-fricción (sin autenticación corporativa):**

```python
# backend-api/src/adapters/gov/
# Todas son gratis, algunas requieren registro simple

PROVIDERS = {
    "rama_cdmx": "http://datosabiertos.aire.cdmx.gob.mx:8080/opendata/anuales_horarios_gz/contaminantes_{YEAR}.csv.gz",
    "sinaica": "https://sinaica.inecc.gob.mx/",  # scraping
    "conagua_smn": "https://smn.conagua.gob.mx/webservices/?method=3",  # JSON, 48h, update 1h15min
    "firms_nasa": "https://firms.modaps.eosdis.nasa.gov/api/area/csv/{MAP_KEY}/VIIRS_SNPP_NRT/-120,15,-85,35/1",
    "tempo_nasa": "https://asdc.larc.nasa.gov/project/TEMPO",  # ya integrado
    "cams_copernicus": "https://ads.atmosphere.copernicus.eu/api/v2/",  # registro gratis
    "ecobici_gbfs": "https://gbfs.mex.lyftbikes.com/gbfs/gbfs.json",
    "denue_inegi": "https://www.inegi.org.mx/app/api/denue/v1/consulta/buscar/{COND}/{LAT,LON}/{M}/{TOKEN}",
    "inegi_indicadores": "https://www.inegi.org.mx/app/api/indicadores/",
    "coneval_ageb": "shapefile/CSV descarga directa",
    "sedema_pronostico": "https://www.aire.cdmx.gob.mx/pronostico-aire/pronostico-por-contaminante.php",  # scraping
    "ensanut_insp": "https://ensanut.insp.mx/encuestas/ensanutcontinua2024/",  # CSV/SPSS
    "cubos_dgis": "http://www.dgis.salud.gob.mx/contenidos/basesdedatos/BD_Cubos_gobmx.html",
    "purpleair": "https://api.purpleair.com/",  # key read-only gratis
}
```

### Ideas específicas de integración

- **RAMA horario granular** → reemplaza WAQI para CDMX (resolución minuto, no hora).
- **FIRMS incendios** → alerta cuando hay incendio <100km de CDMX que impactará PM2.5 en 6h.
- **CONAGUA SMN** → ya usas Open-Meteo, agrega SMN como cross-validation (fuente oficial MX).
- **DENUE** → reemplaza búsquedas "farmacia cercana" con el dataset oficial 5M establecimientos.
- **CONEVAL AGEB** → capa de justicia ambiental en mapa (idea 68).
- **ENSANUT** → entrena modelo de prevalencia asma por AGEB para personalización inicial.
- **SEDEMA scraping** → ensemble con tu GradientBoosting para mejorar forecast.

---

## <a id="stack-tecnico"></a>6. Stack técnico recomendado (iOS 26)

### Apple Intelligence Foundation Models Framework

```swift
import FoundationModels

// Pattern @Generable para structured output
@Generable
struct AirAdvice {
    let shouldGoOutside: Bool
    let reason: String
    let specificActions: [String]
    let urgency: UrgencyLevel
}

@Generable
enum UrgencyLevel {
    case informational, moderate, critical
}

// Ejemplo de uso
let session = LanguageModelSession(instructions: """
    Eres un asistente de salud ambiental en español mexicano.
    Explica a nivel primaria, sin jerga técnica.
    Prioriza seguridad de poblaciones vulnerables.
""")

let advice = try await session.respond(
    to: "AQI 145 en Iztapalapa, usuaria embarazada 28 semanas",
    generating: AirAdvice.self
)
```

**Ventajas HCAI**:
- On-device = privacidad total (no manda location a Gemini)
- Gratis = escalable a millones sin cost/token
- Offline = funciona en metro, áreas rurales
- 3B parámetros = suficiente para tareas estructuradas

### CoreML on-device training (iOS 26)

```swift
import CoreML

// MLUpdateTask para personalización
let updateTask = try MLUpdateTask(
    forModelAt: modelURL,
    trainingData: userPersonalData,
    configuration: MLModelConfiguration(),
    completionHandler: { context in
        // Modelo actualizado con datos DEL usuario
        // Nunca deja el dispositivo
    }
)
```

### Vision framework patterns

```swift
// Foto del cielo → AQI
let request = VNClassifyImageRequest { request, error in
    // Modelo custom entrenado en hackAIR dataset
}

// Detección de humo visible
let smokeRequest = VNGenerateImageFeaturePrintRequest()

// Lectura OCR de etiqueta producto
let textRequest = VNRecognizeTextRequest()
```

### SoundAnalysis patterns

```swift
import SoundAnalysis

// Detección de tos nocturna (Hyfe-style)
let coughClassifier = try MLModel(contentsOf: coughModelURL)
let soundRequest = try SNClassifySoundRequest(mlModel: coughClassifier)

// Clasificación de tráfico (diésel vs gasolina)
let trafficRequest = try SNClassifySoundRequest(mlModel: trafficModel)
```

### WidgetKit Live Activities

```swift
// Live Activity en Lock Screen + Dynamic Island
struct AirQualityActivity: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var aqi: Int
        var trend: Trend
        var recommendation: String
    }
}
```

---

## <a id="priorizacion"></a>7. Priorización para hackathon (2 días)

### Tier 1: MUST-HAVE (construir primero, ~6-8h)
| # | Idea | Por qué | Horas |
|---|---|---|---|
| **83** | "¿Abro la ventana?" | Pregunta universal, 1 pantalla, impacto máximo | 2h |
| **69** | Modo "Explica como abuelita" | Foundation Models visible al jurado | 2h |
| **51** | Modo Cuidador (adultos mayores) | Narrativa HCAI perfecta + CloudKit | 3h |
| **60** | Modo Informal (vendedor ambulante) | Diferenciador vs cualquier app comercial | 2h |

### Tier 2: DIFFERENTIATORS (si hay tiempo, ~4-6h)
| # | Idea | Por qué |
|---|---|---|
| **47** | Modo Gestación (embarazadas) | Población desatendida + alto impacto |
| **55** | ¿Recreo afuera? (escuelas) | Integra con programa SEDEMA existente |
| **99** | Live Activity con emoción | Visual demo-friendly |
| **66** | Modo Fogón (leña) | Incluye comunidades rurales/indígenas |
| **68** | Mapa justicia ambiental | Mensaje político fuerte |

### Tier 3: NICE-TO-HAVE (solo si sobra tiempo)
| # | Idea | Por qué |
|---|---|---|
| 71 | Modo Chofer (recirculación) | Cuando encuentres conductor Uber en calle |
| 81 | Modo Perro | Crowd-pleaser demo |
| 93 | Detector fake news | Polémico pero memorable |
| 100 | Sonido del aire | Accesibilidad creativa |

### Orden recomendado día-por-día

**Día 1 (sábado) — 10 horas efectivas:**
- 9-11am: Setup Foundation Models + `@Generable` structs (1 dev)
- 9-11am: Expandir `VulnerabilityProfile` con pregnancyWeek, elderly_dependent, informal_worker (1 dev)
- 9-11am: Diseñar 3 pantallas Tier 1 en Figma (diseñador)
- 11am-2pm: Idea 83 "¿Abro la ventana?" end-to-end
- 3-6pm: Idea 69 "Explica como abuelita" en todas las vistas existentes
- 7-10pm: Idea 51 Modo Cuidador con CloudKit

**Día 2 (domingo) — 8 horas efectivas:**
- 9-12pm: Idea 60 Modo Informal (vendedor ambulante) + DENUE
- 12-2pm: Idea 47 Modo Gestación con prompt trimestral
- 2-4pm: Idea 99 Live Activity con tono emocional
- 4-6pm: Integrar RAMA real data (idea 55 como demo)
- 6-8pm: Grabar demo 3-min, pulir narrativa HCAI, slide deck

### Narrativa HCAI para pitch (3 min)

> "Las apps de calidad del aire actuales fallan con el 70% de los mexicanos: vendedores ambulantes que no pueden quedarse en casa, embarazadas sin app prenatal ambiental, cuidadores que no saben cuándo preocuparse por su abuela, familias que cocinan con leña y no conocen el riesgo.
>
> AirWay usa Apple Intelligence on-device para **servir a quien ninguna app comercial atiende**. Foundation Models traduce AQI técnico a 'español-abuelita'. CoreML entrena un modelo personal de asma sin que tus datos salgan del iPhone. La cámara detecta cocinas sin chimenea. El micrófono distingue tráfico diésel de gasolina.
>
> No reemplazamos al médico ni al gobierno — les damos herramientas. No decidimos por ti — te informamos. Y cuando tu abuela no sabe usar la app, tu primo puede recibir la alerta por ella.
>
> Esto es HCAI: tecnología que abraza la desigualdad de México en lugar de ignorarla."

---

## <a id="fuentes"></a>8. Apéndice: Fuentes

### Pain points México
- [Infobae Contingencia 2025](https://www.infobae.com/mexico/2025/01/07/cdmx-esta-cerca-de-su-segunda-contingencia-ambiental-de-2025-tres-alcaldias-registran-mala-calidad-del-aire/)
- [UNAM Atmósfera 2025](https://www.atmosfera.unam.mx/en-2025-la-mala-calidad-del-aire-podria-ser-mas-extrema-en-cdmx/)
- [PMC Air pollution preterm Mexico](https://pmc.ncbi.nlm.nih.gov/articles/PMC3594336/)
- [Prenatal PM2.5 neurodesarrollo CDMX](https://pmc.ncbi.nlm.nih.gov/articles/PMC8759610/)
- [ISGlobal ruta escolar](https://www.isglobal.org/-/la-exposicion-a-la-contaminacion-atmosferica-en-el-trayecto-a-la-escuela-perjudica-a-la-memoria-de-trabajo-de-los-ninos)
- [Animal Político banderines](https://animalpolitico.com/sociedad/banderines-colores-calidad-aire-escuelas-cdmx)
- [IDB unequal effects](https://blogs.iadb.org/ideas-matter/en/the-unequal-effects-of-air-pollution-on-health-and-income-in-mexico-city/)
- [DataMéxico ambulantes](https://www.economia.gob.mx/datamexico/es/profile/occupation/vendedores-ambulantes)
- [Silicosis CDMX 2025](https://consultorsalud.com.mx/silicosis-en-mexico-riesgo-que-reaparece/)
- [Revista Alergia MX outdoor workers](https://www.revistaalergia.mx/ojs/index.php/ram/article/download/1463/2745)
- [Taxistas black carbon](https://www.infosalus.com/salud-investigacion/noticia-taxistas-soportan-niveles-mas-altos-contaminacion-otros-conductores-profesionales-20190930070534.html)
- [La Jornada 1/5 población leña](https://www.jornada.com.mx/2024/01/03/economia/020n1eco)
- [INSP fogones](https://insp.mx/assets/documents/webinars/2021/CISP_Humolena.pdf)
- [Cambridge PM2.5 poorer localities](https://www.cambridge.org/core/journals/environment-and-development-economics/article/is-air-pollution-increasing-in-poorer-localities-of-mexico-evidence-from-pm-25-satellite-data/E42F78970E25DF7B65FD85221E6FD131)
- [BMC AQI awareness CDMX](https://link.springer.com/article/10.1186/s12889-018-5418-5)
- [8.5M asma IMSS](https://www.gob.mx/salud/prensa/331-en-mexico-8-5-millones-de-personas-viven-con-asma-iner)
- [OHCHR derechos humanos 2026](https://www.ohchr.org/es/press-releases/2026/03/air-pollution-driving-widespread-human-rights-violations-un-expert)

### IA / Papers
- [Multimodal PM Prediction MDPI 2025](https://www.mdpi.com/1424-8220/25/13/4053)
- [Sky images VLM arXiv 2509.15076](https://arxiv.org/abs/2509.15076)
- [Federated Air Quality IEEE 2025](https://ieeexplore.ieee.org/document/10975802/)
- [Apple Foundation Models Framework](https://developer.apple.com/documentation/FoundationModels)
- [Apple Foundation Tech Report 2025](https://machinelearning.apple.com/research/apple-foundation-models-tech-report-2025)
- [Acoustic vehicle classification 2025](https://www.sciencedirect.com/science/article/pii/S2405844025018110)
- [AirPredict Frontiers 2025](https://www.frontiersin.org/journals/digital-health/articles/10.3389/fdgth.2025.1573342/full)
- [AI Asthma Guard MDPI 2024](https://www.mdpi.com/2571-5577/7/5/78)
- [RAND youth AI chatbots 2025](https://www.rand.org/news/press/2025/11/one-in-eight-adolescents-and-young-adults-use-ai-chatbots.html)
- [Digital Mental Health Climate Change](https://psychiatryonline.org/doi/10.1176/appi.ps.20240327)
- [Transport Mode TCN Sensors 2022](https://www.mdpi.com/1424-8220/22/17/6712)
- [AirPods respiratory rate research](https://appleinsider.com/articles/21/08/12/apple-researchers-use-airpods-to-estimate-user-respiratory-rates)
- [DeepVision Indoor AQ 2024](https://www.sciencedirect.com/science/article/pii/S2352710224000986)
- [AmericasNLP 2025](https://aclanthology.org/volumes/2025.americasnlp-1/)
- [Google Maya/Nahuatl/Zapoteco](https://mexiconewsdaily.com/culture/indigenous-languages-maya-zapotec-and-nahuatl-google-translate/)
- [UNDP VAYU](https://www.undp.org/india/blog/mapping-invisible-understanding-air-pollution-through-citizen-science)
- [Hyfe cough monitor PMC 2025](https://pmc.ncbi.nlm.nih.gov/articles/PMC11809693/)
- [BMC AI health misinformation 2025](https://link.springer.com/article/10.1186/s12889-025-26148-9)
- [Personalized health air response arXiv](https://arxiv.org/html/2505.10556v2)
- [AQE-Net mobile AQ estimation](https://www.mdpi.com/2072-4292/14/22/5732)

### Datos gubernamentales
- [Datos Abiertos CDMX SIMAT](https://datos.cdmx.gob.mx/dataset/?organization=secretaria-de-medio-ambiente&tags=SIMAT)
- [SINAICA](https://sinaica.inecc.gob.mx/)
- [ENSANUT Continua 2024](https://ensanut.insp.mx/encuestas/ensanutcontinua2024/index.php)
- [CONAGUA SMN Web Service](https://smn.conagua.gob.mx/es/web-service-api)
- [NASA FIRMS API](https://firms.modaps.eosdis.nasa.gov/api/)
- [TEMPO Earthdata](https://www.earthdata.nasa.gov/data/instruments/tempo)
- [Ecobici Open Data](https://ecobici.cdmx.gob.mx/en/open-data/)
- [Hoy No Circula](https://hoynocircula.cdmx.gob.mx/)
- [Áreas Verdes CDMX](https://datos.cdmx.gob.mx/dataset/inventario-de-areas-verdes-en-la-ciudad-de-mexico)
- [CONEVAL AGEB 2020](https://www.coneval.org.mx/Medicion/IRS/Paginas/Rezago_social_AGEB_2020.aspx)
- [INEGI DENUE API](https://www.inegi.org.mx/servicios/api_denue.html)
- [DGIS Cubos](http://www.dgis.salud.gob.mx/contenidos/basesdedatos/BD_Cubos_gobmx.html)
- [Open-Meteo Air Quality](https://open-meteo.com/en/docs/air-quality-api)
- [WAQI API](https://aqicn.org/api/)
- [OpenAQ v3](https://docs.openaq.org)
- [AireCDMX App Store reviews](https://apps.apple.com/mx/app/airecdmx/id1666987005)

---

## Totales

- **54 ideas NUEVAS** (47-100) que complementan las 46 previas
- **10 poblaciones vulnerables** específicamente atendidas
- **15 APIs mexicanas** listadas para integración
- **40+ papers** 2024-2026 como base científica
- **Tier 1 priorizado** = 4 ideas implementables en 10h

Listo para iterar contigo. Dime qué ideas quieres expandir a detalle (como hicimos con la Idea 5).
