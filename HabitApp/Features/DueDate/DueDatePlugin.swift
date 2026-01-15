//
//  DueDatePlugin.swift
//  TaskApp
//
//  Created by Francisco José García García on 11/11/25.
//
import Foundation
import SwiftData
import SwiftUI

/// Plugin que gestiona las fechas de vencimiento (DESHABILITADO para HabitApp)
/// Este plugin sirve como ejemplo de la arquitectura
class DueDatePlugin: DataPlugin, ViewPlugin {
    
    // MARK: - FeaturePlugin Properties
    
    var models: [any PersistentModel.Type] {
        return [TaskDueDate.self]
    }
    
    // DESHABILITADO: Este plugin era para la app de tareas
    var isEnabled: Bool {
        return false
    }
    
    // MARK: - Private Properties
    
    private let config: AppConfig
    
    // MARK: - Initialization
    
    required init(config: AppConfig) {
        self.config = config
        print("🗓️ DueDatePlugin inicializado - DESHABILITADO (ejemplo)")
    }
    
    // MARK: - DataPlugin Methods
    
    func willDeleteHabit(_ habit: Habit) async {
        // No hace nada - plugin deshabilitado
    }
    
    func didDeleteHabit(habitId: UUID) async {
        // No hace nada - plugin deshabilitado
    }
    
    // MARK: - ViewPlugin Methods
    
    func habitRowView(for habit: Habit) -> AnyView { AnyView(EmptyView()) }
    
    func habitDetailView(for habit: Binding<Habit>) -> AnyView { AnyView(EmptyView()) }
    
    func settingsView() -> AnyView {
        AnyView(
            Section("Due Date Plugin (Ejemplo)") {
                Text("Plugin deshabilitado - Ejemplo de arquitectura")
                    .foregroundColor(.secondary)
            }
        )
    }
}
