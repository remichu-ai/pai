import SwiftUI

struct TranscriptToggleView: View {
    @Binding var isTranscriptVisible: Bool
    var vertical: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Text("Transcript")
                .font(.system(size: vertical ? 18 : 14, weight: .medium))
                .foregroundColor(.white)
            
            Toggle("", isOn: $isTranscriptVisible)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()
                .scaleEffect(vertical ? 1.2 : 0.8)
        }
    }
}
