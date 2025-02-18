
import LiveKit
import LiveKitComponents
import SwiftUI

/// The ControlBar component handles connection, disconnection, and audio controls
/// You can customize this component to fit your app's needs
struct ControlBar: View {

    // We injected these into the environment in VoiceAssistantApp.swift and ContentView.swift
    @EnvironmentObject private var tokenService: TokenService
    @EnvironmentObject private var room: Room
    
    // initialize to false and connect function will turn it on upon start
    @State private var isAudioEnabled: Bool = false
    @Binding var isVideoEnabled: Bool
    @State private var isScreenSharingEnabled: Bool = false
    
    // Private internal state
    @State private var isConnecting: Bool = false
    @State private var isDisconnecting: Bool = false


    
    // Namespace for view transitions
    @Namespace private var animation


    // These are the overall configurations for this component, based on current app state
    private enum Configuration {
        case disconnected, connected, transitioning
    }

    private var currentConfiguration: Configuration {
        if isConnecting || isDisconnecting {
            return .transitioning
        } else if room.connectionState == .disconnected {
            return .disconnected
        } else {
            return .connected
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Spacer()

            switch currentConfiguration {
            case .disconnected:
                ConnectButton(connectAction: connect)
                    .matchedGeometryEffect(id: "main-button", in: animation, properties: .position)
            case .connected:
                // When connected, show audio controls and disconnect button in segmented button-like group
                HStack(spacing: 2) {
                    Button(action: {toggleAudio(toggleMode: .toggle) }) {
                        Label {
                            Text(isAudioEnabled ? "Mute" : "Unmute")
                        } icon: {
                            Image(systemName: isAudioEnabled ? "mic" : "mic.slash")
                        }
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    LocalAudioVisualizer(track: room.localParticipant.firstAudioTrack)
                        .frame(height: 44)
                        .id(room.localParticipant.firstAudioTrack?.id ?? "no-track") // Force re-render when the track changes
                    
                    Button(action: {toggleVideo(toggleMode: .toggle) }) {
                        Label {
                            Text(isVideoEnabled ? "Stop Video" : "Start Video")
                        } icon: {
                            Image(systemName: isVideoEnabled ? "video" : "video.slash")
                        }
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { toggleScreenShare(toggleMode: .toggle) }) {
                            Label {
                                Text(isScreenSharingEnabled ? "Stop Screen Share" : "Start Screen Share")
                            } icon: {
                                Image(systemName: isScreenSharingEnabled ? "rectangle.on.rectangle" : "rectangle.on.rectangle.slash")
                            }
                            .labelStyle(.iconOnly)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                }
                .background(.primary.opacity(0.1))
                .cornerRadius(8)
                
                DisconnectButton(disconnectAction: disconnect)
                    .matchedGeometryEffect(id: "main-button", in: animation, properties: .position)
                
            case .transitioning:
                TransitionButton(isConnecting: isConnecting)
                    .matchedGeometryEffect(id: "main-button", in: animation, properties: .position)
            }

            Spacer()
        }
        .animation(.spring(duration: 0.3), value: currentConfiguration)
    }

    /// Fetches a token and connects to the LiveKit room
    /// This assumes the agent is running and is configured to automatically join new rooms
    private func connect() {
        Task {
            isConnecting = true

            // Generate a random room name to ensure a new room is created
            // In a production app, you may want a more reliable process for ensuring agent dispatch
            let roomName = "room-\(Int.random(in: 1000 ... 9999))"

            // For this demo, we'll use a random participant name as well. you may want to use user IDs in a production app
            let participantName = "user-\(Int.random(in: 1000 ... 9999))"

            do {
                // Fetch connection details from token service
                if let connectionDetails = try await tokenService.fetchConnectionDetails(
                    roomName: roomName,
                    participantName: participantName
                ) {
                    // Connect to the room and enable the microphone
                    try await room.connect(
                        url: connectionDetails.serverUrl,
                        token: connectionDetails.participantToken
                    )
                    try toggleAudio(toggleMode: .on)
                } else {
                    print("Failed to fetch connection details")
                }
                isConnecting = false
            } catch {
                print("Connection error: \(error)")
                isConnecting = false
            }
        }
    }

    /// Disconnects from the current LiveKit room
    private func disconnect() {
        Task {
            isDisconnecting = true
            await room.disconnect()
            isDisconnecting = false
            
            // Reset the flags to false
            isAudioEnabled = false
            isVideoEnabled = false
            isScreenSharingEnabled = false
            
            isDisconnecting = false
        }
    }
    
    enum ToggleMode: String {
        case on = "on"
        case off = "off"
        case toggle = "toggle"
    }
    
    private func toggleAudio(toggleMode: ToggleMode = .toggle) {
        Task {
            let captureOptions: AudioCaptureOptions = AudioCaptureOptions(
                echoCancellation: true,
                autoGainControl: true,
                noiseSuppression: true,
                highpassFilter: true
            )
            
            if (isAudioEnabled==true && toggleMode == .on) || (isAudioEnabled==false && toggleMode == .off) {
                print("audio is already in the targeted state")
                return  // exit as no need to toggle
            }
            
            let targetMode = toggleMode == .toggle ? !isAudioEnabled : (toggleMode == .on)
            print("target mode is \(targetMode)")
            // toggle audio
            try await self.room.localParticipant.setMicrophone(enabled: targetMode, captureOptions: captureOptions)
            isAudioEnabled = targetMode
            
            print("toggle audio to \(isAudioEnabled ? "unmuted" : "muted")")
        }
    }
    
    private func toggleVideo(toggleMode: ToggleMode = .toggle) {
        Task {
            let captureOptions = CameraCaptureOptions(
                position: .back,
                dimensions: .h1080_43,
                fps: 24
            )
            
            let publishOptions = VideoPublishOptions(
                name: "video_track",
                encoding: nil,
                screenShareEncoding: nil,
                simulcast: false, // Disable simulcast here
                simulcastLayers: [],
                screenShareSimulcastLayers: [],
                preferredCodec: nil,
                preferredBackupCodec: nil,
                degradationPreference: .auto,
                streamName: nil
            )
            
            // Determine the target mode based on the toggleMode
            let targetMode = toggleMode == .toggle ? !isVideoEnabled : (toggleMode == .on)
            
            // Check if the video is already in the targeted state
            if (isVideoEnabled && toggleMode == .on) || (!isVideoEnabled && toggleMode == .off) {
                print("video is already in the targeted state")
                return  // exit as no need to toggle
            }
            
            // Toggle video
            try await self.room.localParticipant.setCamera(
                enabled: targetMode,
                captureOptions: captureOptions,
                publishOptions: publishOptions
            )
            isVideoEnabled = targetMode
            
            print("toggle video to \(isVideoEnabled ? "enabled" : "disabled")")
        }
    }
    
    private func toggleScreenShare(toggleMode: ToggleMode = .toggle) {
        Task {
            // Ensure video is turned off before starting screen share
//            if isVideoEnabled {
//                try await toggleVideo(toggleMode: .off)
//            }
            
            // Determine the target mode based on the toggleMode
            let targetMode = toggleMode == .toggle ? !isScreenSharingEnabled : (toggleMode == .on)

            try await self.room.localParticipant.setScreenShare(enabled: targetMode)
            isScreenSharingEnabled = targetMode
            print("Screen sharing toggled to \(isScreenSharingEnabled ? "enabled" : "disabled")")
        }
    }
}

/// Displays real-time audio levels for the local participant
private struct LocalAudioVisualizer: View {
    var track: AudioTrack?

    @StateObject private var audioProcessor: AudioProcessor

    init(track: AudioTrack?) {
        self.track = track
        _audioProcessor = StateObject(
            wrappedValue: AudioProcessor(
                track: track,
                bandCount: 9,
                isCentered: false))
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<9, id: \.self) { index in
                Rectangle()
                    .fill(.primary)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .scaleEffect(
                        y: max(0.05, CGFloat(audioProcessor.bands[index])), anchor: .center)
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 0)
        .padding(.trailing, 8)
    }
}

/// Button shown when disconnected to start a new conversation
private struct ConnectButton: View {
    var connectAction: () -> Void

