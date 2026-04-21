//
//  AirWayApp.swift
//  AirWay
//
//  Created by Emilio Cruz Vargas on 21/09/25.
//

import SwiftUI
import UserNotifications

#if HAS_HUMANKIT
import HumanKit
#endif

@main
struct AirWayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let notificationHandler = NotificationHandler()
    @StateObject private var appSettings = AppSettings.shared

    init() {
        UNUserNotificationCenter.current().delegate = notificationHandler
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appSettings)
        }
    }
}

// MARK: - AppDelegate para SDKs que requieren hook en didFinishLaunchingWithOptions

/// Necesario porque el SDK BioDigital HumanKit exige que `HKServices.shared.setup(delegate:)`
/// se llame **antes** de instanciar cualquier `HKHuman`. La validación de la
/// API key/secret (leídos del bundle `BioDigital.plist`) corre de forma asíncrona
/// y notifica al delegate vía `onValidSDK()` / `onInvalidSDK()`.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if HAS_HUMANKIT
        BioDigitalConfig.debugDump()
        HKServices.shared.setup(delegate: BioDigitalSDKObserver.shared)
        print("🩺 [BioDigital] HKServices.setup() invocado — esperando validación…")
        #endif
        return true
    }
}

// MARK: - Observer global del estado de validación del SDK

/// Singleton que recibe los callbacks de `HKServicesDelegate` a nivel app.
/// Cualquier vista que muestre el modelo consulta `isValidSDK` antes de
/// instanciar `HKHuman`.
#if HAS_HUMANKIT

final class BioDigitalSDKObserver: NSObject, HKServicesDelegate {

    static let shared = BioDigitalSDKObserver()

    @objc private(set) var isValidSDK: Bool = false
    @objc private(set) var hasResolved: Bool = false

    /// Notifica a los observadores cuando cambia el estado.
    static let didChangeNotification = Notification.Name("BioDigitalSDKObserverDidChange")

    private override init() { super.init() }

    func onValidSDK() {
        print("🩺 [BioDigital] ✅ onValidSDK — credenciales aceptadas")
        isValidSDK = true
        hasResolved = true
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    func onInvalidSDK() {
        print("🩺 [BioDigital] ❌ onInvalidSDK — credenciales RECHAZADAS. Verifica:")
        print("    · BioDigital.plist en el bundle con APIKey y APISecret")
        print("    · Bundle ID del target coincide con el portal BioDigital")
        print("    · Clean build después de cambios")
        isValidSDK = false
        hasResolved = true
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    func modelsLoaded() {
        print("🩺 [BioDigital] modelsLoaded — modelos disponibles descargados")
    }
}

#else

/// Stub para cuando el SDK no está enlazado. Mantiene la misma firma pública
/// para no romper el resto del código.
final class BioDigitalSDKObserver: NSObject {
    static let shared = BioDigitalSDKObserver()
    @objc private(set) var isValidSDK: Bool = false
    @objc private(set) var hasResolved: Bool = false
    static let didChangeNotification = Notification.Name("BioDigitalSDKObserverDidChange")
    private override init() { super.init() }
}

#endif
