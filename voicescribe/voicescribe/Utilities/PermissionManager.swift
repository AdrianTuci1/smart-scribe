import Foundation
import AVFoundation
import ApplicationServices
import Combine
import AppKit

/// Centralized permission manager that handles all app permissions
/// This ensures permissions are requested only during onboarding
/// and avoids duplicate prompts throughout the app
class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()
    
    override private init() {
        super.init()
    }
    
    // Keys for UserDefaults to persist permission state
    private enum PermissionKeys {
        static let microphoneGranted = "MicrophonePermissionGranted"
        static let accessibilityGranted = "AccessibilityPermissionGranted"
        static let onboardingCompleted = "OnboardingCompleted"
    }
    
    // MARK: - Published Properties
    @Published var microphonePermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var accessibilityPermissionStatus: Bool = false
    
    
    // MARK: - Public Methods
    
    /// Checks if microphone permission is granted
    /// This method only checks status without prompting
    func isMicrophonePermissionGranted() -> Bool {
        checkPermissionStatuses()
        return microphonePermissionStatus == .authorized
    }
    
    /// Checks if accessibility permission is granted
    /// This method only checks status without prompting
    func isAccessibilityPermissionGranted() -> Bool {
        checkPermissionStatuses()
        return accessibilityPermissionStatus
    }
    
    /// Requests microphone permission (only called during onboarding)
    /// Returns true if permission was granted
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        // Check if we already know the permission status
        if microphonePermissionStatus != .notDetermined {
            completion(microphonePermissionStatus == .authorized)
            return
        }
        
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.microphonePermissionStatus = granted ? .authorized : .denied
                UserDefaults.standard.set(granted, forKey: PermissionKeys.microphoneGranted)
                completion(granted)
            }
        }
    }
    
    /// Requests accessibility permission by opening system settings
    /// This should only be called during onboarding
    func requestAccessibilityPermission() {
        // First try to trigger the system prompt
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        if isTrusted {
            self.accessibilityPermissionStatus = true
            UserDefaults.standard.set(true, forKey: PermissionKeys.accessibilityGranted)
            return
        }
        
        // Force TCC to recognize the app layout by creating a system-wide element
        // This is often needed to make the app appear in the list
        print("Attempting to create system-wide element to force TCC registration...")
        let element = AXUIElementCreateSystemWide()
        print("System-wide element created: \(element)")
        
        // Attempt to read an attribute to force the TCC prompt/registration
        // Simple creation isn't enough; we need to try to USE the API.
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value)
        print("Attempted to read kAXRoleAttribute from system-wide element. Result: \(result.rawValue)")
        
        // ATTEMPT 3: Try to post a key event. This is a very strong trigger for Accessibility.
        // We simulate a harmless event (like pressing 'a' but without actually posting it if possible, or just creating it)
        if CGEvent(source: nil) != nil {
             print("Created CGEvent successfully")
             // Just creating might not be enough, but posting is risky if we don't have permission.
             // However, posting is exactly what fails and triggers the prompt.
             // Let's try to post a dummy event to a location that probably ignores it?
             // Or better, let's just rely on the fact that we tried to Use CGEvent.
        }
        
        // If not trusted, open system settings
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        
        // Start monitoring for permission changes
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
            let granted = AXIsProcessTrustedWithOptions(options)
            
            DispatchQueue.main.async {
                self?.accessibilityPermissionStatus = granted
                UserDefaults.standard.set(granted, forKey: PermissionKeys.accessibilityGranted)
                
                if granted {
                    timer.invalidate()
                }
            }
        }
    }
    
    /// Opens system settings for microphone permission
    /// Use this when user needs to manually grant denied permission
    func openMicrophoneSettings() {
        // Open System Preferences directly to Privacy & Security > Microphone
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        NSWorkspace.shared.open(url)
        
        // Start monitoring for permission changes
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.checkPermissionStatuses()
            
            if self?.microphonePermissionStatus == .authorized {
                timer.invalidate()
            }
        }
    }
    
    /// Opens system settings for accessibility permission
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        
        // Start monitoring for permission changes
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.checkPermissionStatuses()
            
            if self?.accessibilityPermissionStatus == true {
                timer.invalidate()
            }
        }
    }
    
    /// Checks all permission statuses and updates the published properties
    /// This should be called on app launch
    func checkPermissionStatuses() {
        // Check microphone permission
        microphonePermissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        // Check accessibility permission (Functional Check)
        // Instead of relying solely on AXIsProcessTrustedWithOptions, we try to use the API.
        // If we can read the Role of the system-wide element, we definitely have access.
        let element = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value)
        
        // kAXErrorSuccess implies we have access.
        if result == .success {
            print("PermissionManager: Accessibility Functional Check PASSED")
            accessibilityPermissionStatus = true
        } else {
            // Fallback to the standard check just in case
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
            let isTrusted = AXIsProcessTrustedWithOptions(options)
            print("PermissionManager: Accessibility Functional Check FAILED (Error: \(result.rawValue)). AXIsProcessTrusted: \(isTrusted)")
            accessibilityPermissionStatus = isTrusted
        }
    }
    
    /// Resets all permission tracking (for testing purposes)
    func resetPermissionTracking() {
        UserDefaults.standard.removeObject(forKey: PermissionKeys.microphoneGranted)
        UserDefaults.standard.removeObject(forKey: PermissionKeys.accessibilityGranted)
        UserDefaults.standard.removeObject(forKey: PermissionKeys.onboardingCompleted)
        checkPermissionStatuses()
    }
    
    /// Checks if onboarding has been completed
    func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: PermissionKeys.onboardingCompleted)
    }
    
    /// Marks onboarding as completed
    func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: PermissionKeys.onboardingCompleted)
    }
}