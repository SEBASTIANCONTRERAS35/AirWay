//
//  RouteManager.swift
//  AcessNet
//
//  Gestor de rutas usando MKDirections para cálculo de rutas óptimas
//

import Foundation
import MapKit
import Combine
import SwiftUI

class RouteManager: ObservableObject {

    // MARK: - Published Properties

    /// Ruta actual calculada (DEPRECATED - usar currentScoredRoute)
    @Published var currentRoute: RouteInfo?

    /// Rutas alternativas disponibles (DEPRECATED - usar alternateScoredRoutes)
    @Published var alternateRoutes: [RouteInfo] = []

    /// Ruta actual con scoring de calidad del aire
    @Published var currentScoredRoute: ScoredRoute?

    /// Rutas alternativas con scoring
    @Published var alternateScoredRoutes: [ScoredRoute] = []

    /// Indica si se está calculando una ruta
    @Published var isCalculating: Bool = false

    /// Error en caso de fallo al calcular ruta
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var currentTask: Task<Void, Never>?
    private var preference: RoutePreference = .balanced  // Default: balanced

    /// Servicio de API de calidad del aire
    private let airQualityService: AirQualityAPIService

    /// Flag para usar mock service (testing sin backend)
    private var useMockService: Bool = true  // Cambiar a false cuando tengas backend real

    // MARK: - Initialization

    init(useMockService: Bool = true) {
        self.useMockService = useMockService
        self.airQualityService = useMockService ? MockAirQualityAPIService() : AirQualityAPIService.shared
    }

    // MARK: - Public Methods

    /// Establece la preferencia de ruta
    func setPreference(_ preference: RoutePreference) {
        self.preference = preference
    }

    /// Calcula la ruta desde un origen hasta un destino
    func calculateRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        // Almacenar destino para recálculos
        lastDestination = destination

        // Cancelar cualquier cálculo previo
        currentTask?.cancel()

