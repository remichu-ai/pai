import SwiftUI

@main
struct PAIApp: App {
    @StateObject private var sessionConfigStore = SessionConfigStore()
    private var tokenService: TokenService = .init()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tokenService)
                .environmentObject(sessionConfigStore)
        }
    }
}
