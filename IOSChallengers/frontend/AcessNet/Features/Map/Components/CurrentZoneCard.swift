//
//  CurrentZoneCard.swift
//  AcessNet
//
//  Card que muestra la zona de calidad del aire actual durante navegación
//

import SwiftUI
import CoreLocation

// MARK: - Current Zone Card

struct CurrentZoneCard: View {
    let zone: AirQualityZone?

    var body: some View {
        HStack(spacing: 16) {
            // Izquierda: AQI Badge grande
            VStack(spacing: 4) {
                Text("\(Int(zone?.airQuality.aqi ?? 0))")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(zone?.color ?? .gray)

                Text("AQI")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 90)

            Divider()
                .frame(height: 60)

            // Derecha: Métricas detalladas
            VStack(alignment: .leading, spacing: 8) {
                // Nivel de calidad
                HStack(spacing: 8) {
                    Image(systemName: zone?.icon ?? "aqi.medium")
                        .font(.title3)
                        .foregroundStyle(zone?.color ?? .gray)

                    Text(zone?.level.rawValue ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                // PM2.5
                HStack(spacing: 8) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("PM2.5: \(Int(zone?.airQuality.pm25 ?? 0)) µg/m³")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Mensaje de salud
                if let zone = zone {
                    HStack(spacing: 4) {
                        Image(systemName: healthIcon(for: zone.level))
                            .font(.caption)
                            .foregroundStyle(healthColor(for: zone.level))

                        Text(healthMessage(for: zone.level))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(zone?.fillColor ?? Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(zone?.strokeColor ?? .clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Helper Methods

    private func healthIcon(for level: AQILevel) -> String {
        switch level {
        case .good:
            return "checkmark.circle.fill"
        case .moderate:
            return "exclamationmark.circle.fill"
        case .poor, .unhealthy:
            return "exclamationmark.triangle.fill"
        case .severe, .hazardous:
            return "xmark.octagon.fill"
        }
    }

    private func healthColor(for level: AQILevel) -> Color {
        switch level {
        case .good:
            return Color(hex: "#4CAF50")
        case .moderate:
            return Color(hex: "#FF9800")
        case .poor:
            return Color(hex: "#FF5722")
        case .unhealthy:
            return Color(hex: "#E53935")
        case .severe:
            return Color(hex: "#8E24AA")
        case .hazardous:
            return Color(hex: "#6A1B4D")
        }
    }

    private func healthMessage(for level: AQILevel) -> String {
        switch level {
        case .good:
            return "Safe for everyone"
        case .moderate:
            return "Acceptable quality"
        case .poor:
            return "Sensitive groups affected"
        case .unhealthy:
            return "Everyone may be affected"
        case .severe:
            return "Health warnings"
        case .hazardous:
            return "Emergency conditions"
        }
    }
}

// MARK: - Empty State Card

struct EmptyZoneCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "aqi.medium")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Loading Air Quality...")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Fetching data for current area")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Compact Zone Indicator (para vista pequeña)

struct CompactZoneIndicator: View {
    let zone: AirQualityZone?

    var body: some View {
        HStack(spacing: 8) {
            // Círculo de color
            Circle()
                .fill(zone?.color ?? .gray)
                .frame(width: 12, height: 12)

            // AQI value
            Text("\(Int(zone?.airQuality.aqi ?? 0))")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(zone?.color ?? .gray)

            // Level name
            Text(zone?.level.rawValue ?? "Unknown")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(zone?.fillColor ?? Color(.systemGray6))
        )
        .overlay(
            Capsule()
                .strokeBorder(zone?.strokeColor ?? .clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Preview

#Preview("Current Zone Card") {
    VStack(spacing: 20) {
        Text("Current Zone Cards")
            .font(.title2.bold())
            .padding()

        // Good Air Quality
        CurrentZoneCard(zone: AirQualityZone(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 500,
            airQuality: AirQualityPoint(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                aqi: 45,
                pm25: 10.5,
                pm10: 18.2,
                timestamp: Date()
            )
        ))

        // Moderate Air Quality
        CurrentZoneCard(zone: AirQualityZone(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 500,
            airQuality: AirQualityPoint(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                aqi: 85,
                pm25: 35.5,
                pm10: 45.2,
                timestamp: Date()
            )
        ))

        // Unhealthy Air Quality
        CurrentZoneCard(zone: AirQualityZone(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 500,
            airQuality: AirQualityPoint(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                aqi: 165,
                pm25: 75.5,
                pm10: 95.2,
                timestamp: Date()
            )
        ))

        Divider()

        // Empty state
        EmptyZoneCard()

        Divider()

        // Compact indicator
        HStack(spacing: 12) {
            CompactZoneIndicator(zone: AirQualityZone(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                radius: 500,
                airQuality: AirQualityPoint(
                    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    aqi: 45,
                    pm25: 10.5,
                    pm10: 18.2,
                    timestamp: Date()
                )
            ))

            CompactZoneIndicator(zone: AirQualityZone(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                radius: 500,
                airQuality: AirQualityPoint(
                    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    aqi: 125,
                    pm25: 55.5,
                    pm10: 65.2,
                    timestamp: Date()
                )
            ))
        }

        Spacer()
    }
    .padding()
}
