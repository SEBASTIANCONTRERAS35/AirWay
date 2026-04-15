//
//  MapAnimations.swift
//  AcessNet
//
//  Sistema de animaciones reutilizables para el mapa
//

import SwiftUI

// MARK: - View Modifiers para Animaciones

/// Animación de pulso continuo
struct PulseAnimation: ViewModifier {
    let color: Color
    let duration: Double
    @State private var animate = false

    func body(content: Content) -> some View {
        content
            .overlay {
                Circle()
                    .stroke(color, lineWidth: 3)
                    .scaleEffect(animate ? 2.0 : 0.5)
                    .opacity(animate ? 0.0 : 1.0)
            }
            .onAppear {
                withAnimation(
                    .easeOut(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
    }
}

/// Animación bounce al aparecer
struct BounceAnimation: ViewModifier {
    @State private var scale: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
    }
}

/// Animación de fade in
struct FadeInAnimation: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                    opacity = 1.0
                }
            }
    }
}

/// Animación de ripple (ondas)
struct RippleEffect: View {
    let color: Color
    let count: Int
    let duration: Double
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(animate ? 3.0 : 0)
                    .opacity(animate ? 0.0 : 0.8)
                    .animation(
                        .easeOut(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * (duration / Double(count))),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

/// Animación de rotación continua
struct RotatingAnimation: ViewModifier {
    let duration: Double
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

/// Animación de brillo (glow)
struct GlowAnimation: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var animate = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(animate ? 0.8 : 0.3), radius: animate ? radius : radius / 2)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
            .onAppear { animate = true }
    }
}

/// Animación de shake (temblor)
struct ShakeAnimation: ViewModifier {
    @State private var offset: CGFloat = 0
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                    offset = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                        offset = -10
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                        offset = 0
                    }
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Aplica animación de pulso
    func pulseEffect(color: Color = .blue, duration: Double = 1.5) -> some View {
        modifier(PulseAnimation(color: color, duration: duration))
    }

    /// Aplica animación bounce al aparecer
    func bounceIn() -> some View {
        modifier(BounceAnimation())
    }

    /// Aplica animación fade in
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInAnimation(delay: delay))
    }

    /// Aplica animación de rotación continua
    func rotate(duration: Double = 2.0) -> some View {
        modifier(RotatingAnimation(duration: duration))
    }

    /// Aplica efecto de brillo animado
    func glowEffect(color: Color = .white, radius: CGFloat = 10) -> some View {
        modifier(GlowAnimation(color: color, radius: radius))
    }

    /// Aplica animación de shake
    func shake(trigger: Bool) -> some View {
        modifier(ShakeAnimation(trigger: trigger))
    }
}

// MARK: - Componentes Animados

/// Círculo pulsante mejorado
struct AnimatedPulsingCircle: View {
    let color: Color
    let size: CGFloat
    @State private var animate = false

    var body: some View {
        ZStack {
            // Círculo interior con blur
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size, height: size)
                .blur(radius: 5)
                .scaleEffect(animate ? 1.2 : 0.8)

            // Anillo exterior que se expande
            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: size, height: size)
                .scaleEffect(animate ? 1.8 : 1.0)
                .opacity(animate ? 0.0 : 1.0)

            // Segundo anillo con delay
            Circle()
                .stroke(color.opacity(0.5), lineWidth: 2)
                .frame(width: size, height: size)
                .scaleEffect(animate ? 1.5 : 0.8)
                .opacity(animate ? 0.0 : 0.7)
        }
        .onAppear {
            withAnimation(
                .easeOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                animate = true
            }
        }
    }
}

/// Indicador de carga circular
struct LoadingIndicator: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    colors: [.blue, .cyan, .blue],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 30, height: 30)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Preview

#Preview("Pulse Animation") {
    Circle()
        .fill(.blue)
        .frame(width: 50, height: 50)
        .pulseEffect(color: .blue, duration: 1.5)
}

#Preview("Bounce Animation") {
    Image(systemName: "car.fill")
        .font(.system(size: 40))
        .foregroundStyle(.blue)
        .bounceIn()
}

#Preview("Ripple Effect") {
    RippleEffect(color: .blue, count: 3, duration: 2.0)
        .frame(width: 100, height: 100)
}

#Preview("Animated Pulsing Circle") {
    AnimatedPulsingCircle(color: .blue, size: 60)
}

#Preview("Loading Indicator") {
    LoadingIndicator()
}
