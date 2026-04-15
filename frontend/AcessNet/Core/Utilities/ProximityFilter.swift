//
//  ProximityFilter.swift
//  AcessNet
//
//  Utilidad para filtrar elementos del mapa por proximidad al usuario
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Proximity Filter

/// Filtra elementos del mapa basándose en la distancia desde la ubicación del usuario
class ProximityFilter {

    // MARK: - Constants

    /// Radio máximo de visibilidad por defecto en metros (2km)
    static let defaultMaxRadius: CLLocationDistance = 2_000

    // MARK: - Public Methods

    /// Filtra zonas de calidad del aire por distancia desde ubicación del usuario
    /// - Parameters:
    ///   - zones: Array de zonas a filtrar
    ///   - userLocation: Ubicación del usuario
    ///   - maxRadius: Radio máximo en metros (default: 2km)
    /// - Returns: Zonas dentro del radio especificado
    static func filterZones(
        _ zones: [AirQualityZone],
        from userLocation: CLLocationCoordinate2D,
        maxRadius: CLLocationDistance = defaultMaxRadius
    ) -> [AirQualityZone] {
        return zones.filter { zone in
            let distance = calculateDistance(
                from: userLocation,
                to: zone.coordinate
            )
            return distance <= maxRadius
        }
    }

    /// Filtra annotations de alertas por distancia desde ubicación del usuario
    /// - Parameters:
    ///   - annotations: Array de annotations a filtrar
    ///   - userLocation: Ubicación del usuario
    ///   - maxRadius: Radio máximo en metros (default: 2km)
    /// - Returns: Annotations dentro del radio especificado
    static func filterAnnotations(
        _ annotations: [CustomAnnotation],
        from userLocation: CLLocationCoordinate2D,
        maxRadius: CLLocationDistance = defaultMaxRadius
    ) -> [CustomAnnotation] {
        return annotations.filter { annotation in
            let distance = calculateDistance(
                from: userLocation,
                to: annotation.coordinate
            )
            return distance <= maxRadius
        }
    }

    /// Filtra flechas de ruta por distancia desde ubicación del usuario
    /// - Parameters:
    ///   - arrows: Array de flechas a filtrar
    ///   - userLocation: Ubicación del usuario
    ///   - maxRadius: Radio máximo en metros (default: 2km)
    /// - Returns: Flechas dentro del radio especificado
    static func filterRouteArrows(
        _ arrows: [RouteArrowAnnotation],
        from userLocation: CLLocationCoordinate2D,
        maxRadius: CLLocationDistance = defaultMaxRadius
    ) -> [RouteArrowAnnotation] {
        return arrows.filter { arrow in
            let distance = calculateDistance(
                from: userLocation,
                to: arrow.coordinate
            )
            return distance <= maxRadius
        }
    }

    /// Calcula la distancia entre dos coordenadas usando fórmula Haversine
    /// - Parameters:
    ///   - from: Coordenada de origen
    ///   - to: Coordenada de destino
    /// - Returns: Distancia en metros
    static func calculateDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        let fromLocation = CLLocation(
            latitude: from.latitude,
            longitude: from.longitude
        )
        let toLocation = CLLocation(
            latitude: to.latitude,
            longitude: to.longitude
        )

        return fromLocation.distance(from: toLocation)
    }

    /// Verifica si una coordenada está dentro del radio de visibilidad
    /// - Parameters:
    ///   - coordinate: Coordenada a verificar
    ///   - userLocation: Ubicación del usuario
    ///   - maxRadius: Radio máximo en metros (default: 2km)
    /// - Returns: true si está dentro del radio
    static func isWithinRadius(
        _ coordinate: CLLocationCoordinate2D,
        from userLocation: CLLocationCoordinate2D,
        maxRadius: CLLocationDistance = defaultMaxRadius
    ) -> Bool {
        let distance = calculateDistance(from: userLocation, to: coordinate)
        return distance <= maxRadius
    }
}

// MARK: - Statistics Extension

extension ProximityFilter {
    /// Estadísticas de filtrado
    struct FilterStatistics {
        let totalElements: Int
        let visibleElements: Int
        let hiddenElements: Int
        let filterRadius: CLLocationDistance

        var reductionPercentage: Double {
            guard totalElements > 0 else { return 0 }
            return Double(hiddenElements) / Double(totalElements) * 100.0
        }
    }

    /// Calcula estadísticas de filtrado para debugging
    static func calculateStatistics<T>(
        total: [T],
        visible: [T],
        radius: CLLocationDistance
    ) -> FilterStatistics {
        return FilterStatistics(
            totalElements: total.count,
            visibleElements: visible.count,
            hiddenElements: total.count - visible.count,
            filterRadius: radius
        )
    }

    /// Log de estadísticas de filtrado
    static func logFilterStatistics(_ stats: FilterStatistics, elementType: String) {
        print("""
        📍 Proximity Filter - \(elementType):
           - Total: \(stats.totalElements)
           - Visible: \(stats.visibleElements)
           - Hidden: \(stats.hiddenElements)
           - Reduction: \(String(format: "%.1f", stats.reductionPercentage))%
           - Radius: \(Int(stats.filterRadius / 1000))km
        """)
    }
}
