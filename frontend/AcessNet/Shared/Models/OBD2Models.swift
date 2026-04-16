//
//  OBD2Models.swift
//  AcessNet
//
//  Modelos para telemetría en vivo desde dongle OBD-II ELM327 BLE.
//  PIDs estándar SAE J1979.
//

import Foundation

// MARK: - Live Data

struct OBD2LiveData: Equatable {
    var timestamp: Date = Date()

    // PIDs en modo 01
    var rpm: Int = 0                    // PID 0x0C
    var speedKmh: Int = 0               // PID 0x0D
    var throttlePct: Double = 0         // PID 0x11
    var mafGs: Double = 0               // PID 0x10 — Mass Air Flow g/s
    var fuelRateLh: Double = 0          // PID 0x5E — L/hr (si soportado)
    var engineTempC: Int = 0            // PID 0x05
    var intakeTempC: Int = 0            // PID 0x0F
    var baroPressureKpa: Int = 0        // PID 0x33
    var fuelLevelPct: Double = 0        // PID 0x2F
    var engineLoadPct: Double = 0       // PID 0x04

    /// Fuel rate computado desde MAF si el vehículo no reporta PID 0x5E.
    /// MAF [g/s] -> L/hr gasolina aproximado.
    ///
    /// Fórmula: fuel_L_per_hr = (MAF_g_s * 3600) / (AFR * fuel_density_g_per_L)
    /// AFR estequiométrica gasolina ≈ 14.7
    /// Densidad gasolina ≈ 740 g/L
    var computedFuelRateLh: Double {
        if fuelRateLh > 0 { return fuelRateLh }
        guard mafGs > 0 else { return 0 }
        let afr = 14.7
        let density = 740.0
        return (mafGs * 3600) / (afr * density)
    }

    /// Consumo instantáneo km/L (necesita speed)
    var instantKmPerL: Double? {
        let rate = computedFuelRateLh
        guard rate > 0.1, speedKmh > 5 else { return nil }
        return Double(speedKmh) / rate
    }

    /// MPG equivalente (para usuarios EE.UU.)
    var mpg: Double? {
        guard let kmL = instantKmPerL else { return nil }
        return kmL * 2.35215
    }
}

// MARK: - Connection state

enum OBD2ConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting(peripheralName: String?)
    case connected(peripheralName: String)
    case failed(reason: String)

    var label: String {
        switch self {
        case .disconnected: return "Desconectado"
        case .scanning: return "Buscando dongles BLE…"
        case .connecting(let name): return "Conectando \(name ?? "…")"
        case .connected(let name): return "Conectado: \(name)"
        case .failed(let r): return "Error: \(r)"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

// MARK: - PID helpers

enum OBD2PID: String, CaseIterable {
    case rpm = "0C"
    case speed = "0D"
    case throttle = "11"
    case maf = "10"
    case fuelRate = "5E"
    case engineTemp = "05"
    case intakeTemp = "0F"
    case baroPressure = "33"
    case fuelLevel = "2F"
    case engineLoad = "04"

    var command: String { "01\(rawValue)\r" }
    var responsePrefix: String { "41\(rawValue)" }
}
