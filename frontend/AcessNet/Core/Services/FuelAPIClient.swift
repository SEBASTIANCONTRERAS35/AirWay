//
//  FuelAPIClient.swift
//  AcessNet
//
//  Cliente HTTP para endpoints /api/v1/fuel/*
//  Backend Django (ver backend-api/src/interfaces/api/fuel/).
//

import Foundation
import os

// MARK: - Errors

enum FuelAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int, String?)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .invalidResponse: return "Respuesta del servidor inválida"
        case .serverError(let code, let msg):
            return "Error del servidor (\(code)): \(msg ?? "desconocido")"
        case .decoding(let e): return "Error decodificando: \(e.localizedDescription)"
        case .network(let e): return "Error de red: \(e.localizedDescription)"
        }
    }
}

// MARK: - Client

final class FuelAPIClient {
    static let shared = FuelAPIClient()

    /// Override en tests / dev.
    var baseURL: URL {
        if let env = ProcessInfo.processInfo.environment["AIRWAY_API_BASE_URL"],
           let u = URL(string: env) {
            return u
        }
        return AppConfig.backendBaseURL
    }

    private let session: URLSession
    private let decoder: JSONDecoder

    private init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys  // respetamos snake_case manualmente en modelos
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Estimate

    func estimate(
        polyline: String,
        vehicle: VehicleProfile,
        durationMin: Double? = nil,
        passengers: Int = 1,
        departAt: Date? = nil,
        fuelPriceOverride: Double? = nil
    ) async throws -> FuelEstimate {
        let url = baseURL.appendingPathComponent("api/v1/fuel/estimate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30

        var body: [String: Any] = [
            "polyline": polyline,
            "vehicle": vehicle.toAPIDictionary(),
            "passengers": passengers,
        ]
        if let d = durationMin { body["duration_min"] = d }
        if let dep = departAt {
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            body["depart_at"] = fmt.string(from: dep)
        }
        if let price = fuelPriceOverride { body["fuel_price_override"] = price }

        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        AirWayLogger.fuel.info(
            "FuelAPI.estimate vehicle=\(vehicle.fullDisplayName, privacy: .public) polyline_len=\(polyline.count, privacy: .public) duration=\(String(describing: durationMin), privacy: .public)"
        )
        AirWayLogger.network.httpRequest(method: "POST", url: url, bodySize: req.httpBody?.count)

        let estimate: FuelEstimate = try await performRequest(req)
        AirWayLogger.fuel.info(
            "FuelAPI.estimate result L=\(String(format: "%.2f", estimate.liters), privacy: .public) $=\(String(format: "%.2f", estimate.pesosCost), privacy: .public) CO2=\(String(format: "%.2f", estimate.co2Kg), privacy: .public)kg conf=\(estimate.confidencePct, privacy: .public)%"
        )
        return estimate
    }

    // MARK: - Catalog

    func fetchCatalog() async throws -> CatalogResponse {
        let url = baseURL.appendingPathComponent("api/v1/fuel/catalog")
        let req = URLRequest(url: url)
        return try await performRequest(req)
    }

    func searchCatalog(query: String, limit: Int = 10) async throws -> CatalogSearchResponse {
        guard var comps = URLComponents(
            url: baseURL.appendingPathComponent("api/v1/fuel/catalog/search"),
            resolvingAgainstBaseURL: true
        ) else { throw FuelAPIError.invalidURL }
        comps.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        guard let url = comps.url else { throw FuelAPIError.invalidURL }
        let req = URLRequest(url: url)
        return try await performRequest(req)
    }

    // MARK: - Prices

    func fetchPrices() async throws -> FuelPrices {
        let url = baseURL.appendingPathComponent("api/v1/fuel/prices")
        let req = URLRequest(url: url)
        return try await performRequest(req)
    }

    // MARK: - Private helpers

    private func performRequest<T: Decodable>(_ req: URLRequest) async throws -> T {
        let startT = Date()
        do {
            let (data, resp) = try await session.data(for: req)
            let elapsedMs = Date().timeIntervalSince(startT) * 1000
            guard let http = resp as? HTTPURLResponse else {
                AirWayLogger.network.error("FuelAPI invalid response type")
                throw FuelAPIError.invalidResponse
            }
            let url = req.url ?? URL(string: "unknown://")!
            AirWayLogger.network.httpResponse(url: url, status: http.statusCode,
                                              bytes: data.count, durationMs: elapsedMs)
            guard (200..<300).contains(http.statusCode) else {
                let errText = String(data: data, encoding: .utf8)
                AirWayLogger.network.error("FuelAPI server error \(http.statusCode): \(errText ?? "?", privacy: .public)")
                throw FuelAPIError.serverError(http.statusCode, errText)
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                AirWayLogger.network.error("FuelAPI decode error: \(error.localizedDescription, privacy: .public)")
                throw FuelAPIError.decoding(error)
            }
        } catch let err as FuelAPIError {
            throw err
        } catch {
            AirWayLogger.network.httpError(url: req.url ?? URL(string: "unknown://")!, error: error)
            throw FuelAPIError.network(error)
        }
    }
}

// MARK: - Response wrappers

struct CatalogResponse: Codable {
    let makes: [String]?
    let vehicles: [ConueeVehicleEntry]?
    let make: String?
    let models: [String]?
}

struct CatalogSearchResponse: Codable {
    let query: String
    let results: [ConueeVehicleEntry]
}
