import Foundation
import LiveKit

func sendSessionConfigToBackend(_ sessionConfig: SessionConfig, room: Room) {
    Task {
        print("Participant count: \(room.participantCount)")
        print("All participants: \(room.allParticipants)")
        print("Remote participants: \(room.remoteParticipants)")
        
        guard let payload = serialize(sessionConfig) else {
            print("Serialization failed")
            return
        }
        
        do {
            if let agentIdentity = findAgentIdentity(in: room.remoteParticipants) {
                let response = try await room.localParticipant.performRpc(
                    destinationIdentity: agentIdentity,
                    method: "pg.updateConfig",
                    payload: payload
                )
                print("Update session config response: \(response)")
            } else {
                print("No agent found")
            }
        } catch {
            print("Update session config failed: \(error)")
        }
    }
}
