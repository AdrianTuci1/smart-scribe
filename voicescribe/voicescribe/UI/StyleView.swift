import SwiftUI

struct StyleView: View {
    @State private var selectedContext: MessageContext = .personalMessages
    @State private var stylePreferences: [MessageContext: WritingStyle] = [
        .personalMessages: .veryCasual,
        .workMessages: .casual,
        .email: .formal,
        .other: .casual
    ]
    
    var currentStyle: WritingStyle {
        stylePreferences[selectedContext] ?? .casual
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top spacing for titlebar area
            Color.clear
                .frame(height: 52)
            
            // Header
            Text("Style")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            // Context tabs
            HStack(spacing: 0) {
                ForEach(MessageContext.allCases, id: \.self) { context in
                    Button(action: { selectedContext = context }) {
                        Text(context.rawValue)
                            .font(.subheadline)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(selectedContext == context ? Color.accentColor.opacity(0.1) : Color.clear)
                    .overlay(
                        Rectangle()
                            .fill(selectedContext == context ? Color.accentColor : Color.clear)
                            .frame(height: 2),
                        alignment: .bottom
                    )
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.top, -1)
            
            // Info banner
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                        .foregroundColor(.blue)
                    Image(systemName: "message.fill")
                        .foregroundColor(.purple)
                        .padding(.leading, -4)
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(.green)
                        .padding(.leading, -4)
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .padding(.leading, -4)
                }
                .font(.caption)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("This style applies in personal messengers")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Available on desktop in English. iOS and more languages coming soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.yellow.opacity(0.15))
            .cornerRadius(8)
            .padding()
            
            // Style options
            HStack(alignment: .top, spacing: 16) {
                ForEach(WritingStyle.allCases, id: \.self) { style in
                    StyleOptionCard(
                        style: style,
                        isSelected: currentStyle == style,
                        onSelect: {
                            stylePreferences[selectedContext] = style
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(minWidth: 600, maxWidth: 900)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StyleOptionCard: View {
    let style: WritingStyle
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(style.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(style.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(style.example)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Avatar placeholder
                Circle()
                    .fill(avatarColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(avatarInitial)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
    }
    
    var avatarColor: Color {
        switch style {
        case .formal:
            return Color(red: 0.8, green: 0.7, blue: 0.9)
        case .casual:
            return Color(red: 0.95, green: 0.7, blue: 0.8)
        case .veryCasual:
            return Color(red: 0.5, green: 0.4, blue: 0.8)
        }
    }
    
    var avatarInitial: String {
        switch style {
        case .formal:
            return "J"
        case .casual:
            return "J"
        case .veryCasual:
            return "J"
        }
    }
}
