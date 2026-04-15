//
//  MultiRouteVisualization.swift
//  AcessNet
//
//  Componentes visuales para mostrar múltiples rutas alternativas con scoring
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Multi Route Overlay

/// MapContent para mostrar múltiples rutas en el mapa con diferentes estilos
struct MultiRouteOverlay: MapContent {
    let scoredRoutes: [ScoredRoute]
    let selectedIndex: Int?
    let animationPhase: CGFloat

    var body: some MapContent {
        ForEach(Array(scoredRoutes.enumerated()), id: \.element.id) { index, route in
            RoutePolylineMapContent(
                route: route,
                isSelected: selectedIndex == index,
                routeStyle: determineRouteStyle(for: route, at: index),
                animationPhase: animationPhase
            )
        }
    }

    private func determineRouteStyle(for route: ScoredRoute, at index: Int) -> RouteStyle {
        // Determinar estilo basado en la mejor característica de la ruta
        if let incidents = route.incidentAnalysis {
            if incidents.safetyScore >= 90 {
                return .safest
            }
        }

        if route.airQualityScore >= 85 {
            return .cleanest
        }

        if route.timeScore >= 90 {
            return .fastest
        }

        // Por defecto, usar estilo por posición
        switch index {
        case 0: return .primary
        case 1: return .alternative1
        case 2: return .alternative2
        default: return .alternative1
        }
    }
}

// MARK: - Route Polyline View

/// MapContent wrapper for route polylines (not a View)
struct RoutePolylineMapContent: MapContent {
    let route: ScoredRoute
    let isSelected: Bool
    let routeStyle: RouteStyle
    let animationPhase: CGFloat

    var body: some MapContent {
        // Capa base (sombra)
        MapPolyline(route.routeInfo.route.polyline)
            .stroke(
                Color.black.opacity(isSelected ? 0.4 : 0.2),
                style: StrokeStyle(
                    lineWidth: isSelected ? 10 : 6,
                    lineCap: .round,
                    lineJoin: .round
                )
            )

        // Capa principal con gradiente (color más intenso si está seleccionada)
        MapPolyline(route.routeInfo.route.polyline)
            .stroke(
                LinearGradient(
                    colors: isSelected ? selectedGradientColors : routeStyle.gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: isSelected ? 7 : 4,
                    lineCap: .round,
                    lineJoin: .round
                )
            )

        // Capa de animación (solo si está seleccionada)
        if isSelected {
            MapPolyline(route.routeInfo.route.polyline)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: [20, 15],
                        dashPhase: animationPhase
                    )
                )
        }
    }

    // Colores más intensos para la ruta seleccionada
    private var selectedGradientColors: [Color] {
        [Color(hex: "#00B020"), Color(hex: "#00D428")]  // Verde intenso y brillante
    }
}

// MARK: - Route Style

/// Estilos predefinidos para las rutas
enum RouteStyle {
    case primary       // Ruta recomendada
    case fastest       // Más rápida
    case safest        // Más segura
    case cleanest      // Mejor aire
    case alternative1  // Alternativa 1
    case alternative2  // Alternativa 2

    var gradientColors: [Color] {
        switch self {
        case .primary:
            return [Color(hex: "#34C759"), Color(hex: "#30D158")]  // Verde medio brillante
        case .fastest:
            return [Color(hex: "#52C41A"), Color(hex: "#73D13D")]  // Verde lima
        case .safest:
            return [Color(hex: "#2ECC71"), Color(hex: "#27AE60")]  // Verde esmeralda
        case .cleanest:
            return [Color(hex: "#00C853"), Color(hex: "#64DD17")]  // Verde claro brillante
        case .alternative1:
            return [Color(hex: "#7CB342"), Color(hex: "#9CCC65")]  // Verde oliva claro
        case .alternative2:
            return [Color(hex: "#66BB6A"), Color(hex: "#81C784")]  // Verde pastel
        }
    }

