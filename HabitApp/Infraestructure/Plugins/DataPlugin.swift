//
//  DataPlugin.swift
//  TaskApp
//

import Foundation
import SwiftData

@MainActor
protocol DataPlugin: FeaturePlugin {
    var models: [any PersistentModel.Type] { get }

    func willDeleteHabit(_ habit: Habit) async
    func didDeleteHabit(habitId: UUID) async

    func habitCompletionDidChange(
        habitId: UUID,
        isCompleted: Bool,
        completionDate: Date?
    ) async
}

extension DataPlugin {
    func willDeleteHabit(_ habit: Habit) async { }
    func didDeleteHabit(habitId: UUID) async { }
    func habitCompletionDidChange(
        habitId: UUID,
        isCompleted: Bool,
        completionDate: Date?
    ) async { }
}
