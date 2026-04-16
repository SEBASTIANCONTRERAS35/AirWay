//
//  AppConfig.swift
//  AcessNet
//
//  Configuración global compartida (base URL backend, flags).
//

import Foundation

enum AppConfig {
    /// URL base del backend AirWay. Sobrescribible con env var AIRWAY_API_BASE_URL.
    static var backendBaseURL: URL {
        if let env = ProcessInfo.processInfo.environment["AIRWAY_API_BASE_URL"],
           let u = URL(string: env) {
            return u
        }
        // Default production / dev
        #if DEBUG
        return URL(string: "http://localhost:8000")!
        #else
        return URL(string: "https://api.airway.mx")!
        #endif
    }
}
