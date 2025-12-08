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
            HStack {
                Text("Dictionary")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingAddEntry = true }) {
                    Label("Add Entry", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search corrections...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom)
            
            // Entries list
            if filteredEntries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No dictionary entries yet" : "No matching entries")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text("Add corrections to help improve transcription accuracy")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        DictionaryEntryRow(entry: entry)
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
                    .onDelete(perform: deleteEntries)
                }
                .listStyle(.inset)
            }
        }
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

struct DictionaryEntryRow: View {
    let entry: DictionaryEntry
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.incorrectWord)
                    .font(.body)
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
                    .foregroundColor(.primary)
                Text("Corrected text")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
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
