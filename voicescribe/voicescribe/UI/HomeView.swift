import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Welcome Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Welcome back, Tucicovenco")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    HStack(spacing: 16) {
                        Label("0 week", systemImage: "flame")
                            .foregroundColor(.orange)
                        Label("41 words", systemImage: "pencil")
                            .foregroundColor(.red)
                        Label("109 WPM", systemImage: "speedometer")
                            .foregroundColor(.yellow)
                    }
                    .font(.caption)
                }
            }
            
            // Make Flow sound like you Card
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make Flow sound like ")
                        .font(.title)
                        .fontWeight(.medium)
                    + Text("you")
                        .font(.title)
                        .fontWeight(.medium)
                        .italic()
                    
                    Text("Flow adapts to how you write in different apps. Personalize your style for messages, work chats, emails, and other apps so every word sounds like you.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Start now") {
                        // Action
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
            }
            .background(Color(red: 1.0, green: 0.95, blue: 0.85))
            .cornerRadius(12)
            
            // TODAY Section
            Text("TODAY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                TranscriptRow(time: "04:50 AM", text: "Dasimina.")
                TranscriptRow(time: "04:50 AM", text: "You")
                TranscriptRow(time: "04:49 AM", text: "I want to pick up a few things from the store:")
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Bread for sandwiches")
                    Text("• Potato chips")
                    Text("• Vanilla ice cream")
                }
                .font(.body)
                .foregroundColor(.primary)
                .padding(.leading, 80)
                
                TranscriptRow(time: "04:48 AM", text: "Hi Greg,")
            }
            
            Spacer()
        }
        .padding(32)
    }
}

struct TranscriptRow: View {
    let time: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            
            Text(text)
                .font(.body)
        }
    }
}
