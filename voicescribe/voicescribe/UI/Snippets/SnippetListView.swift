import SwiftUI

struct SnippetListView: View {
    @State private var snippets: [Snippet] = []
    @State private var searchText: String = ""
    @State private var showingAddSnippet: Bool = false
    @State private var editingSnippet: Snippet?
    
    private let syncService = DataSyncService.shared
    
    var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return snippets.sorted { $0.title < $1.title }
        } else {
            return snippets.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.title < $1.title }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Snippets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingAddSnippet = true }) {
                    Label("Add Snippet", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search snippets...", text: $searchText)
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
            
            // Snippets list
            if filteredSnippets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "scissors")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No snippets yet" : "No matching snippets")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text("Create shortcuts for frequently used phrases")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredSnippets) { snippet in
                        SnippetRow(snippet: snippet)
                            .contextMenu {
                                Button("Edit") {
                                    editingSnippet = snippet
                                }
                                Button("Delete", role: .destructive) {
                                    deleteSnippet(snippet)
                                }
                            }
                            .onTapGesture {
                                editingSnippet = snippet
                            }
                    }
                    .onDelete(perform: deleteSnippets)
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAddSnippet) {
            AddSnippetView { title, content in
                addSnippet(title: title, content: content)
            }
        }
        .sheet(item: $editingSnippet) { snippet in
            EditSnippetView(snippet: snippet) { updated in
                updateSnippet(updated)
            }
        }
        .onAppear {
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        Task {
            do {
                let fetchedSnippets = try await syncService.fetchSnippets()
                DispatchQueue.main.async {
                    if !fetchedSnippets.isEmpty {
                        self.snippets = fetchedSnippets
                    } else {
                        // Use sample data if no snippets found
                        self.snippets = [
                            Snippet(id: UUID(), title: "Email Signature", content: "Best regards,\nAdrian"),
                            Snippet(id: UUID(), title: "Meeting Intro", content: "Hi everyone, thanks for joining today's meeting."),
                            Snippet(id: UUID(), title: "Out of Office", content: "I'm currently out of office and will respond when I return.")
                        ]
                    }
                }
            } catch {
                print("Failed to fetch snippets: \(error)")
                // Use sample data on error
                DispatchQueue.main.async {
                    if self.snippets.isEmpty {
                        self.snippets = [
                            Snippet(id: UUID(), title: "Email Signature", content: "Best regards,\nAdrian"),
                            Snippet(id: UUID(), title: "Meeting Intro", content: "Hi everyone, thanks for joining today's meeting."),
                            Snippet(id: UUID(), title: "Out of Office", content: "I'm currently out of office and will respond when I return.")
                        ]
                    }
                }
            }
        }
    }
    
    private func addSnippet(title: String, content: String) {
        let newSnippet = Snippet(title: title, content: content)
        snippets.append(newSnippet)
        
        Task {
            do {
                try await syncService.syncSnippets(snippets)
            } catch {
                print("Failed to sync snippets: \(error)")
            }
        }
        
        showingAddSnippet = false
    }
    
    private func updateSnippet(_ updated: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == updated.id }) {
            snippets[index] = updated
            
            Task {
                do {
                    try await syncService.syncSnippets(snippets)
                } catch {
                    print("Failed to sync snippets: \(error)")
                }
            }
        }
        editingSnippet = nil
    }
    
    private func deleteSnippet(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        
        Task {
            do {
                try await syncService.syncSnippets(snippets)
            } catch {
                print("Failed to sync snippets: \(error)")
            }
        }
    }
    
    private func deleteSnippets(at offsets: IndexSet) {
        let snippetsToDelete = offsets.map { filteredSnippets[$0] }
        snippets.removeAll { snippet in snippetsToDelete.contains { $0.id == snippet.id } }
    }
}

struct SnippetRow: View {
    let snippet: Snippet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snippet.title)
                .font(.headline)
            Text(snippet.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

struct AddSnippetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    let onAdd: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Snippet")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Snippet Title")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g., Email Signature", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $content)
                    .font(.body)
                    .frame(height: 150)
                    .border(Color(NSColor.separatorColor), width: 1)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add") {
                    onAdd(title, content)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty || content.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 350)
    }
}

struct EditSnippetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String
    @State private var content: String
    let snippet: Snippet
    let onUpdate: (Snippet) -> Void
    
    init(snippet: Snippet, onUpdate: @escaping (Snippet) -> Void) {
        self.snippet = snippet
        self.onUpdate = onUpdate
        _title = State(initialValue: snippet.title)
        _content = State(initialValue: snippet.content)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Snippet")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Snippet Title")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g., Email Signature", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $content)
                    .font(.body)
                    .frame(height: 150)
                    .border(Color(NSColor.separatorColor), width: 1)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    var updated = snippet
                    updated.title = title
                    updated.content = content
                    onUpdate(updated)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty || content.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 350)
    }
}

