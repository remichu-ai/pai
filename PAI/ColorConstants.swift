import SwiftUI

struct ColorConstants {
    // Custom colors with hex codes
    static let settingsBlueGrey = Color(hex: "F0F3F6") // Light blueish-grey from top right button
    static let buttonShadow = Color(hex: "D0D8E0").opacity(0.4) // Reduced opacity from 0.5 to 0.4
    
    // Colors only - no view modifiers
    static let buttonBackground = settingsBlueGrey
    static let buttonBackgroundInactive = Color.white
    
    // New hold-to-talk colors
    static let holdToTalkActive = Color(hex: "B3D7FF")   // a warm orange
    static let holdToTalkIdle   = Color(hex: "007AFF")   // lighter orange
    
    // connect button
    static let connectButtonBackground = Color(hex: "69778A")
    
    static let buttonContent = Color(hex: "69778A") // Darker grey for icons
    static let controlBackgroundBase = settingsBlueGrey.opacity(0.95)
    static let toggleActiveColor = Color.blue
    static let toggleInactiveColor = Color(hex: "69778A")
    
    // View modifier functions
    static func controlBackgroundWithMaterial() -> some View {
        settingsBlueGrey
            .opacity(0.85)
            .background(.thinMaterial)
    }
    
    static let visualizerBackground = Color(hex: "D8DFE8")
}
