import Foundation
import SwiftData

@MainActor
final class RewardsPlugin: DataPlugin {
    private let config: AppConfig
    var isEnabled: Bool { true }
    var models: [any PersistentModel.Type] { [XPProfile.self] }

    required init(config: AppConfig) { self.config = config }

    func habitCompletionDidChange(
        habitId: UUID,
        isCompleted: Bool,
        completionDate: Date?
    ) async {
        await MainActor.run {
            RewardsStorage.applyHabitCompletionDidChange(habitId: habitId, isCompleted: isCompleted)
        }
    }
}