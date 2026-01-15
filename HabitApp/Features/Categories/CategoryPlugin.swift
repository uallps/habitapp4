import Foundation
import SwiftData
import SwiftUI

@MainActor
final class CategoryPlugin: DataPlugin, ViewPlugin {
    private let config: AppConfig
    var models: [any PersistentModel.Type] { [HabitCategory.self, HabitCategoryAssignment.self] }
    var isEnabled: Bool { config.enableCategories }

    required init(config: AppConfig) { self.config = config }

    func willDeleteHabit(_ habit: Habit) async {
        await CategoryStorage.deleteAssignments(for: habit.id)
    }

    func didDeleteHabit(habitId: UUID) async { }

    func habitRowView(for habit: Habit) -> AnyView {
        AnyView(CategoryRowView(habitId: habit.id, isEnabled: isEnabled))
    }

    func habitDetailView(for habit: Binding<Habit>) -> AnyView {
        AnyView(CategoryDetailView(habitId: habit.id, isEnabled: isEnabled))
    }

    func settingsView() -> AnyView {
        AnyView(CategorySettingsView(config: config))
    }
}
