# GasolinaMeter AirWay — Propuesta completa por fases

**Fecha:** 16 abril 2026
**Alcance:** Integrar 7 ideas seleccionadas (G1, G3, G4, G6, G7, G8, G10) en AirWay
**Complementa:** `IDEAS_EXPANSION_SIMULACION_EMISIONES_INUNDACIONES_CV.md`

---

## 0. ANÁLISIS DEL ESTADO ACTUAL

### 0.1 Backend Django (lo que YA tienes)

| Archivo | Función | Reutilizable para |
|---|---|---|
| `backend-api/src/interfaces/api/routes/views.py` (636 líneas) | Endpoints AQI + análisis | Base para `/fuel/*` y `/trip-compare` |
| `backend-api/src/application/routes/use_cases.py` | `ComputeRouteUseCase` con OSRM + exposure | Extender con `FuelEstimateUseCase` |
| `backend-api/src/application/routes/exposure.py` | `ExposureService.score_polyline()` | Mismo patrón para `FuelService.score_polyline()` |
| `backend-api/src/adapters/router/osrm_client.py` | OSRM ya integrado | Fuente de polylines para fuel |
| `backend-api/src/adapters/ai/llm_service.py` | Gemini 2.5 Flash + timeout 45s | Vision API (G6) + Eco-coach + simulación contrafactual |
| `backend-api/src/application/air/aggregator.py` | IDW multi-fuente | Input para G10 (AQI multi-hora) |
| `backend-api/src/application/ml/` | Pipeline GradientBoosting PM2.5 | Gemelo: pipeline fuel prediction |
| `backend-api/src/adapters/air/openmeteo_provider.py` | `get_forecast()` + `get_current_weather()` | Temperatura/viento para ajustes consumo |
| `backend-api/src/core/celery.py` + `celerybeat-schedule` | Tareas programadas | Scraper Profeco diario |

### 0.2 Frontend iOS (lo que YA tienes)

| Archivo | Función | Reutilizable para |
|---|---|---|
| `frontend/AcessNet/Core/Services/RouteOptimizer.swift` | `OptimizationConfig` con presets `fastest/cleanest/safest/balanced/healthiest` | Añadir `.ecoFuel`, `.cheapest` |
| `frontend/AcessNet/Shared/Models/RouteModels.swift` | `RoutePreference` enum extensible | Añadir nuevos cases |
| `frontend/AcessNet/Features/Map/Services/RouteManager.swift` | Coordina rutas y scoring | Añadir `fuelEstimate` a cada ruta |
| `frontend/AcessNet/Features/Map/Components/RouteInfoCard.swift` | UI tarjeta ruta | Añadir "Wallet-o-meter" |
| `frontend/AcessNet/Features/Map/Components/RoutePreferenceSelector.swift` (706 líneas) | Presets + sliders | Añadir preset "💰 Más barata" |
| `frontend/AcessNet/Features/Health/Views/VulnerabilityProfileView.swift` | Perfil salud usuario | Añadir tab "Mi vehículo" |
| Apple Watch PPI Score | `PPIScoreEngine` con HR/HRV/SpO2/RR | Complica: HRV × estilo conducción |
| Onboarding existente | Flujo inicial | Añadir paso 4 "Tu auto" |

### 0.3 Gaps (lo que NO existe y hay que crear)

- `VehicleProfile` model + persistencia
- Factores de emisión México (SEDEMA) tabulados
- Precios gasolina en vivo (parser Profeco)
- Modelo físico VT-Micro + ajuste México (altitud 2240m, grade)
- Parser Hoy No Circula API
- Multimodal routing (Metro/Uber/Bici)
- Gemini Vision pipeline
- CoreMotion driving-style classifier
- OBD-II CoreBluetooth ELM327 parser
- CoreML personal fuel model per-user
- Dataset CONUEE vehículos ligeros MX (precargado)

### 0.4 Datos duros para el pitch

- **Precio gasolina CDMX (13 abril 2026, Profeco):** Magna $23.80, Premium $28.42, Diésel $28.28 por litro
- **Salario mínimo MX 2026:** 278 MXN/día → un tanque de 45 L Magna ≈ 4 días de salario mínimo
- **Hogares informales** destinan 12-15% del ingreso a gasolina
- **4% del PIB MX** son costos de salud por contaminación atmosférica (Semarnat/La Jornada 2023)
- **CDMX 2240 msnm** → -3.5% consumo vs nivel del mar pero -15-20% potencia
- **Conducción agresiva:** +15-40% consumo (múltiples papers 2024-2025)
- **Stop-and-go urbano:** +25% consumo vs flujo libre
- **A/C en verano CDMX:** +8-21% consumo

---

## 1. ESTRATEGIA POR FASES

La propuesta se divide en **7 fases** que van de lo crítico a lo ambicioso. Cada fase es **demo-able por sí sola** y construye base para la siguiente.

| Fase | Nombre | Idea | Duración | Dependencias | Demo entregable |
|---|---|---|---|---|---|
| **1** | Fundación: VehicleProfile + motor físico | Base G1/G3 | 8-10h | Ninguna | Usuario configura auto y ve litros estimados |
| **2** | Wallet-o-meter MVP | **G1** | 4-6h | Fase 1 | Tarjeta "$54 MXN" en RouteInfoCard con comparación A/B |
| **3** | Gasolinera más barata en ruta | **G3** | 8-10h | Fase 1 | Popup "Pemex Reforma $23.12 a 0.8 km" |
| **4** | Auto vs Metro vs Uber vs Bici | **G4** | 10-12h | Fase 2 | Sheet comparativo multimodal |
| **5** | Gemini Vision identifica tu auto | **G6** | 6-8h | Fase 1 | Foto tablero → perfil auto auto-completado |
| **6** | CoreMotion driving-style sin hardware | **G8** | 12-16h | Fase 2 | Modelo personal después de 10 viajes |
| **7** | Mejor momento para salir (multi-objetivo) | **G10** | 10-12h | Fases 2,3 + PPI existente | Slider 6h "espera 45 min, ahorras $7 y 58% exposición" |
| **8 (Premium)** | OBD-II Bluetooth dongle | **G7** | 3-5 días | Fase 6 | Dongle $30 → MAPE <5% |

**Total ruta base (Fases 1-7):** 58-74h distribuibles en 4 devs durante hackathon 48h (15-20h por dev).
**Fase 8 (OBD-II):** post-hackathon / versión Premium.

### 1.1 Ruta sugerida en hackathon 48h

```
Día 1 (12h)
├─ 00-04  Fase 1 (devs 1+2)             → VehicleProfile + motor físico
├─ 04-08  Fase 2 (dev 1) + Fase 5 (dev 3) → Wallet + Gemini Vision
├─ 08-12  Fase 3 (dev 2) + Fase 4 (dev 4) → Profeco + Multimodal
Día 2 (10h)
├─ 12-18  Fase 7 (devs 1+2)             → Mejor momento + UI
├─ 18-22  Fase 6 parcial (dev 3)         → CoreMotion tracking (sin modelo personal)
├─ 22-24  Polish + demo video + pitch
```

---

## 2. FASE 1 — Fundación: VehicleProfile + motor físico

**Objetivo:** Que el usuario pueda configurar su auto y la app estime litros para una ruta simple.
**Duración:** 8-10h.
**Demo:** Seleccionas destino → ves "Tu Chevy Aveo 2018 gastará ~1.8 litros".

### 2.1 Backend Django

