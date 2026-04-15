//
//  EnergyPulseView.swift
//  AcessNet
//
//  Pulso de energía expansivo con gradiente arcoíris
//

import SwiftUI
import CoreLocation

// MARK: - Energy Pulse View

struct EnergyPulseView: View {
    let pulse: EnergyPulse

    var body: some View {
        ZStack {
            // Outer glow expansivo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .cyan.opacity(pulse.opacity * 0.4),
                            .blue.opacity(pulse.opacity * 0.2),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120 * pulse.scale, height: 120 * pulse.scale)
                .blur(radius: 15)

            // Pulso principal con gradiente arcoíris
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [.cyan, .blue, .purple, .pink, .cyan],
                        center: .center
                    ),
                    lineWidth: 4
                )
                .frame(width: 50 * pulse.scale, height: 50 * pulse.scale)
                .opacity(pulse.opacity)
                .multicolorGlow(
                    colors: [.cyan, .blue, .purple, .pink],
                    radius: 15,
                    intensity: pulse.opacity
                )

            // Núcleo del pulso
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white, .cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 20 * (1 + pulse.progress * 0.5), height: 20 * (1 + pulse.progress * 0.5))
                .opacity(pulse.opacity * 0.8)
                .blur(radius: 2)
        }
    }
}

// MARK: - Simple Pulse (alternativa ligera)

struct SimplePulseView: View {
    let pulse: EnergyPulse

    var body: some View {
        Circle()
            .strokeBorder(
                .cyan.opacity(pulse.opacity),
                lineWidth: 3
            )
            .frame(width: 40 * pulse.scale, height: 40 * pulse.scale)
            .neonGlow(color: .cyan, radius: 10)
    }
}

// MARK: - Ripple Pulse (efecto ondular)

struct RipplePulseView: View {
    let pulse: EnergyPulse

    var body: some View {
        ZStack {
            // Múltiples círculos concéntricos
            ForEach(0..<3) { i in
                Circle()
                    .strokeBorder(
                        .blue.opacity(pulse.opacity * (1.0 - Double(i) * 0.3)),
                        lineWidth: 2
                    )
                    .frame(
                        width: (40 + CGFloat(i) * 15) * pulse.scale,
                        height: (40 + CGFloat(i) * 15) * pulse.scale
                    )
            }
        }
        .neonGlow(color: .blue, radius: 12)
    }
}

// MARK: - Preview

#Preview("Energy Pulses") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 60) {
            Text("Energy Pulse Effects")
                .font(.title.bold())
                .foregroundStyle(.white)

            // Ejemplo de pulso en diferentes estados
            HStack(spacing: 80) {
                VStack {
                    EnergyPulseView(
                        pulse: EnergyPulse(
                            coordinate: .init(latitude: 0, longitude: 0),
                            progress: 0.0,
                            scale: 1.0,
                            opacity: 1.0
                        )
                    )
                    Text("Start")
                        .foregroundStyle(.white)
                        .font(.caption)
                }

                VStack {
                    EnergyPulseView(
                        pulse: EnergyPulse(
                            coordinate: .init(latitude: 0, longitude: 0),
                            progress: 0.5,
                            scale: 2.0,
                            opacity: 0.5
                        )
                    )
                    Text("Mid")
                        .foregroundStyle(.white)
                        .font(.caption)
                }

                VStack {
                    EnergyPulseView(
                        pulse: EnergyPulse(
                            coordinate: .init(latitude: 0, longitude: 0),
                            progress: 1.0,
                            scale: 3.0,
                            opacity: 0.1
                        )
                    )
                    Text("End")
                        .foregroundStyle(.white)
                        .font(.caption)
                }
            }

            Divider()
                .background(.white)

            // Variantes de pulso
            HStack(spacing: 80) {
                VStack {
                    SimplePulseView(
                        pulse: EnergyPulse(
                            coordinate: .init(latitude: 0, longitude: 0),
                            progress: 0.3,
                            scale: 1.5,
                            opacity: 0.7
                        )
                    )
                    Text("Simple")
                        .foregroundStyle(.white)
                        .font(.caption)
                }

                VStack {
                    RipplePulseView(
                        pulse: EnergyPulse(
                            coordinate: .init(latitude: 0, longitude: 0),
                            progress: 0.4,
                            scale: 1.8,
                            opacity: 0.6
                        )
                    )
                    Text("Ripple")
                        .foregroundStyle(.white)
                        .font(.caption)
                }
            }

            Spacer()
        }
        .padding()
    }
}
