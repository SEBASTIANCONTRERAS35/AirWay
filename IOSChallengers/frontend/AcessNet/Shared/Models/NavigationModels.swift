//
//  NavigationModels.swift
//  AcessNet
//
//  Modelos de datos para el sistema de navegación turn-by-turn
//

import Foundation
import CoreLocation
import MapKit

// MARK: - Navigation Step

/// Representa un paso de navegación (instrucción)
struct NavigationStep: Identifiable {
    let id = UUID()
    let instruction: String              // "Turn right on Main St"
    let distance: Double                 // Metros al siguiente paso
    let maneuverType: ManeuverType       // Tipo de maniobra
    let coordinate: CLLocationCoordinate2D
    let expectedAQI: Double?             // AQI esperado en esta zona
    let stepIndex: Int                   // Índice del paso en la ruta

    init(
        instruction: String,
        distance: Double,
        maneuverType: ManeuverType,
        coordinate: CLLocationCoordinate2D,
        expectedAQI: Double? = nil,
        stepIndex: Int = 0
    ) {
        self.instruction = instruction
        self.distance = distance
        self.maneuverType = maneuverType
        self.coordinate = coordinate
        self.expectedAQI = expectedAQI
        self.stepIndex = stepIndex
    }

    /// Crea NavigationStep desde MKRoute.Step
    init(from mkStep: MKRoute.Step, stepIndex: Int, expectedAQI: Double? = nil) {
        self.instruction = mkStep.instructions
        self.distance = mkStep.distance
        self.maneuverType = ManeuverType.from(mkStep: mkStep)
        self.coordinate = mkStep.polyline.coordinate
        self.expectedAQI = expectedAQI
        self.stepIndex = stepIndex
    }

    // MARK: - Computed Properties

    /// Distancia formateada
    var distanceFormatted: String {
        if distance < 100 {
            return "In \(Int(distance)) m"
        } else if distance < 1000 {
            return "In \(Int(distance)) m"
        } else {
            return "In \(String(format: "%.1f", distance / 1000)) km"
        }
    }

    /// Instrucción corta para mostrar
    var shortInstruction: String {
        // Tomar solo la primera línea
        return instruction.components(separatedBy: "\n").first ?? instruction
    }
}

// MARK: - Maneuver Type

/// Tipos de maniobras de navegación
enum ManeuverType: String, CaseIterable {
    case straight = "Continue Straight"
    case turnLeft = "Turn Left"
    case turnRight = "Turn Right"
    case sharpLeft = "Sharp Left"
    case sharpRight = "Sharp Right"
    case slightLeft = "Bear Left"
    case slightRight = "Bear Right"
    case exitLeft = "Take Exit Left"
    case exitRight = "Take Exit Right"
    case merge = "Merge"
    case roundabout = "Roundabout"
    case arrive = "Arrive at Destination"
    case depart = "Head"
    case uTurn = "Make U-Turn"
    case unknown = "Continue"

    /// Icono SF Symbol
    var icon: String {
        switch self {
        case .straight:
            return "arrow.up"
        case .turnLeft:
            return "arrow.turn.up.left"
        case .turnRight:
            return "arrow.turn.up.right"
        case .sharpLeft:
            return "arrow.uturn.left"
        case .sharpRight:
            return "arrow.uturn.right"
        case .slightLeft:
            return "arrow.up.left"
        case .slightRight:
            return "arrow.up.right"
        case .exitLeft:
            return "arrow.uturn.up.circle"
        case .exitRight:
            return "arrow.uturn.up.circle"
        case .merge:
            return "arrow.triangle.merge"
        case .roundabout:
            return "arrow.triangle.2.circlepath"
        case .arrive:
            return "mappin.circle.fill"
        case .depart:
            return "location.fill"
        case .uTurn:
            return "arrow.uturn.down"
        case .unknown:
            return "arrow.up.circle"
        }
    }

    /// Color del icono
    var color: String {
        switch self {
        case .arrive:
            return "#4CAF50" // Verde
        case .sharpLeft, .sharpRight, .uTurn:
            return "#F44336" // Rojo (maniobra compleja)
        case .exitLeft, .exitRight, .roundabout:
            return "#FF9800" // Naranja (atención)
        default:
            return "#2196F3" // Azul (normal)
        }
    }

    /// Crea ManeuverType desde MKRoute.Step
    static func from(mkStep: MKRoute.Step) -> ManeuverType {
        let instructions = mkStep.instructions.lowercased()

        // Llegada
        if instructions.contains("arrive") || instructions.contains("destination") {
            return .arrive
        }

        // Salida
        if instructions.contains("head") || instructions.contains("start") {
            return .depart
        }

        // Giros
        if instructions.contains("turn left") || instructions.contains("left turn") {
            return .turnLeft
        }
        if instructions.contains("turn right") || instructions.contains("right turn") {
            return .turnRight
        }

        // Giros pronunciados
        if instructions.contains("sharp left") {
            return .sharpLeft
        }
        if instructions.contains("sharp right") {
            return .sharpRight
        }

        // Giros suaves
        if instructions.contains("slight left") || instructions.contains("bear left") {
            return .slightLeft
        }
        if instructions.contains("slight right") || instructions.contains("bear right") {
            return .slightRight
        }

        // Salidas
        if instructions.contains("exit") && instructions.contains("left") {
            return .exitLeft
        }
        if instructions.contains("exit") && instructions.contains("right") {
            return .exitRight
        }

        // Merge
        if instructions.contains("merge") {
            return .merge
        }

        // Rotonda
        if instructions.contains("roundabout") || instructions.contains("traffic circle") {
            return .roundabout
        }

        // U-Turn
        if instructions.contains("u-turn") || instructions.contains("u turn") {
            return .uTurn
        }

        // Continuar recto
        if instructions.contains("continue") || instructions.contains("straight") {
            return .straight
        }

        return .unknown
    }
}

