import Cocoa
import AVFoundation
import CoreAudio
import CoreMediaIO

/// A helper class that monitors the active running state of a camera or microphone AVCaptureDevice.
class MonitoredDevice {
    let device: AVCaptureDevice
    let isVideo: Bool
    let connectionID: UInt32
    
    private var isRunning: Bool = false
    private var audioListenerBlock: AudioObjectPropertyListenerBlock?
    private var videoListenerBlock: CMIOObjectPropertyListenerBlock?
    private let onStateChange: (MonitoredDevice, Bool) -> Void
    
    init?(device: AVCaptureDevice, onStateChange: @escaping (MonitoredDevice, Bool) -> Void) {
        self.device = device
        self.isVideo = device.hasMediaType(.video)
        self.onStateChange = onStateChange
        
        let selector = NSSelectorFromString("connectionID")
        guard device.responds(to: selector),
              let connectionIDNum = device.value(forKey: "connectionID") as? NSNumber else {
            return nil
        }
        self.connectionID = connectionIDNum.uint32Value
    }
    
    func startMonitoring() {
        self.isRunning = queryIsRunning()
        
        let status: OSStatus
        if isVideo {
            var addr = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kAudioDevicePropertyDeviceIsRunningSomewhere),
                mScope: CMIOObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kAudioObjectPropertyElementMain)
            )
            let block: CMIOObjectPropertyListenerBlock = { [weak self] (_, _) in
                self?.handlePropertyChange()
            }
            self.videoListenerBlock = block
            status = CMIOObjectAddPropertyListenerBlock(connectionID, &addr, DispatchQueue.main, block)
        } else {
            var addr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            let block: AudioObjectPropertyListenerBlock = { [weak self] (_, _) in
                self?.handlePropertyChange()
            }
            self.audioListenerBlock = block
            status = AudioObjectAddPropertyListenerBlock(connectionID, &addr, DispatchQueue.main, block)
        }
        
        if status != noErr {
            print("Failed to register property listener for \(device.localizedName) (ID: \(connectionID)), status: \(status)")
        }
    }
    
    func stopMonitoring() {
        if isVideo {
            if let block = videoListenerBlock {
                var addr = CMIOObjectPropertyAddress(
                    mSelector: CMIOObjectPropertySelector(kAudioDevicePropertyDeviceIsRunningSomewhere),
                    mScope: CMIOObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
                    mElement: CMIOObjectPropertyElement(kAudioObjectPropertyElementMain)
                )
                CMIOObjectRemovePropertyListenerBlock(connectionID, &addr, DispatchQueue.main, block)
                self.videoListenerBlock = nil
            }
        } else {
            if let block = audioListenerBlock {
                var addr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                AudioObjectRemovePropertyListenerBlock(connectionID, &addr, DispatchQueue.main, block)
                self.audioListenerBlock = nil
            }
        }
    }
    
    func queryIsRunning() -> Bool {
        var isRunningVal: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status: OSStatus
        
        if isVideo {
            var addr = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kAudioDevicePropertyDeviceIsRunningSomewhere),
                mScope: CMIOObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kAudioObjectPropertyElementMain)
            )
            status = CMIOObjectGetPropertyData(connectionID, &addr, 0, nil, size, &size, &isRunningVal)
        } else {
            var addr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            status = AudioObjectGetPropertyData(connectionID, &addr, 0, nil, &size, &isRunningVal)
        }
        
        return status == noErr && isRunningVal != 0
    }
    
    private func handlePropertyChange() {
        let newState = queryIsRunning()
        if newState != isRunning {
            isRunning = newState
            onStateChange(self, isRunning)
        }
    }
    
    func synchronizeState() {
        let newState = queryIsRunning()
        if newState != isRunning {
            isRunning = newState
            onStateChange(self, isRunning)
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    /// Currently active device monitors keyed by the device uniqueID.
    var activeMonitors: [String: MonitoredDevice] = [:]
    
    /// The Menu Bar Status Item
    var statusItem: NSStatusItem!
    
    /// The context menu for the status item
    var statusMenu: NSMenu!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setbuf(Darwin.stdout, nil)
        print("Starting camera and microphone active state monitoring...")
        
        // 1. Load User Settings
        SettingsManager.shared.load()
        
        // 2. Hide Dock Icon (runs strictly as Menu Bar utility)
        NSApp.setActivationPolicy(.accessory)
        
        // 3. Setup Menu Bar Item and Context Menu
        setupStatusItem()
        
        // 4. Request notifications early if enabled
        if SettingsManager.shared.notificationsEnabled {
            NotificationManager.shared.requestAuthorization()
        }
        
        // 5. Initial Device Monitoring Configuration
        setupObservers()
        discoverAndMonitorDevices()
        
        // 6. Update visual icon state
        updateStatusItemIcon()
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        statusMenu = NSMenu()
        statusMenu.autoenablesItems = false
        statusMenu.delegate = self
        statusItem.menu = statusMenu
    }
    
    func updateStatusItemIcon() {
        guard let button = statusItem.button else { return }
        
        let isPaused = SettingsManager.shared.isPaused
        let hasActiveDevices = activeMonitors.values.contains { $0.queryIsRunning() }
        
        let symbolName: String
        if isPaused {
            symbolName = "video.slash"
        } else if hasActiveDevices {
            symbolName = "record.circle.fill"
        } else {
            symbolName = "video"
        }
        
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "In Meeting Status") {
            image.isTemplate = true
            button.image = image
        }
        
        // Configure tooltips
        if isPaused {
            button.toolTip = "In Meeting: Detection Paused"
        } else if hasActiveDevices {
            button.toolTip = "In Meeting: Device is Active!"
        } else {
            button.toolTip = "In Meeting: Idle"
        }
    }

    func setupObservers() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(deviceWasConnected(_:)), name: AVCaptureDevice.wasConnectedNotification, object: nil)
        center.addObserver(self, selector: #selector(deviceWasDisconnected(_:)), name: AVCaptureDevice.wasDisconnectedNotification, object: nil)
    }

    func discoverAndMonitorDevices() {
        // Audio Devices (Microphones)
        let discoverySessionAudio = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        for device in discoverySessionAudio.devices {
            monitorDevice(device)
        }

        // Video Devices (Cameras)
        let discoverySessionVideo = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .continuityCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        for device in discoverySessionVideo.devices {
            monitorDevice(device)
        }
    }

    func monitorDevice(_ device: AVCaptureDevice) {
        let uuid = device.uniqueID
        guard activeMonitors[uuid] == nil else { return }

        guard let monitor = MonitoredDevice(device: device, onStateChange: { [weak self] (monitored, isRunning) in
            self?.logDeviceStateChange(monitored.device, isRunning: isRunning)
            self?.handleDeviceStateChange(monitored.device, isVideo: monitored.isVideo, isRunning: isRunning)
        }) else {
            print("Device skipped (could not obtain ConnectionID): \(device.localizedName) (UUID: \(uuid))")
            return
        }

        monitor.startMonitoring()
        activeMonitors[uuid] = monitor

        print("Device Discovered: \(device.localizedName) (UUID: \(uuid)), Active: \(monitor.queryIsRunning())")
        updateStatusItemIcon()
    }

    func unmonitorDevice(_ device: AVCaptureDevice) {
        let uuid = device.uniqueID
        if let monitor = activeMonitors[uuid] {
            monitor.stopMonitoring()
            activeMonitors.removeValue(forKey: uuid)
            print("Device Removed: \(device.localizedName) (UUID: \(uuid))")
            updateStatusItemIcon()
        }
    }

    @objc func deviceWasConnected(_ notification: Notification) {
        if let device = notification.object as? AVCaptureDevice {
            monitorDevice(device)
        }
    }

    @objc func deviceWasDisconnected(_ notification: Notification) {
        if let device = notification.object as? AVCaptureDevice {
            unmonitorDevice(device)
        }
    }

    func logDeviceStateChange(_ device: AVCaptureDevice, isRunning: Bool) {
        let type = device.hasMediaType(.video) ? "Camera" : "Microphone"
        let status = isRunning ? "Active" : "Inactive"
        print("[\(status)] \(type): \(device.localizedName)")
    }
    
    func handleDeviceStateChange(_ device: AVCaptureDevice, isVideo: Bool, isRunning: Bool) {
        // 1. Redraw status bar icon state
        updateStatusItemIcon()
        
        // 2. Short-circuit alerts if global monitoring is paused
        guard !SettingsManager.shared.isPaused else { return }
        
        // Skip events if the device is excluded from alerts
        guard !SettingsManager.shared.excludedDeviceIDs.contains(device.uniqueID) else {
            print("Device event ignored (device is excluded): \(device.localizedName)")
            return
        }
        
        // 3. Dispatch Local Notifications
        NotificationManager.shared.sendNotification(
            deviceName: device.localizedName,
            isVideo: isVideo,
            isActive: isRunning
        )
        
        // 4. Dispatch Webhooks
        WebhookManager.shared.dispatchWebhook(
            deviceName: device.localizedName,
            isVideo: isVideo,
            isActive: isRunning
        )
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        for monitor in activeMonitors.values {
            monitor.stopMonitoring()
        }
        activeMonitors.removeAll()
    }
    
    // MARK: - NSMenuDelegate (Dynamic Status Menu Builder)
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        
        // 1. Title Header
        let headerItem = NSMenuItem(title: "Monitored Devices:", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        // 2. Enumerate monitored devices and display their states
        if activeMonitors.isEmpty {
            let emptyItem = NSMenuItem(title: "  No devices found", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            let sortedMonitors = activeMonitors.values.sorted { $0.device.localizedName < $1.device.localizedName }
            for monitor in sortedMonitors {
                let isRunning = monitor.queryIsRunning()
                let typeSymbol = monitor.isVideo ? "📹" : "🎤"
                let statusDot = isRunning ? "🔴" : "⚪"
                let stateText = isRunning ? "Active" : "Idle"
                let title = "  \(statusDot) \(typeSymbol) \(monitor.device.localizedName) (\(stateText))"
                
                let item = NSMenuItem(title: title, action: #selector(toggleDeviceEnabled(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = monitor.device.uniqueID
                
                let isExcluded = SettingsManager.shared.excludedDeviceIDs.contains(monitor.device.uniqueID)
                item.state = isExcluded ? .off : .on
                item.isEnabled = true
                
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Pause/Resume monitoring
        let isPaused = SettingsManager.shared.isPaused
        let pauseTitle = isPaused ? "Resume Detection" : "Pause Detection"
        let pauseItem = NSMenuItem(title: pauseTitle, action: #selector(togglePause), keyEquivalent: "")
        pauseItem.isEnabled = true
        menu.addItem(pauseItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Open Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.isEnabled = true
        menu.addItem(settingsItem)
        
        // 5. About
        let aboutItem = NSMenuItem(title: "About...", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.isEnabled = true
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 6. Quit App
        let quitItem = NSMenuItem(title: "Quit In Meeting", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.isEnabled = true
        menu.addItem(quitItem)
    }
    
    // MARK: - Menu Actions
    
    @objc func toggleDeviceEnabled(_ sender: NSMenuItem) {
        guard let uuid = sender.representedObject as? String else { return }
        
        if SettingsManager.shared.excludedDeviceIDs.contains(uuid) {
            SettingsManager.shared.excludedDeviceIDs.remove(uuid)
            print("Device alerts ENABLED for UUID: \(uuid)")
        } else {
            SettingsManager.shared.excludedDeviceIDs.insert(uuid)
            print("Device alerts DISABLED for UUID: \(uuid)")
        }
        
        updateStatusItemIcon()
    }
    
    @objc func togglePause() {
        SettingsManager.shared.isPaused.toggle()
        updateStatusItemIcon()
        
        let isPaused = SettingsManager.shared.isPaused
        print("Detection \(isPaused ? "PAUSED" : "RESUMED")")
        
        if !isPaused {
            for monitor in activeMonitors.values {
                monitor.synchronizeState()
            }
        }
    }
    
    @objc func openSettings() {
        SettingsWindowController.shared.showWindow()
    }
    
    @objc func openAbout() {
        if let url = URL(string: "https://github.com/fellowgeek/in-meeting") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
