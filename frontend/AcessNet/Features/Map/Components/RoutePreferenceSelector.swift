//
//  RoutePreferenceSelector.swift
//  AcessNet
//
//  Selector interactivo de preferencias de ruta con sliders visuales
//

import SwiftUI
import Combine

// MARK: - Route Preference Selector

/// Vista principal del selector de preferencias
struct RoutePreferenceSelector: View {
    @Binding var isPresented: Bool
    @ObservedObject var preferences: RoutePreferencesModel
    let onApply: () -> Void

    @State private var selectedPreset: PresetType? = nil
    @State private var showingAdvanced = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            ScrollView {
                VStack(spacing: 24) {
                    // Presets rápidos
                    presetsSection

                    // Sliders principales
                    slidersSection

                    // Opciones avanzadas
                    if showingAdvanced {
                        advancedOptionsSection
                    }

                    // Vista previa de impacto
                    impactPreviewSection
                }
                .padding()
            }

            // Footer con botones
            footerView
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(radius: 20)
        .transition(.move(edge: .bottom))
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            // Handle bar
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route Preferences")
                        .font(.title2.bold())

                    Text("Customize your optimal route")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
            }
            .padding()
        }
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.headline)
                .foregroundStyle(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PresetButton(
                        type: .fastest,
                        isSelected: selectedPreset == .fastest,
                        action: { applyPreset(.fastest) }
                    )

                    PresetButton(
                        type: .safest,
                        isSelected: selectedPreset == .safest,
                        action: { applyPreset(.safest) }
                    )

                    PresetButton(
                        type: .healthiest,
                        isSelected: selectedPreset == .healthiest,
                        action: { applyPreset(.healthiest) }
                    )

                    PresetButton(
                        type: .balanced,
                        isSelected: selectedPreset == .balanced,
                        action: { applyPreset(.balanced) }
                    )
                }
            }
        }
    }

    private var slidersSection: some View {
        VStack(spacing: 20) {
            // Speed Priority
            PreferenceSlider(
                title: "Speed Priority",
                icon: "bolt.fill",
                value: $preferences.speedWeight,
                color: .purple,
                description: speedDescription
            )

            // Safety Priority
            PreferenceSlider(
                title: "Safety Priority",
                icon: "shield.fill",
                value: $preferences.safetyWeight,
                color: .green,
                description: safetyDescription
            )

            // Air Quality Priority
            PreferenceSlider(
                title: "Clean Air Priority",
                icon: "leaf.fill",
                value: $preferences.airQualityWeight,
                color: .teal,
                description: airDescription
            )
        }
        .onChange(of: preferences.speedWeight) { _ in selectedPreset = nil }
        .onChange(of: preferences.safetyWeight) { _ in selectedPreset = nil }
        .onChange(of: preferences.airQualityWeight) { _ in selectedPreset = nil }
    }

    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Options")
                .font(.headline)

            VStack(spacing: 12) {
                ToggleOption(
                    title: "Avoid Highways",
                    icon: "road.lanes",
                    isOn: $preferences.avoidHighways,
                    description: "Take local roads when possible"
                )

                ToggleOption(
                    title: "Consider Traffic Patterns",
                    icon: "clock.arrow.circlepath",
                    isOn: $preferences.considerTrafficPatterns,
                    description: "Use historical traffic data"
                )

                ToggleOption(
                    title: "Predictive Analysis",
                    icon: "chart.line.uptrend.xyaxis",
                    isOn: $preferences.predictiveAnalysis,
                    description: "Anticipate future conditions"
                )
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var impactPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Impact Preview")
                .font(.headline)

            HStack(spacing: 16) {
                ImpactIndicator(
                    label: "Time",
                    impact: preferences.timeImpact,
                    icon: "clock.fill",
                    color: .blue
                )

                ImpactIndicator(
                    label: "Safety",
                    impact: preferences.safetyImpact,
                    icon: "shield.fill",
                    color: .green
                )

                ImpactIndicator(
                    label: "Health",
                    impact: preferences.healthImpact,
                    icon: "heart.fill",
                    color: .red
                )
            }

            Text(preferences.impactSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
        )
    }

    private var footerView: some View {
        HStack(spacing: 12) {
            // Advanced toggle
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingAdvanced.toggle()
                }
            }) {
                Label(
                    showingAdvanced ? "Hide Advanced" : "Show Advanced",
                    systemImage: showingAdvanced ? "chevron.up" : "chevron.down"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
            }

            Spacer()

            // Reset button
            Button(action: {
                preferences.reset()
                selectedPreset = nil
            }) {
                Text("Reset")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.1))
                    )
            }

            // Apply button
            Button(action: {
                onApply()
                isPresented = false
            }) {
                Text("Apply")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Helper Methods

    private func applyPreset(_ preset: PresetType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPreset = preset
            preferences.applyPreset(preset)
        }
    }

    private var speedDescription: String {
        switch preferences.speedWeight {
        case 0..<0.3: return "Prioritize other factors over speed"
        case 0.3..<0.6: return "Moderate speed consideration"
        case 0.6..<0.8: return "Prefer faster routes"
        default: return "Fastest route possible"
        }
    }

    private var safetyDescription: String {
        switch preferences.safetyWeight {
        case 0..<0.3: return "Accept some risk for efficiency"
        case 0.3..<0.6: return "Balance safety with other factors"
        case 0.6..<0.8: return "Prioritize avoiding incidents"
        default: return "Maximum safety, avoid all hazards"
        }
    }

    private var airDescription: String {
        switch preferences.airQualityWeight {
        case 0..<0.3: return "Air quality is less important"
        case 0.3..<0.6: return "Consider air quality moderately"
        case 0.6..<0.8: return "Prefer cleaner air routes"
        default: return "Cleanest air possible"
        }
    }
}

