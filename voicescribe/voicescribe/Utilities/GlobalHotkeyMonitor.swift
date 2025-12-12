import Cocoa
import Carbon
import AppKit

class GlobalHotkeyMonitor {
    static let shared = GlobalHotkeyMonitor()
    
    private var eventMonitor: Any?
    private var keyMonitor: Any?
    private var handler: (() -> Void)?
    private var monitoringTimer: Timer?
    
    // Store in UserDefaults for persistence across app launches
    private let accessibilityPromptKey = "AccessibilityPromptShown"
    
    private init() {}
    
    // These methods are now handled by PermissionManager
    // Kept for backward compatibility
    func requestAccessibilityPermission() -> Bool {
        // Request accessibility permission with prompt
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        print("Accessibility permission status: \(accessEnabled)")
        return accessEnabled
    }
    
    func checkAccessibilityStatus() -> Bool {
        // Check without prompting
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        print("Current accessibility status: \(accessEnabled)")
        return accessEnabled
    }
    
    func requestAccessibilityPermissionIfNeeded() -> Bool {
        // Check if permission is already granted
        if checkAccessibilityStatus() {
            return true
        }
        
        // Check if we've already shown the prompt
        if UserDefaults.standard.bool(forKey: accessibilityPromptKey) {
            return false
        }
        
        // Show prompt and mark that we've shown it
        let granted = requestAccessibilityPermission()
        UserDefaults.standard.set(true, forKey: accessibilityPromptKey)
        return granted
    }
    
    func startMonitoring(handler: @escaping () -> Void) {
        self.handler = handler
        
        // Check for Accessibility permissions using PermissionManager
        if !PermissionManager.shared.isAccessibilityPermissionGranted() {
            print("Accessibility permissions not granted. Global hotkey will not work.")
            
            // Don't automatically show prompt, just log the issue
            // The onboarding flow will handle requesting permissions
            return
        }
        
        setupEventMonitors()
        print("Global hotkey monitoring started")
    }
    
    func startMonitoringWithPrompt(handler: @escaping () -> Void) {
        self.handler = handler
        
        // Check for Accessibility permissions using PermissionManager
        if !PermissionManager.shared.isAccessibilityPermissionGranted() {
            print("Accessibility permissions not granted. Global hotkey will not work.")
            DispatchQueue.main.async {
                self.showAccessibilityPrompt()
            }
            return
        }
        
        setupEventMonitors()
        print("Global hotkey monitoring started with prompt")
    }
    
    private func setupEventMonitors() {
        // Use local event monitor for Fn key
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 63 { // Fn key
                print("GlobalHotkeyMonitor: Fn key pressed locally")
                self?.handler?()
                return nil // Consume the event
            }
            return event // Pass through other events
        }
        
        // Also add global monitor to capture events when app is not focused
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 63 { // Fn key
                print("GlobalHotkeyMonitor: Fn key pressed globally")
                self?.handler?()
            }
        }
        
        print("GlobalHotkeyMonitor: Event monitors set up for Fn key (keyCode: 63)")
    }
    
    private func showAccessibilityPrompt() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "VoiceScribe needs accessibility permissions to use global hotkeys. Please add VoiceScribe to the Accessibility list in System Settings."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Use PermissionManager to open settings and monitor for changes
            PermissionManager.shared.openAccessibilitySettings()
            
            // Monitor for permission changes using PermissionManager status
            monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                if PermissionManager.shared.isAccessibilityPermissionGranted() {
                    // Permission granted, restart monitoring
                    self?.setupEventMonitors()
                    timer.invalidate()
                    self?.monitoringTimer = nil
                }
            }
        }
    }
    
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        
        // Stop the monitoring timer if it's active
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        handler = nil
        print("Global hotkey monitoring stopped")
    }
}
