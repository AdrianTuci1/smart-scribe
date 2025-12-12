import SwiftUI

// Shared design system components
struct DesignTokens {
    struct Colors {
        let backgroundColor = Color(NSColor.windowBackgroundColor)
        let primaryTextColor = Color.primary
        let secondaryTextColor = Color.secondary
        let primaryButtonBackground = Color(red: 0.27, green: 0.23, blue: 0.33) // #453B55 - Dark purple
        let primaryButtonForeground = Color.white
        let ssoButtonBorder = Color.gray.opacity(0.3)
        let activeStepColor = Color.primary // Black for active step
        let inactiveStepColor = Color.gray // Gray for inactive steps
        let errorColor = Color.red
        let successColor = Color.green
        let systemGray = Color.gray
        let systemGray5 = Color(white: 0.9) // Approximate systemGray5
        let systemGray6 = Color(white: 0.95) // Approximate systemGray6
    }
    
    struct Fonts {
        let stepLabel = Font.subheadline
        let mainTitle = Font.title
        let subtitle = Font.body
        let inputPlaceholder = Font.body
        let primaryButton = Font.headline
    }
    
    struct Spacing {
        let paddingHorizontal: CGFloat = 24
        let headerBottomMargin: CGFloat = 40
        let componentVerticalSpacing: CGFloat = 32
        let ssoGridGap: CGFloat = 16
    }
    
    let colors = Colors()
    let fonts = Fonts()
    let spacing = Spacing()
}

// Button styles matching the Flow design
enum FlowButtonType {
    case primary
    case secondary
}

struct FlowButtonStyle: ButtonStyle {
    let type: FlowButtonType
    let designTokens: DesignTokens
    let color: Color? // Override color for special cases (e.g., error buttons)
    
    init(type: FlowButtonType, designTokens: DesignTokens, color: Color? = nil) {
        self.type = type
        self.designTokens = designTokens
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(designTokens.fonts.primaryButton)
            .foregroundColor(type == .primary ? designTokens.colors.primaryButtonForeground : designTokens.colors.primaryTextColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                type == .primary 
                ? (color ?? designTokens.colors.primaryButtonBackground) 
                : designTokens.colors.backgroundColor
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(designTokens.colors.ssoButtonBorder, lineWidth: type == .primary ? 0 : 1)
            )
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}