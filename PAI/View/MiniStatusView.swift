import LiveKit
import LiveKitComponents
import SwiftUI

/// A mini version of the audio visualizer for displaying in the top bar.
struct MiniStatusView: View {
    @EnvironmentObject private var room: Room

    // Get the first agent participant (assumes one agent with one audio track)
    private var agentParticipant: RemoteParticipant? {
        room.remoteParticipants.values.first { $0.kind == .agent }
    }

    // Use the agent state to drive animation effects
    private var agentState: AgentState? {
        agentParticipant?.agentState ?? .initializing
    }

    var body: some View {
        if let track = agentParticipant?.firstAudioTrack {
            BarAudioVisualizer(
                audioTrack: track,
                barColor: .primary,
                barCount: 3 // fewer bars for a compact view
            )
            .frame(width: 100, height: 44)  // constrain to a mini size
            .opacity(agentState == .speaking ? 1 : 0.3)
            .animation(
                .easeInOut(duration: 1)
                    .repeatForever(autoreverses: true)
                    .speed(agentState == .thinking ? 5 : 1),
                value: agentState
            )
        } else {
            // Placeholder to maintain layout consistency when no audio track is available.
            Rectangle()
                .fill(.clear)
                .frame(width: 100, height: 44)
        }
    }
}
