import Foundation
import SwiftData

@Model
final class HabitChain: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdDate: Date

    init(id: UUID = UUID(), name: String, createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.createdDate = createdDate
    }
}