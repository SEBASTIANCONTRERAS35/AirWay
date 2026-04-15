//
//  AirQualityCloudView.swift
//  AcessNet
//
//  Componentes visuales para mostrar zonas de calidad del aire en el mapa
//

import SwiftUI
import CoreLocation

// MARK: - Air Quality Cloud Annotation

/// Vista de anotación para una zona de calidad del aire con efecto de "nube"
struct AirQualityCloudAnnotation: View {
    let zone: AirQualityZone
    let showPulse: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6

    var body: some View {
        ZStack {
            // Capa 1: Efecto de pulso exterior (opcional)
            if showPulse {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                zone.color.opacity(0.4),
                                zone.color.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 15,
                            endRadius: 35
                        )
                    )
                    .frame(width: 70, height: 70)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)
                    .blur(radius: 4)
            }

            // Capa 2: Círculo principal con gradiente
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            zone.color.opacity(zone.fillOpacity * 1.5),
                            zone.color.opacity(zone.fillOpacity * 0.8),
                            zone.color.opacity(zone.fillOpacity * 0.3)
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 50, height: 50)
                .blur(radius: 2)

            // Capa 3: Icono central
            Image(systemName: zone.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
        }
        .onAppear {
            if showPulse {
                startPulseAnimation()
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.3
            pulseOpacity = 0.3
        }
    }
}

// MARK: - Air Quality Zone Detail Card

/// Card de detalles cuando se toca una zona
struct AirQualityZoneDetailCard: View {
    let zone: AirQualityZone
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    zone.color.opacity(0.95),
                                    zone.color.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: zone.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AQI \(Int(zone.airQuality.aqi))")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(zone.levelDescription)
                        .font(.subheadline)
                        .foregroundStyle(zone.color)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
            }

            Divider()

            // Detalles de contaminantes
            VStack(alignment: .leading, spacing: 12) {
                Text("Pollutant Levels")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    // PM2.5
                    PollutantDetailView(
                        icon: "aqi.medium",
                        label: "PM2.5",
                        value: String(format: "%.1f", zone.airQuality.pm25),
                        unit: "μg/m³",
                        color: zone.color
                    )

                    if let pm10 = zone.airQuality.pm10 {
                        PollutantDetailView(
                            icon: "aqi.high",
                            label: "PM10",
                            value: String(format: "%.1f", pm10),
                            unit: "μg/m³",
                            color: zone.color
                        )
                    }
                }
            }

            Divider()

            // Health message
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)

                Text(zone.level.extendedHealthMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 5)
        .padding(.horizontal)
    }
}

// MARK: - Pollutant Detail View

/// Vista de detalle de un contaminante individual
struct PollutantDetailView: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 2) {
                    Text(value)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview("Air Quality Cloud") {
    let sampleAirQuality = AirQualityPoint(
        coordinate: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
        aqi: 75,
        pm25: 22.5,
        pm10: 45.0
    )

    let sampleZone = AirQualityZone(
        coordinate: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
        radius: 500,
        airQuality: sampleAirQuality
    )

    return VStack(spacing: 30) {
        Text("Air Quality Cloud Views").font(.title.bold())

        // Cloud annotation
        AirQualityCloudAnnotation(zone: sampleZone, showPulse: true)
            .frame(width: 70, height: 70)

        // Detail card
        AirQualityZoneDetailCard(zone: sampleZone) {
            print("Dismissed")
        }
    }
    .padding()
}
