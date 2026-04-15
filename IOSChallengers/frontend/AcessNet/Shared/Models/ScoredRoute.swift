//
//  ScoredRoute.swift
//  AcessNet
//
//  Modelo de ruta con scoring multi-criterio (tiempo + calidad del aire)
//

import Foundation
import MapKit

// MARK: - Scored Route

/// Ruta con análisis de tiempo, calidad del aire e incidentes combinados
struct ScoredRoute: Identifiable {
    let id: UUID
    let routeInfo: RouteInfo
    let airQualityAnalysis: AirQualityRouteAnalysis?
    let incidentAnalysis: IncidentRouteAnalysis?

    // Scores normalizados (0-100)
    let timeScore: Double          // 100 = más rápido
    let airQualityScore: Double    // 100 = mejor aire
    let safetyScore: Double        // 100 = más seguro (menos incidentes)
    let combinedScore: Double      // Score final ponderado

    // Metadata
    let preference: RoutePreference
    let rankPosition: Int?         // Posición en ranking (1 = mejor)

    init(
        id: UUID = UUID(),
        routeInfo: RouteInfo,
        airQualityAnalysis: AirQualityRouteAnalysis? = nil,
        incidentAnalysis: IncidentRouteAnalysis? = nil,
        fastestTime: TimeInterval,
        cleanestAQI: Double,
        safestSafetyScore: Double = 100.0,
        preference: RoutePreference,
        rankPosition: Int? = nil
    ) {
        self.id = id
        self.routeInfo = routeInfo
        self.airQualityAnalysis = airQualityAnalysis
        self.incidentAnalysis = incidentAnalysis
        self.preference = preference
        self.rankPosition = rankPosition

        // Calcular score de tiempo (normalizado)
        self.timeScore = RouteScoring.calculateTimeScore(
            actualTime: routeInfo.expectedTravelTime,
            fastestTime: fastestTime
        )

        // Calcular score de calidad del aire (normalizado)
        if let analysis = airQualityAnalysis {
            self.airQualityScore = RouteScoring.calculateAirQualityScore(
                actualAQI: analysis.averageAQI,
                cleanestAQI: cleanestAQI
            )
        } else {
            // Si no hay datos de aire, usar score neutral (50)
            self.airQualityScore = 50.0
        }

        // Calcular score de seguridad (normalizado)
        if let analysis = incidentAnalysis {
            self.safetyScore = analysis.safetyScore
        } else {
            // Si no hay datos de incidentes, asumir ruta segura (85)
            self.safetyScore = 85.0
        }

        // Calcular score combinado según preferencia
        self.combinedScore = RouteScoring.calculateCombinedScoreWithSafety(
            timeScore: self.timeScore,
            airQualityScore: self.airQualityScore,
            safetyScore: self.safetyScore,
            preference: preference
        )
    }

    // MARK: - Computed Properties

    /// Nivel de calidad del aire promedio
    var averageAQILevel: AQILevel {
        guard let analysis = airQualityAnalysis else { return .moderate }
        return analysis.averageLevel
    }

    /// Riesgo para la salud
    var healthRisk: HealthRisk {
        guard let analysis = airQualityAnalysis else { return .medium }
        return analysis.overallHealthRisk
    }

    /// AQI promedio
    var averageAQI: Double {
        return airQualityAnalysis?.averageAQI ?? 0
    }

    /// PM2.5 promedio
    var averagePM25: Double {
        return airQualityAnalysis?.averagePM25 ?? 0
    }

    /// Formato de AQI para mostrar
    var aqiFormatted: String {
        return String(format: "%.0f", averageAQI)
    }

    /// Descripción del score combinado
    var scoreDescription: String {
        switch combinedScore {
        case 90...100: return "Excellent Route"
        case 75..<90: return "Very Good Route"
        case 60..<75: return "Good Route"
        case 40..<60: return "Fair Route"
        default: return "Poor Route"
        }
    }

