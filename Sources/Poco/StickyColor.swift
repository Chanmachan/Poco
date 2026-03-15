import SwiftUI

// MARK: - Color Helpers

extension Color {
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.hasPrefix("#") ? String(sanitized.dropFirst()) : sanitized
        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - StickyColor

enum StickyColor: String, CaseIterable {
    case yellow = "#FFF9C4"
    case blue   = "#E3F2FD"
    case green  = "#E8F5E9"
    case pink   = "#FCE4EC"
    case white  = "#FAFAFA"

    var displayName: String {
        switch self {
        case .yellow: return "🟡 黄"
        case .blue:   return "🔵 青"
        case .green:  return "🟢 緑"
        case .pink:   return "🩷 ピンク"
        case .white:  return "⬜ 白"
        }
    }

    var accentHex: String {
        switch self {
        case .yellow: return "#E6952A"
        case .blue:   return "#1565C0"
        case .green:  return "#2E7D32"
        case .pink:   return "#C62828"
        case .white:  return "#9E9E9E"
        }
    }

    var backgroundColor: Color { Color(hex: rawValue) }
    var accentColor: Color     { Color(hex: accentHex) }

    static func from(_ hex: String) -> StickyColor {
        StickyColor(rawValue: hex) ?? .yellow
    }
}
