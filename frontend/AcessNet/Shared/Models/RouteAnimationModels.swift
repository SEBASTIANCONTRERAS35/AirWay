//
//  RouteAnimationModels.swift
//  AcessNet
//
//  Modelos para animaciones de ruta espectaculares
//

import Foundation
import CoreLocation

// MARK: - Traveling Particle

/// Representa una partícula que viaja a lo largo de la ruta
struct TravelingParticle: Identifiable, Equatable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var heading: Double  // 0-360 grados
    var progress: Double // 0.0 - 1.0 (posición en la ruta)
    let index: Int  // Para animaciones escalonadas
    let color: ParticleColor

    init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        heading: Double = 0,
        progress: Double = 0,
        index: Int = 0,
        color: ParticleColor = .cyan
    ) {
        self.id = id
        self.coordinate = coordinate
        self.heading = heading
        self.progress = progress
        self.index = index
        self.color = color
    }

    static func == (lhs: TravelingParticle, rhs: TravelingParticle) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Particle Color

enum ParticleColor {
    case cyan
    case blue
    case purple
    case pink
    case rainbow

    var colors: [Color] {
        switch self {
        case .cyan:
            return [.cyan, .cyan.opacity(0.8)]
        case .blue:
            return [.blue, .blue.opacity(0.8)]
        case .purple:
            return [.purple, .purple.opacity(0.8)]
        case .pink:
            return [.pink, .pink.opacity(0.8)]
        case .rainbow:
            return [.cyan, .blue, .purple, .pink]
        }
    }
}

import SwiftUI

// MARK: - Energy Pulse

/// Representa un pulso de energía expansivo
struct EnergyPulse: Identifiable, Equatable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var progress: Double // 0.0 - 1.0 (progreso de la animación)
    var scale: CGFloat  // Factor de escala
    var opacity: Double // Opacidad

    init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        progress: Double = 0,
        scale: CGFloat = 1.0,
        opacity: Double = 1.0
    ) {
        self.id = id
        self.coordinate = coordinate
        self.progress = progress
        self.scale = scale
        self.opacity = opacity
    }

    static func == (lhs: EnergyPulse, rhs: EnergyPulse) -> Bool {
        return lhs.id == rhs.id
    }

    /// Actualiza el pulso basado en el progreso
    mutating func update(progress: Double) {
        self.progress = progress
        // Escala de 1.0 a 3.0
        self.scale = 1.0 + (2.0 * progress)
        // Opacidad de 1.0 a 0.0 con curva easeOut
        self.opacity = max(0, 1.0 - pow(progress, 2))
    }
}

// MARK: - Multicolor Elevated Point

/// Punto elevado con gradiente multicolor
struct MulticolorElevatedPoint: Identifiable, Equatable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let index: Int
    let distanceFromStart: Double

    init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        index: Int = 0,
        distanceFromStart: Double = 0
    ) {
        self.id = id
        self.coordinate = coordinate
        self.index = index
        self.distanceFromStart = distanceFromStart
    }

    static func == (lhs: MulticolorElevatedPoint, rhs: MulticolorElevatedPoint) -> Bool {
        return lhs.id == rhs.id
    }

    /// Colores del gradiente basados en posición
    var gradientColors: [Color] {
        let colors: [Color] = [.cyan, .blue, .purple, .pink]
        let startIndex = index % colors.count
        var result: [Color] = []

        for i in 0..<4 {
            result.append(colors[(startIndex + i) % colors.count])
        }

        return result
    }
}

// MARK: - Route Animation State

/// Estado global de animación de la ruta
struct RouteAnimationState {
    var particles: [TravelingParticle] = []
    var pulses: [EnergyPulse] = []
    var elevatedPoints: [MulticolorElevatedPoint] = []
    var dashPhase: CGFloat = 0
    var hueRotation: Double = 0
    var isAnimating: Bool = false

    mutating func reset() {
        particles.removeAll()
        pulses.removeAll()
        elevatedPoints.removeAll()
        dashPhase = 0
        hueRotation = 0
        isAnimating = false
    }
}
