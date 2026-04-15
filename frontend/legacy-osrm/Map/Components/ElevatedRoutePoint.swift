//
//  ElevatedRoutePoint.swift
//  AcessNet
//
//  Punto elevado visible sobre edificios 3D en la ruta
//

import SwiftUI

// MARK: - Elevated Route Point

struct ElevatedRoutePoint: View {
    let index: Int
    let total: Int

    @State private var rotationAngle: Double = 0
    @State private var isPulsing = false

    var gradientColors: [Color] {
        let allColors: [Color] = [.cyan, .blue, .purple, .pink]
        let startIndex = index % allColors.count
        return (0..<4).map { i in allColors[(startIndex + i) % allColors.count] }
    }

    var body: some View {
        ZStack {
            // Outer glow pulsante multicolor
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            gradientColors[0].opacity(0.6),
                            gradientColors[1].opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 16
                    )
                )
                .frame(width: 32, height: 32)
                .blur(radius: 6)
                .scaleEffect(isPulsing ? 1.4 : 1.0)

            // Main point con gradiente angular giratorio
            Circle()
                .fill(
                    AngularGradient(
                        colors: gradientColors,
                        center: .center,
                        startAngle: .degrees(rotationAngle),
                        endAngle: .degrees(rotationAngle + 360)
                    )
                )
                .frame(width: 12, height: 12)
                .multicolorGlow(colors: gradientColors, radius: 10, intensity: 1.0)
                .overlay(
                    Circle()
                        .strokeBorder(.white, lineWidth: 2)
                )
        }
        .onAppear {
            // Stagger pulse animation
            let pulseDelay = Double(index) * 0.03
            DispatchQueue.main.asyncAfter(deadline: .now() + pulseDelay) {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }

            // Stagger rotation animation
            let rotationDelay = Double(index) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + rotationDelay) {
                withAnimation(
                    .linear(duration: 3.0)
                    .repeatForever(autoreverses: false)
                ) {
                    rotationAngle = 360
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Elevated Route Points") {
    VStack(spacing: 30) {
        Text("Elevated Route Point")
            .font(.title2.bold())
            .padding()

        HStack(spacing: 40) {
            VStack {
                ElevatedRoutePoint(index: 0, total: 10)
                Text("First Point")
                    .font(.caption)
            }

            VStack {
                ElevatedRoutePoint(index: 5, total: 10)
                Text("Mid Point")
                    .font(.caption)
            }

            VStack {
                ElevatedRoutePoint(index: 9, total: 10)
                Text("Last Point")
                    .font(.caption)
            }
        }

        Spacer()
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
