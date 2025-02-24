import Foundation

class SessionConfigStore: ObservableObject {
    @Published var sessionConfig: SessionConfig {
        didSet {
            saveConfig()
        }
    }
    
    private let configKey = "sessionConfig"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let decodedConfig = try? JSONDecoder().decode(SessionConfig.self, from: data) {
            sessionConfig = decodedConfig
        } else {
            sessionConfig = SessionConfig() // default settings
        }
    }
    
    private func saveConfig() {
        if let encoded = try? JSONEncoder().encode(sessionConfig) {
            UserDefaults.standard.set(encoded, forKey: configKey)
        }
    }
}
