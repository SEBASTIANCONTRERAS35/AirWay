//
//  AirQualityData.swift
//  AirWayWatch Watch App
//
//  Created by BICHOTEE
//

import SwiftUI

struct AirQualityData {
    let aqi: Int
    let location: String
    let pm25: Double
    let pm10: Double
    let temperature: Int
    let humidity: Int
    let qualityLevel: QualityLevel

    enum QualityLevel: String {
        case good = "Good"
        case moderate = "Moderate"
        case unhealthy = "Unhealthy"
        case veryUnhealthy = "Very Unhealthy"

        var color: String {
            switch self {
            case .good: return "#E0E0E0"
            case .moderate: return "#FDD835"
            case .unhealthy: return "#FF9800"
            case .veryUnhealthy: return "#E53935"
            }
        }
    }

    static let sample = AirQualityData(
        aqi: 58,
        location: "TLALPAN",
        pm25: 25.3,
        pm10: 42.1,
        temperature: 16,
        humidity: 65,
        qualityLevel: .moderate
    )
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
