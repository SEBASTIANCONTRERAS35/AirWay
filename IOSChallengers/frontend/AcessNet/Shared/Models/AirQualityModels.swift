//
//  AirQualityModels.swift
//  AcessNet
//
//  Modelos de datos para calidad del aire integrados con NASA APIs
//
//  NOTA: AQILevel está definido en AirQuality.swift (del equipo develop)
//  Este archivo extiende esa funcionalidad base con modelos adicionales para NASA APIs
//

import Foundation
import CoreLocation

// MARK: - AQILevel Extension

extension AQILevel {
    /// Ícono SF Symbol extendido para routing
    var routingIcon: String {
        switch self {
        case .good: return "leaf.fill"
        case .moderate: return "leaf"
        case .poor: return "exclamationmark.triangle"
        case .unhealthy: return "exclamationmark.triangle.fill"
        case .severe: return "xmark.shield.fill"
        case .hazardous: return "allergens.fill"
        }
    }

    /// Mensaje de salud extendido
    var extendedHealthMessage: String {
        switch self {
        case .good:
            return "Air quality is satisfactory"
        case .moderate:
            return "Acceptable air quality"
        case .poor:
            return "Sensitive groups may experience health effects"
        case .unhealthy:
            return "Everyone may begin to experience health effects"
        case .severe:
            return "Health alert: everyone may experience serious effects"
        case .hazardous:
            return "Health warning: emergency conditions"
        }
    }
}

// MARK: - Health Risk Assessment

/// Evaluación de riesgo para la salud
enum HealthRisk: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"

    var icon: String {
        switch self {
        case .low: return "checkmark.shield.fill"
        case .medium: return "shield.lefthalf.filled"
        case .high: return "exclamationmark.shield.fill"
        case .veryHigh: return "xmark.shield.fill"
        }
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .veryHigh: return "red"
        }
    }
}

// MARK: - Air Quality Point Data

/// Datos de calidad del aire en un punto específico
struct AirQualityPoint: Codable, Identifiable {
    let id: UUID
    let coordinate: CoordinateCodable
    let aqi: Double                    // Air Quality Index (0-500)
    let pm25: Double                   // PM2.5 particulate matter (μg/m³)
    let pm10: Double?                  // PM10 particulate matter (μg/m³)
    let no2: Double?                   // Nitrogen Dioxide (ppb)
    let o3: Double?                    // Ozone (ppb)
    let co: Double?                    // Carbon Monoxide (ppm)
    let so2: Double?                   // Sulfur Dioxide (ppb)
    let aod: Double?                   // Aerosol Optical Depth (NASA MODIS)
    let timestamp: Date

    init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        aqi: Double,
        pm25: Double,
        pm10: Double? = nil,
        no2: Double? = nil,
        o3: Double? = nil,
        co: Double? = nil,
        so2: Double? = nil,
        aod: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.coordinate = CoordinateCodable(coordinate: coordinate)
        self.aqi = aqi
        self.pm25 = pm25
        self.pm10 = pm10
        self.no2 = no2
        self.o3 = o3
        self.co = co
        self.so2 = so2
        self.aod = aod
        self.timestamp = timestamp
    }

    /// Nivel de calidad del aire
    var level: AQILevel {
        return AQILevel.from(aqi: Int(aqi))
    }

    /// Score de salud (0-100, donde 100 es mejor)
    var healthScore: Double {
        // Invertir AQI: cuanto menor el AQI, mejor el score
        // AQI 0 → 100, AQI 500 → 0
        return max(0, min(100, 100 * (1 - aqi / 500)))
    }

    /// Riesgo para la salud
    var healthRisk: HealthRisk {
        switch level {
        case .good, .moderate:
            return .low
        case .poor:
            return .medium
        case .unhealthy:
            return .high
        case .severe, .hazardous:
            return .veryHigh
        }
    }
}

// MARK: - Air Quality Segment

/// Segmento de ruta con datos de calidad del aire
struct AirQualitySegment: Codable, Identifiable {
    let id: UUID
    let startCoordinate: CoordinateCodable
    let endCoordinate: CoordinateCodable
    let distanceMeters: Double
    let airQuality: AirQualityPoint

    init(
        id: UUID = UUID(),
        startCoordinate: CLLocationCoordinate2D,
        endCoordinate: CLLocationCoordinate2D,
        distanceMeters: Double,
        airQuality: AirQualityPoint
    ) {
        self.id = id
        self.startCoordinate = CoordinateCodable(coordinate: startCoordinate)
        self.endCoordinate = CoordinateCodable(coordinate: endCoordinate)
        self.distanceMeters = distanceMeters
        self.airQuality = airQuality
    }
}

// MARK: - Air Quality Route Analysis

/// Análisis completo de calidad del aire de una ruta
struct AirQualityRouteAnalysis: Codable, Identifiable {
    let id: UUID
    let segments: [AirQualitySegment]
    let averageAQI: Double
    let maxAQI: Double
    let minAQI: Double
    let averagePM25: Double
    let averageHealthScore: Double
    let overallHealthRisk: HealthRisk
    let timestamp: Date