**Archivo nuevo:** `backend-api/src/application/fuel/vehicle_profile.py`

```python
from dataclasses import dataclass
from enum import Enum

class FuelType(Enum):
    MAGNA = "magna"           # 87 octanos
    PREMIUM = "premium"       # 93 octanos
    DIESEL = "diesel"
    HYBRID = "hybrid"
    ELECTRIC = "electric"

@dataclass
class VehicleProfile:
    make: str                 # "Chevrolet"
    model: str                # "Aveo"
    year: int                 # 2018
    fuel_type: FuelType
    conuee_km_per_l: float    # 14.2 (oficial CONUEE)
    engine_cc: int            # 1600
    transmission: str         # "manual" | "automatic" | "cvt"
    weight_kg: int            # 1150
    drag_coefficient: float = 0.33
```

**Archivo nuevo:** `backend-api/src/application/fuel/physics_model.py`

Implementa VT-Micro + ajustes México:

```python
import math

# Factores emisión SEDEMA (por litro de gasolina)
CO2_KG_PER_L_GASOLINE = 2.39
CO2_KG_PER_L_DIESEL = 2.68
PM25_G_PER_L_GASOLINE = 0.012
PM25_G_PER_L_DIESEL = 0.195  # diésel emite 16× más PM2.5

CDMX_ALTITUDE_M = 2240
ALTITUDE_FUEL_FACTOR = 0.965  # -3.5% vs nivel del mar

def estimate_fuel_liters(
    distance_km: float,
    vehicle: VehicleProfile,
    avg_speed_kmh: float,
    avg_grade_pct: float,    # pendiente promedio ruta (-5 a +5)
    temperature_c: float,
    wind_headwind_kmh: float,
    stops_count: int,
    driving_style: float = 1.0,  # 0.85 (suave) a 1.25 (agresivo)
) -> dict:
    """
    Modelo físico simplificado basado en VT-Micro + ajustes México.
    Retorna {liters, co2_kg, pm25_g, confidence}.
    """
    base_liters = distance_km / vehicle.conuee_km_per_l

    # 1. Altitud CDMX
    altitude_factor = ALTITUDE_FUEL_FACTOR

    # 2. Pendiente (4% por cada 1% grade promedio)
    grade_factor = 1.0 + abs(avg_grade_pct) * 0.04

    # 3. Tráfico/stops (hasta +25% en stop-and-go)
    traffic_factor = 1.0 + (stops_count / max(distance_km, 1)) * 0.08

    # 4. A/C si temperatura > 26°C
    ac_factor = 1.08 if temperature_c > 26 else (
        1.12 if temperature_c < 5 else 1.0  # cold-start también penaliza
    )

    # 5. Viento de frente (10-25%)
    wind_factor = 1.0 + max(0, wind_headwind_kmh / 100.0) * 0.25

    # 6. Estilo de conducción
    style_factor = driving_style

    # Combinación multiplicativa
    final_liters = (
        base_liters
        * altitude_factor
        * grade_factor
        * traffic_factor
        * ac_factor
        * wind_factor
        * style_factor
    )

    # Emisiones
    if vehicle.fuel_type == FuelType.DIESEL:
        co2 = final_liters * CO2_KG_PER_L_DIESEL
        pm25 = final_liters * PM25_G_PER_L_DIESEL
    else:
        co2 = final_liters * CO2_KG_PER_L_GASOLINE
        pm25 = final_liters * PM25_G_PER_L_GASOLINE

    # Confianza basada en cuántos factores son "nominales"
    confidence = 0.75 if driving_style == 1.0 else 0.85

    return {
        "liters": round(final_liters, 2),
        "co2_kg": round(co2, 2),
        "pm25_g": round(pm25, 3),
        "confidence": confidence,
        "breakdown": {
            "base": round(base_liters, 2),
            "altitude_factor": altitude_factor,
            "grade_factor": round(grade_factor, 3),
            "traffic_factor": round(traffic_factor, 3),
            "ac_factor": ac_factor,
            "wind_factor": round(wind_factor, 3),
        }
    }
```

**Archivo nuevo:** `backend-api/src/application/fuel/fuel_service.py`

Gemelo de `exposure.py`, scorea el polyline:

```python
import polyline
from adapters.air.openmeteo_provider import OpenMeteoProvider
from .physics_model import estimate_fuel_liters

class FuelService:
    def __init__(self, weather_provider=None, elevation_service=None):
        self.weather = weather_provider or OpenMeteoProvider()
        self.elevation = elevation_service  # reusar src/adapters/air/elevation_service.py

    def score_polyline(self, encoded_polyline, vehicle, depart_at=None):
        pts = polyline.decode(encoded_polyline, precision=6)
        distance_km = self._total_distance(pts)
        avg_speed = self._estimate_avg_speed(pts, depart_at)
        avg_grade = self._average_grade(pts) if self.elevation else 0.0
        midpoint = pts[len(pts)//2]
        weather = self.weather.get_current_weather(midpoint[0], midpoint[1])
        stops = self._estimate_stops(pts)  # usa OSM traffic_signals

        result = estimate_fuel_liters(
            distance_km=distance_km,
            vehicle=vehicle,
            avg_speed_kmh=avg_speed,
            avg_grade_pct=avg_grade,
            temperature_c=weather.get("temperature_2m", 20),
            wind_headwind_kmh=weather.get("wind_speed_10m", 0) * 3.6,
            stops_count=stops,
            driving_style=1.0,
        )
        return result
```

**Archivo nuevo:** `backend-api/src/interfaces/api/fuel/views.py`

```python
class FuelEstimateView(APIView):
    """
    POST /api/v1/fuel/estimate
    Body: {
      "polyline": "encoded_string",
      "vehicle": { "make":"Nissan", "model":"Versa", "year":2019,
                   "fuel_type":"magna", "conuee_km_per_l":14.2, ... },
      "depart_at": "2026-04-16T08:30:00-06:00"  # opcional
    }
    """
    def post(self, request):
        data = request.data
        vehicle = VehicleProfile(**data["vehicle"])
        fuel_service = FuelService(elevation_service=ElevationService())
        result = fuel_service.score_polyline(
            data["polyline"], vehicle,
            depart_at=data.get("depart_at")
        )
        result["pesos_cost"] = result["liters"] * _current_fuel_price(vehicle.fuel_type)
        return Response(result)

def _current_fuel_price(fuel_type):
    # Fase 3 reemplaza con Profeco
    prices = {"magna": 23.80, "premium": 28.42, "diesel": 28.28}
    return prices.get(fuel_type.value if hasattr(fuel_type, "value") else fuel_type, 23.80)
```

**Archivo a modificar:** `backend-api/src/interfaces/api/routes/urls.py` — registrar ruta.

**Dataset a bundle:** `backend-api/src/data/conuee_vehicles_mx.json` con top 500 vehículos vendidos en México (descarga de `datos.gob.mx` CONUEE catálogo rendimiento). Usar como lookup.

### 2.2 Frontend iOS

**Archivo nuevo:** `frontend/AcessNet/Shared/Models/VehicleProfile.swift`

