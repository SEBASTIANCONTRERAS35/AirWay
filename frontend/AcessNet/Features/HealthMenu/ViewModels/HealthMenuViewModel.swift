//
//  HealthMenuViewModel.swift
//  AcessNet
//
//  VM del menú tipo Cure (MGS3). Mantiene el estado de salud del cuerpo,
//  la lista de tratamientos recomendados y el estado de carga del SDK.
//
//  Fuente de datos:
//   · PhoneConnectivityManager.shared — PPI Score + biométricos + AQI desde
//     Apple Watch / iPhone (Watch Connectivity).
//   · VulnerabilityProfile en UserDefaults — perfil clínico del usuario.
//   · PPIToBodyHealthMapper — traduce biometría + AQI a damage por órgano.
//
//  Si el Watch no está conectado se usa `Input.demoFallback` (CDMX día típico).
//

import SwiftUI
import Observation
import Combine

@MainActor
@Observable
final class HealthMenuViewModel {

    // MARK: - State

    var bodyState: BodyHealthState
    var treatments: [Treatment]
    var isModelReady: Bool = false
    var loadError: String?
    var isLiveData: Bool = false
    var selectedOrgan: BodyHealthState.Organ?

    /// Overrides manuales por órgano para debug/demo (solo builds DEBUG).
    /// Si es != nil, sobrescriben el valor calculado desde biometría.
    var debugHeartOverride: Double? = nil
    var debugLungsOverride: Double? = nil
    var debugBrainOverride: Double? = nil


    var currentAQIBadge: AQIBadge

    struct AQIBadge: Equatable {
        let location: String
        let pollutant: String
        let level: String
        let aqi: Int

        var tint: Color {
            switch aqi {
            case ..<51:   return Color(hex: "#4ADE80")
            case ..<101:  return Color(hex: "#F4B942")
            case ..<151:  return Color(hex: "#FF8A3D")
            case ..<201:  return Color(hex: "#FF5B5B")
            default:      return Color(hex: "#8B5CF6")
            }
        }
    }

    // MARK: - Observation

    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []
    @ObservationIgnored private let connectivity = PhoneConnectivityManager.shared

    // MARK: - Init

    init() {
        // Estado inicial con fallback; se recomputa apenas llega data.
        // Calculamos todo en locales antes de asignar a self para que todas
        // las stored properties queden inicializadas antes del primer acceso
        // a `self` (bindConnectivity / recompute).
        let initial = PPIToBodyHealthMapper.Input.demoFallback
        let initialState = PPIToBodyHealthMapper.map(initial)
        self.bodyState = initialState
        self.treatments = PPIToBodyHealthMapper.treatments(for: initialState, input: initial)
        self.currentAQIBadge = Self.badge(from: initial.aqi)

        bindConnectivity()
        recompute()
    }

    // MARK: - Connectivity binding

