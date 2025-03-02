import SwiftUI

struct ColorConstants {
    // Base colors with improved contrast for dark mode
    static let settingsBlueGrey = Color(hex: "F0F3F6")  // Light blueish-grey
    static let lightModeBackground = Color(hex: "F0F0F0")   // A very light grey
    static let darkModeBackground = Color(hex: "121212")    // Very dark grey instead of pure black
    static let darkModeCardBackground = Color(hex: "1E1E1E")    // Slightly lighter than background
    static let darkModeElementBackground = Color(hex: "2A2A2A") // For controls and interactive elements
    
    // System-aware colors (automatically adapt to light/dark mode)
    static func dynamicBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkModeBackground : lightModeBackground
    }
    
    static func dynamicButtonBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkModeElementBackground : settingsBlueGrey
    }
    
    static func dynamicControlBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkModeCardBackground : settingsBlueGrey
    }
    
    // Button and control styling with improved visibility
    static func buttonShadow(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.6) : Color(hex: "D0D8E0").opacity(0.4)
    }
    
    static func buttonContent(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color(hex: "69778A")
    }
    
    // For inactive states with better contrast
    static func buttonBackgroundInactive(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "3A3A3A") : Color.white
    }
    
    // Accent colors that work in both modes
    static let toggleActiveColor = Color.blue
    static func toggleInactiveColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .light ? Color(hex: "4A4A4A") : Color.white.opacity(0.7)
    }
    
    // Connect button
    static let connectButtonBackground = Color.blue
    
    // Visualizer colors with better contrast
    static func visualizerBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "2A2A2A").opacity(0.9) : Color(hex: "D8DFE8")
    }
    
    // Transcript message colors with improved readability
    static let transcriptUserBG = Color.blue.opacity(0.25)
    static let transcriptAIBG = Color(hex: "333333") // Slightly lighter for dark mode
    static let transcriptUserText = Color.white
    static let transcriptAIText = Color.white
    
    // View modifier functions with dark mode support and better visibility
    static func controlBackgroundWithMaterial(_ colorScheme: ColorScheme) -> some View {
        Group {
            if colorScheme == .dark {
                darkModeCardBackground
                    .opacity(0.95)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            } else {
                settingsBlueGrey
                    .opacity(0.85)
                    .background(.thinMaterial)
            }
        }
    }
}
