import Foundation

struct ConnectionDetails: Codable {
    let serverUrl: String
    let roomName: String
    let participantName: String
    let participantToken: String
}

class TokenService: ObservableObject {
    func fetchConnectionDetails(roomName: String, participantName: String) async throws -> ConnectionDetails? {
        if let apiConnectionDetails = try await fetchConnectionDetailsFromAPI(roomName: roomName, participantName: participantName) {
            return apiConnectionDetails
        }

        return try await fetchConnectionDetailsFromSandbox(roomName: roomName, participantName: participantName)
    }

    private let apiBaseUrl: String = "http://100.123.119.59:3111" // Replace with your API base URL

    private func fetchConnectionDetailsFromAPI(roomName: String, participantName: String) async throws -> ConnectionDetails? {
        guard let token = try await fetchTokenFromAPI() else {
            return nil
        }

        return .init(
            serverUrl: "http://100.123.119.59:7880", // Replace with your LiveKit server URL
            roomName: roomName,
            participantName: participantName,
            participantToken: token
        )
    }

    private func fetchTokenFromAPI() async throws -> String? {
        let url = URL(string: "\(apiBaseUrl)/getToken")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("Failed to connect to the token API")
            return nil
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            debugPrint("Error from token API: \(httpResponse.statusCode), response: \(httpResponse)")
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let token = json["token"] as? String else {
            debugPrint("Error parsing token from API response")
            return nil
        }

        return token
    }

    private let sandboxId: String? = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "LiveKitSandboxId") as? String {
            // LK CLI will add unwanted double quotes
            return value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }()

    private let sandboxUrl: String = "https://cloud-api.livekit.io/api/sandbox/connection-details"
    private func fetchConnectionDetailsFromSandbox(roomName: String, participantName: String) async throws -> ConnectionDetails? {
        guard let sandboxId else {
            return nil
        }

        var urlComponents = URLComponents(string: sandboxUrl)!
        urlComponents.queryItems = [
            URLQueryItem(name: "roomName", value: roomName),
            URLQueryItem(name: "participantName", value: participantName),
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue(sandboxId, forHTTPHeaderField: "X-Sandbox-ID")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("Failed to connect to LiveKit Cloud sandbox")
            return nil
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            debugPrint("Error from LiveKit Cloud sandbox: \(httpResponse.statusCode), response: \(httpResponse)")
            return nil
        }

        guard let connectionDetails = try? JSONDecoder().decode(ConnectionDetails.self, from: data) else {
            debugPrint("Error parsing connection details from LiveKit Cloud sandbox, response: \(httpResponse)")
            return nil
        }

        return connectionDetails
    }
}
