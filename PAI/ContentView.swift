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
    
    // New state for hand-free mode (default on)
    @State private var isHoldToTalk: Bool = true

    init() {
        let delegate = TranscriptionDelegate()
        _room = StateObject(wrappedValue: Room(delegate: delegate))
        self.transcriptionDelegate = delegate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with only settings (removed hand-free toggle here)
            HStack {
                Spacer()
                if isVideoEnabled {
                    MiniStatusView()
                }
                
                if room.connectionState == .connected {
                    Button(action: { showingToolSettings.toggle() }) {
                        Image(systemName: "wrench")
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
                }
                .padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            
            // Main content area
            VStack(spacing: 24) {
                // Video/Status and transcript views
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
                
                if room.connectionState == .connected {
                    Spacer() // Pushes everything below to the bottom
                }

                if isTranscriptVisible {
                    TranscriptionView(delegate: transcriptionDelegate)
                }

                if room.connectionState == .connected {
                    HStack {
                        ControlBar(
                            onStartConversation: startConversation,
                            isAudioEnabled: $isAudioEnabled,
                            isVideoEnabled: $isVideoEnabled,
                            isTranscriptVisible: $isTranscriptVisible,
                            isHoldToTalk: $isHoldToTalk
                        )
                    }
                        
                } else {
                    VStack(spacing: 8) {
                        
                        ControlBar(
                            onStartConversation: startConversation,
                            isAudioEnabled: $isAudioEnabled,
                            isVideoEnabled: $isVideoEnabled,
                            isTranscriptVisible: $isTranscriptVisible,
                            isHoldToTalk: $isHoldToTalk
                        )
                        
                        HoldToTalkView(isHoldToTalk: $isHoldToTalk)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
