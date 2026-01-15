//
//  ViewPlugin.swift
//  TaskApp
//

import Foundation
import SwiftUI

protocol ViewPlugin: FeaturePlugin {
    func habitRowView(for habit: Habit) -> AnyView
    func habitDetailView(for habit: Binding<Habit>) -> AnyView
    func settingsView() -> AnyView
}
