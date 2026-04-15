import Foundation
import CoreLocation

struct WatchCoordinate: Codable {
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
}

struct WatchRouteData: Codable {
    let distanceFormatted: String
    let timeFormatted: String
    let coordinates: [WatchCoordinate]
    let averageAQI: Int
    let qualityLevel: String
    let destinationName: String
    let trafficIncidents: Int
    let hazardIncidents: Int
    let safetyScore: Double
}

struct WatchMessage: Codable {
    enum MessageType: String, Codable {
        case routeCreated
        case routeCleared
        case requestCurrentRoute
    }

    let type: MessageType
    let route: WatchRouteData?

    init(type: MessageType, route: WatchRouteData? = nil) {
        self.type = type
        self.route = route
    }
}