    /// Icono según score
    var scoreIcon: String {
        switch combinedScore {
        case 90...100: return "star.circle.fill"
        case 75..<90: return "checkmark.circle.fill"
        case 60..<75: return "checkmark.circle"
        case 40..<60: return "minus.circle"
        default: return "xmark.circle"
        }
    }

    /// Resumen de la ruta
    var summary: String {
        var parts: [String] = []

        parts.append(routeInfo.distanceFormatted)
        parts.append(routeInfo.timeFormatted)

        if let analysis = airQualityAnalysis {
            parts.append("AQI \(Int(analysis.averageAQI))")
        }

        if let incidents = incidentAnalysis {
            if incidents.totalIncidents > 0 {
                parts.append("\(incidents.totalIncidents) incident\(incidents.totalIncidents > 1 ? "s" : "")")
            }
        }

        return parts.joined(separator: " • ")
    }

    /// Nivel de riesgo de la ruta
    var riskLevel: RiskLevel? {
        return incidentAnalysis?.riskLevel
    }

    /// Resumen de incidentes
    var incidentSummary: String? {
        return incidentAnalysis?.incidentSummary
    }
}

// MARK: - Route Scoring Engine

/// Motor de cálculo de scoring multi-criterio
struct RouteScoring {

    // MARK: - Score Calculation

    /// Calcula el score de tiempo normalizado (0-100)
    /// - Parameters:
    ///   - actualTime: Tiempo de la ruta actual en segundos
    ///   - fastestTime: Tiempo de la ruta más rápida en segundos
    /// - Returns: Score de 0 a 100 (100 = más rápido)
    static func calculateTimeScore(actualTime: TimeInterval, fastestTime: TimeInterval) -> Double {
        guard actualTime > 0, fastestTime > 0 else { return 50.0 }

        // Score = 100 * (tiempo_minimo / tiempo_actual)
        // Cuanto más cercano a tiempo_minimo, más cercano a 100
        let ratio = fastestTime / actualTime
        let score = ratio * 100

        // Limitar entre 0 y 100
        return max(0, min(100, score))
    }

    /// Calcula el score de calidad del aire normalizado (0-100)
    /// - Parameters:
    ///   - actualAQI: AQI de la ruta actual
    ///   - cleanestAQI: AQI de la ruta más limpia
    /// - Returns: Score de 0 a 100 (100 = mejor aire)
    static func calculateAirQualityScore(actualAQI: Double, cleanestAQI: Double) -> Double {
        guard actualAQI > 0, cleanestAQI > 0 else { return 50.0 }

        // Scoring RELATIVO: comparar contra la ruta más limpia
        // Esto crea diferencias claras entre rutas para mejor etiquetado

        // Calcular score base para ambas rutas
        let actualScore = 100 * (1 - actualAQI / 500)   // Ruta actual
        let cleanScore = 100 * (1 - cleanestAQI / 500)  // Ruta más limpia

        // Normalizar: la más limpia = 100, el resto proporcional
        if cleanScore > 0 {
            let normalized = (actualScore / cleanScore) * 100
            return max(0, min(100, normalized))
        }

        // Fallback: usar score absoluto
        return max(0, min(100, actualScore))
    }

    /// Calcula el score combinado según la preferencia del usuario
    /// - Parameters:
    ///   - timeScore: Score de tiempo (0-100)
    ///   - airQualityScore: Score de calidad del aire (0-100)
    ///   - preference: Preferencia de ruteo
    /// - Returns: Score combinado ponderado (0-100)
    static func calculateCombinedScore(
        timeScore: Double,
        airQualityScore: Double,
        preference: RoutePreference
    ) -> Double {
        let (timeWeight, airWeight) = preference.weights

        let combined = (timeWeight * timeScore) + (airWeight * airQualityScore)

        return max(0, min(100, combined))
    }

