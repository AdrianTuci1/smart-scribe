import SwiftUI

struct MainPopoverView: View {
    @State private var selection: SidebarItem = .home
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 0) {
                SidebarView(selection: $selection)
                
                Divider()
                
                Group {
                    switch selection {
                    case .home:
                        HomeView()
                    case .dictionary:
                        DictionaryView()
                    case .snippets:
                        SnippetListView()
                    case .style:
                        StyleView()
                    case .notes:
                        NotesView()
                    case .invite:
                        InviteTeamView()
                    case .freeMonth:
                        FreeMonthView()
                    case .settings:
                        SettingsView()
                    case .help:
                        HelpView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(minWidth: 800, minHeight: 600)
            
            // User menu in the top right corner
            UserMenuView()
        }
    }
}

// Placeholder views for menu items without full implementation
struct InviteTeamView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            Text("Invite Your Team")
                .font(.title)
                .fontWeight(.bold)
            Text("Share VoiceScribe with your team members")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Send Invitations") {
                // TODO: Implement invite functionality
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FreeMonthView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift.fill")
                .font(.system(size: 64))
                .foregroundColor(.purple)
            Text("Get a Free Month")
                .font(.title)
                .fontWeight(.bold)
            Text("Refer friends and get a free month of VoiceScribe Pro")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Share Referral Link") {
                // TODO: Implement referral functionality
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Help & Support")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                HelpLink(
                    icon: "book.fill",
                    title: "Documentation",
                    description: "Learn how to use VoiceScribe",
                    action: { /* TODO */ }
                )
                
                HelpLink(
                    icon: "message.fill",
                    title: "Contact Support",
                    description: "Get help from our team",
                    action: { /* TODO */ }
                )
                
                HelpLink(
                    icon: "keyboard.fill",
                    title: "Keyboard Shortcuts",
                    description: "View all keyboard shortcuts",
                    action: { /* TODO */ }
                )
                
                HelpLink(
                    icon: "exclamationmark.bubble.fill",
                    title: "Report a Bug",
                    description: "Help us improve VoiceScribe",
                    action: { /* TODO */ }
                )
            }
            
            Spacer()
        }
        .padding(32)
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