// MARK: - Preference Slider

struct PreferenceSlider: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let color: Color
    let description: String

    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }

            CustomSlider(
                value: $value,
                color: color,
                isEditing: $isEditing
            )

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .opacity(isEditing ? 1 : 0.7)
        }
    }
}

// MARK: - Custom Slider

struct CustomSlider: View {
    @Binding var value: Double
    let color: Color
    @Binding var isEditing: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(value), height: 8)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .stroke(color, lineWidth: 3)
                    )
                    .scaleEffect(isEditing ? 1.2 : 1.0)
                    .offset(x: geometry.size.width * CGFloat(value) - 12)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                isEditing = true
                                let newValue = gesture.location.x / geometry.size.width
                                value = min(max(0, Double(newValue)), 1)

                                // Haptic feedback
                                if Int(value * 10) != Int(newValue * 10) {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isEditing = false
                                }
                            }
                    )
            }
        }
        .frame(height: 24)
    }
}

// MARK: - Toggle Option

struct ToggleOption: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let description: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.blue)
        }
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let type: PresetType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? type.colors : [Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .primary)
                }

                Text(type.label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isSelected ? type.colors[0] : .secondary)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Impact Indicator

struct ImpactIndicator: View {
    let label: String
    let impact: ImpactLevel
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(impact.color)

            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)

            Text(impact.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(impact.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(impact.color.opacity(0.1))
        )
    }
}

// MARK: - Models

/// Modelo de preferencias de ruta
class RoutePreferencesModel: ObservableObject {
    @Published var speedWeight: Double = 0.4 {
        didSet { normalizeWeights() }
    }
    @Published var safetyWeight: Double = 0.3 {
        didSet { normalizeWeights() }
    }
    @Published var airQualityWeight: Double = 0.3 {
        didSet { normalizeWeights() }
    }

    @Published var avoidHighways: Bool = false
    @Published var considerTrafficPatterns: Bool = true
    @Published var predictiveAnalysis: Bool = true

    // Computed properties
    var timeImpact: ImpactLevel {
        switch speedWeight {
        case 0..<0.3: return .low
        case 0.3..<0.6: return .medium
        default: return .high
        }
    }

    var safetyImpact: ImpactLevel {
        switch safetyWeight {
        case 0..<0.3: return .low
        case 0.3..<0.6: return .medium
        default: return .high
        }
    }

    var healthImpact: ImpactLevel {
        switch airQualityWeight {
        case 0..<0.3: return .low
        case 0.3..<0.6: return .medium
        default: return .high
        }
    }

    var impactSummary: String {
        if speedWeight > 0.6 {
            return "Routes will prioritize speed over safety and air quality"
        } else if safetyWeight > 0.6 {
            return "Routes will avoid incidents, even if it takes longer"
        } else if airQualityWeight > 0.6 {
            return "Routes will seek cleaner air, potentially increasing travel time"
        } else {
            return "Routes will balance all factors for optimal results"
        }
    }

    func applyPreset(_ preset: PresetType) {
        switch preset {
        case .fastest:
            speedWeight = 0.8
            safetyWeight = 0.1
            airQualityWeight = 0.1
        case .safest:
            speedWeight = 0.2
            safetyWeight = 0.6
            airQualityWeight = 0.2
        case .healthiest:
            speedWeight = 0.2
            safetyWeight = 0.3
            airQualityWeight = 0.5
        case .balanced:
            speedWeight = 0.34
            safetyWeight = 0.33
            airQualityWeight = 0.33
        }
    }

    func reset() {
        speedWeight = 0.4
        safetyWeight = 0.3
        airQualityWeight = 0.3
        avoidHighways = false
        considerTrafficPatterns = true
        predictiveAnalysis = true
    }

    private func normalizeWeights() {
        let total = speedWeight + safetyWeight + airQualityWeight
        guard total > 0 else { return }

        // No normalizar si ya está cerca de 1
        if abs(total - 1.0) < 0.01 { return }

        // Normalizar para que sumen 1.0
        speedWeight = speedWeight / total
        safetyWeight = safetyWeight / total
        airQualityWeight = airQualityWeight / total
    }
}

/// Tipos de preset
enum PresetType {
    case fastest
    case safest
    case healthiest
    case balanced

    var icon: String {
        switch self {
        case .fastest: return "bolt.fill"
        case .safest: return "shield.fill"
        case .healthiest: return "leaf.fill"
        case .balanced: return "scale.3d"
        }
    }

    var label: String {
        switch self {
        case .fastest: return "Fastest"
        case .safest: return "Safest"
        case .healthiest: return "Healthiest"
        case .balanced: return "Balanced"
        }
    }

    var colors: [Color] {
        switch self {
        case .fastest: return [.purple, .indigo]
        case .safest: return [.green, .mint]
        case .healthiest: return [.teal, .cyan]
        case .balanced: return [.blue, .blue.opacity(0.7)]
        }
    }
}

/// Nivel de impacto
enum ImpactLevel {
    case low
    case medium
    case high

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - View Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}