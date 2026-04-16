//
//  DriversPanel.swift
//  AcessNet
//
//  Panel "¿Por qué?" — muestra top drivers que empujan la predicción.
//

import SwiftUI

struct DriversPanel: View {
    let drivers: [ForecastDriver]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.blue)
                Text("¿Por qué esta probabilidad?")
                    .font(.headline)
            }

            ForEach(drivers.prefix(5)) { driver in
                DriverRow(driver: driver)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

private struct DriverRow: View {
    let driver: ForecastDriver

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(driver.humanName)
                    .font(.subheadline.weight(.medium))
                if let value = driver.value {
                    Text(formatValue(value))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            ImportanceBar(importance: driver.importance)
                .frame(width: 60, height: 6)
        }
    }

    private func formatValue(_ v: Double) -> String {
        if abs(v) >= 100 {
            return String(format: "%.0f", v)
        } else if abs(v) >= 1 {
            return String(format: "%.1f", v)
        } else {
            return String(format: "%.3f", v)
        }
    }
}

private struct ImportanceBar: View {
    let importance: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.blue)
                    .frame(width: geo.size.width * min(1.0, importance * 10))
            }
        }
    }
}
