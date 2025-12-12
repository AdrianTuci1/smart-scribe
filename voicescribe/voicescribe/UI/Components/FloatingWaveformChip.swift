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
    @State private var isHoveringChip: Bool = false
    @State private var showTooltip: Bool = false
    @State private var chipState: ChipState = .normal
    @State private var waveformAmplitudes: [CGFloat] = Array(repeating: 3, count: 5)
    
    // Dock manager for positioning
    @StateObject private var dockManager = DockManager.shared
    
    // Callbacks for error panel actions
    var onSelectMicrophone: (() -> Void)?
    var onTroubleshoot: (() -> Void)?
    var onDismissError: (() -> Void)?
    
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
    
    // Recording width (slightly wider only on recording)
    private let recordingWidth: CGFloat = 84
    
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
            
            // Tooltip (appears on hover when not recording)
            if isHoveringChip && !isRecording && showTooltip && chipState != .recording {
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
                chipState = .recording
                startWaveformAnimation()
            } else {
                chipState = isHoveringChip ? .hover : .normal
                stopWaveformAnimation()
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
                Button(action: cancelRecording) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color(white: 0.2))
                        )
                }
                .buttonStyle(.plain)
            }
            
            // Waveform Area (center) - always visible, changes appearance
            HStack(spacing: isRecording ? 4 : 3) {
                if isRecording {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.red)
                            .frame(width: 3, height: waveformAmplitudes[index])
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
            
            // Stop Button - visible only when recording
            if isRecording {
                Button(action: stopRecording) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.red)
                        .frame(width: 14, height: 14)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(Color(white: 0.25))
                        )
                }
                .buttonStyle(.plain)
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
            if !isRecording {
                toggleRecording()
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    if !isRecording {
                        toggleRecording()
                    }
                }
        )
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
    
    private func cancelRecording() {
        withAnimation {
            isRecording = false
        }
    }
    
    private func dismissError() {
        withAnimation {
            chipState = .normal
        }
        onDismissError?()
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
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
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
    
    // MARK: - Action Methods
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
}

// MARK: - Hover Handling
private extension FloatingWaveformChip {
    func handleHoverChange(hovering: Bool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            isHoveringChip = hovering
            if !isRecording {
                chipState = hovering ? .hover : .normal
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
        
        FloatingWaveformChip(isRecording: .constant(false))
    }
}
