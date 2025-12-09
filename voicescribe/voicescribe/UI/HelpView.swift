import SwiftUI

struct HelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Text("Help & Support")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape)
            }
            
            // Help options
            VStack(alignment: .leading, spacing: 16) {
                HelpLink(
                    icon: "book.fill",
                    title: "Documentation",
                    description: "Learn how to use VoiceScribe",
                    action: { openDocumentation() }
                )
                
                HelpLink(
                    icon: "message.fill",
                    title: "Contact Support",
                    description: "Get help from our team",
                    action: { contactSupport() }
                )
                
                HelpLink(
                    icon: "keyboard.fill",
                    title: "Keyboard Shortcuts",
                    description: "View all keyboard shortcuts",
                    action: { showKeyboardShortcuts() }
                )
                
                HelpLink(
                    icon: "exclamationmark.bubble.fill",
                    title: "Report a Bug",
                    description: "Help us improve VoiceScribe",
                    action: { reportBug() }
                )
            }
            
            Spacer()
            
            // Footer
            HStack {
                Text("VoiceScribe Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Check for Updates") {
                    checkForUpdates()
                }
                .font(.caption)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func openDocumentation() {
        if let url = URL(string: "https://voicescribe.app/docs") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func contactSupport() {
        if let url = URL(string: "mailto:support@voicescribe.app") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showKeyboardShortcuts() {
        // Show keyboard shortcuts dialog
        let alert = NSAlert()
        alert.messageText = "Keyboard Shortcuts"
        alert.informativeText = """
        Push to Talk: ⌃⌥⌘R
        Hands-Free Mode: ⌃⌥⌘H
        Command Mode: ⌃⌥⌘C
        Paste Last Transcript: ⌃⌥⌘V
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func reportBug() {
        if let url = URL(string: "https://voicescribe.app/bug-report") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func checkForUpdates() {
        // Check for updates functionality
        let alert = NSAlert()
        alert.messageText = "Check for Updates"
        alert.informativeText = "You are using the latest version of VoiceScribe."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

struct HelpLink: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}


