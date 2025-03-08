import SwiftUI

struct ColorConstants {
    // MARK: - Base Colors
    // Dark mode colors remain the same:
    static let darkModeBackground       = Color(hex: "121212") // Very dark grey
    static let darkModeCardBackground   = Color(hex: "1E1E1E") // Slightly lighter than background
    static let darkModeElementBackground = Color(hex: "2A2A2A") // For controls and interactive elements
    
    // Updated light mode colors for better clarity and contrast:
    static let lightModeBackground      = Color(hex: "F8F9FA") // Softer off-white
    static let lightModeElementBackground = Color(hex: "F2F4F6") // Slightly darker than background
    // (Previously used "settingsBlueGrey" can be replaced or repurposed below.)

    // MARK: - Dynamic Backgrounds
    static func dynamicBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkModeBackground : lightModeBackground
    }
    
    static func dynamicButtonBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkModeElementBackground : lightModeElementBackground
    }
    
    static func dynamicControlBackground(_ colorScheme: ColorScheme) -> Color {
        // Same as above, or you can differentiate controls vs. buttons
        colorScheme == .dark ? darkModeCardBackground : lightModeElementBackground
    }
    
    // MARK: - Button Content & Shadows
    static func buttonShadow(_ colorScheme: ColorScheme) -> Color {
        // Keep a darker shadow in dark mode, a softer one in light mode
        colorScheme == .dark
        ? Color.black.opacity(0.6)
        : Color(hex: "A0AEC0").opacity(0.4)  // A subtle blue-gray shadow
    }
    
    static func buttonContent(_ colorScheme: ColorScheme) -> Color {
        // Dark mode: white with a bit of opacity
        // Light mode: darker text color for good contrast
        colorScheme == .dark
        ? Color.white.opacity(0.9)
        : Color(hex: "2D3748")  // A deeper gray-blue for text/icons
    }
    
    // For inactive states (e.g. disabled or toggled off):
    static func buttonBackgroundInactive(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
        ? Color(hex: "3A3A3A")
        : Color.white
    }
    
    // MARK: - Toggle Colors
    static let toggleActiveColor = Color.blue
    static func toggleInactiveColor(for colorScheme: ColorScheme) -> Color {
        // Dark mode: a lighter white with opacity
        // Light mode: a neutral/dark gray
        colorScheme == .dark
        ? Color.white.opacity(0.7)
        : Color(hex: "4A4A4A")
    }
    
    // MARK: - Connect Button
    static let connectButtonBackground = Color.blue
    
    // MARK: - Audio Visualizer
    static func visualizerBackground(_ colorScheme: ColorScheme) -> Color {
        // Keep the dark mode logic the same
        colorScheme == .dark
        ? Color(hex: "2A2A2A").opacity(0.9)
        : Color(hex: "E2E6EA") // Lighten up from D8DFE8 for a sleeker look
    }
    
    // MARK: - Transcript Bubble Colors
    // If you like how dark mode currently looks, leave it.
    // Just ensure the light mode is more consistent.
    static func transcriptBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
        ? Color.black.opacity(0.8)
        : Color.white.opacity(0.95)
    }
    
    static func transcriptUserBubble(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
        ? Color.blue.opacity(0.6)
        : Color.blue.opacity(0.3)
    }
    
    static func transcriptAIBubble(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
        ? Color.white.opacity(0.1)
        : Color.gray.opacity(0.2)
    }
    
    // If you still need a separate "settingsBlueGrey" or similar, you can keep it:
    static let settingsBlueGrey = Color(hex: "ECEFF4")
    
    // MARK: - Control Background with Material
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
                // Slightly adjust to match the new light mode background
                lightModeElementBackground
                    .opacity(0.85)
                    .background(.thinMaterial)
            }
        }
    }
}
