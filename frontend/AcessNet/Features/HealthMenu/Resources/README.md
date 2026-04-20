# HealthMenu · Diagnóstico corporal tipo MGS3

Menú que muestra un modelo anatómico 3D del cuerpo del usuario con los
órganos afectados por contaminación resaltados, más una lista de
tratamientos. Se abre desde `BodyScanHubView` en modo `.saved` (solo si hay
un escaneo LiDAR guardado).

---

## Arquitectura actual (modo por defecto)

**Sin dependencias externas.** El visor 3D es **`AnatomicalModelView`** —
un wrapper SceneKit nativo que carga un USDZ del bundle, hace hit-testing
para detectar qué órgano tocas, y pinta los órganos según el nivel de daño.

Mientras no agregues un USDZ anatómico al bundle, la app renderiza una
**escena de respaldo** (torso translúcido + 6 esferas nombradas como
órganos). Suficiente para probar el flujo completo.

## Agregar el modelo USDZ real (recomendado)

El wrapper busca un archivo llamado **`anatomy_body.usdz`** (o `.usd` /
`.usda` / `.scn` / `.dae`) dentro del bundle.

### Opción A · Z-Anatomy (CC-BY-SA 4.0, más completo)

1. Descargar `.fbx` desde [github.com/LluisV/Z-Anatomy](https://github.com/LluisV/Z-Anatomy)
   (carpeta `Resources/Models/FBX`) o el Google Drive enlazado en el repo.
2. Convertir a USDZ:
   ```bash
   # Requiere Reality Composer Pro (Xcode) instalado
   xcrun usdz_converter input.fbx anatomy_body.usdz
   ```
   Si `usdz_converter` falla, usar **Reality Composer Pro**:
   - Abrir Reality Composer Pro → File → Import → seleccionar `.fbx`.
   - File → Export → USDZ → nombrar `anatomy_body.usdz`.
3. Arrastrar `anatomy_body.usdz` al proyecto Xcode (Copy if needed ✅,
   target AcessNet ✅).

### Opción B · Sketchfab (variedad CC0/CC-BY)

1. Buscar en [sketchfab.com](https://sketchfab.com) con filtros:
   `Downloadable` + `USDZ` + `Anatomy`.
2. Modelos sugeridos (verificar licencia antes de usar):
   - "Human Anatomy Lite" (~15 MB, órganos separados).
   - "Human Body - Interactive Anatomy" (completo, CC-BY).
3. Descargar el USDZ, renombrar a `anatomy_body.usdz`, arrastrar al
   proyecto.

### Opción C · Apple AR Quick Look samples

Hay modelos de cuerpo humano disponibles en la galería oficial de Apple:
https://developer.apple.com/augmented-reality/quick-look/

### Verificar nombres de nodos del USDZ

Para que los órganos se pinten y sean tap-able, los `SCNNode` internos del
USDZ deben contener palabras clave reconocibles. `AnatomicalNodeMatcher`
reconoce (case-insensitive, `contains`):

| Órgano  | Patrones que matchean                                              |
| ------- | ------------------------------------------------------------------ |
| brain   | `brain`, `cerebrum`, `cerebellum`, `cerebro`                       |
| lungs   | `lung`, `pulmon`, `respiratory`, `bronch`, `alveol`                |
| heart   | `heart`, `cardiac`, `corazon`, `cardiovascular`                    |
| throat  | `trachea`, `larynx`, `pharynx`, `throat`, `traquea`, `laringe`     |
| nose    | `nose`, `nasal`, `sinus`, `nariz`                                  |
| skin    | `skin`, `integumentary`, `piel`, `epiderm`                         |

Para ver los nombres reales del USDZ descargado:

```swift
// Paste temporalmente en AnatomicalModelView.Coordinator.loadScene:
scene.rootNode.enumerateHierarchy { node, _ in
    if let name = node.name { print("🦴 node: \(name)") }
}
```

Si ningún nodo matchea los patrones, extiende
`AnatomicalNodeMatcher.patterns` con las palabras que sí usa tu asset.

### Tap sin match → log automático

Cuando el usuario toca un nodo que el matcher no reconoce, verás en consola:

```
🩺 anatomical tap (no mapeado): <nombre_del_nodo>
```

Usa esos logs para completar los patrones.

---

## Plan futuro — Integración BioDigital HumanKit (cuando haya API key)

El wrapper alternativo `BioDigitalHumanView.swift` está preparado para
activarse vía flag de compilación. Requiere:

1. Subscription plan developer de BioDigital (ver trámite en
   `BioDigitalConfig.swift`).
2. Agregar el SPM: `https://github.com/biodigital-inc/HumanKit.git` (≥ 164.3).
3. Activar **Active Compilation Conditions → `HAS_HUMANKIT`** en Build
   Settings.
4. Agregar `BIODIGITAL_API_KEY` y `BIODIGITAL_API_SECRET` vía
   `Secrets.xcconfig` (ejemplo en `frontend/Secrets.example.xcconfig`).
5. Intercambiar `AnatomicalModelView` por `BioDigitalHumanView` en
   `HealthMenuView.swift` (una línea).

Mientras no se active la flag, ese archivo compila en modo stub SceneKit.

---

## Qué NO está conectado aún (iteraciones futuras)

Marcados con `// TODO` en el código:

- **Motor real de daño** por contaminación (ver `BodyHealthState.cdmxHighPollutionMock`).
- **APIs de calidad del aire** reales (IQAir / SEDEMA / OpenWeather) para
  el badge AQI del header.
- **HealthKit** para datos del usuario (pasos, frecuencia cardíaca, etc.).
- **Notificaciones push** contextuales al cambiar el AQI.
- **Navegación a detalle** completo de cada tratamiento.

---

## Flujo de usuario

1. Usuario escanea su cuerpo con LiDAR (tab Body → Escanear) → obtiene USDZ.
2. Va al modo **Modelo** del hub.
3. Toca **"Ver estado de tu cuerpo"** (CTA gradient naranja-rojo abajo del
   modelo).
4. Se abre `HealthMenuView` a pantalla completa.
5. Ve el AQI de CDMX, el modelo anatómico con órganos coloreados y los
   tratamientos sugeridos.
6. Toca un órgano → sheet con detalle del daño + condiciones activas.
