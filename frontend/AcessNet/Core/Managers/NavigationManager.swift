//
//  NavigationManager.swift
//  AcessNet
//
//  Gestor principal del sistema de navegación turn-by-turn
//

import Foundation
import CoreLocation
import MapKit
import Combine
import SwiftUI

// MARK: - Navigation Manager

class NavigationManager: ObservableObject {

    // MARK: - Published Properties

    /// Estado de navegación activa
    @Published private(set) var isNavigating: Bool = false

    /// Ruta activa en navegación
    @Published private(set) var activeRoute: ScoredRoute?

    /// Paso actual de navegación
    @Published private(set) var currentStep: NavigationStep?

    /// Siguiente paso de navegación
    @Published private(set) var nextStep: NavigationStep?

    /// Zona de calidad del aire actual
    @Published private(set) var currentZone: AirQualityZone?

    /// Progreso a lo largo de la ruta (0.0 - 1.0)
    @Published private(set) var progressAlongRoute: Double = 0.0

    /// Distancia restante total en metros
    @Published private(set) var distanceRemaining: Double = 0.0

    /// Tiempo restante estimado en segundos
    @Published private(set) var etaRemaining: TimeInterval = 0.0

    /// Distancia recorrida en metros
    @Published private(set) var distanceTraveled: Double = 0.0

    /// Alertas activas
    @Published private(set) var activeAlert: NavigationAlert?

    /// Estado completo de navegación
    @Published private(set) var state: NavigationState = .empty

    // MARK: - Private Properties

    /// Todos los pasos de navegación
    private var navigationSteps: [NavigationStep] = []

    /// Índice del paso actual
    private var currentStepIndex: Int = 0

    /// Última ubicación procesada
    private var lastProcessedLocation: CLLocationCoordinate2D?

    /// Configuración de navegación
    private let config = NavigationConfiguration.default

    /// Timer para actualizar ETA
    private var etaUpdateTimer: Timer?

    /// Velocidad promedio reciente (m/s)
    private var averageSpeed: Double = 8.33 // ~30 km/h por defecto

    /// Historial de velocidades para calcular promedio
    private var speedHistory: [Double] = []

    /// Máximo de elementos en historial de velocidad
    private let maxSpeedHistorySize = 10

    /// Última actualización de ETA
    private var lastETAUpdate: Date?

    /// Air Quality Grid Manager (inyectado)
    private weak var airQualityGridManager: AirQualityGridManager?

    /// Distancia al próximo paso
    @Published private(set) var distanceToNextManeuver: Double = 0.0

    // MARK: - Initialization

    init(airQualityGridManager: AirQualityGridManager? = nil) {
        self.airQualityGridManager = airQualityGridManager
    }

    // MARK: - Public Methods

    /// Inicia la navegación con una ruta
    func startNavigation(route: ScoredRoute, gridManager: AirQualityGridManager) {
        print("🧭 Iniciando navegación...")

        self.activeRoute = route
        self.airQualityGridManager = gridManager
        self.isNavigating = true

        // Generar pasos de navegación desde MKRoute.steps
        generateNavigationSteps(from: route)

        // Resetear estado
        progressAlongRoute = 0.0
        distanceTraveled = 0.0
        currentStepIndex = 0
        lastProcessedLocation = nil
        speedHistory = []
        activeAlert = nil

        // Calcular distancia total
        distanceRemaining = route.routeInfo.route.distance
        etaRemaining = route.routeInfo.expectedTravelTime

        // Configurar primer paso
        if !navigationSteps.isEmpty {
            currentStep = navigationSteps[0]
            if navigationSteps.count > 1 {
                nextStep = navigationSteps[1]
            }
        }

        // Iniciar timer de ETA
        startETATimer()

        // Actualizar estado
        updateNavigationState()

        print("✅ Navegación iniciada: \(navigationSteps.count) pasos")
    }

    /// Detiene la navegación
    func stopNavigation() {
        print("🛑 Deteniendo navegación...")

        isNavigating = false
        activeRoute = nil
        currentStep = nil
        nextStep = nil
        currentZone = nil
        navigationSteps = []
        currentStepIndex = 0
        progressAlongRoute = 0.0
        distanceRemaining = 0.0
        etaRemaining = 0.0
        distanceTraveled = 0.0
        activeAlert = nil
        lastProcessedLocation = nil

        // Detener timer
        stopETATimer()

        // Actualizar estado
        updateNavigationState()
    }

