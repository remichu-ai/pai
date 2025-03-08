import LiveKit
import Foundation

func getToolList(room: Room) async throws -> (allTools: [String], activeTools: [String]) {
    guard let agentIdentity = findAgentIdentity(in: room.remoteParticipants) else {
        return ([], [])
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
    
    // If "tool_list" exists, use it; otherwise assume the root dictionary holds the tool info.
    let toolListDict: [String: Any]
    if let nested = responseDict?["tool_list"] as? [String: Any] {
        toolListDict = nested
    } else {
        toolListDict = responseDict ?? [:]
    }
    
    // Parse the "active" tools.
    var activeTools: [String] = []
    if let active = toolListDict["active"] as? [String] {
        activeTools = active
    } else if let activeStr = toolListDict["active"] as? String, activeStr == "NONE" {
        activeTools = []
    }
    
    // Parse the "disabled" tools.
    var disabledTools: [String] = []
    if let disabled = toolListDict["disabled"] as? [String] {
        disabledTools = disabled
    } else if let disabledStr = toolListDict["disabled"] as? String, disabledStr == "NONE" {
        disabledTools = []
    }
    
    // Combine both lists for a full list of tools.
    let allTools = Array(Set(activeTools + disabledTools))
    return (allTools, activeTools)
}
