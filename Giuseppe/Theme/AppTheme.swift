import SwiftUI

enum AppTheme: String, CaseIterable {
    case blue
    case green
    case teal
    case amber

    var displayName: String {
        switch self {
        case .blue:  "经典蓝"
        case .green: "财富绿"
        case .teal:  "青蓝"
        case .amber: "暖金"
        }
    }

    var primaryColor: Color {
        switch self {
        case .blue:  Color(hex: "007AFF")
        case .green: Color(hex: "34C759")
        case .teal:  Color(hex: "5AC8FA")
        case .amber: Color(hex: "FF9500")
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}

@Observable
final class ThemeManager {
    var currentTheme: AppTheme {
        didSet { UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme") }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "appTheme") ?? ""
        currentTheme = AppTheme(rawValue: raw) ?? .blue
    }
}
