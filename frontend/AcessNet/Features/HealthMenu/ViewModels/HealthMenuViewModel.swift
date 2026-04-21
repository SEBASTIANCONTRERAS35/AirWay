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
        bodyState = PPIToBodyHealthMapper.map(input)
        treatments = PPIToBodyHealthMapper.treatments(for: bodyState, input: input)
        currentAQIBadge = Self.badge(from: input.aqi)
        isLiveData = connectivity.latestPPIScore != nil
            || connectivity.latestBiometrics != nil
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