    /// Calcula el score combinado con seguridad según la preferencia del usuario
    /// - Parameters:
    ///   - timeScore: Score de tiempo (0-100)
    ///   - airQualityScore: Score de calidad del aire (0-100)
    ///   - safetyScore: Score de seguridad (0-100)
    ///   - preference: Preferencia de ruteo
    /// - Returns: Score combinado ponderado (0-100)
    static func calculateCombinedScoreWithSafety(
        timeScore: Double,
        airQualityScore: Double,
        safetyScore: Double,
        preference: RoutePreference
    ) -> Double {
        let weights = preference.weightsWithSafety

        let combined = (weights.timeWeight * timeScore) +
                      (weights.airQualityWeight * airQualityScore) +
                      (weights.safetyWeight * safetyScore)

        return max(0, min(100, combined))
    }

    // MARK: - Comparison Helpers

    /// Compara dos rutas y retorna la diferencia
    static func compareRoutes(_ route1: ScoredRoute, _ route2: ScoredRoute) -> RouteComparison {
        let timeDiff = route1.routeInfo.expectedTravelTime - route2.routeInfo.expectedTravelTime
        let aqiDiff = route1.averageAQI - route2.averageAQI

        let timeDiffMinutes = Int(timeDiff / 60)
        let aqiDiffPercentage = (aqiDiff / route2.averageAQI) * 100

        return RouteComparison(
            timeDifferenceMinutes: timeDiffMinutes,
            aqiDifference: aqiDiff,
            aqiDifferencePercentage: aqiDiffPercentage,
            betterAirQuality: route1.averageAQI < route2.averageAQI,
            fasterRoute: route1.routeInfo.expectedTravelTime < route2.routeInfo.expectedTravelTime
        )
    }
}

// MARK: - Route Comparison

/// Comparación entre dos rutas
struct RouteComparison {
    let timeDifferenceMinutes: Int     // Positivo = route1 es más lento
    let aqiDifference: Double          // Positivo = route1 tiene peor aire
    let aqiDifferencePercentage: Double
    let betterAirQuality: Bool         // true si route1 tiene mejor aire
    let fasterRoute: Bool              // true si route1 es más rápido

    /// Descripción textual de la comparación
    var description: String {
        var parts: [String] = []

        // Tiempo
        if timeDifferenceMinutes == 0 {
            parts.append("Same time")
        } else if timeDifferenceMinutes > 0 {
            parts.append("\(abs(timeDifferenceMinutes)) min slower")
        } else {
            parts.append("\(abs(timeDifferenceMinutes)) min faster")
        }

        // Calidad del aire
        if abs(aqiDifferencePercentage) < 5 {
            parts.append("similar air quality")
        } else if betterAirQuality {
            parts.append("\(Int(abs(aqiDifferencePercentage)))% cleaner air")
        } else {
            parts.append("\(Int(abs(aqiDifferencePercentage)))% worse air")
        }

        return parts.joined(separator: ", ")
    }

    /// Descripción corta
    var shortDescription: String {
        if fasterRoute && betterAirQuality {
            return "⭐ Faster & cleaner"
        } else if fasterRoute {
            return "⚡ Faster route"
        } else if betterAirQuality {
            return "🌿 Cleaner air"
        } else {
            return "⚠️ Slower & worse air"
        }
    }
}

// MARK: - Route Preference Extension

extension RoutePreference {

    /// Pesos para scoring combinado (timeWeight, airQualityWeight)
    /// Los pesos suman 1.0 (100%)
    var weights: (timeWeight: Double, airQualityWeight: Double) {
        switch self {
        case .fastest:
            return (1.0, 0.0)  // 100% tiempo, 0% aire

        case .shortest:
            return (1.0, 0.0)  // 100% distancia (usa tiempo como proxy)

        case .avoidHighways:
            return (1.0, 0.0)  // 100% tiempo

        case .cleanestAir:
            return (0.0, 1.0)  // 0% tiempo, 100% aire

        case .balanced:
            return (0.5, 0.5)  // 50% tiempo, 50% aire

        case .healthOptimized:
            return (0.3, 0.7)  // 30% tiempo, 70% aire

        case .safest:
            return (0.2, 0.0)  // 20% tiempo, 0% aire (80% safety implícito)

        case .avoidIncidents:
            return (0.3, 0.0)  // 30% tiempo, 0% aire (70% safety implícito)

        case .balancedSafety:
            return (0.33, 0.33)  // 33% tiempo, 33% aire (34% safety implícito)

        case .customWeighted(let timeWeight, let airWeight):
            // Normalizar para que sumen 1.0
            let total = timeWeight + airWeight
            guard total > 0 else { return (0.5, 0.5) }
            return (timeWeight / total, airWeight / total)

        case .customWeightedSafety:
            return (0.33, 0.33)  // Por defecto balanceado
        }
    }

