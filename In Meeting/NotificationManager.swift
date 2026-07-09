import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Requests notification permissions if they haven't been granted yet.
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification Authorization Error: \(error.localizedDescription)")
            } else if granted {
                print("Notification permissions granted.")
            } else {
                print("Notification permissions denied.")
            }
        }
    }
    
    /// Dispatches a local system notification for a device state change.
    func sendNotification(deviceName: String, isVideo: Bool, isActive: Bool) {
        let settings = SettingsManager.shared
        guard settings.notificationsEnabled else { return }
        
        if isActive && !settings.notifyOnActivation { return }
        if !isActive && !settings.notifyOnDeactivation { return }
        
        let center = UNUserNotificationCenter.current()
        
        // Check current notification settings
        center.getNotificationSettings { [weak self] systemSettings in
            guard systemSettings.authorizationStatus == .authorized || systemSettings.authorizationStatus == .provisional else {
                // If the user toggled it in settings but system permissions are missing, request it.
                self?.requestAuthorization()
                return
            }
            
            let type = isVideo ? "Camera" : "Microphone"
            let statusString = isActive ? "Active" : "Inactive"
            let actionString = isActive ? "is now in use" : "no longer in use"
            
            let content = UNMutableNotificationContent()
            content.title = "In Meeting Status Change"
            content.body = "[\(statusString)] \(type): \(deviceName) \(actionString)."
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let identifier = "InMeeting-\(deviceName.uuidCompatible)-\(statusString)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                }
            }
        }
    }
}

private extension String {
    var uuidCompatible: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
    }
}
