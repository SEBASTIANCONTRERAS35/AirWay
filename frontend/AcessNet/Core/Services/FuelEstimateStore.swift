//
//  FuelEstimateStore.swift
//  AcessNet
//
//  Cache en memoria de FuelEstimate por routeID.
//  Evita modificar la firma de ScoredRoute y permite actualizar estimates async
//  después de que las rutas ya se pintaron en el mapa.
//

import Foundation
import Combine
import os

@MainActor
final class FuelEstimateStore: ObservableObject {
    static let shared = FuelEstimateStore()

    @Published private(set) var estimatesByRoute: [UUID: FuelEstimate] = [:]

    /// Guarda un estimate para una ruta específica.
    func set(_ estimate: FuelEstimate, for routeId: UUID) {
        estimatesByRoute[routeId] = estimate
    }

    /// Elimina el estimate (p. ej. al recalcular rutas).
    func remove(routeId: UUID) {
        estimatesByRoute.removeValue(forKey: routeId)
    }

    func get(for routeId: UUID) -> FuelEstimate? {
        estimatesByRoute[routeId]
    }

    /// Limpia todo el cache (al cambiar destino).
    func clearAll() {
        estimatesByRoute.removeAll()
    }

    /// Carga en paralelo estimaciones para un conjunto de rutas.
    /// No falla si alguna ruta individual falla.
    func loadEstimates(
        for routes: [ScoredRoute],
        vehicle: VehicleProfile,
        fuelPriceOverride: Double? = nil
    ) async {
        AirWayLogger.fuel.info(
            "FuelEstimateStore.loadEstimates for \(routes.count, privacy: .public) routes, vehicle=\(vehicle.fullDisplayName, privacy: .public)"
        )
        let startT = Date()
        var successes = 0
        var failures = 0

        await withTaskGroup(of: (UUID, FuelEstimate?).self) { group in
            for route in routes {
                group.addTask {
                    // Encode polyline de MKRoute a String (precision 5)
                    let encodedPoly = MKPolylineEncoder.encode(route.routeInfo.polyline)
                    do {
                        let est = try await FuelAPIClient.shared.estimate(
                            polyline: encodedPoly,
                            vehicle: vehicle,
                            durationMin: route.routeInfo.expectedTravelTime / 60,
                            passengers: 1,
                            fuelPriceOverride: fuelPriceOverride
                        )
                        return (route.id, est)
                    } catch {
                        AirWayLogger.fuel.warning(
                            "loadEstimates failed for route \(route.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
                        )
                        return (route.id, nil)
                    }
                }
            }
            for await (id, est) in group {
                if let est = est {
                    set(est, for: id)
                    successes += 1
                } else {
                    failures += 1
                }
            }
        }

        let elapsedMs = Date().timeIntervalSince(startT) * 1000
        AirWayLogger.fuel.info(
            "FuelEstimateStore.loadEstimates done: \(successes, privacy: .public) ok, \(failures, privacy: .public) fail in \(String(format: "%.0f", elapsedMs), privacy: .public)ms"
        )
    }
}

// MARK: - Convenience extension

extension ScoredRoute {
    /// Acceso conveniente al FuelEstimate cacheado.
    @MainActor
    var fuelEstimate: FuelEstimate? {
        FuelEstimateStore.shared.get(for: id)
    }

    /// Ahorros vs la ruta "más cara" del batch actual.
    /// Se calcula fuera (en FuelComparisonHelper).
    @MainActor
    func fuelSavings(versus maxCost: Double) -> Double? {
        guard let cost = fuelEstimate?.pesosCost, maxCost > cost else { return nil }
        return maxCost - cost
    }
}