    /// Pesos para scoring combinado con seguridad (timeWeight, airQualityWeight, safetyWeight)
    /// Los pesos suman 1.0 (100%)
    var weightsWithSafety: (timeWeight: Double, airQualityWeight: Double, safetyWeight: Double) {
        switch self {
        case .fastest:
            return (1.0, 0.0, 0.0)  // 100% tiempo

        case .shortest:
            return (1.0, 0.0, 0.0)  // 100% distancia (usa tiempo como proxy)

        case .avoidHighways:
            return (0.8, 0.0, 0.2)  // 80% tiempo, 20% safety (evitar autopistas puede ser más seguro)

        case .cleanestAir:
            return (0.0, 1.0, 0.0)  // 100% aire

        case .balanced:
            return (0.2, 0.5, 0.3)  // 20% tiempo, 50% aire, 30% safety - Prioriza aire limpio

        case .healthOptimized:
            return (0.2, 0.5, 0.3)  // 20% tiempo, 50% aire, 30% safety

        case .safest:
            return (0.2, 0.0, 0.8)  // 20% tiempo, 80% safety

        case .avoidIncidents:
            return (0.3, 0.0, 0.7)  // 30% tiempo, 70% safety

        case .balancedSafety:
            return (0.40, 0.10, 0.50)  // 50% safety, 40% time, 10% air - Prioriza seguridad + rapidez

        case .customWeighted(let timeWeight, let airWeight):
            // Añadir un peso de seguridad mínimo
            let safetyWeight = 0.1
            let total = timeWeight + airWeight + safetyWeight
            return (timeWeight / total, airWeight / total, safetyWeight / total)

        case .customWeightedSafety(let timeWeight, let airWeight, let safetyWeight):
            // Normalizar para que sumen 1.0
            let total = timeWeight + airWeight + safetyWeight
            guard total > 0 else { return (0.33, 0.33, 0.34) }
            return (timeWeight / total, airWeight / total, safetyWeight / total)
        }
    }

    /// Nombre descriptivo
    var displayName: String {
        switch self {
        case .fastest: return "Fastest Route"
        case .shortest: return "Shortest Route"
        case .avoidHighways: return "Avoid Highways"
        case .cleanestAir: return "Cleanest Air"
        case .balanced: return "Balanced (Time + Air)"
        case .healthOptimized: return "Health Optimized"
        case .safest: return "Safest Route"
        case .avoidIncidents: return "Avoid Incidents"
        case .balancedSafety: return "Balanced with Safety"
        case .customWeighted(let timeWeight, let airWeight):
            return "Custom (\(Int(timeWeight * 100))% time, \(Int(airWeight * 100))% air)"
        case .customWeightedSafety(let timeWeight, let airWeight, let safetyWeight):
            return "Custom (\(Int(timeWeight * 100))% time, \(Int(airWeight * 100))% air, \(Int(safetyWeight * 100))% safety)"
        }
    }

    /// Ícono
    var icon: String {
        switch self {
        case .fastest: return "bolt.fill"
        case .shortest: return "arrow.left.and.right"
        case .avoidHighways: return "road.lanes"
        case .cleanestAir: return "leaf.fill"
        case .balanced: return "scale.3d"
        case .healthOptimized: return "heart.circle.fill"
        case .safest: return "shield.fill"
        case .avoidIncidents: return "exclamationmark.shield"
        case .balancedSafety: return "shield.checkered"
        case .customWeighted: return "slider.horizontal.3"
        case .customWeightedSafety: return "slider.horizontal.below.square.fill.and.square"
        }
    }
}
