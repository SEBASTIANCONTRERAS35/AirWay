//
//  NotificationHandler.swift
//  AcessNet
//
//  Created to present local notifications while the app is in foreground.
//

import UserNotifications

final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    // Present notifications as banner/sound/badge when app is active
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
