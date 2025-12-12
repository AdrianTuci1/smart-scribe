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
            
            // User avatar with menu
            Menu {
                // Profile Section
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.accentColor.gradient)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(getInitials())
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.userName ?? "User")
                                .font(.headline) // Using headline font for name
                                .foregroundColor(.primary) // Using label color
                            
                            if let email = authService.userEmail {
                                Text(email)
                                    .font(.subheadline) // Using subheadline font for email
                                    .foregroundColor(.secondary) // Using secondaryLabel color
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
                    // Pro Trial Button
                    Button(action: {
                        settingsCategory = .plansBilling
                        showingSettings = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.white)
                            
                            Text("Go Pro")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#C29EFF")) // Pro Trial Button Background
                        .cornerRadius(8) // Border radius for Pro Trial button
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                }
                
                Divider()
                    .padding(.vertical, 8)
                    .background(designTokens.colors.systemGray5)
                
                // Referral Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Get a free month of Flow Pro")
                            .font(.headline) // Using headline font for referral title
                            .foregroundColor(.primary)
                        
                        Text("Refer friends, earn rewards")
                            .font(.subheadline) // Using subheadline font for referral subtitle
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            // Open referral share sheet
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text("Refer a friend")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(designTokens.colors.systemGray) // Light gray button background
                            .cornerRadius(8) // Border radius for referral button
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                
                Divider()
                    .padding(.vertical, 8)
                    .background(designTokens.colors.systemGray5)
                
                // Download Section
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "phone")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Download Flow for iOS")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Scan QR code with your phone")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // QR Code Placeholder
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "qrcode")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        // Open iOS download link
                        if let url = URL(string: "https://apps.apple.com/app/flow-ai-transcription/id123456789") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                    .background(designTokens.colors.systemGray5)
                
                // Settings Section
                Section {
                    Button(action: {
                        settingsCategory = .account
                        showingSettings = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            
                            Text("Manage account")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                        .padding(.horizontal, 16)
                        .background(designTokens.colors.systemGray5)
                    
                    Button(action: {
                        Task {
                            authService.signOut()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            Text("Sign Out")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } label: {
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
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .onHover { hovering in
                isHovering = hovering
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

// MARK: - Color Extensions

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