    /// Actualiza la ubicación del usuario durante navegación
    func updateUserLocation(_ location: CLLocationCoordinate2D, speed: CLLocationSpeed) {
        guard isNavigating, let route = activeRoute else { return }

        // 1. Actualizar velocidad promedio
        updateAverageSpeed(speed)

        // 2. Calcular progreso en la ruta
        let (progress, distanceCovered) = calculateProgress(userLocation: location, route: route)
        progressAlongRoute = progress
        distanceTraveled = distanceCovered

        // 3. Calcular distancia restante
        let totalDistance = route.routeInfo.route.distance
        distanceRemaining = max(0, totalDistance - distanceCovered)

        // 4. Actualizar ETA si es necesario
        updateETAIfNeeded()

        // 5. Encontrar zona actual de calidad del aire
        updateCurrentZone(location: location)

        // 6. Actualizar paso actual de navegación
        updateCurrentNavigationStep(location: location)

        // 7. Verificar si está off-route
        checkIfOffRoute(location: location)

        // 8. Verificar alertas
        checkNavigationAlerts(location: location)

        // 9. Actualizar estado completo
        updateNavigationState()

        // Guardar última ubicación procesada
        lastProcessedLocation = location
    }

    /// Establece el Air Quality Grid Manager
    func setAirQualityGridManager(_ manager: AirQualityGridManager) {
        self.airQualityGridManager = manager
    }

    // MARK: - Private Methods

    /// Genera pasos de navegación desde MKRoute
    private func generateNavigationSteps(from route: ScoredRoute) {
        let mkRoute = route.routeInfo.route
        let steps = mkRoute.steps

        navigationSteps = steps.enumerated().map { index, mkStep in
            NavigationStep(from: mkStep, stepIndex: index)
        }

        print("📋 Generados \(navigationSteps.count) pasos de navegación")
    }

    /// Calcula el progreso del usuario en la ruta
    private func calculateProgress(
        userLocation: CLLocationCoordinate2D,
        route: ScoredRoute
    ) -> (progress: Double, distanceCovered: Double) {
        let polyline = route.routeInfo.route.polyline
        let coords = polyline.coordinates()

        guard coords.count >= 2 else {
            return (0.0, 0.0)
        }

        // Encontrar punto más cercano en polyline
        var minDistance = Double.infinity
        var closestIndex = 0

        for (index, coord) in coords.enumerated() {
            let dist = userLocation.distance(to: coord)
            if dist < minDistance {
                minDistance = dist
                closestIndex = index
            }
        }

        // Calcular distancia recorrida hasta ese punto
        var distanceCovered: Double = 0
        for i in 0..<closestIndex {
            guard i + 1 < coords.count else { break }
            distanceCovered += coords[i].distance(to: coords[i + 1])
        }

        // Si el punto más cercano no es el primero, agregar fracción del último segmento
        if closestIndex > 0 && closestIndex < coords.count {
            let prevCoord = coords[max(0, closestIndex - 1)]
            let closestCoord = coords[closestIndex]
            let segmentLength = prevCoord.distance(to: closestCoord)

            if segmentLength > 0 {
                let userToClosest = userLocation.distance(to: closestCoord)
                let fraction = 1.0 - (userToClosest / segmentLength)
                distanceCovered += segmentLength * max(0, min(1, fraction))
            }
        }

        let totalDistance = polyline.totalLength()
        let progress = totalDistance > 0 ? min(1.0, distanceCovered / totalDistance) : 0.0

        return (progress, distanceCovered)
    }

    /// Actualiza la zona actual de calidad del aire
    private func updateCurrentZone(location: CLLocationCoordinate2D) {
        guard let gridManager = airQualityGridManager else { return }

        // Buscar zona más cercana
        currentZone = gridManager.zones.min { zone1, zone2 in
            let dist1 = location.distance(to: zone1.coordinate)
            let dist2 = location.distance(to: zone2.coordinate)
            return dist1 < dist2
        }
    }

    /// Actualiza el paso actual de navegación
    private func updateCurrentNavigationStep(location: CLLocationCoordinate2D) {
        guard !navigationSteps.isEmpty else { return }

        // Encontrar paso más cercano adelante del usuario
        var bestStepIndex = currentStepIndex

        for (index, step) in navigationSteps.enumerated() {
            guard index >= currentStepIndex else { continue }

            let distanceToStep = location.distance(to: step.coordinate)

            // Si ya pasamos este paso (distancia muy pequeña), avanzar
            if distanceToStep < config.stepCompletionThreshold {
                bestStepIndex = min(index + 1, navigationSteps.count - 1)
            }
        }

        // Actualizar índice y pasos
        if bestStepIndex != currentStepIndex {
            currentStepIndex = bestStepIndex
            print("➡️ Avanzando a paso \(currentStepIndex + 1)/\(navigationSteps.count)")
        }

        // Actualizar current y next step
        if currentStepIndex < navigationSteps.count {
            currentStep = navigationSteps[currentStepIndex]

            // Calcular distancia al siguiente paso
            distanceToNextManeuver = location.distance(to: currentStep!.coordinate)

            // Next step
            if currentStepIndex + 1 < navigationSteps.count {
                nextStep = navigationSteps[currentStepIndex + 1]
            } else {
                nextStep = nil
            }
        }
    }

