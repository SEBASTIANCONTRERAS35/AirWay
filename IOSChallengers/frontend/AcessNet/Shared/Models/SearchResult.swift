//
//  SearchResult.swift
//  AcessNet
//
//  Modelo para resultados de búsqueda de ubicaciones
//

import Foundation
import MapKit
import CoreLocation

// MARK: - Search Result Model

struct SearchResult: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D?
    let mapItem: MKMapItem?

    init(id: UUID = UUID(), title: String, subtitle: String, coordinate: CLLocationCoordinate2D? = nil, mapItem: MKMapItem? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.mapItem = mapItem
    }

    // Inicializador desde MKLocalSearchCompletion
    init(from completion: MKLocalSearchCompletion) {
        self.id = UUID()
        self.title = completion.title
        self.subtitle = completion.subtitle
        self.coordinate = nil
        self.mapItem = nil
    }

    // Inicializador desde MKMapItem (después de búsqueda completa)
    init(from mapItem: MKMapItem) {
        self.id = UUID()
        self.title = mapItem.name ?? "Unknown"
        self.subtitle = mapItem.placemark.title ?? ""
        self.coordinate = mapItem.placemark.coordinate
        self.mapItem = mapItem
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Helper Properties

    /// Tipo de lugar basado en el mapItem
    var placeType: PlaceType {
        guard let mapItem = mapItem else { return .generic }

        // Categorías de MKPointOfInterestCategory
        if let category = mapItem.pointOfInterestCategory {
            switch category {
            case .restaurant, .cafe, .bakery, .brewery, .winery:
                return .food
            case .hotel, .museum, .theater, .movieTheater, .nightlife:
                return .entertainment
            case .store, .pharmacy:
                return .shopping
            case .gasStation, .evCharger, .parking:
                return .transportation
            case .hospital:
                return .health
            case .park, .beach:
                return .nature
            default:
                return .generic
            }
        }

        return .generic
    }

    /// Formato de dirección completa
    var fullAddress: String {
        guard let placemark = mapItem?.placemark else { return subtitle }

        var components: [String] = []

        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }

        return components.isEmpty ? subtitle : components.joined(separator: ", ")
    }
}

// MARK: - Place Type Enum

enum PlaceType {
    case food
    case entertainment
    case shopping
    case transportation
    case health
    case nature
    case generic

    var icon: String {
        switch self {
        case .food:
            return "fork.knife.circle.fill"
        case .entertainment:
            return "theatermasks.circle.fill"
        case .shopping:
            return "cart.circle.fill"
        case .transportation:
            return "car.circle.fill"
        case .health:
            return "cross.circle.fill"
        case .nature:
            return "tree.circle.fill"
        case .generic:
            return "mappin.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .food:
            return "orange"
        case .entertainment:
            return "purple"
        case .shopping:
            return "blue"
        case .transportation:
            return "green"
        case .health:
            return "red"
        case .nature:
            return "green"
        case .generic:
            return "gray"
        }
    }
}

// MARK: - Search History Item

/// Modelo para historial de búsquedas (opcional, para feature futuro)
struct SearchHistoryItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let timestamp: Date

    init(id: UUID = UUID(), title: String, subtitle: String, timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.timestamp = timestamp
    }

    init(from searchResult: SearchResult) {
        self.id = UUID()
        self.title = searchResult.title
        self.subtitle = searchResult.subtitle
        self.timestamp = Date()
    }
}
