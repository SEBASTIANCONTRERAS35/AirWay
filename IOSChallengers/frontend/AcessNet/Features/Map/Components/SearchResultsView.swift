//
//  SearchResultsView.swift
//  AcessNet
//
//  Vista de resultados de búsqueda de ubicaciones
//

import SwiftUI
import CoreLocation

// MARK: - Search Results View

struct SearchResultsView: View {
    let results: [SearchResult]
    let isSearching: Bool
    let userLocation: CLLocationCoordinate2D?
    let onSelect: (SearchResult) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                searchingView
            } else if results.isEmpty {
                emptyResultsView
            } else {
                resultsList
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
    }

    // MARK: - Subviews

    private var searchingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.9)

            Text("Searching...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
    }

    private var emptyResultsView: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("No results found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
    }

    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(results) { result in
                    SearchResultRow(
                        result: result,
                        userLocation: userLocation,
                        onSelect: { onSelect(result) }
                    )

                    if result.id != results.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
        .frame(maxHeight: 300) // Máximo 5-6 resultados visibles
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SearchResult
    let userLocation: CLLocationCoordinate2D?
    let onSelect: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onSelect()
            }
        }) {
            HStack(spacing: 12) {
                // Icono de tipo de lugar
                Image(systemName: result.placeType.icon)
                    .font(.title2)
                    .foregroundStyle(colorForPlaceType(result.placeType))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(colorForPlaceType(result.placeType).opacity(0.1))
                    )

                // Información del lugar
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Distancia (si hay coordenadas y ubicación del usuario)
                if let distance = calculateDistance() {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(distance)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? Color.gray.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func calculateDistance() -> String? {
        guard let userLocation = userLocation,
              let resultCoordinate = result.coordinate else {
            return nil
        }

        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let resultLoc = CLLocation(latitude: resultCoordinate.latitude, longitude: resultCoordinate.longitude)

        let distanceInMeters = userLoc.distance(from: resultLoc)

        if distanceInMeters < 1000 {
            return String(format: "%.0f m", distanceInMeters)
        } else {
            return String(format: "%.1f km", distanceInMeters / 1000)
        }
    }

    private func colorForPlaceType(_ type: PlaceType) -> Color {
        switch type {
        case .food:
            return .orange
        case .entertainment:
            return .purple
        case .shopping:
            return .blue
        case .transportation:
            return .green
        case .health:
            return .red
        case .nature:
            return .green
        case .generic:
            return .gray
        }
    }
}

// MARK: - Recent Searches View (opcional, futuro)

struct RecentSearchesView: View {
    let recentSearches: [SearchHistoryItem]
    let onSelect: (SearchHistoryItem) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recent Searches")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear", action: onClear)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Lista de búsquedas recientes
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(recentSearches) { search in
                        Button(action: {
                            onSelect(search)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(search.title)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    if !search.subtitle.isEmpty {
                                        Text(search.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Image(systemName: "arrow.up.backward")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        if search.id != recentSearches.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
    }
}

// MARK: - Preview

#Preview("Search Results") {
    VStack {
        Spacer()

        SearchResultsView(
            results: [
                SearchResult(
                    title: "Starbucks",
                    subtitle: "123 Main Street, San Francisco",
                    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                ),
                SearchResult(
                    title: "Apple Park",
                    subtitle: "One Apple Park Way, Cupertino",
                    coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
                ),
                SearchResult(
                    title: "Golden Gate Bridge",
                    subtitle: "San Francisco, CA",
                    coordinate: CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783)
                )
            ],
            isSearching: false,
            userLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            onSelect: { result in
                print("Selected: \(result.title)")
            }
        )
        .padding()

        Spacer()
    }
}

#Preview("Searching") {
    VStack {
        Spacer()

        SearchResultsView(
            results: [],
            isSearching: true,
            userLocation: nil,
            onSelect: { _ in }
        )
        .padding()

        Spacer()
    }
}

#Preview("No Results") {
    VStack {
        Spacer()

        SearchResultsView(
            results: [],
            isSearching: false,
            userLocation: nil,
            onSelect: { _ in }
        )
        .padding()

        Spacer()
    }
}
