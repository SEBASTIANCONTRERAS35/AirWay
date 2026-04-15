//
//  ContentView.swift
//  AirWayWatch Watch App
//
//  Created by Emilio Cruz Vargas on 05/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var airQualityData: AirQualityData = .sample

    var body: some View {
        CompatibleNavigation {
            ScrollView {
                VStack(spacing: 16) {
                    // Location header
                    Text(airQualityData.location)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .textCase(.uppercase)

                    // Main AQI Display
                    VStack(spacing: 8) {
                        Text("\(airQualityData.aqi)")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)

                        Text(airQualityData.qualityLevel.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(hex: airQualityData.qualityLevel.color).opacity(0.3))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(hex: airQualityData.qualityLevel.color), lineWidth: 1)
                                    )
                            )
                    }

                    // PM Indicators
                    VStack(spacing: 8) {
                        PMRow(label: "PM2.5", value: airQualityData.pm25)
                        PMRow(label: "PM10", value: airQualityData.pm10)
                    }
                    .padding(.vertical, 8)

                    // Weather info
                    HStack(spacing: 12) {
                        WeatherItem(
                            icon: "thermometer",
                            value: "\(airQualityData.temperature)°C"
                        )

                        Divider()
                            .frame(height: 30)

                        WeatherItem(
                            icon: "drop.fill",
                            value: "\(airQualityData.humidity)%"
                        )
                    }
                    .padding(.vertical, 8)

                    // Quick actions
                    VStack(spacing: 8) {
                        NavigationLink(destination: ExposureView()) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                Text("Today's Exposure")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.15))
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: RouteMapView()) {
                            HStack {
                                Image(systemName: "map.fill")
                                    .font(.caption)
                                Text("Route Map")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.15))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "#0A1D4D"),
                        Color(hex: "#4AA1B3")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

// MARK: - Supporting Views

struct PMRow: View {
    let label: String
    let value: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text(String(format: "%.1f μg/m³", value))
                .font(.caption).bold()
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct WeatherItem: View {
    let icon: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Text(value)
                .font(.caption2).bold()
                .foregroundColor(.white)
        }
    }
}

struct CompatibleNavigation<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if #available(watchOS 9.0, *) {
            NavigationStack {
                content()
            }
        } else {
            NavigationView {
                content()
            }
        }
    }
}

#Preview {
    ContentView()
}