        currentTask = Task { @MainActor in
            await performRouteCalculation(from: origin, to: destination)
        }
    }

    /// Limpia la ruta actual y alternativas
    func clearRoute() {
        currentTask?.cancel()
        currentRoute = nil
        alternateRoutes = []
        errorMessage = nil
        isCalculating = false
        lastDestination = nil
    }

    /// Recalcula la ruta actual con nueva ubicación de origen
    /// Nota: Requiere almacenar la coordenada de destino previamente
    var lastDestination: CLLocationCoordinate2D?

    func updateOrigin(to newOrigin: CLLocationCoordinate2D) {
        guard let destination = lastDestination else {
            return
        }
        calculateRoute(from: newOrigin, to: destination)
    }

    // MARK: - Private Methods

    @MainActor
    private func performRouteCalculation(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async {
        isCalculating = true
        errorMessage = nil

        // Crear placemarks
        let originPlacemark = MKPlacemark(coordinate: origin)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        // Crear request
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: originPlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = preference.transportType
        request.requestsAlternateRoutes = true  // Siempre pedir alternativas para scoring

        // Configurar opciones según preferencia
        switch preference {
        case .fastest, .cleanestAir, .balanced, .healthOptimized, .customWeighted:
            // Por defecto MKDirections optimiza para la ruta más rápida
            break
        case .shortest:
            // MKDirections no tiene opción explícita para ruta más corta,
            // pero podemos filtrar las alternativas después
            break
        case .avoidHighways:
            // Evitar autopistas
            request.tollPreference = .avoid
            break
        }

        // Calcular rutas
        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()

            // Convertir a RouteInfo
            let routes = response.routes.map { RouteInfo(from: $0) }

            if routes.isEmpty {
                errorMessage = "No se encontró ninguna ruta disponible"
                currentRoute = nil
                alternateRoutes = []
                currentScoredRoute = nil
                alternateScoredRoutes = []
            } else {
                print("✅ Apple Maps retornó \(routes.count) rutas")

                // Si la preferencia requiere datos de aire, hacer scoring avanzado
                if preference.requiresAirQualityData {
                    await performAirQualityScoring(routes: routes)
                } else {
                    // Modo legacy: solo ordenar por tiempo
                    let sortedRoutes = sortRoutes(routes)
                    currentRoute = sortedRoutes.first
                    alternateRoutes = Array(sortedRoutes.dropFirst())

                    // También crear scored routes sin datos de aire
                    let fastestTime = routes.map { $0.expectedTravelTime }.min() ?? 0
                    let scoredRoutes = routes.map { routeInfo in
                        ScoredRoute(
                            routeInfo: routeInfo,
                            airQualityAnalysis: nil,
                            fastestTime: fastestTime,
                            cleanestAQI: 0,
                            preference: preference
                        )
                    }

                    currentScoredRoute = scoredRoutes.first
                    alternateScoredRoutes = Array(scoredRoutes.dropFirst())

                    print("✅ Ruta calculada: \(currentRoute?.distanceFormatted ?? "N/A"), tiempo: \(currentRoute?.timeFormatted ?? "N/A")")
                }

                if !alternateRoutes.isEmpty {
                    print("📍 \(alternateRoutes.count) rutas alternativas disponibles")
                }
            }
        } catch {
            print("❌ Error al calcular ruta: \(error.localizedDescription)")
            errorMessage = "No se pudo calcular la ruta: \(error.localizedDescription)"
            currentRoute = nil
            alternateRoutes = []
            currentScoredRoute = nil
            alternateScoredRoutes = []
        }

        isCalculating = false
    }

    /// Realiza scoring avanzado con datos de calidad del aire
    @MainActor
    private func performAirQualityScoring(routes: [RouteInfo]) async {
        print("🌍 Iniciando análisis de calidad del aire para \(routes.count) rutas...")

        var routesWithAirQuality: [(RouteInfo, AirQualityRouteAnalysis?)] = []

        // Para cada ruta, analizar calidad del aire
        for (index, routeInfo) in routes.enumerated() {
            print("  Analizando ruta \(index + 1)/\(routes.count)...")

            do {
                // Samplear coordenadas del polyline (cada 150m)
                let sampledCoordinates = samplePolylineCoordinates(
                    routeInfo.route.polyline,
                    interval: 150
                )

                print("    - Polyline tiene \(sampledCoordinates.count) puntos muestreados")

                // Consultar backend para análisis de calidad del aire
                let airQualityAnalysis = try await airQualityService.analyzeRoute(
                    coordinates: sampledCoordinates,
                    samplingInterval: 150
                )

                print("    - AQI promedio: \(Int(airQualityAnalysis.averageAQI))")

                // Guardar ruta con análisis
                routesWithAirQuality.append((routeInfo, airQualityAnalysis))

            } catch {
                print("    ⚠️ Error analizando ruta: \(error.localizedDescription)")

                // Si falla el análisis de aire, crear ruta sin datos de aire
                routesWithAirQuality.append((routeInfo, nil))
            }
        }

        // Calcular valores mínimos para normalización
        let fastestTime = routes.map { $0.expectedTravelTime }.min() ?? 0
        let cleanestAQI = routesWithAirQuality.compactMap { $0.1?.averageAQI }.min() ?? 50

        // Crear ScoredRoutes con scoring normalizado
        var finalScoredRoutes = routesWithAirQuality.enumerated().map { (index, tuple) in
            ScoredRoute(
                routeInfo: tuple.0,
                airQualityAnalysis: tuple.1,
                fastestTime: fastestTime,
                cleanestAQI: cleanestAQI,
                preference: preference,
                rankPosition: index + 1
            )
        }

        // Ordenar por score combinado (mayor a menor)
        finalScoredRoutes.sort { $0.combinedScore > $1.combinedScore }

        // Actualizar rank positions después de ordenar
        for (index, _) in finalScoredRoutes.enumerated() {
            finalScoredRoutes[index] = ScoredRoute(
                id: finalScoredRoutes[index].id,
                routeInfo: finalScoredRoutes[index].routeInfo,
                airQualityAnalysis: finalScoredRoutes[index].airQualityAnalysis,
                fastestTime: fastestTime,
                cleanestAQI: cleanestAQI,
                preference: preference,
                rankPosition: index + 1
            )
        }

        // Asignar rutas scored
        currentScoredRoute = finalScoredRoutes.first
        alternateScoredRoutes = Array(finalScoredRoutes.dropFirst())

        // Mantener compatibilidad con legacy properties
        currentRoute = currentScoredRoute?.routeInfo
        alternateRoutes = alternateScoredRoutes.map { $0.routeInfo }

        // Log resultado
        if let best = currentScoredRoute {
            print("🏆 Mejor ruta seleccionada:")
            print("   - \(best.routeInfo.distanceFormatted), \(best.routeInfo.timeFormatted)")
            print("   - AQI promedio: \(Int(best.averageAQI))")
            print("   - Score combinado: \(Int(best.combinedScore))/100")
            print("   - \(best.scoreDescription)")
        }
    }

    /// Samplea coordenadas del polyline a intervalos regulares
    private func samplePolylineCoordinates(_ polyline: MKPolyline, interval: CLLocationDistance) -> [CLLocationCoordinate2D] {
        let allCoordinates = polyline.coordinates()
        guard allCoordinates.count >= 2 else { return allCoordinates }

        var sampledCoordinates: [CLLocationCoordinate2D] = []
        var accumulatedDistance: CLLocationDistance = 0
        var nextSampleDistance: CLLocationDistance = 0

        // Siempre incluir primer punto
        sampledCoordinates.append(allCoordinates[0])

        for i in 0..<allCoordinates.count - 1 {
            let coord1 = allCoordinates[i]
            let coord2 = allCoordinates[i + 1]
            let segmentDistance = coord1.distance(to: coord2)

            accumulatedDistance += segmentDistance

            // Si pasamos el siguiente punto de muestreo
            while accumulatedDistance >= nextSampleDistance + interval {
                nextSampleDistance += interval

                // Interpolar punto en el segmento
                let distanceIntoSegment = nextSampleDistance - (accumulatedDistance - segmentDistance)
                let fraction = distanceIntoSegment / segmentDistance

                if fraction >= 0 && fraction <= 1 {
                    let sampledPoint = coord1.interpolate(to: coord2, fraction: fraction)
                    sampledCoordinates.append(sampledPoint)
                }
            }
        }

        // Siempre incluir último punto
        if let last = allCoordinates.last {
            // Verificar si el último punto ya está incluido comparando coordenadas manualmente
            let lastSampled = sampledCoordinates.last
            let shouldAddLast = lastSampled == nil ||
                abs(lastSampled!.latitude - last.latitude) > 0.0001 ||
                abs(lastSampled!.longitude - last.longitude) > 0.0001

            if shouldAddLast {
                sampledCoordinates.append(last)
            }
        }

        return sampledCoordinates
    }

    /// Ordena las rutas según la preferencia establecida
    private func sortRoutes(_ routes: [RouteInfo]) -> [RouteInfo] {
        switch preference {
        case .fastest, .cleanestAir, .balanced, .healthOptimized, .customWeighted:
            return routes.sorted { $0.expectedTravelTime < $1.expectedTravelTime }
        case .shortest:
            return routes.sorted { $0.distanceInKm < $1.distanceInKm }
        case .avoidHighways:
            // Para evitar autopistas, preferimos la más rápida de las disponibles
            return routes.sorted { $0.expectedTravelTime < $1.expectedTravelTime }
        }
    }

    // MARK: - Helper Methods

    /// Obtiene el punto medio de la ruta para centrar la cámara
    func getRouteBounds() -> MKMapRect? {
        guard let route = currentRoute else { return nil }
        return route.route.polyline.boundingMapRect
    }

    /// Calcula el padding apropiado para mostrar toda la ruta en pantalla
    func getPaddingForRouteDisplay() -> EdgeInsets {
        return EdgeInsets(top: 100, leading: 50, bottom: 200, trailing: 50)
    }

    // MARK: - Directional Arrows

    /// Calcula flechas direccionales a lo largo de la ruta
    /// - Parameter interval: Distancia entre flechas en metros (default: 150m)
    /// - Returns: Array de flechas direccionales
    func calculateDirectionalArrows(interval: CLLocationDistance = 150) -> [RouteArrowAnnotation] {
        guard let route = currentRoute?.route else {
            print("❌ calculateDirectionalArrows: No hay ruta en currentRoute")
            return []
        }

        let polyline = route.polyline
        let coordinates = polyline.coordinates()

        print("📊 Polyline tiene \(coordinates.count) coordenadas, distancia total: \(route.distance)m")

        guard coordinates.count >= 2 else {
            print("❌ Polyline tiene menos de 2 coordenadas")
            return []
        }

        var arrows: [RouteArrowAnnotation] = []
        var distanceAccumulated: CLLocationDistance = 0
        var nextArrowDistance: CLLocationDistance = 50 // Primera flecha a 50m

        for i in 0..<coordinates.count - 1 {
            let coord1 = coordinates[i]
            let coord2 = coordinates[i + 1]

            let segmentDistance = coord1.distance(to: coord2)

            // Verificar si debemos colocar flechas en este segmento
            while distanceAccumulated + segmentDistance >= nextArrowDistance {
                // Calcular qué fracción del segmento usar
                let distanceIntoSegment = nextArrowDistance - distanceAccumulated
                let fraction = distanceIntoSegment / segmentDistance

                // Interpolar coordenada
                let arrowCoordinate = coord1.interpolate(to: coord2, fraction: fraction)

                // Calcular heading del segmento
                let heading = coord1.bearing(to: coord2)

                // Crear flecha
                arrows.append(RouteArrowAnnotation(
                    coordinate: arrowCoordinate,
                    heading: heading,
                    distanceFromStart: nextArrowDistance,
                    segmentIndex: i
                ))

                // Siguiente flecha
                nextArrowDistance += interval
            }

            distanceAccumulated += segmentDistance
        }

        print("📍 Generadas \(arrows.count) flechas antes de filtrar")

        // Filtrar flechas muy cerca del destino (últimos 100m)
        let totalDistance = route.distance
        arrows = arrows.filter { $0.distanceFromStart < totalDistance - 100 }

        print("🎯 Calculadas \(arrows.count) flechas direccionales después de filtrar")

        return arrows
    }

    // MARK: - Elevated Route Points (for 3D visibility)

    /// Calcula puntos elevados estratégicos a lo largo de la ruta
    /// - Parameter interval: Distancia entre puntos en metros (default: 40m)
    /// - Returns: Array de coordenadas para puntos elevados
    func calculateElevatedPoints(interval: CLLocationDistance = 40) -> [CLLocationCoordinate2D] {
        guard let route = currentRoute?.route else { return [] }

        let polyline = route.polyline
        let coordinates = polyline.coordinates()

        guard coordinates.count >= 2 else { return [] }

        var points: [CLLocationCoordinate2D] = []
        var distanceAccumulated: CLLocationDistance = 0
        var nextPointDistance: CLLocationDistance = 0 // Primer punto en el inicio

        for i in 0..<coordinates.count - 1 {
            let coord1 = coordinates[i]
            let coord2 = coordinates[i + 1]

            let segmentDistance = coord1.distance(to: coord2)

            // Verificar si debemos colocar puntos en este segmento
            while distanceAccumulated + segmentDistance >= nextPointDistance {
                // Calcular qué fracción del segmento usar
                let distanceIntoSegment = nextPointDistance - distanceAccumulated
                let fraction = distanceIntoSegment / segmentDistance

                // Interpolar coordenada
                let pointCoordinate = coord1.interpolate(to: coord2, fraction: fraction)
                points.append(pointCoordinate)

                // Siguiente punto
                nextPointDistance += interval
            }

            distanceAccumulated += segmentDistance
        }

        // Agregar punto final si no está muy cerca del último punto
        if let lastCoord = coordinates.last, let lastPoint = points.last {
            let distanceToEnd = lastPoint.distance(to: lastCoord)
            if distanceToEnd > interval / 2 {
                points.append(lastCoord)
            }
        }

        print("🎯 Calculados \(points.count) puntos elevados para visibilidad 3D")

        return points
    }

    // MARK: - Animated Particles

    /// Genera partículas iniciales para animación
    /// - Parameter count: Número de partículas (default: 5)
    /// - Returns: Array de partículas viajeras
    func generateTravelingParticles(count: Int = 5) -> [TravelingParticle] {
        guard let polyline = currentRoute?.route.polyline else { return [] }

        var particles: [TravelingParticle] = []
        let colors: [ParticleColor] = [.cyan, .blue, .purple, .pink, .rainbow]

        for i in 0..<count {
            // Distribuir partículas uniformemente al inicio
            let initialProgress = Double(i) / Double(count)

            if let pathInfo = polyline.pathInfo(at: initialProgress) {
                let particle = TravelingParticle(
                    coordinate: pathInfo.coordinate,
                    heading: pathInfo.heading,
                    progress: initialProgress,
                    index: i,
                    color: colors[i % colors.count]
                )
                particles.append(particle)
            }
        }

        print("✨ Generadas \(particles.count) partículas viajeras")
        return particles
    }

    /// Actualiza posición de partícula basada en progreso
    /// - Parameters:
    ///   - particle: Partícula a actualizar
    ///   - progress: Nuevo progreso (0.0 - 1.0)
    /// - Returns: Partícula actualizada
    func updateParticle(_ particle: TravelingParticle, progress: Double) -> TravelingParticle {
        guard let polyline = currentRoute?.route.polyline,
              let pathInfo = polyline.pathInfo(at: progress) else {
            return particle
        }

        var updated = particle
        updated.coordinate = pathInfo.coordinate
        updated.heading = pathInfo.heading
        updated.progress = progress

        return updated
    }

    // MARK: - Multicolor Elevated Points

    /// Genera puntos elevados multicolor
    /// - Parameter interval: Distancia entre puntos en metros (default: 40m)
    /// - Returns: Array de puntos elevados multicolor
    func generateMulticolorElevatedPoints(interval: CLLocationDistance = 40) -> [MulticolorElevatedPoint] {
        guard let route = currentRoute?.route else { return [] }

        let polyline = route.polyline
        let coordinates = polyline.coordinates()

        guard coordinates.count >= 2 else { return [] }

        var points: [MulticolorElevatedPoint] = []
        var distanceAccumulated: CLLocationDistance = 0
        var nextPointDistance: CLLocationDistance = 0

        for i in 0..<coordinates.count - 1 {
            let coord1 = coordinates[i]
            let coord2 = coordinates[i + 1]
            let segmentDistance = coord1.distance(to: coord2)

            while distanceAccumulated + segmentDistance >= nextPointDistance {
                let distanceIntoSegment = nextPointDistance - distanceAccumulated
                let fraction = distanceIntoSegment / segmentDistance
                let pointCoordinate = coord1.interpolate(to: coord2, fraction: fraction)

                points.append(MulticolorElevatedPoint(
                    coordinate: pointCoordinate,
                    index: points.count,
                    distanceFromStart: nextPointDistance
                ))

                nextPointDistance += interval
            }

            distanceAccumulated += segmentDistance
        }

        print("🌈 Generados \(points.count) puntos elevados multicolor")
        return points
    }
}

// MARK: - Helper Extensions

private extension EdgeInsets {
    static func uniform(_ value: CGFloat) -> EdgeInsets {
        return EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
    }
}
