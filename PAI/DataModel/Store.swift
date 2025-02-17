import Foundation

class SessionConfigStore: ObservableObject {
    @Published var sessionConfig: SessionConfig = SessionConfig()
}
