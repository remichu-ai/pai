import LiveKit
import Foundation

enum ErrorCodeInterrupt: Error {
    case noAgentIdentity
    case interruptAgentFailed
}


func interruptAgent(room: Room) async throws -> Result<String, ErrorCodeInterrupt> {
    guard let agentIdentity = findAgentIdentity(in: room.remoteParticipants) else {
        return .failure(.noAgentIdentity)
    }
    
    do {
        
        let response = try await room.localParticipant.performRpc(
            destinationIdentity: agentIdentity,
            method: "interruptAgent",
            payload: ""
        )
        
        guard let jsonData = response.data(using: .utf8) else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }
        
        let toolListResponse = try JSONDecoder().decode(ToolListResponse.self, from: jsonData)
        
        return toolListResponse.changed == "true" ? .success("Success") : .failure(.interruptAgentFailed)
    } catch {
        return .failure(.interruptAgentFailed)
    }
}
