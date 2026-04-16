//
//  ContingencyCastView.swift
//  AcessNet
//
//  Pantalla principal de ContingencyCast — pronóstico probabilístico
//  de contingencias ambientales en CDMX con 48-72h de anticipación.
//

import SwiftUI

struct ContingencyCastView: View {

    // MARK: - State

    @State private var response: ContingencyForecastResponse?
    @State private var selectedHorizon: Int = 24
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var naturalExplanation: String = ""
    @State private var isGeneratingExplanation = false

    @AppStorage("user_hologram") private var userHologram: String = ""

    // MARK: - Derived

    private var selectedForecast: HorizonForecast? {
        response?.forecasts.first(where: { $0.horizonH == selectedHorizon })
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if isLoading {
                    ProgressView("Calculando pronóstico...")
                        .padding(.vertical, 40)
                } else if let error = errorMessage {
                    errorView(error)
                } else if let selected = selectedForecast {
                    ProbabilityGauge(
                        probability: selected.probFase1O3,
                        ci80Lower: selected.o3Ci80Ppb.first,
                        ci80Upper: selected.o3Ci80Ppb.last,
                        o3ExpectedPpb: selected.o3ExpectedPpb,
                        horizonHours: selected.horizonH
                    )
                    .frame(height: 240)
                    .padding(.horizontal)

                    horizonSelector

                    if !naturalExplanation.isEmpty {
                        explanationCard
                    } else if isGeneratingExplanation {
                        HStack {
                            ProgressView().scaleEffect(0.7)
                            Text("Generando explicación...").font(.caption)
                        }
                    }

                    if !selected.recommendations.isEmpty {
                        RecommendationsPanel(
                            recommendations: selected.recommendations,
                            probabilityLevel: selected.probabilityLevel
                        )
                        .padding(.horizontal)
                    }

                    if !selected.topDrivers.isEmpty {
                        DriversPanel(drivers: selected.topDrivers)
                            .padding(.horizontal)
                    }

                    disclaimerView
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("ContingencyCast")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadForecast()
        }
        .refreshable {
            await loadForecast()
        }
    }

    // MARK: - Sub-views

    private var header: some View {
        VStack(spacing: 4) {
            Text("Probabilidad de contingencia")
                .font(.headline)
            Text("ZMVM · Fase 1 Ozono")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var horizonSelector: some View {
        HStack(spacing: 10) {
            ForEach(response?.forecasts ?? []) { forecast in
                Button {
                    withAnimation(.spring()) {
                        selectedHorizon = forecast.horizonH
                    }
                } label: {
                    HorizonCard(forecast: forecast)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    selectedHorizon == forecast.horizonH
                                        ? Color.accentColor
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Explicación")
                    .font(.headline)
            }
            Text(naturalExplanation)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }

    private var disclaimerView: some View {
        Text(response?.disclaimer ?? "")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
            .padding(.top, 10)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("No pudimos obtener el pronóstico")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Reintentar") {
                Task { await loadForecast() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }

    // MARK: - Actions

    @MainActor
    private func loadForecast() async {
        isLoading = true
        errorMessage = nil
        naturalExplanation = ""
        defer { isLoading = false }

        do {
            let hologram = userHologram.isEmpty ? nil : userHologram
            let resp = try await ContingencyService.shared.fetchForecast(hologram: hologram)
            self.response = resp

            // Seleccionar h+24 por defecto si existe
            if let first = resp.forecasts.first {
                self.selectedHorizon = first.horizonH
            }

            // Pedir a Foundation Models que expanda el hint en explicación natural
            Task {
                await generateExplanation(for: resp)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func generateExplanation(for resp: ContingencyForecastResponse) async {
        guard let selected = resp.forecasts.first(where: { $0.horizonH == selectedHorizon }) else {
            return
        }
        isGeneratingExplanation = true
        defer { isGeneratingExplanation = false }

        let text = await ContingencyExplanationService.shared.explain(
            forecast: selected,
            hint: resp.explanationHint
        )
        self.naturalExplanation = text
    }
}

#Preview {
    NavigationStack {
        ContingencyCastView()
    }
}
