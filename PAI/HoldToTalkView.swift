import SwiftUI

struct HoldToTalkView: View {
    @Binding var isHoldToTalk: Bool
    var vertical: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Text("Hold-to-Talk")
                .font(.system(size: vertical ? 18 : 14, weight: .medium))
                .foregroundColor(.white)
            
            Toggle("", isOn: $isHoldToTalk)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()
                .scaleEffect(vertical ? 1.2 : 0.8) // Smaller scale when not in vertical mode
        }
        .padding(.vertical, vertical ? 8 : 4)
        .padding(.horizontal, vertical ? 12 : 8)
    }
}
