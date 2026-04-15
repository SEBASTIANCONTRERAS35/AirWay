//
//  MulticolorGlowModifier.swift
//  AcessNet
//
//  Modificador de glow multicolor reutilizable para efectos neón
//

import SwiftUI

// MARK: - Multicolor Glow Modifier

struct MulticolorGlowModifier: ViewModifier {
    let colors: [Color]
    let radius: CGFloat
    let intensity: Double

    init(colors: [Color] = [.cyan, .blue, .purple], radius: CGFloat = 10, intensity: Double = 1.0) {
        self.colors = colors
        self.radius = radius
        self.intensity = intensity
    }

    func body(content: Content) -> some View {
        ZStack {
            // Glow layers - múltiples sombras para efecto neón
            ForEach(0..<3) { i in
                content
                    .shadow(
                        color: colors[i % colors.count].opacity(intensity * 0.6),
                        radius: radius / CGFloat(i + 1),
                        x: 0,
                        y: 0
                    )
            }

            // Contenido principal
            content
        }
    }
}

// MARK: - Pulsating Glow Modifier

struct PulsatingGlowModifier: ViewModifier {
    let colors: [Color]
    let baseRadius: CGFloat
    @State private var isPulsing = false

    init(colors: [Color] = [.cyan, .blue], baseRadius: CGFloat = 8) {
        self.colors = colors
        self.baseRadius = baseRadius
    }

    func body(content: Content) -> some View {
        content
            .modifier(MulticolorGlowModifier(
                colors: colors,
                radius: isPulsing ? baseRadius * 1.5 : baseRadius,
                intensity: isPulsing ? 1.2 : 0.8
            ))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Neon Glow Modifier

struct NeonGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    init(color: Color = .cyan, radius: CGFloat = 12) {
        self.color = color
        self.radius = radius
    }

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius / 3, x: 0, y: 0)
            .shadow(color: color.opacity(0.6), radius: radius / 2, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: radius * 1.5, x: 0, y: 0)
    }
}

// MARK: - View Extensions

extension View {
    /// Aplica glow multicolor
    func multicolorGlow(colors: [Color] = [.cyan, .blue, .purple], radius: CGFloat = 10, intensity: Double = 1.0) -> some View {
        modifier(MulticolorGlowModifier(colors: colors, radius: radius, intensity: intensity))
    }

    /// Aplica glow pulsante
    func pulsatingGlow(colors: [Color] = [.cyan, .blue], baseRadius: CGFloat = 8) -> some View {
        modifier(PulsatingGlowModifier(colors: colors, baseRadius: baseRadius))
    }

    /// Aplica glow neón simple
    func neonGlow(color: Color = .cyan, radius: CGFloat = 12) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius))
    }
}

// MARK: - Preview

#Preview("Glow Effects") {
    VStack(spacing: 40) {
        Text("Glow Effects")
            .font(.title.bold())

        HStack(spacing: 40) {
            Circle()
                .fill(.white)
                .frame(width: 30, height: 30)
                .multicolorGlow(colors: [.cyan, .blue, .purple])

            Circle()
                .fill(.white)
                .frame(width: 30, height: 30)
                .pulsatingGlow()

            Circle()
                .fill(.white)
                .frame(width: 30, height: 30)
                .neonGlow(color: .pink)
        }

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
