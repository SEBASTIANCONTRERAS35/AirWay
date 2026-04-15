//
//  NavigationProgressBar.swift
//  AcessNet
//
//  Barra de progreso de navegación con distancia y ETA restantes
//

import SwiftUI

// MARK: - Navigation Progress Bar

struct NavigationProgressBar: View {
    let progress: Double                 // 0.0 - 1.0
    let distanceRemaining: Double        // Metros
    let eta: TimeInterval                // Segundos
    let averageAQI: Double?              // AQI promedio de la ruta

    var body: some View {
        VStack(spacing: 12) {
            // Barra de progreso visual
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Fondo
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // Progreso
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: progressGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(min(1.0, max(0.0, progress))), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)

            // Información de progreso
            HStack(spacing: 16) {
                // Izquierda: Distancia y ETA
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(distanceRemainingFormatted) remaining")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(etaFormatted)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Derecha: Porcentaje de progreso
                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                    )
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Computed Properties

    /// Distancia restante formateada
    private var distanceRemainingFormatted: String {
        if distanceRemaining < 1000 {
            return "\(Int(distanceRemaining)) m"
        } else {
            return String(format: "%.1f km", distanceRemaining / 1000)
        }
    }

    /// ETA formateado
    private var etaFormatted: String {
        let minutes = Int(eta / 60)

        if minutes < 1 {
            return "< 1 min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }

    /// Colores del gradiente de progreso (basado en AQI promedio de ruta)
    private var progressGradientColors: [Color] {
        guard let aqi = averageAQI else {
            // Por defecto: azul
            return [Color(hex: "#2196F3"), Color(hex: "#1976D2")]
        }

        // Colorear según calidad del aire promedio
        if aqi < 50 {
            // Good - Verde
            return [Color(hex: "#4CAF50"), Color(hex: "#66BB6A")]
        } else if aqi < 100 {
            // Moderate - Amarillo
            return [Color(hex: "#FFC107"), Color(hex: "#FFB300")]
        } else if aqi < 150 {
            // Unhealthy for Sensitive - Naranja
            return [Color(hex: "#FF9800"), Color(hex: "#FF6F00")]
        } else {
            // Unhealthy+ - Rojo
            return [Color(hex: "#F44336"), Color(hex: "#E53935")]
        }
    }
}

// MARK: - Compact Progress Bar (vista reducida)

struct CompactProgressBar: View {
    let progress: Double
    let distanceRemaining: Double
    let eta: TimeInterval

    var body: some View {
        HStack(spacing: 12) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        Color(hex: "#2196F3"),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)

                Text("\(Int(progress * 100))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text(distanceRemainingFormatted)
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                    Text(etaFormatted)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var distanceRemainingFormatted: String {
        if distanceRemaining < 1000 {
            return "\(Int(distanceRemaining))m"
        } else {
            return String(format: "%.1fkm", distanceRemaining / 1000)
        }
    }

    private var etaFormatted: String {
        let minutes = Int(eta / 60)
        if minutes < 1 {
            return "< 1min"
        } else if minutes < 60 {
            return "\(minutes)min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins == 0 ? "\(hours)h" : "\(hours)h\(mins)m"
        }
    }
}

// MARK: - Detailed Progress Info (con estadísticas adicionales)

struct DetailedProgressInfo: View {
    let progress: Double
    let distanceRemaining: Double
    let distanceTraveled: Double
    let eta: TimeInterval
    let averageSpeed: Double?  // km/h
    let averageAQI: Double?

    var body: some View {
        VStack(spacing: 16) {
            // Barra de progreso principal
            NavigationProgressBar(
                progress: progress,
                distanceRemaining: distanceRemaining,
                eta: eta,
                averageAQI: averageAQI
            )

            // Stats grid
            HStack(spacing: 12) {
                // Distancia recorrida
                StatCard(
                    icon: "figure.walk",
                    label: "Traveled",
                    value: distanceTraveledFormatted
                )

                // Velocidad promedio
                if let speed = averageSpeed {
                    StatCard(
                        icon: "speedometer",
                        label: "Avg Speed",
                        value: "\(Int(speed)) km/h"
                    )
                }

                // AQI promedio
                if let aqi = averageAQI {
                    StatCard(
                        icon: "aqi.medium",
                        label: "Avg AQI",
                        value: "\(Int(aqi))",
                        valueColor: aqiColor(for: aqi)
                    )
                }
            }
        }
    }

    private var distanceTraveledFormatted: String {
        if distanceTraveled < 1000 {
            return "\(Int(distanceTraveled)) m"
        } else {
            return String(format: "%.1f km", distanceTraveled / 1000)
        }
    }

    private func aqiColor(for aqi: Double) -> Color {
        if aqi < 50 { return Color(hex: "#4CAF50") }
        else if aqi < 100 { return Color(hex: "#FFC107") }
        else if aqi < 150 { return Color(hex: "#FF9800") }
        else { return Color(hex: "#F44336") }
    }
}

// MARK: - Stat Card Helper

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview("Navigation Progress Bar") {
    VStack(spacing: 20) {
        Text("Progress Bars")
            .font(.title2.bold())
            .padding()

        // 25% progress - Good AQI
        NavigationProgressBar(
            progress: 0.25,
            distanceRemaining: 2300,
            eta: 420,
            averageAQI: 45
        )

        // 60% progress - Moderate AQI
        NavigationProgressBar(
            progress: 0.60,
            distanceRemaining: 850,
            eta: 180,
            averageAQI: 85
        )

        // 90% progress - Unhealthy AQI
        NavigationProgressBar(
            progress: 0.90,
            distanceRemaining: 120,
            eta: 60,
            averageAQI: 165
        )

        Divider()

        // Compact version
        CompactProgressBar(
            progress: 0.45,
            distanceRemaining: 1500,
            eta: 300
        )

        Divider()

        // Detailed version
        DetailedProgressInfo(
            progress: 0.70,
            distanceRemaining: 950,
            distanceTraveled: 2150,
            eta: 240,
            averageSpeed: 32,
            averageAQI: 78
        )

        Spacer()
    }
    .padding()
}
