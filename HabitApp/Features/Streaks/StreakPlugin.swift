import Foundation
import SwiftData
import SwiftUI

@MainActor
final class StreakPlugin: DataPlugin, ViewPlugin {
    private let config: AppConfig
    var isEnabled: Bool { config.enableStreaks }
    var models: [any PersistentModel.Type] { [HabitStreak.self] }

    nonisolated required init(config: AppConfig) { self.config = config }

    nonisolated func willDeleteHabit(_ habit: Habit) async {
        await StreakStorage.deleteStreak(for: habit.id)
    }

    nonisolated func didDeleteHabit(habitId: UUID) async { }

    nonisolated func habitCompletionDidChange(
        habitId: UUID,
        isCompleted: Bool,
        completionDate: Date?
    ) async {
        await MainActor.run {
            guard self.isEnabled else { return }
            StreakStorage.applyCompletionChange(habitId: habitId, isCompleted: isCompleted)
        }
    }

    func habitRowView(for habit: Habit) -> AnyView {
        AnyView(StreakRowView(habitId: habit.id, isEnabled: isEnabled))
    }

    func habitDetailView(for habit: Binding<Habit>) -> AnyView {
        AnyView(StreakDetailView(habitId: habit.wrappedValue.id, isEnabled: isEnabled))
    }

    func settingsView() -> AnyView {
        AnyView(StreakSettingsView(config: config))
    }
}
