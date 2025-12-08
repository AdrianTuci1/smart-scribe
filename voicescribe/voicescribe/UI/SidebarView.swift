import SwiftUI
import Combine

struct SidebarView: View {
    @Binding var selection: SidebarItem
    
    var body: some View {
        List {
            Section {
                SidebarButton(title: "Home", icon: "square.grid.2x2", item: .home, selection: $selection)
                SidebarButton(title: "Dictionary", icon: "book", item: .dictionary, selection: $selection)
                SidebarButton(title: "Snippets", icon: "scissors", item: .snippets, selection: $selection)
                SidebarButton(title: "Style", icon: "textformat", item: .style, selection: $selection)
                SidebarButton(title: "Notes", icon: "note.text", item: .notes, selection: $selection)
            } header: {
                Text("Flow Pro Trial")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(4)
                    .padding(.bottom, 8)
            }
            
            Spacer()
            
            Section {
                SidebarButton(title: "Invite your team", icon: "person.2", item: .invite, selection: $selection)
                SidebarButton(title: "Get a free month", icon: "gift", item: .freeMonth, selection: $selection)
                SidebarButton(title: "Settings", icon: "gearshape", item: .settings, selection: $selection)
                SidebarButton(title: "Help", icon: "questionmark.circle", item: .help, selection: $selection)
            }
        }
        .listStyle(SidebarListStyle())
        .frame(width: 150)
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let item: SidebarItem
    @Binding var selection: SidebarItem
    
    var body: some View {
        Button(action: { selection = item }) {
            Label(title, systemImage: icon)
                .foregroundColor(selection == item ? .accentColor : .primary)
        }
        .buttonStyle(PlainButtonStyle()) // SidebarListStyle handles selection visuals mostly, but custom button gives control
        .tag(item) // Useful if we switched to NavigationLink/List selection binding
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
