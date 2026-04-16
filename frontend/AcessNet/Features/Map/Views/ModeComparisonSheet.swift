//
//  ModeComparisonSheet.swift
//  AcessNet
//
//  Bottom sheet que compara auto/metro/uber/bici para el mismo origen-destino.
//  Muestra costo total, tiempo, CO₂, exposición PM2.5 y un insight de Gemini.
//

import SwiftUI
import CoreLocation
import os

struct ModeComparisonSheet: View {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let vehicle: VehicleProfile?

    @State private var response: TripCompareResponse?
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if loading {
                        ProgressView("Calculando 4 modos de transporte...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if let err = error {
                        errorView(err)
                    } else if let resp = response {
                        content(resp)
                    }
                }
                .padding()
            }
            .navigationTitle("Compara tu viaje")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("¿Cómo prefieres llegar?")
                .font(.title2.bold())
            Text("Comparamos precio real, tiempo, emisiones y exposición para 4 modos.")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func content(_ resp: TripCompareResponse) -> some View {
        // AI insight banner
        if let insight = resp.aiInsight {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text(insight)
                    .font(.callout)
            }
            .padding(12)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }

        // Mode cards
        VStack(spacing: 10) {
            ForEach(resp.orderedModes) { mode in
                ModeCard(
                    mode: mode,
                    isCheapest: mode.mode == resp.cheapest?.mode,
                    isFastest: mode.mode == resp.fastest?.mode,
                    isHealthiest: mode.mode == resp.healthiest?.mode
                )
            }
        }

        // Resumen
        summarySection(resp)
    }

    @ViewBuilder
    private func summarySection(_ resp: TripCompareResponse) -> some View {
        if let cheapest = resp.cheapest, let fastest = resp.fastest {
            VStack(alignment: .leading, spacing: 8) {
                Text("Resumen")
                    .font(.headline)
                HStack {
                    Image(systemName: "pesosign.circle.fill").foregroundColor(.green)
                    Text("Más barato: \(cheapest.emoji) \(cheapest.displayName) — \(cheapest.costFormatted)")
                        .font(.subheadline)
                }
                HStack {
                    Image(systemName: "bolt.fill").foregroundColor(.yellow)
                    Text("Más rápido: \(fastest.emoji) \(fastest.displayName) — \(fastest.durationFormatted)")
                        .font(.subheadline)
                }
                if let healthy = resp.healthiest {
                    HStack {
                        Image(systemName: "heart.fill").foregroundColor(.pink)
                        Text("Mejor salud: \(healthy.emoji) \(healthy.displayName)")
                            .font(.subheadline)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(12)
        }
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("No pudimos comparar").font(.headline)
            Text(msg).font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Reintentar") { Task { await load() } }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Load

    private func load() async {
        loading = true
        error = nil
        AirWayLogger.ui.info(
            "ModeComparisonSheet loading vehicle=\(self.vehicle?.fullDisplayName ?? "nil", privacy: .public)"
        )
        defer { loading = false }
        do {
            response = try await TripCompareAPI.shared.compare(
                origin: origin, destination: destination, vehicle: vehicle
            )
            AirWayLogger.ui.info(
                "ModeComparisonSheet loaded \(self.response?.modes.count ?? 0) modes"
            )
        } catch {
            self.error = error.localizedDescription
            AirWayLogger.ui.error("ModeComparisonSheet failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

// MARK: - Mode Card

private struct ModeCard: View {
    let mode: TripMode
    let isCheapest: Bool
    let isFastest: Bool
    let isHealthiest: Bool

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(mode.emoji).font(.system(size: 42))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(mode.displayName).font(.headline)
                        if isCheapest { badge("⭐ Barato", color: .green) }
                        if isFastest { badge("⚡ Rápido", color: .yellow) }
                        if isHealthiest { badge("💚 Salud", color: .pink) }
                    }

                    HStack(spacing: 6) {
                        Label(mode.durationFormatted, systemImage: "clock.fill")
                        Text("·").foregroundColor(.secondary)
                        Label(mode.costFormatted, systemImage: "pesosign.circle.fill")
                    }
                    .font(.subheadline)

                    HStack(spacing: 6) {
                        Label(mode.co2Formatted + " CO₂", systemImage: "smoke.fill")
                        if mode.caloriesBurned > 0 {
                            Text("·").foregroundColor(.secondary)
                            Label("\(mode.caloriesBurned) kcal", systemImage: "flame.fill")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if mode.hiddenCostMxn > 1 {
                        Text("(incluye $\(Int(mode.hiddenCostMxn.rounded())) MXN ocultos)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                Button {
                    withAnimation { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.up.circle" : "chevron.down.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            if expanded {
                Divider().padding(.horizontal, 12)
                detailsView
                    .padding(12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(highlightColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(highlightColor.opacity(0.25), lineWidth: 1)
        )
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    private var highlightColor: Color {
        if isCheapest { return .green }
        if isHealthiest { return .pink }
        if isFastest { return .yellow }
        return .blue
    }

    @ViewBuilder
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let vehicle = mode.vehicleDisplay {
                detailRow("Vehículo", vehicle)
            }
            if let liters = mode.liters {
                detailRow("Consumo estimado", String(format: "%.2f L", liters))
            }
            if let tolls = mode.tollsMxn, tolls > 0 {
                detailRow("Peajes", "$\(Int(tolls))")
            }
            if let parking = mode.parkingMxn, parking > 0 {
                detailRow("Estacionamiento", "$\(Int(parking))")
            }
            if let dep = mode.depreciationMxn, dep > 0 {
                detailRow("Depreciación", String(format: "$%.0f", dep))
            }
            if let walk = mode.walkingM, walk > 0 {
                detailRow("Caminata", "\(walk) m")
            }
            if mode.pm25ExposureG > 0 {
                detailRow("Exposición PM2.5", String(format: "%.3f g", mode.pm25ExposureG))
            }
            if let note = mode.healthNote {
                Text(note).font(.caption2).foregroundColor(.orange)
            }
            if let note = mode.fareNote {
                Text(note).font(.caption2).foregroundColor(.secondary)
            }
        }
        .font(.caption)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
    }
}
