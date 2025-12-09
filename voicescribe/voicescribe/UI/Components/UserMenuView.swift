import SwiftUI

struct UserMenuView: View {
    @StateObject private var authService = AuthService.shared
    @State private var isMenuOpen = false
    @State private var showingSettings = false
    @State private var settingsCategory: SettingsCategory = .account
    
    var body: some View {
        HStack(spacing: 14) {
            // Notification bell
            Button(action: {
                // Notification action
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    // Notification badge
                    Circle()
                        .fill(Color.red)
                        .frame(width: 9, height: 9)
                        .offset(x: 3, y: -2)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 36, height: 36)
            
            // User avatar with menu
            Menu {
                // User info header
                Section {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(getInitials())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(authService.userName ?? "User")
                                .font(.headline)
                            Text(authService.userEmail ?? "user@example.com")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                Button(action: {
                    settingsCategory = .account
                    showingSettings = true
                }) {
                    Label("Manage Account", systemImage: "person.circle")
                }
                
                Divider()
                
                Button(action: {
                    Task {
                        await authService.signOut()
                    }
                }) {
                    Label("Sign Out", systemImage: "arrow.right.square")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .offset(x: -10) // open slightly more toward the window interior
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
