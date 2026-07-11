import Foundation
import Combine
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared: SettingsManager = {
        let manager = SettingsManager()
        manager.load()
        return manager
    }()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private let kNotificationsEnabled = "notificationsEnabled"
    private let kNotifyOnActivation = "notifyOnActivation"
    private let kNotifyOnDeactivation = "notifyOnDeactivation"
    private let kWebhookType = "webhookType" // "combined" or "separate"
    private let kCombinedActiveURL = "combinedActiveURL"
    private let kCombinedInactiveURL = "combinedInactiveURL"
    private let kAudioActiveURL = "audioActiveURL"
    private let kAudioInactiveURL = "audioInactiveURL"
    private let kVideoActiveURL = "videoActiveURL"
    private let kVideoInactiveURL = "videoInactiveURL"
    private let kWebhookMethod = "webhookMethod" // "POST" or "GET"
    private let kCustomTemplateEnabled = "customTemplateEnabled"
    private let kCustomTemplate = "customTemplate"
    private let kIsPaused = "isPaused"
    private let kLaunchAtLogin = "launchAtLogin"
    
    @Published var notificationsEnabled: Bool = true {
        didSet { defaults.set(notificationsEnabled, forKey: kNotificationsEnabled) }
    }
    
    @Published var notifyOnActivation: Bool = true {
        didSet { defaults.set(notifyOnActivation, forKey: kNotifyOnActivation) }
    }
    
    @Published var notifyOnDeactivation: Bool = true {
        didSet { defaults.set(notifyOnDeactivation, forKey: kNotifyOnDeactivation) }
    }
    
    @Published var webhookType: String = "combined" {
        didSet { defaults.set(webhookType, forKey: kWebhookType) }
    }
    
    @Published var combinedActiveURL: String = "" {
        didSet { defaults.set(combinedActiveURL, forKey: kCombinedActiveURL) }
    }
    
    @Published var combinedInactiveURL: String = "" {
        didSet { defaults.set(combinedInactiveURL, forKey: kCombinedInactiveURL) }
    }
    
    @Published var audioActiveURL: String = "" {
        didSet { defaults.set(audioActiveURL, forKey: kAudioActiveURL) }
    }
    
    @Published var audioInactiveURL: String = "" {
        didSet { defaults.set(audioInactiveURL, forKey: kAudioInactiveURL) }
    }
    
    @Published var videoActiveURL: String = "" {
        didSet { defaults.set(videoActiveURL, forKey: kVideoActiveURL) }
    }
    
    @Published var videoInactiveURL: String = "" {
        didSet { defaults.set(videoInactiveURL, forKey: kVideoInactiveURL) }
    }
    
    @Published var webhookMethod: String = "POST" {
        didSet { defaults.set(webhookMethod, forKey: kWebhookMethod) }
    }
    
    @Published var customTemplateEnabled: Bool = false {
        didSet { defaults.set(customTemplateEnabled, forKey: kCustomTemplateEnabled) }
    }
    
    @Published var customTemplate: String = "" {
        didSet { defaults.set(customTemplate, forKey: kCustomTemplate) }
    }
    
    @Published var isPaused: Bool = false {
        didSet { defaults.set(isPaused, forKey: kIsPaused) }
    }
    
    @Published var launchAtLogin: Bool = false {
        didSet {
            defaults.set(launchAtLogin, forKey: kLaunchAtLogin)
            updateLaunchAtLogin()
        }
    }
    
    private init() {
        // Register default configurations in UserDefaults
        defaults.register(defaults: [
            kNotificationsEnabled: true,
            kNotifyOnActivation: true,
            kNotifyOnDeactivation: true,
            kWebhookType: "combined",
            kCombinedActiveURL: "",
            kCombinedInactiveURL: "",
            kAudioActiveURL: "",
            kAudioInactiveURL: "",
            kVideoActiveURL: "",
            kVideoInactiveURL: "",
            kWebhookMethod: "POST",
            kCustomTemplateEnabled: false,
            kCustomTemplate: """
            {
              "device": "{{device_name}}",
              "type": "{{device_type}}",
              "status": "{{device_status}}",
              "timestamp": "{{timestamp}}"
            }
            """,
            kIsPaused: false,
            kLaunchAtLogin: false
        ])
    }
    
    // Load persisted values into properties
    func load() {
        notificationsEnabled = defaults.bool(forKey: kNotificationsEnabled)
        notifyOnActivation = defaults.bool(forKey: kNotifyOnActivation)
        notifyOnDeactivation = defaults.bool(forKey: kNotifyOnDeactivation)
        webhookType = defaults.string(forKey: kWebhookType) ?? "combined"
        combinedActiveURL = defaults.string(forKey: kCombinedActiveURL) ?? ""
        combinedInactiveURL = defaults.string(forKey: kCombinedInactiveURL) ?? ""
        audioActiveURL = defaults.string(forKey: kAudioActiveURL) ?? ""
        audioInactiveURL = defaults.string(forKey: kAudioInactiveURL) ?? ""
        videoActiveURL = defaults.string(forKey: kVideoActiveURL) ?? ""
        videoInactiveURL = defaults.string(forKey: kVideoInactiveURL) ?? ""
        webhookMethod = defaults.string(forKey: kWebhookMethod) ?? "POST"
        customTemplateEnabled = defaults.bool(forKey: kCustomTemplateEnabled)
        customTemplate = defaults.string(forKey: kCustomTemplate) ?? ""
        isPaused = defaults.bool(forKey: kIsPaused)
        
        let systemEnabled = SMAppService.mainApp.status == .enabled
        let savedEnabled = defaults.bool(forKey: kLaunchAtLogin)
        if systemEnabled != savedEnabled {
            launchAtLogin = systemEnabled
        } else {
            launchAtLogin = savedEnabled
        }
    }
    
    private func updateLaunchAtLogin() {
        let service = SMAppService.mainApp
        if launchAtLogin {
            if service.status != .enabled {
                do {
                    try service.register()
                    print("[Settings] Launch at Login registered successfully.")
                } catch {
                    print("[Settings Error] Failed to register launch at login: \(error.localizedDescription)")
                }
            }
        } else {
            if service.status == .enabled {
                do {
                    try service.unregister()
                    print("[Settings] Launch at Login unregistered successfully.")
                } catch {
                    print("[Settings Error] Failed to unregister launch at login: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension String {
    var isValidWebhookURL: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return true // empty is acceptable (means disabled)
        }
        
        // Check if starts with http:// or https:// (case insensitive)
        let lowercased = trimmed.lowercased()
        guard lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") else {
            return false
        }
        
        // Temporarily replace template placeholders with placeholder text to avoid validation failures
        let tempString = trimmed
            .replacingOccurrences(of: "{{device_name}}", with: "placeholder")
            .replacingOccurrences(of: "{{device_type}}", with: "placeholder")
            .replacingOccurrences(of: "{{device_status}}", with: "placeholder")
            .replacingOccurrences(of: "{{timestamp}}", with: "placeholder")
        
        guard let url = URL(string: tempString),
              let host = url.host,
              !host.isEmpty else {
            return false
        }
        
        return true
    }
}
