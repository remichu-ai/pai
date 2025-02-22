import Foundation
import LiveKit

func serializeSessionConfig(_ sessionConfig: SessionConfig) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted  // Optional: makes the JSON easier to read
    do {
        let jsonData = try encoder.encode(sessionConfig)
        return String(data: jsonData, encoding: .utf8)
    } catch {
        print("Failed to encode session config: \(error)")
        return nil
    }
}

func sendSessionConfigToBackend(_ sessionConfig: SessionConfig, room: Room) {
    Task {
        print("Participant count: \(room.participantCount)")
        print("All participants: \(room.allParticipants)")
        print("Remote participants: \(room.remoteParticipants)")

        
        guard let payload = serializeSessionConfig(sessionConfig) else {
            print("Serialization failed")
            return
        }
        
        do {
            let remoteParticipants = room.remoteParticipants
            var agentIdentity: Participant.Identity? = nil  // Declare as an optional
            
            for (key, _) in remoteParticipants {
                print("Checking participant: \(key)")
                if key.stringValue.contains("agent") {
                    agentIdentity = key
                    print("agent detected")
                    break  // Stop after finding the first matching identity
                }
            }
            
            if let agentIdentity = agentIdentity {  // Use optional binding
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
