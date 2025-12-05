// homework_copilotApp.swift
// Main entry point - keeps things clean and organized

import SwiftUI
import Vision
import AppKit
import Carbon
import ScreenCaptureKit

@main
struct HomeworkCopilotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - we only use menu bar
        Settings {
            
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var floatingWindow: OverlayWindow?
    var configWindow: NSWindow?
    var hotKeyRef: EventHotKeyRef?
    var configHotKeyRef: EventHotKeyRef?
    var textGrabHotKeyRef: EventHotKeyRef?
    var upArrowHotKeyRef: EventHotKeyRef?
    var downArrowHotKeyRef: EventHotKeyRef?
    let screenCapturer = ScreenCapturer()
    let textGrabber = TextGrabber()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - make it a pure menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Setup
        setupMenuBar()
        registerCaptureHotKey()
        registerConfigHotKey()
        registerTextGrabHotKey()
        registerArrowKeyHotKeys()
        floatingWindow = OverlayWindow()
        requestScreenCapturePermission()
        requestAccessibilityPermission()
    }
    
    // MARK: - Menu Bar
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Homework Copilot")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Settings", action: #selector(showConfigWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Hide/Show Answer (⌘⇧C)", action: #selector(toggleOverlayWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Capture Screenshot (⌘⇧S)", action: #selector(captureScreen), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Send Selected Text (⌘⇧T)", action: #selector(grabSelectedText), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    // MARK: - Hotkeys
    
    func registerCaptureHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x68776370)
        hotKeyID.id = 1
        
        RegisterEventHotKey(UInt32(kVK_ANSI_S), UInt32(cmdKey | shiftKey), hotKeyID,
                          GetApplicationEventTarget(), 0, &hotKeyRef)
        
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                     eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            if hotKeyID.id == 1 {
                NotificationCenter.default.post(name: NSNotification.Name("CaptureScreenshot"), object: nil)
            } else if hotKeyID.id == 2 {
                NotificationCenter.default.post(name: NSNotification.Name("ToggleOverlay"), object: nil)
            } else if hotKeyID.id == 3 {
                NotificationCenter.default.post(name: NSNotification.Name("GrabSelectedText"), object: nil)
            } else if hotKeyID.id == 4 {
                NotificationCenter.default.post(name: NSNotification.Name("UpArrowPressed"), object: nil)
            } else if hotKeyID.id == 5 {
                NotificationCenter.default.post(name: NSNotification.Name("DownArrowPressed"), object: nil)
            }
            return noErr
        }, 1, &eventSpec, nil, nil)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("CaptureScreenshot"),
                                              object: nil, queue: .main) { _ in
            self.captureScreen()
        }
    }
    
    func registerConfigHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x68776370)
        hotKeyID.id = 2
        
        RegisterEventHotKey(UInt32(kVK_ANSI_C), UInt32(cmdKey | shiftKey), hotKeyID,
                          GetApplicationEventTarget(), 0, &configHotKeyRef)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ToggleOverlay"),
                                              object: nil, queue: .main) { _ in
            self.toggleOverlayWindow()
        }
    }
    
    func registerTextGrabHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x68776370)
        hotKeyID.id = 3
        
        RegisterEventHotKey(UInt32(kVK_ANSI_T), UInt32(cmdKey | shiftKey), hotKeyID,
                          GetApplicationEventTarget(), 0, &textGrabHotKeyRef)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("GrabSelectedText"),
                                              object: nil, queue: .main) { _ in
            self.grabSelectedText()
        }
    }

    // MARK: - Arrow Key Hotkeys
    
    func registerArrowKeyHotKeys() {
        // Up arrow - Capture screen
        var upArrowID = EventHotKeyID()
        upArrowID.signature = OSType(0x68776370)
        upArrowID.id = 4
        
        RegisterEventHotKey(UInt32(kVK_UpArrow), 0, upArrowID,
                          GetApplicationEventTarget(), 0, &upArrowHotKeyRef)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("UpArrowPressed"),
                                              object: nil, queue: .main) { _ in
            print("⬆️ Up arrow pressed - capturing screen")
            self.captureScreen()
        }
        
        // Down arrow - Toggle visibility
        var downArrowID = EventHotKeyID()
        downArrowID.signature = OSType(0x68776370)
        downArrowID.id = 5
        
        RegisterEventHotKey(UInt32(kVK_DownArrow), 0, downArrowID,
                          GetApplicationEventTarget(), 0, &downArrowHotKeyRef)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("DownArrowPressed"),
                                              object: nil, queue: .main) { _ in
            print("⬇️ Down arrow pressed - toggling visibility")
            self.toggleOverlayWindow()
        }
        
        print("✅ Arrow key bindings registered:")
        print("   ↑ = Capture & OCR")
        print("   ↓ = Toggle answer visibility")
    }

    // MARK: - Actions
    
    @objc func toggleOverlayWindow() {
        guard let window = floatingWindow else { return }
        
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.orderFront(nil)
            window.makeKey()
        }
    }
    
    @objc func toggleConfigWindow() {
        if let window = configWindow, window.isVisible {
            window.close()
        } else {
            showConfigWindow()
        }
    }
    
    @objc func showConfigWindow() {
        print("🔧 Show settings clicked")
        
        // If window already exists and is visible, just bring it forward
        if let window = configWindow, window.isVisible {
            print("✅ Settings window already open, bringing to front")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window
        let contentView = SettingsView()
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Homework Copilot Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 550, height: 650))
        window.center()
        
        // Make sure window is visible
        window.isReleasedWhenClosed = false
        window.level = .normal
        
        print("🪟 Opening settings window")
        window.makeKeyAndOrderFront(nil)
        
        // Force app activation
        NSApp.activate(ignoringOtherApps: true)
        
        self.configWindow = window
        
        print("✅ Settings window opened")
    }
    
    @objc func captureScreen() {
        print("🎬 Capture triggered!")
        Task {
            do {
                print("📸 Starting screen capture...")
                let image = try await screenCapturer.captureScreen()
                print("✅ Screen captured successfully!")
                await performOCR(on: image)
            } catch {
                print("❌ Screen capture failed: \(error)")
                await MainActor.run {
                    floatingWindow?.showWindow(with: "Failed to capture screen. Please grant Screen Recording permission in System Settings.")
                }
            }
        }
    }
    
    @objc func grabSelectedText() {
        print("📝 Grabbing selected text...")
        
        guard let selectedText = textGrabber.getSelectedText(), !selectedText.isEmpty else {
            print("⚠️ No text selected")
            floatingWindow?.showWindow(with: "No text selected. Please highlight text and try again.")
            return
        }
        
        print("✅ Got selected text: \(selectedText.prefix(100))...")
        sendToLLM(text: selectedText)
    }
    
    // MARK: - OCR & LLM
    
    func performOCR(on image: NSImage) async {
        print("🔍 Starting OCR...")
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("❌ Failed to convert NSImage to CGImage")
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            if let error = error {
                print("❌ OCR Error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("❌ No observations found")
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            print("📝 OCR detected \(observations.count) text blocks")
            print("📄 Text length: \(recognizedText.count) characters")
            print("📄 First 100 chars: \(String(recognizedText.prefix(100)))")
            
            Task { @MainActor in
                if recognizedText.isEmpty {
                    print("⚠️ No text detected")
                    self?.floatingWindow?.showWindow(with: "No text detected in screenshot.")
                } else {
                    print("✅ Sending to LLM...")
                    self?.sendToLLM(text: recognizedText)
                }
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            print("✅ OCR request completed")
        } catch {
            print("❌ OCR failed to perform: \(error)")
        }
    }
    
    func sendToLLM(text: String) {
        Task { @MainActor in
            print("💬 Showing loading message...")
            floatingWindow?.showWindow(with: "loading...")
        }
        
        Task {
            do {
                print("🌐 Calling Replicate API...")
                let answer = try await callReplicateAPI(question: text)
                print("✅ Got answer from API")
                
                await MainActor.run {
                    print("💬 Showing answer...")
                    floatingWindow?.showWindow(with: answer)
                }
            } catch {
                print("❌ API Error: \(error)")
                await MainActor.run {
                    floatingWindow?.showWindow(with: "Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func callReplicateAPI(question: String) async throws -> String {
        let apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? "YOUR_REPLICATE_TOKEN"
        let modelVersion = UserDefaults.standard.string(forKey: "selectedModel") ?? "meta/meta-llama-3.1-70b-instruct:fbfb20b472b2f3bdd101412a9f70a0ed4fc0ced78a77ff00970ee7a2383c575d"
        let customPrompt = UserDefaults.standard.string(forKey: "customPrompt") ?? """
        On the first line, output ONLY the final answer in bold using two asterisks on each side, like this: **The answer is option A**. Do not include any other text on that line. After that, write a 1–2 sentence explanation. Always use bold by wrapping text in double asterisks. No preamble, no extra lines before the answer.
        """

        print("🔑 Using API key: \(apiKey.prefix(10))...")
        print("🤖 Using model: \(modelVersion)")
        
        let createUrl = URL(string: "https://api.replicate.com/v1/predictions")!
        var createRequest = URLRequest(url: createUrl)
        createRequest.httpMethod = "POST"
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        createRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let fullPrompt = """
        \(customPrompt)
        
        Question: \(question)
        
        Answer:
        """
        
        let body: [String: Any] = [
            "version": modelVersion,
            "input": [
                "prompt": fullPrompt,
                "max_tokens": 1024,
                "temperature": 0.7
            ]
        ]
        
        createRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: createRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response", code: -1)
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        print("📡 API Response: \(json)")
        
        guard let getUrl = json["urls"] as? [String: String],
              let pollUrl = getUrl["get"] else {
            throw NSError(domain: "No poll URL", code: -1)
        }
        
        return try await pollReplicateResult(url: pollUrl, apiKey: apiKey)
    }
    
    func pollReplicateResult(url: String, apiKey: String) async throws -> String {
        let pollUrl = URL(string: url)!
        var pollRequest = URLRequest(url: pollUrl)
        pollRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        for _ in 0..<60 {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let (data, _) = try await URLSession.shared.data(for: pollRequest)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? String else {
                continue
            }
            
            if status == "succeeded" {
                if let output = json["output"] as? [String] {
                    return output.joined()
                } else if let output = json["output"] as? String {
                    return output
                }
            } else if status == "failed" || status == "canceled" {
                let error = json["error"] as? String ?? "Unknown error"
                throw NSError(domain: "Replicate", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
            }
        }
        
        throw NSError(domain: "Replicate", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeout waiting for result"])
    }
    
    func requestScreenCapturePermission() {
        Task {
            do {
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            } catch {
                print("Permission request failed: \(error)")
            }
        }
    }
    
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("⚠️ Accessibility permission needed for text grabbing")
        }
    }
}
