//
//  TripMode.swift
//  AcessNet
//
//  Modelos para comparación multimodal (Fase 4).
//  Respuesta de /api/v1/trip/compare
//

import Foundation

// MARK: - Trip mode

struct TripMode: Codable, Equatable, Identifiable {
    var id: String { mode }

    let mode: String                  // "auto" | "metro" | "uber" | "bici"
    let durationMin: Double
    let distanceKm: Double
    let directCostMxn: Double
    let hiddenCostMxn: Double
    let totalCostMxn: Double
    let co2Kg: Double
    let pm25ExposureG: Double
    let caloriesBurned: Int

    // Campos opcionales por modo
    let liters: Double?
    let vehicleDisplay: String?
    let tollsMxn: Double?
    let parkingMxn: Double?
    let depreciationMxn: Double?
    let walkingM: Int?
    let fareBreakdown: [String: Double]?
    let surgeAssumed: Double?
    let fareNote: String?
    let ecobiciAvailable: Bool?
    let healthNote: String?

    enum CodingKeys: String, CodingKey {
        case mode, liters
        case durationMin = "duration_min"
        case distanceKm = "distance_km"
        case directCostMxn = "direct_cost_mxn"
        case hiddenCostMxn = "hidden_cost_mxn"
        case totalCostMxn = "total_cost_mxn"
        case co2Kg = "co2_kg"
        case pm25ExposureG = "pm25_exposure_g"
        case caloriesBurned = "calories_burned"
        case vehicleDisplay = "vehicle_display"
        case tollsMxn = "tolls_mxn"
        case parkingMxn = "parking_mxn"
        case depreciationMxn = "depreciation_mxn"
        case walkingM = "walking_m"
        case fareBreakdown = "fare_breakdown"
        case surgeAssumed = "surge_assumed"
        case fareNote = "fare_note"
        case ecobiciAvailable = "ecobici_available"
        case healthNote = "health_note"
    }

    // MARK: - Presentación

    var emoji: String {
        switch mode {
        case "auto": return "🚗"
        case "metro": return "🚇"
        case "uber": return "🚕"
        case "bici": return "🚴"
        default: return "📍"
        }
    }

    var displayName: String {
        switch mode {
        case "auto": return "Auto"
        case "metro": return "Metro + caminata"
        case "uber": return "Uber / DiDi"
        case "bici": return "Bici"
        default: return mode.capitalized
        }
    }

    var durationFormatted: String {
        if durationMin < 60 { return "\(Int(durationMin.rounded())) min" }
        let h = Int(durationMin) / 60
        let m = Int(durationMin) % 60
        return "\(h)h \(m)m"
    }

    var costFormatted: String {
        "$\(Int(totalCostMxn.rounded())) MXN"
    }

    var co2Formatted: String {
        if co2Kg < 0.01 { return "0 kg" }
        if co2Kg < 1 { return String(format: "%.0f g", co2Kg * 1000) }
        return String(format: "%.1f kg", co2Kg)
    }
}

// MARK: - Response

struct TripCompareResponse: Codable {
    let origin: GeoPoint
    let destination: GeoPoint
    let modes: [String: TripMode]
    let recommendation: TripRecommendation?
    let aiInsight: String?

    enum CodingKeys: String, CodingKey {
        case origin, destination, modes, recommendation
        case aiInsight = "ai_insight"
    }

    /// Orden canónico: auto, metro, uber, bici
    var orderedModes: [TripMode] {
        let order = ["auto", "metro", "uber", "bici"]
        return order.compactMap { modes[$0] }
    }

    var cheapest: TripMode? {
        orderedModes.min(by: { $0.totalCostMxn < $1.totalCostMxn })
    }

    var fastest: TripMode? {
        orderedModes.min(by: { $0.durationMin < $1.durationMin })
    }

    var healthiest: TripMode? {
        // Lowest PM2.5 y cero emisiones propias, con calorías ganadas como bonus
        orderedModes.min(by: { lhs, rhs in
            let lhsScore = lhs.pm25ExposureG - Double(lhs.caloriesBurned) * 0.0001
            let rhsScore = rhs.pm25ExposureG - Double(rhs.caloriesBurned) * 0.0001
            return lhsScore < rhsScore
        })
    }
}

struct GeoPoint: Codable {
    let lat: Double
    let lon: Double
}

struct TripRecommendation: Codable {
    let modeSuggested: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case modeSuggested = "mode_suggested"
        case reason
    }
}
