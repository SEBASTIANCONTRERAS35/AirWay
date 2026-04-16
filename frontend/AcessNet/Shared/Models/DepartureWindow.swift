//
//  DepartureWindow.swift
//  AcessNet
//
//  Modelos para "mejor momento para salir" (Fase 7).
//  Respuesta de /api/v1/fuel/optimal_departure.
//

import Foundation

struct DepartureWindow: Codable, Identifiable, Equatable {
    var id: String { departAt }
    let departAt: String          // ISO-8601
    let hour: Int
    let durationMin: Double
    let distanceKm: Double
    let pesosCost: Double
    let liters: Double
    let co2Kg: Double
    let aqiAvg: Int
    let exposureIndex: Double
    let trafficFactor: Double
    let score: Double
    let rank: Int
    let subScores: SubScores?

    enum CodingKeys: String, CodingKey {
        case hour, score, rank, liters
        case departAt = "depart_at"
        case durationMin = "duration_min"
        case distanceKm = "distance_km"
        case pesosCost = "pesos_cost"
        case co2Kg = "co2_kg"
        case aqiAvg = "aqi_avg"
        case exposureIndex = "exposure_index"
        case trafficFactor = "traffic_factor"
        case subScores = "sub_scores"
    }

    var departDate: Date {
        ISO8601DateFormatter().date(from: departAt) ?? Date()
    }

    var departTimeLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: departDate)
    }

    var aqiCategory: String {
        switch aqiAvg {
        case 0...50: return "Bueno"
        case 51...100: return "Moderado"
        case 101...150: return "Dañino sensibles"
        case 151...200: return "Dañino"
        case 201...300: return "Muy dañino"
        default: return "Peligroso"
        }
    }
}

struct SubScores: Codable, Equatable {
    let time: Double
    let cost: Double
    let aqi: Double
    let exposure: Double
}

struct DepartureSavings: Codable, Equatable {
    let pesos: Double
    let minutes: Double
    let exposurePct: Int
    let co2Kg: Double

    enum CodingKeys: String, CodingKey {
        case pesos, minutes
        case exposurePct = "exposure_pct"
        case co2Kg = "co2_kg"
    }
}

struct OptimalDepartureResponse: Codable {
    let windows: [DepartureWindow]
    let best: DepartureWindow?
    let worst: DepartureWindow?
    let savingsIfBest: DepartureSavings?
    let recommendation: String?
    let vehicleDisplay: String?

    enum CodingKeys: String, CodingKey {
        case windows, best, worst, recommendation
        case savingsIfBest = "savings_if_best"
        case vehicleDisplay = "vehicle_display"
    }
}
