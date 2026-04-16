//
//  VehicleVisionAPI.swift
//  AcessNet
//
//  Cliente para identificación de vehículo vía Gemini Vision.
//

import Foundation
import UIKit
import os

final class VehicleVisionAPI {
    static let shared = VehicleVisionAPI()

    private let session: URLSession = .shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var baseURL: URL { AppConfig.backendBaseURL }

    // MARK: - Main entrypoint

    func identify(image: UIImage, compressionQuality: CGFloat = 0.6) async throws -> VehicleVisionResult {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw FuelAPIError.invalidResponse
        }
        let b64 = data.base64EncodedString()
        return try await identify(imageB64: b64, mimeType: "image/jpeg")
    }

    func identify(imageB64: String, mimeType: String = "image/jpeg") async throws -> VehicleVisionResult {
        let url = baseURL.appendingPathComponent("api/v1/vehicle/identify_from_image")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 50   // Gemini Vision puede tardar

        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "image": imageB64,
            "mime_type": mimeType,
        ])

        let sizeKb = Double(imageB64.count) * 3 / 4 / 1024
        AirWayLogger.vision.info(
            "VehicleVisionAPI.identify mime=\(mimeType, privacy: .public) size=\(String(format: "%.1f", sizeKb), privacy: .public)KB"
        )
        AirWayLogger.network.httpRequest(method: "POST", url: url, bodySize: req.httpBody?.count)

        let startT = Date()
        let (data, resp) = try await session.data(for: req)
        let elapsedMs = Date().timeIntervalSince(startT) * 1000
        guard let http = resp as? HTTPURLResponse else {
            AirWayLogger.vision.error("VehicleVisionAPI invalid response")
            throw FuelAPIError.invalidResponse
        }
        AirWayLogger.network.httpResponse(url: url, status: http.statusCode,
                                          bytes: data.count, durationMs: elapsedMs)
        guard (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8)
            AirWayLogger.vision.error("VehicleVisionAPI \(http.statusCode): \(errText ?? "", privacy: .public)")
            throw FuelAPIError.serverError(http.statusCode, errText)
        }
        let result = try decoder.decode(VehicleVisionResult.self, from: data)
        AirWayLogger.vision.info(
            "VehicleVisionAPI result success=\(result.success, privacy: .public) type=\(result.type ?? "?", privacy: .public) conf=\(result.confidencePct, privacy: .public)% make=\(result.make ?? "-", privacy: .public) model=\(result.model ?? "-", privacy: .public)"
        )
        return result
    }
}
