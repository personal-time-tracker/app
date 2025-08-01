import Foundation
import SwiftUI

enum Theme: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: Self { self }

    var displayName: String {
        switch self {
        case .system: "Как в системе"
        case .light: "Светлая"
        case .dark: "Темная"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
} 