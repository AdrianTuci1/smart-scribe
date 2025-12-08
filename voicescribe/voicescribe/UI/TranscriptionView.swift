import SwiftUI

struct TranscriptionView: View {
    @StateObject private var viewModel = TranscriptionViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Button(action: { /* Apply Bold */ }) {
                    Image(systemName: "bold")
                }
                Button(action: { /* Apply Italic */ }) {
                    Image(systemName: "italic")
                }
                Button(action: { /* Apply Title */ }) {
                    Image(systemName: "textformat.size")
                }
                Button(action: { /* Apply List */ }) {
                    Image(systemName: "list.bullet")
                }
                Spacer()
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Editor Area
            ZStack(alignment: .topLeading) {
                RichTextEditor(text: $viewModel.finalText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if !viewModel.provisionalText.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Text(viewModel.provisionalText)
                                .italic()
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Material.ultraThinMaterial)
                                .cornerRadius(8)
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            
            // Footer Controls with Waveform
            HStack {
                Button(action: {
                    viewModel.toggleRecording()
                }) {
                    HStack {
                        Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title)
                            .foregroundColor(viewModel.isRecording ? .red : .green)
                        
                        if viewModel.isRecording {
                            WaveformView(isRecording: true)
                                .frame(width: 100)
                        }
                        
                        Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}
