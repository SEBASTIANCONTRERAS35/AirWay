//
//  VehicleVisionResult.swift
//  AcessNet
//
//  Respuesta de /api/v1/vehicle/identify_from_image (Gemini Vision).
//

import Foundation

struct VehicleVisionResult: Codable, Equatable {
    let success: Bool
    let type: String?              // "dashboard" | "plate" | "exterior" | "sticker" | "unknown"
    let make: String?
    let model: String?
    let yearEstimate: Int?
    let odometerKm: Int?
    let plateNumber: String?
    let holograma: String?
    let confidence: Double
    let notes: String?
    let error: String?
    let matchedConuee: ConueeVehicleEntry?

    enum CodingKeys: String, CodingKey {
        case success, type, make, model, confidence, notes, error
        case yearEstimate = "year_estimate"
        case odometerKm = "odometer_km"
        case plateNumber = "plate_number"
        case holograma
        case matchedConuee = "matched_conuee"
    }

    var confidencePct: Int { Int((confidence * 100).rounded()) }

    /// Construye un VehicleProfile sugerido (priorizando match CONUEE).
    func toVehicleProfile(nickname: String? = nil) -> VehicleProfile? {
        if let match = matchedConuee {
            return match.toVehicleProfile(nickname: nickname)
        }
        guard let mk = make, let md = model, let y = yearEstimate else { return nil }
        return VehicleProfile(
            make: mk, model: md, year: y,
            fuelType: .magna,
            conueeKmPerL: 14.0,
            engineCc: 1600,
            transmission: "manual",
            weightKg: 1150,
            nickname: nickname,
            odometerKm: odometerKm
        )
    }
}