    var pulseColor: Color {
        switch self {
        case .primary: return Color(hex: "#34C759")
        case .fastest: return Color(hex: "#52C41A")
        case .safest: return Color(hex: "#2ECC71")
        case .cleanest: return Color(hex: "#00C853")
        case .alternative1: return Color(hex: "#7CB342")
        case .alternative2: return Color(hex: "#66BB6A")
        }
    }

    var icon: String {
        switch self {
        case .primary: return "star.fill"
        case .fastest: return "bolt.fill"
        case .safest: return "shield.fill"
        case .cleanest: return "leaf.fill"
        case .alternative1: return "arrow.triangle.branch"
        case .alternative2: return "arrow.triangle.2.circlepath"
        }
    }

    var label: String {
        switch self {
        case .primary: return "Recommended"
        case .fastest: return "Fastest"
        case .safest: return "Safest"
        case .cleanest: return "Cleanest Air"
        case .alternative1: return "Alternative 1"
        case .alternative2: return "Alternative 2"
        }
    }
}

// MARK: - Route Cards Selector

/// Selector de rutas con cards visuales
struct RouteCardsSelector: View {
    let routes: [ScoredRoute]
    @Binding var selectedIndex: Int?
    let onSelectRoute: (Int) -> Void

    @State private var expandedCard: UUID? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(routes.enumerated()), id: \.element.id) { index, route in
                    RouteComparisonCard(
                        route: route,
                        index: index,
                        isSelected: selectedIndex == index,
                        isExpanded: expandedCard == route.id,
                        routeStyle: determineStyle(for: route, at: index),
                        bestRouteTime: routes.first?.routeInfo.expectedTravelTime,
                        onTap: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedIndex = index
                                onSelectRoute(index)
                            }
                        },
                        onExpand: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                expandedCard = expandedCard == route.id ? nil : route.id
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .frame(height: expandedCard == nil ? 140 : 220)
    }

    private func determineStyle(for route: ScoredRoute, at index: Int) -> RouteStyle {
        // Protección: si solo hay una ruta, es Recommended
        guard routes.count > 1 else { return .primary }

        // Determinar qué ruta tiene cada característica más alta
        let safestIndex = routes.enumerated().max(by: { $0.element.safetyScore < $1.element.safetyScore })?.offset
        let fastestIndex = routes.enumerated().max(by: { $0.element.timeScore < $1.element.timeScore })?.offset
        let cleanestIndex = routes.enumerated().max(by: { $0.element.airQualityScore < $1.element.airQualityScore })?.offset

        print("🔍 Route \(index): Safety=\(route.safetyScore), Time=\(route.timeScore), Air=\(route.airQualityScore)")
        print("🏆 Best indices - Fastest: \(fastestIndex ?? -1), Cleanest: \(cleanestIndex ?? -1), Safest: \(safestIndex ?? -1)")

        // Calcular diferencias entre mejor y peor ruta
        let safetyScores = routes.map { $0.safetyScore }
        let timeScores = routes.map { $0.timeScore }
        let airScores = routes.map { $0.airQualityScore }

        let safetyDifference = (safetyScores.max() ?? 0) - (safetyScores.min() ?? 0)
        let timeDifference = (timeScores.max() ?? 0) - (timeScores.min() ?? 0)
        let airDifference = (airScores.max() ?? 0) - (airScores.min() ?? 0)

        print("📊 Differences - Safety: \(safetyDifference), Time: \(timeDifference), Air: \(airDifference)")

        // Umbral mínimo de diferencia - prácticamente cualquier diferencia cuenta
        let threshold: Double = 0.01

        // Asignar etiqueta especial solo a UNA ruta (la que tiene la característica más dominante)
        // Prioridad: Cleanest Air > Fastest > Safest
        if index == cleanestIndex && airDifference >= threshold {
            print("✅ Route \(index) is CLEANEST (Primera prioridad)")
            return .cleanest
        } else if index == fastestIndex && timeDifference >= threshold && index != cleanestIndex {
            print("✅ Route \(index) is FASTEST (Segunda prioridad)")
            return .fastest
        } else if index == safestIndex && safetyDifference >= threshold && index != cleanestIndex && index != fastestIndex {
            print("✅ Route \(index) is SAFEST (Tercera prioridad)")
            return .safest
        }

        print("⭐ Route \(index) is RECOMMENDED")
        // Todas las demás rutas simplemente son "Recommended"
        return .primary
    }
}

