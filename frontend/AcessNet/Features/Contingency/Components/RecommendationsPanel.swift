//
//  RecommendationsPanel.swift
//  AcessNet
//
//  Acciones sugeridas según probabilidad + perfil del usuario.
//

import SwiftUI

struct RecommendationsPanel: View {
    let recommendations: [String]
    let probabilityLevel: ProbabilityLevel

    private var icon: String {
        switch probabilityLevel {
        case .low:      return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.circle.fill"
        case .high, .veryHigh: return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch probabilityLevel {
        case .low:      return .green
        case .moderate: return .yellow
        case .high:     return .orange
        case .veryHigh: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text("¿Qué hacer?")
                    .font(.headline)
            }

            ForEach(recommendations, id: \.self) { rec in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(iconColor)
                        .padding(.top, 7)
                    Text(rec)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}
