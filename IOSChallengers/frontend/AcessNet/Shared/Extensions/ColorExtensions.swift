//
//  ColorExtensions.swift
//  AcessNet
//
//  Sistema de colores cohesivo para toda la app
//

import SwiftUI

// MARK: - Design System Colors

extension Color {

    // MARK: - Hex Color Initializer

    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Primary Colors

    /// Color principal de la app (azul)
    static let appPrimary = Color.blue

    /// Color secundario de la app (cyan)
    static let appSecondary = Color.cyan

    /// Color de acento (púrpura)
    static let appAccent = Color.purple

    // MARK: - Map Colors

    /// Color para rutas activas
    static let routeActive = Color.blue

    /// Color para usuario en movimiento
    static let userMoving = Color.cyan

    /// Color para usuario estático
    static let userStatic = Color.blue

    // MARK: - Alert Colors (por tipo)

    static let alertTraffic = Color.red
    static let alertHazard = Color.yellow
    static let alertAccident = Color.orange
    static let alertPedestrian = Color.blue
    static let alertPolice = Color.indigo
    static let alertRoadWork = Color.orange

    // MARK: - UI Element Colors

    /// Color para indicadores de éxito (estilo de la app)
    static let appSuccess = Color.green

    /// Color para indicadores de advertencia (estilo de la app)
    static let appWarning = Color.orange

    /// Color para botones primarios
    static let buttonPrimary = Color.blue

    /// Color para botones secundarios
    static let buttonSecondary = Color.gray

    /// Color para botones de acción destructiva
    static let buttonDestructive = Color.red

    /// Color para indicadores de error
    static let error = Color.red

    // MARK: - Opacity Levels (Sistema cohesivo de opacidades)

    /// Opacidad extra baja (5%)
    static let opacityExtraLight: Double = 0.05

    /// Opacidad baja (10-15%)
    static let opacityLight: Double = 0.12

    /// Opacidad media baja (20-25%)
    static let opacityMediumLight: Double = 0.20

    /// Opacidad media (40-50%)
    static let opacityMedium: Double = 0.40

    /// Opacidad media alta (60-70%)
    static let opacityMediumHigh: Double = 0.65

    /// Opacidad alta (80-85%)
    static let opacityHigh: Double = 0.80

    /// Opacidad extra alta (90-95%)
    static let opacityExtraHigh: Double = 0.90

    // MARK: - AirWay Design Tokens (sincronizados con la web)

    /// Fondo base oscuro (navy casi negro)
    static let awBg = Color(hex: "#060A18")
    /// Fondo elevado (cards, sheets sobre el bg)
    static let awBgElev = Color(hex: "#0D1427")
    /// Primary marca (azul marino profundo)
    static let awPrimary = Color(hex: "#0A1D4D")
    /// Accent (cian vibrante, highlights interactivos)
    static let awAccent = Color(hex: "#0099FF")
    /// Superficie glass sobre fondo oscuro (~68% alpha)
    static let awSurface = Color(hex: "#121A30").opacity(0.68)
    /// Superficie hover/activa
    static let awSurfaceHover = Color(hex: "#16203A").opacity(0.88)

    /// Texto primario sobre fondo oscuro (blanco frío)
    static let awInk = Color(hex: "#F5F9FF")
    /// Texto secundario (subtítulos, etiquetas)
    static let awInkSoft = Color(hex: "#C5CDE0")
    /// Texto terciario (hints, metadata)
    static let awInkMuted = Color(hex: "#8A95B5")

    /// Borde sutil sobre superficies oscuras
    static let awBorder = Color.white.opacity(0.08)
    /// Borde más marcado (estados activos)
    static let awBorderStrong = Color.white.opacity(0.16)

    // MARK: - Shadow Colors

    /// Sombra para elementos elevados (botones, cards)
    static var shadowElevated: Color {
        Color.black.opacity(0.15)
    }

