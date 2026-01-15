import Foundation
import SwiftData

@Model
final class XPProfile: Identifiable {
    @Attribute(.unique) var id: UUID
    var totalXP: Int
    var lastDailyClaim: Date?

    init(id: UUID = UUID(), totalXP: Int = 0, lastDailyClaim: Date? = nil) {
        self.id = id
        self.totalXP = totalXP
        self.lastDailyClaim = lastDailyClaim
    }
}