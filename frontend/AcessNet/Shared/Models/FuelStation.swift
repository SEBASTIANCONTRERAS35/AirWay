//
//  FuelStation.swift
//  AcessNet
//
//  Modelo de gasolinera con precio y distancia al usuario/ruta.
//  Respuesta de /api/v1/fuel/stations_near y /stations_on_route.
//

import Foundation
import CoreLocation

struct FuelStation: Codable, Identifiable, Equatable {
    let id: String
    let brand: String
    let name: String
    let address: String
    let lat: Double
    let lon: Double
    let price: Double              // precio para el fuelType solicitado
    let fuelType: String?
    let distanceM: Int?            // distancia al usuario o a la ruta (según endpoint)
    let savingsPerLiter: Double?   // ahorro vs promedio dataset

    enum CodingKeys: String, CodingKey {
        case id, brand, name, address, lat, lon, price
        case fuelType = "fuel_type"
        case distanceM = "distance_m"
        case savingsPerLiter = "savings_per_liter"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var distanceKmFormatted: String {
        guard let m = distanceM else { return "—" }
        if m < 1000 { return "\(m) m" }
        return String(format: "%.1f km", Double(m) / 1000)
    }

    var priceFormatted: String {
        String(format: "$%.2f", price)
    }

    var savingsFormatted: String? {
        guard let s = savingsPerLiter, s > 0.01 else { return nil }
        return String(format: "-$%.2f / L", s)
    }
}

struct FuelStationsResponse: Codable {
    let fuelType: String
    let averagePrice: Double
    let count: Int
    let stations: [FuelStation]

    enum CodingKeys: String, CodingKey {
        case fuelType = "fuel_type"
        case averagePrice = "average_price"
        case count, stations
    }
}
