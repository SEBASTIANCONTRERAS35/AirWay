//
//  DirectionalArrowView.swift
//  AcessNet
//
//  Vista de flecha direccional para rutas 3D
//

import SwiftUI

// MARK: - Directional Arrow View

struct DirectionalArrowView: View {
    let heading: Double
    let isNext: Bool  // Si es la siguiente flecha a seguir
    let size: CGFloat

    init(heading: Double, isNext: Bool = false, size: CGFloat = 40) {
        self.heading = heading
        self.isNext = isNext
        self.size = size
    }

    @State private var animate = false

    var body: some View {
        ZStack {
            // Sombra de fondo para efecto 3D elevado
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: 4)
                .offset(y: 3)

            // Círculo de fondo
            Circle()
                .fill(
                    LinearGradient(
                        colors: isNext ? [.cyan, .blue] : [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .blue.opacity(0.5), radius: 8, x: 0, y: 4)

            // Borde blanco
            Circle()
                .strokeBorder(.white, lineWidth: 3)
                .frame(width: size, height: size)

            // Flecha
            ArrowShape()
                .fill(.white)
                .frame(width: size * 0.5, height: size * 0.5)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .rotationEffect(.degrees(heading))
        .scaleEffect(animate && isNext ? 1.1 : 1.0)
        .animation(
            isNext ?
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                nil,
            value: animate
        )
        .onAppear {
            if isNext {
                animate = true
            }
        }
    }
}

// MARK: - Arrow Shape

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Punta de la flecha
        path.move(to: CGPoint(x: width * 0.5, y: 0))

        // Lado derecho
        path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.4))

        // Tallo derecho
        path.addLine(to: CGPoint(x: width * 0.65, y: height))
        path.addLine(to: CGPoint(x: width * 0.35, y: height))

        // Tallo izquierdo
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.4))

        // Lado izquierdo
        path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.4))

        path.closeSubpath()

        return path
    }
}

// MARK: - Compact Arrow (para zoom lejano)

struct CompactDirectionalArrow: View {
    let heading: Double

    var body: some View {
        ZStack {
            // Círculo pequeño
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 24, height: 24)
                .shadow(color: .blue.opacity(0.4), radius: 4, x: 0, y: 2)

            // Flecha simple
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
        }
        .rotationEffect(.degrees(heading))
    }
}

// MARK: - Elevated Route Marker

struct ElevatedRouteMarker: View {
    let heading: Double
    let distanceText: String?

    var body: some View {
        VStack(spacing: 4) {
            // Flecha principal
            ZStack {
                // Sombra para dar efecto de elevación
                Capsule()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .blur(radius: 6)
                    .offset(y: 6)

                // Contenedor de flecha
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 45, height: 45)
                        .shadow(color: .blue.opacity(0.6), radius: 10, x: 0, y: 5)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .rotationEffect(.degrees(heading))
            }

            // Distancia (opcional)
            if let distance = distanceText {
                Text(distance)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.blue.opacity(0.9))
                            .shadow(radius: 3)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("Directional Arrows") {
    VStack(spacing: 30) {
        Text("Directional Arrow Styles")
            .font(.title2.bold())
            .padding()

        HStack(spacing: 40) {
            VStack {
                DirectionalArrowView(heading: 0, isNext: false, size: 40)
                Text("North")
                    .font(.caption)
            }

            VStack {
                DirectionalArrowView(heading: 90, isNext: false, size: 40)
                Text("East")
                    .font(.caption)
            }

            VStack {
                DirectionalArrowView(heading: 180, isNext: false, size: 40)
                Text("South")
                    .font(.caption)
            }

            VStack {
                DirectionalArrowView(heading: 270, isNext: false, size: 40)
                Text("West")
                    .font(.caption)
            }
        }

        Divider()

        HStack(spacing: 40) {
            VStack {
                DirectionalArrowView(heading: 45, isNext: true, size: 50)
                Text("Next Turn")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }

            VStack {
                CompactDirectionalArrow(heading: 135)
                Text("Compact")
                    .font(.caption)
            }
        }

        Divider()

        HStack(spacing: 40) {
            ElevatedRouteMarker(heading: 0, distanceText: "150m")
            ElevatedRouteMarker(heading: 90, distanceText: nil)
        }

        Spacer()
    }
    .padding()
}
