import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Top spacing for titlebar area
            Color.clear
                .frame(height: 52)
            
            // Welcome Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Welcome back, Tucicovenco")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    HStack(spacing: 16) {
                        Label("1 week", systemImage: "flame.fill")
                            .foregroundColor(.orange)
                        Label("403 words", systemImage: "pencil")
                            .foregroundColor(.red)
                        Label("43 WPM", systemImage: "hand.thumbsup.fill")
                            .foregroundColor(.yellow)
                    }
                    .font(.caption)
                }
            }
            
            // Feature promotion card
            VStack(alignment: .leading, spacing: 12) {
                Text("Tag @files and `variables` hands free")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 0) {
                    Text("\"Can you refactor helloWorld.js?\" — ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Flow automatically tags the right files and variables in Cursor and Windsurf, no hands required!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Button("Try it now") {
                    // Action
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .controlSize(.regular)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 1.0, green: 0.98, blue: 0.88)) // Light yellow
            .cornerRadius(12)
            
            // YESTERDAY Section
            Text("YESTERDAY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                TranscriptRow(time: "12:39 AM", text: "adrian.tucicovenco@gmail.com")
                
                TranscriptRow(time: "12:38 AM", text: "Suntem încântați de mesajul tău.")
                TranscriptRow(time: "", text: "Ămmm, avem disponibilitate pentru patru camere în perioada 14-28 decembrie.")
                TranscriptRow(time: "", text: "Ăăă, prețul este două sute cincizeci de lei pe noapte.")
                TranscriptRow(time: "", text: "Ăă, email: signature.")
                
                TranscriptRow(time: "12:35 AM", text: "La Vibe Coding avem Variable Recognition, pentru a recunoaște variabilele, și File Tagging în Chat, pentru a tăbui fișiere automat în chat.")
                TranscriptRow(time: "", text: "La Experimental avem Command Mode - Enable Advanced Voice Commands.")
                TranscriptRow(time: "", text: "La Account, avem first name, last name, email, profile picture și butoane pentru Sign out și Delete account.")
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct TranscriptRow: View {
    let time: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(time)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
                .opacity(time.isEmpty ? 0 : 1)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
}
