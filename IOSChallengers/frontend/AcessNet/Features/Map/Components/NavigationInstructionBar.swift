//
//  NavigationInstructionBar.swift
//  AcessNet
//
//  Barra superior que muestra la próxima instrucción de navegación
//

import SwiftUI
import CoreLocation

// MARK: - Navigation Instruction Bar

struct NavigationInstructionBar: View {
    let step: NavigationStep?
    let distanceToManeuver: Double

    @State private var pulse: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            // Icono de maniobra
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: iconGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: iconColor.opacity(0.3), radius: isUrgent ? 12 : 8, x: 0, y: 4)
                    .scaleEffect(pulse && isUrgent ? 1.05 : 1.0)

                Image(systemName: step?.maneuverType.icon ?? "arrow.up")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Información de instrucción
            VStack(alignment: .leading, spacing: 4) {
                // Distancia
                Text(distanceText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(isUrgent ? iconColor : .secondary)

                // Instrucción
                Text(step?.shortInstruction ?? "Continue on route")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Indicador de urgencia (cuando está muy cerca)
            if isUrgent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .opacity(pulse ? 1.0 : 0.6)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isUrgent ? iconColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
        .onAppear {
            if isUrgent {
                pulse = true
            }
        }
        .onChange(of: isUrgent) { _, newValue in
            pulse = newValue
        }
    }

    // MARK: - Computed Properties

    /// Indica si la maniobra es urgente (< 100m)
    private var isUrgent: Bool {
        return distanceToManeuver < 100
    }

    /// Texto de distancia formateado
    private var distanceText: String {
        if distanceToManeuver < 50 {
            return "Now"
        } else if distanceToManeuver < 1000 {
            return "In \(Int(distanceToManeuver)) m"
        } else {
            return "In \(String(format: "%.1f", distanceToManeuver / 1000)) km"
        }
    }

    /// Color del icono según tipo de maniobra
    private var iconColor: Color {
        guard let step = step else { return Color(hex: "#2196F3") }
        return Color(hex: step.maneuverType.color)
    }

    /// Colores del gradiente del icono
    private var iconGradientColors: [Color] {
        let base = iconColor
        return [base, base.opacity(0.8)]
    }
}

// MARK: - Compact Instruction Bar (vista reducida)

struct CompactInstructionBar: View {
    let step: NavigationStep?
    let distance: Double

    var body: some View {
        HStack(spacing: 12) {
            // Icono pequeño
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 40, height: 40)

                Image(systemName: step?.maneuverType.icon ?? "arrow.up")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Distancia + instrucción en una línea
            VStack(alignment: .leading, spacing: 2) {
                Text(distanceText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(step?.shortInstruction ?? "Continue")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var iconColor: Color {
        guard let step = step else { return Color(hex: "#2196F3") }
        return Color(hex: step.maneuverType.color)
    }

    private var distanceText: String {
        if distance < 50 {
            return "Now"
        } else if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// MARK: - Preview

#Preview("Navigation Instruction Bar") {
    VStack(spacing: 20) {
        Text("Navigation Instructions")
            .font(.title2.bold())
            .padding()

        // Turn Right - Normal
        NavigationInstructionBar(
            step: NavigationStep(
                instruction: "Turn right on Main Street",
                distance: 350,
                maneuverType: .turnRight,
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            ),
            distanceToManeuver: 350
        )

        // Turn Left - Urgent
        NavigationInstructionBar(
            step: NavigationStep(
                instruction: "Turn left on Market Street and continue for 2 blocks",
                distance: 50,
                maneuverType: .turnLeft,
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            ),
            distanceToManeuver: 50
        )

        // Arrive - Close
        NavigationInstructionBar(
            step: NavigationStep(
                instruction: "Arrive at your destination on the right",
                distance: 25,
                maneuverType: .arrive,
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            ),
            distanceToManeuver: 25
        )

        // Sharp Right - Far
        NavigationInstructionBar(
            step: NavigationStep(
                instruction: "Take sharp right onto Highway 101",
                distance: 1500,
                maneuverType: .sharpRight,
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            ),
            distanceToManeuver: 1500
        )

        Divider()

        // Compact versions
        VStack(spacing: 12) {
            CompactInstructionBar(
                step: NavigationStep(
                    instruction: "Turn right on Main St",
                    distance: 200,
                    maneuverType: .turnRight,
                    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                ),
                distance: 200
            )

            CompactInstructionBar(
                step: NavigationStep(
                    instruction: "Arrive at destination",
                    distance: 50,
                    maneuverType: .arrive,
                    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                ),
                distance: 50
            )
        }

        Spacer()
    }
    .padding()
}
