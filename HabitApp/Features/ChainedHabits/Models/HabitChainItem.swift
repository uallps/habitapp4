import Foundation
import SwiftData

@Model
final class HabitChainItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var chainId: UUID
    var habitId: UUID
    var position: Int

    init(id: UUID = UUID(), chainId: UUID, habitId: UUID, position: Int) {
        self.id = id
        self.chainId = chainId
        self.habitId = habitId
        self.position = position
    }
}