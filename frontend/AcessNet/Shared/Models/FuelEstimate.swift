//
//  FuelEstimate.swift
//  AcessNet
//
//  Respuesta del endpoint /api/v1/fuel/estimate.
//  Se adjunta a ScoredRoute para que RouteInfoCard muestre el Wallet-o-meter.
//

import Foundation

struct FuelEstimate: Codable, Equatable {
    let liters: Double
    let pesosCost: Double
    let co2Kg: Double
    let pm25Grams: Double
    let confidence: Double
    let distanceKm: Double
    let durationMin: Double?
    let avgSpeedKmh: Double?
    let avgGradePct: Double?
    let stopsEstimated: Int?
    let temperatureC: Double?
    let vehicleDisplay: String?
    let breakdown: FuelBreakdown?
    let kwh: Double?           // Sólo EV

    enum CodingKeys: String, CodingKey {
        case liters
        case pesosCost = "pesos_cost"
        case co2Kg = "co2_kg"
        case pm25Grams = "pm25_g"
        case confidence
        case distanceKm = "distance_km"
        case durationMin = "duration_min"
        case avgSpeedKmh = "avg_speed_kmh"
        case avgGradePct = "avg_grade_pct"
        case stopsEstimated = "stops_estimated"
        case temperatureC = "temperature_c"
        case vehicleDisplay = "vehicle_display"
        case breakdown
        case kwh
    }
}

struct FuelBreakdown: Codable, Equatable {
    let baseLiters: Double?
    let altitudeFactor: Double?
    let gradeFactor: Double?
    let trafficFactor: Double?
    let acFactor: Double?
    let windFactor: Double?
    let styleFactor: Double?
    let speedFactor: Double?
    let passengerFactor: Double?

    enum CodingKeys: String, CodingKey {
        case baseLiters = "base_liters"
        case altitudeFactor = "altitude_factor"
        case gradeFactor = "grade_factor"
        case trafficFactor = "traffic_factor"
        case acFactor = "ac_factor"
        case windFactor = "wind_factor"
        case styleFactor = "style_factor"
        case speedFactor = "speed_factor"
        case passengerFactor = "passenger_factor"
    }
}

extension FuelEstimate {
    /// Formateo amigable para UI
    var litersFormatted: String {
        String(format: "%.2f L", liters)
    }

    var pesosFormatted: String {
        "$\(Int(pesosCost.rounded())) MXN"
    }

    var co2Formatted: String {
        if co2Kg < 1 {
            return String(format: "%.0f g", co2Kg * 1000)
        }
        return String(format: "%.1f kg", co2Kg)
    }

    var confidencePct: Int {
        Int((confidence * 100).rounded())
    }

    /// Breakdown legible para Gemini / UI avanzada
    var breakdownLines: [String] {
        guard let b = breakdown else { return [] }
        var lines: [String] = []
        if let f = b.altitudeFactor, f != 1.0 { lines.append("Altitud CDMX: \(factorString(f))") }
        if let f = b.gradeFactor, f != 1.0 { lines.append("Pendiente: \(factorString(f))") }
        if let f = b.trafficFactor, f != 1.0 { lines.append("Tráfico: \(factorString(f))") }
        if let f = b.acFactor, f != 1.0 { lines.append("A/C: \(factorString(f))") }
        if let f = b.windFactor, f != 1.0 { lines.append("Viento: \(factorString(f))") }
        if let f = b.styleFactor, f != 1.0 { lines.append("Tu estilo: \(factorString(f))") }
        return lines
    }

    private func factorString(_ f: Double) -> String {
        let pct = (f - 1.0) * 100
        return String(format: "%+.1f%%", pct)
    }
}

// MARK: - Fuel Prices (endpoint /fuel/prices)

struct FuelPrices: Codable {
    let magna: Double
    let premium: Double
    let diesel: Double
    let source: String?
    let updatedAt: String?
    let currency: String?
    let unit: String?

    enum CodingKeys: String, CodingKey {
        case magna, premium, diesel, source, currency, unit
        case updatedAt = "updated_at"
    }

    func price(for fuelType: FuelType) -> Double {
        switch fuelType {
        case .magna, .hybrid: return magna
        case .premium: return premium
        case .diesel: return diesel
        case .electric: return 2.85  // MXN/kWh CFE DAC-1
        }
    }
}
