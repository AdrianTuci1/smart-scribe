import SwiftUI

struct WaveformView: View {
    @State private var phase: CGFloat = 0.0
    var isRecording: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "mic.fill")
                .foregroundColor(.red)
                .padding(.trailing, 4)
            
            ForEach(0..<10) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isRecording ? Color.primary : Color.secondary.opacity(0.5))
                    .frame(width: 3, height: isRecording ? CGFloat.random(in: 10...25) : 4)
                    .animation(
                        isRecording 
                            ? Animation.easeInOut(duration: 0.2).repeatForever().delay(Double(index) * 0.05) 
                            : .default,
                        value: isRecording
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Material.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    }

