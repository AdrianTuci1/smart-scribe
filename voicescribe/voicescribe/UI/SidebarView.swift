import SwiftUI
import Combine

// MARK: - Sidebar Content View (unified with window chrome)
struct SidebarContentView: View {
    @Binding var selection: SidebarItem
    @Binding var isSidebarCollapsed: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Space for titlebar (traffic lights + controls are in MainPopoverView)
            Color.clear.frame(height: 50)
            
            // Logo section - positioned below the titlebar
            HStack(spacing: 6) {
                // App icon/logo
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
                
                Text("Flow")
                    .font(.system(size: 18, weight: .bold))
                
                // Pro Trial badge
                Text("Pro Trial")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green)
                    .cornerRadius(10)
                
                Spacer()
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Navigation items
            VStack(spacing: 4) {
                SidebarButton(title: "Home", icon: "square.grid.2x2", item: .home, selection: $selection)
                SidebarButton(title: "Dictionary", icon: "book", item: .dictionary, selection: $selection)
                SidebarButton(title: "Snippets", icon: "scissors", item: .snippets, selection: $selection)
                SidebarButton(title: "Style", icon: "textformat", item: .style, selection: $selection)
                SidebarButton(title: "Notes", icon: "note.text", item: .notes, selection: $selection)
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Bottom section
            VStack(spacing: 4) {
                SidebarButton(title: "Invite your team", icon: "person.2", item: .invite, selection: $selection)
                SidebarButton(title: "Get a free month", icon: "gift", item: .freeMonth, selection: $selection)
                SidebarButton(title: "Settings", icon: "gearshape", item: .settings, selection: $selection)
                SidebarButton(title: "Help", icon: "questionmark.circle", item: .help, selection: $selection)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .ignoresSafeArea(.all)
    }
}

// MARK: - Collapsed Sidebar Content View
struct CollapsedSidebarContentView: View {
    @Binding var selection: SidebarItem
    @Binding var isSidebarCollapsed: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Space for titlebar (traffic lights + controls are in MainPopoverView)
            Color.clear.frame(height: 50)
            
            // Compact logo
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.purple)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            // Navigation items (icons only)
            VStack(spacing: 4) {
                CollapsedSidebarButton(icon: "square.grid.2x2", item: .home, selection: $selection)
                CollapsedSidebarButton(icon: "book", item: .dictionary, selection: $selection)
                CollapsedSidebarButton(icon: "scissors", item: .snippets, selection: $selection)
                CollapsedSidebarButton(icon: "textformat", item: .style, selection: $selection)
                CollapsedSidebarButton(icon: "note.text", item: .notes, selection: $selection)
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Bottom section (icons only)
            VStack(spacing: 4) {
                CollapsedSidebarButton(icon: "person.2", item: .invite, selection: $selection)
                CollapsedSidebarButton(icon: "gift", item: .freeMonth, selection: $selection)
                CollapsedSidebarButton(icon: "gearshape", item: .settings, selection: $selection)
                CollapsedSidebarButton(icon: "questionmark.circle", item: .help, selection: $selection)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .ignoresSafeArea(.all)
    }
}

// MARK: - Legacy Sidebar View (for backwards compatibility)
struct SidebarView: View {
    @Binding var selection: SidebarItem
    @State private var isCollapsed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top spacing for titlebar area (traffic lights + controls)
            Color.clear
                .frame(height: 52)
            
            // Logo section
            HStack(spacing: 8) {
                if !isCollapsed {
                    HStack(spacing: 6) {
                        // App icon/logo
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.purple)
                        
                        Text("Flow")
                            .font(.system(size: 18, weight: .bold))
                        
                        // Pro Trial badge
                        Text("Pro Trial")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Navigation items
            VStack(spacing: 4) {
                if !isCollapsed {
                    SidebarButton(title: "Home", icon: "square.grid.2x2", item: .home, selection: $selection)
                    SidebarButton(title: "Dictionary", icon: "book", item: .dictionary, selection: $selection)
                    SidebarButton(title: "Snippets", icon: "scissors", item: .snippets, selection: $selection)
                    SidebarButton(title: "Style", icon: "textformat", item: .style, selection: $selection)
                    SidebarButton(title: "Notes", icon: "note.text", item: .notes, selection: $selection)
                } else {
                    CollapsedSidebarButton(icon: "square.grid.2x2", item: .home, selection: $selection)
                    CollapsedSidebarButton(icon: "book", item: .dictionary, selection: $selection)
                    CollapsedSidebarButton(icon: "scissors", item: .snippets, selection: $selection)
                    CollapsedSidebarButton(icon: "textformat", item: .style, selection: $selection)
                    CollapsedSidebarButton(icon: "note.text", item: .notes, selection: $selection)
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Bottom section
            if !isCollapsed {
                VStack(spacing: 4) {
                    SidebarButton(title: "Invite your team", icon: "person.2", item: .invite, selection: $selection)
                    SidebarButton(title: "Get a free month", icon: "gift", item: .freeMonth, selection: $selection)
                    SidebarButton(title: "Settings", icon: "gearshape", item: .settings, selection: $selection)
                    SidebarButton(title: "Help", icon: "questionmark.circle", item: .help, selection: $selection)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
            }
        }
        .frame(width: isCollapsed ? 60 : 200)
        .background(Color(NSColor.windowBackgroundColor))
        .animation(.easeInOut(duration: 0.3), value: isCollapsed)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SidebarToggle"))) { notification in
            if let userInfo = notification.userInfo,
               let collapsedState = userInfo["isCollapsed"] as? Bool {
                isCollapsed = collapsedState
            }
        }
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let item: SidebarItem
    @Binding var selection: SidebarItem
    
    private var isSelected: Bool {
        selection == item
    }
    
    var body: some View {
        Button(action: { selection = item }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primary.opacity(0.08) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CollapsedSidebarButton: View {
    let icon: String
    let item: SidebarItem
    @Binding var selection: SidebarItem
    
    private var isSelected: Bool {
        selection == item
    }
    
    var body: some View {
        Button(action: { selection = item }) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.primary.opacity(0.08) : Color.clear)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SidebarItem {
    case home
    case dictionary
    case snippets
    case style
    case notes
    case invite
    case freeMonth
    case settings
    case help
}
