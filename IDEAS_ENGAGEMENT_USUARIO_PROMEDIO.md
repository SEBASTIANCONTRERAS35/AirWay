# AirWay — Ideas de Engagement para Usuario Promedio

**Objetivo:** Que un joven de 25 años, sano, sin asma, sin embarazo, **no pueda ignorar** la app.
**Método:** Psicología del comportamiento + IA + vanidad + estatus social + dopamine.

---

## Tabla de contenido

1. [El problema real](#problema)
2. [Principios de diseño](#principios)
3. [Ideas por MECANISMO PSICOLÓGICO](#mecanismos)
   - [💀 Miedo visceral (loss aversion)](#miedo)
   - [💅 Vanidad estética (cara, piel, voz)](#vanidad)
   - [🏆 Estatus social y competición](#estatus)
   - [🎮 Gamificación y dopamine](#gamificacion)
   - [📱 Narrativa personal e identidad](#narrativa)
   - [🔮 Predicción personal visceral](#prediccion)
   - [🧪 Curiosidad y revelación](#curiosidad)
   - [💸 Impacto económico personal](#economico)
   - [⏮️ Comparación temporal (infancia, futuro)](#temporal)
   - [🎨 Visual / AR / Visceral](#visual)
   - [🔗 Social y compartible (viral)](#viral)
   - [🧠 Integración mental/emocional](#mental)
4. [Hook pattern aplicado (Nir Eyal)](#hook)
5. [Priorización — Tier viralidad](#priorizacion)

---

## <a id="problema"></a>1. El problema real

### Por qué las apps de calidad del aire FALLAN con usuarios promedio

| Razón | Evidencia |
|---|---|
| **"No soy vulnerable"** | 80% de usuarios jóvenes piensan que la contaminación no les afecta |
| **Números abstractos** | "PM2.5: 45 µg/m³" no activa ninguna emoción |
| **Aburrido** | Dashboards = formato de reporte = skip |
| **Sin acción inmediata** | "Evita ejercicio intenso" = ya lo leí en otra app |
| **Sin stakes personales** | No hay nada que PERDER por ignorar |
| **No compartible** | Nadie screenshot-ea un AQI number |

### Lo que SÍ engancha (apps ganadoras)

| App | Mecanismo | Por qué funciona |
|---|---|---|
| **Spotify Wrapped** | Narrativa personal anual | Cero valor práctico. 100% vanidad + identidad |
| **Duolingo** | Streaks + búho amenazante | Pérdida social si rompes racha |
| **Strava** | Comparación con vecinos | "Tu vecino corrió más km que tú" |
| **Instagram filters** | Vanidad instantánea | Ver tu cara mejorada/modificada |
| **Apple Health rings** | 3 círculos simples + streak | Feedback visual minimalista |
| **Tinder** | Swipe + variable reward | Dopamine impredecible |
| **BeReal** | FOMO diario | Push temporal obligatorio |
| **TikTok** | Infinite scroll + dopamine | Contenido infinito personalizado |

**Lección**: copiar estos mecanismos con data de aire, no inventar nuevos.

---

## <a id="principios"></a>2. Principios de diseño para usuario promedio

1. **Personal > genérico**: Nunca "AQI en CDMX es 85". Siempre "TÚ respiraste 2.3 cigarrillos hoy".
2. **Visceral > abstracto**: Cucharadas, cigarros, años perdidos, cara envejecida. NO microgramos.
3. **Pérdida > ganancia**: "Restando 14 meses a tu vida" > "Ganarías salud".
4. **Social > solo**: Comparación con amigos, vecinos, ciudad.
5. **Diario > semanal**: Trigger todos los días, no solo contingencias.
6. **Compartible > privado**: Cada pantalla debe funcionar como screenshot.
7. **Breve > explicativo**: 1 frase de impacto, no 3 párrafos educativos.
8. **Vanidad > moralismo**: Tu piel, tu cara, tu voz — NO "protege el planeta".

---

## <a id="mecanismos"></a>3. Ideas por MECANISMO PSICOLÓGICO

---

### <a id="miedo"></a>💀 Miedo visceral (Loss Aversion)

> *"La gente cambia 2.5x más rápido por miedo a perder que por ganar algo" — Kahneman*

#### 💡 Idea 101: **Tu cuenta regresiva de vida**
- **Qué hace**: Pantalla principal con contador: "Te quedan **23 años, 4 meses, 12 días**" basado en tu PPI personal + exposición acumulada. Baja en tiempo real.
- **Cálculo**: Actuarial-style usando meta-análisis PM2.5 mortality (cada 10 µg/m³ = −1.03 años expectativa). Tu promedio de exposición × edad = descuento personal.
- **Visceral**: El contador baja visiblemente. No puedes NO mirarlo.
- **HCAI/Ético**: Disclaimer "Estimación estadística. No diagnóstico". Opcional apagar.
- **Tech**: Foundation Models genera el cálculo + explicación. Live Activity en Lock Screen.

#### 💡 Idea 102: **Receta médica invisible**
- **Qué hace**: "Hoy tu cuerpo procesó inflamación equivalente a **2 Advil**. Esta semana: **14 Advil**".
- **Mapping**: PM2.5 exposure → CRP inflammation markers → ibuprofen-equivalent dose (peer-reviewed).
- **Por qué funciona**: Todos entienden Advil. Nadie entiende µg/m³.

#### 💡 Idea 103: **Edad pulmonar biológica**
- **Qué hace**: "Tienes 25 años. Tus pulmones tienen **34 años**". Con gráfica de progresión.
- **Cálculo**: CoreML usando HealthKit FEV1 proxy (respiratory rate + SpO2 trend) + exposición acumulada.
- **Paper base**: Spirometric age formulas existen desde 2010.
- **Visceral**: 9 años de diferencia duele.

#### 💡 Idea 104: **La lotería del asma**
- **Qué hace**: "Tu probabilidad de desarrollar asma en los próximos 5 años: **18%**" (vs promedio 8%).
- **Modelo**: CoreML personal entrenado con ENSANUT + exposición + HealthKit RR baseline.
- **HCAI**: Muestra IC 95%, fuente de predicción, cómo bajarlo.

#### 💡 Idea 105: **Tu fumador invisible**
- **Qué hace**: "Sin fumar, hoy inhalaste el equivalente a **3.2 cigarros Marlboro Light**".
- **Ya existe** `CigaretteEquivalenceEngine` — solo hay que hacerlo visible en LIVE ACTIVITY + widget + notificación diaria 9pm.
- **Animación**: Cigarrillos acumulándose en un cenicero virtual.
- **Compartible**: Screenshot del cenicero = WhatsApp-friendly.

#### 💡 Idea 106: **Tu última llamada limpia**
- **Qué hace**: "Última vez que respiraste aire OMS-recomendable: hace **47 días**".
- **Psicología**: Conteo de pérdida explícito. Te recuerda cuánto tiempo has aguantado aire sucio.
- **Tech**: Tracking histórico de AQI en tu ubicación.

---

### <a id="vanidad"></a>💅 Vanidad estética (Cara, Piel, Voz)

> *"La gente gastará $300 en skincare pero ignora $0 en air care. Regla: secuestrar el budget de vanidad."*

#### 💡 Idea 107: **Tu cara contaminada en 10 años** ⭐
- **Qué hace**: Tomás selfie. IA genera tu rostro en 10 años con progresión realista basada en tu exposición actual: arrugas de estrés oxidativo, manchas por PM2.5, pérdida de elasticidad.
- **Tech**: On-device image generation + Apple Intelligence + CoreML aging model. Research: "Air pollution accelerates skin aging" (J Invest Dermatol 2010-2024).
- **Viralidad**: El filtro Instagram perfecto. 10/10 screenshot rate.
- **Comparación split**: tu cara "limpia" vs tu cara "contaminada". Como app FaceApp pero basada en datos reales tuyos.

#### 💡 Idea 108: **Tu piel + PM2.5 tracker**
- **Qué hace**: Selfie semanal. Vision framework detecta acné, rojez, brillo. Correlaciona con PM2.5 semanal. "Tu acné sube 40% los días contaminados".
- **Tech**: `VNDetectFaceLandmarksRequest` + skin analysis custom CoreML + historial HealthKit.
- **Mercado probado**: Apps skincare (TrueMe, YouCam) tienen millones de usuarios. Sumar aire.

#### 💡 Idea 109: **Tu voz envejecida**
- **Qué hace**: Grabas 10 segundos leyendo una frase. IA sintetiza cómo sonará tu voz en 20 años con tu exposición actual (raspada, bronquial).
- **Tech**: iOS 26 Speech Synthesis + voice aging ML + on-device generation.
- **Compartible**: Audio clip virales en redes. "Así sonarás a los 45".

#### 💡 Idea 110: **Tu pelo contaminado**
- **Qué hace**: Dice cuánto PM2.5 se acumula en tu cabello diariamente según tu tiempo afuera. Visualiza como "polvo invisible". Sugiere horario ideal para lavarlo (no cuando recién entraste, sino después de X horas).
- **Tech**: Cálculo simple basado en OSHA dermal deposition rates.

#### 💡 Idea 111: **Tu ropa después del día**
- **Qué hace**: Al final del día fotografías tu playera/camisa blanca. Vision detecta particulado visible + compara con mañana.
- **Visceral**: "Tu ropa tiene 3x más polvo que la semana pasada. Algo cambió en tu ruta".

---

### <a id="estatus"></a>🏆 Estatus social y competición

> *"Strava ganó comparando tu km con los de Juan. AirWay puede ganar comparando tu aire con el de tus amigos."*

#### 💡 Idea 112: **Leaderboard del aire — Rank vs amigos**
- **Qué hace**: Lista tipo Strava: "Tú respiras peor que **7 de tus 10 amigos**". Basado en GPS + AQI por ubicación.
- **Tech**: CloudKit sharing + ranking algoritm por exposición semanal.
- **Trigger semanal**: Notificación domingo: "Hugo mejoró esta semana. Tú bajaste 3 puestos".

#### 💡 Idea 113: **Rank vs tu ciudad**
- **Qué hace**: "Eres el usuario **#12,340 más expuesto** en CDMX (top 25% peor)". Desglose por alcaldía.
- **Psicología**: Nadie quiere estar abajo en ningún ranking.

#### 💡 Idea 114: **Medallero de colonia**
- **Qué hace**: Tu colonia/AGEB tiene un score colectivo. Rank vs otras colonias. "Roma Norte está en **lugar 847**. Anímala con tus vecinos".
- **Tech**: Agregado anónimo con k-anonymity (no revela usuarios individuales).
- **Civic impact**: Presión social vecinal por mejores políticas.

#### 💡 Idea 115: **Celebridad del aire**
- **Qué hace**: "Tu exposición es similar a la de **Peso Pluma** (vive en Jalisco, bajo)" o "**Tu alcaldía tiene peor aire que la Cuarta Transformación**" (datos públicos de ubicación de gobernantes).
- **Viralidad**: El chisme político + ambiental combinado.

#### 💡 Idea 116: **Match ambiental (Tinder-style)**
- **Qué hace**: Swipe cards: "Este match vive en Coyoacán (AQI 45). Tú vives en Iztapalapa (AQI 95). ¿Citas indoor o outdoor?". Para apps de dating, API pública.
- **Spin-off**: widget para Bumble/Tinder con tu "aire score".

#### 💡 Idea 117: **Embajador de oxígeno**
- **Qué hace**: Niveles sociales: Novato → Embajador → Maestro del aire. Ganas puntos compartiendo rutas limpias con amigos. Status visible en perfil.
- **Mecánica**: Referral con recompensa tangible (3 amigos = premium gratis 1 mes).

---

### <a id="gamificacion"></a>🎮 Gamificación y dopamine

> *"Apple Activity Rings cerraron + de 1 billón de rings. 3 círculos. 0 educación. Puro dopamine."*

#### 💡 Idea 118: **AirRings — 3 anillos respiratorios**
- **Qué hace**: Copia Apple Activity rings pero con:
  - 🔴 Anillo exposure (límite diario OMS)
  - 🟡 Anillo ventilation (abrir ventana 3x día)
  - 🟢 Anillo clean-minutes (minutos en aire <50 AQI)
- Cierra los 3 = celebración con animación.
- **Tech**: WidgetKit + HKActivitySummary-style custom.

#### 💡 Idea 119: **Streaks de respiración limpia** 
- **Qué hace**: "Llevas **23 días** manteniendo exposición bajo límite personal". Duolingo-style, incluyendo el búho que te amenaza.
- **Pérdida social**: "Si no entras mañana, pierdes tu racha". Shame + loss aversion.
- **Recuperación**: "Freeze token" comprable con engagement.

#### 💡 Idea 120: **Tamagotchi ambiental — "Tu Aira"**
- **Qué hace**: Criatura virtual que vive en tus pulmones. Si respiras limpio, Aira está feliz/azul. Si respiras sucio, se pone gris/triste/enferma.
- **Mecánica**: Hay que "alimentarla" con horas de aire limpio. Si no, puede "morir" y reiniciar.
- **Referencia**: Pou, Neko Atsume, Pokémon Go.

#### 💡 Idea 121: **Badges coleccionables diarios**
- **Qué hace**: Cada día un badge único con arte procedural según tu aire + ubicación + hora. Colección NFT-style (sin blockchain, solo local).
- **FOMO**: "Hoy es Martes 16 abril — badge ÚNICO disponible hasta medianoche".

#### 💡 Idea 122: **Micro-misiones diarias**
- **Qué hace**: 3 retos fáciles cada día:
  1. "Camina 500m en ruta limpia (por parque)"
  2. "Abre la ventana en ventana óptima"
  3. "Identifica un síntoma hoy (tos, dolor cabeza, fatiga)"
- Completar = XP + progreso semanal.
- **Tech**: Foundation Models genera retos personalizados al contexto.

#### 💡 Idea 123: **AirChallenge con amigos**
- **Qué hace**: 7 días de reto colectivo. "Tú + 3 amigos: bajar exposición colectiva 20%". App mide. Ganador = foto grupal con certificado.
- **Mecánica**: Equipos + leaderboard interno + chat grupal integrado.

#### 💡 Idea 124: **Spin-the-wheel matutino**
- **Qué hace**: Cada mañana spinnea la ruleta: recibes 1 tip personalizado + micro-reto del día. Variable reward = dopamine.

---

### <a id="narrativa"></a>📱 Narrativa personal e identidad

> *"Spotify Wrapped es la pieza de marketing más viral del mundo. CERO utilidad. 100% identidad."*

#### 💡 Idea 125: **Air Wrapped — Resumen semanal/anual** ⭐
- **Qué hace**: Cada domingo (o fin de año) una story tipo Instagram/Spotify Wrapped:
  - "Tu semana en el aire"
  - "Tu ruta más peligrosa: Eje Central (PM2.5: 142)"
  - "Tu día más limpio: Sábado 8am (AQI 28)"
  - "Cigarros equivalentes: 17.3 🚬"
  - "Tu ranking vs amigos: #4/10"
  - "Tu playlist: canciones que escuchaste en días limpios"
- **Formato**: Stories animadas verticales 9:16, perfectas para IG/WhatsApp.
- **Tech**: Foundation Models genera copy + SwiftUI animations.

#### 💡 Idea 126: **Mini documental mensual de ti**
- **Qué hace**: 30 segundos de video generado por IA: narrativa con voiceover + fotos tuyas + mapas animados de tu mes. Título: "Abril 2026: Tu historia con el aire".
- **Tech**: Foundation Models narrativa + video generation + on-device rendering.

#### 💡 Idea 127: **Tu air personality type**
- **Qué hace**: Test 10 preguntas (tipo 16personalities) → te asigna un tipo:
  - "The Night Owl Urbano"
  - "The Outdoor Warrior"
  - "The Home Hermit"
  - "The Commuter Martyr"
- Perfil shareable con avatar único + recomendaciones específicas.

#### 💡 Idea 128: **Alma ambiental**
- **Qué hace**: Perfil continuo: "Eres un *Metro Worker Expuesto*: trabajas lejos, commuteas 90 min, tu alma respira 1.8x el promedio capitalino".
- **Tech**: Foundation Models + personalización profunda + updates mensuales.

#### 💡 Idea 129: **Tu diario respiratorio**
- **Qué hace**: Journaling integrado con iOS 26 Journal. Entrada diaria auto-generada + campo de texto libre: "Hoy tuve migraña — AirWay correlacionó con NO2 pico a las 3pm. Tu cuerpo te dijo algo que ignoraste".

---

### <a id="prediccion"></a>🔮 Predicción personal visceral

> *"Saber que MAÑANA te va a doler la cabeza antes de que pase = magia."*

#### 💡 Idea 130: **Pronóstico de mal humor**
- **Qué hace**: "Mañana: **60% prob de irritabilidad** por contaminación + poco sueño". Basado en tu patrón histórico iOS 26 `stateOfMind` + AQI forecast.
- **Tech**: CoreML regression + iOS 26 mental health data.
- **Por qué pega**: Le da al usuario una explicación para emociones que ignora.

#### 💡 Idea 131: **ETA de tu dolor de cabeza**
- **Qué hace**: "Dolor de cabeza estimado en **3 horas** si no te mueves del lugar actual" (basado en tu patrón personal de migrañas + AQI creciente).
- **Accionable**: "Cambia de ambiente ahora y evitarás el 80% del riesgo".

#### 💡 Idea 132: **Tu productividad del día**
- **Qué hace**: "Hoy tu productividad bajará **~15%** por exposición matutina". Basado en estudios PM2.5 → cognitive performance.
- **Paper**: "Air pollution and cognitive performance" (PNAS 2018-2024).
- **Viral**: Trabajadores oficinas adoran justificar su bajo rendimiento.

#### 💡 Idea 133: **Horóscopo ambiental diario**
- **Qué hace**: Formato tipo horóscopo: "Iztapalapa Aries: hoy tu aire te sacudirá. Mueve tu café a las 10am para evitar O3 pico". Lenguaje juguetón.
- **Tech**: Foundation Models con prompt "horóscopo" + datos reales.

#### 💡 Idea 134: **Tu rendimiento ejercicio del día**
- **Qué hace**: Antes de salir a correr: "Si corres ahora, tu cuerpo absorberá **5.2 cigarros**. Espera 2 horas y será 2.1. Post: tu ritmo será 5% más lento hoy".
- **Integra con**: Watch Workout App. Pop-up al iniciar ejercicio.

---

### <a id="curiosidad"></a>🧪 Curiosidad y revelación

> *"BuzzFeed construyó un imperio en 'TEST: qué tipo de X eres'"*

#### 💡 Idea 135: **Test viral: ¿Qué tan limpio es TU aire?**
- **Qué hace**: 10 preguntas (trayecto, horarios, barrio, hábitos). Resultado colorido shareable: "Tu puntaje: **54/100 — Urbano Expuesto**".
- **Mecanismo**: Tinder cards + animación + share directo a IG Stories.

#### 💡 Idea 136: **Detective del aire**
- **Qué hace**: Misterio interactivo: "Ana tose más los martes. Mira las pistas: su ruta, su AQI, su trabajo. ¿Cuál es la causa?". Educación disfrazada de juego.
- **Tech**: Foundation Models genera casos personalizados.

#### 💡 Idea 137: **Los mitos del aire — Quiz semanal**
- **Qué hace**: Cada lunes 5 preguntas: "¿La lluvia limpia el aire?" (verdad mixta), "¿Las plantas purifican suficiente el aire indoor?" (falso), "¿El cubrebocas quirúrgico bloquea PM2.5?" (falso). Respuestas con explicación visual.

#### 💡 Idea 138: **¿Qué respiraron los mexicas en 1521?**
- **Qué hace**: Time-travel AR. Visualiza tu ubicación con aire prehispánico vs hoy. Serie temporal de la degradación del aire en México.
- **Educativo + memorable**.

#### 💡 Idea 139: **Destapa tu ciudad**
- **Qué hace**: Mapa tipo SnapChat donde descubres hotspots contaminación en tu colonia. "Descubre 3 puntos nuevos esta semana". Exploration mode.

---

### <a id="economico"></a>💸 Impacto económico personal

> *"El dinero despierta a todos — especialmente a jóvenes mexicanos con sueldo limitado."*

#### 💡 Idea 140: **Calculadora de costo personal**
- **Qué hace**: "La contaminación te cuesta **$4,230 MXN/año**" (desglose: consultas respiratorias, medicamentos OTC, productividad perdida, lavado de ropa extra, mantenimiento de piel).
- **Base**: Estudios carga económica México + proxies personales.

#### 💡 Idea 141: **Tu sueldo vs tu aire**
- **Qué hace**: "Ganas $800 hoy. Gastaste $120 en 'salud perdida' por 4h expuesto al nivel actual. Ganancia real: **$680**".
- **Psicología**: Contabilidad mental + loss aversion.

#### 💡 Idea 142: **AirCoin economy**
- **Qué hace**: Moneda interna que ganas con comportamientos saludables. Canjeables por:
  - Descuentos en farmacias (DENUE partnership)
  - Asesorías médicas IMSS
  - Cubrebocas N95
- **Tech**: CloudKit + partnerships.

#### 💡 Idea 143: **Renta ambiental oculta**
- **Qué hace**: "Tu renta dice $8,000/mes. En realidad pagas $9,200 incluyendo tu daño pulmonar por esta zona. Aquí hay zonas con igual precio y 40% mejor aire".
- **Feature**: Buscador de departamentos por AQI + renta.

---

### <a id="temporal"></a>⏮️ Comparación temporal

#### 💡 Idea 144: **Aire de tu infancia**
- **Qué hace**: "Cuando naciste (2001), el aire en tu barrio era: **AQI 45**. Hoy: **AQI 78**. Has perdido **73% de la calidad** de aire de tu infancia".
- **Tech**: Datos históricos RAMA/SIMAT desde los 90s.
- **Visceral**: Nostalgia + pérdida.

#### 💡 Idea 145: **Tu aire vs el aire de tus padres a tu edad**
- **Qué hace**: "A los 25, tu papá en Guadalajara respiraba AQI promedio 32. Tú respiras 67. El doble". Datos generacionales públicos.

#### 💡 Idea 146: **Tu cápsula del tiempo**
- **Qué hace**: Cada año, la app guarda tus métricas + una foto de tu ciudad. Al año 10 puedes ver "tu aire hace una década". Engagement ultra-long-term.

#### 💡 Idea 147: **Si sigues así... (proyección 10 años)**
- **Qué hace**: "Si no cambias nada: en 2036 tendrás 35 años con pulmones de 48. Si cambias X: tendrás 35 con pulmones de 37". Escenarios side-by-side.
- **Tech**: CoreML proyecciones + visualización gráfica.

---

### <a id="visual"></a>🎨 Visual / AR / Visceral

#### 💡 Idea 148: **Espejo negro**
- **Qué hace**: Apuntas iPhone a tu cara en modo espejo. AR overlay muestra dónde se deposita PM2.5 en tu sistema respiratorio (nariz, tráquea, bronquios, alvéolos) con acumulación por horas.
- **Tech**: ARKit body tracking + visualización médica.

#### 💡 Idea 149: **Tu pulmón en realidad aumentada**
- **Qué hace**: Ver tu pulmón flotando en AR con color según salud real. Interacción: zoom a alvéolos dañados.
- **Educativo + brutal**.

#### 💡 Idea 150: **Partículas en tu cuarto (AR)**
- **Qué hace**: AR filter que visualiza PM2.5 del aire del cuarto donde estás — puntos flotantes según concentración. Ya tienen las 2000 partículas implementadas — solo indoor mode con I/O ratio estimator.

#### 💡 Idea 151: **Infografía corporal animada**
- **Qué hace**: Cada noche antes de dormir, animación 10s: "Hoy tus pulmones procesaron X litros de aire con Y gramos de contaminación. Tu cuerpo trabajó por ti así:". Dopamine visual + gratitud.

#### 💡 Idea 152: **Tu huella invisible**
- **Qué hace**: "Al caminar, levantaste **0.3g de polvo**. Tu coche emitió **42g CO2**. Tu aire acondicionado filtró **890L**". Tú CONTRIBUYES + RECIBES. Corresponsabilidad.

#### 💡 Idea 153: **Sonificación del aire**
- **Qué hace**: Widget de sonido ambient que cambia según AQI. Música agradable + AQI bajo. Disonante cuando es alto. Reemplaza alarma/ringtone.
- **Accesibilidad**: Personas daltónicas "escuchan" el aire.

---

### <a id="viral"></a>🔗 Social y compartible (viral)

#### 💡 Idea 154: **Stickers WhatsApp personalizados**
- **Qué hace**: Sticker pack que se actualiza con tu aire del día. "Yo hoy con AQI 145 🥴", "Tu vecino hoy con AQI 45 😎". Share directo.
- **Tech**: WhatsApp sticker format + on-device generation.

#### 💡 Idea 155: **Meme generator ambiental**
- **Qué hace**: Tomá cualquier meme viral MX (Pepe, Peso Pluma, Checo Pérez) + overlay con tu AQI + situación. Generador custom.
- **Compartible al extremo**.

#### 💡 Idea 156: **Instagram Stories auto-generadas**
- **Qué hace**: 1 tap para generar y compartir a IG Story: "Mi día respiratorio 16 abril". Con gráfica + ubicación + ranking.
- **Tech**: Deep link IG Stories API + SwiftUI rendering.

#### 💡 Idea 157: **Reto TikTok integrado**
- **Qué hace**: #AirWayChallenge — grabas video de ti caminando con el AirWay Live Activity visible. Reto semanal con tema (ruta limpia, dance routine en parque arbolado, etc.).

#### 💡 Idea 158: **Tu "pasaporte respiratorio"**
- **Qué hace**: Cada ciudad que visitas se estampa en un pasaporte virtual con su AQI promedio. Colecciona ciudades. Rank por "viajero más limpio".

---

### <a id="mental"></a>🧠 Integración mental/emocional

#### 💡 Idea 159: **Correlación emocional — tu humor**
- **Qué hace**: Gráfica: "Los días contaminados TÚ reportas 23% más tristeza (iOS 26 Journal/State of Mind). Tu cerebro lo siente aunque tú no sepas por qué".
- **Tech**: HKStateOfMind + correlación AQI.

#### 💡 Idea 160: **Eco-ansiedad coach**
- **Qué hace**: Si el usuario reporta alta ansiedad climática, Foundation Models ofrece marco de Good Grief Network (10 pasos) — guardrails estrictos, no reemplaza terapia.
- **Paper**: Psychiatric Services 2024.

#### 💡 Idea 161: **Tu pareja / familia — correlaciones**
- **Qué hace**: Con permiso, conecta con pareja/padres: "Tu mamá tose más los martes. Revisa su ubicación + AQI. Patrón: su trayecto al mercado pasa por zona crítica".
- **Tech**: CloudKit sharing familiar.

#### 💡 Idea 162: **Respiración guiada contextual**
- **Qué hace**: Cuando AQI es bueno, te invita a hacer 5 min de respiración profunda afuera. "Aire excelente ahora. Aprovecha". Gamifica momentos de buena calidad.

---

## <a id="hook"></a>4. Hook pattern aplicado (Nir Eyal)

Las apps que enganchan tienen 4 elementos cíclicos:

```
     ┌──────────────┐
     │   TRIGGER    │  ←  Notification "Hoy respiraste 3.4 🚬"
     └──────┬───────┘
            ↓
     ┌──────────────┐
     │    ACTION    │  ←  Tap abre la app
     └──────┬───────┘
            ↓
     ┌──────────────┐
     │   REWARD     │  ←  Ver cigarros animados + tu rank
     │ (variable)   │      (variable cada día → dopamine)
     └──────┬───────┘
            ↓
     ┌──────────────┐
     │  INVESTMENT  │  ←  Editar perfil, agregar amigo,
     │              │      customizar badge → lock-in
     └──────────────┘
            (loop)
```

**AirWay aplicado**:

| Elemento | Implementación sugerida |
|---|---|
| **External trigger** | Push 8am "Tu día respiratorio listo"; Push 9pm "Resumen diario"; WhatsApp sticker desde amigos |
| **Internal trigger** | Sentir tos → abrir app; ver smog en ventana → abrir app; ansiedad climática → abrir app |
| **Action (simple)** | 1 tap para ver AirRings / cigarros / rank |
| **Variable reward** | Cada día: badge único, rank cambiante, cara envejecida distinta, mensaje Foundation Models distinto |
| **Investment** | Agregar amigos, editar perfil de vulnerabilidad, customizar widget, stickers propios, streaks a mantener |

---

## <a id="priorizacion"></a>5. Priorización — Tier viralidad

### 🔥 Tier S — Viral Obligatorias (máximo retorno emocional + screenshot-ready)

| # | Idea | Por qué es S | Horas implementación |
|---|---|---|---|
| **107** | Tu cara contaminada en 10 años | FaceApp + datos reales = viral garantizado | 6h (image gen compleja) |
| **125** | Air Wrapped semanal/anual | Spotify Wrapped proven pattern | 4h |
| **101** | Tu cuenta regresiva de vida | Loss aversion máximo, imposible ignorar | 2h |
| **105** | Tu fumador invisible (cigarros) | Ya existe engine, falta el show | 1h |
| **118** | AirRings (3 anillos) | Apple pattern proven, UX intuitivo | 3h |
| **112** | Leaderboard amigos | Strava pattern, FOMO social | 4h |

### 🎯 Tier A — Diferenciadores fuertes

| # | Idea | Por qué |
|---|---|---|
| **103** | Edad pulmonar biológica | Comparable, shareable |
| **119** | Streaks Duolingo-style | Dopamine diario |
| **130** | Pronóstico mal humor | Predicción única |
| **154** | Stickers WhatsApp | Viralidad MX pura |
| **127** | Air personality type | BuzzFeed pattern |
| **140** | Calculadora costo personal | Dinero = atención |
| **144** | Aire de tu infancia | Nostalgia + datos históricos |

### 🎨 Tier B — Engagement diario

| # | Idea | Por qué |
|---|---|---|
| **120** | Tamagotchi Aira | Retorno diario |
| **121** | Badges coleccionables | FOMO diario |
| **133** | Horóscopo ambiental | Tono juguetón |
| **135** | Test viral | BuzzFeed pattern |
| **150** | Partículas AR cuarto | Ya tienen motor partículas |
| **159** | Correlación humor | iOS 26 feature nuevo |

### 💎 Tier C — Wow factor (si sobra tiempo)

- 126 Mini documental mensual
- 109 Voz envejecida
- 148 Espejo negro AR
- 138 Aire prehispánico
- 146 Cápsula del tiempo
- 115 Celebridad del aire

---

## 6. Combo ganador para hackathon (2 días)

**Propuesta concreta — 14 horas totales:**

### Día 1 (sábado) — Foundation + 3 features virales
- [ ] Hora 1-2: **Idea 105** — Visualización cigarros + Live Activity (reuses existing engine)
- [ ] Hora 3-6: **Idea 107** — Cara contaminada (la feature PITCH del hackathon)
- [ ] Hora 7-10: **Idea 118** — AirRings (3 círculos) + Widget

### Día 2 (domingo) — Social + narrativa + polish
- [ ] Hora 11-13: **Idea 125** — Air Wrapped weekly (SwiftUI animations)
- [ ] Hora 14-16: **Idea 112** — Leaderboard amigos + CloudKit
- [ ] Hora 17-18: **Idea 154** — Sticker pack WhatsApp
- [ ] Hora 19-20: **Idea 101** — Cuenta regresiva (widget)
- [ ] Hora 21-22: Demo + pitch

### Pitch de 3 minutos — Nueva narrativa

> "Las apps de calidad del aire fallan porque hablan como médicos. AirWay habla como Instagram.
>
> Te mostramos tu cara en 10 años si sigues respirando este aire. Te contamos cuántos cigarrillos invisibles fumaste hoy. Te comparamos con tus amigos. Tus datos se convierten en historias compartibles, no en gráficas aburridas.
>
> Apple Intelligence genera tu 'Air Wrapped' mensual — como Spotify, pero con tus pulmones. Foundation Models predice tu mal humor de mañana. CoreML estima tu edad pulmonar biológica.
>
> No te damos otra pantalla de AQI. Te damos una razón para cuidarte hoy — porque mañana importa."

---

## 7. Por qué esto sí funciona con usuario promedio

| Obstáculo típico | Cómo lo rompe AirWay 2.0 |
|---|---|
| "Yo soy joven/sano" | **Idea 103 edad pulmonar real**: te demuestra que NO |
| "Los datos son aburridos" | **Idea 125 Air Wrapped**: es una historia, no una tabla |
| "No cambio mi vida por esto" | **Idea 101 cuenta regresiva de vida**: cambia la ecuación mental |
| "Solo es una app más" | **Idea 107 cara contaminada**: nadie más tiene esto |
| "No afecta mi estatus" | **Idea 112 leaderboard amigos**: ahora sí afecta |
| "No es compartible" | **Idea 154 stickers WhatsApp**: cada feature genera meme |
| "No tengo tiempo" | **Idea 118 AirRings**: 2 segundos de mirada al widget |
| "No me identifico" | **Idea 127 personality type**: ahora tienes identidad |

---

## 8. Riesgos éticos a mitigar (HCAI compliance)

Estas ideas son potentes = peligrosas si se mal-implementan. Guardrails:

1. **Idea 101 (cuenta regresiva)**: Opcional, con disclaimer, opt-out en 1 tap.
2. **Idea 107 (cara futura)**: No usar con menores de 18. No compartir sin consentimiento.
3. **Idea 104 (lotería de asma)**: Mostrar IC, no como certeza médica.
4. **Idea 112 (leaderboard)**: Nunca exponer ubicación exacta. Solo rank agregado.
5. **Idea 130 (mal humor)**: No crear dependencia. Link a IMSS salud mental si detecta pattern grave.
6. **Idea 141 (costo personal)**: No individualizar culpa sistémica. Contextualizar.
7. **Idea 160 (eco-ansiedad)**: No simular terapeuta. Referir a profesionales.

---

## Totales

- **62 ideas NUEVAS** (101-162) enfocadas en engagement de usuario promedio
- **12 mecanismos psicológicos** usados (Loss aversion, vanidad, estatus, gamificación, narrativa, predicción, curiosidad, economía, nostalgia, visual, social, mental)
- **Hook pattern completo** aplicado (trigger → action → reward → investment)
- **Priorización Tier S/A/B/C** con 6 ideas Tier S para hackathon
- **Plan 2 días / 22 horas** con 7 ideas específicas

**La apuesta clave**: invertir 6h en **Idea 107 (tu cara en 10 años)** es la feature que ganará el hackathon si se ejecuta bien. Es FaceApp con alma médica y datos reales — inédita.
