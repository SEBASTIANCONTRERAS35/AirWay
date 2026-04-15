//
//  RoutePathHelper.swift
//  AcessNet
//
//  Helper para calcular puntos a lo largo de un polyline de ruta
//

import Foundation
import MapKit
import CoreLocation

// MARK: - MKPolyline Path Extensions

extension MKPolyline {

    /// Obtiene un punto específico en el polyline basado en una fracción (0.0 = inicio, 1.0 = final)
    /// - Parameter fraction: Valor entre 0.0 y 1.0 representando la posición en el path
    /// - Returns: Coordenada en esa posición del path, o nil si el polyline está vacío
    func pointAt(fraction: Double) -> CLLocationCoordinate2D? {
        guard fraction >= 0 && fraction <= 1 else { return nil }

        let coordinates = self.coordinates()
        guard coordinates.count >= 2 else { return nil }

        // Si fracción es 0 o 1, retornar extremos directamente
        if fraction == 0 { return coordinates.first }
        if fraction == 1 { return coordinates.last }

        // Calcular distancia total
        let totalDistance = self.totalLength()
        let targetDistance = totalDistance * fraction

        // Encontrar el segmento que contiene el punto objetivo
        var accumulatedDistance: CLLocationDistance = 0

        for i in 0..<coordinates.count - 1 {
            let coord1 = coordinates[i]
            let coord2 = coordinates[i + 1]
            let segmentDistance = coord1.distance(to: coord2)

            if accumulatedDistance + segmentDistance >= targetDistance {
                // El punto está en este segmento
                let distanceIntoSegment = targetDistance - accumulatedDistance
                let segmentFraction = distanceIntoSegment / segmentDistance
                return coord1.interpolate(to: coord2, fraction: segmentFraction)
            }

            accumulatedDistance += segmentDistance
        }

        // Fallback: retornar último punto
        return coordinates.last
    }

    /// Obtiene el heading (dirección) en un punto específico del polyline
    /// - Parameter fraction: Valor entre 0.0 y 1.0 representando la posición en el path
    /// - Returns: Ángulo en grados (0-360) o nil si no se puede calcular
    func headingAt(fraction: Double) -> Double? {
        guard fraction >= 0 && fraction <= 1 else { return nil }

        let coordinates = self.coordinates()
        guard coordinates.count >= 2 else { return nil }

        let totalDistance = self.totalLength()
        let targetDistance = totalDistance * fraction
        var accumulatedDistance: CLLocationDistance = 0

        for i in 0..<coordinates.count - 1 {
            let coord1 = coordinates[i]
            let coord2 = coordinates[i + 1]
            let segmentDistance = coord1.distance(to: coord2)

            if accumulatedDistance + segmentDistance >= targetDistance {
                // El heading es la dirección de este segmento
                return coord1.bearing(to: coord2)
            }

            accumulatedDistance += segmentDistance
        }

        // Fallback: heading del último segmento
        if coordinates.count >= 2 {
            return coordinates[coordinates.count - 2].bearing(to: coordinates[coordinates.count - 1])
        }

        return nil
    }

    /// Obtiene múltiples puntos equidistantes a lo largo del polyline
    /// - Parameter count: Número de puntos a obtener
    /// - Returns: Array de coordenadas espaciadas uniformemente
    func uniformPoints(count: Int) -> [CLLocationCoordinate2D] {
        guard count > 0 else { return [] }
        guard count > 1 else { return coordinates().first.map { [$0] } ?? [] }

        var points: [CLLocationCoordinate2D] = []

        for i in 0..<count {
            let fraction = Double(i) / Double(count - 1)
            if let point = pointAt(fraction: fraction) {
                points.append(point)
            }
        }

        return points
    }

    /// Calcula la distancia acumulada hasta una coordenada específica del polyline
    /// - Parameter targetIndex: Índice de la coordenada objetivo
    /// - Returns: Distancia acumulada en metros
    func distanceToIndex(_ targetIndex: Int) -> CLLocationDistance {
        let coordinates = self.coordinates()
        guard targetIndex > 0 && targetIndex < coordinates.count else { return 0 }

        var distance: CLLocationDistance = 0
        for i in 0..<targetIndex {
            distance += coordinates[i].distance(to: coordinates[i + 1])
        }

        return distance
    }
}

// MARK: - Route Path Info

struct RoutePathInfo {
    let coordinate: CLLocationCoordinate2D
    let heading: Double
    let fraction: Double  // 0.0 - 1.0
    let distanceFromStart: CLLocationDistance
}

extension MKPolyline {

    /// Obtiene información completa de un punto en el path
    /// - Parameter fraction: Posición en el path (0.0 - 1.0)
    /// - Returns: Información del punto incluyendo coordenada, heading y distancia
    func pathInfo(at fraction: Double) -> RoutePathInfo? {
        guard let coordinate = pointAt(fraction: fraction),
              let heading = headingAt(fraction: fraction) else {
            return nil
        }

        let totalDistance = self.totalLength()
        let distanceFromStart = totalDistance * fraction

        return RoutePathInfo(
            coordinate: coordinate,
            heading: heading,
            fraction: fraction,
            distanceFromStart: distanceFromStart
        )
    }
}
