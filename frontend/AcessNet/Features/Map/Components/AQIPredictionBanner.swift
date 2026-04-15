//
//  AQIPredictionBanner.swift
//  AcessNet
//
//  Banner compacto de predicción ML sobre el mapa.
//  Muestra AQI actual → predicho + mejor hora para salir.
//

import SwiftUI

struct AQIPredictionBanner: View {
    @State private var prediction: MLPredictionResponse?
    @State private var bestTime: BestTimeResponse?
    @State private var isLoading = true
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if isLoading && !hasLoaded {
                loadingBanner
            } else if let pred = prediction, pred.model_available == true {
                predictionContent(pred)
            }
        }
        .task {
            guard !hasLoaded else { return }
            await loadData()
        }
    }

    // MARK: - Loading

    private var loadingBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.7)
            Text("Loading prediction...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Prediction Content

    private func predictionContent(_ pred: MLPredictionResponse) -> some View {
        VStack(spacing: 0) {
            // Main pill: AQI trend
            HStack(spacing: 10) {
                // Current AQI
                if let current = pred.current_aqi {
                    HStack(spacing: 4) {
                        Image(systemName: "aqi.medium")
                            .font(.system(size: 11))
                        Text("\(current)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.primary)
                }

                // Arrow trend
                if let trend = pred.trend {
                    Image(systemName: trendIcon(trend))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(trendColor(trend))
                }

                // Predicted 6h AQI
                if let pred6h = pred.predictions?["6h"] {
                    HStack(spacing: 4) {
                        Text("\(pred6h.aqi)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text("in 6h")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(colorForAQI(pred6h.aqi))
                }

                // Separator
                if bestTime?.best_window != nil {
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 1, height: 16)
                }

                // Best time
                if let best = bestTime?.best_window {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                        Text("Best: \(extractHour(best.start))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        let lat = 19.4326
        let lon = -99.1332
        let base = "https://airway-api.onrender.com/api/v1"

        // Prediction
        do {
            guard let url = URL(string: "\(base)/air/prediction?lat=\(lat)&lon=\(lon)&mode=walk") else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(PredictionEndpointResponse.self, from: data)
            await MainActor.run {
                prediction = response.prediction
            }
        } catch {
            print("Banner prediction error: \(error)")
        }

        // Best time
        do {
            guard let url = URL(string: "\(base)/air/best-time?lat=\(lat)&lon=\(lon)&mode=bike&hours=12") else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(BestTimeResponse.self, from: data)
            await MainActor.run { bestTime = response }
        } catch {
            print("Banner best-time error: \(error)")
        }

        await MainActor.run {
            isLoading = false
            hasLoaded = true
        }
    }

    // MARK: - Helpers

    private func trendIcon(_ trend: String) -> String {
        switch trend {
        case "subiendo": return "arrow.up.right"
        case "bajando": return "arrow.down.right"
        default: return "arrow.right"
        }
    }

    private func trendColor(_ trend: String) -> Color {
        switch trend {
        case "subiendo": return .orange
        case "bajando": return .green
        default: return .secondary
        }
    }

    private func colorForAQI(_ aqi: Int) -> Color {
        switch aqi {
        case 0..<51: return .green
        case 51..<101: return .yellow
        case 101..<151: return .orange
        default: return .red
        }
    }

    private func extractHour(_ time: String) -> String {
        if let tIndex = time.firstIndex(of: "T") {
            return String(time[time.index(after: tIndex)...].prefix(5))
        }
        return time
    }
}

// Response from /air/prediction endpoint (wraps MLPredictionResponse)
struct PredictionEndpointResponse: Codable {
    let prediction: MLPredictionResponse?
    let current: PredictionCurrentData?

    enum CodingKeys: String, CodingKey {
        case prediction, current
    }
}

struct PredictionCurrentData: Codable {
    let aqi: Int?
    let category: String?
    let pm25: Double?
}
