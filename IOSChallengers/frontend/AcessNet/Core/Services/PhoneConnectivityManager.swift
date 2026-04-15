//
//  PhoneConnectivityManager.swift
//  AcessNet
//
//  Gestor de conectividad para enviar rutas desde iPhone al Apple Watch
//

import Foundation
import WatchConnectivity
import Combine
import CoreLocation
import MapKit

class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()

    // MARK: - Published Properties
    @Published var isWatchConnected: Bool = false
    @Published var lastMessageSent: Date?

    // MARK: - Private Properties
    private var session: WCSession?

    // MARK: - Initialization
    private override init() {
        super.init()
        setupWatchConnectivity()
    }

    // MARK: - Setup
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("⚠️ WatchConnectivity no está soportado en este dispositivo")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()

        print("📱 PhoneConnectivityManager configurado y activando...")
    }

    // MARK: - Public Methods

    /// Envía una ruta al Apple Watch
    func sendRouteToWatch(from scoredRoute: ScoredRoute, destinationName: String) {
        guard let session = session else {
            print("⚠️ WCSession no está disponible")
            return
        }

        // Convertir coordenadas del polyline
        let coordinates = scoredRoute.routeInfo.route.polyline.coordinates()
        let watchCoordinates = coordinates.map { WatchCoordinate(from: $0) }

        // Crear modelo para Watch
        let watchRoute = WatchRouteData(
            distanceFormatted: scoredRoute.routeInfo.distanceFormatted,
            timeFormatted: scoredRoute.routeInfo.timeFormatted,
            coordinates: watchCoordinates,
            averageAQI: Int(scoredRoute.averageAQI),
            qualityLevel: scoredRoute.averageAQILevel.rawValue,
            destinationName: destinationName,
            trafficIncidents: scoredRoute.incidentAnalysis?.trafficCount ?? 0,
            hazardIncidents: scoredRoute.incidentAnalysis?.hazardCount ?? 0,
            safetyScore: scoredRoute.incidentAnalysis?.safetyScore ?? 100.0
        )

        sendRoute(watchRoute, messageType: .routeCreated)
    }

    /// Limpia la ruta en el Apple Watch
    func clearRouteOnWatch() {
        let message = WatchMessage(type: .routeCleared)
        sendMessage(message)
    }

    // MARK: - Private Methods

    private func sendRoute(_ route: WatchRouteData, messageType: WatchMessage.MessageType) {
        let message = WatchMessage(type: messageType, route: route)
        sendMessage(message)
    }

    private func sendMessage(_ message: WatchMessage) {
        guard let session = session else {
            print("⚠️ WCSession no está disponible")
            return
        }

        do {
            let data = try JSONEncoder().encode(message)
            let dictionary = ["message": data]

            // Intentar enviar mensaje interactivo si el Watch está disponible
            if session.isReachable {
                session.sendMessage(dictionary, replyHandler: { reply in
                    print("✅ Watch respondió: \(reply)")
                }, errorHandler: { error in
                    print("❌ Error enviando mensaje al Watch: \(error.localizedDescription)")
                    // Intentar transferir en segundo plano
                    self.transferUserInfo(dictionary)
                })
            } else {
                // Watch no está alcanzable, transferir en segundo plano
                print("⏳ Watch no alcanzable, transfiriendo en segundo plano...")
                self.transferUserInfo(dictionary)
            }

            DispatchQueue.main.async {
                self.lastMessageSent = Date()
            }

            print("📤 Mensaje enviado al Watch: \(message.type.rawValue)")
        } catch {
            print("❌ Error codificando mensaje para Watch: \(error.localizedDescription)")
        }
    }

    private func transferUserInfo(_ dictionary: [String: Any]) {
        guard let session = session else { return }
        session.transferUserInfo(dictionary)
        print("📦 UserInfo transferido al Watch en segundo plano")
    }

    private func handleWatchRequest(_ message: WatchMessage, replyHandler: @escaping ([String: Any]) -> Void) {
        switch message.type {
        case .requestCurrentRoute:
            // El Watch solicita la ruta actual
            // Aquí deberías obtener la ruta actual del RouteManager
            print("📨 Watch solicita ruta actual")
            // Por ahora, enviar respuesta vacía
            replyHandler(["status": "no_route"])
        default:
            replyHandler(["status": "unknown_request"])
        }
    }
}

// MARK: - WCSessionDelegate
extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = (activationState == .activated && session.isPaired && session.isWatchAppInstalled)

            if let error = error {
                print("❌ Error activando WCSession en iPhone: \(error.localizedDescription)")
            } else {
                print("✅ WCSession activado en iPhone con estado: \(activationState.rawValue)")
                print("   - Paired: \(session.isPaired)")
                print("   - Watch App Installed: \(session.isWatchAppInstalled)")
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⏸️ WCSession quedó inactiva")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("🔄 WCSession desactivada, reactivando...")
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📨 Mensaje con respuesta recibido del Watch")

        if let data = message["message"] as? Data {
            do {
                let watchMessage = try JSONDecoder().decode(WatchMessage.self, from: data)
                handleWatchRequest(watchMessage, replyHandler: replyHandler)
            } catch {
                print("❌ Error decodificando mensaje del Watch: \(error.localizedDescription)")
                replyHandler(["status": "error", "message": error.localizedDescription])
            }
        }
    }
}

