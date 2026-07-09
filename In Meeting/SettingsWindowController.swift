import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()
    
    private init() {
        // Create the SwiftUI view
        let settingsView = SettingsView()
        
        // Host the SwiftUI view in an NSHostingView
        let hostingController = NSHostingController(rootView: settingsView)
        
        // Create a native AppKit window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "In Meeting Settings"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
        window.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Shows the settings window and brings it to front.
    func showWindow() {
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func windowWillClose(_ notification: Notification) {
        // Clean up or handle window closed state if needed
    }
}
