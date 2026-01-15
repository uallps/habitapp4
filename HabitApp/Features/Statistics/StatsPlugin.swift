import SwiftUI
import SwiftData

@MainActor
final class StatsPlugin: ViewPlugin {
    private let config: AppConfig
    var models: [any PersistentModel.Type] { [] }
    var isEnabled: Bool { config.enableStatistics }

    nonisolated required init(config: AppConfig) { self.config = config }

    func habitRowView(for habit: Habit) -> AnyView {
        AnyView(EmptyView())
    }

    func habitDetailView(for habit: Binding<Habit>) -> AnyView {
        AnyView(StatsDetailView(habit: habit.wrappedValue, isEnabled: isEnabled))
    }

    func settingsView() -> AnyView {
        AnyView(StatsSettingsView(config: config))
    }
}