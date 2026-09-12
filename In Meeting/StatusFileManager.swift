import Foundation

/// Manages writing the real-time meeting status indicator file to the user's home directory.
class StatusFileManager {
    static let shared = StatusFileManager()
    
    private let statusFileURL: URL
    private var lastWrittenState: Bool?
    
    private init() {
        self.statusFileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".in-meeting")
    }
    
    /// Updates the status file based on whether a monitored device is deemed active.
    func updateStatus(isActive: Bool) {
        guard SettingsManager.shared.statusFileEnabled else {
            removeFile()
            return
        }
        
        // Avoid redundant disk I/O if the aggregate state hasn't changed
        if lastWrittenState == isActive {
            return
        }
        
        lastWrittenState = isActive
        writeStatus(isActive ? "active\n" : "inactive\n")
    }
    
    /// Writes the raw status string atomically to ~/.in-meeting.
    private func writeStatus(_ status: String) {
        guard let data = status.data(using: .utf8) else { return }
        
        do {
            try data.write(to: statusFileURL, options: .atomic)
        } catch {
            print("[StatusFile Error] Failed to write status file to \(statusFileURL.path): \(error.localizedDescription)")
        }
    }
    
    /// Removes the ~/.in-meeting status file from disk if it exists.
    func removeFile() {
        lastWrittenState = nil
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: statusFileURL.path) {
            do {
                try fileManager.removeItem(at: statusFileURL)
            } catch {
                print("[StatusFile Error] Failed to remove status file at \(statusFileURL.path): \(error.localizedDescription)")
            }
        }
    }
    
    /// Synchronizes status when the setting toggle is changed.
    func handleEnabledChanged(_ isEnabled: Bool, isActive: Bool) {
        if isEnabled {
            lastWrittenState = isActive
            writeStatus(isActive ? "active\n" : "inactive\n")
        } else {
            removeFile()
        }
    }
    
    /// Performs cleanup on application termination by setting state to inactive.
    func cleanup() {
        guard SettingsManager.shared.statusFileEnabled else { return }
        lastWrittenState = false
        writeStatus("inactive\n")
    }
}
