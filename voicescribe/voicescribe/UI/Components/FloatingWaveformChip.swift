import SwiftUI
import AppKit

// MARK: - Chip State Enum
enum ChipState: Equatable {
    case normal
    case hover
    case recording
    case error(title: String, message: String, micName: String)
    case serverError // New error state for server send failure
    case processing(message: String) // PLEASE_HOLD and SLOW_PROCESSING
    case requestError(message: String, actionTitle: String) // REQUEST_ISSUE
    
    static func == (lhs: ChipState, rhs: ChipState) -> Bool {
        switch (lhs, rhs) {
        case (.normal, .normal), (.hover, .hover), (.recording, .recording), (.serverError, .serverError):
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

    
    var isServerError: Bool {
        if case .serverError = self { return true }
        return false
    }
}

// MARK: - Main Chip View
struct FloatingWaveformChip: View {
    @Binding var isRecording: Bool
    @Binding var isPaused: Bool
    
    @State private var isHoveringChip: Bool = false
    @State private var showTooltip: Bool = false
    @Binding var chipState: ChipState
    @Binding var waveformAmplitudes: [CGFloat]
    
    // Dock manager for positioning
    @StateObject private var dockManager = DockManager.shared
    
    // Callbacks for error panel actions
    var onSelectMicrophone: (() -> Void)?
    var onTroubleshoot: (() -> Void)?
    var onDismissError: (() -> Void)?
    var onCancelRecording: (() -> Void)?
    
    // Timer for waveform animation
    // Timer for waveform animation - REMOVED, using Binding
    // @State private var animationTimer: Timer?
    
    // Unified chip dimensions
    // Not hovered (idle) size baseline
    // Unified chip dimensions
    // Not hovered (idle) size baseline
    public static let chipWidth: CGFloat = 36
    public static let compactHeight: CGFloat = 13
    
    // Hovered width tweak
    public static let hoveredWidth: CGFloat = 52
    
    // Hovered/recording height baseline
    public static let expandedHeight: CGFloat = 22
    
    // Recording width (wider to accommodate pause button)
    public static let recordingWidth: CGFloat = 130 // Increased to ensure buttons fit comfortably
    
    var body: some View {
        VStack(spacing: 8) {
            // Panels show above the chip
            switch chipState {
            case .error(let title, let message, let micName):
                errorPanel(title: title, message: message, micName: micName)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .processing(let message):
                processingPanel(message: message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .requestError(let message, let actionTitle):
                requestErrorPanel(message: message, actionTitle: actionTitle)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            default:
                EmptyView()
            }
            
            unifiedChip
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        // Animation timer removed, controlled by parent
    }

    // MARK: - Unified Chip (same size for normal and recording)
    private var unifiedChip: some View {
            HStack(spacing: 0) {
                // X (Cancel) Button - visible only when recording
                if isRecording {
                    Button(action: cancelRecordingAction) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 14, height: 14) // 14px as requested
                            .background(
                                Circle()
                                    .fill(Color(white: 0.2))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 6)
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
                .contentShape(Rectangle())
                
                if isRecording {
                    // Stop Button (Done)
                    Button(action: stopRecording) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.red)
                            .frame(width: 8, height: 8) // Inner square slightly smaller
                            .padding(3) // Padding to make touch target/visual wrapper 14px
                            .frame(width: 14, height: 14) // Outer frame 14px
                            .background(
                                Circle()
                                    .fill(Color(white: 0.25))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 6)
                } else if case .serverError = chipState {
                     // Error State: "!" icon in place of buttons
                     Image(systemName: "exclamationmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 14, height: 14)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(width: isRecording ? Self.recordingWidth : (isHoveringChip ? Self.hoveredWidth : Self.chipWidth),
                   height: (!isHoveringChip && !isRecording && chipState != .serverError) ? Self.compactHeight : Self.expandedHeight)
            .background(
                Capsule()
                    .fill(Color(white: 0.12))
                    .overlay(
                        Capsule()
                            .stroke(chipState.isServerError ? Color.red : Color(white: 0.28), lineWidth: (isHoveringChip || isRecording || chipState.isServerError) ? 1 : 0)
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
        // MARK: - Waveform Animation
        // Handled by parent via Binding

        
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
    
    
    // MARK: - Hover Handling
    private func handleHoverChange(hovering: Bool) {
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
                chipState: .constant(.normal),
                waveformAmplitudes: .constant(Array(repeating: 5.0, count: 5))
            )
        }
    }
