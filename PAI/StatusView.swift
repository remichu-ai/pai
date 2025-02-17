import LiveKit
import LiveKitComponents
import SwiftUI

/// Shows a visualizer for the agent participant in the room
/// In a more complex app, you may want to show more information here
struct StatusView: View {
    // Load the room from the environment
    @EnvironmentObject private var room: Room

    // Find the first agent participant in the room
    // This assumes there's only one agent and they publish only one audio track
    // Your application may have more complex requirements
    private var agentParticipant: RemoteParticipant? {
        for participant in room.remoteParticipants.values {
            if participant.kind == .agent {
                return participant
            }
        }

        return nil
    }

    // Reads the agent state property which is updated automatically
    private var agentState: AgentState? {
        agentParticipant?.agentState ?? .initializing
    }

    var body: some View {
        if let track = agentParticipant?.firstAudioTrack {
            BarAudioVisualizer(audioTrack: track, barColor: .primary, barCount: 5)
                .opacity(agentState == .speaking ? 1 : 0.3)
                .animation(
                    .easeInOut(duration: 1)
                        .repeatForever(autoreverses: true)
                        .speed(agentState == .thinking ? 5 : 1),
                    value: agentState)
        } else {
            // Placeholder for when agent audio isn't available yet, so the app geometry doesn't change
            Rectangle().fill(.clear)
        }
    }
}
