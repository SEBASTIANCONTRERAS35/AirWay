//
//  WeatherSimTheme.swift
//  AcessNet
//
//  Temas visuales por condición climática simulada.
//  El modo `airWay` usa la paleta de la página web (navy + cian accent).
//

import SwiftUI

enum WeatherSimMode: String, CaseIterable, Identifiable {
    case airWay
    case sunny
    case cloudy
    case overcast
    case rainy
    case stormy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .airWay:   return "AirWay"
        case .sunny:    return "Sunny"
        case .cloudy:   return "Cloudy"
        case .overcast: return "Overcast"
        case .rainy:    return "Rainy"
        case .stormy:   return "Stormy"
        }
    }

    var sfIcon: String {
        switch self {
        case .airWay:   return "sparkles"
        case .sunny:    return "sun.max.fill"
        case .cloudy:   return "cloud.sun.fill"
        case .overcast: return "cloud.fill"
        case .rainy:    return "cloud.rain.fill"
        case .stormy:   return "cloud.bolt.rain.fill"
        }
    }

    /// Gradient de fondo para el tema
    var backgroundGradient: LinearGradient {
        switch self {
        case .airWay:
            return LinearGradient(
                stops: [
                    .init(color: rgb(6, 10, 24),    location: 0.00),
                    .init(color: rgb(13, 20, 39),   location: 0.45),
                    .init(color: rgb(10, 29, 77),   location: 1.00)
                ],
                startPoint: .top, endPoint: .bottom
            )
        case .sunny:
            return LinearGradient(
                colors: [rgb(59, 166, 255), rgb(107, 198, 255), rgb(255, 209, 128)],
                startPoint: .top, endPoint: .bottom
            )
        case .cloudy:
            return LinearGradient(
                colors: [rgb(74, 106, 138), rgb(106, 138, 168), rgb(147, 175, 199)],
                startPoint: .top, endPoint: .bottom
            )
        case .overcast:
            return LinearGradient(
                colors: [rgb(55, 72, 92), rgb(78, 99, 119), rgb(107, 126, 145)],
                startPoint: .top, endPoint: .bottom
            )
        case .rainy:
            return LinearGradient(
                colors: [rgb(30, 45, 69), rgb(44, 68, 96), rgb(63, 92, 122)],
                startPoint: .top, endPoint: .bottom
            )
        case .stormy:
            return LinearGradient(
                colors: [rgb(14, 21, 36), rgb(26, 36, 54), rgb(42, 52, 71)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    /// Color de acento
    var accent: Color {
        switch self {
        case .airWay:   return rgb(0, 153, 255)
        case .sunny:    return rgb(255, 179, 0)
        case .cloudy:   return .white
        case .overcast: return rgb(184, 197, 209)
        case .rainy:    return rgb(127, 194, 255)
        case .stormy:   return rgb(255, 212, 0)
        }
    }

    /// Texto primario
    var ink: Color {
        switch self {
        case .airWay:   return rgb(245, 249, 255)
        case .sunny:    return rgb(11, 30, 58)
        default:        return .white
        }
    }

    /// Texto secundario
    var inkSoft: Color {
        switch self {
        case .airWay:   return rgb(197, 205, 224)
        case .sunny:    return rgb(46, 62, 87).opacity(0.85)
        default:        return .white.opacity(0.85)
        }
    }

    /// Texto terciario
    var inkMuted: Color {
        switch self {
        case .airWay:   return rgb(138, 149, 181)
        case .sunny:    return rgb(46, 62, 87).opacity(0.6)
        default:        return .white.opacity(0.6)
        }
    }

    /// Superficie glass para cards
    var surface: Color {
        switch self {
        case .airWay:   return rgb(18, 26, 48).opacity(0.68)
        case .sunny:    return Color.white.opacity(0.35)
        default:        return Color.white.opacity(0.15)
        }
    }

    /// Borde sutil
    var border: Color {
        switch self {
        case .airWay:   return Color.white.opacity(0.08)
        case .sunny:    return rgb(11, 30, 58).opacity(0.12)
        default:        return Color.white.opacity(0.2)
        }
    }

    /// Borde más marcado
    var borderStrong: Color {
        switch self {
        case .airWay:   return Color.white.opacity(0.16)
        case .sunny:    return rgb(11, 30, 58).opacity(0.24)
        default:        return Color.white.opacity(0.35)
        }
    }

    private func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(.sRGB, red: r / 255.0, green: g / 255.0, blue: b / 255.0, opacity: 1.0)
    }
}
