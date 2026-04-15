//
//  IncidentAnalysis.swift
//  AcessNet
//
//  Modelo para análisis de incidentes a lo largo de las rutas
//

import Foundation
import CoreLocation

// MARK: - Incident Analysis Model

/// Análisis de incidentes encontrados a lo largo de una ruta
struct IncidentRouteAnalysis {
    let totalIncidents: Int
    let criticalIncidents: Int
    let nearbyIncidents: [(incident: CustomAnnotation, distance: Double)]
    let safetyScore: Double  // 0-100 (100 = más seguro)
    let riskLevel: RiskLevel

    // Conteo por tipo de incidente
    let trafficCount: Int
    let hazardCount: Int
    let accidentCount: Int
    let pedestrianCount: Int
    let policeCount: Int
    let roadWorkCount: Int

    /// Score de seguridad promedio de la ruta
    var averageSafetyScore: Double {
        return safetyScore
    }

    /// Descripción del nivel de riesgo
    var riskDescription: String {
        switch riskLevel {
        case .veryLow: return "Very Safe Route"
        case .low: return "Safe Route"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        case .veryHigh: return "Very High Risk"
        }
    }

    /// Icono representativo del riesgo
    var riskIcon: String {
        switch riskLevel {
        case .veryLow: return "checkmark.shield.fill"
        case .low: return "checkmark.shield"
        case .moderate: return "exclamationmark.shield"
        case .high: return "exclamationmark.triangle.fill"
        case .veryHigh: return "xmark.shield.fill"
        }
    }

    /// Color del nivel de riesgo
    var riskColor: String {
        switch riskLevel {
        case .veryLow: return "green"
        case .low: return "mint"
        case .moderate: return "yellow"
        case .high: return "orange"
        case .veryHigh: return "red"
        }
    }

    /// Resumen de incidentes para mostrar
    var incidentSummary: String {
        if totalIncidents == 0 {
            return "Clear route - no incidents"
        }

        var parts: [String] = []

        if accidentCount > 0 {
            parts.append("\(accidentCount) accident\(accidentCount > 1 ? "s" : "")")
        }
        if trafficCount > 0 {
            parts.append("\(trafficCount) traffic")
        }
        if hazardCount > 0 {
            parts.append("\(hazardCount) hazard\(hazardCount > 1 ? "s" : "")")
        }
        if roadWorkCount > 0 {
            parts.append("\(roadWorkCount) road work")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Risk Level

/// Nivel de riesgo basado en incidentes
enum RiskLevel: Int, CaseIterable {
    case veryLow = 0    // 0-20 safety score
    case low = 1        // 21-40
    case moderate = 2   // 41-60
    case high = 3       // 61-80
    case veryHigh = 4   // 81-100

    /// Determina el nivel de riesgo basado en el safety score
    static func from(safetyScore: Double) -> RiskLevel {
        switch safetyScore {
        case 80...100: return .veryLow
        case 60..<80: return .low
        case 40..<60: return .moderate
        case 20..<40: return .high
        default: return .veryHigh
        }
    }
}

// MARK: - Incident Impact Calculator

/// Calculador del impacto de incidentes en las rutas
struct IncidentImpactCalculator {

    // Radios de impacto en metros
    static let immediateImpactRadius: Double = 100   // Impacto inmediato
    static let nearbyImpactRadius: Double = 500      // Impacto cercano
    static let areaImpactRadius: Double = 1000       // Impacto de área

    /// Calcula el impacto de un incidente basado en tipo y distancia
    static func calculateImpact(type: AlertType, distance: Double) -> Double {
        // Factor base según tipo de incidente
        let baseSeverity: Double
        switch type {
        case .accident:
            baseSeverity = 1.0    // Máximo impacto
        case .roadWork:
            baseSeverity = 0.8
        case .traffic:
            baseSeverity = 0.7
        case .hazard:
            baseSeverity = 0.6
        case .police:
            baseSeverity = 0.4
        case .pedestrian:
            baseSeverity = 0.3
        }

        // Factor de distancia (decae con la distancia)
        let distanceFactor: Double
        if distance <= immediateImpactRadius {
            distanceFactor = 1.0  // Impacto total
        } else if distance <= nearbyImpactRadius {
            // Decaimiento lineal de 1.0 a 0.5
            let ratio = (distance - immediateImpactRadius) / (nearbyImpactRadius - immediateImpactRadius)
            distanceFactor = 1.0 - (ratio * 0.5)
        } else if distance <= areaImpactRadius {
            // Decaimiento lineal de 0.5 a 0.1
            let ratio = (distance - nearbyImpactRadius) / (areaImpactRadius - nearbyImpactRadius)
            distanceFactor = 0.5 - (ratio * 0.4)
        } else {
            // Más allá del área de impacto
            distanceFactor = 0.1
        }

        // Factor de tiempo (incidentes más recientes tienen más impacto)
        // Por ahora usamos 1.0, pero podríamos considerar timestamp
        let timeFactor = 1.0

        return baseSeverity * distanceFactor * timeFactor
    }

    /// Calcula el safety score de una ruta basado en todos los incidentes
    static func calculateRouteSafetyScore(incidents: [(incident: CustomAnnotation, distance: Double)]) -> Double {
        guard !incidents.isEmpty else { return 100.0 }  // Sin incidentes = 100% seguro

        // Calcular impacto acumulado
        var totalImpact: Double = 0
        var maxImpact: Double = 0

        for (incident, distance) in incidents {
            let impact = calculateImpact(type: incident.alertType, distance: distance)
            totalImpact += impact
            maxImpact = max(maxImpact, impact)
        }

        // Normalizar el impacto total
        // Usamos una combinación del impacto máximo y el promedio
        let avgImpact = totalImpact / Double(incidents.count)
        let combinedImpact = (maxImpact * 0.6) + (avgImpact * 0.4)

        // Convertir a safety score (0-100)
        // Más impacto = menor safety score
        let safetyScore = max(0, min(100, 100 * (1 - combinedImpact)))

        return safetyScore
    }

    /// Cuenta incidentes críticos (accidentes y road work cercanos)
    static func countCriticalIncidents(incidents: [(incident: CustomAnnotation, distance: Double)]) -> Int {
        return incidents.filter { (incident, distance) in
            let isCriticalType = incident.alertType == .accident || incident.alertType == .roadWork
            let isNearby = distance <= nearbyImpactRadius
            return isCriticalType && isNearby
        }.count
    }
}