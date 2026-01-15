import Foundation
import SwiftData
import SwiftUI

@MainActor
final class NotesPlugin: DataPlugin, ViewPlugin {
    private let config: AppConfig
    var models: [any PersistentModel.Type] { [HabitNote.self] }
    var isEnabled: Bool { config.enableDailyNotes }

    nonisolated required init(config: AppConfig) { self.config = config }

    nonisolated func willDeleteHabit(_ habit: Habit) async {
        await NotesStorage.deleteNotes(for: habit.id)
    }

    nonisolated func didDeleteHabit(habitId: UUID) async { }

    func habitRowView(for habit: Habit) -> AnyView {
        AnyView(NotesRowView(habitId: habit.id, isEnabled: isEnabled))
    }

    func habitDetailView(for habit: Binding<Habit>) -> AnyView {
        AnyView(NotesDetailView(habitId: habit.wrappedValue.id, isEnabled: isEnabled))
    }

    func settingsView() -> AnyView {
        AnyView(NotesSettingsView(config: config))
    }
}