```swift
import Foundation

enum FuelType: String, Codable, CaseIterable {
    case magna = "magna"
    case premium = "premium"
    case diesel = "diesel"
    case hybrid = "hybrid"
    case electric = "electric"

    var displayName: String {
        switch self {
        case .magna: return "Magna (87)"
        case .premium: return "Premium (93)"
        case .diesel: return "Diésel"
        case .hybrid: return "Híbrido"
        case .electric: return "Eléctrico"
        }
    }

    var icon: String {
        switch self {
        case .electric: return "bolt.fill"
        case .hybrid: return "leaf.fill"
        default: return "fuelpump.fill"
        }
    }
}

struct VehicleProfile: Codable, Identifiable {
    var id = UUID()
    var make: String
    var model: String
    var year: Int
    var fuelType: FuelType
    var conueeKmPerL: Double
    var engineCc: Int
    var transmission: String
    var weightKg: Int
    var nickname: String?

    static let sample = VehicleProfile(
        make: "Chevrolet", model: "Aveo", year: 2018,
        fuelType: .magna, conueeKmPerL: 14.2,
        engineCc: 1600, transmission: "manual", weightKg: 1150
    )
}
```

**Archivo nuevo:** `frontend/AcessNet/Core/Services/VehicleProfileService.swift`

```swift
import Foundation

class VehicleProfileService: ObservableObject {
    static let shared = VehicleProfileService()
    @Published var activeProfile: VehicleProfile?
    @Published var savedProfiles: [VehicleProfile] = []

    private let storageKey = "airway.vehicle.profiles"

    init() { load() }

    func save(_ profile: VehicleProfile) {
        if let idx = savedProfiles.firstIndex(where: { $0.id == profile.id }) {
            savedProfiles[idx] = profile
        } else {
            savedProfiles.append(profile)
        }
        activeProfile = profile
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(savedProfiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([VehicleProfile].self, from: data)
        else { return }
        savedProfiles = list
        activeProfile = list.first
    }
}
```

**Archivo nuevo:** `frontend/AcessNet/Features/Settings/Views/VehicleProfileView.swift`

UI para crear/editar VehicleProfile (picker CONUEE catalog + custom).

**Archivo a modificar:** `frontend/AcessNet/Shared/Models/RouteModels.swift`

```swift
struct FuelEstimate: Codable {
    let liters: Double
    let pesosCost: Double
    let co2Kg: Double
    let pm25Grams: Double
    let confidence: Double
}

// Extender ScoredRoute
extension ScoredRoute {
    var fuelEstimate: FuelEstimate? { get }  // cached, computed por RouteManager
}
```

**Archivo a modificar:** `frontend/AcessNet/Core/Services/APIClient.swift` (si existe) o crear `FuelAPIClient.swift`:

```swift
class FuelAPIClient {
    static let shared = FuelAPIClient()
    private let baseURL = "https://api.airway.mx/api/v1"

    func estimate(polyline: String, vehicle: VehicleProfile,
                  departAt: Date? = nil) async throws -> FuelEstimate {
        let url = URL(string: "\(baseURL)/fuel/estimate")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "polyline": polyline,
            "vehicle": try vehicle.asDictionary(),
            "depart_at": departAt?.iso8601 ?? NSNull()
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(FuelEstimate.self, from: data)
    }
}
```

### 2.3 Criterio de éxito Fase 1

- [ ] Backend responde `/api/v1/fuel/estimate` con JSON estructurado.
- [ ] iOS persiste `VehicleProfile` en UserDefaults.
- [ ] Logs muestran "Estimado 1.8 L, $42.80 MXN, 4.3 kg CO₂" al seleccionar destino.
- [ ] Confianza >0.7 reportada.

---

## 3. FASE 2 — G1: Wallet-o-meter MVP

**Objetivo:** Mostrar el costo en pesos con comparación A vs B vs C en `RouteInfoCard`.
**Duración:** 4-6h. **Dependencia:** Fase 1.
**Demo:** Tarjeta que dice "$54 MXN — 3.2 L — 7.6 kg CO₂ · ahorras $12 vs ruta más cara".

### 3.1 Frontend iOS — integración en card existente

**Archivo a modificar:** `frontend/AcessNet/Features/Map/Services/RouteManager.swift`

Después de calcular rutas OSRM, pedir estimate al backend:

```swift
func computeRoutes(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async throws -> [ScoredRoute] {
    let routes = try await osrm.route(from: from, to: to, alternatives: 3)
    var scored = routes.map { ScoredRoute(from: $0) }

    // NUEVO: fuel estimate paralelo para cada ruta
    if let vehicle = VehicleProfileService.shared.activeProfile {
        await withTaskGroup(of: (UUID, FuelEstimate?).self) { group in
            for route in scored {
                group.addTask {
                    let est = try? await FuelAPIClient.shared.estimate(
                        polyline: route.polyline, vehicle: vehicle)
                    return (route.id, est)
                }
            }
            for await (id, est) in group {
                if let idx = scored.firstIndex(where: { $0.id == id }) {
                    scored[idx].fuelEstimate = est
                }
            }
        }
    }
    return scored
}
```

**Archivo a modificar:** `frontend/AcessNet/Features/Map/Components/RouteInfoCard.swift`

Añadir sección:

```swift
// Dentro del body de RouteInfoCard
if let fuel = route.fuelEstimate {
    HStack(spacing: 16) {
        // Wallet-o-meter
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "pesosign.circle.fill")
                    .foregroundColor(.green)
                Text("$\(Int(fuel.pesosCost))")
                    .font(.system(.title2, design: .rounded))
                    .bold()
            }
            Text("\(String(format: "%.1f", fuel.liters)) L")
                .font(.caption)
                .foregroundColor(.secondary)
        }

        Spacer()

        // CO2 badge
        VStack(alignment: .leading, spacing: 2) {
            Text("\(String(format: "%.1f", fuel.co2Kg)) kg")
                .font(.subheadline)
                .bold()
            Text("CO₂ emitido")
                .font(.caption2)
                .foregroundColor(.secondary)
        }

        // Savings vs worst
        if let savings = route.savingsVsWorst, savings.pesos > 5 {
            Text("-$\(Int(savings.pesos))")
                .font(.caption.bold())
                .foregroundColor(.green)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .cornerRadius(8)
        }
    }
    .padding()
    .background(Color.secondary.opacity(0.05))
    .cornerRadius(12)
}
```

**Añadir animación spring** al aparecer el número (efecto "casino"):

```swift
.transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
.animation(.spring(response: 0.5, dampingFraction: 0.7), value: fuel.pesosCost)
```

### 3.2 Archivo a modificar: `RoutePreferenceSelector.swift`

Añadir preset:

```swift
enum PresetType: String, CaseIterable {
    case balanced, fastest, cleanest, safest
    case cheapest  // NUEVO
    case ecoFuel   // NUEVO

    var icon: String {
        switch self {
        case .cheapest: return "pesosign.circle.fill"
        case .ecoFuel: return "leaf.circle.fill"
        // ...
        }
    }

    var title: String {
        switch self {
        case .cheapest: return "💰 Más barata"
        case .ecoFuel: return "🌿 Eco-combustible"
        // ...
        }
    }
}
```

### 3.3 Criterio de éxito Fase 2

- [ ] Tarjeta "Wallet-o-meter" visible en cada ruta con animación.
- [ ] Badge verde "-$X" cuando hay ahorro.
- [ ] Preset "💰 Más barata" reordena las rutas por `fuelEstimate.pesosCost`.

---

## 4. FASE 3 — G3: Gasolinera más barata en tu ruta

**Objetivo:** Popup "Pemex Reforma $23.12 a 0.8 km, -$0.68 vs promedio".
**Duración:** 8-10h. **Dependencia:** Fase 1.
**Demo:** Durante navegación con tanque <30%, sugerencia aparece automáticamente.

