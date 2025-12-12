import SwiftUI
import AppKit

// MARK: - Chip State Enum
enum ChipState: Equatable {
    case normal
    case hover
    case recording
    case error(title: String, message: String, micName: String)
    case processing(message: String) // PLEASE_HOLD and SLOW_PROCESSING
    case requestError(message: String, actionTitle: String) // REQUEST_ISSUE
    
    static func == (lhs: ChipState, rhs: ChipState) -> Bool {
        switch (lhs, rhs) {
        case (.normal, .normal), (.hover, .hover), (.recording, .recording):
            return true
        case (.error(let t1, let m1, let n1), .error(let t2, let m2, let n2)):
            return t1 == t2 && m1 == m2 && n1 == n2
        case (.processing(let m1), .processing(let m2)):
            return m1 == m2
        case (.requestError(let m1, let a1), .requestError(let m2, let a2)):
            return m1 == m2 && a1 == a2
        default:
            return false
        }
    }
}

// MARK: - Main Chip View
struct FloatingWaveformChip: View {
    @Binding var isRecording: Bool
    @Binding var isPaused: Bool
    
    @State private var isHoveringChip: Bool = false
    @State private var showTooltip: Bool = false
    @Binding var chipState: ChipState
    @State private var waveformAmplitudes: [CGFloat] = Array(repeating: 3, count: 5)
    
    // Dock manager for positioning
    @StateObject private var dockManager = DockManager.shared
    
    // Callbacks for error panel actions
    var onSelectMicrophone: (() -> Void)?
    var onTroubleshoot: (() -> Void)?
    var onDismissError: (() -> Void)?
    var onCancelRecording: (() -> Void)?
    
    // Timer for waveform animation
    @State private var animationTimer: Timer?
    
    // Unified chip dimensions
    // Not hovered (idle) size baseline
    private let chipWidth: CGFloat = 36
    private let compactHeight: CGFloat = 13
    
    // Hovered width tweak
    private let hoveredWidth: CGFloat = 52
    
    // Hovered/recording height baseline
    private let expandedHeight: CGFloat = 22
    
    // Recording width (wider to accommodate pause button)
    private let recordingWidth: CGFloat = 110
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Error Panel (when in error state)
            if case .error(let title, let message, let micName) = chipState {
                errorPanel(title: title, message: message, micName: micName)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .padding(.bottom, 12)
            }
            
            // Processing Panel (PLEASE_HOLD and SLOW_PROCESSING)
            if case .processing(let message) = chipState {
                processingPanel(message: message)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .padding(.bottom, 12)
            }
            
            // Request Error Panel (REQUEST_ISSUE)
            if case .requestError(let message, let actionTitle) = chipState {
                requestErrorPanel(message: message, actionTitle: actionTitle)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .padding(.bottom, 12)
            }
            
            // Tooltip (appears on hover when not recording and no error/processing state)
            if isHoveringChip && !isRecording && showTooltip && (chipState == .normal || chipState == .hover) {
                tooltipView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .padding(.bottom, 8)
            }
            
