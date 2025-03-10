import LiveKit
import Foundation

enum ErrorCodeClearHistory: Error {
    case noAgentIdentity
    case clearHistoryFailed
}

struct ClearHistoryTimeResponse: Decodable {
    let changed: String
}

func clearMessageHistory(room: Room) async throws -> Result<String, ErrorCodeClearHistory> {
    guard let agentIdentity = findAgentIdentity(in: room.remoteParticipants) else {
        return .failure(.noAgentIdentity)
    }
    
    do {
        // Encode the toolList array into JSON data.
        let payloadDict = ["clear_history": "true"]
        let jsonData = try JSONEncoder().encode(payloadDict)
        
        // Convert JSON data to a String payload.
        guard let jsonPayload = String(data: jsonData, encoding: .utf8) else {
            return .failure(.clearHistoryFailed)
        }
        
        let response = try await room.localParticipant.performRpc(
            destinationIdentity: agentIdentity,
            method: "clearHistory",
            payload: jsonPayload
        )
        print("Set record start time: \(response)")
        
        guard let jsonData = response.data(using: .utf8) else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }
        
        let toolListResponse = try JSONDecoder().decode(ToolListResponse.self, from: jsonData)
        
        return toolListResponse.changed == "true" ? .success("Success") : .failure(.clearHistoryFailed)
    } catch {
        return .failure(.clearHistoryFailed)
    }
}
