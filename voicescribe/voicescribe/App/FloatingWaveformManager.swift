import Cocoa
import SwiftUI
import Combine

class FloatingWaveformManager: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var isPaused: Bool = false
    @Published var waveformAmplitudes: [CGFloat] = Array(repeating: 3, count: 7)
    @Published var sessionState: TranscriptionSessionState = .idle
    @Published var chipState: ChipState = .normal
    
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
    
    private var positionPollingTimer: Timer?
    
    init() {
        setupBindings()
        // Create chip immediately at initialization
        createFloatingChip()
        // Ensure it's visible initially
        show()
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
            
        // Bind paused state
        recordingManager.$isPaused
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPaused in
                self?.isPaused = isPaused
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
                self?.handleSessionStateChange(state)
            }
            .store(in: &cancellables)
            
        // Bind recording state to chip state
        recordingManager.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                guard let self = self else { return }
                // Only update if not in an error/processing state or if starting recording
                if isRecording {
                    self.chipState = .recording
                } else if case .recording = self.chipState {
                    self.chipState = .normal
                    // Explicitly reposition after state change from recording to normal
                    DispatchQueue.main.async {
                        self.repositionChip()
                    }
                }
            }
            .store(in: &cancellables)
            
        // Reposition when chip state changes (e.g. hover, error)
        $chipState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.repositionChip()
            }
            .store(in: &cancellables)
    }
    
    private func handleSessionStateChange(_ state: TranscriptionSessionState) {
        switch state {
        case .error(let message):
            // Use the compact server error state (red outline + ! icon)
            self.chipState = .serverError
            self.show()
        case .processing:
            // Optional: show processing state
            break
        default:
            break
        }
    }
    
    private func createFloatingChip() {
        // If chip already exists, don't create another
        if chipWindow != nil {
            return
        }
        
        // Create SwiftUI view with binding to isRecording and isPaused
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
            isPaused: Binding(
                get: { self.isPaused },
                set: { _ in self.togglePause() }
            ),
            chipState: Binding(
                get: { self.chipState },
                set: { self.chipState = $0 }
            ),
            waveformAmplitudes: Binding(
                 get: { 
                     // Ensure we only pass 5 elements
                     Array(self.waveformAmplitudes.prefix(5)) 
                 },
                 set: { _ in } // Read-only binding from chip's perspective
            ),
            onSelectMicrophone: { [weak self] in
                self?.onSelectMicrophone?()
            },
            onTroubleshoot: { [weak self] in
                self?.onTroubleshoot?()
            },
            onDismissError: { [weak self] in
                self?.chipState = .normal
            },
            onCancelRecording: { [weak self] in
                self?.cancelRecording()
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
        
        // let visibleFrame = screen.visibleFrame // Unused
        let fullFrame = screen.frame
        
        // Calculate dimensions based on state
        var requiredWidth: CGFloat = FloatingWaveformChip.chipWidth
        var requiredHeight: CGFloat = FloatingWaveformChip.compactHeight
        
        if isRecording {
            requiredWidth = FloatingWaveformChip.recordingWidth
            requiredHeight = FloatingWaveformChip.expandedHeight
        } else {
            switch chipState {
            case .hover:
                requiredWidth = FloatingWaveformChip.hoveredWidth
                requiredHeight = FloatingWaveformChip.expandedHeight
            case .error, .processing, .requestError:
                requiredWidth = 400 // Max width for panels
                requiredHeight = 250 // Expanded height for panels
            default:
                requiredWidth = FloatingWaveformChip.chipWidth
                requiredHeight = FloatingWaveformChip.compactHeight
            }
        }
        
        // Center horizontally on the PHYSICAL screen
        let x = fullFrame.midX - (requiredWidth / 2)
        
        // Position vertically: Use DockManager to get the recommended bottom margin
        // This handles hidden dock and different dock sizes
        let bottomMargin = dockManager.getRecommendedBottomMargin()
        let y = fullFrame.minY + bottomMargin
        
        // Ensure the panel stays within screen bounds horizontally
        let finalX = max(fullFrame.minX, min(x, fullFrame.maxX - requiredWidth))
        let finalY = y // Trust DockManager's calculation for Y
        
        // Update frame
        // Use animation for smooth resizing if the window is already visible
        if panel.isVisible {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(NSRect(x: finalX, y: finalY, width: requiredWidth, height: requiredHeight), display: true)
            }, completionHandler: nil)
        } else {
            panel.setFrame(NSRect(x: finalX, y: finalY, width: requiredWidth, height: requiredHeight), display: true)
        }
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
            
        // Setup polling for dock changes that don't trigger notifications (like autohide animations)
        // More aggressive 0.1s polling for smoother UI tracking
        positionPollingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.repositionChip()
        }
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
    
    func togglePause() {
        print("FloatingWaveformManager: togglePause() called, current isPaused: \(isPaused)")
        recordingManager.togglePause()
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
        
        // Don't hide, just revert to normal size/state
        DispatchQueue.main.async { [weak self] in
            // Only hide if not recording
            guard let self = self else { return }
            self.chipState = .normal
            self.repositionChip()
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