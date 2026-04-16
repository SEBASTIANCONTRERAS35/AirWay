//
//  FuelStationSuggestionBanner.swift
//  AcessNet
//
//  Banner sugiriendo la gasolinera más barata en la ruta del usuario.
//  Se dispara cuando el nivel de tanque es bajo (Fase 7+) o manualmente.
//

import SwiftUI
import MapKit

struct FuelStationSuggestionBanner: View {
    let station: FuelStation
    let averagePrice: Double
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            brandBadge

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(station.brand)
                        .font(.subheadline.bold())
                    Text("a \(station.distanceKmFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    Text(station.priceFormatted)
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .foregroundColor(.green)
                    if let savings = station.savingsFormatted {
                        Text(savings)
                            .font(.caption.bold())
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
                Text(station.address)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.12), Color.yellow.opacity(0.08)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(14)
        .onTapGesture(perform: onTap)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var brandBadge: some View {
        ZStack {
            Circle().fill(brandColor.opacity(0.2))
            Image(systemName: "fuelpump.fill")
                .font(.title2)
                .foregroundColor(brandColor)
        }
        .frame(width: 44, height: 44)
    }

    private var brandColor: Color {
        switch station.brand.lowercased() {
        case "pemex": return .green
        case "shell": return .yellow
        case "bp": return .green
        case "mobil": return .blue
        default: return .orange
        }
    }
}

// MARK: - Open in Maps helper

extension FuelStation {
    /// Abre la estación en Apple Maps con driving directions.
    func openInMaps() {
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        FuelStationSuggestionBanner(
            station: FuelStation(
                id: "1", brand: "Pemex", name: "Pemex Reforma",
                address: "Paseo de la Reforma 100, Juárez",
                lat: 19.4356, lon: -99.1531, price: 23.62,
                fuelType: "magna", distanceM: 400, savingsPerLiter: 0.68
            ),
            averagePrice: 24.30,
            onTap: {},
            onDismiss: {}
        )

        FuelStationSuggestionBanner(
            station: FuelStation(
                id: "2", brand: "Shell", name: "Shell Polanco",
                address: "Av. Masaryk 61, Polanco",
                lat: 19.43, lon: -99.20, price: 24.10,
                fuelType: "magna", distanceM: 1200, savingsPerLiter: 0.20
            ),
            averagePrice: 24.30,
            onTap: {},
            onDismiss: {}
        )
    }
    .padding()
}
#endif