    private func bindConnectivity() {
        // Observar cualquier cambio en los @Published del manager y recomputar.
        connectivity.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // `objectWillChange` dispara antes del cambio; hop al siguiente
                // runloop para leer los valores ya actualizados.
                DispatchQueue.main.async { self?.recompute() }
            }
            .store(in: &cancellables)
    }

    /// Construye el Input actual a partir de los datos observables + perfil
    /// almacenado, y recomputa BodyHealthState + tratamientos.
    func recompute() {
        let input = currentInput()
        var state = PPIToBodyHealthMapper.map(input)

        // Overrides manuales (debug slider) tienen precedencia sobre biometría.
        let heart = debugHeartOverride.map { OrganHealth(damageLevel: $0,
                                                         activeConditions: state.heart.activeConditions) }
            ?? state.heart
        let lungs = debugLungsOverride.map { OrganHealth(damageLevel: $0,
                                                         activeConditions: state.lungs.activeConditions) }
            ?? state.lungs
        let brain = debugBrainOverride.map { OrganHealth(damageLevel: $0,
                                                         activeConditions: state.brain.activeConditions) }
            ?? state.brain

        state = BodyHealthState(
            lungs: lungs,
            nose: state.nose,
            brain: brain,
            throat: state.throat,
            heart: heart,
            skin: state.skin
        )

        bodyState = state
        treatments = PPIToBodyHealthMapper.treatments(for: bodyState, input: input)
        currentAQIBadge = Self.badge(from: input.aqi)
        isLiveData = connectivity.latestPPIScore != nil
            || connectivity.latestBiometrics != nil
    }

    /// Aplicados desde el slider de debug. Disparan un recompute inmediato.
    func setHeartDebugOverride(_ value: Double?) {
        debugHeartOverride = value
        recompute()
    }

    func setLungsDebugOverride(_ value: Double?) {
        debugLungsOverride = value
        recompute()
    }

    func setBrainDebugOverride(_ value: Double?) {
        debugBrainOverride = value
        recompute()
    }

    /// Helper genérico para el panel debug polimórfico.
    func setDebugOverride(for focus: BodyPartFocus, value: Double?) {
        switch focus {
        case .heart: setHeartDebugOverride(value)
        case .lungs: setLungsDebugOverride(value)
        case .brain: setBrainDebugOverride(value)
        }
    }

    // MARK: - Exposure causes (datos narrativos para UI)

    /// Cigarrillos equivalentes fumados hoy por exposición a PM2.5.
    /// Si hay `CigaretteData` del Watch, lo usamos directo. Si no, estimamos
    /// asumiendo 8h de exposición al AQI actual (≈ 1 cig cada 22 µg/m³).
    var cigarettesEquivalentToday: Double {
        if let cig = connectivity.latestCigaretteData?.cigarettesToday, cig > 0 {
            return cig
        }
        let pm25 = PPIToBodyHealthMapper.Input.demoFallback.aqi?.pm25 ?? 35
        return min((pm25 / 22.0) * (8.0 / 24.0), 5.0) // estimado suave
    }

    /// Dosis PM2.5 acumulada en µg (microgramos inhalados).
    var cumulativePM25DoseUg: Double {
        connectivity.latestCigaretteData?.cumulativeDoseUg ?? {
            let pm25 = PPIToBodyHealthMapper.Input.demoFallback.aqi?.pm25 ?? 35
            return pm25 * 8 // µg × horas estimadas
        }()
    }

    /// Horas estimadas en aire con AQI > 100 hoy.
    var hoursInBadAirToday: Double {
        guard let aqi = PPIToBodyHealthMapper.Input.demoFallback.aqi?.aqi else { return 0 }
        if aqi > 150 { return 8.0 }
        if aqi > 100 { return 4.5 }
        if aqi > 50  { return 1.5 }
        return 0.0
    }

    /// HR actual del Watch (si disponible) o demo.
    var currentHeartRate: Double? {
        connectivity.latestBiometrics?.heartRate
    }

    /// SpO2 actual del Watch.
    var currentSpO2: Double? {
        connectivity.latestBiometrics?.spO2
    }

    func debugOverride(for focus: BodyPartFocus) -> Double? {
        switch focus {
        case .heart: return debugHeartOverride
        case .lungs: return debugLungsOverride
        case .brain: return debugBrainOverride
        }
    }

    private func currentInput() -> PPIToBodyHealthMapper.Input {
        PPIToBodyHealthMapper.Input(
            ppi: connectivity.latestPPIScore,
            biometrics: connectivity.latestBiometrics,
            aqi: PPIToBodyHealthMapper.Input.demoFallback.aqi, // TODO: conectar AQI real observable
            cigarettes: connectivity.latestCigaretteData,
            vulnerability: loadVulnerability()
        )
    }

    private func loadVulnerability() -> VulnerabilityProfile {
        guard let data = UserDefaults.standard.data(forKey: "vulnerability_profile_data"),
              let decoded = try? JSONDecoder().decode(VulnerabilityProfile.self, from: data) else {
            return VulnerabilityProfile()
        }
        return decoded
    }

    private static func badge(from aqi: AQIUpdateData?) -> AQIBadge {
        guard let aqi else {
            return AQIBadge(location: "CDMX", pollutant: "PM2.5", level: "—", aqi: 0)
        }
        let level: String = {
            switch aqi.aqi {
            case ..<51:  return "BUENO"
            case ..<101: return "MODERADO"
            case ..<151: return "MALO"
            case ..<201: return "MUY MALO"
            default:     return "PELIGROSO"
            }
        }()
        return AQIBadge(
            location: aqi.location,
            pollutant: aqi.dominantPollutant ?? "PM2.5",
            level: level,
            aqi: aqi.aqi
        )
    }

    // MARK: - SDK callbacks (anatomical model)

    func handleModelReady() {
        isModelReady = true
        loadError = nil
    }

    func handleLoadError(_ message: String) {
        isModelReady = false
        loadError = message
    }

    func handleFallbackNotice(_ message: String) {
        isModelReady = true
        loadError = message
    }

    func didSelectOrgan(_ organ: BodyHealthState.Organ) {
        HapticFeedback.light()
        selectedOrgan = organ
    }

    func didPickObject(_ objectId: String) {
        guard let organ = BioDigitalOrganMapper.organ(forObjectId: objectId) else {
            print("🩺 BioDigital objectPicked (no mapeado): \(objectId)")
            return
        }
        didSelectOrgan(organ)
    }

    func didTapTreatment(_ treatment: Treatment) {
        // TODO: deep link a detalle del tratamiento
        print("🩺 tapped treatment: \(treatment.title)")
    }

    func dismissOrganDetail() {
        selectedOrgan = nil
    }

    func retryLoad() {
        loadError = nil
        isModelReady = false
    }
}
