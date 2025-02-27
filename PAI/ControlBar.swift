import SwiftUI
import LiveKit
import LiveKitComponents
import AVFoundation

struct ControlBar: View {
    @EnvironmentObject private var room: Room
        
    // Callback when the connect button is tapped
    var onStartConversation: () -> Void
    
    @Binding var isAudioEnabled: Bool
    @Binding var isVideoEnabled: Bool
    @Binding var isTranscriptVisible: Bool
    @Binding var isHoldToTalk: Bool
    
    @State private var isScreenSharingEnabled: Bool = false
    @State private var isConnecting: Bool = false
    @State private var isDisconnecting: Bool = false
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    @State private var isRecording: Bool = false

    // Updated dimensions for a more modern look
    let buttonSize: CGFloat = 70
    let buttonFontSize: CGFloat = 22
    
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
        VStack(spacing: 12) {
            // Top row for toggles when connected
            if currentConfiguration == .connected {
                HStack(spacing: 16) {
                    // Audio visualizer with fixed width
                    LocalAudioVisualizer(track: room.localParticipant.firstAudioTrack)
                        .frame(height: 40)
                        .frame(width: 90)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(20)
                        .id(room.localParticipant.firstAudioTrack?.id ?? "no-track")
                    
                    // Camera flip button
                    Button(action: flipCamera) {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ColorConstants.buttonContent)
                            .padding(10)
                            .background(ColorConstants.buttonBackground)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Simplified Toggle controls - just icon and toggle, no container
                    HStack(spacing: 8) {
                        Image(systemName: isTranscriptVisible ? "text.bubble.fill" : "text.bubble")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(isTranscriptVisible ? ColorConstants.toggleActiveColor : ColorConstants.toggleInactiveColor)
                        
                        Toggle("", isOn: $isTranscriptVisible)
                            .toggleStyle(SwitchToggleStyle(tint: ColorConstants.toggleActiveColor))
                            .labelsHidden()
                            .scaleEffect(0.9)
                    }
                    
                    // Use the HoldToTalkView component but set showLabel to false
                    HoldToTalkView(isHoldToTalk: $isHoldToTalk, showLabel: false)
                }
                .padding(.horizontal, 16)
            }
            
            // Main controls
            switch currentConfiguration {
            case .disconnected:
                // Just the StartCallButton without any container styling
                UnstyledStartCallButton(connectAction: onStartConversation)
                    .matchedGeometryEffect(id: "main-button", in: animation)
                
            case .connected:
                // Control buttons in a modern layout
                HStack(spacing: 28) {
                    // Change mic button to record button when Hold-to-Talk is enabled
                    if isHoldToTalk {
                        // Custom record button with prominent styling
                        Button(action: toggleRecording) {
                            ZStack {
                                Circle()
                                    .fill(isRecording ? Color.red : ColorConstants.buttonBackground)
                                    .frame(width: buttonSize, height: buttonSize)
                                    .shadow(color: ColorConstants.buttonShadow, radius: 5, x: 0, y: 2)
                                
                                if isRecording {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: buttonFontSize, weight: .semibold))
                                        .foregroundColor(.white)
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: buttonSize * 0.7)
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: buttonSize * 0.5)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .shadow(color: isRecording ? Color.red.opacity(0.4) : Color.red.opacity(0.2), radius: 8, x: 0, y: 3)
                    } else {
                        RoundControlButton(
                            iconName: isAudioEnabled ? "mic.fill" : "mic.slash.fill",
                            action: { toggleAudio(toggleMode: .toggle) },
                            isActive: isAudioEnabled,
                            primaryColor: .blue,
                            size: buttonSize,
                            fontSize: buttonFontSize
                        )
                    }
                    
                    RoundControlButton(
                        iconName: isVideoEnabled ? "video.fill" : "video.slash.fill",
                        action: { toggleVideo(toggleMode: .toggle) },
                        isActive: isVideoEnabled,
                        primaryColor: .indigo,
                        size: buttonSize,
                        fontSize: buttonFontSize
                    )
                    
                    RoundControlButton(
                        iconName: isScreenSharingEnabled ? "rectangle.on.rectangle.fill" : "rectangle.on.rectangle",
                        action: { toggleScreenShare(toggleMode: .toggle) },
                        isActive: isScreenSharingEnabled,
                        primaryColor: .purple,
                        size: buttonSize,
                        fontSize: buttonFontSize
                    )
                    
                    // End call button with X icon
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
                    .matchedGeometryEffect(id: "main-button", in: animation)
                }
                .padding(.horizontal, 20)
                
            case .transitioning:
                TransitionIndicator(isConnecting: isConnecting)
                    .matchedGeometryEffect(id: "main-button", in: animation)
            }
        }
        // Only apply container styling when connected
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
        .animation(.spring(response: 0.3), value: currentConfiguration)
    }
    
    // Toggle functions remain the same
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
    
    private func toggleRecording() {
        Task {
            if isRecording {
                // Currently recording, need to stop
                isRecording = false
                
                // Turn off audio capture
                try await self.room.localParticipant.setMicrophone(enabled: false)
                isAudioEnabled = false
                
                // Call createConversation function
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
            } else {
                // Not recording, need to start
                isRecording = true
                
                // Turn on audio capture
                let captureOptions = AudioCaptureOptions(
                    echoCancellation: true,
                    autoGainControl: true,
                    noiseSuppression: true,
                    highpassFilter: true
                )
                try await self.room.localParticipant.setMicrophone(enabled: true, captureOptions: captureOptions)
                isAudioEnabled = true
            }
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
        // Ensure video is enabled
        guard isVideoEnabled else { return }
        
        // Attempt to use the camera capturer's switch method
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

            // Reset flags
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
            RoundedRectangle(cornerRadius: 16)
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
        .frame(height: 40)
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
                    .fill(isActive ? primaryColor : ColorConstants.buttonBackground)
                    .frame(width: size, height: size)
                    .shadow(color: ColorConstants.buttonShadow, radius: 5, x: 0, y: 2)
                
                Image(systemName: iconName)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(isActive ? .white : ColorConstants.buttonContent)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: isActive ? primaryColor.opacity(0.4) : Color.clear, radius: 5, x: 0, y: 3)
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
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                
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