// MARK: - Navigation State

/// Estado completo del sistema de navegación
struct NavigationState {
    let isNavigating: Bool
    let selectedRoute: ScoredRoute?
    let currentStep: NavigationStep?
    let nextStep: NavigationStep?
    let currentZone: AirQualityZone?
    let progress: Double                 // 0.0 - 1.0
    let distanceRemaining: Double        // Metros
    let etaRemaining: TimeInterval       // Segundos
    let distanceTraveled: Double         // Metros recorridos

    init(
        isNavigating: Bool = false,
        selectedRoute: ScoredRoute? = nil,
        currentStep: NavigationStep? = nil,
        nextStep: NavigationStep? = nil,
        currentZone: AirQualityZone? = nil,
        progress: Double = 0.0,
        distanceRemaining: Double = 0.0,
        etaRemaining: TimeInterval = 0.0,
        distanceTraveled: Double = 0.0
    ) {
        self.isNavigating = isNavigating
        self.selectedRoute = selectedRoute
        self.currentStep = currentStep
        self.nextStep = nextStep
        self.currentZone = currentZone
        self.progress = progress
        self.distanceRemaining = distanceRemaining
        self.etaRemaining = etaRemaining
        self.distanceTraveled = distanceTraveled
    }

    // MARK: - Computed Properties

    /// Distancia restante formateada
    var distanceRemainingFormatted: String {
        if distanceRemaining < 1000 {
            return "\(Int(distanceRemaining)) m"
        } else {
            return String(format: "%.1f km", distanceRemaining / 1000)
        }
    }

    /// ETA restante formateado
    var etaRemainingFormatted: String {
        let minutes = Int(etaRemaining / 60)

        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }

    /// Distancia recorrida formateada
    var distanceTraveledFormatted: String {
        if distanceTraveled < 1000 {
            return "\(Int(distanceTraveled)) m"
        } else {
            return String(format: "%.1f km", distanceTraveled / 1000)
        }
    }

    /// Porcentaje de progreso
    var progressPercentage: Int {
        return Int(progress * 100)
    }

    /// Estado vacío/inicial
    static let empty = NavigationState()
}

// MARK: - Navigation Alert

/// Alertas durante la navegación
enum NavigationAlert: Equatable {
    case approaching(step: String, distance: Double)   // "Approaching turn in 200m"
    case poorAirQuality(aqi: Int)                      // "Poor air quality ahead (AQI 150)"
    case offRoute                                      // "You're off route. Recalculating..."
    case arrived                                       // "You have arrived!"
    case recalculating                                 // "Recalculating route..."

    var message: String {
        switch self {
        case .approaching(let step, let distance):
            if distance < 100 {
                return "Prepare to \(step)"
            } else {
                return "\(step) in \(Int(distance))m"
            }
        case .poorAirQuality(let aqi):
            return "Poor air quality ahead (AQI \(aqi))"
        case .offRoute:
            return "You're off route. Recalculating..."
        case .arrived:
            return "You have arrived!"
        case .recalculating:
            return "Recalculating route..."
        }
    }

    var icon: String {
        switch self {
        case .approaching:
            return "exclamationmark.triangle.fill"
        case .poorAirQuality:
            return "aqi.high"
        case .offRoute:
            return "location.slash.fill"
        case .arrived:
            return "checkmark.circle.fill"
        case .recalculating:
            return "arrow.clockwise.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .approaching:
            return "#FF9800" // Naranja
        case .poorAirQuality:
            return "#F44336" // Rojo
        case .offRoute:
            return "#FF5722" // Rojo-naranja
        case .arrived:
            return "#4CAF50" // Verde
        case .recalculating:
            return "#2196F3" // Azul
        }
    }
}

// MARK: - Navigation Configuration

/// Configuración de navegación
struct NavigationConfiguration {
    /// Distancia mínima para considerar que pasó un paso (metros)
    let stepCompletionThreshold: Double = 30

    /// Distancia para anunciar próximo paso (metros)
    let stepAnnouncementDistance: Double = 200

    /// Distancia máxima para considerar que usuario está en ruta (metros)
    let offRouteThreshold: Double = 50

    /// Intervalo de recálculo de ETA (segundos)
    let etaUpdateInterval: TimeInterval = 30

    /// Velocidad promedio asumida si no hay datos (km/h)
    let defaultSpeed: Double = 30

    /// Distancia mínima para recalcular ruta cuando está off-route (metros)
    let recalculationDistance: Double = 100

    static let `default` = NavigationConfiguration()
}
