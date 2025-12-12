//
//  HistoryView.swift
//  VoiceScribe
//
//  Created on 12.12.2025.
//

import SwiftUI

struct TranscriptionItem: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let duration: TimeInterval
    let preview: String
}

struct HistoryView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var transcriptions = [
        TranscriptionItem(
            title: "Meeting Notes",
            date: Date(),
            duration: 300,
            preview: "Discussed the quarterly results and upcoming product launches..."
        ),
        TranscriptionItem(
            title: "Personal Memo",
            date: Date().addingTimeInterval(-86400),
            duration: 120,
            preview: "Remember to pick up groceries and call mom..."
        ),
        TranscriptionItem(
            title: "Lecture Notes",
            date: Date().addingTimeInterval(-172800),
            duration: 1800,
            preview: "Today's lecture covered the principles of machine learning..."
        )
    ]
    
    var body: some View {
        NavigationView {
            List(transcriptions) { transcription in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(transcription.title)
                            .font(.headline)
                        Spacer()
                        Text(formatDuration(transcription.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(formatDate(transcription.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(transcription.preview)
                        .font(.body)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        appCoordinator.navigateTo(.home)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppCoordinator())
}