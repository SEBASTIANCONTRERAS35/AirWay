//
//  NavigationPanel.swift
//  AcessNet
//
//  Panel principal de navegación que integra todos los componentes
//

import SwiftUI
import CoreLocation

// MARK: - Navigation Panel

struct NavigationPanel: View {
    let navigationState: NavigationState
    let currentZone: AirQualityZone?
    let distanceToManeuver: Double
    let onEndNavigation: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Top: Instrucción actual
            NavigationInstructionBar(
                step: navigationState.currentStep,
                distanceToManeuver: distanceToManeuver
            )

            // Middle: Zona de calidad del aire actual
            if let zone = currentZone {
                CurrentZoneCard(zone: zone)
            } else {
                EmptyZoneCard()
            }

            // Bottom: Barra de progreso
            NavigationProgressBar(
                progress: navigationState.progress,
                distanceRemaining: navigationState.distanceRemaining,
                eta: navigationState.etaRemaining,
                averageAQI: navigationState.selectedRoute?.averageAQI
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
        )
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Compact Navigation Panel (vista reducida)

struct CompactNavigationPanel: View {
    let navigationState: NavigationState
    let distanceToManeuver: Double
    let onExpand: () -> Void
    let onEndNavigation: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)

            // Compact content
            VStack(spacing: 12) {
                // Instrucción compacta
                CompactInstructionBar(
                    step: navigationState.currentStep,
                    distance: distanceToManeuver
                )

                // Progreso compacto
                CompactProgressBar(
                    progress: navigationState.progress,
                    distanceRemaining: navigationState.distanceRemaining,
                    eta: navigationState.etaRemaining
                )
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -3)
        .onTapGesture {
            onExpand()
        }
    }
}

// MARK: - Arrival Panel

struct ArrivalPanel: View {
    let destination: String
    let onDismiss: () -> Void

    @State private var confettiAnimation = false

    var body: some View {
        VStack(spacing: 20) {
            // Icono de llegada con animación
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#4CAF50"), Color(hex: "#66BB6A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: "#4CAF50").opacity(0.4), radius: 20, x: 0, y: 8)
                    .scaleEffect(confettiAnimation ? 1.1 : 1.0)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(confettiAnimation ? 360 : 0))
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    confettiAnimation = true
                }
            }

            // Mensaje
            VStack(spacing: 8) {
                Text("You have arrived!")
                    .font(.title.bold())
                    .foregroundStyle(.primary)

                Text(destination)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Botón de cierre
            Button(action: onDismiss) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Finish")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#4CAF50"), Color(hex: "#66BB6A")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "#4CAF50").opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
        )
        .padding(.horizontal)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Off Route Alert

struct OffRouteAlert: View {
    let onRecalculate: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Icono de alerta
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 50, height: 50)

                Image(systemName: "location.slash.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            // Mensaje
            VStack(alignment: .leading, spacing: 4) {
                Text("You're off route")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Would you like to recalculate?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Botones
            HStack(spacing: 8) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Circle().fill(Color(.systemGray5)))
                }

                Button(action: onRecalculate) {
                    Text("Recalculate")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Preview

#Preview("Navigation Panel") {
    VStack {
        Spacer()

        NavigationPanel(
            navigationState: NavigationState(
                isNavigating: true,
                selectedRoute: nil,
                currentStep: NavigationStep(
                    instruction: "Turn right on Main Street and continue for 2 blocks",
                    distance: 250,
                    maneuverType: .turnRight,
                    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                ),
                nextStep: NavigationStep(
                    instruction: "Turn left on Market Street",
                    distance: 500,
                    maneuverType: .turnLeft,
                    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                ),
                currentZone: AirQualityZone(
                    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    radius: 500,
                    airQuality: AirQualityPoint(
                        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                        aqi: 85,
                        pm25: 35.5,
                        pm10: 45.2,
                        timestamp: Date()
                    )
                ),
                progress: 0.45,
                distanceRemaining: 1800,
                etaRemaining: 360,
                distanceTraveled: 1500
            ),
            currentZone: AirQualityZone(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                radius: 500,
                airQuality: AirQualityPoint(
                    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    aqi: 85,
                    pm25: 35.5,
                    pm10: 45.2,
                    timestamp: Date()
                )
            ),
            distanceToManeuver: 250,
            onEndNavigation: {}
        )
    }
    .ignoresSafeArea()
}

#Preview("Arrival Panel") {
    VStack {
        Spacer()

        ArrivalPanel(
            destination: "123 Main Street, San Francisco",
            onDismiss: {}
        )
    }
    .ignoresSafeArea()
}

#Preview("Off Route Alert") {
    VStack {
        OffRouteAlert(
            onRecalculate: {},
            onDismiss: {}
        )
        .padding()

        Spacer()
    }
}
