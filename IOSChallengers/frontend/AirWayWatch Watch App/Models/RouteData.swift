//
//  RouteData.swift
//  AirWayWatch Watch App
//
//  Modelo de datos compartido para rutas entre iPhone y Watch
//

import Foundation
import CoreLocation

/// Modelo simplificado de ruta para Apple Watch
struct WatchRouteData: Codable, Identifiable {
    let id: String
    let distanceFormatted: String
    let timeFormatted: String
    let coordinates: [WatchCoordinate]
    let averageAQI: Int
    let qualityLevel: String
    let destinationName: String

    // Información adicional
    let trafficIncidents: Int
    let hazardIncidents: Int
    let safetyScore: Double

    init(
        id: String = UUID().uuidString,
        distanceFormatted: String,
        timeFormatted: String,
        coordinates: [WatchCoordinate],
        averageAQI: Int,
        qualityLevel: String,
        destinationName: String,
        trafficIncidents: Int = 0,
        hazardIncidents: Int = 0,
        safetyScore: Double = 100.0
    ) {
        self.id = id
        self.distanceFormatted = distanceFormatted
        self.timeFormatted = timeFormatted
        self.coordinates = coordinates
        self.averageAQI = averageAQI
        self.qualityLevel = qualityLevel
        self.destinationName = destinationName
        self.trafficIncidents = trafficIncidents
        self.hazardIncidents = hazardIncidents
        self.safetyScore = safetyScore
    }

    var aqiColor: String {
        switch averageAQI {
        case 0..<51: return "#7BC043"
        case 51..<101: return "#FDD835"
        case 101..<151: return "#FF9800"
        default: return "#E53935"
        }
    }

    var riskLevel: String {
        switch safetyScore {
        case 80...100: return "Low Risk"
        case 60..<80: return "Medium Risk"
        case 40..<60: return "High Risk"
        default: return "Critical Risk"
        }
    }
}

/// Coordenada codificable para transferir entre dispositivos
struct WatchCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Mensaje de comunicación entre iPhone y Watch
struct WatchMessage: Codable {
    enum MessageType: String, Codable {
        case routeCreated
        case routeUpdated
        case routeCleared
        case requestCurrentRoute
    }

    let type: MessageType
    let route: WatchRouteData?
    let timestamp: Date

    init(type: MessageType, route: WatchRouteData? = nil) {
        self.type = type
        self.route = route
        self.timestamp = Date()
    }
}

// MARK: - Sample Data for Testing
extension WatchRouteData {
    static var sample: WatchRouteData {
        WatchRouteData(
            distanceFormatted: "5.2 km",
            timeFormatted: "12 min",
            coordinates: [
                WatchCoordinate(latitude: 19.2827, longitude: -99.6525),
                WatchCoordinate(latitude: 19.2900, longitude: -99.6400),
                WatchCoordinate(latitude: 19.2950, longitude: -99.6350),
                WatchCoordinate(latitude: 19.3000, longitude: -99.6300)
            ],
            averageAQI: 65,
            qualityLevel: "Moderate",
            destinationName: "Starbucks Centro",
            trafficIncidents: 2,
            hazardIncidents: 1,
            safetyScore: 75.0
        )
    }
}
