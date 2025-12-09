import SwiftUI

struct MainPopoverView: View {
    @State private var selection: SidebarItem = .home
    @State private var contentSelection: SidebarItem = .home
    @State private var showingSettings = false
    @State private var showingInvite = false
    @State private var showingFreeMonth = false
    @State private var showingHelp = false
    @State private var isSidebarCollapsed = false
    
    private let expandedSidebarWidth: CGFloat = 220
    private let collapsedSidebarWidth: CGFloat = 60
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main content layer
            HStack(spacing: 0) {
                // Sidebar
                if isSidebarCollapsed {
                    CollapsedSidebarContentView(selection: $selection, isSidebarCollapsed: $isSidebarCollapsed)
                        .frame(width: collapsedSidebarWidth)
                } else {
                    SidebarContentView(selection: $selection, isSidebarCollapsed: $isSidebarCollapsed)
                        .frame(width: expandedSidebarWidth)
                }
                
                // Content area - inset appearance
                VStack(spacing: 0) {
                    Group {
                        switch contentSelection {
                        case .home, .invite, .freeMonth, .settings, .help:
                            HomeView()
                        case .dictionary:
                            DictionaryView()
                        case .snippets:
                            SnippetListView()
                        case .style:
                            StyleView()
                        case .notes:
                            NotesView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                .padding(.top, 50) // Space for titlebar
                .padding(.trailing, 12)
                .padding(.bottom, 12)
            }
            
            // Titlebar layer - 8px down from top
            VStack {
                HStack(alignment: .center, spacing: 0) {
                    // Space for traffic lights
                    Color.clear.frame(width: 78)
                    
                    // Sidebar toggle button (larger)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSidebarCollapsed.toggle()
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Toggle Sidebar")
                    
                    Spacer()
                    
                    // User menu (far right of window)
                    UserMenuView()
                        .padding(.trailing, 16)
                }
                .frame(height: 36)
                .padding(.top, 8) // Move 8px down
                
                Spacer()
            }
        }
        .background(
            WindowAccessor { window in
                window.setTrafficLightsOffset(x: 64, y: 128)
            }
            .frame(width: 0, height: 0)
        )
        .ignoresSafeArea(.all)
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
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
                selection = contentSelection
            case .freeMonth:
                showingFreeMonth = true
                selection = contentSelection
            case .settings:
                showingSettings = true
                selection = contentSelection
            case .help:
                showingHelp = true
                selection = contentSelection
            default:
                contentSelection = newSelection
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSidebarCollapsed)
    }
}

struct MainPopoverViewWithoutUserMenu: View {
    @State private var selection: SidebarItem = .home
    @State private var contentSelection: SidebarItem = .home
    @State private var showingSettings = false
    @State private var showingInvite = false
    @State private var showingFreeMonth = false
    @State private var showingHelp = false
    @State private var isSidebarCollapsed = false
    
    private let expandedSidebarWidth: CGFloat = 220
    private let collapsedSidebarWidth: CGFloat = 60
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main content layer
            HStack(spacing: 0) {
                // Sidebar
                if isSidebarCollapsed {
                    CollapsedSidebarContentView(selection: $selection, isSidebarCollapsed: $isSidebarCollapsed)
                        .frame(width: collapsedSidebarWidth)
                } else {
                    SidebarContentView(selection: $selection, isSidebarCollapsed: $isSidebarCollapsed)
                        .frame(width: expandedSidebarWidth)
                }
                
                // Content area - inset appearance
                VStack(spacing: 0) {
                    Group {
                        switch contentSelection {
                        case .home, .invite, .freeMonth, .settings, .help:
                            HomeView()
                        case .dictionary:
                            DictionaryView()
                        case .snippets:
                            SnippetListView()
                        case .style:
                            StyleView()
                        case .notes:
                            NotesView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                .padding(.top, 50) // Space for titlebar
                .padding(.trailing, 12)
                .padding(.bottom, 12)
            }
            
            // Titlebar layer - 8px down from top
            VStack {
                HStack(alignment: .center, spacing: 0) {
                    // Space for traffic lights
                    Color.clear.frame(width: 78)
                    
                    // Sidebar toggle button (larger)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSidebarCollapsed.toggle()
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Toggle Sidebar")
                    
                    Spacer()
                    
                    // User menu (far right of window)
                    UserMenuView()
                        .padding(.trailing, 16)
                }
                .frame(height: 36)
                .padding(.top, 8) // Move 8px down
                
                Spacer()
            }
        }
        .background(
            WindowAccessor { window in
                window.setTrafficLightsVerticalOffset(8)
            }
            .frame(width: 0, height: 0)
        )
        .ignoresSafeArea(.all)
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
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
                selection = contentSelection
            case .freeMonth:
                showingFreeMonth = true
                selection = contentSelection
            case .settings:
                showingSettings = true
                selection = contentSelection
            case .help:
                showingHelp = true
                selection = contentSelection
            default:
                contentSelection = newSelection
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSidebarCollapsed)
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
        case .home: return "Home"
        case .dictionary: return "Dictionary"
        case .snippets: return "Snippets"
        case .style: return "Style"
        case .notes: return "Notes"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "square.grid.2x2"
        case .dictionary: return "book"
        case .snippets: return "scissors"
        case .style: return "textformat"
        case .notes: return "note.text"
        }
    }
}
