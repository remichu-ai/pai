import SwiftUI

struct ColorConstants {
    // Custom colors with hex codes
    static let settingsBlueGrey = Color(hex: "F0F3F6") // Light blueish-grey from top right button
    static let buttonShadow = Color(hex: "D0D8E0").opacity(0.4) // Reduced opacity from 0.5 to 0.4
    
    // Colors only - no view modifiers
    static let buttonBackground = settingsBlueGrey
    static let buttonContent = Color(hex: "69778A") // Darker grey for icons
    static let controlBackgroundBase = settingsBlueGrey.opacity(0.95)
    static let toggleActiveColor = Color.blue
    static let toggleInactiveColor = Color(hex: "69778A")
    
    // View modifier functions
    static func controlBackgroundWithMaterial() -> some View {
        settingsBlueGrey
            .opacity(0.95)
            .background(.ultraThinMaterial)
    }
    
    static let visualizerBackground = Color(hex: "D8DFE8")
}