### 4.1 Backend — scraper Profeco + base de datos geolocalizada

**Archivo nuevo:** `backend-api/src/adapters/fuel/profeco_scraper.py`

```python
import requests
from bs4 import BeautifulSoup
from datetime import date

class ProfecoScraper:
    """
    Descarga reporte diario PDF Profeco y extrae precios por estación.
    URL patrón: https://combustibles.profeco.gob.mx/qqpgasolina/{YEAR}/QQPGASOLINA_{MMDDYY}.pdf
    """
    BASE_URL = "https://combustibles.profeco.gob.mx/qqpgasolina"

    def fetch_today(self) -> list[dict]:
        today = date.today()
        url = f"{self.BASE_URL}/{today.year}/QQPGASOLINA_{today.strftime('%m%d%y')}.pdf"
        pdf_bytes = requests.get(url, timeout=30).content
        return self._parse_pdf(pdf_bytes)

    def _parse_pdf(self, pdf_bytes):
        # Usar pdfplumber o camelot-py para extraer tablas
        import pdfplumber
        import io
        stations = []
        with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
            for page in pdf.pages:
                for table in page.extract_tables():
                    for row in table[1:]:
                        stations.append({
                            "brand": row[0],       # Pemex, BP, Shell...
                            "address": row[1],
                            "alcaldia": row[2],
                            "magna": float(row[3]) if row[3] else None,
                            "premium": float(row[4]) if row[4] else None,
                            "diesel": float(row[5]) if row[5] else None,
                        })
        return stations
```

**Alternativa más robusta:** CRE (Comisión Reguladora de Energía) dataset en `datos.gob.mx` con precios georreferenciados. Preferir CRE por incluir lat/lon directos.

**Archivo nuevo:** `backend-api/src/core/tasks.py`

```python
from celery import shared_task
from adapters.fuel.profeco_scraper import ProfecoScraper
from django.db import transaction
from models import FuelStation  # Django model con PostGIS Point field

@shared_task
def update_fuel_prices_daily():
    scraper = ProfecoScraper()
    data = scraper.fetch_today()
    with transaction.atomic():
        for s in data:
            FuelStation.objects.update_or_create(
                address=s["address"],
                defaults={
                    "brand": s["brand"],
                    "location": geocode(s["address"]),
                    "magna_price": s["magna"],
                    "premium_price": s["premium"],
                    "diesel_price": s["diesel"],
                    "updated_at": timezone.now(),
                }
            )
```

**Añadir a `celerybeat-schedule`:**
```python
CELERY_BEAT_SCHEDULE = {
    "update-fuel-prices-daily": {
        "task": "core.tasks.update_fuel_prices_daily",
        "schedule": crontab(hour=7, minute=0),  # 7am CDT daily
    },
}
```

### 4.2 Endpoint de consulta

**Archivo nuevo:** `backend-api/src/interfaces/api/fuel/stations_view.py`

```python
class FuelStationsOnRouteView(APIView):
    """
    POST /api/v1/fuel/stations_on_route
    Body: {
      "polyline": "...",
      "fuel_type": "magna",
      "buffer_km": 0.5  # stations within 500m of route
    }
    Returns top 5 cheapest stations near route.
    """
    def post(self, request):
        from django.contrib.gis.geos import LineString, Point
        from django.contrib.gis.measure import D
        import polyline as polyline_lib

        pts = polyline_lib.decode(request.data["polyline"], precision=6)
        line = LineString([Point(lon, lat) for lat, lon in pts])
        buffer_km = float(request.data.get("buffer_km", 0.5))

        stations = (
            FuelStation.objects
            .filter(location__distance_lte=(line, D(km=buffer_km)))
            .order_by(f"{request.data['fuel_type']}_price")[:5]
        )
        return Response([
            {
                "brand": s.brand,
                "address": s.address,
                "lat": s.location.y,
                "lon": s.location.x,
                "price": getattr(s, f"{request.data['fuel_type']}_price"),
                "distance_km": round(line.distance(s.location) * 111, 2),
                "savings_per_liter": _avg_price(request.data['fuel_type']) - price,
            } for s in stations
        ])
```

### 4.3 Frontend iOS

**Archivo nuevo:** `frontend/AcessNet/Features/Map/Components/FuelStationSuggestionBanner.swift`

Banner que aparece cuando `tankLevel < 0.3` (opcional, si hay OBD) o manual:

```swift
struct FuelStationSuggestionBanner: View {
    let station: FuelStation
    let averagePrice: Double
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fuelpump.fill")
                .font(.title2)
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(station.brand) a \(String(format: "%.1f", station.distanceKm)) km")
                    .font(.subheadline.bold())
                Text("Magna $\(station.price, specifier: "%.2f") · ahorras $\(averagePrice - station.price, specifier: "%.2f")/L")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .onTapGesture(perform: onTap)
    }
}
```

### 4.4 Criterio de éxito Fase 3

- [ ] Backend tiene >200 gasolineras CDMX con precios actualizados diarios.
- [ ] Endpoint responde <500ms para buffer 500m de polyline.
- [ ] Banner aparece con estación más barata durante navegación.

---

## 5. FASE 4 — G4: Auto vs Metro vs Uber vs Bici

**Objetivo:** Sheet comparativo con costo total real, incluyendo externalidades.
**Duración:** 10-12h. **Dependencia:** Fase 2.
**Demo:** Tap "Comparar modos" → tarjetas con emoji + costo + tiempo + exposición.

### 5.1 Backend — multimodal routing

**Archivo nuevo:** `backend-api/src/application/routes/multimodal.py`

```python
from adapters.router.osrm_client import OSRMClient
from adapters.maps.mapbox_client import MapboxClient  # para transit

class MultimodalRouter:
    """
    Devuelve ruta en 4 modos: auto, metro+caminata, uber, bici.
    """
    def compute_all(self, origin, dest, vehicle=None):
        results = {}

        # 1. Auto
        car_route = OSRMClient().route([origin, dest], profile="car")
        results["auto"] = self._score_car(car_route, vehicle)

        # 2. Metro + caminata (Mapbox transit)
        transit = MapboxClient().directions(origin, dest, profile="transit")
        results["metro"] = self._score_transit(transit)

        # 3. Uber estimado (sin API oficial: fórmula Waze/CDMX)
        results["uber"] = self._estimate_uber(car_route)

        # 4. Bici
        bike = OSRMClient().route([origin, dest], profile="bike")
        results["bici"] = self._score_bike(bike)

        return results

    def _score_car(self, route, vehicle):
        fuel = FuelService().score_polyline(route["geometry"], vehicle)
        tolls = self._estimate_tolls(route)
        parking = self._estimate_parking(route["destination"])
        depreciation = route["distance_km"] * 2.5  # ~$2.50/km Kavak-style
        total = fuel["pesos_cost"] + tolls + parking + depreciation
        return {
            "mode": "auto",
            "duration_min": route["duration"] / 60,
            "distance_km": route["distance"] / 1000,
            "direct_cost_mxn": fuel["pesos_cost"],
            "hidden_cost_mxn": tolls + parking + depreciation,
            "total_cost_mxn": total,
            "co2_kg": fuel["co2_kg"],
            "pm25_exposure_g": fuel["pm25_g"],  # emitido
            "calories_burned": 0,
        }

    def _score_transit(self, transit):
        # CDMX: Metro $5, Metrobús $6, Cablebús $7
        fare = 10  # asumimos combinación
        walk_m = transit.get("walking_distance", 0)
        return {
            "mode": "metro",
            "duration_min": transit["duration"] / 60,
            "distance_km": transit["distance"] / 1000,
            "direct_cost_mxn": fare,
            "hidden_cost_mxn": 0,
            "total_cost_mxn": fare,
            "co2_kg": 0.02 * (transit["distance"] / 1000),  # promedio Metro CDMX
            "pm25_exposure_g": _metro_pm25_exposure(transit["duration"] / 60),
            "calories_burned": int(walk_m * 0.05),
        }

    def _estimate_uber(self, car_route):
        km = car_route["distance"] / 1000
        min = car_route["duration"] / 60
        base = 13
        price = base + (km * 8.20) + (min * 1.15)
        return {
            "mode": "uber",
            "duration_min": min,
            "distance_km": km,
            "direct_cost_mxn": price,
            "hidden_cost_mxn": 0,
            "total_cost_mxn": price,
            "co2_kg": km * 0.22,  # factor Uber CDMX SEDEMA
            "pm25_exposure_g": km * 0.008,
            "calories_burned": 0,
        }

    def _score_bike(self, bike_route):
        km = bike_route["distance"] / 1000
        min = bike_route["duration"] / 60
        return {
            "mode": "bici",
            "duration_min": min,
            "distance_km": km,
            "direct_cost_mxn": 0,
            "hidden_cost_mxn": km * 0.30,  # mantenimiento
            "total_cost_mxn": km * 0.30,
            "co2_kg": 0,
            "pm25_exposure_g": _bike_exposure(min),  # ciclista inhala 2x el aire
            "calories_burned": int(min * 8),
        }
```

