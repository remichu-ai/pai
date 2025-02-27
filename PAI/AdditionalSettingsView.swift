import SwiftUI

struct AdditionalSettingsView: View {
    @Binding var isTranscriptVisible: Bool
    @Binding var isHoldToTalk: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Additional Settings")) {
                    Toggle(isOn: $isTranscriptVisible) {
                        Label("Transcript", systemImage: isTranscriptVisible ? "text.bubble.fill" : "text.bubble")
                    }
                    Toggle(isOn: $isHoldToTalk) {
                        Label("Hold to Talk", systemImage: isHoldToTalk ? "hand.tap.fill" : "hand.tap")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Dismiss the view – when used as a sheet this button will close it.
                        // Depending on your implementation you might rely on the .sheet binding to dismiss.
                        // For example, in iOS 15+ you might use the dismiss environment.
                    }
                }
            }
        }
    }
}
