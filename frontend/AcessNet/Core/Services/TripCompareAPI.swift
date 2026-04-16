//
//  TripCompareAPI.swift
//  AcessNet
//
//  Cliente para /api/v1/trip/compare.
//

import Foundation
import CoreLocation
import os

final class TripCompareAPI {
    static let shared = TripCompareAPI()

    private let session: URLSession = .shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var baseURL: URL { AppConfig.backendBaseURL }

    func compare(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        vehicle: VehicleProfile? = nil,
        includeAIInsight: Bool = true
    ) async throws -> TripCompareResponse {
        let url = baseURL.appendingPathComponent("api/v1/trip/compare")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 45

        var body: [String: Any] = [
            "origin": ["lat": origin.latitude, "lon": origin.longitude],
            "destination": ["lat": destination.latitude, "lon": destination.longitude],
            "include_ai_insight": includeAIInsight,
        ]
        if let v = vehicle {
            body["vehicle"] = v.toAPIDictionary()
        }

        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        AirWayLogger.trip.info(
            "TripCompareAPI.compare origin=\(origin.latitude, privacy: .private(mask: .hash)) vehicle=\(vehicle?.fullDisplayName ?? "default", privacy: .public) aiInsight=\(includeAIInsight, privacy: .public)"
        )
        AirWayLogger.network.httpRequest(method: "POST", url: url, bodySize: req.httpBody?.count)

        let startT = Date()
        let (data, resp) = try await session.data(for: req)
        let elapsedMs = Date().timeIntervalSince(startT) * 1000
        guard let http = resp as? HTTPURLResponse else {
            AirWayLogger.trip.error("TripCompareAPI invalid response")
            throw FuelAPIError.invalidResponse
        }
        AirWayLogger.network.httpResponse(url: url, status: http.statusCode,
                                          bytes: data.count, durationMs: elapsedMs)
        guard (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8)
            AirWayLogger.trip.error("TripCompareAPI \(http.statusCode): \(errText ?? "", privacy: .public)")
            throw FuelAPIError.serverError(http.statusCode, errText)
        }

        let response = try decoder.decode(TripCompareResponse.self, from: data)
        AirWayLogger.trip.info(
            "TripCompareAPI result cheapest=\(response.cheapest?.mode ?? "?", privacy: .public) $\(Int(response.cheapest?.totalCostMxn ?? 0), privacy: .public) · fastest=\(response.fastest?.mode ?? "?", privacy: .public) \(Int(response.fastest?.durationMin ?? 0), privacy: .public)min"
        )
        return response
    }
}
