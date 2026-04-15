//
//  RouteArrowAnnotation.swift
//  AcessNet
//
//  Modelo para flechas direccionales a lo largo de la ruta
//

import Foundation
import CoreLocation

// MARK: - Route Arrow Annotation

struct RouteArrowAnnotation: Identifiable, Equatable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let heading: Double  // Dirección en grados (0-360)
    let distanceFromStart: Double  // Distancia desde el inicio en metros
    let segmentIndex: Int  // Índice del segmento de la ruta

    init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        heading: Double,
        distanceFromStart: Double,
        segmentIndex: Int = 0
    ) {
        self.id = id
        self.coordinate = coordinate
        self.heading = heading
        self.distanceFromStart = distanceFromStart
        self.segmentIndex = segmentIndex
    }

    // MARK: - Equatable

    static func == (lhs: RouteArrowAnnotation, rhs: RouteArrowAnnotation) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    /// Distancia formateada para mostrar
    var distanceFormatted: String {
        if distanceFromStart < 1000 {
            return String(format: "%.0f m", distanceFromStart)
        } else {
            return String(format: "%.1f km", distanceFromStart / 1000)
        }
    }

    /// Heading normalizado (0-360)
    var normalizedHeading: Double {
        var h = heading.truncatingRemainder(dividingBy: 360)
        if h < 0 {
            h += 360
        }
        return h
    }

    /// Dirección cardinal (N, NE, E, SE, S, SW, W, NW)
    var cardinalDirection: String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((normalizedHeading + 22.5) / 45) % 8
        return directions[index]
    }
}
