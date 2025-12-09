import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    var menuBarManager: MenuBarManager!
    var floatingWaveformManager: FloatingWaveformManager!
    var windowController: WindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize Managers
        floatingWaveformManager = FloatingWaveformManager()
        
        // Initialize Menu Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.slash", accessibilityDescription: "VoiceScribe")
        }
        
        menuBarManager = MenuBarManager(statusItem: statusItem)
        
        // Setup Global Hotkey
        setupGlobalHotkey()
        
        // Setup bindings for menu bar icon updates
        setupMenuBarBindings()
        
        // Setup window controller after app launches
        DispatchQueue.main.async {
            self.setupWindowController()
        }
    }
    
    func setupWindowController() {
        // Get the main window
        if let window = NSApplication.shared.windows.first {
            // Create and set the window controller
            windowController = WindowController(window: window)
            window.windowController = windowController
            
            // Make sure the window is visible
            window.makeKeyAndOrderFront(nil)
            
            // Call windowDidLoad manually since we're setting the controller after window creation
            windowController?.windowDidLoad()
        }
    }
    
    func setupGlobalHotkey() {
        GlobalHotkeyMonitor.shared.startMonitoring { [weak self] in
            guard let self = self else { return }
            // Toggle recording with floating waveform
            self.floatingWaveformManager.toggleRecording()
            
            // Menu bar icon will be updated through bindings
        }
    }
    
    private func setupMenuBarBindings() {
        // Bind menu bar icon to recording state
        RecordingManager.shared.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.menuBarManager.isRecording = isRecording
            }
            .store(in: &RecordingManager.shared.cancellables)
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
