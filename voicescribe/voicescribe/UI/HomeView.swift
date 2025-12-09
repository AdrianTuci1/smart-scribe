import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var hoveredTranscriptId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Welcome Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Welcome back, \(viewModel.userName)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    HStack(spacing: 16) {
                        Label("\(viewModel.streakDays) week", systemImage: "flame.fill")
                            .foregroundColor(.orange)
                        Label("\(viewModel.totalWords) words", systemImage: "pencil")
                            .foregroundColor(.red)
                        Label("\(viewModel.wordsPerMinute) WPM", systemImage: "hand.thumbsup.fill")
                            .foregroundColor(.yellow)
                    }
                    .font(.caption)
                }
            }
            
            // Feature promotion card
            VStack(alignment: .leading, spacing: 12) {
                Text("Tag @files and `variables` hands free")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 0) {
                    Text("\"Can you refactor helloWorld.js?\" — ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Flow automatically tags the right files and variables in Cursor and Windsurf, no hands required!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Button("Try it now") {
                    // Action
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .controlSize(.regular)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.3, green: 0.54, blue: 0.88)) // Light yellow
            .cornerRadius(12)
            
            // Transcripts List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.groupedTranscripts, id: \.0) { group, transcripts in
                        // Section Header
                        Text(group)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
                        ForEach(transcripts) { transcript in
                            TranscriptRow(
                                transcript: transcript,
                                isHovered: hoveredTranscriptId == transcript.id,
                                showTime: shouldShowTime(for: transcript, in: transcripts),
                                onCopy: { viewModel.copyTranscript(transcript) },
                                onFlag: { viewModel.toggleFlag(transcript) },
                                onUndoAIEdit: { viewModel.undoAIEdit(transcript) },
                                onRetry: { viewModel.retryTranscription(transcript) },
                                onDelete: { viewModel.deleteTranscript(transcript) },
                                onDownloadAudio: { viewModel.downloadAudio(transcript) }
                            )
                            .onHover { isHovered in
                                hoveredTranscriptId = isHovered ? transcript.id : nil
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            viewModel.loadTranscripts()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private func shouldShowTime(for transcript: Transcript, in transcripts: [Transcript]) -> Bool {
        guard let index = transcripts.firstIndex(where: { $0.id == transcript.id }) else {
            return true
        }
        
        // Always show time for first item
        if index == 0 {
            return true
        }
        
        // Show time if previous transcript has a different minute
        let previous = transcripts[index - 1]
        let calendar = Calendar.current
        let currentMinute = calendar.component(.minute, from: transcript.timestamp)
        let previousMinute = calendar.component(.minute, from: previous.timestamp)
        let currentHour = calendar.component(.hour, from: transcript.timestamp)
        let previousHour = calendar.component(.hour, from: previous.timestamp)
        
        return currentMinute != previousMinute || currentHour != previousHour
    }
}

// MARK: - Transcript Row View
struct TranscriptRow: View {
    let transcript: Transcript
    let isHovered: Bool
    let showTime: Bool
    let onCopy: () -> Void
    let onFlag: () -> Void
    let onUndoAIEdit: () -> Void
    let onRetry: () -> Void
    let onDelete: () -> Void
    let onDownloadAudio: () -> Void
    
    @State private var showCopyTooltip = false
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: transcript.timestamp)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Time column
            Text(showTime ? timeString : "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
                .opacity(showTime ? 1 : 0)
            
            // Text content
            Text(transcript.text)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Action buttons (visible on hover)
            HStack(spacing: 8) {
                // Copy button
                Button(action: {
                    onCopy()
                    showCopyTooltip = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopyTooltip = false
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(showCopyTooltip ? "Copied!" : "Copy transcript")
                
                // Flag button
                Button(action: onFlag) {
                    Image(systemName: transcript.isFlagged ? "flag.fill" : "flag")
                        .font(.system(size: 14))
                        .foregroundColor(transcript.isFlagged ? .orange : .secondary)
                }
                .buttonStyle(.plain)
                .help(transcript.isFlagged ? "Remove flag" : "Flag transcript")
                
                // More options menu
                Menu {
                    if transcript.canUndoAIEdit {
                        Button(action: onUndoAIEdit) {
                            Label("Undo AI edit", systemImage: "arrow.uturn.backward")
                        }
                    }
                    
                    Button(action: onRetry) {
                        Label("Retry transcript", systemImage: "arrow.clockwise")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete transcript", systemImage: "trash")
                    }
                    
                    Divider()
                    
                    Button(action: onDownloadAudio) {
                        Label("Download audio", systemImage: "arrow.down.circle")
                    }
                    .disabled(transcript.audioUrl == nil)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20)
            }
            .opacity(isHovered ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isHovered ? Color.gray.opacity(0.05) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Home View Model
@MainActor
class HomeViewModel: ObservableObject {
    @Published var transcripts: [Transcript] = []
    @Published var groupedTranscripts: [(String, [Transcript])] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Stats
    @Published var userName = "User"
    @Published var streakDays = 1
    @Published var totalWords = 0
    @Published var wordsPerMinute = 0
    
    private let apiService = APIService.shared
    private let authService = AuthService.shared
    
    init() {
        // Load user info
        if let name = authService.userName {
            userName = name
        }
    }
    
    func loadTranscripts() {
        isLoading = true
        
        Task {
            do {
                let fetchedTranscripts = try await apiService.fetchTranscripts()
                self.transcripts = fetchedTranscripts
                self.groupedTranscripts = fetchedTranscripts.groupedByDate()
                self.calculateStats()
            } catch {
                self.showError(message: "Failed to load transcripts: \(error.localizedDescription)")
            }
            self.isLoading = false
        }
    }
    
    func copyTranscript(_ transcript: Transcript) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(transcript.text, forType: .string)
    }
    
    func toggleFlag(_ transcript: Transcript) {
        let updatedTranscript = transcript.withToggledFlag()
        
        Task {
            do {
                _ = try await apiService.updateTranscript(updatedTranscript)
                // Update local state
                if let index = transcripts.firstIndex(where: { $0.id == transcript.id }) {
                    transcripts[index] = updatedTranscript
                    groupedTranscripts = transcripts.groupedByDate()
                }
            } catch {
                showError(message: "Failed to update transcript: \(error.localizedDescription)")
            }
        }
    }
    
    func undoAIEdit(_ transcript: Transcript) {
        let restoredTranscript = transcript.withUndoneAIEdit()
        
        Task {
            do {
                _ = try await apiService.updateTranscript(restoredTranscript)
                // Update local state
                if let index = transcripts.firstIndex(where: { $0.id == transcript.id }) {
                    transcripts[index] = restoredTranscript
                    groupedTranscripts = transcripts.groupedByDate()
                }
            } catch {
                showError(message: "Failed to undo AI edit: \(error.localizedDescription)")
            }
        }
    }
    
    func retryTranscription(_ transcript: Transcript) {
        Task {
            do {
                let updatedTranscript = try await apiService.retryTranscription(transcriptId: transcript.id)
                // Update local state
                if let index = transcripts.firstIndex(where: { $0.id == transcript.id }) {
                    transcripts[index] = updatedTranscript
                    groupedTranscripts = transcripts.groupedByDate()
                }
            } catch {
                showError(message: "Failed to retry transcription: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteTranscript(_ transcript: Transcript) {
        Task {
            do {
                try await apiService.deleteTranscript(id: transcript.id)
                // Update local state
                transcripts.removeAll { $0.id == transcript.id }
                groupedTranscripts = transcripts.groupedByDate()
            } catch {
                showError(message: "Failed to delete transcript: \(error.localizedDescription)")
            }
        }
    }
    
    func downloadAudio(_ transcript: Transcript) {
        guard transcript.audioUrl != nil else {
            showError(message: "No audio available for this transcript")
            return
        }
        
        Task {
            do {
                let audioURL = try await apiService.getTranscriptAudioURL(transcriptId: transcript.id)
                
                // Open save panel
                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [.audio]
                savePanel.nameFieldStringValue = "transcript_\(transcript.id).m4a"
                
                let response = await savePanel.beginSheetModal(for: NSApp.keyWindow!)
                
                if response == .OK, let destinationURL = savePanel.url {
                    // Download the audio file
                    let (data, _) = try await URLSession.shared.data(from: audioURL)
                    try data.write(to: destinationURL)
                }
            } catch {
                showError(message: "Failed to download audio: \(error.localizedDescription)")
            }
        }
    }
    
    private func calculateStats() {
        // Calculate total words
        totalWords = transcripts.reduce(0) { count, transcript in
            count + transcript.text.split(separator: " ").count
        }
        
        // Calculate words per minute (rough estimate based on transcription times)
        // This is a simplified calculation
        if !transcripts.isEmpty {
            wordsPerMinute = max(30, min(80, totalWords / max(1, transcripts.count)))
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
