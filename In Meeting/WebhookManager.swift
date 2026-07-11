import Foundation

class WebhookManager {
    static let shared = WebhookManager()
    
    private init() {}
    
    /// Dispatches a webhook request based on the state change.
    func dispatchWebhook(deviceName: String, isVideo: Bool, isActive: Bool) {
        let settings = SettingsManager.shared
        guard !settings.isPaused else { return }
        
        // 1. Determine target URL based on device type and state
        let urlString: String
        
        if settings.webhookType == "combined" {
            urlString = isActive ? settings.combinedActiveURL : settings.combinedInactiveURL
        } else {
            if isVideo {
                urlString = isActive ? settings.videoActiveURL : settings.videoInactiveURL
            } else {
                urlString = isActive ? settings.audioActiveURL : settings.audioInactiveURL
            }
        }
        
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return // No URL configured for this event
        }
        
        guard trimmed.isValidWebhookURL else {
            print("[Webhook Warning] Configured URL is invalid: \(urlString)")
            return
        }
        
        // 2. Perform placeholder replacement in the URL itself (useful for GET queries or path templates)
        let resolvedURLString = replacePlaceholders(in: urlString, deviceName: deviceName, isVideo: isVideo, isActive: isActive, urlEncode: true)
        
        guard let url = URL(string: resolvedURLString) else {
            print("[Webhook] Invalid URL: \(resolvedURLString)")
            return
        }
        
        // 3. Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = settings.webhookMethod
        request.timeoutInterval = 8.0
        
        // 4. Set Headers and Body based on GET vs POST
        if settings.webhookMethod == "POST" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payloadString: String
            if settings.customTemplateEnabled {
                payloadString = replacePlaceholders(in: settings.customTemplate, deviceName: deviceName, isVideo: isVideo, isActive: isActive, urlEncode: false)
            } else {
                // Default payload format
                let type = isVideo ? "camera" : "microphone"
                let status = isActive ? "active" : "inactive"
                let timestamp = ISO8601DateFormatter().string(from: Date())
                payloadString = """
                {
                  "device": "\(deviceName.escapedForJSON)",
                  "type": "\(type)",
                  "status": "\(status)",
                  "timestamp": "\(timestamp)"
                }
                """
            }
            request.httpBody = payloadString.data(using: .utf8)
        }
        
        // 5. Run the background request with retry policy (up to 3 retries, starting with 2.0s delay)
        sendRequestWithRetry(request, attemptsRemaining: 3, delay: 2.0, eventType: isActive ? "Active" : "Inactive")
    }
    
    /// Sends the request and schedules retries on transport failures or 5xx server responses.
    private func sendRequestWithRetry(_ request: URLRequest, attemptsRemaining: Int, delay: TimeInterval, eventType: String) {
        let url = request.url
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[Webhook Error] Transport failure to \(url?.host ?? "unknown"): \(error.localizedDescription)")
                self.handleRetry(request, attemptsRemaining: attemptsRemaining, delay: delay, eventType: eventType)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("[Webhook Success] Dispatched event (\(eventType)) to \(url?.host ?? "unknown") (Status: \(httpResponse.statusCode))")
                } else {
                    print("[Webhook Warning] Server returned status \(httpResponse.statusCode) for \(url?.absoluteString ?? "unknown")")
                    if (500...599).contains(httpResponse.statusCode) {
                        self.handleRetry(request, attemptsRemaining: attemptsRemaining, delay: delay, eventType: eventType)
                    }
                }
            }
        }
        task.resume()
    }
    
    private func handleRetry(_ request: URLRequest, attemptsRemaining: Int, delay: TimeInterval, eventType: String) {
        if attemptsRemaining > 0 {
            print("[Webhook Info] Retrying dispatch to \(request.url?.host ?? "unknown") in \(delay) seconds... (Attempts remaining: \(attemptsRemaining))")
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.sendRequestWithRetry(request, attemptsRemaining: attemptsRemaining - 1, delay: delay * 2.0, eventType: eventType)
            }
        } else {
            print("[Webhook Error] Final failure dispatching event (\(eventType)) to \(request.url?.host ?? "unknown"). No attempts remaining.")
        }
    }
    
    /// Sends a test webhook call to verify configurations manually.
    func sendTestWebhook(to urlString: String, method: String, completion: @escaping (Bool, String) -> Void) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(false, "URL is empty.")
            return
        }
        
        guard trimmed.isValidWebhookURL else {
            completion(false, "Invalid URL format.")
            return
        }
        
        let settings = SettingsManager.shared
        let resolvedURLString = replacePlaceholders(in: urlString, deviceName: "Test Virtual Camera", isVideo: true, isActive: true, urlEncode: true)
        
        guard let url = URL(string: resolvedURLString) else {
            completion(false, "Invalid URL string.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 10.0
        
        if method == "POST" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let payloadString: String
            if settings.customTemplateEnabled {
                payloadString = replacePlaceholders(in: settings.customTemplate, deviceName: "Test Virtual Camera", isVideo: true, isActive: true, urlEncode: false)
            } else {
                let timestamp = ISO8601DateFormatter().string(from: Date())
                payloadString = """
                {
                  "device": "Test Virtual Camera",
                  "type": "camera",
                  "status": "active",
                  "timestamp": "\(timestamp)",
                  "is_test": true
                }
                """
            }
            request.httpBody = payloadString.data(using: .utf8)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let bodyPreview: String
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    bodyPreview = String(str.prefix(150)) + (str.count > 150 ? "..." : "")
                } else {
                    bodyPreview = "No response body."
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    completion(true, "Status: \(httpResponse.statusCode). Response: \(bodyPreview)")
                } else {
                    completion(false, "Failed status: \(httpResponse.statusCode). Response: \(bodyPreview)")
                }
            } else {
                completion(false, "Unknown response type.")
            }
        }
        task.resume()
    }
    
    // MARK: - Helpers
    
    private func replacePlaceholders(in template: String, deviceName: String, isVideo: Bool, isActive: Bool, urlEncode: Bool = false) -> String {
        let type = isVideo ? "camera" : "microphone"
        let status = isActive ? "active" : "inactive"
        let isoDate = ISO8601DateFormatter().string(from: Date())
        
        let finalDeviceName = urlEncode ? (deviceName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? deviceName) : deviceName
        let finalType = urlEncode ? (type.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? type) : type
        let finalStatus = urlEncode ? (status.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? status) : status
        let finalTimestamp = urlEncode ? (isoDate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? isoDate) : isoDate
        
        return template
            .replacingOccurrences(of: "{{device_name}}", with: finalDeviceName)
            .replacingOccurrences(of: "{{device_type}}", with: finalType)
            .replacingOccurrences(of: "{{device_status}}", with: finalStatus)
            .replacingOccurrences(of: "{{timestamp}}", with: finalTimestamp)
    }
}

private extension String {
    var escapedForJSON: String {
        return self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