    var body: some View {
        Button(action: connectAction) {
            Text("Start a Conversation")
//                .textCase(.uppercase)
                .frame(height: 44)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Color("ButtonBackgroundColor")
//            .primary.opacity(0.1)
        )
        .foregroundStyle(.primary)
        .cornerRadius(8)
    }
}

/// Button shown when connected to end the conversation
private struct DisconnectButton: View {
    var disconnectAction: () -> Void

    var body: some View {
        Button(action: disconnectAction) {
            Label {
                Text("Disconnect")
            } icon: {
                Image(systemName: "xmark")
                    .fontWeight(.bold)
            }
            .labelStyle(.iconOnly)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            .red.opacity(0.9)
        )
        .foregroundStyle(.white)
        .cornerRadius(8)
    }
}

/// (fake) button shown during connection state transitions
private struct TransitionButton: View {
    var isConnecting: Bool

    var body: some View {
        Button(action: {}) {
            Text(isConnecting ? "Connecting…" : "Disconnecting…")
                .textCase(.uppercase)
        }
        .buttonStyle(.plain)
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background(
            .primary.opacity(0.1)
        )
        .foregroundStyle(.secondary)
        .cornerRadius(8)
        .disabled(true)
    }
}

/// Dropdown menu for selecting audio input device on macOS
private struct AudioDeviceSelector: View {
    @State private var audioDevices: [AudioDevice] = []
    @State private var selectedDevice: AudioDevice = AudioManager.shared.defaultInputDevice

    var body: some View {
        Menu {
            ForEach(audioDevices, id: \.deviceId) { device in
                Button(action: {
                    selectedDevice = device
                    AudioManager.shared.inputDevice = device
                }) {
                    HStack {
                        Text(device.name)
                        if device.deviceId == selectedDevice.deviceId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "chevron.down")
                .fontWeight(.bold)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            updateDevices()

            // Listen for audio device changes
            // Note that this listener is global so can only override it from one spot
            // In a more complex app, you may need a different approach
            AudioManager.shared.onDeviceUpdate = { manager in
                Task { @MainActor in
                    updateDevices()
                }
            }
        }.onDisappear {
            AudioManager.shared.onDeviceUpdate = nil
        }
    }

    private func updateDevices() {
        audioDevices = AudioManager.shared.inputDevices
        selectedDevice = AudioManager.shared.inputDevice
    }
}
