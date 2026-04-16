//
//  ContingencyForecast.swift
//  AcessNet
//
//  Modelos del response de /api/v1/contingency/forecast
//

import Foundation

// MARK: - Response completo

struct ContingencyForecastResponse: Codable {
    let timestamp: Date
    let location: LocationCoordinate
    let forecasts: [HorizonForecast]
    let explanationHint: String
    let modelVersion: String
    let disclaimer: String

    private enum CodingKeys: String, CodingKey {
        case timestamp
        case location
        case forecasts
        case explanationHint = "explanation_hint"
        case modelVersion = "model_version"
        case disclaimer
    }
}

struct LocationCoordinate: Codable {
    let lat: Double
    let lon: Double
}

// MARK: - Pronóstico por horizonte (24h, 48h, 72h)

struct HorizonForecast: Codable, Identifiable {
    var id: Int { horizonH }

    let horizonH: Int
    let probFase1O3: Double        // 0.0–1.0 calibrada
    let probUncalibrated: Double
    let o3ExpectedPpb: Double
    let o3Ci80Ppb: [Double]        // [q10, q90]
    let topDrivers: [ForecastDriver]
    let recommendations: [String]

    private enum CodingKeys: String, CodingKey {
        case horizonH = "horizon_h"
        case probFase1O3 = "prob_fase1_o3"
        case probUncalibrated = "prob_uncalibrated"
        case o3ExpectedPpb = "o3_expected_ppb"
        case o3Ci80Ppb = "o3_ci80_ppb"
        case topDrivers = "top_drivers"
        case recommendations
    }

    // MARK: - Helpers derivados

    var probabilityLevel: ProbabilityLevel {
        switch probFase1O3 {
        case 0..<0.3:  return .low
        case 0.3..<0.6: return .moderate
        case 0.6..<0.8: return .high
        default:        return .veryHigh
        }
    }

    var probabilityPercent: Int {
        Int(round(probFase1O3 * 100))
    }

    var ci80LowerPercent: Int? {
        // El intervalo CI80 es sobre el VALOR de O3, no sobre probabilidad.
        // Esto expone el intervalo correctamente.
        guard o3Ci80Ppb.count >= 2 else { return nil }
        return Int(round(o3Ci80Ppb[0]))
    }

    var ci80UpperPercent: Int? {
        guard o3Ci80Ppb.count >= 2 else { return nil }
        return Int(round(o3Ci80Ppb[1]))
    }
}

// MARK: - Driver individual (para panel de "¿por qué?")

struct ForecastDriver: Codable, Identifiable {
    var id: String { feature }

    let feature: String
    let value: Double?
    let importance: Double

    /// Nombre legible en español del feature técnico.
    var humanName: String {
        switch feature {
        case _ where feature.hasPrefix("O3_max_lag"):
            return "Ozono histórico"
        case _ where feature.hasPrefix("O3_max_roll"):
            return "Tendencia de ozono"
        case _ where feature.hasPrefix("PM25"):
            return "Partículas PM2.5"
        case _ where feature.hasPrefix("NO2"):
            return "Dióxido de nitrógeno"
        case "temperature_2m":          return "Temperatura"
        case "shortwave_radiation":     return "Radiación solar"
        case "uv_index":                return "Índice UV"
        case "wind_speed_10m":          return "Velocidad del viento"
        case "relative_humidity_2m":    return "Humedad"
        case "boundary_layer_height":   return "Altura capa de mezcla"
        case "dT_dz_850":               return "Gradiente vertical T"
        case "inversion_flag":          return "Inversión térmica"
        case "stagnation":              return "Estancamiento atmosférico"
        case "T_x_rad":                 return "Calor × radiación"
        case "vent_idx":                return "Índice de ventilación"
        case "is_ozone_season":         return "Temporada de ozono"
        case "is_weekend":              return "Fin de semana"
        default:
            return feature.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

// MARK: - Niveles y colores

enum ProbabilityLevel: String, Codable {
    case low, moderate, high, veryHigh

    var label: String {
        switch self {
        case .low:      return "Baja"
        case .moderate: return "Moderada"
        case .high:     return "Alta"
        case .veryHigh: return "Muy alta"
        }
    }
}
