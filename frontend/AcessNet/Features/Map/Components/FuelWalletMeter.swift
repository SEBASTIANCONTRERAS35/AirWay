//
//  FuelWalletMeter.swift
//  AcessNet
//
//  Tarjeta "Wallet-o-meter": muestra costo en pesos, litros, CO₂
//  y ahorro vs la ruta más cara. Integrada en RouteInfoCard.
//

import SwiftUI

struct FuelWalletMeter: View {
    let estimate: FuelEstimate
    let maxCostInBatch: Double?      // Para calcular ahorro vs más cara
    let compact: Bool

    init(estimate: FuelEstimate, maxCostInBatch: Double? = nil, compact: Bool = false) {
        self.estimate = estimate
        self.maxCostInBatch = maxCostInBatch
        self.compact = compact
    }

    var body: some View {
        if compact {
            compactBody
        } else {
            fullBody
        }
    }

    // MARK: - Compact (una línea)

    private var compactBody: some View {
        HStack(spacing: 10) {
            Image(systemName: "pesosign.circle.fill")
                .foregroundColor(.green)
            Text(estimate.pesosFormatted)
                .font(.subheadline.bold())
                .monospacedDigit()
            Text("·")
                .foregroundColor(.secondary)
            Text(estimate.litersFormatted)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let savings = savingsVsMax, savings > 5 {
                Spacer(minLength: 6)
                savingsBadge(savings)
            }
        }
    }

    // MARK: - Full

    private var fullBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    Text("GasolinaMeter")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                } icon: {
                    Image(systemName: "fuelpump.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Spacer()
                confidencePill
            }

            HStack(spacing: 18) {
                // Pesos
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "pesosign.circle.fill")
                            .foregroundColor(.green)
                        Text("\(Int(estimate.pesosCost.rounded()))")
                            .font(.system(.title2, design: .rounded).bold())
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    Text(String(format: "%.2f L", estimate.liters))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider().frame(height: 36)

                // CO2
                VStack(alignment: .leading, spacing: 2) {
                    Text(estimate.co2Formatted)
                        .font(.subheadline.bold())
                        .monospacedDigit()
                    Text("CO₂ emitido")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)

                if let savings = savingsVsMax, savings > 5 {
                    savingsBadge(savings)
                }
            }

            if !estimate.breakdownLines.isEmpty {
                // Factores visibles bajo demanda
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(estimate.breakdownLines, id: \.self) { line in
                            Text("• \(line)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Desglose")
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: estimate.pesosCost)
    }

    // MARK: - Subviews

    private var confidencePill: some View {
        HStack(spacing: 3) {
            Image(systemName: confidenceIcon)
                .font(.caption2)
            Text("\(estimate.confidencePct)%")
                .font(.caption2.bold())
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(confidenceColor.opacity(0.15))
        .foregroundColor(confidenceColor)
        .cornerRadius(8)
    }

    private func savingsBadge(_ savings: Double) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.caption2)
            Text("-$\(Int(savings.rounded()))")
                .font(.caption.bold())
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.2))
        .foregroundColor(.green)
        .cornerRadius(8)
        .accessibilityLabel("Ahorras \(Int(savings.rounded())) pesos")
    }

    // MARK: - Computed

    private var savingsVsMax: Double? {
        guard let max = maxCostInBatch, max > estimate.pesosCost else { return nil }
        return max - estimate.pesosCost
    }

    private var confidenceIcon: String {
        switch estimate.confidencePct {
        case 80...: return "checkmark.seal.fill"
        case 65..<80: return "checkmark.seal"
        default: return "questionmark.diamond"
        }
    }

    private var confidenceColor: Color {
        switch estimate.confidencePct {
        case 80...: return .green
        case 65..<80: return .blue
        default: return .orange
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Full") {
    FuelWalletMeter(
        estimate: FuelEstimate(
            liters: 1.82,
            pesosCost: 43.30,
            co2Kg: 4.35,
            pm25Grams: 0.022,
            confidence: 0.85,
            distanceKm: 8.4,
            durationMin: 28,
            avgSpeedKmh: 32,
            avgGradePct: -0.3,
            stopsEstimated: 21,
            temperatureC: 22,
            vehicleDisplay: "Nissan Versa 2019",
            breakdown: FuelBreakdown(
                baseLiters: 1.71, altitudeFactor: 0.965, gradeFactor: 1.01,
                trafficFactor: 1.08, acFactor: 1.0, windFactor: 1.02,
                styleFactor: 1.05, speedFactor: 1.0, passengerFactor: 1.0
            ),
            kwh: nil
        ),
        maxCostInBatch: 55.80
    )
    .padding()
}

#Preview("Compact") {
    FuelWalletMeter(
        estimate: FuelEstimate(
            liters: 1.82, pesosCost: 43.30, co2Kg: 4.35, pm25Grams: 0.022,
            confidence: 0.85, distanceKm: 8.4, durationMin: 28,
            avgSpeedKmh: 32, avgGradePct: nil, stopsEstimated: nil,
            temperatureC: nil, vehicleDisplay: nil, breakdown: nil, kwh: nil
        ),
        maxCostInBatch: 55.80,
        compact: true
    )
    .padding()
}
#endif
