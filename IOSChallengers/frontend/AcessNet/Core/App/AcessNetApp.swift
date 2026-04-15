//
//  AirWayApp.swift
//  AirWay
//
//  Created by Emilio Cruz Vargas on 21/09/25.
//

import SwiftUI
import UserNotifications

@main
struct AirWayApp: App {
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
