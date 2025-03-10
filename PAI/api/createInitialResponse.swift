import LiveKit
import Foundation

enum ErrorCodeCreateInitialResponse: Error {
    case noAgentIdentity
    case createInitialResponseFailed
}

struct CreateInitialResponseResponse: Decodable {
    let changed: String
}

func createInitialResponse(room: Room) async throws -> Result<String, ErrorCodeCreateInitialResponse> {
    guard let agentIdentity = findAgentIdentity(in: room.remoteParticipants) else {
        return .failure(.noAgentIdentity)
    }
    
    do {
        // Encode the toolList array into JSON data.
        let payloadDict = ["create_initial_response": "true"]
        let jsonData = try JSONEncoder().encode(payloadDict)
        
        // Convert JSON data to a String payload.
        guard let jsonPayload = String(data: jsonData, encoding: .utf8) else {
            return .failure(.createInitialResponseFailed)
        }
        
        let response = try await room.localParticipant.performRpc(
            destinationIdentity: agentIdentity,
            method: "createInitialResponse",
            payload: jsonPayload
        )
        print("Create Initial Response Response: \(response)")
        
        guard let jsonData = response.data(using: .utf8) else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }
        
        let toolListResponse = try JSONDecoder().decode(ToolListResponse.self, from: jsonData)
        
        return toolListResponse.changed == "true" ? .success("Success") : .failure(.createInitialResponseFailed)
    } catch {
        return .failure(.createInitialResponseFailed)
    }
}
