import SwiftUI

struct AdditionalSettingsPopup: View {
    @Binding var isTranscriptVisible: Bool
    @Binding var isHoldToTalk: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $isTranscriptVisible) {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 16))
                        .foregroundColor(isTranscriptVisible ? ColorConstants.toggleActiveColor : ColorConstants.buttonContent)
                    
                    Text("Transcript")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ColorConstants.buttonContent)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: ColorConstants.toggleActiveColor))
            
            Divider()
            
            Toggle(isOn: $isHoldToTalk) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 16))
                        .foregroundColor(isHoldToTalk ? ColorConstants.toggleActiveColor : ColorConstants.buttonContent)
                    
                    Text("Hold to Talk")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ColorConstants.buttonContent)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: ColorConstants.toggleActiveColor))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: ColorConstants.buttonShadow, radius: 10, x: 0, y: 5)
        )
        // This is a self-contained component that doesn't position itself
        // Positioning will be handled by the parent view
    }
}
