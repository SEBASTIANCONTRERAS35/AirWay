//
//  TripTelemetry.swift
//  AcessNet
//
//  Telemetría de un viaje en auto: samples de CoreMotion + CoreLocation.
//  Usado para calcular driving_style y alimentar CoreML personal.
//

import Foundation
import CoreLocation

struct TripTelemetry: Codable, Identifiable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date?
    var vehicleProfileId: UUID?

    // Contadores derivados
    var harshAccels: Int = 0       // |a| > 3 m/s² (brusco)
    var harshBrakes: Int = 0       // a < -3 m/s²
    var idleSeconds: Int = 0       // speed < 3 km/h
    var maxSpeedKmh: Double = 0
    var avgSpeedKmh: Double = 0
    var totalDistanceKm: Double = 0
    var elevationGainM: Double = 0
    var stopsCount: Int = 0        // paradas completas

    // Opcional: samples detallados (límite N para no crecer)
    var samples: [TelemetrySample] = []

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        vehicleProfileId: UUID? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.vehicleProfileId = vehicleProfileId
    }

    var durationSeconds: TimeInterval {
        (endedAt ?? Date()).timeIntervalSince(startedAt)
    }

    var durationMinutes: Double { durationSeconds / 60 }

    /// Driving-style multiplier computed from harsh events per minute.
    /// Retorna 0.85 (muy suave) .. 1.30 (muy agresivo).
    var computedStyleMultiplier: Double {
        let duration = max(durationMinutes, 0.5)
        let events = Double(harshAccels + harshBrakes)
        let rate = events / duration   // eventos / min
        // rate 0 → 0.92 (suave)
        // rate 0.3 → 1.10 (normal)
        // rate 0.8+ → 1.30 (agresivo)
        let base = 0.92 + min(rate * 0.5, 0.38)
        return max(0.85, min(base, 1.30))
    }
}

struct TelemetrySample: Codable {
    let t: Date
    let lat: Double
    let lon: Double
    let speedKmh: Double
    let altitude: Double
    let accelMagnitude: Double     // m/s², descontada gravedad
}
