//
//  HapticFeedback.swift
//  AcessNet
//
//  Sistema unificado de feedback háptico para micro-interacciones
//

import UIKit
import SwiftUI

// MARK: - Haptic Feedback Manager

struct HapticFeedback {

    // MARK: - Impact Feedback

    /// Feedback ligero para interacciones sutiles (botones secundarios, gestos)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Feedback medio para interacciones estándar (botones primarios, confirmaciones)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Feedback pesado para interacciones importantes (acciones destructivas, alertas)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Feedback rígido para interacciones precisas
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    /// Feedback suave para interacciones delicadas
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Feedback de éxito
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Feedback de advertencia
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Feedback de error
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Feedback de selección (para pickers, segmented controls)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Custom Patterns

    /// Doble tap ligero
    static func doubleTap() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            light()
        }
    }

    /// Patrón de confirmación (medio + ligero)
    static func confirm() {
        medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            light()
        }
    }

    /// Patrón de cancelación (ligero + ligero con delay)
    static func cancel() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            light()
        }
    }
}

// MARK: - View Modifiers para Haptic Feedback

/// Modifier para agregar feedback háptico a cualquier botón
struct HapticButtonModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    let action: () -> Void

    func body(content: Content) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
            action()
        }) {
            content
        }
    }
}

extension View {
    /// Convierte una vista en un botón con feedback háptico
    func hapticButton(
        style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        action: @escaping () -> Void
    ) -> some View {
        modifier(HapticButtonModifier(style: style, action: action))
    }
}

// MARK: - Gesture Modifiers con Haptic Feedback

extension View {

    /// Tap gesture con feedback háptico
    func hapticTapGesture(
        count: Int = 1,
        feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onTapGesture(count: count) {
            let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
            generator.impactOccurred()
            action()
        }
    }

    /// Long press gesture con feedback háptico al inicio
    func hapticLongPressGesture(
        minimumDuration: Double = 0.5,
        feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onLongPressGesture(minimumDuration: minimumDuration) {
            let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
            generator.impactOccurred()
            action()
        }
    }
}

// MARK: - Animated Press Effect con Haptic

struct AnimatedPressEffect: ViewModifier {
    @State private var isPressed = false
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let scaleEffect: CGFloat
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scaleEffect : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                            generator.impactOccurred()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
    }
}

extension View {
    /// Agrega efecto de presión animado con feedback háptico
    func animatedPress(
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        scaleEffect: CGFloat = 0.95,
        action: @escaping () -> Void
    ) -> some View {
        modifier(AnimatedPressEffect(hapticStyle: hapticStyle, scaleEffect: scaleEffect, action: action))
    }
}

// MARK: - Contextual Haptic Feedback

/// Feedback contextual basado en el tipo de acción
enum HapticAction {
    case buttonPress
    case buttonPrimaryPress
    case buttonDestructivePress
    case navigationBack
    case navigationForward
    case mapInteraction
    case routeCalculated
    case alertAdded
    case searchResultSelected
    case menuToggle

    func trigger() {
        switch self {
        case .buttonPress:
            HapticFeedback.light()
        case .buttonPrimaryPress:
            HapticFeedback.medium()
        case .buttonDestructivePress:
            HapticFeedback.heavy()
        case .navigationBack:
            HapticFeedback.soft()
        case .navigationForward:
            HapticFeedback.light()
        case .mapInteraction:
            HapticFeedback.light()
        case .routeCalculated:
            HapticFeedback.confirm()
        case .alertAdded:
            HapticFeedback.success()
        case .searchResultSelected:
            HapticFeedback.selection()
        case .menuToggle:
            HapticFeedback.medium()
        }
    }
}

// MARK: - Micro-Interaction Animations

struct MicroInteractions {

    /// Escala de pulso para elementos interactivos
    static func pulseScale(isActive: Bool) -> CGFloat {
        isActive ? 1.05 : 1.0
    }

    /// Escala de press para botones
    static func pressScale(isPressed: Bool) -> CGFloat {
        isPressed ? 0.95 : 1.0
    }

    /// Opacidad hover para elementos interactivos
    static func hoverOpacity(isHovered: Bool) -> Double {
        isHovered ? 0.8 : 1.0
    }

    /// Spring animation standard para micro-interacciones
    static let spring = Animation.spring(
        response: 0.4,
        dampingFraction: 0.8
    )

    /// Spring animation rápida
    static let springFast = Animation.spring(
        response: 0.25,
        dampingFraction: 0.65
    )

    /// Spring animation suave
    static let springSmooth = Animation.spring(
        response: 0.4,
        dampingFraction: 0.75
    )
}

// MARK: - Interactive Button Styles

struct HapticButtonStyle: ButtonStyle {
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let scaleEffect: CGFloat

    init(
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        scaleEffect: CGFloat = 0.95
    ) {
        self.hapticStyle = hapticStyle
        self.scaleEffect = scaleEffect
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { newValue in
                if newValue {
                    let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                    generator.impactOccurred()
                }
            }
    }
}

extension ButtonStyle where Self == HapticButtonStyle {
    /// Estilo de botón con feedback háptico
    static func haptic(
        style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        scale: CGFloat = 0.95
    ) -> HapticButtonStyle {
        HapticButtonStyle(hapticStyle: style, scaleEffect: scale)
    }
}