### 5.2 Endpoint

```python
class TripCompareView(APIView):
    """POST /api/v1/trip/compare"""
    def post(self, request):
        origin = request.data["origin"]
        dest = request.data["destination"]
        vehicle = VehicleProfile(**request.data["vehicle"])
        router = MultimodalRouter()
        return Response(router.compute_all(origin, dest, vehicle))
```

### 5.3 Frontend iOS

**Archivo nuevo:** `frontend/AcessNet/Features/Map/Views/ModeComparisonSheet.swift`

Bottom sheet con 4 tarjetas visuales:

```swift
struct ModeComparisonSheet: View {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    @State private var comparison: MultimodalComparison?
    @State private var loading = true

    var body: some View {
        VStack {
            Text("Cómo ir a tu destino").font(.title2.bold())
            if let c = comparison {
                VStack(spacing: 12) {
                    ModeCard(mode: c.auto, icon: "🚗", bestFor: "rapidez")
                    ModeCard(mode: c.metro, icon: "🚇", bestFor: "economía", isBest: c.metro.isCheapest)
                    ModeCard(mode: c.uber, icon: "🚕", bestFor: "comodidad")
                    ModeCard(mode: c.bici, icon: "🚴", bestFor: "salud", isBest: c.bici.isHealthiest)
                }
                // Insight Gemini
                Text(c.insight)
                    .font(.callout)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            } else {
                ProgressView("Calculando...")
            }
        }
        .task {
            comparison = try? await TripCompareAPI.shared.compare(origin, destination)
            loading = false
        }
    }
}

struct ModeCard: View {
    let mode: TripMode
    let icon: String
    let bestFor: String
    var isBest: Bool = false

    var body: some View {
        HStack {
            Text(icon).font(.largeTitle)
            VStack(alignment: .leading) {
                Text(mode.displayName).font(.headline)
                Text("\(Int(mode.durationMin)) min · $\(Int(mode.totalCostMxn))")
                    .font(.subheadline).foregroundColor(.secondary)
                if mode.hiddenCostMxn > 0 {
                    Text("(incluye $\(Int(mode.hiddenCostMxn)) ocultos)")
                        .font(.caption).foregroundColor(.orange)
                }
            }
            Spacer()
            if isBest {
                Text("⭐")
            }
        }
        .padding()
        .background(isBest ? Color.green.opacity(0.15) : Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}
```

**Insight Gemini:** usa `LLMService` existente con prompt:

```
Usuario va de {A} a {B}. Auto: {X}min/${cost}/AQI{exposure}. Metro: ... .
Sugiere cuál elegir en 1 oración, considerando su perfil: {vulnerability}.
```

### 5.4 Criterio de éxito Fase 4

- [ ] 4 tarjetas con costo+tiempo+CO₂ comparables.
- [ ] Badge "incluye $X ocultos" visible (peajes, depreciación).
- [ ] Gemini sugiere una opción en 1 oración.

---

## 6. FASE 5 — G6: Gemini Vision identifica tu auto

**Objetivo:** Foto del tablero/auto → perfil pre-rellenado.
**Duración:** 6-8h. **Dependencia:** Fase 1.
**Demo:** Toma foto del dashboard → Gemini extrae marca/modelo/km → VehicleProfile listo.

### 6.1 Backend — Gemini Vision endpoint

**Archivo nuevo:** `backend-api/src/adapters/ai/gemini_vision.py`

```python
from google import genai
import json, os

class GeminiVisionClient:
    def __init__(self):
        self.client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

    def identify_vehicle(self, image_b64: str) -> dict:
        prompt = """
        Analiza esta imagen de un auto mexicano. Si es:
        - Tablero/odómetro: extrae km actuales, marca, modelo inferido
        - Placa mexicana: extrae los 7 caracteres y región
        - Vista exterior: extrae marca, modelo, año aproximado
        - Etiqueta Hoy No Circula: extrae color y número

        Responde SOLO JSON:
        {
          "type": "dashboard" | "plate" | "exterior" | "sticker",
          "make": "...",
          "model": "...",
          "year_estimate": 2018,
          "odometer_km": 120000,
          "confidence": 0.85,
          "notes": "..."
        }
        """
        resp = self.client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[
                {"role": "user", "parts": [
                    {"inline_data": {"mime_type": "image/jpeg", "data": image_b64}},
                    {"text": prompt}
                ]}
            ],
            config={"response_mime_type": "application/json"}
        )
        return json.loads(resp.text)
```

**Archivo nuevo:** `backend-api/src/interfaces/api/fuel/vehicle_vision_view.py`

```python
class VehicleVisionView(APIView):
    """POST /api/v1/vehicle/identify_from_image"""
    def post(self, request):
        image_b64 = request.data["image"]
        vision = GeminiVisionClient()
        identified = vision.identify_vehicle(image_b64)

        # Enriquecer con catalog CONUEE si matches
        if identified.get("make") and identified.get("model"):
            match = ConueeCatalog.lookup(
                make=identified["make"],
                model=identified["model"],
                year=identified.get("year_estimate")
            )
            if match:
                identified["conuee_km_per_l"] = match.km_per_l
                identified["fuel_type"] = match.fuel_type
                identified["engine_cc"] = match.engine_cc
        return Response(identified)
```

### 6.2 Frontend iOS

**Archivo nuevo:** `frontend/AcessNet/Features/Settings/Views/VehicleScanView.swift`

