//
//  ProbabilityGauge.swift
//  AcessNet
//
//  Gauge circular animado para mostrar probabilidad de contingencia.
//

import SwiftUI

struct ProbabilityGauge: View {
    let probability: Double        // 0.0–1.0
    let ci80Lower: Double?
    let ci80Upper: Double?
    let o3ExpectedPpb: Double
    let horizonHours: Int

    @State private var animatedProbability: Double = 0

    private var level: ProbabilityLevel {
        switch probability {
        case 0..<0.3:   return .low
        case 0.3..<0.6: return .moderate
        case 0.6..<0.8: return .high
        default:        return .veryHigh
        }
    }

    private var color: Color {
        switch level {
        case .low:      return .green
        case .moderate: return .yellow
        case .high:     return .orange
        case .veryHigh: return .red
        }
    }

    var body: some View {
        ZStack {
            // Fondo
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 22)

            // Arco de probabilidad
            Circle()
                .trim(from: 0, to: CGFloat(animatedProbability))
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.6), color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.2, dampingFraction: 0.7), value: animatedProbability)

            // Centro
            VStack(spacing: 4) {
                Text("\(Int(round(probability * 100)))%")
                    .font(.system(size: 62, weight: .bold, design: .rounded))
                    .foregroundColor(color)

                Text(level.label.uppercased())
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundColor(color.opacity(0.85))

                Text("prob. Fase 1 en \(horizonHours) h")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let lo = ci80Lower, let hi = ci80Upper {
                    Text("O₃ esperado: \(Int(round(o3ExpectedPpb))) ppb [\(Int(round(lo))) – \(Int(round(hi)))]")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
        }
        .onAppear {
            animatedProbability = probability
        }
        .onChange(of: probability) { _, newValue in
            animatedProbability = newValue
        }
    }
}
