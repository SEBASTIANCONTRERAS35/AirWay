//
//  AirWayLogger.swift
//  AcessNet
//
//  Logger centralizado para AirWay usando os.Logger (iOS 14+).
//  Soporta niveles estándar + privacy classification nativa de Apple.
//
//  Uso:
//    AirWayLogger.fuel.info("Estimación \(liters, privacy: .public) L")
//    AirWayLogger.obd.error("BLE connection failed: \(error.localizedDescription, privacy: .public)")
//
//  Ver logs:
//    - Console.app (macOS): filtrar subsystem:mx.airway
//    - Xcode: ⌘⇧Y (Debug Area)
//    - En terminal: `log stream --predicate 'subsystem == "mx.airway"' --level debug`
//

import Foundation
import os

/// Logger centralizado por categoría.
/// Subsystem único = "mx.airway"
enum AirWayLogger {
    private static let subsystem = "mx.airway"

    // MARK: - Categories (cada módulo mayor tiene su logger)

    /// GasolinaMeter: VehicleProfile, estimate, catalog, prices.
    static let fuel = Logger(subsystem: subsystem, category: "fuel")

    /// Gasolineras / Profeco.
    static let stations = Logger(subsystem: subsystem, category: "stations")

    /// Comparación multimodal (auto/metro/uber/bici).
    static let trip = Logger(subsystem: subsystem, category: "trip")

    /// Gemini Vision (identificación de auto por foto).
    static let vision = Logger(subsystem: subsystem, category: "vision")

    /// Mejor momento para salir.
    static let departure = Logger(subsystem: subsystem, category: "departure")

    /// Telemetría CoreMotion + CoreLocation durante un viaje.
    static let telemetry = Logger(subsystem: subsystem, category: "telemetry")

    /// OBD-II Bluetooth.
    static let obd = Logger(subsystem: subsystem, category: "obd")

    /// Red / HTTP (base client, URLSession).
    static let network = Logger(subsystem: subsystem, category: "network")

    /// Ruteo existente (MKDirections, OSRM).
    static let routing = Logger(subsystem: subsystem, category: "routing")

    /// UI / Navegación.
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Default catch-all para módulos sin categoría específica.
    static let app = Logger(subsystem: subsystem, category: "app")
}

// MARK: - Convenience helpers

extension Logger {
    /// Log de request HTTP con método, URL y tamaño de body.
    func httpRequest(method: String, url: URL, bodySize: Int? = nil) {
        if let size = bodySize {
            self.debug("→ HTTP \(method, privacy: .public) \(url.absoluteString, privacy: .public) [body \(size) bytes]")
        } else {
            self.debug("→ HTTP \(method, privacy: .public) \(url.absoluteString, privacy: .public)")
        }
    }

    /// Log de response HTTP con status + tamaño.
    func httpResponse(url: URL, status: Int, bytes: Int, durationMs: Double) {
        let symbol = (200..<300).contains(status) ? "✓" : "✗"
        self.debug("\(symbol, privacy: .public) HTTP \(status, privacy: .public) \(url.lastPathComponent, privacy: .public) \(bytes) bytes \(String(format: "%.0f", durationMs))ms")
    }

    /// Log de error HTTP.
    func httpError(url: URL, error: Error) {
        self.error("✗ HTTP error \(url.absoluteString, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }
}

// MARK: - Startup banner

enum AirWayLogBanner {
    static func logStartup() {
        AirWayLogger.app.notice("=== AirWay starting · subsystem=mx.airway ===")
        AirWayLogger.app.info("Backend base URL: \(AppConfig.backendBaseURL.absoluteString, privacy: .public)")
        #if DEBUG
        AirWayLogger.app.info("Build: DEBUG")
        #else
        AirWayLogger.app.info("Build: RELEASE")
        #endif
    }
}