    init(
        id: UUID = UUID(),
        segments: [AirQualitySegment],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.segments = segments
        self.timestamp = timestamp

        // Calcular estadísticas
        let aqiValues = segments.map { $0.airQuality.aqi }
        self.averageAQI = aqiValues.isEmpty ? 0 : aqiValues.reduce(0, +) / Double(aqiValues.count)
        self.maxAQI = aqiValues.max() ?? 0
        self.minAQI = aqiValues.min() ?? 0

        let pm25Values = segments.map { $0.airQuality.pm25 }
        self.averagePM25 = pm25Values.isEmpty ? 0 : pm25Values.reduce(0, +) / Double(pm25Values.count)

        let healthScores = segments.map { $0.airQuality.healthScore }
        self.averageHealthScore = healthScores.isEmpty ? 0 : healthScores.reduce(0, +) / Double(healthScores.count)

        // Determinar riesgo general (usar el peor segmento)
        let level = AQILevel.from(aqi: Int(maxAQI))
        switch level {
        case .good, .moderate:
            self.overallHealthRisk = .low
        case .poor:
            self.overallHealthRisk = .medium
        case .unhealthy:
            self.overallHealthRisk = .high
        case .severe, .hazardous:
            self.overallHealthRisk = .veryHigh
        }
    }

    /// Nivel promedio de calidad del aire
    var averageLevel: AQILevel {
        return AQILevel.from(aqi: Int(averageAQI))
    }

    /// Descripción textual del análisis
    var summary: String {
        return "Avg AQI: \(Int(averageAQI)) (\(averageLevel.rawValue))"
    }

    // MARK: - Route Level Distribution

    /// Cuenta de segmentos por nivel de AQI
    var goodSegments: Int {
        segments.filter { AQILevel.from(aqi: Int($0.airQuality.aqi)) == .good }.count
    }

    var moderateSegments: Int {
        segments.filter { AQILevel.from(aqi: Int($0.airQuality.aqi)) == .moderate }.count
    }

    var poorSegments: Int {
        segments.filter { AQILevel.from(aqi: Int($0.airQuality.aqi)) == .poor }.count
    }

    var unhealthySegments: Int {
        segments.filter { AQILevel.from(aqi: Int($0.airQuality.aqi)) == .unhealthy }.count
    }

    var severeSegments: Int {
        segments.filter { AQILevel.from(aqi: Int($0.airQuality.aqi)) == .severe }.count
    }

    var hazardousSegments: Int {
        segments.filter { AQILevel.from(aqi: Int($0.airQuality.aqi)) == .hazardous }.count
    }

    /// Total de segmentos analizados
    var totalSegments: Int {
        segments.count
    }

    /// Descripción detallada de la distribución
    var levelDistributionSummary: String {
        var parts: [String] = []
        if goodSegments > 0 { parts.append("Good: \(goodSegments)") }
        if moderateSegments > 0 { parts.append("Moderate: \(moderateSegments)") }
        if poorSegments > 0 { parts.append("Poor: \(poorSegments)") }
        if unhealthySegments > 0 { parts.append("Unhealthy: \(unhealthySegments)") }
        if severeSegments > 0 { parts.append("Severe: \(severeSegments)") }
        if hazardousSegments > 0 { parts.append("Hazardous: \(hazardousSegments)") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Coordinate Codable Wrapper

/// Wrapper para hacer CLLocationCoordinate2D codable
struct CoordinateCodable: Codable {
    let latitude: Double
    let longitude: Double

    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - API Request/Response Models

/// Request para analizar una ruta
struct AnalyzeRouteRequest: Codable {
    let coordinates: [CoordinateCodable]
    let samplingIntervalMeters: Double

    init(coordinates: [CLLocationCoordinate2D], samplingIntervalMeters: Double = 150) {
        self.coordinates = coordinates.map { CoordinateCodable(coordinate: $0) }
        self.samplingIntervalMeters = samplingIntervalMeters
    }
}

/// Response del backend con análisis de ruta
struct AnalyzeRouteResponse: Codable {
    let routeId: String
    let analysis: AirQualityRouteAnalysis
    let processingTimeMs: Int
    let dataSource: String  // "NASA-MODIS", "NASA-GEOS", etc.
}

/// Request para obtener calidad del aire en un punto
struct AirQualityPointRequest: Codable {
    let latitude: Double
    let longitude: Double
    let includeExtendedMetrics: Bool

    init(coordinate: CLLocationCoordinate2D, includeExtendedMetrics: Bool = false) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.includeExtendedMetrics = includeExtendedMetrics
    }
}

/// Response con datos de un punto
struct AirQualityPointResponse: Codable {
    let airQuality: AirQualityPoint
    let dataSource: String
    let cacheAge: Int?  // Edad del cache en segundos
}

/// Request batch para múltiples puntos
struct BatchAirQualityRequest: Codable {
    let coordinates: [CoordinateCodable]
    let includeExtendedMetrics: Bool

    init(coordinates: [CLLocationCoordinate2D], includeExtendedMetrics: Bool = false) {
        self.coordinates = coordinates.map { CoordinateCodable(coordinate: $0) }
        self.includeExtendedMetrics = includeExtendedMetrics
    }
}

/// Response batch
struct BatchAirQualityResponse: Codable {
    let points: [AirQualityPoint]
    let dataSource: String
    let totalProcessingTimeMs: Int
}
