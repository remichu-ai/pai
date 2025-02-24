import SwiftUI

struct HoldToTalkView: View {
    @Binding var isHoldToTalk: Bool
    var vertical: Bool = false

    var body: some View {
        if vertical {
            VStack(spacing: 4) {
                Text("Hold-to-Talk")
                    .font(.caption)
                Toggle("", isOn: $isHoldToTalk)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle())
            }
        } else {
            HStack(spacing: 4) {
                Text("Hold-to-Talk")
                    .font(.system(size: 16))
                    .padding(.trailing, 6)
                Toggle("", isOn: $isHoldToTalk)
                    .toggleStyle(SwitchToggleStyle())
                    .labelsHidden()
            }
            .padding(.top, 16)
        }
    }
}
