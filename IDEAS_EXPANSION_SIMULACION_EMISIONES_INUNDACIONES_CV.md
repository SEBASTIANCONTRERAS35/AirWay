# AirWay — Expansión: Simulación Urbana, Emisiones, Inundaciones y Computer Vision

**Documento generado:** 16 de abril de 2026
**Base de investigación:** 4 agentes de investigación web con >200 fuentes académicas y técnicas (papers 2024-2026, APIs, datasets, modelos pretrained)
**Hackathon:** Swift Changemakers 2026 (UNAM iOS Lab, 20-21 abril)
**Complementa a:** `IDEAS_IA_AIRWAY_HACKATHON.md`, `IDEAS_IA_POBLACIONES_VULNERABLES.md`, `IDEAS_ENGAGEMENT_USUARIO_PROMEDIO.md`, `IDEA5_PREDICCION_AQI_IMPLEMENTACION.md`, `GNN_NIVEL3_IMPLEMENTACION_FUTURA.md`

---

## Tabla de contenido

1. [Resumen ejecutivo](#resumen-ejecutivo)
2. [Estado del arte cruzado 2024-2026](#estado-arte)
3. [TEMA 1 — Simulación de escenarios urbanos](#tema-1-simulacion)
4. [TEMA 2 — Análisis de emisiones contaminantes](#tema-2-emisiones)
5. [TEMA 3 — Zonas propensas a inundaciones](#tema-3-inundaciones)
6. [TEMA 4 — Identificación de emisiones con Computer Vision](#tema-4-cv)
7. [Stack técnico consolidado (iOS 26 + backend Django)](#stack-consolidado)
8. [Priorización cruzada — Combo ganador 48h](#priorizacion-cruzada)
9. [Moonshots consolidados](#moonshots-consolidados)
10. [Narrativa de pitch (3 min)](#narrativa-pitch)
11. [Fuentes y referencias](#fuentes)

---

## <a id="resumen-ejecutivo"></a>1. Resumen ejecutivo

Este documento recoge **~200 referencias** (papers 2024-2026, APIs gubernamentales mexicanas, datasets abiertos, modelos pretrained) y **~54 propuestas experimentales** distribuidas en 4 líneas de expansión para AirWay:

| # | Tema | Ideas nuevas | Papers clave | APIs/datasets | Moonshots |
|---|------|--------------|--------------|---------------|-----------|
| 1 | Simulación de escenarios urbanos | 12 | 15 | 14 | 5 |
| 2 | Análisis de emisiones contaminantes | 12 | 25 | 22 | 5 |
| 3 | Zonas propensas a inundaciones | 12 | 22 | 29 | 5 |
| 4 | Computer Vision para emisiones | 20 | 23 | 14 | 5 |
| **Total** | | **56** | **85** | **79** | **20** |

### Hallazgos transversales críticos

1. **Todo el stack cabe en el hardware actual**: Apple Foundation Models framework (iOS 26, ~3B params on-device) + FastVLM (60 FPS on-device, CVPR 2025) + CoreML + Metal 4 permiten correr simulación, detección CV y RAG sin costo en cloud.

2. **México tiene APIs gubernamentales listas e infrautilizadas**: RAMA, SACMEX Pluviómetros, CONAGUA SMN Web Service, CENAPRED Atlas, Atlas Riesgos CDMX, RETC, INEM, DENUE, CONEVAL AGEB, SEDEMA Inventario ZMVM 2020. **Ninguna app mexicana las cruza todas**.

3. **NASA + ESA cubren México completo y gratis**: TEMPO (NO₂/HCHO/O₃ horario, NRT desde sep-2025), Sentinel-5P TROPOMI, Sentinel-1 SAR flood, GPM IMERG Early Run, SMAP, EMIT, Copernicus DEM GLO-30, MethaneSAT via Google Earth Engine, Carbon Mapper Tanager-1.

4. **Eventos 2024-2025 que justifican la expansión**: Chalco bajo agua 1+ mes agosto 2024, recurrencia mayo-jun 2025; junio 2025 más lluvioso CDMX en décadas (107 mm/24h); Zócalo inundado + AICM cerrado sept 2025; octubre 2025 inundaciones Veracruz/Puebla/Hidalgo (76 muertos, 320,000 sin luz); impuesto emisiones CDMX ene 2025 necesita watchdog ciudadano.

5. **El diferencial HCAI**: las apps comerciales (IQAir, BreezoMeter, AirVisual) muestran números; AirWay puede **simular políticas**, **atribuir fuentes**, **predecir inundaciones**, **ver contaminación por cámara**. Es un salto categórico.

---

## <a id="estado-arte"></a>2. Estado del arte cruzado 2024-2026

### 2.1 Modelos pretrained listos para CoreML

| Modelo | Uso | Footprint | Papers |
|--------|-----|-----------|--------|
| **YOLOv11n / YOLOv10n fine-tuned D-Fire** | Humo/fuego 60 FPS | 6-10 MB | ESCFM-YOLO (89% mAP), HPO-YOLOv5 |
| **EfficientNet-B0 / ViT-B/16 PM25Vision** | Cielo → PM2.5 | 25 MB | PM25Vision (arXiv 2509.16519), AQE-Net |
| **FastVLM (Apple CVPR 2025)** | VQA multimodal | 0.5-7 B | TTFT 85× más rápido que LLaVA-OneVision |
| **MobileCLIP-S0 / MobileCLIP2** | Zero-shot classification | 50-150 MB | ViT-B/16 2.8× más chico |
| **Apple Foundation Model (iOS 26)** | Razonamiento + @Generable | ~3B | WWDC25, ViTDet-L 300M |
| **Prithvi WxC (NASA + IBM)** | Weather/climate/precip. | 320M | arXiv 2409.13598 |
| **Prithvi-EO-2.0** | Geospatial fine-tune | 300M-600M | HuggingFace ibm-nasa-geospatial |
| **Aurora (Microsoft Nature 2025)** | Foundation model Earth | 1.3B | 5000× speedup vs IFS-HRES |
| **Local-FNO (Fourier Neural Operator)** | CFD urbano 500× más rápido | ~50 MB | arXiv 2503.19708 |
| **HydroGAT** | Flood prediction GNN | variable | arXiv 2509.02481, NSE 0.97 |
| **CH4Net / AttMetNet** | Methane plume detection | variable | AMT 2024, arXiv 2512.02751 |
| **FootNet v1.0** | Emulador transporte atmosférico | ~100 MB | GMD 2025, 650× speedup STILT |

### 2.2 Papers 2024-2026 con mayor potencial para AirWay

1. **UrbanGraph** (arXiv 2510.00457, oct 2025) — Physics-Informed GNN heterogéneo dinámico para microclima. **Plantilla directa para tu GNN Nivel 3 ya planificado**.
2. **Local-FNO Urban Airflow** (arXiv 2503.19708, mar 2025) — CFD surrogate con 24 simulaciones de entrenamiento, 500× speedup. Motor ideal para "¿qué pasa si cierro Reforma?".
3. **Google Flood Hub Nature 2024** — LSTM para inundación ribereña 7 días, 80+ países, 460M personas. Mexico en waitlist Cloud Project.
4. **Microsoft Aurora Nature 2025** — 1.3B foundation model Earth, 5000× speedup, supera IFS-HRES. Nube (on-device no).
5. **PM25Vision benchmark** (arXiv 2509.16519, sep 2025) — 11,114 imágenes street-level + PM2.5, 3,261 estaciones, 11 años. Dataset en HuggingFace + Kaggle.
6. **FastVLM CVPR 2025** — VLM 60 FPS on-device iPhone. TTFT 85× más rápido que LLaVA-OneVision. Base del "Apple Intelligence de AirWay".
7. **ES&T 2025 Open-Vocab OD** — OWL-ViT + Mask2Former descubre chimeneas como predictores infrautilizados de polución. 0.37M street-view + 5.7M mediciones.
8. **PINN Inverse Advection-Diffusion** (arXiv 2503.18849, mar 2025) — localizar fuente de contaminación con física invertida + NN. Idea "¿quién te contamina?".
9. **Climate TRACE** — inventario global 660M activos, releases mensuales 2025. API pública.
10. **npj 2025 "Accelerating flood warnings 10 hours"** — topología de red fluvial + AI. Aplicable a Gran Canal CDMX.

### 2.3 Datos duros mexicanos para el pitch (todos con fuente verificable)

- **61% del CO₂ metropolitano viene de transporte** (SEDEMA Inventario ZMVM 2020).
- **Autos particulares 29% + SUV 29% + motos 10% + taxis 9%** de CO₂ transporte.
- **ProAire ZMVM 2021-2030**: 19 acciones atacan >70% de emisiones, meta 25% reducción al 2030, **evitando ~6,000 muertes prematuras**.
- **Impuesto emisiones CDMX enero 2025**: grava fuentes fijas por gases, oportunidad de accountability ciudadana.
- **Chalco se hunde 20 cm/año** por extracción de agua subterránea; **Gran Canal CDMX pasó de 90 a 12 m³/s en 30 años** por pérdida de gradiente.
- **Junio 2025 más lluvioso en décadas CDMX** (Instituto Atmósfera UNAM); 29 junio 2025: 107 mm/24h.
- **Octubre 2025 inundaciones**: 76 muertos, 75 desaparecidos, 100,000 casas destruidas, 320,000 sin luz, 1,000 km carreteras dañadas; comunidades indígenas desproporcionadamente afectadas (World Weather Attribution).
- **Subsidence CDMX hasta 39 cm/año** (Nezahualcóyotl, Sentinel-1); zonas hasta 90 cm/año con X-band.
- **Chalco 2024**: 1+ mes bajo aguas negras; recurrencia 80 cm mayo-jun 2025.
- **CDMX Aedes aegypti detectado desde 2015**, riesgo emergente post-inundación.
- **Leptospirosis Brazil 2024**: 958 casos confirmados, 30 muertes (10.3× baseline). Paralelo inmediato Chalco/Poza Rica.

---

## <a id="tema-1-simulacion"></a>3. TEMA 1 — Simulación de escenarios urbanos

### 3.1 Técnicas SOTA 2024-2026

| Técnica | Madurez | Speedup vs CFD | Viable iPhone | Relevancia AirWay |
|---|---|---|---|---|
| **Fourier Neural Operator (Local-FNO)** | Alta | 50-500× | Sí (CoreML) | **Altísima** |
| **GNN (UrbanGraph, PIGNN-CFD, AirPhyNet)** | Alta | 10-100× | Alta | **Altísima** — cruza con tu GNN Nivel 3 |
| **Physics-Informed NN (PINN)** | Media | 5-50× | Alta | **Alta** — fuente localization |
| **Diffusion post-processing (DDPM)** | Emergente | 3× + 65% accuracy | Media | **Alta** — refinamiento PM2.5 |
| **Cellular Automata híbrido GPU** | Clásica estable | 10× | Muy alta (Metal) | **Media** — sandbox |
| **Lattice Boltzmann Metal 4** | Alta | Tiempo real 1 GPU | iPhone Pro | **Alta** — demo wow |
| **Agent-Based Models (GAMA, MATSim, CityFlow)** | Alta | N/A | Baja on-device | **Alta** — peatones |
| **Deep RL (PPO, TD3) para políticas** | Alta | N/A | Inferencia sí | **Muy alta** — Hoy No Circula RL |
| **LLM-agent simulation (GATSim, UGI)** | Emergente 2025 | N/A | Con Foundation Models sí | **Moonshot** |
| **3D Gaussian Splatting** | Explosiva 2025 | Render tiempo real | iPhone Pro | **Moonshot AR** |

### 3.2 12 propuestas experimentales

#### Idea S1 — "CityLab Reforma": What-If FNO surrogate de cierre de avenidas ★★★★★
El usuario selecciona una vía, el backend corre Local-FNO (pre-entrenado en CFD) y proyecta heatmap AQI 2/4/8h sobre MapKit 3D.
- **Stack:** Django + Local-FNO (PyTorch → ONNX → CoreML), Overture buildings heights, Open-Meteo wind, MapKit 3D + MKPolygon + Metal shader.
- **Tiempo:** 18-24h. **Wow:** 5/5.
- **Integración:** `backend-api/src/interfaces/api/routes/views.py` añade `/api/v1/simulation/close_street`.

#### Idea S2 — "AR Plume Vision": plumas 3D volumétricas sobre mapa real ★★★★★
ARKit geotracking + RealityKit 4 + partículas existentes redirigidas por campo de viento real de Open-Meteo.
- **Stack:** ARGeoTrackingConfiguration (iOS 17+), RealityKit particle emitter, Metal compute shader advección.
- **Tiempo:** 24-30h. **Wow:** 5/5 — **momento ganador del pitch**.

#### Idea S3 — "HoyNoCircula-RL": PPO política alternativa
Agente PPO sugiere cada día qué placas restringir para minimizar O₃ en 48h.
- **Stack:** Stable-Baselines3 + gym custom + CityFlow + inventario SEDEMA + EMFAC2025 adaptado.
- **Tiempo:** 30-36h. **Wow:** 4/5. **Narrativa política potentísima**.

#### Idea S4 — "AirGarden": sandbox gamificado con CA Metal GPU ★★★★
Vista top-down; usuario arrastra árboles, filtros, cambia velocidad vehicular, ve impacto AQI con CA híbrido GPU.
- **Stack:** SpriteKit/SceneKit + Metal compute shader (CA hybrid, Sonnenschein 2025).
- **Tiempo:** 16-22h. **Viabilidad:** 5/5. **Wow:** 4/5.

#### Idea S5 — "CrowdWind CDMX": iPhones como anemómetros federated
CoreMotion + CMAltimeter + FL triangulan viento a resolución de manzana.
- **Stack:** PrivateCloudCompute + Core ML FL (iOS 17+) + PressureNet-style inference.
- **Tiempo:** 20-26h. **Narrativa NASA Space Apps perfecta**.

#### Idea S6 — "Pollution Source Finder": PINN inverso (¿quién te contamina?)
Ecuación advección-difusión reversa con 3h TEMPO+RAMA+viento pinta flechas hacia fuentes probables.
- **Stack:** PyTorch PINN backend → GeoJSON flechas + MKPolyline + Apple Foundation Models narración.
- **Tiempo:** 22-28h. **Wow:** 5/5 — **titulares mediáticos**.

#### Idea S7 — "DigitalTwin-CDMX Phone": Lattice Boltzmann en Metal 4
Mini-CFD on-device en el Neural Engine A17/A18 sobre tile 3D CityGML de la colonia.
- **Stack:** Metal 4 MSL LBM kernel D3Q19, mesh Model I/O, RealityKit scene.
- **Tiempo:** 30-40h. **Solo iPhone Pro**. **Wow:** 5/5 moonshot visible.

#### Idea S8 — "Construcción Impact Predictor": evaluación de impacto por IA
Usuario dibuja edificio futuro; GNN predice cambio AQI; Gemini 2.5 Flash genera reporte estilo EIA.
- **Stack:** UrbanGraph GNN + Gemini + PDFKit.
- **Tiempo:** 20-26h. Herramienta para SEDUVI y consultas públicas.

#### Idea S9 — "Contingencia Predictiva 72h": ensemble multi-modelo
GradientBoosting actual + Transformer HEART + DDPM refinado, avisa **antes** que CAMe declare Fase 1.
- **Stack:** backend ensemble + UserNotifications + HealthKit trigger (cardiópatas).
- **Tiempo:** 14-18h. **La más rápida**. **Viabilidad:** 5/5.

#### Idea S10 — "ScenarioGPT CDMX": Apple Foundation Models narra escenarios
Siri/textbox → NL params → FNO backend → voz + insights.
- **Stack:** Foundation Models framework (WWDC25) + function calling + AVSpeechSynthesizer.
- **Tiempo:** 18-24h.

#### Idea S11 — "DepolluterVision": Stable Diffusion "CDMX sin smog"
Foto del usuario + ControlNet atmospheric clarity → comparativa hoy vs futuro.
- **Stack:** ML-Stable-Diffusion Apple Silicon + ControlNet custom.
- **Tiempo:** 16-22h. **Viralidad alta**.

#### Idea S12 — "HealthExposure Ride-along": dosis real con Apple Watch
Ruta Dijkstra + PPI Score HRV + ecuación ICRP-66 deposición pulmonar → dosis PM2.5 real.
- **Stack:** HealthKit + GradientBoosting PM2.5 + ranking "Pulmones Limpios".
- **Tiempo:** 10-14h. **La más simple** y alto valor. **Integra 100% del stack existente**.

### 3.3 Papers clave

1. UrbanGraph — https://arxiv.org/abs/2510.00457
2. Local-FNO Urban Airflow — https://arxiv.org/abs/2503.19708
3. FNO Wind Directions Cross-City — https://arxiv.org/abs/2501.05499
4. Deep RL Air Quality Booth Placement — https://arxiv.org/abs/2505.00668
5. Diffusion Models Reducing Spatiotemporal Errors — https://arxiv.org/abs/2501.04847
6. AirPhyNet Physics-Guided NN — https://arxiv.org/html/2402.03784v2
7. PINN Inverse Advection-Diffusion Pollution Sources — https://arxiv.org/abs/2503.18849
8. Physics-Informed AI Urban Systems Survey — https://arxiv.org/html/2506.13777v1
9. Hybrid Cellular Automata Traffic Scenarios — https://www.sciencedirect.com/science/article/pii/S1364815225000404
10. Street Canyon Wind Deep Learning Building Simulation — https://link.springer.com/article/10.1007/s12273-025-1243-9
11. AirCade Causal Decoupling — https://arxiv.org/html/2505.20119v1
12. Prithvi Urban Heat Islands Fine-Tune — https://arxiv.org/abs/2510.18773
13. GATSim Generative Agents 2026 — https://www.sciencedirect.com/science/article/abs/pii/S0968090X26000641
14. ML-guided Fixed+Mobile PM2.5 — https://www.nature.com/articles/s41612-025-00984-3
15. HEART Transformer Spatiotemporal — https://arxiv.org/abs/2502.19042

### 3.4 APIs y datasets clave

| Dataset | URL | Costo | Uso |
|---|---|---|---|
| **Overture Maps Buildings** (2.3B footprints + heights) | https://docs.overturemaps.org/guides/buildings/ | Gratis CDLA | Geometría CFD |
| **Google Air Quality API** | https://mapsplatform.google.com/maps-products/air-quality/ | $5/1000 calls | Ground truth |
| **Waze for Cities** | https://www.waze.com/wazeforcities/ | Gratis (gobiernos/academia) | Tráfico real-time |
| **SEDEMA RAMA CDMX** | https://datos.cdmx.gob.mx/dataset/red-automatica-de-monitoreo-atmosferico | Gratis | Mediciones minuto |
| **ESA Destination Earth Climate DT** | https://destine.ecmwf.int/climate-change-adaptation-digital-twin-climate-dt/ | Gratis con registro | 1990-2050 5-10km |
| **IBM-NASA Prithvi-EO-2.0** | https://huggingface.co/ibm-nasa-geospatial | Gratis | Foundation geospatial |
| **Project PLATEAU (Tokyo)** | https://www.mlit.go.jp/plateau/en/ | Gratis | Referencia digital twin |
| **OpenBuildings 2.5D Temporal** | https://spatialthoughts.com/2025/03/29/building_height_gee/ | Gratis no comercial | Heights global 2023-2025 |
| **HYSPLIT NOAA** | https://www.arl.noaa.gov/hysplit/ | Gratis | Modelo Lagrangiano oficial |
| **Eclipse SUMO / CityFlow** | https://eclipse.dev/sumo/ | Open source | Tráfico microsim |
| **GAMA Platform 2025-06** | https://gama-platform.org/ | Open source | ABM |
| **Awesome CityGML** | https://github.com/OloOcki/awesome-citygml | Gratis | 210M edificios 65 ciudades |

---

## <a id="tema-2-emisiones"></a>4. TEMA 2 — Análisis de emisiones contaminantes

### 4.1 12 propuestas experimentales

#### Idea E1 — "¿Quién está contaminando mi aire?" — Mapa de Fuentes Vivas ★★★★★
Capas on/off por fuente (termoeléctricas, cementeras, rellenos, vialidades, incendios) coloreadas por contribución al AQI del usuario.
- **Stack:** Climate TRACE API + Global Power Plant DB + RETC + TROPOMI NO₂ WMS + GFED fires. MapKit + MKTileOverlay.
- **Tiempo:** 1.5-2 días.
- **Inversion bayesiana simplificada:** `contribution = bayesianInverse(asset.emissions, wind, stability, distance)`.

#### Idea E2 — Detector de Fugas de Metano (MARS Mirror) ★★★★★
Push "Ayer se detectó super-pluma de CH₄ en tu municipio" con plume raster Carbon Mapper.
- **Stack:** UNEP MARS + Carbon Mapper API + EMIT L2B CH4PLM GeoJSON + BackgroundTasks.
- **Tiempo:** 1 día. **Cero competencia local**.

#### Idea E3 — Atribución Personal Instantánea ("Tu huella ahora")
CoreLocation + CMMotionActivityManager clasifica modo y calcula gCO₂e/km, kg PM2.5/día.
```swift
let activity = CMMotionActivityManager()
activity.startActivityUpdates(to: .main) { a in
    let speedKMH = location.speed * 3.6
    let ef = MLModel.predict(mode: a, speed: speedKMH, elevation: delta)
    session.emissions += ef * deltaDistance
}
```
- **Tiempo:** 2 días.

#### Idea E4 — "Vecinos Contaminantes" (quemas ilegales con audio+foto+GFED)
SoundAnalysis (crackle fuego) + Vision (humo) + GFED NRT cross-check.
```swift
if audioScore > 0.7 && visionScore > 0.7 && GFED.anyFirePixel(near: loc, within: 500, lastHours: 6) {
    report.verification = .AIconfirmed
}
```
- **Tiempo:** 2.5 días.

#### Idea E5 — "Industria Trazadora" — incumplimiento RETC + TROPOMI
Industria RETC cerca; reportes vs umbral NOM + TROPOMI NO₂ overhead; anomalía 2σ = alerta.
- **Stack:** RETC + TROPOMI L2 vía Sentinel Hub + CNN-LSTM anomaly detector.
- **Tiempo:** 3 días.

#### Idea E6 — Impacto Movilidad Eléctrica (EV Tracker)
Simula tu viaje como: gasolina A, gasolina B sucio, Metro, bici, EV. Muestra evitados.
- **Stack:** Electricity Maps API + factores EFE 2024 SEDEMA.
- **Tiempo:** 1.5 días. **Gamifica ahorro**.

#### Idea E7 — ESG de Colonia + Gemini RAG
"Las 5 empresas que más contaminan en Azcapotzalco" generado por Gemini 2.5 Flash + RAG RETC.
- **Stack:** Django + pgvector + Gemini.
- **Tiempo:** 2 días. Ya tienes Gemini.

#### Idea E8 — Carbono Semanal Widget + Watch
Widget "Tu CO₂ semanal: 45 kg / 2.3 ton/año. 23% encima del promedio CDMX".
- **Stack:** WidgetKit + Charts + complication.
- **Tiempo:** 1 día.

#### Idea E9 — Denuncia Ciudadana OCR placa + clasificador humo
5s video de auto humeante → Vision OCR placa + CNN humo denso/blanco/azul → cruce con Verificación.
- **Stack:** VNRecognizeTextRequest + VNCoreMLRequest + API Hoy No Circula.
- **Tiempo:** 2 días. **Ética:** no mostrar placa en UI pública.

#### Idea E10 — Flotilla Tracker (Uber/DiDi sucios)
Foto del auto al finalizar viaje → YOLO make/model → ranking anónimo por zona.
- **Stack:** Vision + CoreML custom clasificador.
- **Tiempo:** 3 días.

#### Idea E11 — Clasificador de Motor por Sonido (diésel vs gasolina vs EV)
Mic detecta 3 motores diésel en parada → advertencia al asmático que cambie de acera.
```swift
let config = MLSoundClassifier.ModelParameters(
    featureExtractor: .audioFeaturePrint,
    validation: .split(strategy: .automatic(validationFraction: 0.2)))
let classifier = try MLSoundClassifier(trainingData: data, parameters: config)
```
- **Tiempo:** 3-4 días. **Nunca se ha hecho a escala**; publicable como paper.

#### Idea E12 — Conteo Vehicular con Vision (ciudadanos como estaciones)
60s grabación calle → YOLO detecta autos/buses/motos → flujo veh/min × EF SEDEMA → mapa crowd.
- **Stack:** YOLOv8n 4MB CoreML + Core Motion rechazo movimiento brusco.
- **Tiempo:** 3 días.

### 4.2 Papers clave

1. FootNet v1.0 — https://gmd.copernicus.org/articles/18/1661/2025/
2. High-resolution GHG flux inversions — https://acp.copernicus.org/articles/25/5159/2025/
3. Vision Transformer methane Nature Comms 2024 — https://www.nature.com/articles/s41467-024-47754-y
4. CH4Net Sentinel-2 — https://amt.copernicus.org/articles/17/2583/2024/
5. AttMetNet Attention-enhanced DL — https://arxiv.org/html/2512.02751v1
6. U-Plume CNN cuantificación — https://amt.copernicus.org/articles/17/2625/2024/
7. HyperSTARCOP / MPSUNet — https://arxiv.org/abs/2505.21806
8. PollutionNet Vision Transformer NO₂/SO₂ — https://arxiv.org/abs/2604.03311
9. Power Plant CO₂ U-Net + OCO-2/3 — https://arxiv.org/abs/2502.02083
10. Global Solid-Waste Methane Super-emitters ES&T 2025 — https://pubs.acs.org/doi/10.1021/acs.est.4c14196
11. Urban emissions hotspots Gately 2017 — https://pubmed.ncbi.nlm.nih.gov/28628865/ (70% emisiones en 10% calles)
12. Ubiquitous data-driven traffic emission Nature Sustainability 2026 — https://www.nature.com/articles/s41893-026-01797-9
13. High-res on-road vehicle emissions big data ACP 2025 — https://acp.copernicus.org/articles/25/5537/2025/
14. Urban PM2.5 hotspots mobile + GP npj 2025 — https://www.nature.com/articles/s44407-025-00038-1
15. Tracking pollution 13,189 urban areas 2025 — https://www.nature.com/articles/s43247-025-02270-9
16. Multi-ML ozone source attribution 2025 — https://egusphere.copernicus.org/preprints/2025/egusphere-2025-160/
17. TROPOMI CO Mexico City ACP 2020 — https://acp.copernicus.org/articles/20/15761/2020/
18. CO₂/CO Mexico City ACP 2024 — https://acp.copernicus.org/articles/24/11823/2024/
19. DL vehicle CO₂ + XAI Sci Reports 2025 — https://www.nature.com/articles/s41598-025-87233-y
20. OBD-II ML review MDPI Sensors 2025 — https://www.mdpi.com/1424-8220/25/13/4057
21. ST-GasNet urban toxic plumes PNAS Nexus 2025 — https://academic.oup.com/pnasnexus/article/4/6/pgaf198/8169444
22. Aerosol sources dual-isotope + Bayesian 2025 — https://www.nature.com/articles/s43247-025-02487-8
23. LITES methane isotope Optics Express 2025 — https://opg.optica.org/oe/fulltext.cfm?uri=oe-33-24-51094
24. PMF toolkit AMT 2025 — https://amt.copernicus.org/articles/18/6817/2025/
25. Gaussian Process + probabilistic CO₂ inverse ES&T 2025 — https://pubs.acs.org/doi/10.1021/acs.est.4c09395

### 4.3 APIs y datasets

**Satelitales GHG / criterios**:
- NASA TEMPO — https://www.earthdata.nasa.gov/data/instruments/tempo (NRT V02 ~180 min)
- Sentinel-5P TROPOMI — https://documentation.dataspace.copernicus.eu/Data/SentinelMissions/Sentinel5P.html
- NASA EMIT CH₄ plumes — https://earth.jpl.nasa.gov/emit/data/data-portal/Greenhouse-Gases/
- Carbon Mapper Tanager-1 — https://carbonmapper.org/data
- GHGSat (16 satélites nov 2025) — https://www.ghgsat.com/en/products-services/data-sat/
- MethaneSAT vía Google Earth Engine — https://developers.google.com/earth-engine/datasets/publisher/edf-methanesat-ee
- PRISMA (ASI) + EnMAP (DLR) hyperspectral — https://amt.copernicus.org/articles/18/4611/2025/
- Climate TRACE (660M activos, mensual) — https://climatetrace.org/
- Global Power Plant DB (WRI) — https://github.com/wri/global-power-plant-database
- Electricity Maps API — https://app.electricitymaps.com/developer-hub/api/getting-started
- EDGAR v8 JRC-EU 2025 — https://edgar.jrc.ec.europa.eu/
- CAMS Global Reanalysis — https://www.ecmwf.int/en/forecasts/dataset/cams-global-reanalysis
- GEOS-CF v2 NASA — https://gmao.gsfc.nasa.gov/gmao-products/geos-cf/faq_geos-cf/
- NOAA OMI/OMPS SO₂ (759 point sources) — https://so2.gsfc.nasa.gov/measures.html
- UNEP MARS methane alerts — https://www.unep.org/topics/energy/methane/methane-alert-and-response-system-mars
- GFED v5 biomass burning — https://www.globalfiredata.org/
- OpenAQ v3 (v1/v2 retirados 31-ene-2025) — https://docs.openaq.org/

**México/CDMX**:
- SEDEMA Inventario ZMVM 2020 — https://proyectos.sedema.cdmx.gob.mx/datos/storage/app/media/docpub/sedema/inventario-emisiones-cdmx-2020bis.pdf
- Aire CDMX — http://www.aire.cdmx.gob.mx/
- RETC nacional (104 sustancias) — https://www.gob.mx/semarnat/acciones-y-programas/registro-nacional-de-emisiones-rene
- INEM SEMARNAT — https://gisviewer.semarnat.gob.mx/wmaplicacion/inem/
- Hoy No Circula — https://hoynocircula.cdmx.gob.mx/
- Verificación Vehicular SEDEMA — https://sedema.cdmx.gob.mx/programas/programa/verificacion-vehicular
- TRUE real-world taxi emissions Mexico City 2024 — https://trueinitiative.org/wp-content/uploads/2024/11/id-79-mexico-city-rs_report_final.pdf

---

## <a id="tema-3-inundaciones"></a>5. TEMA 3 — Zonas propensas a inundaciones

### 5.1 12 propuestas experimentales

#### Idea F1 — "AirWay FlashFlood 2H": alerta 2h antes de inundación en tu cuadra ★★★★★
GPM IMERG Early Run + GSMaP NOW 6h-ahead + HRRR 1km + SMAP + DEM + OSM drenaje → ConvLSTM on-device.
- **Stack:** CoreML ConvLSTM cuantizado, WeatherKit nowcast, GPM Earth Engine pre-cache, Copernicus DEM GLO-30.
- **Tiempo:** 24-36h.
- **Wow:** "En 90 min habrá 40cm de agua en Av. Tláhuac #5432". **Funciona offline**.

#### Idea F2 — "Modo Temporada Lluvias" (junio-octubre) ★★★★
Toggle que reescribe la UX: capa AQI + riesgo inundación (SACMEX radar + CENAPRED) + zonas seguras. Rutas evitan puntos críticos + mantienen AQI.
- **Stack:** MapKit + heatmap, SACMEX API, CENAPRED Atlas shapefiles, CONAGUA SMN.
- **Tiempo:** 12-18h.

#### Idea F3 — "Modo Cuidador" alerta geocercada adultos mayores aislados
Familiares vulnerables (EPOC/asma/movilidad reducida) → cuadra en alerta → push al cuidador + Live Activity al adulto mayor + check-in Watch haptics.
- **Stack:** SwiftUI Live Activities + WatchOS + HealthKit + CoreLocation geofencing + APNs.
- **Tiempo:** 18-24h. **Intersección vulnerabilidad social (CONEVAL AGEB) + fisiológica**.

#### Idea F4 — "AR Flood Preview" ★★★★★
Apuntas iPhone a tu calle → ARKit + LiDAR + DEM muestran cómo se vería inundada con slider X mm de lluvia.
- **Stack:** ARKit + RealityKit + Metal water shader + Copernicus DEM + LiDAR para nivel local.
- **Tiempo:** 24-36h. **Lo más llamativo visualmente**. Referencia: Storm Surge AR UCAR.

#### Idea F5 — "LiDAR Drain Mapper": reporta alcantarillas tapadas ★★★★
Escanea alcantarilla con LiDAR → YOLO detecta obstrucción → Django REST + PostGIS → mapa público.
- **Stack:** ARKit LiDAR + RoomPlan + Vision + CoreML + MapKit clustering.
- **Tiempo:** 24-36h. Dataset crowdsourced compartible con SACMEX.

#### Idea F6 — "Hydro-On-Device": Manning + DEM ligero
Modelo hidráulico on-device con ecuación de Manning sobre red de drenaje OSM + DEM. Dado lluvia pronosticada, calcula qué calles saturan primero en <1s.
- **Stack:** Swift + Accelerate + OSM Overpass → GeoJSON bundled + DEM cacheado.
- **Tiempo:** 18-24h. **Privacidad total**, sin API.

#### Idea F7 — Predicción AQI post-inundación con Gemini ★★★★★ — **La más rápida (6-8h)**
Prompt a Gemini con: horas post-lluvia, duración encharcamiento, temperatura, humedad, vecindad → pronóstico PM2.5 por esporas/moho + recomendación mascarilla + duración ventilación.
- **Stack:** existente (Django + Gemini 2.5 Flash); sumar contexto de lluvias + datos SACMEX.
- **Tiempo:** 6-8h. **Cierra loop aire↔agua**.

#### Idea F8 — "Digital Twin CDMX" simulación flash flood por colonia ★★★★★
SceneKit/Three.js colonia (Iztapalapa Acatitla o Chalco Culturas de México). "Simular 50mm/h" → surrogate DL entrenado sobre HEC-RAS (10-50× más rápido). Nivel se anima sobre terreno 3D.
- **Stack:** SceneKit + backend Django surrogate PyTorch → CoreML + DEM 1m + OSM buildings.
- **Tiempo:** 36-48h ambicioso. **Moonshot**.

#### Idea F9 — "Alerta Pre-Hospitalaria Post-Inundación"
48-72h después de inundación confirmada → módulo síntomas (fiebre, ictericia, tos, disnea, dolor muscular severo) → triaje leptospirosis/dengue/asma moho → reporte anonimizado + hospital cercano.
- **Stack:** SwiftUI + HealthKit opcional + Gemini clínico (sandbox) + MapKit rutas.
- **Tiempo:** 18-24h. **Referencia Rio Grande do Sul 2024**.

#### Idea F10 — Mapa riesgo dengue post-inundación
MODIS MCDWD + Sentinel-1 áreas inundadas >72h × vectores Aedes aegypti → alerta 2-4 semanas después (pico 3 meses post-flood).
- **Stack:** backend Django tareas diarias + dataset Lancet Planetary Health.
- **Tiempo:** 24-36h. Expansión Veracruz/Tabasco/Guerrero.

#### Idea F11 — Ruta de Evacuación Dinámica
Durante emergencia: refugio temporal (CENAPRED) evitando calles inundadas (Sentinel-1 GFM + reportes + radar SACMEX). Grafo dinámico cada 5 min.
- **Stack:** MapKit + A* pesos dinámicos + GNN HydroGAT/mSWE-GNN.
- **Tiempo:** 18-24h.

#### Idea F12 — "Quiahua 2.0": iPhone como pluviómetro LiDAR
iPhone en recipiente estándar durante tormenta → LiDAR mide cm de agua cada 10 min → datos agregados (FL) densifican SACMEX.
- **Stack:** ARKit LiDAR depth (4m rango) + federated learning + Firebase/Supabase.
- **Tiempo:** 24-36h. **Replica Quiahua UNAM a nivel urbano**.

### 5.2 Papers clave

1. Nearing et al. Nature 2024 Google Flood Hub — https://www.nature.com/articles/s41586-024-07145-1
2. Microsoft Aurora Nature 2025 — https://www.nature.com/articles/s41586-025-09005-y
3. Prithvi WxC NASA+IBM — arXiv 2409.13598
4. HydroGAT 2025 — https://arxiv.org/html/2509.02481
5. ConvLSTM urban flood 2025 — https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2025WR040433
6. ConvLSTM moving storms 2025 — https://link.springer.com/article/10.1007/s13753-025-00685-8
7. LSTM + watershed Kim 2025 — https://onlinelibrary.wiley.com/doi/10.1111/jfr3.70123
8. "Accelerating flood warnings 10 hours" npj 2025 — https://www.nature.com/articles/s44304-025-00083-6
9. mSWE-GNN NHESS 2025 — https://nhess.copernicus.org/articles/25/335/2025/
10. Interpretable PI-GNN flood 2025 — https://onlinelibrary.wiley.com/doi/full/10.1111/mice.13484
11. RA-UNet Precipitation Nowcasting 2025 — https://www.mdpi.com/2072-4292/17/7/1123
12. WassDiff Wasserstein-regularized diffusion — https://arxiv.org/html/2410.00381v4
13. EGUsphere conditional diffusion precipitation 2025 — https://egusphere.copernicus.org/preprints/2025/egusphere-2025-2646/
14. Nat Hazards 2025 economic risk subsidence CDMX — https://link.springer.com/article/10.1007/s11069-024-06891-9
15. Scientific Reports 2024 CDMX Metro InSAR — https://www.nature.com/articles/s41598-024-53525-y
16. WWA oct 2025 atribución Veracruz/Puebla — https://www.worldweatherattribution.org/heavy-rainfall-leading-to-widespread-flooding-in-eastern-mexico-disproportionately-impacts-highly-exposed-indigenous-and-socially-vulnerable-communities/
17. PLOS One 2024 landslide social lag CDMX — https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0340639
18. SaTformer NeurIPS Weather4Cast 2025 — https://arxiv.org/html/2511.11197
19. EGUsphere CNN + ConvLSTM flood dynamics 2025 — https://egusphere.copernicus.org/preprints/2025/egusphere-2025-3171/
20. J Hydrology 2024 PINN Shallow Water — https://www.sciencedirect.com/science/article/pii/S0022169424006589
21. PINN river stage 2025 — https://arxiv.org/html/2503.16850v1
22. iPhone LiDAR stream mapping MDPI 2025 — https://www.mdpi.com/1424-8220/25/19/6141

### 5.3 APIs y datasets

**Precipitación satelital/global**:
- NASA GPM IMERG — https://gpm.nasa.gov/data/imerg (Earth Engine `NASA/GPM_L3/IMERG_V07`)
- JAXA GSMaP NOW — https://sharaku.eorc.jaxa.jp/GSMaP_NOW/ (pronóstico 6h)
- ECMWF + HRRR vía Open-Meteo — gratis sin API key
- Apple WeatherKit — 500k calls/mes gratis, minute-by-minute hasta 1h

**Agua/SAR**:
- Sentinel-1 SAR — gratis Copernicus Data Space / Earth Engine / AWS
- Copernicus GFM (CEMS Global Flood Monitoring) — <5h latencia automática Sentinel-1 VV
- MODIS MCDWD NRT 250m — https://www.earthdata.nasa.gov/data/catalog/lancemodis-mcdwd-l3-nrt-6.1
- OPERA DSWx-HLS NASA/JPL+USGS — https://podaac.jpl.nasa.gov/dataset/OPERA_L3_DSWX-HLS_V1
- VIIRS NRT Global Flood

**Humedad/elevación**:
- SMAP L4 NASA JPL — https://smap.jpl.nasa.gov/
- Copernicus DEM GLO-30 — https://portal.opentopography.org/raster?opentopoID=OTSDEM.032021.4326.3
- SRTM 30m — Earth Engine
- HydroSHEDS — https://www.hydrosheds.org/
- MERIT-Hydro/MERIT-Basins — https://mghydro.com/watersheds/

**México**:
- SACMEX Pluviómetros — https://data.sacmex.cdmx.gob.mx/pluviometros/
- SACMEX Radar SEGIAGUA — https://aplicaciones.sacmex.cdmx.gob.mx/radar-meteorologico/
- CONAGUA SMN Web Service — https://smn.conagua.gob.mx/es/web-service-api
- CONAGUA EMAs (5400 estaciones) — https://sih.conagua.gob.mx/
- CENAPRED Atlas Nacional de Riesgos — http://www.atlasnacionalderiesgos.gob.mx/
- SGIRPC CDMX — https://datos.cdmx.gob.mx/organization/secretaria-de-gestion-integral-de-riesgos-y-proteccion-civil
- Atlas Riesgos CDMX — https://www.atlas.cdmx.gob.mx/
- Atlas Precipitación ICAyCC-UNAM — https://atlas.atmosfera.unam.mx/
- Quiahua UNAM — https://www.atmosfera.unam.mx/quiahua-monitoreo-ciudadano-de-lluvia/
- SIMAT/RAMA/REDMET CDMX — http://aire.cdmx.gob.mx/

**Inundación pronóstico**:
- Google Flood Hub / Flood Forecasting API — https://developers.google.com/flood-forecasting (waitlist Cloud Project)
- GDACS / Copernicus EMS

**Subsidence/drenaje**:
- InSAR Sentinel-1 procesado (EGMS/Capella X-band)
- OpenStreetMap Overpass (`waterway=drain`, `man_made=storm_drain`) — https://overpass-turbo.eu/

### 5.4 Conexión aire ↔ inundación (justificación científica)

1. **Temporada lluvias = PM2.5 bajo** (washout), **pero drizzle con humedad >90% → PM2.5 sube** (wet growth aerosol). AirWay primer modelador.
2. **Post-inundación 48-72h** → spike hongos/mohos interiores; IOM estima 20% asma USA atribuible a dampness.
3. **Basura acumulada post-flood** → quemas informales → PM2.5 + CO (ya medido por RAMA).
4. **Aedes aegypti** expansión por calentamiento + inundaciones; detectado CDMX desde 2015.
5. **Leptospirosis** Brazil 2024: 958 casos, 30 muertes (10.3× baseline). Paralelo Chalco/Poza Rica.
6. **Asma/EPOC post-flood**: moho + humedad + partículas + estrés psicológico.

---

## <a id="tema-4-cv"></a>6. TEMA 4 — Computer Vision para identificación de emisiones (el más detallado)

### 6.1 20 propuestas experimentales ranqueadas

#### CV1 — "AirWay Lens": YOLO11-Fire+Smoke CoreML + AR overlay ★★★★★ — **PRIORIDAD MÁXIMA**
Usuario apunta cámara → detecta chimeneas/humo en tiempo real → overlay AR con bounding box + badge "Fuente emitiendo" + PM2.5 proxy.
- **Stack:** YOLOv10/11 pretrained D-Fire + HF weights → CoreML (`yolo export format=coreml nms=True`) → VNCoreMLRequest en AVCaptureVideoDataOutput → overlay RealityKit.
- **Benchmark esperado:** 60 FPS iPhone 15 Pro+, mAP@50 80-85%.

```swift
let config = MLModelConfiguration()
config.computeUnits = .all
let smokeModel = try YOLOv11FireSmoke(configuration: config).model
let vnModel = try VNCoreMLModel(for: smokeModel)

let request = VNCoreMLRequest(model: vnModel) { req, _ in
    guard let results = req.results as? [VNRecognizedObjectObservation] else { return }
    for obs in results where obs.confidence > 0.45 {
        let label = obs.labels.first?.identifier ?? "?"
        self.arOverlayManager.update(label: label, box: obs.boundingBox, conf: obs.confidence)
    }
}
request.imageCropAndScaleOption = .scaleFill

func showEmissionPlumeAR(box: CGRect, conf: Float, label: String) {
    let anchor = AnchorEntity(world: raycastWorldPoint(from: box.center))
    let badge = makeBadgeEntity(text: "\(label) • \(Int(conf*100))%")
    anchor.addChild(badge)
    particleManager.emitFrom(anchor: anchor, direction: currentWindDir, count: 200)
    arView.scene.addAnchor(anchor)
}
```

**Integración:** reusa `arView` y `particleManager` (2000 partículas existentes). El detector añade fuentes emisoras como **anchors**; las partículas emergen de ellas en vez de caer del cielo uniforme. **Reusa infraestructura AR al 100%**.

#### CV2 — "Cielo → AQI": EfficientNet-B0 CoreML regresor ★★★★
Foto del cielo → predice PM2.5 y AQI de CDMX. Comparación con estación oficial.
- **Stack:** Fine-tune EfficientNet-B0 sobre PM25Vision + 200-500 fotos propias CDMX con PM2.5 reference SEDEMA → CoreML.
- **Benchmark:** R² 0.70-0.85, RMSE 8-15 μg/m³, clasificación 5-bucket ~70%.

```swift
let ds = MLDataTable(contentsOf: URL(...))
let model = try MLImageRegressor(trainingData: ds,
    targetColumn: "pm25", featureColumn: "image")
```

**Truco diferencial:** combinar predicción visual con GPS + AQI oficial. Si difieren >30 μg → flag "posible fuente cercana no monitoreada" → usuario = sensor crowdsourced.

#### CV3 — "Gemini Vision Ask": endpoint VLM zero-shot ★★★★★ — **La más rápida (2-3h)**
Foto cualquiera → backend Gemini 2.5 Flash Vision → JSON estructurado con tipo de fuente/severidad/recomendación.

```python
# backend-api/src/interfaces/api/routes/vision.py
from google import genai
from pydantic import BaseModel

class EmissionAnalysis(BaseModel):
    source_type: str  # "smokestack" | "diesel_vehicle" | "burn_pile" | "construction_dust" | "clean"
    severity: int     # 0-10
    estimated_pm25_contribution: float
    reasoning: str
    recommended_action: str

PROMPT = """Analyze this image taken in Mexico City. You are an air quality expert.
Identify any visible emission sources. Respond in structured JSON with:
- source_type: [smokestack, diesel_vehicle, burn_pile, construction_dust,
  domestic_cooking_fire, wildfire, clean, other]
- severity: 0-10
- estimated_pm25_contribution: rough μg/m³ at 100m
- reasoning: 1-sentence visual cues
- recommended_action: advice for nearby citizen"""

@router.post("/vision/emission_source")
async def analyze_emission(image_b64: str, lat: float, lon: float):
    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    resp = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[{"role":"user","parts":[
            {"inline_data": {"mime_type":"image/jpeg","data": image_b64}},
            {"text": PROMPT}
        ]}],
        config={"response_mime_type":"application/json",
                "response_schema": EmissionAnalysis})
    return resp.parsed
```

**Integración:** tu `backend-api` ya tiene key Gemini configurada (.env), timeout 45s post-commit `cc17f2b`. Solo añadir ruta.

#### CV4 — "Tráfico → Contaminación": YOLO11 vehículos + heatmap AR
Cuenta vehículos (car/motorcycle/bus/truck COCO classes 2/3/5/7) × factores emisión → heatmap AR sobre pavimento.
- **Stack:** YOLO11n COCO + ARKit plane detection + Metal shader heatmap.

```swift
let emissionFactors: [String: Float] = [
    "car": 120, "motorcycle": 85, "bus": 680, "truck": 750  // g CO2/km
]
let totalEmission = detections.reduce(0) { $0 + (emissionFactors[$1.label] ?? 0) }
heatmapLayer.updateIntensity(totalEmission / 5000)
```

#### CV5 — "Verificentro/Hoy No Circula Scanner" ★★★★
Calcomanía holográfica del parabrisas → Vision OCR + detector color HSV + lookup offline días restricción + emisiones estimadas.

```swift
let textReq = VNRecognizeTextRequest { req, _ in
    let strings = (req.results as? [VNRecognizedTextObservation])?.compactMap {
        $0.topCandidates(1).first?.string
    } ?? []
    if let holo = strings.first(where: { ["00","0","1","2","EXENTO"].contains($0.uppercased()) }) {
        let table: [String:(pmDaily: Int, days: [Int])] = [
            "00": (5, []),          "0":  (10, [0]),
            "1":  (25, [1,3,5]),    "2":  (40, [1,2,3,4,5]),
            "EXENTO": (0, [])
        ]
        viewModel.updateStickerInfo(holo, info: table[holo])
    }
}
textReq.recognitionLanguages = ["es-MX"]
textReq.recognitionLevel = .accurate
```

**Idea muy CDMX-específica, nadie la tiene**. Tiempo 3-5h.

#### CV6 — "Quema Nocturna Detector" (Night Mode CNN)
En noche (cuando más hay quemas basura CDMX) detecta naranja/rojo + humo. YOLO fine-tuned "fire at night" + frame differencing + HSV mask.

```swift
func detectNocturnalBurn(frame: CVPixelBuffer) -> Bool {
    let cnnConf = runYOLO(frame)
    let frameDelta = computeFrameDifference(frame)
    let fireColorRatio = hsvMask(frame, hRange: 0...30, sRange: 0.5...1.0)
    return cnnConf > 0.5 || (frameDelta > threshold && fireColorRatio > 0.02)
}
```

#### CV7 — "Humo Negro Diésel Alerter" (enforcement ciudadano) ★★★★★
3-5s video → clasifica humo negro vs vapor blanco → reporte con placa OCR + geo al CAMe/SEDEMA.
- **Stack:** DB-Net o Y-MobileNetV3 (95.17% acc) + OCR placa + backend forwarded.

#### CV8 — "Smokestack Labeler" (chimeneas industriales detalladas) ★★★★★
Detecta chimeneas industrial activas vs inactivas. Overlay AR con flecha + severidad. RETC lookup → empresa asociada.
- **Stack:** YOLO fine-tuned "industrial_smokestack" + clasificador binario emitting/not + SAM/Mask2Former segmentar pluma → medir área.

#### CV9 — "Obra en Construcción → Polvo"
Reconoce obras (malla verde, andamio, grúa, escombro) + DustNet++ para densidad.
- **Stack:** YOLO11 con clases custom + DustNet++ regressor.

#### CV10 — "Apunta a la calle y predice AQI en 5 min" (Time-Lapse Flux)
Usuario fija teléfono 5 min → count vehicular por segundo + haze variación + color shift cielo → predice AQI 15-30 min.
- **Stack:** pipeline frame-by-frame + 1D CNN/Transformer temporal on-device + Combine.

#### CV11 — "Apple Vision AR: Pluma Virtual desde Fuente" ★★★★★
Detecta chimenea/auto/fogata → partículas AR que simulan pluma real según viento (Open-Meteo) y severidad.
- **Stack:** reusa tus 2000 partículas + emisión direccional desde puntos detectados + Metal shader gradientes.
- **Tiempo:** 4-6h. **Reutiliza infraestructura existente**.

#### CV12 — "OCR Placa → Make/Model → Emisiones"
YOLO placa + vehículo → OCR + ResNet50 VMMRdb → tabla emisiones SEDEMA/EPA.
- **Stack:** Vision + ResNet50 fine-tune VMMRdb 291,752 imgs.
- **Privacy-sensitive**: no mostrar placa.

#### CV13 — "Sky Color → Composición Contaminante"
Color dominante horizonte: marrón-ámbar → NO₂, azul-gris → O₃, amarillo-blancuzco → PM2.5.
- **Stack:** UIImage → recorte 30% superior → histograma HSV → bayesiana simple o CNN 3-class.
- **Tiempo:** 2-3h. Quick win.

#### CV14 — "Cámara termográfica virtual (LiDAR)"
iPhone Pro: depth + RGB → pseudo-thermal colorea pixeles lejos/haze como cálidos. Aproxima dónde es más denso el smog.
- **Stack:** ARKitSceneReconstruction + depth + compositing Metal.

#### CV15 — "FastVLM On-Device Q&A" ★★★★★
Usuario apunta cámara → preguntas libres "¿este auto contamina mucho?", "¿qué es ese humo?". FastVLM 60 FPS on-device.

```swift
import MLX
import MLXFastVLM

let vlm = try await FastVLM.load(.fastVitHD_S)
let result = try await vlm.generate(
    image: pixelBuffer,
    prompt: "Describe any visible air pollution sources. Severity 0-10.",
    maxTokens: 128
)
```

**Diferenciador brutal**: Apple Intelligence de AirWay sin costo API, sin latencia, offline.

#### CV16 — Multi-cámara crowd-sourced triangulación 3D pluma
5+ iPhones mismo evento → SfM simplificado → volumen 3D pluma.
- **Moonshot 2 días**; proto con 2 fotos calibradas.

#### CV17 — Stereo Photogrammetry 2 iPhones = dispersión 3D
Multipeer Connectivity sincroniza → reconstrucción 3D.
- **Moonshot**. Sincronización es el reto.

#### CV18 — Barbacoa/Fogón urbano detector
Parrilladas en parques/azoteas (fuente subestimada PM2.5 fines de semana CDMX).
- **Stack:** fine-tune YOLO D-Fire + subset "barbecue" + contexto parque.

#### CV19 — Fuego terraza/balcón
Variante urbana wildfire detection. Integra con Waze-like reporting.

#### CV20 — Fine-tune Foundation Model con fotos del usuario (iOS 26)
Usuario etiqueta sus observaciones (chimenea del barrio emitiendo lunes). Modelo on-device se adapta.
- **Estado abril 2026**: Foundation Models expone QA; fine-tuning on-device aún restringido a LoRA server-side iOS 26 beta. Mock en hackathon.

### 6.2 Papers clave

1. ESCFM-YOLO ene 2026 (89.2% mAP@50, 1.89M params, 60 FPS) — https://www.mdpi.com/2076-3417/16/2/778
2. YOLO Comparative Study abr 2025 — https://www.sciencedirect.com/science/article/pii/S2590123025009454
3. HPO-YOLOv5 Indoor Fire+Smoke 2025 — https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0322052
4. Plume YOLO + Knowledge Distillation nov 2025 — https://www.mdpi.com/2504-446X/9/12/827
5. FCMI-YOLO PLOS 2025 — https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0329555
6. DSS-YOLO Sci Reports 2025 — https://www.nature.com/articles/s41598-025-93278-w
7. Y-MobileNetV3 smoky vehicle (95.17% acc) — https://pmc.ncbi.nlm.nih.gov/articles/PMC10574957/
8. DB-Net vehicle smoke segmentation — https://www.mdpi.com/2076-3417/13/8/4941
9. Spatial-temporal CNN video smoke (97.0% detection, 5ms/frame)
10. Truck black smoke edge computing Xuchang 2025 — https://link.springer.com/article/10.1007/s11227-025-07276-w
11. Multi-Dim Black Smoke Diesel MDPI 2025 — https://www.mdpi.com/2073-8994/17/11/1886
12. **PM25Vision arXiv 2509.16519 sep 2025** (11,114 imgs, 11 años) — https://arxiv.org/abs/2509.16519 | https://huggingface.co/datasets/DeadCardassian/PM25Vision
13. AQE-Net Remote Sensing 2022 (70.1% acc) — https://www.mdpi.com/2072-4292/14/22/5732
14. AQI-Net + Grad-CAM Cambridge (99.81%) — https://www.cambridge.org/core/journals/environmental-data-science/article/air-quality-prediction-from-images-in-indonesia
15. Prior-Enhanced Network Dark Channel + Saturation — https://www.researchgate.net/publication/375923106
16. ViT vs Swin SAPID (ViT 97%, Swin 96%, ResNet-50 64%) — https://www.genesispcl.com/articles/vol-2-issue-1/cser-25-21-0003/
17. Forecasting AQ with VLMs arXiv 2509.15076 ICCV-W 2025 — https://arxiv.org/abs/2509.15076
18. Mobile-Captured Images CNN arXiv 2501.03499 ene 2025 — https://arxiv.org/abs/2501.03499
19. DustNet++ IJCV 2025 — https://link.springer.com/article/10.1007/s11263-025-02376-9
20. Eyes on the Environment datasets review arXiv 2503.14552 — https://arxiv.org/abs/2503.14552
21. **Open-Vocab OD + Mask2Former ES&T 2025** (chimeneas como predictor) — https://pubs.acs.org/doi/10.1021/acs.est.5c09687
22. HybriDet CNN+Transformer wildfire RS oct 2025 — https://www.mdpi.com/2072-4292/17/20/3497
23. Air Cognizer TF Lite Android — https://blog.tensorflow.org/2019/02/air-cognizer-predicting-air-quality.html

### 6.3 Datasets y modelos pretrained

| Dataset/Modelo | Tamaño | URL | Uso AirWay |
|---|---|---|---|
| D-Fire | 21,527 imgs, 26,557 boxes | https://github.com/gaia-solutions-on-demand/DFireDataset | Base YOLO smoke |
| FASDD | 120,000+ imgs 3 subsets (CV/UAV/RS) | https://github.com/openrsgis/FASDD | Mejor multi-scene |
| **PM25Vision** | 11,114 imgs + PM2.5 11 años | https://huggingface.co/datasets/DeadCardassian/PM25Vision | Entrenar sky→AQI |
| KARACHI-AQI | 1,001 imgs | (paper AQE-Net) | Transfer learning |
| Wildfire Smoke Roboflow | 737 imgs + pretrained | https://universe.roboflow.com/brad-dwyer/wildfire-smoke | Zero-shot ready |
| Wildfire V2 Atlantic Tech | 56,029 imgs | https://universe.roboflow.com/atlantic-technological-university/wildfire-v2 | Uno de los más grandes |
| YOLOv10 Fire+Smoke HF | Pretrained weights | https://huggingface.co/TommyNgx/YOLOv10-Fire-and-Smoke-Detection | Descarga directa |
| **VMMRdb** | 291,752 imgs 9,170 clases | https://github.com/faezetta/VMMRdb | Make/model vehicle |
| Cityscapes | 5,000 finos + 30 clases | https://www.cityscapes-dataset.com/ | Seg semántica urbana |
| ADE20K | 20,210 train + 150 clases | https://groups.csail.mit.edu/vision/datasets/ADE20K/ | OWL-ViT + Mask2Former |
| **MobileCLIP/MobileCLIP2 (Apple)** | S0 4.8× más rápido ViT-B/16 | https://github.com/apple/ml-mobileclip | Zero-shot on-device |
| **FastVLM (Apple CVPR 2025)** | TTFT 85× más rápido | https://github.com/apple/ml-fastvlm | VLM on-device |
| SAM 3 / SAM 3D (Meta nov 2025) | Prompt-texto segmentation + 3D | https://about.fb.com/news/2025/11/new-sam-models-detect-objects-create-3d-reconstructions/ | Backend seg pluma |

### 6.4 VLMs para aire — estado del arte

| Modelo | Lugar | Latencia | Accuracy zero-shot AQ | Costo |
|---|---|---|---|---|
| GPT-4o Vision | Cloud | 1-3s | ~80% categorical | $5/1M in |
| **Gemini 2.5 Flash** | Cloud | 0.63s TTFT, 205 tok/s | 75-85% | **$0.30/1M** — mejor precio |
| Gemini 3 Pro (nov 2025) | Cloud | 1-2s | SOTA vision | Premium |
| Sonnet Vision (cloud LLM alt.) | Cloud | 1-2s | Excelente razonamiento | $3/1M |
| **FastVLM (Apple)** | **On-device** | **60 FPS** | ~70% smaller | **Gratis** |
| MobileCLIP-S0 | On-device | 3-15ms | Zero-shot retrieve | Gratis |
| Foundation Model (iOS 26) | On-device | ~100ms | Limitada a sistema | Gratis |
| MLX VLMs (Llama-Vision, Qwen-VL, LLaVA) | On-device mlx-swift | 400+ tok/s M-chip | 70-85% | Gratis |

**Accuracy vs sensor físico**: mejor hybrid CNN-LSTM sobre imágenes = **R²=0.94 PM2.5, RMSE 5.11 μg/m³** — cerca de sensores low-cost calibrados (Plantower PMS5003 típico 10-15 μg/m³). VLMs zero-shot 5-10 puntos abajo pero ganan en generalización + QA.

### 6.5 Benchmark esperado CDMX realista

| Tarea | Modelo | Accuracy realista |
|---|---|---|
| Smoke BBox | YOLO11n + D-Fire | mAP@50 75-85% |
| Fire+Smoke seg | DeepLabv3+ | IoU 80-85% |
| Vehicle count | YOLO11n COCO | 85-92% por clase |
| Black smoke vehicle | Y-MobileNetV3 | 80-85% |
| Sky→AQI regression | EfficientNet-B0 PM25Vision | R² 0.70-0.85, RMSE 8-15 |
| Sky→AQI clasif | ViT-B/16 SAPID | 70-80% CDMX |
| VLM zero-shot QA | Gemini 2.5 Flash | 75-85% |
| License plate OCR | Vision framework | 85-92% |
| VMMR | Two-branch-two-stage | ~85-92% top-5 |
| Dust density | DustNet++ | R² 0.75-0.85 |

---

## <a id="stack-consolidado"></a>7. Stack técnico consolidado (iOS 26 + backend Django)

### 7.1 Frontend iOS (Swift/SwiftUI)

```
frontend/AcessNet/Features/
├─ AirQuality/
│  ├─ Views/
│  │  ├─ AQIHomeView.swift            ← añade toggle "Modo Temporada Lluvias"
│  │  ├─ EnhancedTabBar.swift         ← añade tabs "Lens", "Simulador", "Flood"
│  │  └─ EmissionCameraView.swift     ← NUEVO (CV1, CV15)
│  └─ Services/
│     ├─ EmissionDetectionService.swift ← NUEVO (YOLO CoreML)
│     ├─ SkyAQIService.swift            ← NUEVO (EfficientNet-B0)
│     └─ VerificentrolScannerService.swift ← NUEVO
├─ Simulation/                         ← NUEVO
│  ├─ Views/
│  │  ├─ CityLabView.swift            ← S1 What-If Reforma
│  │  ├─ AirGardenView.swift          ← S4 sandbox
│  │  └─ ScenarioGPTView.swift        ← S10 Foundation Models
│  └─ Engines/
│     ├─ LocalFNOEngine.swift          ← S1
│     ├─ CellularAutomataMetal.swift   ← S4
│     └─ LBMMetal4Engine.swift         ← S7 moonshot
├─ Flood/                              ← NUEVO
│  ├─ Views/
│  │  ├─ FlashFloodAlertView.swift    ← F1
│  │  ├─ ARFloodPreviewView.swift     ← F4
│  │  └─ DrainMapperView.swift         ← F5
│  └─ Services/
│     ├─ ConvLSTMFloodService.swift    ← F1
│     └─ HydroOnDeviceService.swift    ← F6
├─ Emissions/                          ← NUEVO
│  ├─ Views/
│  │  ├─ PollutionSourceMapView.swift  ← E1
│  │  ├─ MethaneAlertView.swift        ← E2
│  │  └─ PersonalFootprintView.swift   ← E3
│  └─ Services/
│     ├─ ClimateTraceService.swift     ← E1
│     └─ SoundEngineClassifier.swift   ← E11
├─ AR/
│  └─ ParticleSystem.swift             ← REUSA: emitFrom(anchor:direction:count:)
├─ Health/Views/PPIDashboardView.swift  ← extender HealthExposure (S12)
└─ Shared/
   ├─ Models/VulnerabilityProfile.swift ← añade pregnancyWeek, elderlyDep, informalWorker
   └─ Services/
      ├─ FoundationModelsService.swift  ← ScenarioGPT (S10)
      └─ FastVLMService.swift           ← VQA (CV15)
```

### 7.2 Backend Django

```
backend-api/src/interfaces/api/routes/
├─ views.py                            ← existente
├─ simulation.py                       ← NUEVO
│  ├─ POST /api/v1/simulation/close_street  (S1)
│  ├─ POST /api/v1/simulation/building_eia  (S8)
│  └─ POST /api/v1/simulation/rl_policy     (S3)
├─ emissions.py                        ← NUEVO
│  ├─ GET /api/v1/emissions/sources_near    (E1)
│  ├─ GET /api/v1/emissions/methane_plumes  (E2)
│  ├─ POST /api/v1/emissions/rag_esg        (E7)
│  └─ POST /api/v1/emissions/industry_anomaly (E5)
├─ flood.py                            ← NUEVO
│  ├─ POST /api/v1/flood/predict_2h     (F1)
│  ├─ POST /api/v1/flood/post_aqi_advice (F7, Gemini)
│  ├─ POST /api/v1/flood/triage          (F9)
│  └─ POST /api/v1/flood/evacuation_route (F11)
└─ vision.py                           ← NUEVO
   ├─ POST /api/v1/vision/emission_source (CV3, Gemini Vision)
   ├─ POST /api/v1/vision/vehicle_plate   (CV12)
   └─ POST /api/v1/vision/sky_aqi         (CV2)
```

### 7.3 Modelos CoreML a empacar

| Modelo | Tamaño | Usado en |
|---|---|---|
| SmokeDetector.mlpackage (YOLO11n D-Fire) | 6-10 MB | CV1, CV6, CV7, CV8, CV18, CV19 |
| SkyAQI.mlpackage (EfficientNet-B0) | 25 MB | CV2, CV13 |
| VehicleCounter.mlpackage (YOLO11n COCO) | 4 MB | CV4, CV12 |
| VerificentrolOCR (Vision built-in) | 0 MB | CV5 |
| EngineClassifier (MLSoundClassifier) | 5 MB | E11 |
| ConvLSTMFlood.mlpackage | 10-20 MB | F1 |
| MobileCLIP-S0 (opcional) | 50 MB | CV15 zero-shot |
| FastVLM-S (moonshot) | 500 MB | CV15 VQA completo |

**Total base:** ~80 MB (sin moonshots). Aceptable para AirWay.

### 7.4 APIs externas consumidas (todas gratis o ya configuradas)

- **Ya en AirWay:** OpenAQ v3, WAQI, Open-Meteo, NASA TEMPO, Gemini 2.5 Flash.
- **Nuevas:** Climate TRACE, Carbon Mapper, EMIT, UNEP MARS, GPM IMERG (Earth Engine), GSMaP, Sentinel-5P TROPOMI, Sentinel-1 SAR (Copernicus Data Space), MODIS MCDWD, OPERA DSWx, SMAP, Copernicus DEM GLO-30, CONAGUA SMN, SACMEX Pluviómetros, CENAPRED, Google Flood Hub (waitlist), RETC, INEM, DENUE, Electricity Maps, Apple WeatherKit.

### 7.5 Frameworks Apple críticos

- **Foundation Models (iOS 26)**: `@Generable`, `LanguageModelSession`, function calling.
- **Vision + CoreML**: `VNCoreMLRequest`, `VNRecognizeTextRequest`, `VNClassifyImageRequest`, `VNGenerateImageFeaturePrintRequest`.
- **ARKit**: `ARGeoTrackingConfiguration`, `ARMeshAnchor`, `sceneReconstruction`, LiDAR `ARDepthData`.
- **RealityKit 4**: `ParticleEmitterComponent`, particle system reusable.
- **Metal 4 + MetalFX (WWDC25)**: neural rendering para LBM/CA.
- **MapKit 3D**: buildings, ARGeoTracking, overlays.
- **WeatherKit**: minute-by-minute 1h + severe alerts (500k calls/mes).
- **HealthKit**: PPI Score existente + exposure ride-along.
- **SoundAnalysis**: `SNClassifySoundRequest`, CreateML `SoundClassifier`.
- **CoreMotion**: `CMMotionActivityManager` (auto/pie/bici), `CMAltimeter`, `CMHeadphoneMotionManager`.
- **MLX Swift**: FastVLM, MobileCLIP, LLMs quantizados.
- **WidgetKit + Live Activities + Dynamic Island**: alertas persistentes.
- **BackgroundTasks (BGAppRefreshTask, BGProcessingTask)**: sync nocturno datasets pesados.

---

## <a id="priorizacion-cruzada"></a>8. Priorización cruzada — Combo ganador 48h

### 8.1 Tier S — Quick wins imprescindibles (bajo riesgo, alto wow)

| # | Idea | Tema | Tiempo | Wow | Justificación |
|---|---|---|---|---|---|
| 1 | **F7 Post-AQI Gemini** | Inundación | 6-8h | 5/5 | Más rápida. Cierra aire↔agua. Usa stack existente. |
| 2 | **CV3 Gemini Vision** | CV | 2-3h | 5/5 | Una tarde. Feature demo-friendly. |
| 3 | **S9 Contingencia 72h** | Simulación | 14-18h | 4/5 | Ensemble sobre GradientBoosting actual. |
| 4 | **S12 HealthExposure** | Simulación | 10-14h | 3/5 | Integra 100% del stack (Watch, ruta, GradientBoosting). |
| 5 | **CV5 Verificentro OCR** | CV | 3-5h | 4/5 | Muy CDMX, nadie lo tiene. |
| 6 | **CV13 Sky Color Bayes** | CV | 2-3h | 3/5 | Super simple, visual. |

**Total Tier S:** ~38-51h → caben en hackathon. Cubre 4 temas.

### 8.2 Tier A — Diferenciadores fuertes del pitch

| # | Idea | Tema | Tiempo | Wow |
|---|---|---|---|---|
| 7 | **S1 CityLab Reforma What-If** | Simulación | 18-24h | 5/5 |
| 8 | **CV1 AirWay Lens YOLO AR** | CV | 6-8h | 5/5 |
| 9 | **CV11 AR Pluma Virtual** | CV | 4-6h | 5/5 |
| 10 | **F1 FlashFlood 2H** | Inundación | 24-36h | 5/5 |
| 11 | **F4 AR Flood Preview LiDAR** | Inundación | 24-36h | 5/5 |
| 12 | **E1 Mapa Fuentes Vivas** | Emisiones | 36-48h | 5/5 |
| 13 | **E2 MARS Methane Mirror** | Emisiones | 1 día | 5/5 |
| 14 | **F3 Modo Cuidador Inundación** | Inundación | 18-24h | 4/5 |
| 15 | **F2 Modo Temporada Lluvias** | Inundación | 12-18h | 4/5 |

### 8.3 Tier B — Extras impresionantes si sobra tiempo

- S2 AR Plume Vision simulación
- S4 AirGarden sandbox
- S10 ScenarioGPT Foundation Models
- CV4 Tráfico → heatmap
- CV7 Humo negro diésel alerter
- E3 Atribución personal CO₂
- E11 Clasificador motor sonido
- F5 LiDAR Drain Mapper
- F6 Hydro-On-Device Manning

### 8.4 Plan día-por-día (para equipo de 4 personas, 48h)

**Día 1 — Sábado 20 abril 2026 (12h efectivas)**

| Hora | Dev 1 (Backend+Simulación) | Dev 2 (iOS+CV) | Dev 3 (iOS+Flood) | Diseñador |
|---|---|---|---|---|
| 09-11 | F7 Gemini flood prompt | CV3 Gemini Vision endpoint | F2 Modo Temporada Lluvias UI | 3 pantallas en Figma |
| 11-14 | S9 Contingencia 72h ensemble | CV1 YOLO CoreML export + integración | F1 ConvLSTM CoreML setup | Assets AR |
| 15-18 | E7 Gemini RAG ESG | CV1 AR overlay + reuse particles | F1 backend `/flood/predict_2h` | AR Flood Preview mockup |
| 19-21 | S1 backend FNO stub | CV5 Verificentro OCR | F4 AR Flood Preview LiDAR | Narrativa pitch |

**Día 2 — Domingo 21 abril 2026 (10h efectivas)**

| Hora | Dev 1 | Dev 2 | Dev 3 | Diseñador |
|---|---|---|---|---|
| 09-12 | S1 CityLab UI + overlay heatmap | CV11 AR pluma virtual desde fuente | F3 Modo Cuidador + CloudKit | Polish AR |
| 12-14 | E1 Mapa Fuentes Climate TRACE + MapKit | CV13 Sky Color Bayes | F4 LiDAR refinamiento | Live Activity |
| 14-17 | E2 MethaneSAT + MARS push | S12 HealthExposure + Watch | Debug flood pipeline | Stickers demo |
| 17-19 | Demo video + rehearsal | Demo video | Demo video | Slide deck + pitch |
| 19-21 | Pitch final 3 min | Pitch final | Pitch final | Pitch final |

**Entregable final al jurado:**
- **Demo iPhone**: CV1 Lens → detecta chimenea → CV11 pluma virtual AR → CV3 Gemini Vision explica → S12 exposición real en Watch.
- **Demo mapa**: E1 Fuentes vivas → F2 Temporada Lluvias → F1 alerta 2h → S1 CityLab What-If.
- **Demo social**: F3 Modo Cuidador (abuela en Iztapalapa) → F7 post-AQI Gemini (moho).

---

## <a id="moonshots-consolidados"></a>9. Moonshots consolidados (20 ideas)

### Simulación urbana
1. **CDMX en vivo con 3D Gaussian Splatting** — densidad de splat = PM2.5 local. Vuelas 3D por la ciudad, los gaussianos son el aire.
2. **CityGPT México**: fine-tune Prithvi-EO-2.0 sobre HLS+TEMPO+RAMA CDMX. Primer "LLM de barrio" del mundo.
3. **Agent Simulation 10M NPCs CDMX distribuidos**: cada iPhone simula 100 agentes de su colonia con Foundation Models. La ciudad se auto-simula con los usuarios como compute.
4. **Time-Travel AQI 1990-2050**: DestinE Climate DT + Gemini narración. "Tu colonia en 1990 / hoy / 2050".
5. **Air Vote referendum urbano**: ciudadanos votan medidas, FNO simula política colectiva cada hora.

### Emisiones
6. **LiDAR + CNN termografía de emisiones** iPhone Pro: point cloud segmentado + TROPOMI overhead → "chimenea roja = excede NOM-085".
7. **On-Device FootNet CoreML inverse modeling**: cada 15 min el iPhone resuelve inversión bayesiana local e imputa emisión en grid 1×1 km.
8. **Apple Foundation Models "Reporte Personal de Emisiones"**: `@Generable` + narrativa on-device sin nube.
9. **Federated Learning emisiones vehiculares** con OBD-II BT ($30 dongle): BMC-GRU sobre PIDs. Paper garantizado.
10. **AR-Emission Tag público**: apunta cámara a cualquier chimenea → RETC + Carbon Mapper + NOM overlay con visual SLAM.

### Inundaciones
11. **AirWay Twin CDMX**: SceneKit gemelo digital de la cuenca con simulación flash flood tiempo real. Usuario llueve sobre mapa.
12. **Federated Rain Sensing**: 10,000 iPhones como pluviómetros LiDAR FL. Cierra gap 2,800 EMAs vs 20M habitantes.
13. **Lluvia → Pulmón modelo causal**: pipeline causal precipitación → mohos → exacerbación asma HealthKit → recomendaciones.
14. **Sentinel-1 Tiny-U-Net on-device**: U-Net cuantizada segmenta agua en SAR local. Primera app iOS con SAR flood detection.
15. **Predicción colapso Gran Canal**: InSAR subsidence + pluviómetros + carga drenaje → LSTM probabilidad rebase 6-24h.

### Computer Vision
16. **Drone + Vision Pro controller**: DJI SDK + YOLO pluma en feed + AR cluster en Vision Pro.
17. **iPhone LiDAR como PM sensor**: noise pattern LiDAR degrada con partículas. Ningún paper lo hace para air quality todavía.
18. **Satélite TEMPO + foto in-situ + crowdsourced VLM** = triple fusion publicable.
19. **Light Painting AR nocturno**: long-exposure + LED pulse otros teléfonos (Nearby Interaction) → pinta el aire según AQI.
20. **Federated VLM visual AQI (VisionAir-style)**: cada user entrena con sus fotos locales sin enviar imágenes crudas.

---

## <a id="narrativa-pitch"></a>10. Narrativa de pitch (3 min)

### Apertura (0:00-0:30)
> "7 millones de muertes al año por contaminación del aire (OMS). En CDMX el 61% del CO₂ viene del transporte, 95% de barrios pobres consideran el aire un gran problema, pero solo el 53% conoce el AQI. Las apps comerciales muestran un número. AirWay hace cuatro cosas que nadie más hace."

### Demo 1 — Computer Vision (0:30-1:00)
> "María sale del metro. Apunta el iPhone a un camión echando humo: **AirWay Lens** detecta el humo negro con YOLO on-device y con Gemini Vision explica que es diésel sucio, estima +40 μg/m³ de PM2.5 y sugiere cubrebocas N95. OCR de la placa envía el reporte al CAMe. Todo en 3 segundos."

### Demo 2 — Simulación (1:00-1:30)
> "Selecciona 'Cerrar Reforma 2 horas' en el **CityLab**. Un Fourier Neural Operator entrenado en CFD real proyecta cómo cambia el AQI en toda la colonia. Foundation Models on-device narra: 'Evitarías 35 μg/m³ en Cuauhtémoc, pero PM2.5 subiría 12% en Insurgentes por desvío'. Los jueces tienen ahora un simulador urbano en el bolsillo."

### Demo 3 — Inundaciones + Aire (1:30-2:00)
> "Son las 7 AM. La abuelita de María vive en Iztapalapa. **AirWay FlashFlood 2H** combina GPM IMERG, radar SACMEX y un ConvLSTM on-device para predecir 40 cm de agua en su cuadra en 90 minutos. María recibe push en el **Modo Cuidador**, llama. 48 horas después, cuando el aire indoor llena de moho, **AirWay + Gemini** le dice cuánto ventilar y qué mascarilla usar porque su asma está en zona roja."

### Demo 4 — Emisiones + Impacto social (2:00-2:30)
> "Detrás de cada número hay un responsable. El **Mapa de Fuentes Vivas** cruza Climate TRACE, RETC y TROPOMI para mostrarte las 5 industrias que más contaminan tu colonia. ¿Vendedor ambulante? No te decimos 'quédate en casa' — te decimos en qué horario trabajar y qué esquina mover tu puesto. ¿Embarazada asmática? Un modelo CoreML personal entrena en tu iPhone sin que tus datos salgan nunca."

### Cierre (2:30-3:00)
> "Esto es Human-Centered AI de verdad: simula contigo, no decide por ti. Atribuye fuentes, no culpa víctimas. Ve lo invisible con tu cámara. Protege al que cocina con leña tanto como al corredor. Todo con Apple Foundation Models, CoreML on-device, Gemini, y APIs mexicanas que por primera vez alguien se toma el trabajo de conectar. Las 7 millones de muertes son estadística. María es persona. AirWay es para María."

---

## <a id="fuentes"></a>11. Fuentes y referencias clave (por tema)

### 11.1 Simulación urbana
- UrbanGraph — https://arxiv.org/abs/2510.00457
- Local-FNO — https://arxiv.org/abs/2503.19708
- AirPhyNet — https://arxiv.org/html/2402.03784v2
- PINN Inverse Source — https://arxiv.org/abs/2503.18849
- DRL Booth Placement — https://arxiv.org/abs/2505.00668
- Diffusion Microclimate — https://arxiv.org/abs/2501.04847
- GATSim generative agents — https://www.sciencedirect.com/science/article/abs/pii/S0968090X26000641
- Overture Maps — https://docs.overturemaps.org/guides/buildings/
- Apple Foundation Models tech report 2025 — https://machinelearning.apple.com/research/apple-foundation-models-tech-report-2025
- WWDC25 Foundation Models — https://developer.apple.com/videos/play/wwdc2025/286/

### 11.2 Emisiones
- NASA TEMPO NRT — https://www.earthdata.nasa.gov/data/instruments/tempo/near-real-time-data
- Carbon Mapper — https://carbonmapper.org/data
- UNEP MARS — https://www.unep.org/topics/energy/methane/methane-alert-and-response-system-mars
- Climate TRACE — https://climatetrace.org/
- FootNet — https://gmd.copernicus.org/articles/18/1661/2025/
- Vision Transformer methane — https://www.nature.com/articles/s41467-024-47754-y
- SEDEMA Inventario ZMVM 2020 — https://proyectos.sedema.cdmx.gob.mx/datos/storage/app/media/docpub/sedema/inventario-emisiones-cdmx-2020bis.pdf
- RETC México — https://historico.datos.gob.mx/busca/dataset/registro-de-emisiones-y-transferencia-de-contaminantes
- Gately 2017 Urban Hotspots — https://pubmed.ncbi.nlm.nih.gov/28628865/
- Ubiquitous Traffic Emissions Nature Sust 2026 — https://www.nature.com/articles/s41893-026-01797-9

### 11.3 Inundaciones
- Google Flood Nature 2024 — https://www.nature.com/articles/s41586-024-07145-1
- Aurora Nature 2025 — https://www.nature.com/articles/s41586-025-09005-y
- HydroGAT — https://arxiv.org/html/2509.02481
- WWA oct 2025 Mexico — https://www.worldweatherattribution.org/heavy-rainfall-leading-to-widespread-flooding-in-eastern-mexico-disproportionately-impacts-highly-exposed-indigenous-and-socially-vulnerable-communities/
- ICAyCC UNAM Junio 2025 — https://www.atmosfera.unam.mx/el-junio-mas-lluvioso-cdmx/
- SACMEX Pluviómetros — https://data.sacmex.cdmx.gob.mx/pluviometros/
- CONAGUA SMN API — https://smn.conagua.gob.mx/es/web-service-api
- CENAPRED Atlas — http://www.atlasnacionalderiesgos.gob.mx/
- Copernicus DEM — https://portal.opentopography.org/raster?opentopoID=OTSDEM.032021.4326.3
- Quiahua UNAM — https://www.atmosfera.unam.mx/quiahua-monitoreo-ciudadano-de-lluvia/

### 11.4 Computer Vision
- ESCFM-YOLO 2026 — https://www.mdpi.com/2076-3417/16/2/778
- PM25Vision — https://arxiv.org/abs/2509.16519 + https://huggingface.co/datasets/DeadCardassian/PM25Vision
- Apple FastVLM CVPR 2025 — https://github.com/apple/ml-fastvlm
- Apple MobileCLIP — https://github.com/apple/ml-mobileclip
- D-Fire Dataset — https://github.com/gaia-solutions-on-demand/DFireDataset
- FASDD — https://github.com/openrsgis/FASDD
- VMMRdb — https://github.com/faezetta/VMMRdb
- Open-Vocab OD ES&T 2025 — https://pubs.acs.org/doi/10.1021/acs.est.5c09687
- Ultralytics YOLO iOS App — https://github.com/ultralytics/yolo-ios-app
- Apple Visual Intelligence — https://support.apple.com/guide/iphone/use-visual-intelligence-iph12eb1545e/26/ios/26

### 11.5 Datos duros mexicanos
- ProAire ZMVM 2021-2030 — https://www.sedema.cdmx.gob.mx/comunicacion/nota/presentan-programa-de-gestion-para-mejorar-la-calidad-del-aire-de-la-zona-metropolitana-del-valle-de-mexico-proaire-zmvm-2021-2030
- Chalco 2025 inundaciones 80cm — https://www.elfinanciero.com.mx/edomex/2025/05/31/chalco-sufre-estragos-de-la-temporada-de-lluvias-2025-reportan-inundaciones-de-hasta-80-centimetros/
- Greenpeace Chalco — https://www.greenpeace.org/mexico/blog/54492/lo-que-pasa-en-chalco-no-se-queda-en-chalco/
- October 2025 Mexican Floods Wikipedia — https://en.wikipedia.org/wiki/October_2025_Mexican_floods_and_landslides
- Copernicus EMS Mexico Oct 2025 — https://global-flood.emergency.copernicus.eu/news/225-flooding-in-central-and-eastern-mexico-october-2025/
- Mexico City Metro InSAR Nature 2024 — https://www.nature.com/articles/s41598-024-53525-y
- TRUE taxi emissions Mexico City 2024 — https://trueinitiative.org/wp-content/uploads/2024/11/id-79-mexico-city-rs_report_final.pdf

---

## Totales

- **56 ideas experimentales nuevas** distribuidas en 4 temas
- **85 papers académicos 2024-2026** (arXiv, Nature, Science, MDPI, Copernicus, PMC)
- **79 datasets/APIs gratis o de bajo costo** (NASA, ESA, Apple, HuggingFace, gobierno México)
- **20 ideas moonshot** (5 por tema)
- **6 ideas Tier S** implementables en ~38-51h (hackathon 48h)
- **Plan día-por-día** para equipo de 4
- **Narrativa pitch 3 min** ya escrita
- **Stack iOS 26 + Django consolidado** con paths de archivos concretos

Este documento es el complemento técnico del pitch HCAI. Se integra coherentemente con los 5 documentos previos de AirWay. Cada idea tiene viabilidad, wow factor, tiempo estimado y papers de respaldo. Listo para imprimir y usar como referencia durante el hackathon.

> **Próximo paso recomendado:** elegir las 6 ideas Tier S + 2 del Tier A (≈50-55h) y distribuir al equipo. Reservar 4h finales para demo + pitch rehearsal.
