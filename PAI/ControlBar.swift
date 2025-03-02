import SwiftUI
import LiveKit
import LiveKitComponents
import AVFoundation

struct ControlBar: View {
    @EnvironmentObject private var room: Room
        
    var onStartConversation: () -> Void
    @Binding var isAudioEnabled: Bool
    @Binding var isVideoEnabled: Bool
    @Binding var isTranscriptVisible: Bool
    @Binding var isHandsFree: Bool
    @Binding var isRecording: Bool    // <<-- Now passed as a binding
    var onToggleAdditionalSettings: () -> Void
    
    @State private var isScreenSharingEnabled: Bool = false
    @State private var isConnecting: Bool = false
    @State private var isDisconnecting: Bool = false
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    
    let buttonSize: CGFloat = 70
    let buttonFontSize: CGFloat = 22
    
    let buttonSizeSmall: CGFloat = 60
    let buttonFontSizeSmall: CGFloat = 20

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
        VStack(spacing: 12) {
            if currentConfiguration == .connected {
                HStack(spacing: 16) {
                    Button(action: {
                        onToggleAdditionalSettings()
                    }) {
                        Circle()
                            .fill(ColorConstants.buttonBackground)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(ColorConstants.buttonContent)
                            )
                    }
                    
                    Spacer()
                    
                    LocalAudioVisualizer(track: room.localParticipant.firstAudioTrack)
                        .frame(height: 26)
                        .frame(width: 90)
                        .id(room.localParticipant.firstAudioTrack?.hashValue ?? 0)
                    
                    Spacer()
                    
                    Button(action: flipCamera) {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(ColorConstants.buttonContent)
                            .padding(10)
                            .background(ColorConstants.buttonBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
            }
            
            switch currentConfiguration {
            case .disconnected:
                UnstyledStartCallButton(connectAction: onStartConversation)
                    .transition(.identity)
                
            case .connected:
                HStack(spacing: 28) {
                    // Audio recording button with mic icons that change based on state
                    ZStack {
                        Circle()
                            .fill(isHandsFree ? (isAudioEnabled ? Color.blue : ColorConstants.buttonBackgroundInactive)
                                               : (isRecording ? Color.blue : ColorConstants.buttonBackgroundInactive))
                            .frame(width: buttonSize, height: buttonSize)
                            .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 2)
                        
                        if isHandsFree {
                            Image(systemName: isAudioEnabled ? "mic.fill" : "mic.slash.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(isAudioEnabled ? .white : ColorConstants.buttonContent)
                        } else {
                            if isRecording {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(ColorConstants.buttonContent)
                            }
                        }
                    }
                    .contentShape(Circle())
                    .onTapGesture {
                        if isHandsFree {
                            toggleAudio(toggleMode: .toggle)
                        } else {
                            setRecording(to: !isRecording)
                        }
                    }
                    
                    RoundControlButton(
                        iconName: isVideoEnabled ? "video.fill" : "video.slash.fill",
                        action: { toggleVideo(toggleMode: .toggle) },
                        isActive: isVideoEnabled,
                        primaryColor: .indigo,
                        size: buttonSizeSmall,
                        fontSize: buttonFontSizeSmall
                    )
                    
                    RoundControlButton(
                        iconName: isScreenSharingEnabled ? "rectangle.on.rectangle.fill" : "rectangle.on.rectangle",
                        action: { toggleScreenShare(toggleMode: .toggle) },
                        isActive: isScreenSharingEnabled,
                        primaryColor: .purple,
                        size: buttonSizeSmall,
                        fontSize: buttonFontSizeSmall
                    )
                    
                    Button(action: disconnect) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: buttonSize, height: buttonSize)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: buttonFontSize, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.identity)
                }
                .padding(.horizontal, 20)
                .transition(.identity)
                
            case .transitioning:
                TransitionIndicator(isConnecting: isConnecting)
                    .transition(.identity)
            }
        }
        .padding(.vertical, currentConfiguration != .disconnected ? 16 : 0)
        .background(
            Group {
                if currentConfiguration != .disconnected {
                    ColorConstants.controlBackgroundWithMaterial()
                        .cornerRadius(24)
                        .shadow(color: ColorConstants.buttonShadow, radius: 10, x: 0, y: 5)
                }
            }
        )
        .animation(nil, value: currentConfiguration)
    }
    
    private func setRecording(to shouldRecord: Bool) {
        Task {
            print("Setting recording to: \(shouldRecord)")
            print("Current recording state: \(isRecording)")
            
            if shouldRecord && !isRecording {
                // First enable the microphone using the existing toggleAudio method
                print("Enabling microphone via toggleAudio...")
                try await toggleAudio(toggleMode: .on)
                
                // Log track state for debugging - using public API methods
                let audioTracks = room.localParticipant.localAudioTracks
                if !audioTracks.isEmpty {
                    let audioTrack = audioTracks.first!
                    print("Audio track successfully published with sid: \(audioTrack.sid)")
                    print("Audio track muted state: \(audioTrack.isMuted)")
                } else {
                    print("Warning: No audio track publication found after enabling microphone")
                }
                
                // Then interrupt agent (after audio is enabled)
                print("Interrupting agent...")
                let result = try await interruptAgent(room: self.room)
                switch result {
                    case .success(let message):
                        print("Successfully interrupted agent: \(message)")
                    case .failure(let error):
                        print("Failed to interrupt agent: \(error)")
                        // Continue with recording even if interrupt fails
                }
                
                // Set recording state last, after audio is confirmed working
                isRecording = true
                print("Recording started successfully")
                
            } else if !shouldRecord && isRecording {
                // First update recording state
                isRecording = false
                print("Stopping recording...")
                
                // Then disable microphone using toggleAudio for consistency
                try await toggleAudio(toggleMode: .off)
                print("Microphone disabled via toggleAudio")
                
                // Only create conversation if not in hands-free mode
                if !isHandsFree {
                    print("Creating conversation...")
                    do {
                        let result = try await createConversation(room: room)
                        switch result {
                        case .success(let response):
                            print("Successfully created conversation: \(response)")
                        case .failure(let error):
                            print("Failed to create conversation: \(error)")
                        }
                    } catch {
                        print("Error creating conversation: \(error)")
                    }
                }
                
                print("Recording stopped successfully")
            }
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
            
            let targetMode = toggleMode == .toggle ? !isAudioEnabled : (toggleMode == .on)
            try await self.room.localParticipant.setMicrophone(enabled: targetMode, captureOptions: captureOptions)
            isAudioEnabled = targetMode
        }
    }
    
    private func toggleVideo(toggleMode: ToggleMode = .toggle) {
        Task {
            let captureOptions = CameraCaptureOptions(
                position: cameraPosition,
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
            try await self.room.localParticipant.setCamera(
                enabled: targetMode,
                captureOptions: captureOptions,
                publishOptions: publishOptions
            )
            isVideoEnabled = targetMode
        }
    }
    
    private func flipCamera() {
        guard isVideoEnabled else { return }
        if let track = room.localParticipant.firstCameraVideoTrack as? LocalVideoTrack,
           let cameraCapturer = track.capturer as? CameraCapturer {
            Task {
                do {
                    try await cameraCapturer.switchCameraPosition()
                } catch {
                    print("Error switching camera: \(error)")
                }
            }
        }
    }
    
    private func toggleScreenShare(toggleMode: ToggleMode = .toggle) {
        Task {
            let targetMode = toggleMode == .toggle ? !isScreenSharingEnabled : (toggleMode == .on)
            try await self.room.localParticipant.setScreenShare(enabled: targetMode)
            isScreenSharingEnabled = targetMode
        }
    }
    
    private func disconnect() {
        Task {
            isDisconnecting = true
            await room.disconnect()
            isDisconnecting = false

            isAudioEnabled = false
            isVideoEnabled = false
            isScreenSharingEnabled = false
            isTranscriptVisible = false
            isRecording = false
        }
    }
}


