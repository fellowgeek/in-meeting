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
    
    deinit {
        stopMonitoring()
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    /// Currently active device monitors keyed by the device uniqueID.
    var activeMonitors: [String: MonitoredDevice] = [:]

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setbuf(Darwin.stdout, nil)
        print("Starting camera and microphone active state monitoring...")
        setupObservers()
        discoverAndMonitorDevices()
    }

    func setupObservers() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(deviceWasConnected(_:)), name: .AVCaptureDeviceWasConnected, object: nil)
        center.addObserver(self, selector: #selector(deviceWasDisconnected(_:)), name: .AVCaptureDeviceWasDisconnected, object: nil)
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
        }) else {
            print("Device skipped (could not obtain ConnectionID): \(device.localizedName) (UUID: \(uuid))")
            return
        }

        monitor.startMonitoring()
        activeMonitors[uuid] = monitor

        print("Device Discovered: \(device.localizedName) (UUID: \(uuid)), Active: \(monitor.queryIsRunning())")
    }

    func unmonitorDevice(_ device: AVCaptureDevice) {
        let uuid = device.uniqueID
        if let monitor = activeMonitors[uuid] {
            monitor.stopMonitoring()
            activeMonitors.removeValue(forKey: uuid)
            print("Device Removed: \(device.localizedName) (UUID: \(uuid))")
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

    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up all active monitors
        for monitor in activeMonitors.values {
            monitor.stopMonitoring()
        }
        activeMonitors.removeAll()
    }
}
