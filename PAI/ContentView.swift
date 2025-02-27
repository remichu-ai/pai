import LiveKit
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var room: Room
    private var transcriptionDelegate = TranscriptionDelegate()
    
    @State private var isVideoEnabled: Bool = false
    @State private var isAudioEnabled: Bool = false
    @AppStorage("serverUrl") private var serverUrl: String = ""
    @EnvironmentObject private var tokenService: TokenService

    @State private var showingSettings: Bool = false
    @State private var showingToolSettings: Bool = false
    @State private var showingMissingUrlAlert: Bool = false
    @State private var isTranscriptVisible: Bool = false
    @EnvironmentObject var sessionConfigStore: SessionConfigStore
    
    @State private var isHoldToTalk: Bool = true
    @Environment(\.colorScheme) private var colorScheme

    init() {
        let delegate = TranscriptionDelegate()
        _room = StateObject(wrappedValue: Room(delegate: delegate))
        self.transcriptionDelegate = delegate
    }
    
    var body: some View {
        ZStack {
            // Adaptive background color based on color scheme
            (colorScheme == .dark ? Color.black : Color(UIColor.systemBackground))
                .edgesIgnoringSafeArea(.all) // Ensure background extends to edges
            
            // Different layout based on connection state
            if room.connectionState == .connected {
                // CONNECTED MODE - Controls at bottom
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Spacer()
                        if isVideoEnabled {
                            MiniStatusView()
                        }
                        
                        Button(action: { showingToolSettings.toggle() }) {
                            Image(systemName: "wrench")
                                .font(.system(size: 20))
                                .foregroundColor(Color("ButtonColor"))
                                .frame(width: 44, height: 44)
                                .background(Color("ButtonBackgroundColor"))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 8)
                        
                        Button(action: { showingSettings.toggle() }) {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .foregroundColor(Color("ButtonColor"))
                                .frame(width: 44, height: 44)
                                .background(Color("ButtonBackgroundColor"))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    
                    // Main content
                    Spacer() // Push content to top
                    
                    if isVideoEnabled {
                        LocalParticipantView()
                            .aspectRatio(3 / 4, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    } else {
                        StatusView()
                            .frame(height: 256)
                            .frame(maxWidth: 512)
                    }
                    
                    if isTranscriptVisible {
                        TranscriptionView(delegate: transcriptionDelegate)
                    }
                    
                    Spacer() // Push controls to bottom
                    
                    // Controls at bottom with added padding
                    ControlBar(
                        onStartConversation: startConversation,
                        isAudioEnabled: $isAudioEnabled,
                        isVideoEnabled: $isVideoEnabled,
                        isTranscriptVisible: $isTranscriptVisible,
                        isHoldToTalk: $isHoldToTalk
                    )
                    .padding(.bottom, 16) // Extra bottom padding in connected mode
                }
                .padding(.horizontal)
            } else {
                // DISCONNECTED MODE - Controls positioned centrally like before
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Spacer()
                        Button(action: { showingSettings.toggle() }) {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .foregroundColor(Color("ButtonColor"))
                                .frame(width: 44, height: 44)
                                .background(Color("ButtonBackgroundColor"))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    
                    // Center content vertically
                    Spacer()
                    
                    // Status view in center
                    if isVideoEnabled {
                        LocalParticipantView()
                            .aspectRatio(3 / 4, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    } else {
                        StatusView()
                            .frame(height: 256)
                            .frame(maxWidth: 512)
                    }
                    
                    Spacer()
                    
                    // Controls in center-bottom
                    VStack(spacing: 30) {
                        ControlBar(
                            onStartConversation: startConversation,
                            isAudioEnabled: $isAudioEnabled,
                            isVideoEnabled: $isVideoEnabled,
                            isTranscriptVisible: $isTranscriptVisible,
                            isHoldToTalk: $isHoldToTalk
                        )
                        
                        HoldToTalkView(isHoldToTalk: $isHoldToTalk)
                            .padding(.top, 20)
                    }
                    
                    // Space below controls - adjust this value to lift controls higher
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .environmentObject(room)
        .onAppear {
            // Any additional onAppear logic
        }
        .onChange(of: isHoldToTalk) { newValue in
            sessionConfigStore.sessionConfig.turnDetection.createResponse = newValue
            sendSessionConfigToBackend(sessionConfigStore.sessionConfig, room: room)
        }
        .sheet(isPresented: $showingSettings) {
            SettingView(
                serverUrl: $serverUrl,
                sessionConfig: $sessionConfigStore.sessionConfig
            )
            .onDisappear {
                sendSessionConfigToBackend(sessionConfigStore.sessionConfig, room: room)
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
        // Your existing function implementation
        if serverUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showingMissingUrlAlert = true
            return
        }
        
        Task {
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
                    // start audio live stream if Hold-to-Talk not selected
                    if isHoldToTalk==false {
                        try await room.localParticipant.setMicrophone(enabled: true, captureOptions: AudioCaptureOptions(
                            echoCancellation: true,
                            autoGainControl: true,
                            noiseSuppression: true,
                            highpassFilter: true
                        ))
                        isAudioEnabled=true
                    } else{
                        isAudioEnabled=false
                    }
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
        .environmentObject(SessionConfigStore())
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Room())
            .environmentObject(SessionConfigStore())
            .previewDisplayName("Default State")
        
        ContentView()
            .environmentObject(Room())
            .environmentObject(SessionConfigStore())
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        ContentView()
            .environmentObject(Room())
            .environmentObject(SessionConfigStore())
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch)"))
            .previewDisplayName("iPad Pro")
    }
}
