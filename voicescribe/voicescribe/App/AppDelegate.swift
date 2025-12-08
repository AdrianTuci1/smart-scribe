import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    var menuBarManager: MenuBarManager!
    var overlayManager: OverlayManager!
    var floatingWaveformManager: FloatingWaveformManager!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize Managers
        overlayManager = OverlayManager()
        floatingWaveformManager = FloatingWaveformManager()
        
        // Initialize Menu Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.slash", accessibilityDescription: "VoiceScribe")
        }
        
        menuBarManager = MenuBarManager(statusItem: statusItem)
        
        // Setup Global Hotkey
        setupGlobalHotkey()
    }
    
    func setupGlobalHotkey() {
        GlobalHotkeyMonitor.shared.startMonitoring { [weak self] in
            guard let self = self else { return }
            // Toggle recording with floating waveform
            self.floatingWaveformManager.toggleRecording()
            
            // Also update menu bar icon
            self.menuBarManager.isRecording = self.floatingWaveformManager.isRecording
        }
    }
    
    // MARK: - URL Handling
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        // Handle file opening if needed
        return true
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle URL opening
        for url in urls {
            handleIncomingURL(url)
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Check if this is an authentication callback
        if url.scheme == "voicescribe" && url.host == "auth" {
            Task {
                let success = await AuthService.shared.handleAuthCallback(url: url)
                
                if success {
                    print("Authentication successful")
                } else {
                    print("Authentication failed: \(AuthService.shared.errorMessage ?? "Unknown error")")
                }
            }
        }
    }
}
