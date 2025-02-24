import LiveKit
import Foundation

enum ErrorCodeCreateConversation: Error {
    case failed
}


func createConversation(room: Room) async throws -> Result<String, ErrorCodeCreateConversation> {
    guard let agentIdentity = findAgentIdentity(in: room.remoteParticipants) else {
        return .failure(.failed)  // or handle the error appropriately
    }
    
    let response = try await room.localParticipant.performRpc(
        destinationIdentity: agentIdentity,
        method: "createResponse",
        payload: ""
    )
    print("create response: \(response)")
    
    // Convert the JSON string into Data.
    guard let jsonData = response.data(using: .utf8) else {
        throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
    }
    
    // Parse the JSON data into a dictionary.
    let responseDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String]
 
    
    // Extract your tool list from the dictionary. For example, if your dictionary has a key "tools":
    print("responseDict \(String(describing: responseDict))")
    if responseDict?["changed"]=="true" {
        return .success(responseDict?["changed"] ?? "")
    }
    
    return .failure(.failed)
}
