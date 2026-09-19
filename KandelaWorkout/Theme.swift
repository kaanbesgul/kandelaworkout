import SwiftUI

extension Color {
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum Theme {
    static let background = Color(hex: "0E0E12")
    static let surface = Color(hex: "17171D")
    static let surfaceElevated = Color(hex: "1C1C24")
    static let fill = Color(hex: "26262E")
    static let fillStrong = Color(hex: "3A3A45")
    static let border = Color(hex: "33333D")
    static let textPrimary = Color(hex: "F5F4F2")
    static let textSecondary = Color(hex: "8E8B95")
    static let textTertiary = Color(hex: "6F6C77")
    static let accent = Color(hex: "FF7A1A")
    static let accentSecondary = Color(hex: "FFB020")
}
