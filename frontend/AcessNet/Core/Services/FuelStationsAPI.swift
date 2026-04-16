//
//  FuelStationsAPI.swift
//  AcessNet
//
//  Cliente para endpoints de gasolineras (/fuel/stations_*).
//

import Foundation
import CoreLocation
import os

final class FuelStationsAPI {
    static let shared = FuelStationsAPI()

    private let session: URLSession = .shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var baseURL: URL { AppConfig.backendBaseURL }

    // MARK: - Near point (GET)

    func stationsNear(
        coordinate: CLLocationCoordinate2D,
        fuelType: FuelType = .magna,
        radiusM: Int = 1500,
        limit: Int = 5
    ) async throws -> FuelStationsResponse {
        guard var comps = URLComponents(
            url: baseURL.appendingPathComponent("api/v1/fuel/stations_near"),
            resolvingAgainstBaseURL: true
        ) else { throw FuelAPIError.invalidURL }
        comps.queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(coordinate.longitude)),
            URLQueryItem(name: "fuel_type", value: fuelType.rawValue),
            URLQueryItem(name: "radius_m", value: String(radiusM)),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        guard let url = comps.url else { throw FuelAPIError.invalidURL }

        AirWayLogger.stations.info(
            "StationsAPI.near lat=\(coordinate.latitude, privacy: .private(mask: .hash)) fuel=\(fuelType.rawValue, privacy: .public) radius=\(radiusM, privacy: .public)m"
        )
        AirWayLogger.network.httpRequest(method: "GET", url: url)

        let startT = Date()
        let (data, resp) = try await session.data(for: URLRequest(url: url))
        let elapsedMs = Date().timeIntervalSince(startT) * 1000
        try Self.validate(resp, data: data)
        let response = try decoder.decode(FuelStationsResponse.self, from: data)

        AirWayLogger.network.httpResponse(url: url, status: 200, bytes: data.count, durationMs: elapsedMs)
        AirWayLogger.stations.info(
            "StationsAPI.near result count=\(response.count, privacy: .public) avg=\(String(format: "%.2f", response.averagePrice), privacy: .public)"
        )
        return response
    }

    // MARK: - On route (POST)

    func stationsOnRoute(
        polyline: String,
        fuelType: FuelType = .magna,
        bufferM: Int = 500,
        limit: Int = 5
    ) async throws -> FuelStationsResponse {
        let url = baseURL.appendingPathComponent("api/v1/fuel/stations_on_route")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "polyline": polyline,
            "fuel_type": fuelType.rawValue,
            "buffer_m": bufferM,
            "limit": limit,
        ])

        AirWayLogger.stations.info(
            "StationsAPI.onRoute polyline_len=\(polyline.count, privacy: .public) fuel=\(fuelType.rawValue, privacy: .public) buffer=\(bufferM, privacy: .public)m"
        )
        AirWayLogger.network.httpRequest(method: "POST", url: url, bodySize: req.httpBody?.count)

        let startT = Date()
        let (data, resp) = try await session.data(for: req)
        let elapsedMs = Date().timeIntervalSince(startT) * 1000
        try Self.validate(resp, data: data)
        let response = try decoder.decode(FuelStationsResponse.self, from: data)

        AirWayLogger.network.httpResponse(url: url, status: 200, bytes: data.count, durationMs: elapsedMs)
        AirWayLogger.stations.info(
            "StationsAPI.onRoute result count=\(response.count, privacy: .public) cheapest=$\(response.stations.first?.priceFormatted ?? "?", privacy: .public)"
        )
        return response
    }

    // MARK: - Validation

    private static func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw FuelAPIError.invalidResponse
        }
        if !(200..<300).contains(http.statusCode) {
            throw FuelAPIError.serverError(http.statusCode, String(data: data, encoding: .utf8))
        }
    }
}
