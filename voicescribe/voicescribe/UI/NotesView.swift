import SwiftUI

struct NotesView: View {
    @State private var notes: [Note] = []
    @State private var voiceInputText: String = ""
    @State private var isRecording: Bool = false
    
    private let syncService = DataSyncService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("For quick thoughts you want to come back to")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.top, 24)
                .padding(.bottom, 32)
            
            // Voice input field
            HStack(spacing: 16) {
                TextField("", text: $voiceInputText, prompt: Text("Take a quick note with your voice").foregroundColor(.secondary))
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                
                // Microphone button
                Button(action: {
                    isRecording.toggle()
                    if !isRecording && !voiceInputText.isEmpty {
                        saveNote()
                    }
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.25))
                        )
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, 48)
            .padding(.bottom, 48)
            
            // Recents section
            VStack(alignment: .leading, spacing: 16) {
                // Recents header with icons
                HStack {
                    Text("RECENTS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { loadNotes() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 48)
                
                Divider()
                    .padding(.horizontal, 48)
                
                // Notes list or empty state
                if notes.isEmpty {
                    VStack(spacing: 16) {
                        Text("No notes found")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 48)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(notes) { note in
                                NoteRecentRow(note: note)
                                    .onTapGesture {
                                        voiceInputText = note.content
                                    }
                            }
                        }
                        .padding(.horizontal, 48)
                        .padding(.top, 8)
                    }
                }
            }
            
            Spacer()
        }
        .frame(minWidth: 600, maxWidth: 900)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadNotes()
        }
    }
    
    private func saveNote() {
        let newNote = Note(id: UUID(), content: voiceInputText, createdAt: Date(), updatedAt: Date())
        notes.insert(newNote, at: 0)
        
        Task {
            do {
                try await syncService.syncNote(newNote)
            } catch {
                print("Failed to sync note: \(error)")
            }
        }
        
        voiceInputText = ""
    }
    
    private func loadNotes() {
        Task {
            do {
                let fetchedNotes = try await syncService.fetchNotes()
                DispatchQueue.main.async {
                    self.notes = fetchedNotes
                }
            } catch {
                print("Failed to fetch notes: \(error)")
                DispatchQueue.main.async {
                    self.notes = []
                }
            }
        }
    }
}

struct NoteRecentRow: View {
    let note: Note
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.windowBackgroundColor))
        )
    }
}

