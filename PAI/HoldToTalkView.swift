import SwiftUI

struct HoldToTalkView: View {
    @Binding var isHoldToTalk: Bool
    var showLabel: Bool = true
    
    var body: some View {
        HStack(spacing: 10) {
            if showLabel {
                // Version with label - for ContentView
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: isHoldToTalk ? "hand.tap.fill" : "hand.tap")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isHoldToTalk ? ColorConstants.toggleActiveColor : ColorConstants.toggleInactiveColor)
                        
                        Text("Hold-to-Talk")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ColorConstants.buttonContent)
                    }
                }
            } else {
                // Simple icon-only version - for ControlBar
                Image(systemName: isHoldToTalk ? "hand.tap.fill" : "hand.tap")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isHoldToTalk ? ColorConstants.toggleActiveColor : ColorConstants.toggleInactiveColor)
            }
            
            Toggle("", isOn: $isHoldToTalk)
                .toggleStyle(SwitchToggleStyle(tint: ColorConstants.toggleActiveColor))
                .labelsHidden()
                .scaleEffect(0.9)
        }
        .padding(.vertical, showLabel ? 8 : 4)
        .padding(.horizontal, showLabel ? 12 : 8)
        .background(showLabel ? ColorConstants.buttonBackground : Color.clear)
        .cornerRadius(16)
        // Reduced shadow opacity for less contrast
        .shadow(color: showLabel ? ColorConstants.buttonShadow.opacity(0.25) : Color.clear, radius: 2, x: 0, y: 1)
    }
}

// Add ColorConstants for reference
extension HoldToTalkView {
    struct ColorConstants {
        static let buttonBackground = Color(red: 0.94, green: 0.95, blue: 0.97) // F0F3F6
        static let buttonContent = Color(red: 0.41, green: 0.47, blue: 0.54) // #69778A
        static let buttonShadow = Color(red: 0.82, green: 0.85, blue: 0.88).opacity(0.5) // D0D8E0
        static let toggleActiveColor = Color.blue
        static let toggleInactiveColor = Color(red: 0.41, green: 0.47, blue: 0.54) // #69778A
    }
}
