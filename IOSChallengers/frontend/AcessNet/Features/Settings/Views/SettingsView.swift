//
//  SettingsView.swift
//  AcessNet
//
//  Created by BICHOTEE
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedAQI: AQIStandard = .european
    @State private var selectedTemperature: TemperatureUnit = .celsius
    @State private var selectedWindSpeed: WindSpeedUnit = .kmh

    enum AQIStandard {
        case european
        case us
    }

    enum TemperatureUnit {
        case celsius
        case fahrenheit
    }

    enum WindSpeedUnit {
        case kmh
        case mph
    }

    var body: some View {
        ZStack {
            // Background gradient - Deep blue to purple
            LinearGradient(
                colors: [
                    Color(hex: "#1a1a2e"),
                    Color(hex: "#16213e"),
                    Color(hex: "#0f3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    HStack {
                        Circle()
                            .fill(Color(hex: "#4ECDC4"))
                            .frame(width: 12, height: 12)

                        Text("SETTINGS")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .tracking(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)

                    // Air Quality Index Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AIR QUALITY INDEX")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)

                        HStack(spacing: 0) {
                            SegmentButton(
                                title: "European AQI",
                                isSelected: selectedAQI == .european
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedAQI = .european
                                }
                            }

                            SegmentButton(
                                title: "US AQI",
                                isSelected: selectedAQI == .us
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedAQI = .us
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .padding(.horizontal)

                    // Temperature Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TEMPERATURE")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)

                        HStack(spacing: 0) {
                            SegmentButton(
                                title: "°C",
                                isSelected: selectedTemperature == .celsius
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTemperature = .celsius
                                }
                            }

                            SegmentButton(
                                title: "°F",
                                isSelected: selectedTemperature == .fahrenheit
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTemperature = .fahrenheit
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .padding(.horizontal)

                    // Wind Speed Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("WIND SPEED")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)

                        HStack(spacing: 0) {
                            SegmentButton(
                                title: "Km/h",
                                isSelected: selectedWindSpeed == .kmh
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedWindSpeed = .kmh
                                }
                            }

                            SegmentButton(
                                title: "Mph",
                                isSelected: selectedWindSpeed == .mph
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedWindSpeed = .mph
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .padding(.horizontal)

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 24)

                    // Weather Simulation Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("WEATHER SIMULATION")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)

                        Text("Cambia el ambiente visual del Home. \"AirWay\" usa la paleta premium de la página web.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            ForEach(WeatherSimMode.allCases) { mode in
                                WeatherModeChip(
                                    mode: mode,
                                    isSelected: appSettings.weatherSimMode == mode
                                ) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        appSettings.weatherSimMode = mode
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 24)

                    // Performance Section
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: "PERFORMANCE")
                            .padding(.bottom, 16)

                        // Proximity Filtering Toggle
                        SettingsToggleRow(
                            title: "Proximity Filtering",
                            subtitle: "Show only nearby elements (\(Int(appSettings.proximityRadiusKm))km)",
                            isOn: $appSettings.enableProximityFiltering
                        )

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 16)

                        // Proximity Radius Slider
                        if appSettings.enableProximityFiltering {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Visibility Radius")
                                        .font(.body)
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("\(Int(appSettings.proximityRadiusKm)) km")
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(Color("AccentColor"))
                                }

                                Slider(
                                    value: $appSettings.proximityRadiusKm,
                                    in: 1...5,
                                    step: 0.5
                                )
                                .tint(Color("AccentColor"))

                                HStack {
                                    Text("1 km")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))

                                    Spacer()

                                    Text("5 km")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.vertical, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 16)
                        }

                        // Performance Info Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: appSettings.enableProximityFiltering ? "checkmark.circle.fill" : "info.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(appSettings.enableProximityFiltering ? .green : .blue)

                                Text(appSettings.enableProximityFiltering ? "Performance Optimized" : "Showing All Elements")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            Text("Grid: \(appSettings.totalAirQualityZones) zones • Static rendering")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))

                            if appSettings.enableProximityFiltering {
                                Text("Elements beyond \(Int(appSettings.proximityRadiusKm))km are hidden for better performance.")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.top, 4)
                            } else {
                                Text("All elements are visible. Performance may vary with many elements.")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(appSettings.enableProximityFiltering ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Support us Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Support us")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            SupportButton(
                                icon: "star.fill",
                                title: "Rate"
                            )

                            Divider()
                                .background(Color.white.opacity(0.1))

                            SupportButton(
                                icon: "paperplane.fill",
                                title: "Share"
                            )

                            Divider()
                                .background(Color.white.opacity(0.1))

                            SupportButton(
                                icon: "square.grid.2x2.fill",
                                title: "More"
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Supporting Views

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.bold())
                .foregroundColor(isSelected ? Color(hex: "#0D1B3E") : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? .white : .clear)
                )
        }
    }
}

struct SupportButton: View {
    let icon: String
    let title: String

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 30)

                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.7))
            .tracking(1)
            .padding(.horizontal)
    }
}

struct WeatherModeChip: View {
    let mode: WeatherSimMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(mode.backgroundGradient)
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? mode.accent : .white.opacity(0.18),
                                        lineWidth: isSelected ? 2 : 1)
                        )

                    Image(systemName: mode.sfIcon)
                        .font(.title3)
                        .foregroundColor(mode.accent)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }

                Text(mode.displayName)
                    .font(.caption.weight(isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.75))

                if isSelected {
                    Circle()
                        .fill(mode.accent)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .tint(Color("AccentColor"))
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
