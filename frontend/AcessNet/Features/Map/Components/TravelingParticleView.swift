//
//  TravelingParticleView.swift
//  AcessNet
//
//  Partícula que viaja a lo largo de la ruta con trail luminoso
//

import SwiftUI
import CoreLocation

// MARK: - Traveling Particle View

struct TravelingParticleView: View {
    let particle: TravelingParticle

    var body: some View {
        ZStack {
            // Trail/estela (más grande y difuminada)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            particle.color.colors[0].opacity(0.6),
                            particle.color.colors[0].opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
                .blur(radius: 8)

            // Partícula principal con glow neón
            Circle()
                .fill(
                    LinearGradient(
                        colors: particle.color.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 16, height: 16)
                .neonGlow(color: particle.color.colors[0], radius: 12)

            // Núcleo brillante
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .blur(radius: 1)
        }
        .rotationEffect(.degrees(particle.heading))
    }
}

// MARK: - Compact Particle (para zoom lejano)

struct CompactParticleView: View {
    let particle: TravelingParticle

    var body: some View {
        Circle()
            .fill(particle.color.colors[0])
            .frame(width: 10, height: 10)
            .neonGlow(color: particle.color.colors[0], radius: 8)
    }
}

// MARK: - Preview

#Preview("Traveling Particles") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Traveling Particles")
                .font(.title.bold())
                .foregroundStyle(.white)

            HStack(spacing: 50) {
                TravelingParticleView(
                    particle: TravelingParticle(
                        coordinate: .init(latitude: 0, longitude: 0),
                        heading: 0,
                        progress: 0,
                        index: 0,
                        color: .cyan
                    )
                )

                TravelingParticleView(
                    particle: TravelingParticle(
                        coordinate: .init(latitude: 0, longitude: 0),
                        heading: 45,
                        progress: 0.5,
                        index: 1,
                        color: .purple
                    )
                )

                TravelingParticleView(
                    particle: TravelingParticle(
                        coordinate: .init(latitude: 0, longitude: 0),
                        heading: 90,
                        progress: 1.0,
                        index: 2,
                        color: .rainbow
                    )
                )
            }

            Divider()
                .background(.white)

            HStack(spacing: 50) {
                CompactParticleView(
                    particle: TravelingParticle(
                        coordinate: .init(latitude: 0, longitude: 0),
                        color: .cyan
                    )
                )

                CompactParticleView(
                    particle: TravelingParticle(
                        coordinate: .init(latitude: 0, longitude: 0),
                        color: .pink
                    )
                )
            }

            Spacer()
        }
        .padding()
    }
}
