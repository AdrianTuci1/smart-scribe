import SwiftUI

struct InviteTeamView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email1 = ""
    @State private var email2 = ""
    @State private var email3 = ""
    @State private var showingInviteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Invite Your Team")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape)
            }
            
            // Description
            Text("Share VoiceScribe with your team members")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            // Invite form
            VStack(alignment: .leading, spacing: 16) {
                Text("Email Addresses")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    TextField("Enter email address", text: $email1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Enter email address", text: $email2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Enter email address", text: $email3)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button(action: {
                    sendInvitations()
                }) {
                    HStack {
                        Image(systemName: "paperplane")
                        Text("Send Invitations")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email1.isEmpty && email2.isEmpty && email3.isEmpty)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .alert("Invitations Sent", isPresented: $showingInviteConfirmation) {
            Button("OK") { }
        } message: {
            Text("Invitations have been sent to your team members.")
        }
    }
    
    private func sendInvitations() {
        var emails = [String]()
        if !email1.isEmpty { emails.append(email1) }
        if !email2.isEmpty { emails.append(email2) }
        if !email3.isEmpty { emails.append(email3) }
        
        print("Sending invitations to: \(emails)")
        
        email1 = ""
        email2 = ""
        email3 = ""
        
        showingInviteConfirmation = true
    }
}

