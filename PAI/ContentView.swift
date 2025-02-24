import LiveKit
import SwiftUI
import UIKit


struct ContentView: View {
    @StateObject private var room: Room
    private var transcriptionDelegate = TranscriptionDelegate()
    
    @State private var isVideoEnabled: Bool = false
    // Use @AppStorage so that serverUrl persists between app launches
    // http://100.123.119.59:7880
    @AppStorage("serverUrl") private var serverUrl: String = ""
    @EnvironmentObject private var tokenService: TokenService

    @State private var showingSettings: Bool = false
    @State private var showingToolSettings: Bool = false
    // Alert to warn if the server URL is missing
    @State private var showingMissingUrlAlert: Bool = false
    @State private var isTranscriptVisible: Bool = false
    @EnvironmentObject var sessionConfigStore: SessionConfigStore
    

    init() {
        let delegate = TranscriptionDelegate()
        // Create custom screenshare options with broadcast extension enabled
//        let customScreenShareOptions = ScreenShareCaptureOptions(useBroadcastExtension: true)
//        // Create custom room options with the custom screenshare options
//        let customRoomOptions = RoomOptions(
//            defaultCameraCaptureOptions: CameraCaptureOptions(),
//            defaultScreenShareCaptureOptions: customScreenShareOptions,
//            defaultAudioCaptureOptions: AudioCaptureOptions(),
//            defaultVideoPublishOptions: VideoPublishOptions(),
//            defaultAudioPublishOptions: AudioPublishOptions(),
//            defaultDataPublishOptions: DataPublishOptions(),
//            adaptiveStream: false,
//            dynacast: false,
//            stopLocalTrackOnUnpublish: true,
//            suspendLocalVideoTracksInBackground: true,
//            e2eeOptions: nil,
//            reportRemoteTrackStatistics: false
//        )
//        
        _room = StateObject(wrappedValue: Room(delegate: delegate))
        self.transcriptionDelegate = delegate
    }
    
    
    var body: some View {
        VStack(spacing: 0) { // Use VStack as the main container
            // Top bar with settings button
            HStack {
                Spacer() // Push the button to the right
                
                if isVideoEnabled {
                    MiniStatusView()
//                        .padding(.leading, 16)
                }
                
                // tool setting button
                if room.connectionState == .connected {
                    Button(action: { showingToolSettings.toggle() }) {
                        Image(systemName: "wrench") // Using a wrench icon for tools
                            .font(.system(size: 20))
                            .foregroundColor(Color("ButtonColor"))
                            .frame(width: 44, height: 44)
                            .background(Color("ButtonBackgroundColor"))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 8)
                }
                
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(Color("ButtonColor"))
                        .frame(width: 44, height: 44)
                        .background(Color("ButtonBackgroundColor"))
                        .clipShape(Circle())
                }.padding(.trailing, 16)

            }
            .frame(maxWidth: .infinity) // Ensure the HStack takes full width
            .padding(.top, 4)     // less top padding
            .padding(.bottom, 4) // more bottom padding
            
            
            // Main content
            VStack(spacing: 24) {
                // Display the local participant's camera feed if video is enabled
                if isVideoEnabled {
                    LocalParticipantView()
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                } else {
                    
                StatusView()
                    .frame(height: 256)
                    .frame(maxWidth: 512)
                }
                
                // Conditionally display the transcript view
                if isTranscriptVisible {
                    TranscriptionView(delegate: transcriptionDelegate)
                }
                
                // Pass a callback (onStartConversation) to the control bar so that before starting
                // a conversation the serverUrl is checked.
                ControlBar(
                    onStartConversation: startConversation,
                    isVideoEnabled: $isVideoEnabled,
                    isTranscriptVisible: $isTranscriptVisible
                    
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
            .onDisappear {
                // Send the updated session config to the backend
                sendSessionConfigToBackend(
                    sessionConfigStore.sessionConfig,
                    room: room
                )
            }
        }
        .sheet(isPresented: $showingToolSettings) {
            ToolSettingView(
                room: room,
                tools: $sessionConfigStore.sessionConfig.tools
            )
        }
        .alert(isPresented: $showingMissingUrlAlert) {
            Alert(
                title: Text("Server URL Not Set"),
                message: Text("Please go to Settings and update the Server URL."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func startConversation() {
        // Check that the server URL is not empty (or not just whitespace)
        if serverUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showingMissingUrlAlert = true
            return
        }
        
        // If the URL is set, proceed with connection logic.
        // For example, you might call a connection method on your room or tokenService.
        // You can reuse your existing logic here:
        Task {
            // Generate random room and participant names (or use your own logic)
            let roomName = "room-\(Int.random(in: 1000 ... 9999))"
            let participantName = "user-\(Int.random(in: 1000 ... 9999))"
            
            do {
                if let connectionDetails = try await tokenService.fetchConnectionDetails(
                    roomName: roomName,
                    participantName: participantName
                ) {
                    try await room.connect(
                        url: connectionDetails.serverUrl,
                        token: connectionDetails.participantToken,
                        roomOptions: RoomOptions(
                            defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
                                useBroadcastExtension: true
                            )
                        )
                    )
                    try await room.localParticipant.setMicrophone(enabled: true, captureOptions: AudioCaptureOptions(
                        echoCancellation: true,
                        autoGainControl: true,
                        noiseSuppression: true,
                        highpassFilter: true
                    ))
                } else {
                    print("Failed to fetch connection details")
                }
            } catch {
                print("Connection error: \(error)")
            }
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
