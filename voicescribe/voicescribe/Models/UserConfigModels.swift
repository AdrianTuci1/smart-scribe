import Foundation

struct UserSettings: Codable, Equatable {
    // General
    var pushToTalkKey: String = "⌃⌥⌘R"
    var handsFreeModeKey: String = "⌃⌥⌘H"
    var commandModeEnabled: Bool = true
    var pasteLastTranscriptEnabled: Bool = true
    var selectedMicrophone: String = "Auto Detect"
    var selectedLanguage: String = "English (US)"
    
    // Vibe Coding
    var variableRecognition: Bool = true
    var fileTaggingInChat: Bool = true
    
    // Experimental
    var advancedVoiceCommands: Bool = false
    
    // System Settings
    var launchAtLogin: Bool = true
    var showFlowBarAlways: Bool = true
    var showInDock: Bool = false
    var dictationSoundEffect: Bool = true
    var muteMusicWhileDictating: Bool = false
    
    // Extras
    var autoAddToDirectory: Bool = true
    var smartFormatting: Bool = true
    var emailAutoSignature: Bool = false
    var creatorMode: Bool = false
    
    // Data & Privacy
    var privacyMode: Bool = false
    var contextAwareness: Bool = true
    var hipaaEnabled: Bool = false
    
    // Init with defaults
    init() {}
}


struct OnboardingConfig: Codable, Equatable {
    var hasCompletedOnboarding: Bool = false
    var selectedDomains: [String] = []
    var completedAt: Date?
    
    init(hasCompletedOnboarding: Bool = false, selectedDomains: [String] = [], completedAt: Date? = nil) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedDomains = selectedDomains
        self.completedAt = completedAt
    }
}

// Wrapper for API responses
struct SettingsResponse: Codable {
    let data: UserSettings?
}

struct OnboardingConfigResponse: Codable {
    let data: OnboardingConfig?
}
