//
//  RouteModels.swift
//  AcessNet
//
//  Modelos de datos para el sistema de ruteo
//

import Foundation
import MapKit
import CoreLocation

// MARK: - Route Preference

/// Preferencias para el cálculo de rutas
enum RoutePreference {
    case fastest                                          // Ruta más rápida (100% tiempo)
    case shortest                                         // Ruta más corta
    case avoidHighways                                    // Evitar autopistas
    case cleanestAir                                      // Mejor calidad del aire (100% aire)
    case balanced                                         // Balanceado (50% tiempo + 50% aire)
    case healthOptimized                                  // Optimizado para salud (30% tiempo + 70% aire)
    case safest                                          // Ruta más segura (evitar incidentes)
    case avoidIncidents                                   // Evitar áreas con incidentes activos
    case balancedSafety                                   // Balanceado con seguridad (33% cada uno)
    case customWeighted(timeWeight: Double, airQualityWeight: Double)  // Pesos personalizados
    case customWeightedSafety(timeWeight: Double, airQualityWeight: Double, safetyWeight: Double)  // Pesos personalizados con seguridad

    var transportType: MKDirectionsTransportType {
        return .automobile
    }

    var requestsAlternateRoutes: Bool {
        return true
    }

    /// Indica si esta preferencia requiere datos de calidad del aire
    var requiresAirQualityData: Bool {
        switch self {
        case .fastest, .shortest, .avoidHighways, .safest, .avoidIncidents:
            return false
        case .cleanestAir, .balanced, .healthOptimized, .customWeighted, .balancedSafety, .customWeightedSafety:
            return true
        }
    }

    /// Indica si esta preferencia requiere datos de incidentes
    var requiresIncidentData: Bool {
        switch self {
        case .fastest, .shortest, .avoidHighways, .cleanestAir:
            return false
        case .balanced, .healthOptimized, .customWeighted:
            return false
        case .safest, .avoidIncidents, .balancedSafety, .customWeightedSafety:
            return true
        }
    }
}

// MARK: - Destination Point

/// Model to represent the destination point (Point B)
struct DestinationPoint: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String?

    init(coordinate: CLLocationCoordinate2D, title: String = "Destination", subtitle: String? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }

    static func == (lhs: DestinationPoint, rhs: DestinationPoint) -> Bool {
        return lhs.id == rhs.id &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

// MARK: - Location Info

/// Información de una ubicación seleccionada (antes de calcular ruta)
struct LocationInfo: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String?
    let distanceFromUser: String
    let airQuality: AirQualityPoint

    init(
        coordinate: CLLocationCoordinate2D,
        title: String,
        subtitle: String? = nil,
        distanceFromUser: String,
        airQuality: AirQualityPoint
    ) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.distanceFromUser = distanceFromUser
        self.airQuality = airQuality
    }

    /// Formatea las coordenadas para mostrar
    var coordinatesFormatted: String {
        let lat = String(format: "%.4f", coordinate.latitude)
        let lon = String(format: "%.4f", coordinate.longitude)
        return "\(lat), \(lon)"
    }

    // MARK: - Air Quality Computed Properties

    /// Nivel de calidad del aire
    var aqiLevel: AQILevel {
        return airQuality.level
    }

    /// Riesgo para la salud
    var healthRisk: HealthRisk {
        return airQuality.healthRisk
    }

    /// Indica si la calidad del aire es saludable (AQI < 100)
    var isHealthySafety: Bool {
        return airQuality.aqi < 100
    }

    /// Mensaje de salud según el nivel AQI
    var healthMessage: String {
        return aqiLevel.extendedHealthMessage
    }
}

// MARK: - Route Info

/// Información procesada de una ruta
struct RouteInfo: Identifiable {
    let id = UUID()
    let route: MKRoute
    let distanceInKm: Double
    let distanceFormatted: String
    let timeFormatted: String
    let expectedTravelTime: TimeInterval

    init(from route: MKRoute) {
        self.route = route
        self.distanceInKm = route.distance / 1000.0
        self.expectedTravelTime = route.expectedTravelTime

        // Formatear distancia
        if distanceInKm < 1 {
            self.distanceFormatted = String(format: "%.0f m", route.distance)
        } else {
            self.distanceFormatted = String(format: "%.1f km", distanceInKm)
        }

        // Formatear tiempo
        let hours = Int(expectedTravelTime) / 3600
        let minutes = Int(expectedTravelTime) / 60 % 60

        if hours > 0 {
            self.timeFormatted = String(format: "%dh %dm", hours, minutes)
        } else {
            self.timeFormatted = String(format: "%d min", minutes)
        }
    }

    /// Obtiene el polyline de la ruta para dibujar en el mapa
    var polyline: MKPolyline {
        return route.polyline
    }

    /// Obtiene las instrucciones de navegación paso a paso
    var steps: [MKRoute.Step] {
        return route.steps
    }
}
