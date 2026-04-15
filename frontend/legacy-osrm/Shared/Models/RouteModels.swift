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
    case customWeighted(timeWeight: Double, airQualityWeight: Double)  // Pesos personalizados

    var transportType: MKDirectionsTransportType {
        return .automobile
    }

    var requestsAlternateRoutes: Bool {
        return true
    }

    /// Indica si esta preferencia requiere datos de calidad del aire
    var requiresAirQualityData: Bool {
        switch self {
        case .fastest, .shortest, .avoidHighways:
            return false
        case .cleanestAir, .balanced, .healthOptimized, .customWeighted:
            return true
        }
    }
}

// MARK: - Destination Point

/// Modelo para representar el punto de destino (Punto B)
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
