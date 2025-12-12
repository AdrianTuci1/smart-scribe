import Cocoa
import SwiftUI
import Combine

class FloatingWaveformManager: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var waveformAmplitudes: [CGFloat] = Array(repeating: 3, count: 7)
    @Published var sessionState: TranscriptionSessionState = .idle
    
    private var chipWindow: NSPanel?
    private var hostingController: NSHostingController<AnyView>?
    private var cancellables = Set<AnyCancellable>()
    
    // Use shared recording manager
    private let recordingManager = RecordingManager.shared
    
    // Dock manager for positioning
    private let dockManager = DockManager.shared
    
    // Callbacks for error panel actions
    var onSelectMicrophone: (() -> Void)?
    var onTroubleshoot: (() -> Void)?
    
    init() {
        setupBindings()
        // Create chip immediately at initialization but keep it hidden
        createFloatingChip()
        // Hide initially
        hide()
        setupDockMonitoring()
        
        // Setup periodic visibility check when recording
        setupVisibilityCheck()
    }
    
    private func setupBindings() {
        // Bind recording state from RecordingManager
        recordingManager.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)
        
        // Bind waveform amplitudes from RecordingManager
        recordingManager.$amplitudes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] amplitudes in
                self?.waveformAmplitudes = amplitudes
            }
            .store(in: &cancellables)
        
        // Bind session state
        recordingManager.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.sessionState = state
            }
            .store(in: &cancellables)
    }
    
    private func createFloatingChip() {
        // If chip already exists, don't create another
        if chipWindow != nil {
            return
        }
        
        // Create SwiftUI view with binding to isRecording
        let view = FloatingWaveformChip(
            isRecording: Binding(
                get: { self.isRecording },
                set: { newValue in
                    if newValue {
                        self.startRecording()
                    } else {
                        self.stopRecording()
                    }
                }
            ),
            onSelectMicrophone: { [weak self] in
                self?.onSelectMicrophone?()
            },
            onTroubleshoot: { [weak self] in
                self?.onTroubleshoot?()
            },
            onDismissError: {
                // Error dismissed, return to normal state
            }
        )
        
        hostingController = NSHostingController(rootView: AnyView(view))
        
        // Create the panel - using a more compact size initially
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
            styleMask: [.nonactivatingPanel, .borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Configure panel properties - use a higher level to appear above dock
        panel.level = .floating // Use floating level instead of screenSaver to ensure proper mouse event handling
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true // Enable shadow for better visibility
        panel.hidesOnDeactivate = false // Make sure it doesn't hide when app loses focus
        panel.ignoresMouseEvents = false // Ensure it can receive mouse events
        panel.isMovable = false // Prevent manual movement
        panel.acceptsMouseMovedEvents = true // Ensure proper mouse event handling
        panel.contentViewController = hostingController
        
        // Position at bottom center of screen
        positionChip(panel)
        
        // Show panel
        panel.orderFront(nil)
        
        self.chipWindow = panel
    }
    
    private func positionChip(_ panel: NSPanel) {
        // Get the screen where the mouse cursor is currently located
        guard let screen = getScreenWithCursor() ?? NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let panelWidth: CGFloat = 400  // Width to accommodate error panels
        let panelHeight: CGFloat = 200 // Height to accommodate error panels and tooltips
        
        // Update dock information to ensure we have the latest state
        dockManager.updateDockInfo()
        
        // Calculate position:
        // - Center horizontally
        // - Position 8px above dock or bottom of screen
        
        // Center horizontally on the screen
        let x = screenFrame.midX - (panelWidth / 2)
        
        // Position vertically: 8px above dock or bottom of screen
        // In macOS coordinates, y=0 is at bottom of screen
        let dockHeight = dockManager.getDockHeight()
        let y = dockHeight + 8  // Position 8px above dock or 8px above bottom if dock is hidden
        
        // Ensure the panel stays within visible bounds
        let finalX = max(screenFrame.minX, min(x, screenFrame.maxX - panelWidth))
        let finalY = max(screenFrame.minY, y)
        
        // Set the panel frame with calculated position
        panel.setFrame(NSRect(x: finalX, y: finalY, width: panelWidth, height: panelHeight), display: true)
        print("Positioning chip at: x=\(finalX), y=\(finalY) (dockHidden: \(dockManager.dockIsHidden), dockHeight: \(dockManager.dockHeight))")
    }
    
    private func getScreenWithCursor() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        }
    }
    
    private func repositionChip() {
        guard let panel = chipWindow else { return }
        positionChip(panel)
    }
    
    private func setupDockMonitoring() {
        // Monitor display changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.dockManager.updateDockInfo()
                self?.repositionChip()
                // Ensure window level is maintained after display change
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.chipWindow?.level = .floating
                    self?.chipWindow?.orderFront(nil)
                }
            }
            .store(in: &cancellables)
        
        // Monitor space changes
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.dockManager.updateDockInfo()
                self?.repositionChip()
                    // Ensure window is visible in new space
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self?.chipWindow?.level = .floating
                        self?.chipWindow?.orderFront(nil)
                    }
            }
            .store(in: &cancellables)
        
        // Monitor dock state changes
        dockManager.$dockIsHidden
            .sink { [weak self] _ in
                self?.repositionChip()
            }
            .store(in: &cancellables)
            
        dockManager.$dockHeight
            .sink { [weak self] _ in
                self?.repositionChip()
            }
            .store(in: &cancellables)
        
        // Monitor app activation/deactivation to maintain window level
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                // Ensure window maintains its level when app becomes active
                self?.dockManager.updateDockInfo()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.chipWindow?.level = .floating
                    self?.chipWindow?.orderFront(nil)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupVisibilityCheck() {
        // Monitor recording state changes to ensure visibility
        $isRecording
            .sink { [weak self] isRecording in
                if isRecording {
                    // When recording starts, ensure the window is visible
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.ensureVisibleAboveDock()
                    }
                    
                    // Set up periodic checks while recording
                    self?.setupPeriodicVisibilityCheck()
                    
                    // Set up mouse tracking to move window between screens
                    self?.setupMouseTracking()
                } else {
                    // When recording stops, cancel periodic checks
                    self?.cancelPeriodicVisibilityCheck()
                    self?.cancelMouseTracking()
                }
            }
            .store(in: &cancellables)
    }
    
    private var visibilityTimer: Timer?
    
    private func setupPeriodicVisibilityCheck() {
        // Cancel any existing timer
        cancelPeriodicVisibilityCheck()
        
        // Create a new timer that fires every 2 seconds
        visibilityTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            // Only check if still recording
            guard let self = self, self.isRecording else { return }
            
            // Ensure window is still visible and at correct level
            self.ensureVisibleAboveDock()
        }
    }
    
    private func cancelPeriodicVisibilityCheck() {
        visibilityTimer?.invalidate()
        visibilityTimer = nil
    }
    
    private var mouseTrackingTimer: Timer?
    private var lastScreen: NSScreen?
    
    private func setupMouseTracking() {
        // Initialize with current screen
        lastScreen = getScreenWithCursor() ?? NSScreen.main
        
        // Cancel any existing timer
        cancelMouseTracking()
        
        // Create a timer to check mouse position every 0.5 seconds
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            
            let currentScreen = self.getScreenWithCursor() ?? NSScreen.main
            if currentScreen != self.lastScreen {
                // Mouse moved to a different screen, reposition the window
                self.lastScreen = currentScreen
                self.repositionChip()
                print("Mouse moved to different screen, repositioning waveform")
            }
        }
    }
    
    private func cancelMouseTracking() {
        mouseTrackingTimer?.invalidate()
        mouseTrackingTimer = nil
    }
    
    // MARK: - Public Methods
    
    func toggleRecording() {
        print("FloatingWaveformManager: toggleRecording() called, current isRecording: \(isRecording)")
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        // Create chip if it doesn't exist
        createFloatingChip()
        
        // Start recording
        recordingManager.startRecording()
        
        // Show chip if it's hidden
        show()
        
        // Ensure it's visible above dock with a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.ensureVisibleAboveDock()
        }
    }
    
    func stopRecording() {
        recordingManager.stopRecording()
        
        // Hide chip after a delay to allow for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            // Only hide if not recording
            if !(self?.isRecording ?? true) {
                self?.hide()
            }
        }
    }
    
    func cancelRecording() {
        recordingManager.cancelRecording()
        
        // Hide chip after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.hide()
        }
    }
    
    func show() {
        if chipWindow == nil {
            createFloatingChip()
        } else {
            // Use .floating level to ensure proper mouse event handling while still appearing above most windows
            chipWindow?.level = .floating
            chipWindow?.orderFront(nil)
            // Don't make key as it might interfere with focus
            print("FloatingWaveformManager: show() called - ordering chip to front with floating level")
        }
    }
    
    func ensureVisibleAboveDock() {
        guard let panel = chipWindow else { 
            createFloatingChip()
            return
        }
        
        // Force reposition and level update
        repositionChip()
        panel.level = .floating
        panel.orderFront(nil)
        
        print("FloatingWaveformManager: ensureVisibleAboveDock() called")
    }
    
    func hide() {
        chipWindow?.orderOut(nil)
    }
    
    func showError(title: String = "We couldn't hear you",
                   message: String = "We didn't pick up any speech from your {mic} microphone",
                   micName: String = "Built-in mic (recommended)") {
        // Create chip if it doesn't exist
        createFloatingChip()
        
        // Just show the chip for now
        // Error display functionality would require more complex integration
        show()
    }
}