```swift
struct VehicleScanView: View {
    @State private var capturedImage: UIImage?
    @State private var identified: IdentifiedVehicle?
    @State private var showCamera = false
    @State private var loading = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Toma una foto de tu tablero, placa o auto")
                .multilineTextAlignment(.center)

            if let img = capturedImage {
                Image(uiImage: img).resizable().scaledToFit().frame(height: 300)
            }

            Button("Abrir cámara") { showCamera = true }
                .buttonStyle(.borderedProminent)

            if loading {
                ProgressView("Analizando con Gemini...")
            }

            if let v = identified {
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(v.make) \(v.model) \(v.year)", systemImage: "car.fill")
                    if let odo = v.odometerKm {
                        Label("\(odo) km", systemImage: "gauge")
                    }
                    if let km_l = v.conueeKmPerL {
                        Label("\(String(format: "%.1f", km_l)) km/L oficial", systemImage: "leaf")
                    }
                    Text("Confianza: \(Int(v.confidence * 100))%")
                        .font(.caption).foregroundColor(.secondary)

                    Button("Usar este perfil") {
                        VehicleProfileService.shared.save(
                            VehicleProfile(from: v)
                        )
                    }.buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage)
        }
        .onChange(of: capturedImage) { newImage in
            guard let img = newImage else { return }
            Task { await identify(img) }
        }
    }

    func identify(_ image: UIImage) async {
        loading = true
        defer { loading = false }
        guard let data = image.jpegData(compressionQuality: 0.6) else { return }
        let b64 = data.base64EncodedString()
        identified = try? await VehicleVisionAPI.shared.identify(imageB64: b64)
    }
}
```

### 6.3 Criterio de éxito Fase 5

- [ ] Foto del dashboard → Gemini devuelve make/model/km en <5s.
- [ ] Si matches CONUEE, rendimiento km/L se pre-rellena.
- [ ] "Usar este perfil" persiste en `VehicleProfileService`.

---

## 7. FASE 6 — G8: CoreMotion driving-style sin hardware

**Objetivo:** Sin OBD-II, detectar estilo de conducción y personalizar modelo con CoreML.
**Duración:** 12-16h. **Dependencia:** Fase 2.
**Demo:** Después de 10 viajes, modelo personal mejora MAPE a ~7-10%.

### 7.1 iOS — tracking durante viaje

**Archivo nuevo:** `frontend/AcessNet/Core/Services/DrivingTelemetryService.swift`

```swift
import CoreMotion
import CoreLocation
import Combine

class DrivingTelemetryService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentTrip: TripTelemetry?
    private let motion = CMMotionManager()
    private let location = CLLocationManager()
    private let activityManager = CMMotionActivityManager()

    struct TripTelemetry: Codable {
        var startedAt: Date
        var endedAt: Date?
        var samples: [Sample] = []
        var harshAccels: Int = 0        // |a| > 3 m/s²
        var harshBrakes: Int = 0        // a < -3 m/s²
        var idleSeconds: Int = 0        // speed < 3 km/h
        var avgSpeedKmh: Double = 0
        var maxSpeedKmh: Double = 0
        var totalDistanceKm: Double = 0
        var elevationGainM: Double = 0
    }

    struct Sample: Codable {
        let t: Date
        let speedKmh: Double
        let accelX: Double, accelY: Double, accelZ: Double
        let altitude: Double
    }

    func startTrip() {
        currentTrip = TripTelemetry(startedAt: Date())

        // Activity classifier
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let a = activity, a.automotive else { return }
            // Confirmar que está en auto
        }

        // Motion
        motion.accelerometerUpdateInterval = 0.2  // 5 Hz suficiente
        motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let d = data else { return }
            self.processAccel(d)
        }

        // Location
        location.startUpdatingLocation()
    }

    func endTrip() async -> TripTelemetry? {
        motion.stopAccelerometerUpdates()
        location.stopUpdatingLocation()
        currentTrip?.endedAt = Date()
        let trip = currentTrip

        // Enviar al backend para alimentar modelo personal
        if let t = trip {
            try? await TelemetryAPI.shared.upload(t)
        }
        return trip
    }

    private func processAccel(_ d: CMAccelerometerData) {
        let magnitude = sqrt(d.acceleration.x*d.acceleration.x
                           + d.acceleration.y*d.acceleration.y
                           + d.acceleration.z*d.acceleration.z)
        let net = abs(magnitude - 1.0) * 9.81  // descontar gravedad
        if net > 3.0 {
            currentTrip?.harshAccels += 1
        }
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard var trip = currentTrip, let last = locations.last else { return }
        let speed = max(0, last.speed) * 3.6
        trip.samples.append(Sample(
            t: Date(), speedKmh: speed,
            accelX: 0, accelY: 0, accelZ: 0,  // motion fuses aparte
            altitude: last.altitude
        ))
        trip.maxSpeedKmh = max(trip.maxSpeedKmh, speed)
        if speed < 3 { trip.idleSeconds += 1 }
        currentTrip = trip
    }
}
```

### 7.2 Detección automática de "ir en auto"

Usar `CMMotionActivityManager` que ya clasifica `automotive`. Auto-iniciar trip cuando se detecta.

### 7.3 Backend — modelo personal CoreML on-device

**Opción simple (recomendada para hackathon):** mantener `driving_style` como float en VehicleProfile y actualizarlo con EMA:

```swift
// Al terminar viaje
let style = computeStyleMultiplier(trip: t)
// style: 0.85 (suave) a 1.25 (agresivo)
var profile = VehicleProfileService.shared.activeProfile!
profile.drivingStyle = 0.9 * profile.drivingStyle + 0.1 * style  // EMA
VehicleProfileService.shared.save(profile)

func computeStyleMultiplier(trip: TripTelemetry) -> Double {
    let durationMin = trip.endedAt!.timeIntervalSince(trip.startedAt) / 60
    let harshRate = Double(trip.harshAccels + trip.harshBrakes) / durationMin
    // harshRate típico: 0 (suave) a 0.5 (agresivo)
    return 0.92 + min(harshRate * 0.7, 0.33)
}
```

**Opción avanzada:** CreateML MLBoostedTreeRegressor on-device:

```swift
import CreateML
// Después de 30+ viajes con fuel real reportado manualmente:
let ds = try MLDataTable(dictionary: tripHistoryDict)
let regressor = try MLBoostedTreeRegressor(
    trainingData: ds,
    targetColumn: "liters_actual",
    featureColumns: [
        "distance_km", "elevation_gain_m", "avg_speed_kmh",
        "harsh_accel_count", "harsh_brake_count", "idle_seconds",
        "hour_of_day", "temp_c", "day_of_week"
    ]
)
try regressor.write(to: personalModelURL)
```

### 7.4 Criterio de éxito Fase 6

- [ ] `DrivingTelemetryService` inicia auto cuando detecta movimiento vehicular.
- [ ] Conteos de harsh accel/brake/idle se registran.
- [ ] `drivingStyle` se actualiza con EMA tras cada viaje.
- [ ] (Stretch) Modelo CoreML personal entrena después de 10 viajes.

---

## 8. FASE 7 — G10: Mejor momento para salir (multi-objetivo)

**Objetivo:** Slider temporal 6h que combina AQI + tráfico + gasolina + exposición personal.
**Duración:** 10-12h. **Dependencia:** Fases 2, 3, más `prediction_service.py` existente.
**Demo:** "Si sales 8:30 → 28 min, $45, AQI 85. Si sales 9:15 → 22 min, $38, AQI 62. **Espera 45 min, ahorras $7 y reduces 58% exposición**".

### 8.1 Backend — motor multi-objetivo

**Archivo nuevo:** `backend-api/src/application/fuel/departure_optimizer.py`

