import SwiftUI
import LiveKit

@main
struct PAIApp: App {
    @AppStorage("serverUrl") private var serverUrl: String = ""
    @AppStorage("authenticationUrl") private var authenticationUrl: String = ""
    
    @StateObject private var sessionConfigStore = SessionConfigStore()
    @StateObject private var tokenService: TokenService
    @StateObject private var room: Room
    @StateObject private var transcriptionDelegate: TranscriptionDelegate

    init() {
        // Read stored values for tokenService initialization.
        let storedServerUrl = UserDefaults.standard.string(forKey: "serverUrl") ?? ""
        let storedAuthenticationUrl = UserDefaults.standard.string(forKey: "authenticationUrl") ?? ""
        _tokenService = StateObject(wrappedValue: TokenService(serverUrl: storedServerUrl,
                                                               authenticationUrl: storedAuthenticationUrl))
        // Create a single instance of TranscriptionDelegate.
        let delegate = TranscriptionDelegate()
        _transcriptionDelegate = StateObject(wrappedValue: delegate)
        // Initialize the Room with the same delegate.
        _room = StateObject(wrappedValue: Room(delegate: delegate))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(room: room)
                .environmentObject(transcriptionDelegate)
                .environmentObject(tokenService)
                .environmentObject(sessionConfigStore)
        }
    }
}
