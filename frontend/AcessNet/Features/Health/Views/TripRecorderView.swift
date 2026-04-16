//
//  TripRecorderView.swift
//  AcessNet
//
//  UI para iniciar/monitorear viaje. Muestra velocidad, distancia, eventos
//  bruscos en vivo, y tras "Terminar" actualiza el driving_style del perfil.
//

import SwiftUI

struct TripRecorderView: View {
    @StateObject private var service = DrivingTelemetryService.shared
    @StateObject private var vehicleService = VehicleProfileService.shared
    @State private var showingSummary: TripTelemetry?

    var body: some View {
        VStack(spacing: 20) {
            if service.isRecording {
                liveView
            } else {
                startView
            }
        }
        .padding()
        .sheet(item: $showingSummary) { trip in
            TripSummaryView(trip: trip)
        }
    }

    // MARK: - Start

    private var startView: some View {
        VStack(spacing: 18) {
            Image(systemName: "car.side.fill")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient(
                    colors: [.blue, .purple], startPoint: .top, endPoint: .bottom
                ))

            Text("Registrar viaje")
                .font(.title2.bold())

            if let vehicle = vehicleService.activeProfile {
                Text("Vehículo activo: \(vehicle.displayName)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Text("Estilo actual: \(vehicle.drivingStyleLabel)")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Text("⚠️ Sin vehículo configurado")
                    .font(.callout)
                    .foregroundColor(.orange)
            }

            Button {
                service.startTrip(vehicleId: vehicleService.activeProfile?.id)
            } label: {
                Label("Iniciar viaje", systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(vehicleService.activeProfile == nil)

            if !service.pastTrips.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Historial")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    ForEach(service.pastTrips.prefix(3)) { trip in
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading) {
                                Text(trip.startedAt, style: .date)
                                    .font(.subheadline)
                                Text("\(String(format: "%.1f", trip.totalDistanceKm)) km · \(Int(trip.durationMinutes)) min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.2f", trip.computedStyleMultiplier))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Live

    private var liveView: some View {
        VStack(spacing: 20) {
            Text("Viaje en curso")
                .font(.title3.bold())
                .foregroundColor(.red)

            // Velocidad grande
            VStack(spacing: 0) {
                Text("\(Int(service.liveStats.speedKmh))")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("km/h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Stats grid
            HStack(spacing: 24) {
                statBlock(label: "Distancia",
                          value: String(format: "%.1f km", service.liveStats.distanceKm),
                          icon: "road.lanes")
                statBlock(label: "Tiempo",
                          value: "\(Int(service.liveStats.durationMin)) min",
                          icon: "clock.fill")
                statBlock(label: "Eventos",
                          value: "\(service.liveStats.harshEvents)",
                          icon: "exclamationmark.triangle.fill",
                          color: service.liveStats.harshEvents > 2 ? .orange : .green)
            }

            Button(role: .destructive) {
                if let finished = service.endTrip() {
                    showingSummary = finished
                }
            } label: {
                Label("Terminar viaje", systemImage: "stop.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Cancelar sin guardar") {
                service.cancelTrip()
            }
            .foregroundColor(.secondary)
            .font(.caption)
        }
    }

    private func statBlock(label: String, value: String, icon: String, color: Color = .blue) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Trip Summary

struct TripSummaryView: View {
    let trip: TripTelemetry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroHeader

                    VStack(alignment: .leading, spacing: 10) {
                        metricRow("Distancia total",
                                  String(format: "%.2f km", trip.totalDistanceKm),
                                  icon: "road.lanes")
                        metricRow("Duración",
                                  "\(Int(trip.durationMinutes)) min",
                                  icon: "clock.fill")
                        metricRow("Velocidad máxima",
                                  String(format: "%.0f km/h", trip.maxSpeedKmh),
                                  icon: "speedometer")
                        metricRow("Velocidad promedio",
                                  String(format: "%.0f km/h", trip.avgSpeedKmh),
                                  icon: "gauge.medium")
                        metricRow("Ganancia de elevación",
                                  String(format: "%.0f m", trip.elevationGainM),
                                  icon: "mountain.2.fill")
                        metricRow("Tiempo en ralentí",
                                  "\(trip.idleSeconds) s",
                                  icon: "hand.raised.fill")
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(12)

                    // Estilo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tu estilo de conducción")
                            .font(.headline)

                        HStack {
                            Image(systemName: "gauge")
                            Text(styleLabel)
                                .font(.title3.bold())
                                .foregroundColor(styleColor)
                        }

                        HStack {
                            Text("Aceleraciones bruscas")
                            Spacer()
                            Text("\(trip.harshAccels)")
                                .bold()
                        }
                        HStack {
                            Text("Frenadas bruscas")
                            Spacer()
                            Text("\(trip.harshBrakes)")
                                .bold()
                        }

                        Text(styleAdvice)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(styleColor.opacity(0.08))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Resumen del viaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }

    private var heroHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            VStack(alignment: .leading) {
                Text("Viaje guardado")
                    .font(.headline)
                Text("Tu perfil se actualizó automáticamente.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func metricRow(_ label: String, _ value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(value).bold().monospacedDigit()
        }
    }

    private var styleLabel: String {
        let m = trip.computedStyleMultiplier
        switch m {
        case ..<0.95: return "Muy eficiente"
        case 0.95..<1.05: return "Suave"
        case 1.05..<1.15: return "Normal"
        case 1.15..<1.25: return "Agresivo"
        default: return "Muy agresivo"
        }
    }

    private var styleColor: Color {
        switch trip.computedStyleMultiplier {
        case ..<1.05: return .green
        case 1.05..<1.15: return .blue
        case 1.15..<1.25: return .orange
        default: return .red
        }
    }

    private var styleAdvice: String {
        switch trip.computedStyleMultiplier {
        case ..<1.05:
            return "Tu conducción es eficiente. Cada viaje ahorra en combustible y reduce emisiones."
        case 1.05..<1.15:
            return "Conducción normal. Acelerar más suavemente podría ahorrarte hasta 10% de gasolina."
        case 1.15..<1.25:
            return "Hubo varias aceleraciones bruscas. Conducir más suave ahorra combustible y reduce estrés."
        default:
            return "Muchos eventos bruscos detectados. Considera anticipar los cambios de velocidad para un viaje más eficiente."
        }
    }
}
