import Foundation

func sendSessionConfigToBackend(_ sessionConfig: SessionConfig, serverUrl: String) {
    guard let url = URL(string: "\(serverUrl)/update_session-config") else {
        print("Invalid server URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        let jsonData = try JSONEncoder().encode(sessionConfig)
        request.httpBody = jsonData
    } catch {
        print("Failed to encode session config: \(error)")
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Failed to send session config: \(error)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print("Failed to send session config: HTTP \(httpResponse.statusCode)")
            return
        }
        
        print("Session config successfully sent to backend")
    }.resume()
}
