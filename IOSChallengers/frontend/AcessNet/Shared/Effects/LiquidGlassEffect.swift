//
//  LiquidGlassEffect.swift
//  AcessNet
//
//  Custom blur effects para liquid glass morphism
//

import SwiftUI
import UIKit

// MARK: - Visual Effect Blur

/// Custom blur effect usando UIVisualEffectView para mayor control
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var vibrancy: Bool = false

    func makeUIView(context: Context) -> UIVisualEffectView {
        let effect = UIBlurEffect(style: blurStyle)
        let view = UIVisualEffectView(effect: effect)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if vibrancy {
            let vibrancyEffect = UIVibrancyEffect(blurEffect: effect)
            let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyView.frame = view.bounds
            vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.contentView.addSubview(vibrancyView)
        }

        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        let effect = UIBlurEffect(style: blurStyle)
        uiView.effect = effect
    }
}

// MARK: - Liquid Glass Modifier

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 28
    var intensity: Double = 0.7

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // CAPA 1: Base ultra blur
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // CAPA 2: Blur custom intenso
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .overlay(
                            VisualEffectBlur(
                                blurStyle: .systemChromeMaterial,
                                vibrancy: true
                            )
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        )
                        .opacity(intensity)

                    // CAPA 3: Gradiente de refracción
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.25),
                                    .clear,
                                    .white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // CAPA 4: Shimmer overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                center: .topLeading,
                                startRadius: 20,
                                endRadius: 150
                            )
                        )

                    // CAPA 5: Glass overlay mejorado
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.2),
                                    .white.opacity(0.08),
                                    .white.opacity(0.15)
                                ],
                                startPoint: UnitPoint(x: 0, y: 0),
                                endPoint: UnitPoint(x: 1, y: 1)
                            )
                        )

                    // CAPA 6: Inner glow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.8),
                                    .white.opacity(0.4),
                                    .white.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                        .blur(radius: 1)

                    // CAPA 7: Glossy border brillante
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.9),
                                    .white.opacity(0.3),
                                    .white.opacity(0.6),
                                    .white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
    }
}

// MARK: - View Extension

extension View {
    /// Aplica efecto liquid glass al view
    func liquidGlass(cornerRadius: CGFloat = 28, intensity: Double = 0.7) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, intensity: intensity))
    }
}
