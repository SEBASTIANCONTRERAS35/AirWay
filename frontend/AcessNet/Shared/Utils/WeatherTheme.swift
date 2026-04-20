//
//  WeatherTheme.swift
//  AcessNet
//
//  Colores dinámicos que cambian según el clima
//

import SwiftUI

// MARK: - Environment Key

private struct WeatherThemeKey: EnvironmentKey {
    static let defaultValue = WeatherTheme(condition: .overcast)
}

extension EnvironmentValues {
    var weatherTheme: WeatherTheme {
        get { self[WeatherThemeKey.self] }
        set { self[WeatherThemeKey.self] = newValue }
    }
}

// MARK: - Theme

struct WeatherTheme {
    let condition: WeatherCondition
    /// Si true, ignora la condición climática y usa la paleta de marca AirWay (sincronizada con la página web).
    let isAirWay: Bool

    init(condition: WeatherCondition = .overcast, isAirWay: Bool = false) {
        self.condition = condition
        self.isAirWay = isAirWay
    }

    // Card background
    var cardColor: Color {
        // AirWay surface: #121A30 @ 68% (sincronizado con --color-aw-surface de la web)
        if isAirWay { return Color(hex: "#121A30").opacity(0.68) }
        switch condition {
        case .sunny:  return Color(hex: "#1E3858")
        case .cloudy: return Color(hex: "#282E3E")
        case .overcast: return Color(hex: "#242A35")
        case .rainy:  return Color(hex: "#1E2A48")
        case .stormy: return Color(hex: "#281A40")
        }
    }

    // Card border
    var borderColor: Color {
        if isAirWay { return .white.opacity(0.08) }
        switch condition {
        case .sunny:  return .white.opacity(0.18)
        case .cloudy: return .white.opacity(0.12)
        case .overcast: return .white.opacity(0.10)
        case .rainy:  return .white.opacity(0.14)
        case .stormy: return .white.opacity(0.12)
        }
    }

    // Accent color
    var accent: Color {
        if isAirWay { return Color(hex: "#0099FF") }
        switch condition {
        case .sunny:  return Color(hex: "#FFB830")
        case .cloudy: return Color(hex: "#8EACC0")
        case .overcast: return Color(hex: "#7A8A9A")
        case .rainy:  return Color(hex: "#5080C0")
        case .stormy: return Color(hex: "#8060C0")
        }
    }

    // Page background (for subviews without WeatherBackground)
    var pageBackground: Color {
        if isAirWay { return Color(hex: "#060A18") }
        switch condition {
        case .sunny:  return Color(hex: "#0E1E30")
        case .cloudy: return Color(hex: "#0E1218")
        case .overcast: return Color(hex: "#0C1018")
        case .rainy:  return Color(hex: "#0A1020")
        case .stormy: return Color(hex: "#0A0610")
        }
    }

    // Text tint (subtle warm/cool shift)
    var textTint: Color {
        if isAirWay { return Color(hex: "#F5F9FF") }
        switch condition {
        case .sunny:  return Color(hex: "#FFF5E0")
        case .cloudy: return .white
        case .overcast: return .white
        case .rainy:  return Color(hex: "#E0EEFF")
        case .stormy: return Color(hex: "#E8E0FF")
        }
    }
}
