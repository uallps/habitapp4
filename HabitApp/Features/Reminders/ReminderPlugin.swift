import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ReminderPlugin: DataPlugin, ViewPlugin {
    private let config: AppConfig
    var models: [any PersistentModel.Type] { [HabitReminder.self] }
    var isEnabled: Bool { config.enableReminders }

    required init(config: AppConfig) {
        self.config = config
        Task { @MainActor in
            await ReminderNotifications.requestPermission()
        }
    }

    func willDeleteHabit(_ habit: Habit) async {
        ReminderStorage.deleteReminders(for: habit.id)
    }

    func didDeleteHabit(habitId: UUID) async { }

    func habitRowView(for habit: Habit) -> AnyView {
        AnyView(ReminderRowView(habitId: habit.id, isEnabled: isEnabled))
    }

    func habitDetailView(for habit: Binding<Habit>) -> AnyView {
        AnyView(ReminderDetailView(habit: habit, isEnabled: isEnabled))
    }

    func settingsView() -> AnyView {
        AnyView(ReminderSettingsView(config: config))
    }
}
