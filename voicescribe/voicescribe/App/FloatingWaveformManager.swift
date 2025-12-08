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
    
    // Callbacks for error panel actions
    var onSelectMicrophone: (() -> Void)?
    var onTroubleshoot: (() -> Void)?
    
    init() {
        setupBindings()
        createFloatingChip()
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
        // Create the SwiftUI view with binding to isRecording
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
        
        // Create the panel - increased size to accommodate error panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 250),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure panel properties
        panel.level = .statusBar // Above normal windows, below menu bar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false // View has its own shadow
        panel.contentViewController = hostingController
        
        // Position at bottom center of screen
        positionChip(panel)
        
        // Show the panel
        panel.orderFront(nil)
        
        self.chipWindow = panel
    }
    
    private func positionChip(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let panelWidth: CGFloat = 420
        let panelHeight: CGFloat = 250
        
        // Position at bottom center, above the Dock
        let x = screenFrame.midX - (panelWidth / 2)
        let y = screenFrame.minY + 7 // Very close to bottom, just above Dock
        
        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
    }
    
    // MARK: - Public Methods
    
    func toggleRecording() {
        recordingManager.toggleRecording()
    }
    
    func startRecording() {
        recordingManager.startRecording()
    }
    
    func stopRecording() {
        recordingManager.stopRecording()
    }
    
    func cancelRecording() {
        recordingManager.cancelRecording()
    }
    
    func show() {
        chipWindow?.orderFront(nil)
    }
    
    func hide() {
        chipWindow?.orderOut(nil)
    }
    
    func showError(title: String = "We couldn't hear you",
                   message: String = "We didn't pick up any speech from your {mic} microphone",
                   micName: String = "Built-in mic (recommended)") {
        // Need to recreate the chip view with error state
        // For now, we'll trigger this through the chip view directly
    }
}
