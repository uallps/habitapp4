import Foundation
import SwiftData
import SwiftUI

@Model
final class HabitCategory: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var icon: String

    init(name: String, colorHex: String = "#4F46E5", icon: String = "tag.fill") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
    }

    var color: Color { Color(hex: colorHex) }
}