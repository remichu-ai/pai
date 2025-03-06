import LiveKit
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var room: Room
    private var transcriptionDelegate = TranscriptionDelegate()
    
    @State private var isVideoEnabled: Bool = false
    @State private var isAudioEnabled: Bool = false
    @State private var isRecording: Bool = false
    @AppStorage("serverUrl") private var serverUrl: String = ""
    @AppStorage("authenticationUrl") private var authenticationUrl: String = ""
    @EnvironmentObject private var tokenService: TokenService

    @State private var showingSettings: Bool = false
    @State private var showingToolSettings: Bool = false
    @State private var showingMissingUrlAlert: Bool = false
    @State private var isTranscriptVisible: Bool = false
    @EnvironmentObject var sessionConfigStore: SessionConfigStore
    
    @State private var isHandsFree: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    // HOISTED STATE: We show this popup in an overlay at the top level
    @State private var showingAdditionalSettings: Bool = false
    
    // New state for connection loading
    @State private var isConnecting: Bool = false

    init() {
        let delegate = TranscriptionDelegate()
        _room = StateObject(wrappedValue: Room(delegate: delegate))
        self.transcriptionDelegate = delegate
    }
    
    var body: some View {
        ZStack {
            // Dynamic background color based on color scheme
            ColorConstants.dynamicBackground(colorScheme)
                .edgesIgnoringSafeArea(.all)
            
            if showingAdditionalSettings {
                Color.black.opacity(0.001) // Nearly transparent - just to capture taps
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingAdditionalSettings = false
                        }
                    }
            }
            
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
                                .foregroundColor(ColorConstants.buttonContent(colorScheme))
                                .frame(width: 44, height: 44)
                                .background(ColorConstants.dynamicButtonBackground(colorScheme))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 8)
                        
                        Button(action: { showingSettings.toggle() }) {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .foregroundColor(ColorConstants.buttonContent(colorScheme))
                                .frame(width: 44, height: 44)
                                .background(ColorConstants.dynamicButtonBackground(colorScheme))
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
                    
                    // Pass down the isRecording binding here.
                    ControlBar(
                        onStartConversation: startConversation,
                        isAudioEnabled: $isAudioEnabled,
                        isVideoEnabled: $isVideoEnabled,
                        isTranscriptVisible: $isTranscriptVisible,
                        isHandsFree: $isHandsFree,
                        isRecording: $isRecording,
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
                    HStack {
                        Spacer()
                        Button(action: { showingSettings.toggle() }) {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : ColorConstants.buttonContent(colorScheme))
                                .frame(width: 44, height: 44)
                                .background(ColorConstants.dynamicButtonBackground(colorScheme))
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
                            isHandsFree: $isHandsFree,
                            isRecording: $isRecording,
                            onToggleAdditionalSettings: {
                                withAnimation(.spring(response: 0.15)) {
                                    showingAdditionalSettings.toggle()
                                }
                            }
                        )
                        
                        HandsFreeView(isHandsFree: $isHandsFree)
                            .padding(.top, 20)
                    }
                    
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal)
                .disabled(isConnecting) // Disable UI during connection
            }
            
            // Loading overlay that appears during connection in non-hands-free mode
            if isConnecting {
                ZStack {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Initializing connection...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color(.systemGray6).opacity(0.7))
                    .cornerRadius(12)
                }
                .transition(.opacity)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .environmentObject(room)
        .onAppear {
            isHandsFree = sessionConfigStore.sessionConfig.turnDetection.createResponse
        }
        .onChange(of: isHandsFree) { newValue in
            // When hands-free changes, update the session config.
            // (Any additional logic to stop recording should already occur via the popup below.)
            sessionConfigStore.sessionConfig.turnDetection.createResponse = newValue
            
            // Turn on microphone if the room is connected.
            if room.connectionState == .connected {
                Task {
                    let captureOptions = AudioCaptureOptions(
                        echoCancellation: true,
                        autoGainControl: true,
                        noiseSuppression: true,
                        highpassFilter: true
                    )
                    // When hands-free is turned on, enable the mic (and vice versa).
                    try await room.localParticipant.setMicrophone(enabled: newValue, captureOptions: captureOptions)
                    isAudioEnabled = newValue
                    isRecording = newValue
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingView(
                serverUrl: $serverUrl,
                authenticationUrl: $authenticationUrl,
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
                    room: room,
                    isTranscriptVisible: $isTranscriptVisible,
                    isHandsFree: $isHandsFree,
                    isRecording: $isRecording    // <<-- Pass the binding so we can reset it when needed
                )
                .padding(.leading, 16)
                .padding(.bottom, 130)
                .transition(.scale(scale: 0.9, anchor: .bottomLeading))
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isConnecting)
    }
    
    // startConversation function remains the same
    private func startConversation() {
        // Existing implementation
        if serverUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showingMissingUrlAlert = true
            return
        }
        
        Task {
            let roomName = "room-\(Int.random(in: 1000 ... 9999))"
            let participantName = "user-\(Int.random(in: 1000 ... 9999))"
            
            do {
                // Set connecting state to true and show loading overlay
                await MainActor.run {
                    isConnecting = true
                }
                
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
                    
                    // Get the audio capture options
                    let captureOptions = AudioCaptureOptions(
                        echoCancellation: true,
                        autoGainControl: true,
                        noiseSuppression: true,
                        highpassFilter: true
                    )
                    
                    // In both modes, always start the microphone initially
                    try await room.localParticipant.setMicrophone(enabled: true, captureOptions: captureOptions)
                    await MainActor.run {
                        isAudioEnabled = true
                    }
                    
                    // If not in hands-free mode, we need to disable the microphone after 1 second
                    if !isHandsFree {
                        // Wait for 0.2 second
                        try await Task.sleep(nanoseconds: 200_000_000)
                        
                        // Then disable the microphone
                        try await room.localParticipant.setMicrophone(enabled: false)
                        await MainActor.run {
                            isAudioEnabled = false
                        }
                    }
                    
                    // disable tool as the tools stored in state might not be what is available this round
                    await MainActor.run {
                        sessionConfigStore.sessionConfig.tools = []
                    }
                    
                    sendSessionConfigToBackend(sessionConfigStore.sessionConfig, room: room)
                    
                } else {
                    print("Failed to fetch connection details")
                }
                
                // Finally, regardless of the outcome, update the UI state
                await MainActor.run {
                    isConnecting = false
                }
                
            } catch {
                print("Connection error: \(error)")
                await MainActor.run {
                    isConnecting = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Room())
        .environmentObject(SessionConfigStore())
}


// New HandsFreeView to replace HoldToTalkView
struct HandsFreeView: View {
    @Binding var isHandsFree: Bool
    @Environment(\.colorScheme) private var colorScheme
    var showLabel: Bool = true
    
    var body: some View {
        HStack(spacing: 10) {
            if showLabel {
                // Version with label - for ContentView
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: isHandsFree ? "hand.raised.slash.fill" : "hand.raised.slash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isHandsFree ? ColorConstants.toggleActiveColor : ColorConstants.toggleInactiveColor(for: colorScheme))
                        
                        Text("Hands-free")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : ColorConstants.buttonContent(colorScheme))
                    }
                }
            } else {
                // Simple icon-only version - for ControlBar
                Image(systemName: isHandsFree ? "hand.raised.slash.fill" : "hand.raised.slash")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isHandsFree ? ColorConstants.toggleActiveColor : ColorConstants.toggleInactiveColor(for: colorScheme))
            }
        
            
            Toggle("", isOn: $isHandsFree)
                .toggleStyle(SwitchToggleStyle(tint: ColorConstants.toggleActiveColor))
                .labelsHidden()
                .scaleEffect(0.9)
        }
        .padding(.vertical, showLabel ? 8 : 4)
        .padding(.horizontal, showLabel ? 12 : 8)
        .background(showLabel ? ColorConstants.dynamicButtonBackground(colorScheme) : Color.clear)
        .cornerRadius(16)
        // Reduced shadow opacity for dark mode
        .shadow(
            color: showLabel ? ColorConstants.buttonShadow(colorScheme) : Color.clear,
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(Room())
        .environmentObject(SessionConfigStore())
}
