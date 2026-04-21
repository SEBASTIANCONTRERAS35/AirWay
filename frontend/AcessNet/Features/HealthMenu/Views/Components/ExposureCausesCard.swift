//
//  ExposureCausesCard.swift
//  AcessNet
//
//  Tarjeta narrativa que explica POR QUÉ los órganos del usuario están en ese
//  estado. Muestra causas reales: cigarrillos equivalentes por PM2.5, dosis
//  acumulada, horas en mal aire, y correlación con biometría del Watch.
//

import SwiftUI

struct ExposureCausesCard: View {
    @Environment(\.weatherTheme) private var theme

    let cigarettes: Double
    let pm25DoseUg: Double
    let badAirHours: Double
    let heartRate: Double?
    let spO2: Double?
    let aqi: Int
    let organWorstLabel: String
    let organWorstDamage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            cigaretteHero
            metricsGrid
            explanationFooter
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#FF5B5B").opacity(0.45),
                                    Color(hex: "#FF8A3D").opacity(0.25),
                                    Color(hex: "#FF5B5B").opacity(0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color(hex: "#FF5B5B").opacity(0.18), radius: 14, y: 6)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.bubble.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#FF8A3D"))
            VStack(alignment: .leading, spacing: 1) {
                Text("POR QUÉ ESTÁS ASÍ")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.8)
                    .foregroundColor(theme.textTint.opacity(0.55))
                Text(headlineText)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.textTint)
            }
            Spacer()
        }
    }

    private var headlineText: String {
        switch organWorstDamage {
        case ..<0.25: return "Tu exposición de hoy ha sido leve"
        case ..<0.50: return "Has acumulado exposición moderada"
        case ..<0.75: return "Tu cuerpo está procesando mucho daño"
        default:      return "Exposición severa detectada"
        }
    }

    // MARK: - Cigarette hero

    private var cigaretteHero: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF5B5B"), Color(hex: "#FF8A3D")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .shadow(color: Color(hex: "#FF5B5B").opacity(0.5), radius: 8)
                Image(systemName: "smoke.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", cigarettes))
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.textTint)
                        .monospacedDigit()
                    Text("cigarros")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.textTint.opacity(0.65))
                }
                Text("equivalentes hoy por PM2.5 inhalada")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.textTint.opacity(0.55))
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#FF5B5B").opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#FF5B5B").opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Metrics grid

    private var metricsGrid: some View {
        HStack(spacing: 10) {
            metricCell(
                icon: "aqi.medium",
                tint: aqiTint,
                value: "\(aqi)",
                label: "AQI actual",
                sub: aqiDescription
            )
            metricCell(
                icon: "aqi.low",
                tint: Color(hex: "#F472B6"),
                value: String(format: "%.0fh", badAirHours),
                label: "En aire malo",
                sub: "AQI > 100 hoy"
            )
            metricCell(
                icon: "wind",
                tint: Color(hex: "#7DD3FC"),
                value: String(format: "%.0f", pm25DoseUg),
                label: "µg PM2.5",
                sub: "inhalados"
            )
        }
    }

    private func metricCell(icon: String, tint: Color, value: String, label: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(tint)

            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(theme.textTint)
                .monospacedDigit()

            Text(sub)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(theme.textTint.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tint.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                )
        )
    }

    // MARK: - Explanation footer

    private var explanationFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 10, weight: .semibold))
                Text("¿POR QUÉ?")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.5)
            }
            .foregroundColor(theme.textTint.opacity(0.5))

            Text(detailedExplanation)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.textTint.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(.top, 2)
    }

    private var detailedExplanation: String {
        var parts: [String] = []

        // Causa principal según PM2.5
        if cigarettes > 2 {
            parts.append("Respiraste \(String(format: "%.0f", pm25DoseUg)) µg de PM2.5 — equivalente a \(String(format: "%.1f", cigarettes)) cigarros.")
        } else if badAirHours > 1 {
            parts.append("Estuviste \(String(format: "%.0f", badAirHours))h en aire con AQI > 100.")
        }

        // Biometría si hay
        if let hr = heartRate, hr > 85 {
            parts.append("Tu HR está elevado (\(Int(hr)) bpm) — el PM2.5 causa vasoconstricción.")
        }
        if let spo2 = spO2, spo2 < 96 {
            parts.append("SpO₂ en \(Int(spo2))% — tus pulmones están filtrando partículas.")
        }

        // Mensaje por órgano más afectado
        switch organWorstDamage {
        case ..<0.25:
            break
        case ..<0.50:
            parts.append("Tu \(organWorstLabel.lowercased()) muestra irritación leve que se resolverá al descansar.")
        case ..<0.75:
            parts.append("Tu \(organWorstLabel.lowercased()) está inflamado — evita ejercicio al aire libre.")
        default:
            parts.append("Tu \(organWorstLabel.lowercased()) requiere recuperación inmediata — busca espacios cerrados con filtro.")
        }

        return parts.isEmpty
            ? "Tu cuerpo está limpio hoy. Mantén los hábitos saludables."
            : parts.joined(separator: " ")
    }

    // MARK: - Helpers

    private var aqiTint: Color {
        switch aqi {
        case ..<51:   return Color(hex: "#4ADE80")
        case ..<101:  return Color(hex: "#F4B942")
        case ..<151:  return Color(hex: "#FF8A3D")
        case ..<201:  return Color(hex: "#FF5B5B")
        default:      return Color(hex: "#8B5CF6")
        }
    }

    private var aqiDescription: String {
        switch aqi {
        case ..<51:   return "bueno"
        case ..<101:  return "moderado"
        case ..<151:  return "malo"
        case ..<201:  return "muy malo"
        default:      return "peligroso"
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0A0A0F").ignoresSafeArea()
        ExposureCausesCard(
            cigarettes: 2.4,
            pm25DoseUg: 52,
            badAirHours: 4.5,
            heartRate: 92,
            spO2: 94,
            aqi: 168,
            organWorstLabel: "Pulmones",
            organWorstDamage: 0.62
        )
        .padding(20)
    }
}
