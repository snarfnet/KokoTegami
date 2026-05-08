import SwiftUI

enum AppTheme {
    static let night = Color(hex: 0x0B111B)
    static let deep = Color(hex: 0x111B29)
    static let panel = Color(hex: 0x182434)
    static let cream = Color(hex: 0xF5EFE3)
    static let parchment = Color(hex: 0xFFF7E9)
    static let sepia = Color(hex: 0x4B362B)
    static let ink = Color(hex: 0x262421)
    static let waxRed = Color(hex: 0xB94034)
    static let fadedBlue = Color(hex: 0x98A9BB)
    static let warmGray = Color(hex: 0x7B8188)
    static let envelope = Color(hex: 0xD9B978)
    static let stamp = Color(hex: 0xC59A5A)
    static let teal = Color(hex: 0x62D7D4)

    static var nightGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x070A10), Color(hex: 0x101A29), Color(hex: 0x251D22)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
