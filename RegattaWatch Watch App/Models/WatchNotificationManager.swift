//
//  WatchNotificationManager.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 24/11/2024.
//

import Foundation
import UserNotifications
import WatchKit

class WatchNotificationManager: NSObject {
    static let shared = WatchNotificationManager()
    
    private override init() {
        super.init()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    func scheduleTimerNotifications(duration: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        
        // Remove any existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Schedule "Last 10 seconds" notification
        let lastTenSecondsDate = Date().addingTimeInterval(duration - 10)
        scheduleNotification(
            identifier: "lastTenSeconds",
            title: "Last 10 seconds",
            body: "10 seconds to go!",
            date: lastTenSecondsDate
        )
        
        // Schedule "Countdown complete" notification
        let countdownCompleteDate = Date().addingTimeInterval(duration)
        scheduleNotification(
            identifier: "countdownComplete",
            title: "Countdown complete",
            body: "Stopwatch has started!",
            date: countdownCompleteDate
        )
    }
    
    private func scheduleNotification(identifier: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func setupDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
    
}



// Add the extension right here, at the bottom of the same file
extension WatchNotificationManager: UNUserNotificationCenterDelegate {
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
    // Don't show notification if app is in foreground
    completionHandler([])
}
}
