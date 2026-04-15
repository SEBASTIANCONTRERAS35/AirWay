//
//  CLLocationCoordinate2D+Extensions.swift
//  AcessNet
//
//  Extensiones para cálculos geoespaciales
//

import Foundation
import CoreLocation
import MapKit

extension CLLocationCoordinate2D {

    // MARK: - Distance Calculations

    /// Calcula la distancia en metros entre dos coordenadas
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }

    // MARK: - Bearing Calculations

    /// Calcula el bearing (dirección) desde esta coordenada hacia otra
    /// - Returns: Ángulo en grados (0-360), donde 0 = Norte, 90 = Este, etc.
    func bearing(to coordinate: CLLocationCoordinate2D) -> Double {
        let lat1 = self.latitude.degreesToRadians
        let lon1 = self.longitude.degreesToRadians
        let lat2 = coordinate.latitude.degreesToRadians
        let lon2 = coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let radiansBearing = atan2(y, x)
        var degreesBearing = radiansBearing.radiansToDegrees

        // Normalizar a 0-360
        if degreesBearing < 0 {
            degreesBearing += 360
        }

        return degreesBearing
    }

    // MARK: - Interpolation

    /// Interpola entre dos coordenadas
    /// - Parameter to: Coordenada destino
    /// - Parameter fraction: Fracción del camino (0.0 = inicio, 1.0 = destino, 0.5 = punto medio)
    /// - Returns: Coordenada interpolada
    func interpolate(to coordinate: CLLocationCoordinate2D, fraction: Double) -> CLLocationCoordinate2D {
        let lat = self.latitude + (coordinate.latitude - self.latitude) * fraction
        let lon = self.longitude + (coordinate.longitude - self.longitude) * fraction
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // MARK: - Point at Distance and Bearing

    /// Calcula un nuevo punto a una distancia y bearing específicos
    /// - Parameter distance: Distancia en metros
    /// - Parameter bearing: Dirección en grados (0-360)
    /// - Returns: Nueva coordenada
    func coordinate(atDistance distance: CLLocationDistance, bearing: Double) -> CLLocationCoordinate2D {
        let earthRadius: Double = 6371000 // metros

        let bearingRad = bearing.degreesToRadians
        let lat1 = self.latitude.degreesToRadians
        let lon1 = self.longitude.degreesToRadians

        let lat2 = asin(
            sin(lat1) * cos(distance / earthRadius) +
            cos(lat1) * sin(distance / earthRadius) * cos(bearingRad)
        )

        let lon2 = lon1 + atan2(
            sin(bearingRad) * sin(distance / earthRadius) * cos(lat1),
            cos(distance / earthRadius) - sin(lat1) * sin(lat2)
        )

        return CLLocationCoordinate2D(
            latitude: lat2.radiansToDegrees,
            longitude: lon2.radiansToDegrees
        )
    }

    // MARK: - Validation

    /// Verifica si la coordenada es válida
    var isValid: Bool {
        return latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180
    }
}

// MARK: - MKMapPoint Extensions

extension MKMapPoint {

    /// Convierte a CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        return self.coordinate
    }

    /// Calcula distancia a otro MKMapPoint
    func distance(to point: MKMapPoint) -> CLLocationDistance {
        let dx = self.x - point.x
        let dy = self.y - point.y
        let distance = sqrt(dx * dx + dy * dy)

        // Convertir distancia de map points a metros (aproximación)
        return distance * 0.0254 // factor de conversión aproximado
    }
}

// MARK: - Double Extensions (Helper)

extension Double {

    /// Convierte grados a radianes
    var degreesToRadians: Double {
        return self * .pi / 180
    }

    /// Convierte radianes a grados
    var radiansToDegrees: Double {
        return self * 180 / .pi
    }

    /// Normaliza un ángulo a 0-360 grados
    var normalizedDegrees: Double {
        var angle = self.truncatingRemainder(dividingBy: 360)
        if angle < 0 {
            angle += 360
        }
        return angle
    }
}

// MARK: - MKPolyline Extensions

extension MKPolyline {

    /// Obtiene array de coordenadas del polyline
    func coordinates() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }

    /// Calcula la longitud total del polyline en metros
    func totalLength() -> CLLocationDistance {
        let coords = coordinates()
        var totalDistance: CLLocationDistance = 0

        for i in 0..<coords.count - 1 {
            totalDistance += coords[i].distance(to: coords[i + 1])
        }

        return totalDistance
    }

    /// Obtiene coordenada en una distancia específica desde el inicio
    func coordinate(atDistance distance: CLLocationDistance) -> CLLocationCoordinate2D? {
        let coords = coordinates()
        var accumulatedDistance: CLLocationDistance = 0

        for i in 0..<coords.count - 1 {
            let segmentDistance = coords[i].distance(to: coords[i + 1])

            if accumulatedDistance + segmentDistance >= distance {
                // La distancia objetivo está en este segmento
                let remainingDistance = distance - accumulatedDistance
                let fraction = remainingDistance / segmentDistance
                return coords[i].interpolate(to: coords[i + 1], fraction: fraction)
            }

            accumulatedDistance += segmentDistance
        }

        // Si la distancia es mayor que la longitud total, retornar el último punto
        return coords.last
    }
}
