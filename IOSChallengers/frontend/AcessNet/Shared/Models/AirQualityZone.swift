//
//  AirQualityZone.swift
//  AcessNet
//
//  Modelo para representar zonas circulares de calidad del aire en el mapa
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Air Quality Zone

/// Representa una zona circular en el mapa con datos de calidad del aire
struct AirQualityZone: Identifiable, Equatable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance  // En metros
    let airQuality: AirQualityPoint
    let timestamp: Date

    init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance = 500,
        airQuality: AirQualityPoint
    ) {
        self.id = id
        self.coordinate = coordinate
        self.radius = radius
        self.airQuality = airQuality
        self.timestamp = Date()
    }

    // MARK: - Computed Properties

    /// Nivel de calidad del aire
    var level: AQILevel {
        return airQuality.level
    }

    /// Color principal según el nivel de AQI
    var color: Color {
        switch level {
        case .good: return Color(hex: "#7BC043")
        case .moderate: return Color(hex: "#F9A825")
        case .poor: return Color(hex: "#FF6F00")
        case .unhealthy: return Color(hex: "#E53935")
        case .severe: return Color(hex: "#8E24AA")
        case .hazardous: return Color(hex: "#6A1B4D")
        }
    }

    /// Color de fondo translúcido para la zona
    var fillColor: Color {
        color.opacity(fillOpacity)
    }

    /// Opacidad según el nivel de contaminación (más contaminado = más opaco)
    var fillOpacity: Double {
        switch level {
        case .good: return 0.15
        case .moderate: return 0.20
        case .poor: return 0.25
        case .unhealthy: return 0.30
        case .severe: return 0.35
        case .hazardous: return 0.40
        }
    }

    /// Color del borde
    var strokeColor: Color {
        color.opacity(0.6)
    }

    /// Indica si los datos están obsoletos (más de 10 minutos)
    var isStale: Bool {
        return Date().timeIntervalSince(timestamp) > 600 // 10 minutos
    }

    /// Descripción textual del nivel
    var levelDescription: String {
        return level.rawValue
    }

    /// Icono según el nivel
    var icon: String {
        return level.routingIcon
    }

    // MARK: - Equatable

    static func == (lhs: AirQualityZone, rhs: AirQualityZone) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Grid Configuration

/// Configuración para el grid de zonas
struct AirQualityGridConfig {
    /// Tamaño del grid (N x N puntos)
    let gridSize: Int

    /// Radio de cada zona en metros
    let zoneRadius: CLLocationDistance

    /// Distancia entre centros de zonas en metros
    let spacing: CLLocationDistance

    /// Tiempo de cache en segundos
    let cacheTime: TimeInterval

    /// Radio total del área cubierta desde el centro
    var totalRadius: CLLocationDistance {
        return spacing * Double(gridSize / 2)
    }

    // MARK: - Presets

    /// Configuración por defecto (3x3 grid, 500m radius, 800m spacing)
    /// Optimizado para cobertura de 2km con filtrado por proximidad
    /// - Grid: 3x3 = 9 zonas generadas
    /// - Radio total: 800m × 1.5 = 1.2km (2.4km diámetro)
    /// - Con filtrado 2km: ~7-9 zonas visibles
    static let `default` = AirQualityGridConfig(
        gridSize: 3,
        zoneRadius: 500,
        spacing: 800,
        cacheTime: 120 // 2 minutos
    )

    /// Configuración de alta densidad (9x9 grid, 400m radius, 600m spacing)
    static let highDensity = AirQualityGridConfig(
        gridSize: 9,
        zoneRadius: 400,
        spacing: 600,
        cacheTime: 120
    )

    /// Configuración de baja densidad (5x5 grid, 600m radius, 1000m spacing)
    static let lowDensity = AirQualityGridConfig(
        gridSize: 5,
        zoneRadius: 600,
        spacing: 1000,
        cacheTime: 180 // 3 minutos
    )
}
