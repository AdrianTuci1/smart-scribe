import SwiftUI

// MARK: - Chip State Enum
enum ChipState: Equatable {
    case normal
    case hover
    case recording
    case error(title: String, message: String, micName: String)
    
    static func == (lhs: ChipState, rhs: ChipState) -> Bool {
        switch (lhs, rhs) {
        case (.normal, .normal), (.hover, .hover), (.recording, .recording):
            return true
        case (.error(let t1, let m1, let n1), .error(let t2, let m2, let n2)):
            return t1 == t2 && m1 == m2 && n1 == n2
        default:
            return false
        }
    }
}

// MARK: - Main Chip View
struct FloatingWaveformChip: View {
    @Binding var isRecording: Bool
    @State private var isHovering: Bool = false
    @State private var showTooltip: Bool = false
    @State private var chipState: ChipState = .normal
    @State private var waveformAmplitudes: [CGFloat] = Array(repeating: 3, count: 7)
    
    // Callbacks for error panel actions
    var onSelectMicrophone: (() -> Void)?
    var onTroubleshoot: (() -> Void)?
    var onDismissError: (() -> Void)?
    
    // Timer for waveform animation
    @State private var animationTimer: Timer?
    
    // Unified chip dimensions
    private let chipWidth: CGFloat = 70
    private let chipHeight: CGFloat = 24
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Error Panel (when in error state)
            if case .error(let title, let message, let micName) = chipState {
                errorPanel(title: title, message: message, micName: micName)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .padding(.bottom, 12)
            }
            
            // Tooltip (appears on hover when not recording)
            if isHovering && !isRecording && showTooltip && chipState != .recording {
                tooltipView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .padding(.bottom, 8)
            }
            
            // Main Chip - unified view with smooth transitions
            unifiedChip
        }
        .frame(maxWidth: .infinity) // Center horizontally
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovering)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isRecording)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: chipState)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                chipState = .recording
                startWaveformAnimation()
            } else {
                chipState = isHovering ? .hover : .normal
                stopWaveformAnimation()
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
                if !isRecording {
                    chipState = hovering ? .hover : .normal
                }
            }
            
            // Show tooltip after a brief delay
            if hovering && !isRecording {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        showTooltip = hovering && isHovering && !isRecording
                    }
                }
            } else {
                showTooltip = false
            }
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
            Button(action: cancelRecording) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(Color(white: 0.25))
            )
            .opacity(isRecording ? 1 : 0)
            .scaleEffect(isRecording ? 1 : 0.5)
            
            // Waveform Area (center) - always visible, changes appearance
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { index in
                    if isRecording {
                        // Recording: animated red bars
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.red)
                            .frame(width: 3, height: waveformAmplitudes[index])
                    } else {
                        // Normal: subtle dots
                        Circle()
                            .fill(Color(white: isHovering ? 0.5 : 0.35))
                            .frame(width: 3, height: 3)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            
            // Stop Button - visible only when recording
            Button(action: stopRecording) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(Color(white: 0.35))
            )
            .opacity(isRecording ? 1 : 0)
            .scaleEffect(isRecording ? 1 : 0.5)
        }
        .padding(4)
        .frame(width: chipWidth, height: chipHeight)
        .background(
            Capsule()
                .fill(Color(white: 0.12))
                .overlay(
                    Capsule()
                        .stroke(Color(white: 0.28), lineWidth: 1)
                )
        )
        .onTapGesture {
            if !isRecording {
                toggleRecording()
            }
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
                waveformAmplitudes = (0..<7).map { _ in
                    CGFloat.random(in: 3...20)
                }
            }
        }
    }
    
    private func stopWaveformAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        withAnimation {
            waveformAmplitudes = Array(repeating: 3, count: 7)
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