// MARK: - Route Comparison Card

/// Card individual para comparar rutas
struct RouteComparisonCard: View {
    let route: ScoredRoute
    let index: Int
    let isSelected: Bool
    let isExpanded: Bool
    let routeStyle: RouteStyle
    let bestRouteTime: TimeInterval?
    let onTap: () -> Void
    let onExpand: () -> Void

    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header con estilo e icono
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: routeStyle.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: routeStyle.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(routeStyle.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if index == 0 {
                        Text("Best overall")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if let bestTime = bestRouteTime {
                        // Mostrar diferencia con la mejor ruta
                        let timeDiff = route.routeInfo.expectedTravelTime - bestTime
                        let timeDiffMin = Int(timeDiff / 60)

                        if timeDiffMin > 0 {
                            Text("+\(timeDiffMin) min")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        } else {
                            Text("Similar time")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Botón de expandir
                Button(action: onExpand) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? routeStyle.pulseColor : .gray)
                }
            }

            // Información básica
            HStack(spacing: 16) {
                // Tiempo
                InfoPill(
                    icon: "clock.fill",
                    value: route.routeInfo.timeFormatted,
                    color: .blue
                )

                // Distancia
                InfoPill(
                    icon: "arrow.left.and.right",
                    value: route.routeInfo.distanceFormatted,
                    color: .green
                )
            }

            // Detalles expandidos
            if isExpanded {
                VStack(spacing: 8) {
                    Divider()

                    // Scores visuales
                    HStack(spacing: 12) {
                        ScoreBadge(
                            label: "Safety",
                            score: route.safetyScore,
                            icon: "shield.fill"
                        )

                        ScoreBadge(
                            label: "Air",
                            score: route.airQualityScore,
                            icon: "leaf.fill"
                        )

                        ScoreBadge(
                            label: "Speed",
                            score: route.timeScore,
                            icon: "bolt.fill"
                        )
                    }

                    // Incidentes si hay
                    if let incidents = route.incidentAnalysis, incidents.totalIncidents > 0 {
                        Text(incidents.incidentSummary)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Score combinado
                    HStack {
                        Text("Overall Score")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(Int(route.combinedScore))/100")
                            .font(.caption.bold())
                            .foregroundStyle(scoreColor(route.combinedScore))
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ?
                                LinearGradient(
                                    colors: routeStyle.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isSelected ? routeStyle.pulseColor.opacity(0.3) : .black.opacity(0.1),
            radius: isSelected ? 15 : 8,
            x: 0,
            y: 5
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .onTapGesture(perform: onTap)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Helper Components

/// Pill de información compacta
struct InfoPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

/// Badge de score visual
struct ScoreBadge: View {
    let label: String
    let score: Double
    let icon: String

    private var color: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 3)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round
                        )
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(color)

                    Text("\(Int(score))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Route Animation Controller

/// Controlador de animaciones para las rutas
class RouteAnimationController: ObservableObject {
    @Published var dashPhase: CGFloat = 0
    @Published var particlePositions: [UUID: CGFloat] = [:]

    private var animationTimer: Timer?

    init() {
        startAnimations()
    }

    deinit {
        stopAnimations()
    }

    func startAnimations() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                self.dashPhase -= 2
                if self.dashPhase <= -40 {
                    self.dashPhase = 0
                }
            }
        }
    }

    func stopAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    func animateParticle(for routeId: UUID) {
        withAnimation(
            .linear(duration: 10)
            .repeatForever(autoreverses: false)
        ) {
            particlePositions[routeId] = 1.0
        }
    }
}