```python
from datetime import datetime, timedelta
from application.air.prediction_service import PredictionService
from application.fuel.fuel_service import FuelService

class DepartureOptimizer:
    def suggest_windows(
        self, origin, dest, vehicle,
        earliest: datetime, latest: datetime,
        user_profile: dict,
        step_min: int = 15,
    ) -> list[dict]:
        """
        Evalúa salida cada step_min minutos entre earliest y latest.
        Retorna lista ordenada por score multi-objetivo.
        """
        predictor = PredictionService()
        fuel_service = FuelService()
        router = OSRMClient()

        windows = []
        t = earliest
        while t <= latest:
            # 1. Ruta a esa hora (OSRM con traffic si aplica)
            route = router.route_at_time([origin, dest], at=t)
            # 2. Fuel
            fuel = fuel_service.score_polyline(route["geometry"], vehicle, depart_at=t)
            # 3. AQI predicho a esa hora en el midpoint
            midpoint = _midpoint(route["geometry"])
            aqi = predictor.predict_at(midpoint, when=t)
            # 4. Exposición = AQI × duración × multiplicador vulnerabilidad
            exposure = aqi * (route["duration"] / 3600) * _vuln_multiplier(user_profile)

            windows.append({
                "depart_at": t.isoformat(),
                "duration_min": route["duration"] / 60,
                "pesos_cost": fuel["pesos_cost"],
                "liters": fuel["liters"],
                "aqi_avg": aqi,
                "exposure_index": exposure,
                "co2_kg": fuel["co2_kg"],
            })
            t += timedelta(minutes=step_min)

        # Score multi-objetivo
        for w in windows:
            w["score"] = self._multi_objective_score(w, user_profile)
        windows.sort(key=lambda x: x["score"], reverse=True)
        return windows

    def _multi_objective_score(self, w, profile):
        # Normalizaciones relativas al mejor
        # Pesos dinámicos según perfil vulnerabilidad
        time_weight = 0.3
        cost_weight = 0.2
        exposure_weight = 0.5 if profile.get("asthma") else 0.3

        # Score: menor duración + menor costo + menor exposición
        return (
            time_weight * (1 / max(w["duration_min"], 1))
            + cost_weight * (1 / max(w["pesos_cost"], 1))
            + exposure_weight * (1 / max(w["exposure_index"], 1))
        ) * 100
```

**Endpoint:** `POST /api/v1/fuel/optimal_departure`

Body:
```json
{
  "origin": {"lat": 19.43, "lon": -99.13},
  "destination": {"lat": 19.38, "lon": -99.27},
  "vehicle": {...},
  "earliest": "2026-04-16T07:00:00-06:00",
  "latest": "2026-04-16T13:00:00-06:00",
  "user_profile": {"asthma": true, "age": 45}
}
```

Response:
```json
{
  "windows": [
    {"depart_at": "09:15", "score": 87, "pesos_cost": 38, "duration_min": 22, "aqi_avg": 62, "saves_vs_now": {"pesos": 7, "minutes": 6, "exposure_pct": 58}},
    {"depart_at": "08:30", "score": 72, "pesos_cost": 45, ...},
    ...
  ],
  "recommendation": "9:15 — ahorras $7, 6 min y 58% exposición",
  "insight": "(generado por Gemini)"
}
```

### 8.2 Frontend iOS — UI tipo "time machine"

**Archivo nuevo:** `frontend/AcessNet/Features/Map/Views/OptimalDepartureView.swift`

```swift
struct OptimalDepartureView: View {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    @State private var windows: [DepartureWindow] = []
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            // Hero recomendación
            if let best = windows.first {
                VStack {
                    Text("Mejor momento para salir")
                        .font(.caption).foregroundColor(.secondary)
                    Text(best.departTime.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text(best.recommendation)
                        .multilineTextAlignment(.center)
                }
            }

            // Chart comparativo 6h
            Chart(windows) { w in
                BarMark(
                    x: .value("Hora", w.departTime, unit: .hour),
                    y: .value("Score", w.score)
                )
                .foregroundStyle(color(for: w.score))
            }
            .frame(height: 200)

            // Slider para explorar ventanas
            Picker("Ventana", selection: $selectedIndex) {
                ForEach(windows.indices, id: \.self) { i in
                    Text(windows[i].departTime.formatted()).tag(i)
                }
            }
            .pickerStyle(.wheel)

            // Detalle de la ventana seleccionada
            if selectedIndex < windows.count {
                DepartureDetailCard(window: windows[selectedIndex])
            }
        }
        .task { await load() }
    }
}
```

### 8.3 Criterio de éxito Fase 7

- [ ] Endpoint responde con 24 ventanas (step 15min en 6h).
- [ ] UI muestra hora óptima en big text.
- [ ] Chart compara las 24 ventanas visualmente.
- [ ] Insight de Gemini narra la recomendación.

---

## 9. FASE 8 — G7 (Premium): OBD-II Bluetooth dongle

**Objetivo:** Integrar dongle ELM327 ($30) para telemetría real-time.
**Duración:** 3-5 días post-hackathon.
**Demo:** Tablero en vivo con RPM/velocidad/fuel rate real + entrenamiento CoreML personal.

### 9.1 iOS — CoreBluetooth + ELM327 parser

**Archivo nuevo:** `frontend/AcessNet/Core/Services/OBD2Service.swift`

```swift
import CoreBluetooth
import Combine

class OBD2Service: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isConnected = false
    @Published var liveData = OBD2LiveData()

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeChar: CBCharacteristic?

    // ELM327 Service UUID común
    private let elmServiceUUID = CBUUID(string: "FFE0")

    struct OBD2LiveData {
        var rpm: Int = 0           // PID 0x0C
        var speedKmh: Int = 0      // PID 0x0D
        var throttlePct: Int = 0   // PID 0x11
        var mafGs: Double = 0       // PID 0x10 — Mass Air Flow
        var fuelRateLh: Double = 0  // PID 0x5E — directo si soporta
        var engineTempC: Int = 0    // PID 0x05
    }

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func scan() {
        central.scanForPeripherals(withServices: [elmServiceUUID])
    }

    func sendPID(_ pid: String) {
        guard let p = peripheral, let c = writeChar else { return }
        let cmd = "01\(pid)\r".data(using: .ascii)!
        p.writeValue(cmd, for: c, type: .withResponse)
    }

    // ... delegate methods, polling loop cada 500ms
}
```

**Cálculo de fuel rate si el vehículo no reporta PID 0x5E:**

```swift
// Si MAF está disponible pero no fuel rate directo:
// fuel_rate_Lh = (MAF_g_s * 3600) / (14.7 * fuel_density_g_L)
// 14.7 = ratio estequiométrico aire/gasolina
// fuel_density_gasolina ≈ 740 g/L

extension OBD2LiveData {
    var computedFuelRateLh: Double {
        if fuelRateLh > 0 { return fuelRateLh }
        let densityG_L = 740.0
        return (mafGs * 3600) / (14.7 * densityG_L)
    }
}
```

### 9.2 Entrenamiento CoreML personal

Con OBD, recopila `(distance, avgSpeed, accels, liters_real)` y entrena MLBoostedTreeRegressor on-device. MAPE esperado <5%.

### 9.3 Criterio de éxito Fase 8

- [ ] Auto-descubre dongle ELM327 via CBCentralManager.
- [ ] Reporta RPM + velocidad + fuel rate en vivo.
- [ ] Guarda TripTelemetry con datos OBD reales.
- [ ] Entrena modelo personal tras 10 viajes con OBD.

---

## 10. RESUMEN INTEGRADO — MAPA DE ARCHIVOS

