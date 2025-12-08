import SwiftUI

struct FreeMonthView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Get a Free Month")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape)
            }
            
            Spacer()
            
            // Main content
            VStack(spacing: 24) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.purple)
                
                Text("Refer friends and get a free month of VoiceScribe Pro")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("For each friend who signs up")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Get 1 month free for every 3 referrals")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("No limit on how many free months you can earn")
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                Button(action: {
                    shareReferralLink()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Referral Link")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .alert("Link Shared", isPresented: $showingShareConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your referral link has been copied to the clipboard.")
        }
    }
    
    private func shareReferralLink() {
        // Copy referral link to clipboard
        let referralLink = "https://voicescribe.app/referral/\(UUID().uuidString)"
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(referralLink, forType: .string)
        
        showingShareConfirmation = true
    }
}

