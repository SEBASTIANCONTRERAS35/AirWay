//
//  AirQualityLegendView.swift
//  AcessNet
//
//  Leyenda interactiva para mostrar niveles de calidad del aire
//

import SwiftUI

// MARK: - Air Quality Legend View

/// Leyenda flotante que muestra los niveles de calidad del aire
struct AirQualityLegendView: View {
    @Binding var isExpanded: Bool
    let statistics: AirQualityGridManager.GridStatistics?

    @State private var glowIntensity: Double = 0.3

    var body: some View {
        VStack(spacing: 0) {
            // Header compacto (siempre visible)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    // Icono pulsante
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .blue.opacity(glowIntensity),
                                        .blue.opacity(glowIntensity * 0.5),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 8,
                                    endRadius: 18
                                )
                            )
                            .frame(width: 36, height: 36)
                            .blur(radius: 4)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.95), .blue.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "aqi.medium")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Air Quality")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let stats = statistics {
                            Text("AQI \(Int(stats.averageAQI))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }

            // Contenido expandido
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()

                    // Niveles de AQI
                    VStack(spacing: 8) {
                        ForEach(AQILevel.allCases, id: \.self) { level in
                            AirQualityLegendRow(
                                level: level,
                                count: count(for: level)
                            )
                        }
                    }

                    // Estadísticas generales
                    if let stats = statistics {
                        Divider()

                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text("\(stats.totalZones)")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.primary)

                                Text("Zones")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)

                            Divider()
                                .frame(height: 30)

                            VStack(spacing: 4) {
                                Text("\(Int(stats.averageAQI))")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(colorForAQI(stats.averageAQI))

                                Text("Avg AQI")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 5)
        .onAppear {
            startGlowAnimation()
        }
    }

    // MARK: - Helper Methods

    private func count(for level: AQILevel) -> Int {
        guard let stats = statistics else { return 0 }

        switch level {
        case .good: return stats.goodCount
        case .moderate: return stats.moderateCount
        case .poor: return stats.poorCount
        case .unhealthy: return stats.unhealthyCount
        case .severe: return stats.severeCount
        case .hazardous: return stats.hazardousCount
        }
    }

    private func colorForAQI(_ aqi: Double) -> Color {
        let level = AQILevel.from(aqi: Int(aqi))
        switch level {
        case .good: return Color(hex: "#7BC043")
        case .moderate: return Color(hex: "#F9A825")
        case .poor: return Color(hex: "#FF6F00")
        case .unhealthy: return Color(hex: "#E53935")
        case .severe: return Color(hex: "#8E24AA")
        case .hazardous: return Color(hex: "#6A1B4D")
        }
    }

    private func startGlowAnimation() {
        withAnimation(
            .easeInOut(duration: 1.8)
            .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 0.5
        }
    }
}

// MARK: - Air Quality Legend Row

/// Fila individual de la leyenda
struct AirQualityLegendRow: View {
    let level: AQILevel
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            // Color indicator
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 1)

            // Level name
            Text(level.rawValue)
                .font(.caption)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Count badge
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.8))
                    .clipShape(Capsule())
            } else {
                Text("-")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(count > 0 ? color.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var color: Color {
        switch level {
        case .good: return Color(hex: "#7BC043")
        case .moderate: return Color(hex: "#F9A825")
        case .poor: return Color(hex: "#FF6F00")
        case .unhealthy: return Color(hex: "#E53935")
        case .severe: return Color(hex: "#8E24AA")
        case .hazardous: return Color(hex: "#6A1B4D")
        }
    }
}

// MARK: - Compact Air Quality Indicator

/// Indicador compacto de calidad del aire (para cuando no hay espacio)
struct CompactAirQualityIndicator: View {
    let averageAQI: Double
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("AQI \(Int(averageAQI))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isActive ? .primary : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .opacity(isActive ? 1.0 : 0.6)
    }

    private var color: Color {
        let level = AQILevel.from(aqi: Int(averageAQI))
        switch level {
        case .good: return Color(hex: "#7BC043")
        case .moderate: return Color(hex: "#F9A825")
        case .poor: return Color(hex: "#FF6F00")
        case .unhealthy: return Color(hex: "#E53935")
        case .severe: return Color(hex: "#8E24AA")
        case .hazardous: return Color(hex: "#6A1B4D")
        }
    }
}

// MARK: - Preview

#Preview("Air Quality Legend") {
    VStack(spacing: 20) {
        Text("Legend Views").font(.title.bold())

        // Leyenda expandida
        AirQualityLegendView(
            isExpanded: .constant(true),
            statistics: AirQualityGridManager.GridStatistics(
                totalZones: 49,
                averageAQI: 75,
                goodCount: 12,
                moderateCount: 18,
                poorCount: 10,
                unhealthyCount: 6,
                severeCount: 2,
                hazardousCount: 1
            )
        )
        .frame(maxWidth: 300)

        // Leyenda colapsada
        AirQualityLegendView(
            isExpanded: .constant(false),
            statistics: AirQualityGridManager.GridStatistics(
                totalZones: 49,
                averageAQI: 75,
                goodCount: 12,
                moderateCount: 18,
                poorCount: 10,
                unhealthyCount: 6,
                severeCount: 2,
                hazardousCount: 1
            )
        )
        .frame(maxWidth: 300)

        // Indicador compacto
        HStack(spacing: 12) {
            CompactAirQualityIndicator(averageAQI: 45, isActive: true)
            CompactAirQualityIndicator(averageAQI: 95, isActive: true)
            CompactAirQualityIndicator(averageAQI: 155, isActive: false)
        }
    }
    .padding()
}
