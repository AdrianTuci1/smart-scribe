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
            Text("Create shortcuts for frequently used phrases")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.top, 24)
                .padding(.bottom, 32)
            
            // Search input field
            HStack(spacing: 16) {
                TextField("", text: $searchText, prompt: Text("Search snippets...").foregroundColor(.secondary))
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
                Button(action: { showingAddSnippet = true }) {
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
            
            // Snippets section
            VStack(alignment: .leading, spacing: 16) {
                // Snippets header with icons
                HStack {
                    Text("SNIPPETS")
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
                        
                        Button(action: { loadSnippets() }) {
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
                
                // Snippets list or empty state
                if filteredSnippets.isEmpty {
                    VStack(spacing: 16) {
                        Text(searchText.isEmpty ? "No snippets yet" : "No matching snippets")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 48)
                        if searchText.isEmpty {
                            Text("Create shortcuts for frequently used phrases")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(filteredSnippets) { snippet in
                                SnippetRecentRow(snippet: snippet)
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
            loadSnippets()
        }
    }
    
    private func loadSnippets() {
        Task {
            do {
                let fetchedSnippets = try await syncService.fetchSnippets()
                DispatchQueue.main.async {
                    self.snippets = fetchedSnippets
                }
            } catch {
                print("Failed to fetch snippets: \(error)")
                DispatchQueue.main.async {
                    self.snippets = []
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

struct SnippetRecentRow: View {
    let snippet: Snippet
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(snippet.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(snippet.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
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