    /// Sombra para elementos muy elevados
    static var shadowHighElevation: Color {
        Color.black.opacity(0.25)
    }

    /// Sombra sutil para elementos flotantes
    static var shadowSubtle: Color {
        Color.black.opacity(0.08)
    }
}

// MARK: - Gradient Presets

extension LinearGradient {

    /// Gradiente primario de la app (azul)
    static let appPrimary = LinearGradient(
        colors: [
            Color.blue.opacity(0.95),
            Color.blue.opacity(0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradiente para rutas
    static let routeGradient = LinearGradient(
        colors: [
            Color.blue.opacity(0.8),
            Color.cyan.opacity(0.7),
            Color.blue.opacity(0.8)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Fondo base AirWay (siempre igual, independiente del clima)
    static let airWayBase = LinearGradient(
        stops: [
            .init(color: Color.awBg,      location: 0.00),
            .init(color: Color.awBgElev,  location: 0.45),
            .init(color: Color.awPrimary, location: 1.00)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Gradiente para glassmorphism (elementos con efecto de vidrio)
    static let glassEffect = LinearGradient(
        colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradiente para bordes brillantes
    static let glossyBorder = LinearGradient(
        colors: [
            Color.white.opacity(0.9),
            Color.white.opacity(0.4)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Radial Gradient Presets

extension RadialGradient {

    /// Glow effect para elementos destacados
    static func glowEffect(color: Color, intensity: Double = 0.4) -> RadialGradient {
        RadialGradient(
            colors: [
                color.opacity(intensity),
                color.opacity(intensity * 0.5),
                .clear
            ],
            center: .center,
            startRadius: 20,
            endRadius: 35
        )
    }

    /// Shadow effect circular
    static func circularShadow(color: Color) -> RadialGradient {
        RadialGradient(
            colors: [
                color.opacity(0.4),
                color.opacity(0.2),
                .clear
            ],
            center: .center,
            startRadius: 15,
            endRadius: 35
        )
    }
}

// MARK: - Helper Extensions

extension View {

    /// Aplica el estilo de glassmorphism estándar de la app
    func appGlassmorphism(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient.glassEffect)
                }
            )
    }

    /// Aplica sombra elevada estándar
    func appElevatedShadow(radius: CGFloat = 15, y: CGFloat = 5) -> some View {
        self
            .shadow(color: Color.shadowElevated, radius: radius, x: 0, y: y)
            .shadow(color: Color.shadowSubtle, radius: 4, x: 0, y: 2)
    }

    /// Aplica sombra con color personalizado
    func coloredShadow(color: Color, intensity: Double = 0.4, radius: CGFloat = 12, y: CGFloat = 6) -> some View {
        self
            .shadow(color: color.opacity(intensity), radius: radius, x: 0, y: y)
            .shadow(color: Color.shadowSubtle, radius: 3, x: 0, y: 2)
    }
}

// MARK: - Design Tokens (Valores reutilizables)

struct DesignTokens {

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacingXXL: CGFloat = 24

    // MARK: - Corner Radius

    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
    static let radiusL: CGFloat = 16
    static let radiusXL: CGFloat = 20
    static let radiusXXL: CGFloat = 28
    static let radiusFull: CGFloat = 999

    // MARK: - Border Width

    static let borderThin: CGFloat = 1
    static let borderMedium: CGFloat = 2
    static let borderThick: CGFloat = 3

    // MARK: - Icon Sizes

    static let iconXS: CGFloat = 12
    static let iconS: CGFloat = 16
    static let iconM: CGFloat = 20
    static let iconL: CGFloat = 24
    static let iconXL: CGFloat = 28

    // MARK: - Animation Durations

    static let animationFast: Double = 0.2
    static let animationNormal: Double = 0.3
    static let animationSlow: Double = 0.5
    static let animationVerySlow: Double = 1.0

    // MARK: - Spring Animation Parameters

    static let springResponse: Double = 0.3
    static let springDamping: Double = 0.7
}

