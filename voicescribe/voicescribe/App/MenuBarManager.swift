import Cocoa
import Combine
import UserNotifications

class MenuBarManager: ObservableObject {
    
    var statusItem: NSStatusItem
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isRecording: Bool = false {
        didSet {
            updateIcon()
        }
    }
    
    @Published var isTranslationEnabled: Bool = true
    @Published var selectedLanguage: String = "English"

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        setupMenu()
        setupBindings()
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupBindings() {
        // Bind to RecordingManager for real-time recording state
        RecordingManager.shared.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
    }

    func setupMenu() {
        let menu = NSMenu()
        
        // Home
        menu.addItem(NSMenuItem(title: "Home", action: nil, keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // Check for updates
        let checkUpdatesItem = NSMenuItem(title: "Check for updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        checkUpdatesItem.target = self
        menu.addItem(checkUpdatesItem)
        
        // Paste last transcript
        let pasteItem = NSMenuItem(title: "Paste last transcript", action: #selector(pasteLastTranscript), keyEquivalent: "v")
        pasteItem.keyEquivalentModifierMask = [.command, .option]
        pasteItem.target = self
        menu.addItem(pasteItem)
        
        menu.addItem(NSMenuItem(title: "Dasimina.", action: nil, keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // Shortcuts
        menu.addItem(NSMenuItem(title: "Shortcuts", action: nil, keyEquivalent: ""))
        
        // Microphone submenu
        let microphoneItem = NSMenuItem(title: "Microphone", action: nil, keyEquivalent: "")
        let microphoneSubmenu = NSMenu()
        microphoneSubmenu.addItem(NSMenuItem(title: "Default", action: nil, keyEquivalent: ""))
        microphoneItem.submenu = microphoneSubmenu
        menu.addItem(microphoneItem)
        
        // Languages submenu
        let languagesItem = NSMenuItem(title: "Languages", action: nil, keyEquivalent: "")
        let languagesSubmenu = NSMenu()
        
        // Add selected languages
        let englishItem = NSMenuItem(title: "English 🇺🇸", action: #selector(selectLanguage(_:)), keyEquivalent: "")
        englishItem.state = selectedLanguage == "English" ? .on : .off
        englishItem.target = self
        languagesSubmenu.addItem(englishItem)
        
        let romanianItem = NSMenuItem(title: "Romanian 🇷🇴", action: #selector(selectLanguage(_:)), keyEquivalent: "")
        romanianItem.state = selectedLanguage == "Romanian" ? .on : .off
        romanianItem.target = self
        languagesSubmenu.addItem(romanianItem)
        
        languagesSubmenu.addItem(NSMenuItem.separator())
        
        // Other languages
        languagesSubmenu.addItem(NSMenuItem(title: "Mandarin (Simplified) 🇨🇳", action: #selector(selectLanguage(_:)), keyEquivalent: ""))
        languagesSubmenu.addItem(NSMenuItem(title: "Spanish 🇪🇸", action: #selector(selectLanguage(_:)), keyEquivalent: ""))
        languagesSubmenu.addItem(NSMenuItem(title: "Afrikaans 🇿🇦", action: #selector(selectLanguage(_:)), keyEquivalent: ""))
        languagesSubmenu.addItem(NSMenuItem(title: "Albanian 🇦🇱", action: #selector(selectLanguage(_:)), keyEquivalent: ""))
        
        languagesItem.submenu = languagesSubmenu
        menu.addItem(languagesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Help Center
        let helpItem = NSMenuItem(title: "Help Center", action: #selector(openHelpCenter), keyEquivalent: "")
        helpItem.target = self
        menu.addItem(helpItem)
        
        // Talk to support
        let supportItem = NSMenuItem(title: "Talk to support", action: #selector(contactSupport), keyEquivalent: "/")
        supportItem.keyEquivalentModifierMask = [.command]
        supportItem.target = self
        menu.addItem(supportItem)
        
        // General feedback
        let feedbackItem = NSMenuItem(title: "General feedback", action: #selector(sendFeedback), keyEquivalent: "")
        feedbackItem.target = self
        menu.addItem(feedbackItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        menu.addItem(NSMenuItem(title: "Quit Wispr Flow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func selectLanguage(_ sender: NSMenuItem) {
        // Extract language name without flag
        let title = sender.title
        if let spaceIndex = title.firstIndex(of: " ") {
            selectedLanguage = String(title[..<spaceIndex])
        } else {
            selectedLanguage = title
        }
        setupMenu() // Rebuild menu to update selection
    }
    
    func updateIcon() {
        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                let iconName = self.isRecording ? "mic.fill" : "mic.slash"
                button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "VoiceScribe Status")
                button.contentTintColor = self.isRecording ? .systemRed : .labelColor
            }
        }
    }
    
    @objc func checkForUpdates() {
        let alert = NSAlert()
        alert.messageText = "Check for Updates"
        alert.informativeText = "You are running the latest version of VoiceScribe."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func pasteLastTranscript() {
        // Get the last transcript from RecordingManager
        let lastTranscript = RecordingManager.shared.lastTranscription
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(lastTranscript.isEmpty ? "No transcript available" : lastTranscript, forType: .string)
        
        // Show a brief notification using modern UserNotifications framework
        let content = UNMutableNotificationContent()
        content.title = "VoiceScribe"
        content.body = lastTranscript.isEmpty ? "No transcript available" : "Last transcript copied to clipboard"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func openHelpCenter() {
        if let url = URL(string: "https://voicescribe.app/help") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func contactSupport() {
        if let url = URL(string: "mailto:support@voicescribe.app?subject=VoiceScribe Support Request") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func sendFeedback() {
        if let url = URL(string: "mailto:feedback@voicescribe.app?subject=VoiceScribe Feedback") {
            NSWorkspace.shared.open(url)
        }
    }
}
