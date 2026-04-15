//
//  AlertAnnotationView.swift
//  AcessNet
//
//  Anotaciones personalizadas y animadas para alertas en el mapa
//

import SwiftUI
import MapKit

// MARK: - Alert Type Enum

enum AlertType: String, CaseIterable {
    case traffic = "Traffic"
    case hazard = "Hazard"
    case accident = "Accident"
    case pedestrian = "Pedestrian"
    case police = "Police"
    case roadWork = "Road Work"

    var icon: String {
        switch self {
        case .traffic: return "car.fill"
        case .hazard: return "exclamationmark.triangle.fill"
        case .accident: return "car.side.rear.and.collision.and.car.side.front"
        case .pedestrian: return "figure.walk"
        case .police: return "hand.raised.square.on.square.fill"
        case .roadWork: return "cone.fill"
        }
    }

    var color: Color {
        switch self {
        case .traffic: return .red
        case .hazard: return .yellow
        case .accident: return .orange
        case .pedestrian: return .blue
        case .police: return .indigo
        case .roadWork: return .orange
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .traffic: return [.red, .red.opacity(0.7)]
        case .hazard: return [.yellow, .orange]
        case .accident: return [.orange, .red]
        case .pedestrian: return [.blue, .cyan]
        case .police: return [.indigo, .blue]
        case .roadWork: return [.orange, .yellow]
        }
    }
}

// MARK: - Alert Annotation View (Modernizado)

struct AlertAnnotationView: View {
    let alertType: AlertType
    let showPulse: Bool

    var body: some View {
        ZStack {
            // Glow externo con gradiente (SIN BLUR - mejor performance)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            alertType.color.opacity(0.4),
                            alertType.color.opacity(0.25),
                            alertType.color.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)

            // Icono principal con glassmorphism (estático)
            ZStack {
                // Fondo con glassmorphism
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        alertType.gradientColors[0].opacity(0.9),
                                        alertType.gradientColors[1].opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: alertType.color.opacity(0.4), radius: 12, x: 0, y: 6)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                // Borde con gradiente
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.8), .white.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 48, height: 48)

                // Icono con efecto de brillo
                Image(systemName: alertType.icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
    }
}

/// Versión compacta de la anotación
struct CompactAlertView: View {
    let alertType: AlertType
    let count: Int

    var body: some View {
        ZStack {
            // Fondo
            Capsule()
                .fill(alertType.color)
                .frame(width: 60, height: 30)
                .shadow(radius: 3)

            HStack(spacing: 4) {
                Image(systemName: alertType.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)

                if count > 1 {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

/// Anotación expandida con información
struct DetailedAlertView: View {
    let alertType: AlertType
    let time: String
    let distance: String?

    var body: some View {
        VStack(spacing: 4) {
            // Icono principal
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: alertType.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(radius: 5)

                Circle()
                    .strokeBorder(.white, lineWidth: 2)
                    .frame(width: 50, height: 50)

                Image(systemName: alertType.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Info card
            VStack(spacing: 2) {
                Text(alertType.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    if let distance = distance {
                        Text(distance)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 2)
            )

            // Pointer (flecha hacia abajo)
            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 12, height: 6)
                .offset(y: -6)
        }
    }
}

/// Triángulo para pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

/// Pin de ubicación personalizado (Modernizado)
struct CustomMapPin: View {
    let color: Color
    let icon: String

    @State private var animate = false

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.4),
                            color.opacity(0.2),
                            .clear
                        ],
                        center: .center,
                        startRadius: 15,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)
                .blur(radius: 6)
                .offset(y: -20)

            // Pin shape moderno
            VStack(spacing: 0) {
                // Círculo principal con glassmorphism
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.95),
                                        color.opacity(0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay {
                        // Borde con gradiente
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.9), .white.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )

                        // Icono
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 5)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)

                // Pointer bottom con gradiente
                Triangle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.9), color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 14, height: 9)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .scaleEffect(animate ? 1.05 : 1.0)
        }
        .offset(y: -20)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Alert Annotations") {
    ScrollView {
        VStack(spacing: 30) {
            Text("Alert Annotation Styles").font(.title2.bold())

            // Standard annotations
            HStack(spacing: 20) {
                ForEach(AlertType.allCases.prefix(3), id: \.self) { type in
                    VStack {
                        AlertAnnotationView(alertType: type, showPulse: false)
                        Text(type.rawValue)
                            .font(.caption)
                    }
                }
            }

            Divider()

            // With pulse
            HStack(spacing: 20) {
                ForEach(AlertType.allCases.suffix(3), id: \.self) { type in
                    VStack {
                        AlertAnnotationView(alertType: type, showPulse: true)
                        Text(type.rawValue)
                            .font(.caption)
                    }
                }
            }

            Divider()

            // Compact views
            HStack(spacing: 15) {
                CompactAlertView(alertType: .traffic, count: 1)
                CompactAlertView(alertType: .police, count: 3)
                CompactAlertView(alertType: .hazard, count: 5)
            }

            Divider()

            // Detailed views
            HStack(spacing: 20) {
                DetailedAlertView(alertType: .accident, time: "5 min ago", distance: "200m")
                DetailedAlertView(alertType: .roadWork, time: "1 hr ago", distance: nil)
            }

            Divider()

            // Custom pins
            HStack(spacing: 20) {
                CustomMapPin(color: .red, icon: "mappin.circle.fill")
                CustomMapPin(color: .blue, icon: "star.fill")
                CustomMapPin(color: .green, icon: "flag.fill")
            }
        }
        .padding()
    }
}
