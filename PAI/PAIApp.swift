import SwiftUI

@main
struct PAIApp: App {
    @AppStorage("serverUrl") private var serverUrl: String = ""
    @AppStorage("authenticationUrl") private var authenticationUrl: String = ""
    @StateObject private var sessionConfigStore = SessionConfigStore()
    @StateObject private var tokenService = TokenService(
        serverUrl: "",              // Temporary initial value
        authenticationUrl: ""       // Temporary initial value
    )

    init() {
        // Read values directly from UserDefaults instead of using the @AppStorage properties.
        let storedServerUrl = UserDefaults.standard.string(forKey: "serverUrl") ?? ""
        let storedAuthenticationUrl = UserDefaults.standard.string(forKey: "authenticationUrl") ?? ""
        _tokenService = StateObject(wrappedValue: TokenService(serverUrl: storedServerUrl,
                                                               authenticationUrl: storedAuthenticationUrl))

    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tokenService)
                .environmentObject(sessionConfigStore)
        }
    }
}
