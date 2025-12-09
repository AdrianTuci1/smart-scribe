import SwiftUI

struct DictionaryView: View {
    @State private var entries: [DictionaryEntry] = []
    @State private var searchText: String = ""
    @State private var showingAddEntry: Bool = false
    @State private var editingEntry: DictionaryEntry?
    
    private let syncService = DataSyncService.shared
    
    var filteredEntries: [DictionaryEntry] {
        if searchText.isEmpty {
            return entries.sorted { $0.incorrectWord < $1.incorrectWord }
        } else {
            return entries.filter {
                $0.incorrectWord.localizedCaseInsensitiveContains(searchText) ||
                $0.correctWord.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.incorrectWord < $1.incorrectWord }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Add corrections to help improve transcription accuracy")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.top, 24)
                .padding(.bottom, 32)
            
            // Search input field
            HStack(spacing: 16) {
                TextField("", text: $searchText, prompt: Text("Search corrections...").foregroundColor(.secondary))
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                
                // Search button
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.25))
                        )
                }
                .buttonStyle(.plain)
                
                // Add button
                Button(action: { showingAddEntry = true }) {
                    Image(systemName: "plus")
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
            
            // Dictionary entries section
            VStack(alignment: .leading, spacing: 16) {
                // Dictionary header with icons
                HStack {
                    Text("DICTIONARY")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(searchText.isEmpty)
                        
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { loadSampleData() }) {
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
                
                // Entries list or empty state
                if filteredEntries.isEmpty {
                    VStack(spacing: 16) {
                        Text(searchText.isEmpty ? "No dictionary entries yet" : "No matching entries")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 48)
                        if searchText.isEmpty {
                            Text("Add corrections to help improve transcription accuracy")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(filteredEntries) { entry in
                                DictionaryRecentRow(entry: entry)
                                    .contextMenu {
                                        Button("Edit") {
                                            editingEntry = entry
                                        }
                                        Button("Delete", role: .destructive) {
                                            deleteEntry(entry)
                                        }
                                    }
                                    .onTapGesture {
                                        editingEntry = entry
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
        .sheet(isPresented: $showingAddEntry) {
            AddDictionaryEntryView { incorrectWord, correctWord in
                addEntry(incorrectWord: incorrectWord, correctWord: correctWord)
            }
        }
        .sheet(item: $editingEntry) { entry in
            EditDictionaryEntryView(entry: entry) { updated in
                updateEntry(updated)
            }
        }
        .onAppear {
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        Task {
            do {
                let fetchedEntries = try await syncService.fetchDictionary()
                DispatchQueue.main.async {
                    if !fetchedEntries.isEmpty {
                        self.entries = fetchedEntries
                    } else {
                        // Use sample data if no entries found
                        self.entries = [
                            DictionaryEntry(incorrectWord: "gonna", correctWord: "going to"),
                            DictionaryEntry(incorrectWord: "wanna", correctWord: "want to"),
                            DictionaryEntry(incorrectWord: "gotta", correctWord: "got to")
                        ]
                    }
                }
            } catch {
                print("Failed to fetch dictionary entries: \(error)")
                // Use sample data on error
                DispatchQueue.main.async {
                    if self.entries.isEmpty {
                        self.entries = [
                            DictionaryEntry(incorrectWord: "gonna", correctWord: "going to"),
                            DictionaryEntry(incorrectWord: "wanna", correctWord: "want to"),
                            DictionaryEntry(incorrectWord: "gotta", correctWord: "got to")
                        ]
                    }
                }
            }
        }
    }
    
    private func addEntry(incorrectWord: String, correctWord: String) {
        let newEntry = DictionaryEntry(incorrectWord: incorrectWord, correctWord: correctWord)
        entries.append(newEntry)
        
        Task {
            do {
                try await syncService.syncDictionary(entries)
            } catch {
                print("Failed to sync dictionary: \(error)")
            }
        }
        
        showingAddEntry = false
    }
    
    private func updateEntry(_ updated: DictionaryEntry) {
        if let index = entries.firstIndex(where: { $0.id == updated.id }) {
            entries[index] = updated
            
            Task {
                do {
                    try await syncService.syncDictionary(entries)
                } catch {
                    print("Failed to sync dictionary: \(error)")
                }
            }
        }
        editingEntry = nil
    }
    
    private func deleteEntry(_ entry: DictionaryEntry) {
        entries.removeAll { $0.id == entry.id }
        
        Task {
            do {
                try await syncService.syncDictionary(entries)
            } catch {
                print("Failed to sync dictionary: \(error)")
            }
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        let entriesToDelete = offsets.map { filteredEntries[$0] }
        entries.removeAll { entry in entriesToDelete.contains { $0.id == entry.id } }
    }
}

struct DictionaryRecentRow: View {
    let entry: DictionaryEntry
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.incorrectWord)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text("Replaces as spoken")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.correctWord)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text("Corrected text")
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

struct AddDictionaryEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var incorrectWord: String = ""
    @State private var correctWord: String = ""
    let onAdd: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Dictionary Entry")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Word as Spoken")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g., gonna", text: $incorrectWord)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Correct Word")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g., going to", text: $correctWord)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add") {
                    onAdd(incorrectWord, correctWord)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(incorrectWord.isEmpty || correctWord.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

struct EditDictionaryEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var incorrectWord: String
    @State private var correctWord: String
    let entry: DictionaryEntry
    let onUpdate: (DictionaryEntry) -> Void
    
    init(entry: DictionaryEntry, onUpdate: @escaping (DictionaryEntry) -> Void) {
        self.entry = entry
        self.onUpdate = onUpdate
        _incorrectWord = State(initialValue: entry.incorrectWord)
        _correctWord = State(initialValue: entry.correctWord)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Dictionary Entry")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Word as Spoken")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g., gonna", text: $incorrectWord)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Correct Word")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g., going to", text: $correctWord)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    var updated = entry
                    updated.incorrectWord = incorrectWord
                    updated.correctWord = correctWord
                    onUpdate(updated)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(incorrectWord.isEmpty || correctWord.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
