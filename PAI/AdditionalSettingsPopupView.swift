import SwiftUI
import LiveKit

struct AdditionalSettingsPopup: View {
    var room: Room
    @Binding var isTranscriptVisible: Bool
    @Binding var isHandsFree: Bool
    @Binding var isRecording: Bool    // <<-- Binding for recording state
    @EnvironmentObject var sessionConfigStore: SessionConfigStore
    
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
            
            Toggle(isOn: Binding(
                get: { isHandsFree },
                set: { newValue in
                    isHandsFree = newValue
                    sessionConfigStore.sessionConfig.turnDetection.createResponse = newValue
                    // If switching to non-hands-free mode, reset recording (stop recording)
                    if !newValue {
                        isRecording = false
                    }
                    
                    // Send updated config to backend
                    sendSessionConfigToBackend(sessionConfigStore.sessionConfig, room: room)
                }
            )) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.slash")
                        .font(.system(size: 16))
                        .foregroundColor(isHandsFree ? ColorConstants.toggleActiveColor : ColorConstants.buttonContent)
                    
                    Text("Hands-free")
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
                .fill(Color(UIColor.systemBackground))
                .shadow(color: ColorConstants.buttonShadow, radius: 10, x: 0, y: 5)
        )
        .onAppear {
            // Initialize the hands-free state from the session config when the view appears
            isHandsFree = sessionConfigStore.sessionConfig.turnDetection.createResponse
        }
    }
}

//// Preview provider for SwiftUI Canvas
//struct AdditionalSettingsPopup_Previews: PreviewProvider {
//    static var previews: some View {
//        AdditionalSettingsPopup(
//            room: Room,
//            isTranscriptVisible: .constant(true),
//            isHandsFree: .constant(true),
//            isRecording: .constant(false)
//        )
//        .environmentObject(SessionConfigStore())
//        .environmentObject(Room())
//        .previewLayout(.sizeThatFits)
//        .padding()
//        .preferredColorScheme(.light)
//        
//        AdditionalSettingsPopup(
//            isTranscriptVisible: .constant(true),
//            isHandsFree: .constant(false),
//            isRecording: .constant(false)
//        )
//        .environmentObject(SessionConfigStore())
//        .environmentObject(Room())
//        .previewLayout(.sizeThatFits)
//        .padding()
//        .preferredColorScheme(.dark)
//    }
//}
