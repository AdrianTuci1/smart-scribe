import SwiftUI

struct MainPopoverView: View {
    @State private var selection: SidebarItem = .home
    @State private var showingSettings = false
    @State private var showingInvite = false
    @State private var showingFreeMonth = false
    @State private var showingHelp = false
    
    var body: some View {
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
                    // Don't show anything here, will be shown as a sheet
                    HomeView()
                case .freeMonth:
                    // Don't show anything here, will be shown as a sheet
                    HomeView()
                case .settings:
                    // Don't show anything here, will be shown as a sheet
                    HomeView()
                case .help:
                    // Don't show anything here, will be shown as a sheet
                    HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings)
        }
        .sheet(isPresented: $showingInvite) {
            InviteTeamView()
        }
        .sheet(isPresented: $showingFreeMonth) {
            FreeMonthView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .onChange(of: selection) { _, newSelection in
            switch newSelection {
            case .invite:
                showingInvite = true
                selection = .home // Reset to home after triggering
            case .freeMonth:
                showingFreeMonth = true
                selection = .home // Reset to home after triggering
            case .settings:
                showingSettings = true
                selection = .home // Reset to home after triggering
            case .help:
                showingHelp = true
                selection = .home // Reset to home after triggering
            default:
                break
            }
        }
    }
}

struct MainPopoverViewWithoutUserMenu: View {
    @State private var selection: SidebarItem = .home
    @State private var showingSettings = false
    @State private var showingInvite = false
    @State private var showingFreeMonth = false
    @State private var showingHelp = false
    
    var body: some View {
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
                    // Don't show anything here, will be shown as a sheet
                    HomeView()
                case .freeMonth:
                    // Don't show anything here, will be shown as a sheet
                    HomeView()
                case .settings:
                    // Don't show anything here, will be shown as a sheet
                    HomeView()
                case .help:
                    // Don't show anything here, will be shown as a sheet
                    HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings)
        }
        .sheet(isPresented: $showingInvite) {
            InviteTeamView()
        }
        .sheet(isPresented: $showingFreeMonth) {
            FreeMonthView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .onChange(of: selection) { _, newSelection in
            switch newSelection {
            case .invite:
                showingInvite = true
                selection = .home // Reset to home after triggering
            case .freeMonth:
                showingFreeMonth = true
                selection = .home // Reset to home after triggering
            case .settings:
                showingSettings = true
                selection = .home // Reset to home after triggering
            case .help:
                showingHelp = true
                selection = .home // Reset to home after triggering
            default:
                break
            }
        }
    }
}

enum ViewType: CaseIterable {
    case home
    case dictionary
    case snippets
    case style
    case notes
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .dictionary:
            return "Dictionary"
        case .snippets:
            return "Snippets"
        case .style:
            return "Style"
        case .notes:
            return "Notes"
        }
    }
    
    var icon: String {
        switch self {
        case .home:
            return "square.grid.2x2"
        case .dictionary:
            return "book"
        case .snippets:
            return "scissors"
        case .style:
            return "textformat"
        case .notes:
            return "note.text"
        }
    }
}