    /// Verifica si el usuario está fuera de ruta
    private func checkIfOffRoute(location: CLLocationCoordinate2D) {
        guard let route = activeRoute else { return }

        let polyline = route.routeInfo.route.polyline
        let coords = polyline.coordinates()

        // Encontrar distancia mínima a la ruta
        var minDistance = Double.infinity
        for coord in coords {
            let dist = location.distance(to: coord)
            minDistance = min(minDistance, dist)
        }

        // Si está muy lejos de la ruta
        if minDistance > config.offRouteThreshold {
            if activeAlert != .offRoute {
                activeAlert = .offRoute
                print("⚠️ Usuario fuera de ruta (distancia: \(Int(minDistance))m)")
            }
        } else {
            // Si vuelve a la ruta, limpiar alerta
            if activeAlert == .offRoute {
                activeAlert = nil
                print("✅ Usuario de vuelta en ruta")
            }
        }
    }

    /// Verifica alertas de navegación
    private func checkNavigationAlerts(location: CLLocationCoordinate2D) {
        // Verificar si está cerca del destino
        if let lastStep = navigationSteps.last {
            let distanceToDestination = location.distance(to: lastStep.coordinate)
            if distanceToDestination < config.stepCompletionThreshold {
                activeAlert = .arrived
                print("🎉 Usuario llegó al destino!")
                return
            }
        }

        // Verificar maniobra próxima
        if let step = currentStep {
            let distanceToStep = location.distance(to: step.coordinate)
            if distanceToStep < config.stepAnnouncementDistance && distanceToStep > config.stepCompletionThreshold {
                activeAlert = .approaching(step: step.maneuverType.rawValue, distance: distanceToStep)
            }
        }

        // Verificar calidad del aire pobre
        if let zone = currentZone, zone.airQuality.aqi > 150 {
            activeAlert = .poorAirQuality(aqi: Int(zone.airQuality.aqi))
        }
    }

    /// Actualiza velocidad promedio
    private func updateAverageSpeed(_ speed: CLLocationSpeed) {
        guard speed > 0 else { return }

        speedHistory.append(speed)

        // Mantener solo los últimos N valores
        if speedHistory.count > maxSpeedHistorySize {
            speedHistory.removeFirst()
        }

        // Calcular promedio
        let sum = speedHistory.reduce(0, +)
        averageSpeed = sum / Double(speedHistory.count)
    }

    /// Actualiza ETA si es necesario
    private func updateETAIfNeeded() {
        // Verificar si es momento de actualizar
        if let lastUpdate = lastETAUpdate {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            if timeSinceLastUpdate < config.etaUpdateInterval {
                return
            }
        }

        // Calcular nuevo ETA
        let speed = averageSpeed > 0 ? averageSpeed : (config.defaultSpeed / 3.6) // km/h a m/s
        etaRemaining = distanceRemaining / speed

        lastETAUpdate = Date()
    }

    /// Inicia timer de actualización de ETA
    private func startETATimer() {
        etaUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isNavigating else { return }

            // Decrementar ETA
            if self.etaRemaining > 0 {
                self.etaRemaining = max(0, self.etaRemaining - 1.0)
            }
        }
    }

    /// Detiene timer de ETA
    private func stopETATimer() {
        etaUpdateTimer?.invalidate()
        etaUpdateTimer = nil
    }

    /// Actualiza el estado completo de navegación
    private func updateNavigationState() {
        state = NavigationState(
            isNavigating: isNavigating,
            selectedRoute: activeRoute,
            currentStep: currentStep,
            nextStep: nextStep,
            currentZone: currentZone,
            progress: progressAlongRoute,
            distanceRemaining: distanceRemaining,
            etaRemaining: etaRemaining,
            distanceTraveled: distanceTraveled
        )
    }

    // MARK: - Public Helpers

    /// Obtiene la zona de calidad del aire en una coordenada específica
    func getZoneAtCoordinate(_ coordinate: CLLocationCoordinate2D) -> AirQualityZone? {
        guard let gridManager = airQualityGridManager else { return nil }

        return gridManager.zones.min { zone1, zone2 in
            let dist1 = coordinate.distance(to: zone1.coordinate)
            let dist2 = coordinate.distance(to: zone2.coordinate)
            return dist1 < dist2
        }
    }

    /// Obtiene el siguiente paso de navegación
    func getNextManeuver() -> NavigationStep? {
        return nextStep
    }
}
