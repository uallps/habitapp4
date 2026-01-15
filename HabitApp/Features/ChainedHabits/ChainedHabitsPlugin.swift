#if PREMIUM
import Foundation
import SwiftData

@MainActor
final class ChainedHabitsPlugin: DataPlugin {
    private let config: AppConfig
    var isEnabled: Bool { true } // luego lo conectamos a un toggle si quieres
    var models: [any PersistentModel.Type] { [HabitChain.self, HabitChainItem.self] }

    required init(config: AppConfig) { self.config = config }

    func willDeleteHabit(_ habit: Habit) async {
        await MainActor.run {
            ChainedHabitsStorage.deleteLinks(for: habit.id)
        }
    }

    func didDeleteHabit(habitId: UUID) async { }
}
#endif