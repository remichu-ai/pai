import LiveKit
import Foundation

func getToolList(room: Room) async throws -> [String] {
    guard let agentIdentity = findAgentIdentity(in: room.remoteParticipants) else {
        return [] // or handle the error appropriately
    }
    
    let response = try await room.localParticipant.performRpc(
        destinationIdentity: agentIdentity,
        method: "getToolList",
        payload: ""
    )
    print("Get tool list: \(response)")
    
    // Convert the JSON string into Data.
    guard let jsonData = response.data(using: .utf8) else {
        throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
    }
    
    // Parse the JSON data into a dictionary.
    let responseDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
 
    
    // Extract your tool list from the dictionary. For example, if your dictionary has a key "tools":
    if let tools = responseDict?["tool_list"] as? [String] {
        return tools
    }
    
    return []
}