            // Main Chip - unified view with smooth transitions
            unifiedChip
        }
        .frame(maxWidth: .infinity) // Center horizontally
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHoveringChip)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isRecording)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: chipState)
        .animation(.easeInOut(duration: 0.5), value: dockManager.dockIsHidden) // Animate position changes
        .animation(.easeInOut(duration: 0.5), value: dockManager.dockHeight) // Animate position changes
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                // state is handled by manager bindings now
                startWaveformAnimation()
            } else {
                stopWaveformAnimation()
            }
        }
        .onChange(of: isPaused) { _, newValue in
            // Handle pause state visual updates if needed
            if newValue {
                stopWaveformAnimation()
            } else if isRecording {
                startWaveformAnimation()
            }
        }
        .onAppear {
            dockManager.updateDockInfo() // Ensure dock info is current when view appears
        }
    }
    
    // MARK: - Tooltip View (wider, text on single line)
    private var tooltipView: some View {
        HStack(spacing: 0) {
            Text("Click or hold ")
                .font(.system(size: 14))
                .foregroundColor(.white)
            Text("fn")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Text(" to start dictating")
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .fixedSize(horizontal: true, vertical: false) // Prevent text wrapping
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color(white: 0.12))
                .overlay(
                    Capsule()
                        .stroke(Color(white: 0.25), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Unified Chip (same size for normal and recording)
    private var unifiedChip: some View {
        HStack(spacing: 0) {
            // X (Cancel) Button - visible only when recording
            if isRecording {
                Button(action: cancelRecordingAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold)) // Slightly smaller
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(Color(white: 0.2))
                        )
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
            
            // Waveform Area (center) - always visible, changes appearance
            HStack(spacing: isRecording ? 4 : 3) {
                if isRecording {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(isPaused ? Color.gray : Color.red) // Grey when paused
                            .frame(width: 3, height: isPaused ? 3 : waveformAmplitudes[index])
                    }
                } else if isHoveringChip {
                    ForEach(0..<5, id: \.self) { _ in
                        Circle()
                            .fill(Color(white: 0.55))
                            .frame(width: 3, height: 3)
                    }
                } else {
                    Capsule()
                        .fill(Color(white: 0.3))
                        .frame(width: 16, height: 2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 18)
            .contentShape(Rectangle()) // Make the area tappable locally if needed
            
            if isRecording {
                // Pause/Resume Button
                Button(action: togglePause) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(Color(white: 0.2))
                        )
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
                
                // Stop Button (Done)
                Button(action: stopRecording) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white) // Start with white checkmark concept? Or keep red square for stop?
                        // User likely wants "Done". The stop symbol usually implies "Finish".
                        // Standard practice: Red square = Stop/Finish.
                        // Let's use red square but maybe a checkmark for "Done" is friendlier?
                        // Stick to red square logic from existing code, but maybe consider user intent.
                        // Code had red square.
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(Color(white: 0.25))
                        )
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(width: isRecording ? recordingWidth : (isHoveringChip ? hoveredWidth : chipWidth),
               height: (!isHoveringChip && !isRecording) ? compactHeight : expandedHeight)
        .background(
            Capsule()
                .fill(Color(white: 0.12))
                .overlay(
                    Capsule()
                        .stroke(Color(white: 0.28), lineWidth: 1)
                )
        )
        .onTapGesture(count: 1) {
            // Main tap action behavior
            if !isRecording {
                toggleRecording()
            }
            // If recording, tapping the background (not buttons) does nothing or stops?
            // Usually buttons handle actions. This capture only affects non-button area.
        }
        .onHover { hovering in
            handleHoverChange(hovering: hovering)
        }
    }
    
    // MARK: - Error Panel
    private func errorPanel(title: String, message: String, micName: String) -> some View {
        VStack(spacing: 12) {
            // Header with error icon and close button
            HStack {
                // Error icon
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text("!")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                    )
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Close button
                Button(action: { dismissError() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            // Message
            Text(message.replacingOccurrences(of: "{mic}", with: micName))
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
            
            // Buttons
            HStack(spacing: 12) {
                Button(action: { onSelectMicrophone?() }) {
                    Text("Select microphone")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(white: 0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: { onTroubleshoot?() }) {
                    Text("Troubleshoot")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(white: 0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(white: 0.18), lineWidth: 1)
                )
        )
        .frame(maxWidth: 400)
    }
    
    // MARK: - Actions
    private func toggleRecording() {
        withAnimation {
            isRecording.toggle()
        }
    }
    
    private func stopRecording() {
        withAnimation {
            isRecording = false
        }
    }
    
    private func cancelRecordingAction() {
        // Use the callback provided by Manager
        onCancelRecording?()
    }
    
    private func togglePause() {
        withAnimation {
            isPaused.toggle()
        }
    }
    
    private func dismissError() {
        withAnimation {
            chipState = .normal
        }
        onDismissError?()
    }
    
    private func dismissProcessing() {
        withAnimation {
            chipState = .normal
        }
    }
    
    private func continueProcessing() {
        // Continue waiting, maintain processing state
        // The timer or caller should manage this state
    }
    
    private func dismissRequestError() {
        withAnimation {
            chipState = .normal
        }
    }
    
    private func retryRequest() {
        // Trigger retry by notifying parent
        // This would typically be handled through a callback
        withAnimation {
            chipState = .normal
        }
    }
    
    // MARK: - Show Error
    func showError(title: String = "We couldn't hear you", 
                   message: String = "We didn't pick up any speech from your {mic} microphone",
                   micName: String = "Built-in mic (recommended)") {
        withAnimation {
            chipState = .error(title: title, message: message, micName: micName)
        }
    }
    
    // MARK: - Waveform Animation
    private func startWaveformAnimation() {
        // Don't restart if already running
        guard animationTimer == nil else { return }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard !isPaused else { return }
            withAnimation(.easeInOut(duration: 0.1)) {
                waveformAmplitudes = (0..<5).map { _ in
                    CGFloat.random(in: 4...18)
                }
            }
        }
    }
    
    private func stopWaveformAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        withAnimation {
            waveformAmplitudes = Array(repeating: 3, count: 5)
        }
    }
    
    // MARK: - Processing Panel
    private func processingPanel(message: String) -> some View {
        VStack(spacing: 12) {
            // Header with processing icon and close button
            HStack {
                // Processing icon
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "clock")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                    )
                
                Text("Procesare")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Close button
                Button(action: { dismissProcessing() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            // Message
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
            
            // Continue/Cancel buttons
            HStack(spacing: 12) {
                Button(action: { dismissProcessing() }) {
                    Text("Anulează")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(white: 0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: { continueProcessing() }) {
                    Text("Continuă așteptarea")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(white: 0.18), lineWidth: 1)
                )
        )
        .frame(maxWidth: 400)
    }
    
    // MARK: - Request Error Panel
    private func requestErrorPanel(message: String, actionTitle: String) -> some View {
        VStack(spacing: 12) {
            // Header with error icon and close button
            HStack {
                // Error icon
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text("!")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                    )
                
                Text("Problemă cu cererea")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Close button
                Button(action: { dismissRequestError() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            // Message
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: { dismissRequestError() }) {
                    Text("Anulează")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(white: 0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: { retryRequest() }) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(white: 0.18), lineWidth: 1)
                )
        )
        .frame(maxWidth: 400)
    }
}

// MARK: - Hover Handling
private extension FloatingWaveformChip {
    func handleHoverChange(hovering: Bool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            isHoveringChip = hovering
            if !isRecording {
                // Only change state if we are currently in normal or hover state
                // This prevents overwriting error/processing states
                if chipState == .normal || chipState == .hover {
                    chipState = hovering ? .hover : .normal
                }
            }
        }
        
        if hovering && !isRecording {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if isHoveringChip && !isRecording {
                    withAnimation {
                        showTooltip = true
                    }
                }
            }
        } else {
            showTooltip = false
        }
    }
    
    // MARK: - Public Methods for Notifications
    func showProcessing(message: String = "Vă rugăm să așteptați. Procesarea durează mai mult decât de obicei.") {
        withAnimation {
            chipState = .processing(message: message)
        }
    }
    
    func showRequestError(message: String = "A existat o problemă cu solicitarea dumneavoastră. Vă rugăm să încercați din nou.", actionTitle: String = "Încearcă din nou") {
        withAnimation {
            chipState = .requestError(message: message, actionTitle: actionTitle)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.blue.opacity(0.3)
            .ignoresSafeArea()
        
        FloatingWaveformChip(
            isRecording: .constant(false),
            isPaused: .constant(false),
            chipState: .constant(.normal)
        )
    }
}
