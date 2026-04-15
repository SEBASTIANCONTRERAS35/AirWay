//
//  BreathabilityIndexView.swift
//  AcessNet
//
//  Indicador visual de "respirabilidad" del aire con animación de pulmones
//

import SwiftUI

// MARK: - Breathability Index View

/// Vista que muestra qué tan respirable está el aire con visualización de pulmones
struct BreathabilityIndexView: View {
    let averageAQI: Double
    let dominantLevel: AQILevel

    @State private var breathingPhase: CGFloat = 0
    @State private var glowIntensity: Double = 0.3

    var body: some View {
        HStack(spacing: 16) {
            // Animated lungs
            animatedLungs

            // Breathability info
            VStack(alignment: .leading, spacing: 6) {
                Text("Breathability")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(breathabilityDescription)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(breathabilityColor)

                Text(breathabilityDetail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Score indicator
            scoreIndicator
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                breathabilityColor.opacity(0.1),
                                breathabilityColor.opacity(0.05),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(breathabilityColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: breathabilityColor.opacity(0.2), radius: 12, x: 0, y: 6)
        .onAppear {
            startBreathingAnimation()
            startGlowAnimation()
        }
    }

    // MARK: - Animated Lungs

    private var animatedLungs: some View {
        ZStack {
            // Glow background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            breathabilityColor.opacity(glowIntensity),
                            breathabilityColor.opacity(glowIntensity * 0.5),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 10)

            // Lungs icon with breathing animation
            ZStack {
                // Background circle
                Circle()
                    .fill(breathabilityColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .scaleEffect(1.0 + breathingPhase * 0.1)

                // Lungs icon
                Image(systemName: "lungs.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                breathabilityColor,
                                breathabilityColor.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(1.0 + breathingPhase * 0.15)

                // Breathing particles
                ForEach(0..<3) { i in
                    Circle()
                        .fill(breathabilityColor.opacity(0.4))
                        .frame(width: 4, height: 4)
                        .offset(y: -30 - (breathingPhase * 20))
                        .opacity(1.0 - breathingPhase)
                        .blur(radius: 1)
                        .offset(x: CGFloat(i - 1) * 8)
                }
            }
        }
    }

    // MARK: - Score Indicator

    private var scoreIndicator: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 50, height: 50)

            // Progress ring
            Circle()
                .trim(from: 0, to: breathabilityScore / 100)
                .stroke(
                    AngularGradient(
                        colors: [
                            breathabilityColor,
                            breathabilityColor.opacity(0.7)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))

            // Score text
            Text("\(Int(breathabilityScore))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(breathabilityColor)
        }
    }

    // MARK: - Computed Properties

    private var breathabilityScore: Double {
        // Convert AQI to breathability score (0-100, higher is better)
        let score = max(0, min(100, 100 - (averageAQI / 2)))
        return score
    }

    private var breathabilityColor: Color {
        switch dominantLevel {
        case .good: return Color(hex: "#E0E0E0")
        case .moderate: return Color(hex: "#F9A825")
        case .poor: return Color(hex: "#FF6F00")
        case .unhealthy: return Color(hex: "#E53935")
        case .severe: return Color(hex: "#8E24AA")
        case .hazardous: return Color(hex: "#6A1B4D")
        }
    }

    private var breathabilityDescription: String {
        switch dominantLevel {
        case .good: return "Excellent"
        case .moderate: return "Good"
        case .poor: return "Fair"
        case .unhealthy: return "Poor"
        case .severe: return "Very Poor"
        case .hazardous: return "Hazardous"
        }
    }

    private var breathabilityDetail: String {
        switch dominantLevel {
        case .good:
            return "Perfect for outdoor breathing"
        case .moderate:
            return "Safe for most people"
        case .poor:
            return "Consider mask for sensitive groups"
        case .unhealthy:
            return "Limit outdoor exposure"
        case .severe:
            return "Wear mask, reduce activity"
        case .hazardous:
            return "Stay indoors, use purifiers"
        }
    }

    // MARK: - Animations

    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: breathingDuration)
            .repeatForever(autoreverses: true)
        ) {
            breathingPhase = 1.0
        }
    }

