import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    @State private var activeTab = 0
    @State private var testStatusMessage = ""
    @State private var testIsSuccess = false
    @State private var testInProgress = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern custom toolbar tabs to keep the aesthetic clean and premium
            Picker("", selection: $activeTab) {
                Text("General").tag(0)
                Text("Webhooks").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Divider()
            
            ScrollView {
                switch activeTab {
                case 0:
                    generalView
                        .padding(24)
                        .transition(.opacity)
                case 1:
                    webhooksView
                        .padding(24)
                        .transition(.opacity)
                default:
                    EmptyView()
                }
            }
            .frame(height: 480)
            
            Divider()
            
            // Footer with Version & About Link
            HStack {
                Text("In Meeting Utility v1.0")
                    .foregroundColor(.secondary)
                    .font(.callout)
                Spacer()
                Button(action: {
                    if let url = URL(string: "https://example.com") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("About Project")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.link)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 580)
    }
    
    // MARK: - General Tab
    
    private var generalView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                    .font(.headline)
                
                Text("Receive native macOS banners when cameras or microphone state updates.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
                
                if settings.notificationsEnabled {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Notify when device turns active (online)", isOn: $settings.notifyOnActivation)
                        Toggle("Notify when device turns inactive (offline)", isOn: $settings.notifyOnDeactivation)
                    }
                    .padding(.leading, 24)
                    .transition(.slide.combined(with: .opacity))
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("System Integration")
                    .font(.headline)
                
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                
                Text("Start the application automatically when you log into your Mac.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
                
                Text("The application runs completely in the status bar. To toggle monitoring on or off quickly, click the menu bar icon and select 'Pause Detection'.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Webhooks Tab
    
    private var webhooksView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section 1: Routing & Methods
            VStack(alignment: .leading, spacing: 12) {
                Text("Routing & Methods")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Webhook Mode")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("", selection: $settings.webhookType) {
                        Text("Combined URL (Unified Events)").tag("combined")
                        Text("Separate URLs (Audio vs. Video)").tag("separate")
                    }
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()
                    .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("HTTP Method")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("", selection: $settings.webhookMethod) {
                        Text("GET").tag("GET")
                        Text("POST").tag("POST")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 150)
                    
                    Text(settings.webhookMethod == "POST" ? "POST: Sends a JSON body payload containing device state details." : "GET: Performs a simple ping request (replaces placeholders in URL query string).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Section 2: Endpoints
            VStack(alignment: .leading, spacing: 12) {
                Text("Endpoints")
                    .font(.headline)
                
                if settings.webhookType == "combined" {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Active URL (Device turned ON)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("https://api.example.com/active", text: $settings.combinedActiveURL)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                        
                        Text("Inactive URL (Device turned OFF)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        TextField("https://api.example.com/inactive", text: $settings.combinedInactiveURL)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Audio Device Active URL")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("https://api.example.com/audio/active", text: $settings.audioActiveURL)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Audio Device Inactive URL")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("https://api.example.com/audio/inactive", text: $settings.audioInactiveURL)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Video Device Active URL")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("https://api.example.com/video/active", text: $settings.videoActiveURL)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Video Device Inactive URL")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("https://api.example.com/video/inactive", text: $settings.videoInactiveURL)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                        }
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Section 3: Payload Template
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Enable Custom JSON Payload Template (POST only)", isOn: $settings.customTemplateEnabled)
                    .font(.headline)
                    .disabled(settings.webhookMethod != "POST")
                
                if settings.customTemplateEnabled && settings.webhookMethod == "POST" {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Variables available: {{device_name}}, {{device_type}}, {{device_status}}, {{timestamp}}")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $settings.customTemplate)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 120)
                            .border(Color.secondary.opacity(0.3), width: 1)
                            .cornerRadius(4)
                    }
                    .transition(.opacity)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Section 4: Testing
            VStack(alignment: .leading, spacing: 10) {
                Text("Test Webhook Settings")
                    .font(.headline)
                
                Text("Trigger a simulation callback using the active URL configured above.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button(action: runWebhookTest) {
                        if testInProgress {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal, 4)
                        } else {
                            Text("Test Webhook")
                        }
                    }
                    .disabled(testInProgress || getPrimaryTestURL().isEmpty)
                    
                    Spacer()
                }
                
                if !testStatusMessage.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: testIsSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(testIsSuccess ? .green : .red)
                        Text(testStatusMessage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                    .transition(.opacity)
                }
            }
        }
    }
    
    // MARK: - Testing Actions
    
    private func getPrimaryTestURL() -> String {
        if settings.webhookType == "combined" {
            return settings.combinedActiveURL
        } else {
            return settings.videoActiveURL.isEmpty ? settings.audioActiveURL : settings.videoActiveURL
        }
    }
    
    private func runWebhookTest() {
        let testURL = getPrimaryTestURL()
        guard !testURL.isEmpty else { return }
        
        testInProgress = true
        testStatusMessage = "Sending simulation ping..."
        
        WebhookManager.shared.sendTestWebhook(to: testURL, method: settings.webhookMethod) { success, result in
            DispatchQueue.main.async {
                self.testIsSuccess = success
                self.testStatusMessage = result
                self.testInProgress = false
            }
        }
    }
}
