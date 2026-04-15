//
//  AirQuality.swift
//  AcessNet
//
//  Created by BICHOTEE
//

import Foundation
import CoreLocation

// MARK: - Air Quality Models

struct AirQualityData: Identifiable {
    let id = UUID()
    let aqi: Int
    let pm25: Double
    let pm10: Double
    let location: String
    let city: String
    let distance: Double
    let temperature: Double
    let humidity: Int
    let windSpeed: Double
    let uvIndex: Int
    let weatherCondition: WeatherCondition
    let lastUpdate: Date

    var qualityLevel: AQILevel {
        AQILevel.from(aqi: aqi)
    }

    var timeAgo: String {
        let minutes = Int(Date().timeIntervalSince(lastUpdate) / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes) minutes ago" }
        let hours = minutes / 60
        return "\(hours) hours ago"
    }
}

enum AQILevel: String, CaseIterable {
    case good = "Good"
    case moderate = "Moderate"
    case poor = "Poor"
    case unhealthy = "Unhealthy"
    case severe = "Severe"
    case hazardous = "Hazardous"

    static func from(aqi: Int) -> AQILevel {
        switch aqi {
        case 0..<51: return .good
        case 51..<101: return .moderate
        case 101..<151: return .poor
        case 151..<201: return .unhealthy
        case 201..<301: return .severe
        default: return .hazardous
        }
    }

    var color: String {
        switch self {
        case .good: return "#E0E0E0"
        case .moderate: return "#FDD835" // Amarillo - Estándar AQI para Moderate (51-100)
        case .poor: return "#FF6F00"
        case .unhealthy: return "#E53935"
        case .severe: return "#8E24AA"
        case .hazardous: return "#6A1B4D"
        }
    }

    var backgroundColor: String {
        switch self {
        case .good: return "#B8E986"
        case .moderate: return "#FFD54F" // Amarillo claro - background original
        case .poor: return "#FFB74D"
        case .unhealthy: return "#EF5350"
        case .severe: return "#AB47BC"
        case .hazardous: return "#880E4F"
        }
    }
}

enum WeatherCondition: String {
    case sunny = "Sunny"
    case cloudy = "Cloudy"
    case overcast = "Overcast"
    case rainy = "Rainy"
    case stormy = "Stormy"

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .overcast: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        }
    }
}

// MARK: - Sample Data

extension AirQualityData {
    static let sample = AirQualityData(
        aqi: 75,
        pm25: 22.0,
        pm10: 66.0,
        location: "Atmosphere Science Center",
        city: "Mexico City, Mexico",
        distance: 3.24,
        temperature: 18.0,
        humidity: 68,
        windSpeed: 4.0,
        uvIndex: 0,
        weatherCondition: .overcast,
        lastUpdate: Date().addingTimeInterval(-360)
    )
}
