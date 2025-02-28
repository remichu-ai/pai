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

    // HOISTED STATE: We show this popup in an overlay at the top level
    @State private var showingAdditionalSettings: Bool = false

    init() {
        let delegate = TranscriptionDelegate()
        _room = StateObject(wrappedValue: Room(delegate: delegate))
        self.transcriptionDelegate = delegate
    }
    
    var body: some View {
        ZStack {
            // Adaptive background color based on color scheme
            (colorScheme == .dark ? Color.black : Color(UIColor.systemBackground))
                .edgesIgnoringSafeArea(.all)
            
            // Layout depends on connection state
            if room.connectionState == .connected {
                // CONNECTED MODE
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
                    
                    Spacer()
                    
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
                    
                    Spacer()
                    
                    // Controls at bottom
                    ControlBar(
                        onStartConversation: startConversation,
                        isAudioEnabled: $isAudioEnabled,
                        isVideoEnabled: $isVideoEnabled,
                        isTranscriptVisible: $isTranscriptVisible,
                        isHoldToTalk: $isHoldToTalk,
                        
                        // NEW: pass a closure to toggle the popup
                        onToggleAdditionalSettings: {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                showingAdditionalSettings.toggle()
                            }
                        }
                    )
                    .padding(.bottom, 16)
                }
                .padding(.horizontal)
            } else {
                // DISCONNECTED MODE
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
                    
                    Spacer()
                    
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
                    
                    VStack(spacing: 30) {
                        ControlBar(
                            onStartConversation: startConversation,
                            isAudioEnabled: $isAudioEnabled,
                            isVideoEnabled: $isVideoEnabled,
                            isTranscriptVisible: $isTranscriptVisible,
                            isHoldToTalk: $isHoldToTalk,
                            
                            // same closure for toggling
                            onToggleAdditionalSettings: {
                                withAnimation(.spring(
                                    response: 0.15
                                )) {
                                    showingAdditionalSettings.toggle()
                                }
                            }
                        )
                        
                        HoldToTalkView(isHoldToTalk: $isHoldToTalk)
                            .padding(.top, 20)
                    }
                    
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
        
        // TOP-LEVEL OVERLAY FOR ADDITIONAL SETTINGS
        .overlay(alignment: .bottomLeading) {
            if showingAdditionalSettings {
                AdditionalSettingsPopup(
                    isTranscriptVisible: $isTranscriptVisible,
                    isHoldToTalk: $isHoldToTalk
                )
                // Position it above the control bar:
                .padding(.leading, 16)
                .padding(.bottom, 130)
                // Adjust '120' to your preference so it sits nicely above the ControlBar
                .transition(.scale(scale: 0.9, anchor: .bottomLeading))
                .zIndex(999)
            }
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
                    if isHoldToTalk == false {
                        try await room.localParticipant.setMicrophone(enabled: true, captureOptions: AudioCaptureOptions(
                            echoCancellation: true,
                            autoGainControl: true,
                            noiseSuppression: true,
                            highpassFilter: true
                        ))
                        isAudioEnabled = true
                    } else {
                        isAudioEnabled = false
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
