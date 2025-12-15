import SwiftUI

struct UserMenuView: View {
    @StateObject private var authService = AuthService.shared
    @State private var isMenuOpen = false
    @State private var showingSettings = false
    @State private var settingsCategory: SettingsCategory = .account
    @State private var isHovering = false
    
    // Design tokens
    private let designTokens = DesignTokens()
    
    var body: some View {
        HStack(spacing: 8) {
            // Notification bell
            Button(action: {
                // Notification action
            }) {
                Image(systemName: "bell")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // User avatar with popover
            Button(action: {
                isMenuOpen.toggle()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    if let userName = authService.userName, !userName.isEmpty {
                        Text(getInitials())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .scaleEffect(isHovering ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isHovering = hovering
            }
            .popover(isPresented: $isMenuOpen, arrowEdge: .bottom) {
                UserMenuContent(
                    authService: authService,
                    onOpenSettings: { category in
                        settingsCategory = category
                        showingSettings = true
                        isMenuOpen = false
                    },
                    onSignOut: {
                        authService.signOut()
                        isMenuOpen = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings, initialCategory: settingsCategory)
        }
    }
    
    private func getInitials() -> String {
        guard let name = authService.userName, !name.isEmpty else {
            return "U"
        }
        
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components.first?.first ?? Character("U"))\(components.last?.first ?? Character(""))"
        } else {
            return String(name.prefix(1)).uppercased()
        }
    }
}

struct UserMenuContent: View {
    @ObservedObject var authService: AuthService
    var onOpenSettings: (SettingsCategory) -> Void
    var onSignOut: () -> Void
    private let designTokens = DesignTokens()
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.accentColor.gradient)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(getInitials())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authService.userName ?? "User")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let email = authService.userEmail {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Pro Trial Button
                Button(action: {
                    onOpenSettings(.plansBilling)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                        
                        Text("Upgrade to Pro")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#C29EFF"), Color(hex: "#9E7BFF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(8)
                    .shadow(color: Color(hex: "#9E7BFF").opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
            
            Divider()
            
            // Menu Items
            VStack(spacing: 4) {
                MenuRow(icon: "gearshape", title: "Manage account") {
                    onOpenSettings(.account)
                }
                
                MenuRow(icon: "square.and.arrow.up", title: "Refer a friend") {
                    // Refer action
                }
                
                MenuRow(icon: "phone", title: "Download Flow for iOS") {
                    if let url = URL(string: "https://apps.apple.com/app/flow-ai-transcription/id123456789") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            
            Divider()
            
            // Sign Out
            VStack(spacing: 4) {
                MenuRow(icon: "arrow.right.square", title: "Sign Out", role: .destructive) {
                    onSignOut()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
        .frame(width: 280)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func getInitials() -> String {
        guard let name = authService.userName, !name.isEmpty else { return "U" }
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components.first?.first ?? "U")\(components.last?.first ?? " ")"
        } else {
            return String(name.prefix(1)).uppercased()
        }
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    var role: ButtonRole? = nil
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(role == .destructive ? .red : .secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(role == .destructive ? .red : .primary)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(isHovering ? Color.primary.opacity(0.05) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering = $0 }
    }
}

// MARK: - Color Extensions (Preserved)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // System color definitions for macOS
    static let systemBackground = Color(NSColor.controlBackgroundColor)
    static let systemGray5 = Color(NSColor.separatorColor)
    static let systemGray3 = Color(NSColor.tertiaryLabelColor).opacity(0.5)
    static let label = Color.primary
    static let secondaryLabel = Color.secondary
}

// ManageAccountView (Preserved from original file to avoid breaking references if any)
struct ManageAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Manage Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape)
            }
            
            // User profile section
            VStack(alignment: .leading, spacing: 16) {
                Text("Profile Information")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Name:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(authService.userName ?? "Not available")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("Email:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(authService.userEmail ?? "Not available")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("User ID:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(authService.currentUser?.userId ?? "Not available")
                            .font(.subheadline)
                            .textSelection(.enabled)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Account actions
            VStack(alignment: .leading, spacing: 16) {
                Text("Account Actions")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    Button(action: {
                        // TODO: Implement change password
                    }) {
                        HStack {
                            Image(systemName: "key")
                            Text("Change Password")
                            Spacer()
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        // TODO: Implement export data
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Export My Data")
                            Spacer()
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        // TODO: Implement delete account
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Account")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}