    private func startGlowAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 0.6
        }
    }

    private var breathingDuration: Double {
        // Breathing rate based on air quality
        // Good air = slower, calm breathing
        // Bad air = faster, labored breathing
        switch dominantLevel {
        case .good: return 4.0
        case .moderate: return 3.5
        case .poor: return 3.0
        case .unhealthy: return 2.5
        case .severe: return 2.0
        case .hazardous: return 1.5
        }
    }
}

// MARK: - Compact Breathability Indicator

/// Versión compacta para mostrar en header o toolbar
struct CompactBreathabilityIndicator: View {
    let averageAQI: Double
    let dominantLevel: AQILevel

    @State private var breathingPhase: CGFloat = 0

    var body: some View {
        HStack(spacing: 8) {
            // Animated lungs icon
            ZStack {
                Image(systemName: "lungs.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(breathabilityColor)
                    .scaleEffect(1.0 + breathingPhase * 0.1)

                // Breathing particles
                Circle()
                    .fill(breathabilityColor.opacity(0.4))
                    .frame(width: 3, height: 3)
                    .offset(y: -12 - (breathingPhase * 8))
                    .opacity(1.0 - breathingPhase)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Breathability")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("\(Int(breathabilityScore))/100")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(breathabilityColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(breathabilityColor.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                breathingPhase = 1.0
            }
        }
    }

    private var breathabilityScore: Double {
        max(0, min(100, 100 - (averageAQI / 2)))
    }

    private var breathabilityColor: Color {
        switch dominantLevel {
        case .good: return Color(hex: "#E0E0E0")
        case .moderate: return Color(hex: "#F9A825")
        case .poor: return Color(hex: "#FF6F00")
        case .unhealthy: return Color(hex: "#E53935")
        case .severe: return Color(hex: "#8E24AA")
        case .hazardous: return Color(hex: "#6A1B4D")
        }
    }
}

// MARK: - Safe Outdoor Time View

/// Indica cuánto tiempo es seguro estar al aire libre
struct SafeOutdoorTimeView: View {
    let level: AQILevel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 20))
                .foregroundStyle(timeColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Safe Outdoor Time")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(safeTimeDescription)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Spacer()

            // Time icon
            ZStack {
                Circle()
                    .fill(timeColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text(safeTimeEmoji)
                    .font(.system(size: 24))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(timeColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var safeTimeDescription: String {
        switch level {
        case .good: return "Unlimited"
        case .moderate: return "4-6 hours"
        case .poor: return "2-3 hours"
        case .unhealthy: return "< 1 hour"
        case .severe: return "< 30 minutes"
        case .hazardous: return "Avoid outdoor"
        }
    }

    private var safeTimeEmoji: String {
        switch level {
        case .good: return "😊"
        case .moderate: return "🙂"
        case .poor: return "😐"
        case .unhealthy: return "😷"
        case .severe: return "🚫"
        case .hazardous: return "⚠️"
        }
    }

    private var timeColor: Color {
        switch level {
        case .good: return .green
        case .moderate: return .yellow
        case .poor: return .orange
        case .unhealthy, .severe, .hazardous: return .red
        }
    }
}

// MARK: - Preview

#Preview("Breathability Views") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Breathability Indicators").font(.title.bold())

            // Main view - Good
            BreathabilityIndexView(averageAQI: 35, dominantLevel: .good)

            // Main view - Poor
            BreathabilityIndexView(averageAQI: 125, dominantLevel: .poor)

            // Main view - Unhealthy
            BreathabilityIndexView(averageAQI: 175, dominantLevel: .unhealthy)

            Divider()

            // Compact indicators
            HStack(spacing: 12) {
                CompactBreathabilityIndicator(averageAQI: 45, dominantLevel: .good)
                CompactBreathabilityIndicator(averageAQI: 135, dominantLevel: .poor)
            }

            Divider()

            // Safe outdoor time
            SafeOutdoorTimeView(level: .good)
            SafeOutdoorTimeView(level: .poor)
            SafeOutdoorTimeView(level: .unhealthy)
        }
        .padding()
    }
}
