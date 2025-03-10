import LiveKit
import Foundation

enum ErrorCodeSetStartTime: Error {
    case noAgentIdentity
    case setStartTimeFailed
}

struct SetStartTimeResponse: Decodable {
    let changed: String
}

func setRecordStartTime(room: Room) async throws -> Result<String, ErrorCodeSetStartTime> {
    guard let agentIdentity = findAgentIdentity(in: room.remoteParticipants) else {
        return .failure(.noAgentIdentity)
    }
    
    do {
        // Encode the toolList array into JSON data.
        let currentTime = Date().timeIntervalSince1970
        let payloadDict = ["start_time": currentTime]
        let jsonData = try JSONEncoder().encode(payloadDict)
        
        // Convert JSON data to a String payload.
        guard let jsonPayload = String(data: jsonData, encoding: .utf8) else {
            return .failure(.setStartTimeFailed)
        }
        
        let response = try await room.localParticipant.performRpc(
            destinationIdentity: agentIdentity,
            method: "setRecordStartTime",
            payload: jsonPayload
        )
        print("Set record start time: \(response)")
        
        guard let jsonData = response.data(using: .utf8) else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }
        
        let toolListResponse = try JSONDecoder().decode(ToolListResponse.self, from: jsonData)
        
        return toolListResponse.changed == "true" ? .success("Success") : .failure(.setStartTimeFailed)
    } catch {
        return .failure(.setStartTimeFailed)
    }
}
