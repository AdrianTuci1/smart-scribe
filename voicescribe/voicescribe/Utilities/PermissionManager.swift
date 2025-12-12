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
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        if isTrusted {
            self.accessibilityPermissionStatus = true
            UserDefaults.standard.set(true, forKey: PermissionKeys.accessibilityGranted)
            return
        }
        
        // If not trusted, open system settings
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        
        // Start monitoring for permission changes
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
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
        
        // Check accessibility permission
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
        accessibilityPermissionStatus = AXIsProcessTrustedWithOptions(options)
    }
    
    /// Force refresh permission status
    func refreshPermissionStatuses() {
        checkPermissionStatuses()
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