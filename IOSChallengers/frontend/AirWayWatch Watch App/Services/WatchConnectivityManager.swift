//
//  WatchConnectivityManager.swift
//  AirWayWatch Watch App
//
//  Gestor de conectividad entre iPhone y Apple Watch
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // MARK: - Published Properties
    @Published var currentRoute: WatchRouteData?
    @Published var isConnected: Bool = false
    @Published var lastMessageReceived: Date?

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

        print("📱 WatchConnectivity configurado y activando...")
    }

    // MARK: - Public Methods

    /// Solicita la ruta actual al iPhone
    func requestCurrentRoute() {
        guard let session = session, session.isReachable else {
            print("⚠️ iPhone no está alcanzable")
            return
        }

        let message = WatchMessage(type: .requestCurrentRoute)

        do {
            let data = try JSONEncoder().encode(message)
            let dictionary = ["message": data]

            session.sendMessage(dictionary, replyHandler: { reply in
                print("✅ Respuesta recibida del iPhone")
                self.handleReply(reply)
            }, errorHandler: { error in
                print("❌ Error enviando mensaje al iPhone: \(error.localizedDescription)")
            })
        } catch {
            print("❌ Error codificando mensaje: \(error.localizedDescription)")
        }
    }

    /// Limpia la ruta actual
    func clearRoute() {
        DispatchQueue.main.async {
            self.currentRoute = nil
        }
    }

    // MARK: - Private Methods

    private func handleReply(_ reply: [String: Any]) {
        if let data = reply["route"] as? Data {
            do {
                let route = try JSONDecoder().decode(WatchRouteData.self, from: data)
                DispatchQueue.main.async {
                    self.currentRoute = route
                    self.lastMessageReceived = Date()
                    print("🗺️ Ruta recibida: \(route.destinationName), \(route.distanceFormatted)")
                }
            } catch {
                print("❌ Error decodificando ruta: \(error.localizedDescription)")
            }
        }
    }

    private func handleReceivedMessage(_ message: WatchMessage) {
        DispatchQueue.main.async {
            self.lastMessageReceived = Date()

            switch message.type {
            case .routeCreated, .routeUpdated:
                if let route = message.route {
                    self.currentRoute = route
                    print("🗺️ Nueva ruta recibida: \(route.destinationName)")
                }
            case .routeCleared:
                self.currentRoute = nil
                print("🗑️ Ruta eliminada")
            case .requestCurrentRoute:
                // Este tipo de mensaje no debería llegar al Watch
                break
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = (activationState == .activated)

            if let error = error {
                print("❌ Error activando WCSession: \(error.localizedDescription)")
            } else {
                print("✅ WCSession activado con estado: \(activationState.rawValue)")
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📨 Mensaje recibido del iPhone")

        if let data = message["message"] as? Data {
            do {
                let watchMessage = try JSONDecoder().decode(WatchMessage.self, from: data)
                handleReceivedMessage(watchMessage)
            } catch {
                print("❌ Error decodificando mensaje: \(error.localizedDescription)")
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📨 Mensaje con respuesta recibido del iPhone")

        if let data = message["message"] as? Data {
            do {
                let watchMessage = try JSONDecoder().decode(WatchMessage.self, from: data)
                handleReceivedMessage(watchMessage)

                // Enviar confirmación
                replyHandler(["status": "received"])
            } catch {
                print("❌ Error decodificando mensaje: \(error.localizedDescription)")
                replyHandler(["status": "error", "message": error.localizedDescription])
            }
        }
    }
}