// Modernized local audio visualizer
struct LocalAudioVisualizer: View {
    var track: AudioTrack?
    
    @StateObject private var audioProcessor: AudioProcessor
    
    init(track: AudioTrack?) {
        self.track = track
        _audioProcessor = StateObject(
            wrappedValue: AudioProcessor(
                track: track,
                bandCount: 10,
                isCentered: false))
    }
    
    public var body: some View {
        ZStack {
            // Use the visualizerBackground from ColorConstants
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorConstants.visualizerBackground)
                .shadow(color: ColorConstants.buttonShadow, radius: 3, x: 0, y: 1)
            
            // Audio visualization bars
            HStack(spacing: 4) {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [ColorConstants.toggleActiveColor.opacity(0.5), ColorConstants.toggleActiveColor.opacity(0.8)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 3)
                        .frame(height: CGFloat(audioProcessor.bands[index % audioProcessor.bands.count]) * 13)
                        .animation(.easeOut(duration: 0.2), value: audioProcessor.bands[index])
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 26)
        .frame(width: 90)
    }
}

// Modern round control button
struct RoundControlButton: View {
    var iconName: String
    var action: () -> Void
    var isActive: Bool
    var primaryColor: Color
    var size: CGFloat = 60
    var fontSize: CGFloat = 22
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    // Use a contrasting color if inactive
                    .fill(isActive ? primaryColor : ColorConstants.buttonBackgroundInactive)
                    .frame(width: size, height: size)
                    .shadow(color: ColorConstants.buttonShadow, radius: 5, x: 0, y: 2)
                
                Image(systemName: iconName)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(isActive ? .white : ColorConstants.buttonContent)
            }
        }
        .buttonStyle(.plain)
        // If active, add a subtle glow or keep it clear if inactive
        .shadow(color: isActive ? primaryColor.opacity(0.4) : Color.clear,
                radius: 5, x: 0, y: 3)
    }
}


// Improved start call button with audio wave icon matching the design in screenshot
struct UnstyledStartCallButton: View {
    var connectAction: () -> Void
    
    var body: some View {
        Button(action: connectAction) {
            ZStack {
                // Larger circle with standard blue color
                Circle()
                    .fill(Color.blue)
                    .frame(width: 120, height: 120) // Increased from 110 to 120
                    // Add standard shadow for better visibility
                    .shadow(color: ColorConstants.connectButtonBackground, radius: 8, x: 0, y: 4)
                
                // Audio wave bars with bigger inner area
                HStack(spacing: 4) { // Increased spacing from 3 to 4
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 4, height: getBarHeight(for: i)) // Increased width from 3 to 4
                    }
                }
                .scaleEffect(1.3) // Scale up the audio wave pattern to make it more prominent
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Function with increased heights for audio wave bars
    private func getBarHeight(for index: Int) -> CGFloat {
        switch index {
        case 0: return 18 // From 15
        case 1: return 30 // From 25
        case 2: return 42 // From 35
        case 3: return 30 // From 25
        case 4: return 18 // From 15
        default: return 24 // From 20
        }
    }
}

// Transition indicator
struct TransitionIndicator: View {
    var isConnecting: Bool
    
    var body: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text(isConnecting ? "Connecting..." : "Disconnecting...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(20)
    }
}