### Archivos NUEVOS a crear

```
backend-api/src/
├─ application/fuel/
│  ├─ __init__.py
│  ├─ vehicle_profile.py         (Fase 1)
│  ├─ physics_model.py           (Fase 1)
│  ├─ fuel_service.py            (Fase 1)
│  └─ departure_optimizer.py     (Fase 7)
├─ application/routes/
│  └─ multimodal.py              (Fase 4)
├─ adapters/fuel/
│  ├─ __init__.py
│  └─ profeco_scraper.py         (Fase 3)
├─ adapters/ai/
│  └─ gemini_vision.py           (Fase 5)
├─ interfaces/api/fuel/
│  ├─ __init__.py
│  ├─ urls.py
│  ├─ views.py                   (Fase 1)
│  ├─ stations_view.py           (Fase 3)
│  └─ vehicle_vision_view.py     (Fase 5)
├─ interfaces/api/trip/
│  └─ views.py                   (Fase 4 — /trip/compare)
└─ data/
   └─ conuee_vehicles_mx.json    (Fase 1)

frontend/AcessNet/
├─ Shared/Models/
│  └─ VehicleProfile.swift       (Fase 1)
├─ Core/Services/
│  ├─ VehicleProfileService.swift     (Fase 1)
│  ├─ FuelAPIClient.swift             (Fase 1)
│  ├─ TripCompareAPI.swift            (Fase 4)
│  ├─ VehicleVisionAPI.swift          (Fase 5)
│  ├─ DrivingTelemetryService.swift   (Fase 6)
│  └─ OBD2Service.swift               (Fase 8)
├─ Features/Settings/Views/
│  ├─ VehicleProfileView.swift        (Fase 1)
│  └─ VehicleScanView.swift           (Fase 5)
├─ Features/Map/Components/
│  └─ FuelStationSuggestionBanner.swift  (Fase 3)
├─ Features/Map/Views/
│  ├─ ModeComparisonSheet.swift       (Fase 4)
│  └─ OptimalDepartureView.swift      (Fase 7)
```

### Archivos EXISTENTES a modificar

```
backend-api/src/
├─ interfaces/api/routes/urls.py           (registrar /fuel, /trip)
└─ core/celery.py                          (Fase 3, tarea diaria Profeco)

frontend/AcessNet/
├─ Shared/Models/RouteModels.swift         (+FuelEstimate, +RoutePreference cases)
├─ Core/Services/RouteOptimizer.swift      (+OptimizationConfig.ecoFuel, .cheapest)
├─ Features/Map/Services/RouteManager.swift (llamar FuelAPI en paralelo)
├─ Features/Map/Components/RouteInfoCard.swift           (+Wallet-o-meter)
└─ Features/Map/Components/RoutePreferenceSelector.swift (+presets)
```

---

## 11. KPIs Y MÉTRICAS DE ÉXITO

| Fase | Métrica objetivo | Cómo medir |
|---|---|---|
| 1 | Latencia endpoint `/fuel/estimate` <300ms | Backend logs |
| 2 | Conversión: % usuarios que toca card Wallet | Analytics (añadir event) |
| 3 | Gasolineras actualizadas diarias >90% días | Celery beat logs |
| 4 | % usuarios que abren sheet multimodal | Analytics |
| 5 | Éxito identificación Gemini >75% | Usuarios confirman perfil |
| 6 | MAPE modelo personal post-10 viajes <15% | Backend val dataset |
| 7 | Ventana óptima elegida vs default | Analytics |
| 8 | Dongles conectados únicos | Device IDs |

---

## 12. NARRATIVA PITCH 60s (solo GasolinaMeter)

> "Abres la app. Foto de tu tablero. En 3 segundos Gemini identifica tu Versa 2019 y consulta su rendimiento oficial CONUEE. Seleccionas destino: 'Te cuesta $54 en auto, $10 en Metro, $180 en Uber. En bici ahorras $127 y quemas 320 calorías'. Pero si sales 45 minutos más tarde, el tráfico baja, el AQI cae 58%, y ahorras 7 pesos más. La gasolinera Pemex 400 metros adelante está 68 centavos más barata. Todo esto lo aprende tu auto sin hardware adicional, solo con el acelerómetro que ya tienes. Y si conectas un dongle OBD-II de $30, el modelo llega a error <5% — tan preciso como un taller. AirWay no solo te dice cómo está el aire. Te dice si vale la pena salir."

---

## 13. RIESGOS Y MITIGACIONES

| Riesgo | Mitigación |
|---|---|
| Profeco rate-limit / cambio de formato PDF | Usar dataset CRE en `datos.gob.mx` como fallback |
| Gemini Vision falsos positivos | Confianza mínima 0.6; usuario confirma manualmente |
| OSRM no tiene traffic real-time | Mapbox Directions (capa gratis 100k req/mes) como upgrade |
| OBD-II compatibilidad | Lista whitelist de dongles testados (Vgate iCar Pro, OBDLink MX+) |
| CoreMotion battery drain | Pausar si actividad ≠ automotive >5 min |
| Precios gasolinas desactualizados | Mostrar timestamp "actualizado hace 3 horas" |
| Multimodal: Uber sin API oficial | Fórmula estimativa + disclaimer "aprox." |

---

## 14. FUENTES CLAVE DE INVESTIGACIÓN

- **DLLT LSTM-Transformer (PLOS One 2025):** R²=0.9945 fuel — https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0335542
- **Review OBD-II ML (Sensors 2025):** https://www.mdpi.com/1424-8220/25/13/4057
- **VED Dataset:** https://github.com/gsoh/VED
- **NREL FASTSim:** https://github.com/NREL/fastsim
- **NREL RouteE:** https://github.com/NREL/routee-powertrain
- **Google Routes API eco-routes:** https://developers.google.com/maps/documentation/routes/eco-routes
- **HERE fuelConsumption v8:** https://www.here.com/docs/bundle/routing-api-developer-guide-v8/page/tutorials/calculate-fuel-consumption.html
- **Profeco precios 13-abr-2026:** https://combustibles.profeco.gob.mx/qqpgasolina/2026/QQPGASOLINA_041326.pdf
- **CONUEE catálogo rendimientos MX:** https://www.datos.gob.mx/dataset/catalogo_rendimiento_combustible_vehiculos_ligeros_venta_mexico
- **SEDEMA Inventario ZMVM 2020:** https://proyectos.sedema.cdmx.gob.mx/datos/storage/app/media/docpub/sedema/inventario-emisiones-cdmx-2020bis.pdf
- **VT-Micro original (Rakha et al. 2004):** https://www.researchgate.net/publication/222656465
- **Eco-Routing 20% savings (JCEIM 2025):** https://jceim.org/index.php/ojs/article/view/66
- **Altitud consumo Quito 2200m (Fuel 2011):** https://www.sciencedirect.com/science/article/abs/pii/S0016236111000627
- **SwiftyOBD iOS ELM327:** https://github.com/HellaVentures/iOS-OBD-Example-App
- **VehiclePaliGemma OCR placas (93.8%):** https://arxiv.org/abs/2412.14197
- **Federated Learning fuel (Neural Processing Letters 2025):** https://link.springer.com/article/10.1007/s11063-025-11811-4

---

> **Siguiente paso sugerido:** confirmar el orden de las fases y empezar por Fase 1 (VehicleProfile + motor físico). Esa fase habilita las otras 6. Pregunta al usuario si quiere que empiece a implementar ahora.
