import SwiftUI

struct UserMenuView: View {
    @StateObject private var authService = AuthService.shared
    @State private var isMenuOpen = false
    @State private var showingManageAccount = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Avatar button in the top right corner
            HStack {
                Spacer()
                Button(action: {
                    isMenuOpen.toggle()
                }) {
                    // User avatar
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 32, height: 32)
                        
                        Text(getInitials())
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 16)
                .padding(.top, 8)
            }
            
            // Dropdown menu
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 12) {
                    // User info section
                    HStack(spacing: 12) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 48, height: 48)
                            
                            Text(getInitials())
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                        }
                        
                        // User details
                        VStack(alignment: .leading, spacing: 2) {
                            Text(authService.userName ?? "User")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(authService.userEmail ?? "user@example.com")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    Divider()
                    
                    // Menu items
                    VStack(spacing: 0) {
                        Button(action: {
                            showingManageAccount = true
                            isMenuOpen = false
                        }) {
                            HStack {
                                Image(systemName: "person.circle")
                                Text("Manage Account")
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.primary)
                        
                        Divider()
                        
                        Button(action: {
                            Task {
                                await authService.signOut()
                                isMenuOpen = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Sign Out")
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.primary)
                    }
                }
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
                .padding(.trailing, 16)
                .padding(.top, 4)
                .zIndex(1000)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingManageAccount) {
            ManageAccountView()
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
