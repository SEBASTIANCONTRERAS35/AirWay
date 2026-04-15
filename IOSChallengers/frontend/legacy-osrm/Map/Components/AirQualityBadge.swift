//
//  AirQualityBadge.swift
//  AcessNet
//
//  Componentes UI para mostrar calidad del aire
//

import SwiftUI

// MARK: - Air Quality Badge

/// Badge para mostrar el AQI de forma visual
struct AirQualityBadge: View {
    let aqi: Double
    let level: AQILevel
    let compact: Bool

    init(aqi: Double, compact: Bool = false) {
        self.aqi = aqi
        self.level = AQILevel.from(aqi: Int(aqi))
        self.compact = compact
    }

    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }

    private var compactView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(colorForLevel)
                .frame(width: 12, height: 12)

            Text("\(Int(aqi))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var fullView: some View {
        VStack(spacing: 8) {
            // Icono y AQI value
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    colorForLevel.opacity(0.3),
                                    colorForLevel.opacity(0.15),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 15,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                        .blur(radius: 6)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorForLevel.opacity(0.95),
                                    colorForLevel.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: level.routingIcon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AQI \(Int(aqi))")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(level.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(colorForLevel)
                }
            }

            // Health message
            Text(level.extendedHealthMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var colorForLevel: Color {
        switch level {
        case .good: return .green
        case .moderate: return .yellow
        case .poor: return .orange
        case .unhealthy: return .red
        case .severe: return .purple
        case .hazardous: return Color(red: 0.5, green: 0.0, blue: 0.0) // maroon
        }
    }
}

// MARK: - Health Risk Badge

/// Badge para mostrar el riesgo de salud
struct HealthRiskBadge: View {
    let healthRisk: HealthRisk

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: healthRisk.icon)
                .font(.caption)
                .foregroundStyle(colorForRisk)

            Text(healthRisk.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(colorForRisk)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(colorForRisk.opacity(0.12))
        .clipShape(Capsule())
    }

    private var colorForRisk: Color {
        switch healthRisk {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
}

// MARK: - Route Score Badge

/// Badge para mostrar el score de la ruta
struct RouteScoreBadge: View {
    let score: Double
    let maxScore: Double = 100

    var body: some View {
        VStack(spacing: 6) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: score / maxScore)
                    .stroke(
                        AngularGradient(
                            colors: [colorForScore, colorForScore.opacity(0.6)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(score))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(colorForScore)

                    Text("/100")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(scoreDescription)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var colorForScore: Color {
        switch score {
        case 90...100: return .green
        case 75..<90: return .blue
        case 60..<75: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var scoreDescription: String {
        switch score {
        case 90...100: return "Excellent"
        case 75..<90: return "Very Good"
        case 60..<75: return "Good"
        case 40..<60: return "Fair"
        default: return "Poor"
        }
    }
}

// MARK: - PM2.5 Indicator

/// Indicador de partículas PM2.5
struct PM25Indicator: View {
    let pm25: Double

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "aqi.medium")
                .font(.caption)
                .foregroundStyle(colorForPM25)

            VStack(alignment: .leading, spacing: 2) {
                Text("PM2.5")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(String(format: "%.1f μg/m³", pm25))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var colorForPM25: Color {
        switch pm25 {
        case 0..<12: return .green
        case 12..<35: return .yellow
        case 35..<55: return .orange
        default: return .red
        }
    }
}

// MARK: - Route Comparison View

/// Vista para comparar dos rutas
struct RouteComparisonView: View {
    let comparison: RouteComparison

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(comparison.shortDescription)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(comparison.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Air Quality Route Summary

/// Resumen completo de calidad del aire de una ruta
struct AirQualityRouteSummary: View {
    let scoredRoute: ScoredRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: scoredRoute.scoreIcon)
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scoredRoute.scoreDescription)
                        .font(.headline.weight(.semibold))

                    Text(scoredRoute.routeInfo.distanceFormatted + " • " + scoredRoute.routeInfo.timeFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let rank = scoredRoute.rankPosition {
                    Text("#\(rank)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.blue)
                }
            }

            Divider()

            // Air quality metrics
            if let analysis = scoredRoute.airQualityAnalysis {
                HStack(spacing: 16) {
                    // AQI
                    VStack(spacing: 4) {
                        Text("AQI")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(Int(analysis.averageAQI))")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)

                        Text(analysis.averageLevel.rawValue)
                            .font(.caption2)
                            .foregroundStyle(colorForAQI(analysis.averageAQI))
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 50)

                    // PM2.5
                    VStack(spacing: 4) {
                        Text("PM2.5")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(String(format: "%.1f", analysis.averagePM25))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)

                        Text("μg/m³")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 50)

                    // Health Risk
                    VStack(spacing: 4) {
                        Text("Risk")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Image(systemName: analysis.overallHealthRisk.icon)
                            .font(.title3)
                            .foregroundStyle(colorForRisk(analysis.overallHealthRisk))

                        Text(analysis.overallHealthRisk.rawValue)
                            .font(.caption2)
                            .foregroundStyle(colorForRisk(analysis.overallHealthRisk))
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Divider()

            // Scores
            HStack(spacing: 16) {
                // Time score
                VStack(spacing: 4) {
                    Text("Speed")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(Int(scoredRoute.timeScore))/100")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity)

                // Air quality score
                VStack(spacing: 4) {
                    Text("Air Quality")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(Int(scoredRoute.airQualityScore))/100")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)

                // Combined score
                VStack(spacing: 4) {
                    Text("Combined")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(Int(scoredRoute.combinedScore))/100")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.purple)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
    }

    private func colorForAQI(_ aqi: Double) -> Color {
        let level = AQILevel.from(aqi: Int(aqi))
        switch level {
        case .good: return .green
        case .moderate: return .yellow
        case .poor: return .orange
        case .unhealthy: return .red
        case .severe: return .purple
        case .hazardous: return Color(red: 0.5, green: 0.0, blue: 0.0)
        }
    }

    private func colorForRisk(_ risk: HealthRisk) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
}

// MARK: - Preview

#Preview("Air Quality Badges") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Air Quality Indicators").font(.title.bold())

            // AQI Badges - Full
            VStack(spacing: 15) {
                AirQualityBadge(aqi: 35)   // Good
                AirQualityBadge(aqi: 75)   // Moderate
                AirQualityBadge(aqi: 125)  // Unhealthy for Sensitive
                AirQualityBadge(aqi: 175)  // Unhealthy
            }

            Divider()

            // Compact badges
            HStack(spacing: 12) {
                AirQualityBadge(aqi: 45, compact: true)
                AirQualityBadge(aqi: 85, compact: true)
                AirQualityBadge(aqi: 135, compact: true)
            }

            Divider()

            // Health Risk Badges
            HStack(spacing: 12) {
                HealthRiskBadge(healthRisk: .low)
                HealthRiskBadge(healthRisk: .medium)
                HealthRiskBadge(healthRisk: .high)
                HealthRiskBadge(healthRisk: .veryHigh)
            }

            Divider()

            // Route Score Badges
            HStack(spacing: 20) {
                RouteScoreBadge(score: 95)
                RouteScoreBadge(score: 72)
                RouteScoreBadge(score: 45)
            }

            Divider()

            // PM2.5 Indicators
            HStack(spacing: 12) {
                PM25Indicator(pm25: 8.5)
                PM25Indicator(pm25: 25.3)
                PM25Indicator(pm25: 45.7)
            }
        }
        .padding()
    }
}
