import LiveKit
import Foundation

enum ErrorCode: Error {
    case noAgentIdentity
    case setToolListFailed
}

struct ToolListResponse: Decodable {
    let changed: String
}

func setToolList(room: Room, toolList: [String]) async throws -> Result<String, ErrorCode> {
    guard let agentIdentity = findAgentIdentity(in: room.remoteParticipants) else {
        return .failure(.noAgentIdentity)
    }
    
    do {
        // Encode the toolList array into JSON data.
        let payloadDict = ["tool_list": toolList]
        let jsonData = try JSONEncoder().encode(payloadDict)
        
        // Convert JSON data to a String payload.
        guard let jsonPayload = String(data: jsonData, encoding: .utf8) else {
            return .failure(.setToolListFailed)
        }
        
        let response = try await room.localParticipant.performRpc(
            destinationIdentity: agentIdentity,
            method: "setToolList",
            payload: jsonPayload
        )
        print("Set tool list: \(response)")
        
        guard let jsonData = response.data(using: .utf8) else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }
        
        let toolListResponse = try JSONDecoder().decode(ToolListResponse.self, from: jsonData)
        
        return toolListResponse.changed == "true" ? .success("Success") : .failure(.setToolListFailed)
    } catch {
        return .failure(.setToolListFailed)
    }
}
