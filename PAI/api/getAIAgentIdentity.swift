import Foundation
import LiveKit

// New reusable function to find the AI Agent's identity
func findAgentIdentity(in remoteParticipants: [Participant.Identity: Participant]) -> Participant.Identity? {
    for (identity, _) in remoteParticipants {
        print("Checking participant: \(identity)")
        if identity.stringValue.contains("agent") {
            print("Agent detected")
            return identity
        }
    }
    return nil
}
