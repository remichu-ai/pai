import Foundation
import LiveKit

func sendSessionConfigToBackend(_ sessionConfig: SessionConfig, room: Room) async throws {
    print("session config: \(sessionConfig)")
    guard let payload = serialize(sessionConfig) else {
        throw NSError(domain: "Serialization", code: -1, userInfo: nil)
    }
    guard let agentIdentity = findAgentIdentity(in: room.remoteParticipants) else {
        throw NSError(domain: "NoAgent", code: -1, userInfo: nil)
    }
    let response = try await room.localParticipant.performRpc(
        destinationIdentity: agentIdentity,
        method: "pg.updateConfig",
        payload: payload
    )
    print("Update session config response: \(response)")
}
