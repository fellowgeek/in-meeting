# AGENTS.md - "In Meeting" Project Context & Instructions

This document provides a comprehensive overview of the "In Meeting" project, its architecture, current state, and developmental guidelines for AI agents working on this repository.

---

## 1. Project Overview
"In Meeting" is a lightweight, sandbox-free macOS application written in Swift. It monitors the active capture states (on/off status) of all camera and microphone devices connected to the Mac and prints clean, real-time status transitions to standard output.

This project is a clean Swift port/rewrite of the core monitoring functionality originally inspired by the Objective-C `OverSight` project.

---

## 2. Core Architecture
Instead of using heavy, asynchronous subprocesses to stream and parse macOS system logs, the app utilizes direct macOS framework calls:

1. **Device Discovery**:
   - Discovers local and virtual audio/video capture devices using `AVCaptureDevice.DiscoverySession`.
2. **Dynamic Hardware Support (Hot-Plugging)**:
   - Registers observer notifications for `Notification.Name.AVCaptureDeviceWasConnected` and `Notification.Name.AVCaptureDeviceWasDisconnected` to dynamically monitor external devices (USB cams, AirPods, continuity cameras) on connection/disconnection.
3. **Running State Monitoring (CoreAudio & CoreMediaIO)**:
   - For each device, the application retrieves the private `connectionID` property using dynamic Key-Value Coding (`device.value(forKey: "connectionID")`).
   - Maps the connection ID to a system-level object ID:
     - **Microphones**: Listened to via CoreAudio's `AudioObjectAddPropertyListenerBlock` with selector `kAudioDevicePropertyDeviceIsRunningSomewhere` (`'gone'`).
     - **Cameras**: Listened to via CoreMediaIO's `CMIOObjectAddPropertyListenerBlock` with selector `kAudioDevicePropertyDeviceIsRunningSomewhere` (`'gone'`).
4. **Buffering**:
   - Calls `setbuf(Darwin.stdout, nil)` on launch to disable standard output buffering, ensuring logs print to stdout in real-time.

---

## 3. Current Project State & Files
- **App Sandbox**: Disabled. The entitlements file [In_Meeting.entitlements](In%20Meeting/In_Meeting.entitlements) has `com.apple.security.app-sandbox` set to `false`. This is mandatory to access CoreAudio and CoreMediaIO system registers.
- **Main Implementation**: Implemented entirely in Swift inside [AppDelegate.swift](In%20Meeting/AppDelegate.swift).
- **Console Log Output Format**:
  - Initial discovery: `Device Discovered: <Name> (UUID: <UUID>), Active: <true/false>`
  - Activation: `[Active] <Camera/Microphone>: <Name>`
  - Deactivation: `[Inactive] <Camera/Microphone>: <Name>`
  - Disconnect: `Device Removed: <Name> (UUID: <UUID>)`

---

## 4. How to Build and Run
Because command-line tool definitions might point to basic macOS CommandLineTools instead of the Xcode toolchain, you should explicitly set the `DEVELOPER_DIR` environment variable to compile or run the app from terminal commands.

### Clean & Build:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project "In Meeting.xcodeproj" -scheme "In Meeting" clean build
```

### Run (from CLI for log output):
```bash
"/Users/erfan/Library/Developer/Xcode/DerivedData/In_Meeting-<hash>/Build/Products/Debug/In Meeting.app/Contents/MacOS/In Meeting"
```

---

## 5. Guidelines for Future Agent Development
- **Memory Safety**: Any event callback blocks registered with CoreAudio/CoreMediaIO properties must capture references weakly (`[weak self]`) to avoid strong reference cycles.
- **Dynamic Property Introspection**: Always check if a device responds to private properties using `device.responds(to: NSSelectorFromString("connectionID"))` before querying it to prevent runtime crashes.
- **No Log stream Subprocesses**: Avoid calling `log stream` or spawning shell tasks for OS logs. Use direct Apple API events for low-power, instant notifications.
