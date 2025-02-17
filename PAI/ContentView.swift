import LiveKit
import SwiftUI
import UIKit


struct ContentView: View {
    @StateObject private var room = Room()
    @State private var isVideoEnabled: Bool = false
//    @State private var videoTrack: LocalVideoTrack?
//    @State private var audioTrack: LocalAudioTrack?
//    @State private var videoPublication: LocalTrackPublication?
//    @State private var audioPublication: LocalTrackPublication?
    @State private var serverUrl: String = "http://100.123.119.59:7880"
    @State private var showingSettings: Bool = false
    @EnvironmentObject var sessionConfigStore: SessionConfigStore
    
    init() { }
    
    var body: some View {
        VStack(spacing: 0) { // Use VStack as the main container
            // Top bar with settings button
            HStack {
                Spacer() // Push the button to the right
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(Color("ButtonColor"))
                        .frame(width: 44, height: 44)
                        .background(Color("ButtonBackgroundColor"))
                        .clipShape(Circle())
                }
                .padding([.top, .trailing], 16)
            }
            .frame(maxWidth: .infinity) // Ensure the HStack takes full width
            
            // Main content
            VStack(spacing: 24) {
                // Display the local participant's camera feed if video is enabled
                if isVideoEnabled {
                    LocalParticipantView()
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                }
                
                StatusView()
                    .frame(height: 256)
                    .frame(maxWidth: 512)
                
                ControlBar(
                    isVideoEnabled: $isVideoEnabled
                )
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Expand to fill remaining space
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the entire view fills the screen
        .environmentObject(room)
        .onAppear {
        }
        .sheet(isPresented: $showingSettings) {
            SettingView(
                serverUrl: $serverUrl,
                sessionConfig: $sessionConfigStore.sessionConfig
            )
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Room())
        .environmentObject(SessionConfigStore()) // Add this line
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Default state
        ContentView()
            .environmentObject(Room())
            .environmentObject(SessionConfigStore()) // Add this line
            .previewDisplayName("Default State")
        
        // Dark mode preview
        ContentView()
            .environmentObject(Room())
            .environmentObject(SessionConfigStore()) // Add this line
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        // iPad Pro preview
        ContentView()
            .environmentObject(Room())
            .environmentObject(SessionConfigStore()) // Add this line
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch)"))
            .previewDisplayName("iPad Pro")
    }
}
