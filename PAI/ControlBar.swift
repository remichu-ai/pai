
import LiveKit
import LiveKitComponents
import SwiftUI

/// The ControlBar component handles connection, disconnection, and audio controls
/// You can customize this component to fit your app's needs
struct ControlBar: View {
    @EnvironmentObject private var room: Room
    
    // Callback when the connect button is tapped.
    var onStartConversation: () -> Void
    
    @Binding var isAudioEnabled: Bool
    @Binding var isVideoEnabled: Bool
    @Binding var isTranscriptVisible: Bool
    @Binding var isHoldToTalk: Bool
    
    @State private var isScreenSharingEnabled: Bool = false
    @State private var isConnecting: Bool = false
    @State private var isDisconnecting: Bool = false

    // Updated size constants for larger, touch-friendly buttons
    let width: CGFloat = 70
    let height: CGFloat = 70
    let fontSize: CGFloat = 28

    @Namespace private var animation

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
        HStack {
            Spacer()
            switch currentConfiguration {
            case .disconnected:
                ConnectButton(connectAction: onStartConversation)
                    .matchedGeometryEffect(id: "main-button", in: animation, properties: .position)
            case .connected:
                // Use a two-row layout:
                VStack(spacing: 8) {
                    // --- First Row: Hold-to-Talk and Audio Visualizer ---
                    HStack(spacing: 8) {
                        // Moved audio visualizer here:
                        LocalAudioVisualizer(track: room.localParticipant.firstAudioTrack)
                            .frame(height: height)
                            .id(room.localParticipant.firstAudioTrack?.id ?? "no-track")
                        Spacer()
                        // Hold-to-Talk toggle
                        HoldToTalkView(isHoldToTalk: $isHoldToTalk, vertical: false)
                    }
//                    .padding(.horizontal, 50)
//                    .padding(.vertical, 4)
                    
                    // --- Second Row: Other control buttons ---
                    HStack(spacing: 12) {
                        RoundIconButton(
                                systemImageName: isAudioEnabled ? "mic" : "mic.slash",
                                action: { toggleAudio(toggleMode: .toggle) },
                                size: width,
                                fontSize: fontSize,
                                backgroundColor: isAudioEnabled ? .green : .gray,
                                foregroundColor: .white
                            )

                            RoundIconButton(
                                systemImageName: isVideoEnabled ? "video" : "video.slash",
                                action: { toggleVideo(toggleMode: .toggle) },
                                size: width,
                                fontSize: fontSize,
                                backgroundColor: isVideoEnabled ? .blue : .gray,
                                foregroundColor: .white
                            )

                            RoundIconButton(
                                systemImageName: isScreenSharingEnabled
                                    ? "rectangle.on.rectangle"
                                    : "rectangle.on.rectangle.slash",
                                action: { toggleScreenShare(toggleMode: .toggle) },
                                size: width,
                                fontSize: fontSize,
                                backgroundColor: isScreenSharingEnabled ? .blue : .gray,
                                foregroundColor: .white
                            )

                            RoundIconButton(
                                systemImageName: "doc.text",
                                action: { isTranscriptVisible.toggle() },
                                size: width,
                                fontSize: fontSize,
                                backgroundColor: isTranscriptVisible ? .blue : .gray,
                                foregroundColor: .white
                            )

//                            Spacer()

                            // The new round disconnect button
                            DisconnectButton(
                                disconnectAction: disconnect,
                                width: width,
                                height: height,
                                fontSize: fontSize
                            )
                            .matchedGeometryEffect(id: "main-button", in: animation, properties: .position)
                    }
//                    .padding(.horizontal, 50)
//                    .padding(.vertical, 4)
//                    .background(Color("ButtonBackgroundColor"))
                    .cornerRadius(8)
                }
            case .transitioning:
                TransitionButton(isConnecting: isConnecting)
                    .matchedGeometryEffect(id: "main-button", in: animation, properties: .position)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(
            Color(.systemGray6) // Or .ultraThinMaterial for a blurred look
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.spring(duration: 0.1), value: currentConfiguration)
    }

    /// Disconnects from the current LiveKit room.
    private func disconnect() {
        Task {
            isDisconnecting = true
            await room.disconnect()
            isDisconnecting = false

            // Reset flags.
            isAudioEnabled = false
            isVideoEnabled = false
            isScreenSharingEnabled = false
            isTranscriptVisible = false

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
            let captureOptions = AudioCaptureOptions(
                echoCancellation: true,
                autoGainControl: true,
                noiseSuppression: true,
                highpassFilter: true
            )
            
            if (isAudioEnabled && toggleMode == .on) || (!isAudioEnabled && toggleMode == .off) {
                print("audio is already in the targeted state")
                return
            }
            
            let targetMode = toggleMode == .toggle ? !isAudioEnabled : (toggleMode == .on)
            print("target mode is \(targetMode)")
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
                simulcast: false,
                simulcastLayers: [],
                screenShareSimulcastLayers: [],
                preferredCodec: nil,
                preferredBackupCodec: nil,
                degradationPreference: .auto,
                streamName: nil
            )
            
            let targetMode = toggleMode == .toggle ? !isVideoEnabled : (toggleMode == .on)
            
            if (isVideoEnabled && toggleMode == .on) || (!isVideoEnabled && toggleMode == .off) {
                print("video is already in the targeted state")
                return
            }
            
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
    var width: CGFloat = 70
    var height: CGFloat = 70
    var fontSize: CGFloat = 28

    var body: some View {
        Button(action: connectAction) {
            Image(systemName: "phone.fill")
                .font(.system(size: fontSize))
                .foregroundColor(.white)
                .frame(width: width, height: height)
                .background(Color.green.opacity(0.9))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}


/// Button shown when connected to end the conversation

private struct DisconnectButton: View {
    var disconnectAction: () -> Void
    var width: CGFloat = 70
    var height: CGFloat = 70
    var fontSize: CGFloat = 28

    var body: some View {
        Button(action: disconnectAction) {
            Image(systemName: "xmark")
                .font(.system(size: fontSize))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: width, height: height)
                .background(Color.red.opacity(0.9))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
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
