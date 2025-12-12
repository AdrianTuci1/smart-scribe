import Cocoa
import SwiftUI
import Combine
import AVFoundation
import ApplicationServices

extension Notification.Name {
    static let globalHotkeyPressed = Notification.Name("globalHotkeyPressed")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menuBarManager: MenuBarManager!
    var floatingWaveformManager: FloatingWaveformManager!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize permission manager and check permissions
        PermissionManager.shared.checkPermissionStatuses()
        
        // Initialize and check authentication status
        Task {
            print("AppDelegate: Initializing authentication check")
            await AuthService.shared.reloadAuthState()
            print("AppDelegate: Authentication check completed - isAuth: \(AuthService.shared.isAuthenticated)")
        }
        
        // Show onboarding if it hasn't been completed
        if !PermissionManager.shared.hasCompletedOnboarding() {
            showOnboarding()
        }
        
        // Initialize Menu Bar Item first
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.slash", accessibilityDescription: "VoiceScribe")
            button.action = #selector(toggleMenuBarMenu)
            button.target = self
        }
        
        // Initialize Managers
        floatingWaveformManager = FloatingWaveformManager()
        menuBarManager = MenuBarManager(statusItem: statusItem)
        
        // Make sure of menu bar is visible
        statusItem.isVisible = true
        
        print("AppDelegate: Status bar initialized, isVisible: \(statusItem.isVisible)")
        
        // Setup Global Hotkey - will check for permissions when user presses key
        setupGlobalHotkey()
        
        // Setup bindings for menu bar icon updates
        setupMenuBarBindings()
        
        // Setup binding to show/hide floating chip based on recording state
        setupFloatingChipBindings()
        
        // Add a small delay before showing chip to ensure everything is initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("AppDelegate: Making chip visible after delay")
            self.floatingWaveformManager.show()
        }
    }
    
    @objc private func toggleMenuBarMenu() {
        guard menuBarManager.statusItem.menu != nil else { return }
        menuBarManager.statusItem.button?.performClick(nil)
    }
    
    func setupGlobalHotkey() {
        print("AppDelegate: Setting up global hotkey...")
        
        // Listen for hotkey notifications from onboarding
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGlobalHotkey),
            name: .globalHotkeyPressed,
            object: nil
        )
        
        // Setup hotkey monitoring
        GlobalHotkeyMonitor.shared.startMonitoring { [weak self] in
            self?.floatingWaveformManager.toggleRecording()
        }
        
        print("AppDelegate: Global hotkey setup completed")
    }
    
    @objc private func handleGlobalHotkey() {
        print("AppDelegate: Received global hotkey notification, toggling recording...")
        floatingWaveformManager.toggleRecording()
    }
    
    // Permission checking and requests are now handled by PermissionManager
    
    private func setupMenuBarBindings() {
        // Bind menu bar icon to recording state
        RecordingManager.shared.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.menuBarManager.isRecording = isRecording
            }
            .store(in: &RecordingManager.shared.cancellables)
    }
    
    private func setupFloatingChipBindings() {
        // Show floating chip when recording starts
        RecordingManager.shared.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                if isRecording {
                    self?.floatingWaveformManager.show()
                } else {
                    // Hide with delay to allow for visual feedback
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.floatingWaveformManager.hide()
                    }
                }
            }
            .store(in: &RecordingManager.shared.cancellables)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up resources
        GlobalHotkeyMonitor.shared.stopMonitoring()
        print("AppDelegate: Application terminating")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Show main view when app is reopened from the dock
            showMainWindow()
        }
        return true
    }
    
    private func showMainWindow() {
        if let mainViewController = NSApplication.shared.windows.first {
            mainViewController.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    // Note: URL handling is now managed by WisprFlowApp.swift using onOpenURL
    
    private func showOnboarding() {
        let onboardingView = OnboardingView()
        let hostingController = NSHostingController(rootView: onboardingView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.title = "Welcome to VoiceScribe"
        
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}