//
//  HorizonCard.swift
//  AcessNet
//
//  Tarjeta compacta por horizonte (24h / 48h / 72h).
//

import SwiftUI

struct HorizonCard: View {
    let forecast: HorizonForecast

    private var color: Color {
        switch forecast.probabilityLevel {
        case .low:      return .green
        case .moderate: return .yellow
        case .high:     return .orange
        case .veryHigh: return .red
        }
    }

    private var horizonLabel: String {
        switch forecast.horizonH {
        case 24: return "Mañana"
        case 48: return "Pasado"
        case 72: return "En 3 días"
        default: return "\(forecast.horizonH) h"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(horizonLabel)
                    .font(.subheadline.bold())
                Spacer()
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
            }

            Text("\(forecast.probabilityPercent)%")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(color)

            ProgressView(value: forecast.probFase1O3)
                .tint(color)

            Text("O₃: \(Int(round(forecast.o3ExpectedPpb))) ppb")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}
