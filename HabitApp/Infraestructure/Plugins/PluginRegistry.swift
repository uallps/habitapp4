//
//  PluginRegistry.swift
//  TaskApp
//
//  Created by Francisco José García García on 11/11/25.
//
import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
/// Registro centralizado de plugins de características
class PluginRegistry: ObservableObject {
    /// Instancia compartida del registro (Singleton)
    static let shared = PluginRegistry()
    
    /// Array de tipos de plugins registrados
    private(set) var registeredPlugins: [FeaturePlugin.Type] = []
    
    /// Instancias de plugins creadas
    @Published private(set) var pluginInstances: [FeaturePlugin] = []
    
    private init() {}
    
    /// Registra un nuevo tipo de plugin
    /// - Parameter pluginType: Tipo del plugin a registrar
    func register(_ pluginType: FeaturePlugin.Type) {
        guard !registeredPlugins.contains(where: { $0 == pluginType }) else {
            print("⚠️ Plugin \(pluginType) ya está registrado")
            return
        }
        
        registeredPlugins.append(pluginType)
        print("✅ Plugin registrado: \(pluginType)")
    }
    
    /// Crea instancias de todos los plugins registrados
    /// - Parameter config: Configuración de la aplicación
    /// - Returns: Array de instancias de plugins
    func createPluginInstances(config: AppConfig) -> [FeaturePlugin] {
        pluginInstances = registeredPlugins.map { pluginType in
            pluginType.init(config: config)
        }
        return pluginInstances
    }
    
    /// Obtiene todos los modelos de los plugins habilitados
    /// - Parameter plugins: Array de instancias de plugins
    /// - Returns: Array de tipos de modelos persistentes
    func getEnabledModels(from plugins: [FeaturePlugin]) -> [any PersistentModel.Type] {
        return plugins
            .compactMap { plugin -> [any PersistentModel.Type]? in
                guard plugin.isEnabled, let dataPlugin = plugin as? DataPlugin else { return nil }
                return dataPlugin.models
            }
            .flatMap { $0 }
    }
    
    /// Notifica a todos los DataPlugins que un hábito va a ser eliminado
    /// - Parameter habit: El hábito que será eliminado
    nonisolated func notifyHabitWillBeDeleted(_ habit: Habit) async {
        let dataPlugins: [DataPlugin] = await MainActor.run {
            pluginInstances.compactMap { $0 as? DataPlugin }.filter { $0.isEnabled }
        }

        await withTaskGroup(of: Void.self) { group in
            for plugin in dataPlugins {
                group.addTask { await plugin.willDeleteHabit(habit) }
            }
        }
    }
    
    /// Notifica a todos los DataPlugins que un hábito ha sido eliminado
    /// - Parameter habitId: ID del hábito eliminado
    nonisolated func notifyHabitDidDelete(habitId: UUID) async {
        let dataPlugins: [DataPlugin] = await MainActor.run {
            pluginInstances.compactMap { $0 as? DataPlugin }.filter { $0.isEnabled }
        }

        await withTaskGroup(of: Void.self) { group in
            for plugin in dataPlugins {
                group.addTask { await plugin.didDeleteHabit(habitId: habitId) }
            }
        }
    }
    
    /// Notifica a todos los DataPlugins que la finalización de un hábito ha cambiado
    /// - Parameters:
    ///   - habitId: ID del hábito cuyo estado de finalización ha cambiado
    ///   - isCompleted: Nuevo estado de finalización del hábito
    ///   - completionDate: Nueva fecha de finalización, si corresponde
    nonisolated func notifyHabitCompletionDidChange(
        habitId: UUID,
        isCompleted: Bool,
        completionDate: Date?
    ) async {
        let dataPlugins: [DataPlugin] = await MainActor.run {
            pluginInstances.compactMap { $0 as? DataPlugin }
                .filter { $0.isEnabled }
        }

        await withTaskGroup(of: Void.self) { group in
            for plugin in dataPlugins {
                group.addTask {
                    await plugin.habitCompletionDidChange(
                        habitId: habitId,
                        isCompleted: isCompleted,
                        completionDate: completionDate
                    )
                }
            }
        }
    }
    
    /// Limpia todos los plugins registrados (útil para testing)
    func clearAll() {
        registeredPlugins.removeAll()
        pluginInstances.removeAll()
        print("🗑️ Todos los plugins han sido eliminados del registro")
    }
    
    /// Obtiene el número de plugins registrados
    var count: Int {
        return registeredPlugins.count
    }
    
    /// Obtiene todas las vistas de fila de plugins para un hábito específico
    /// - Parameter habit: El hábito para el cual obtener las vistas
    /// - Returns: Array de vistas proporcionadas por los plugins habilitados
    func getHabitRowViews(for habit: Habit) -> [AnyView] {
        pluginInstances
            .compactMap { $0 as? any ViewPlugin }
            .filter { $0.isEnabled }
            .map { $0.habitRowView(for: habit) }
    }
    
    /// Obtiene todas las vistas de detalle de plugins para un hábito específico
    /// - Parameter habit: Binding al hábito para el cual obtener las vistas
    /// - Returns: Array de vistas proporcionadas por los plugins habilitados
    func getHabitDetailViews(for habit: Binding<Habit>) -> [AnyView] {
        pluginInstances
            .compactMap { $0 as? any ViewPlugin }
            .filter { $0.isEnabled }
            .map { $0.habitDetailView(for: habit) }
    }
    
    /// Obtiene todas las vistas de configuración de los plugins
    /// - Returns: Array de vistas de configuración proporcionadas por los plugins
    func getPluginSettingsViews() -> [AnyView] {
        pluginInstances
            .compactMap { $0 as? any ViewPlugin }
            .map { $0.settingsView() }
    }
    
    func register(config: AppConfig) {
        // Registrar plugins según configuración
        pluginInstances.removeAll()
        
        // Ejemplo: Registrar CategoryPlugin si está habilitado
        if config.enableCategories {
            let categoryPlugin = CategoryPlugin(config: config)
            if categoryPlugin.isEnabled {
                pluginInstances.append(categoryPlugin)
            }
        }
        
        // Registrar otros plugins aquí...
    }
    
    /// Obtiene todos los modelos de los plugins habilitados (solo DataPlugins)
    func getModels() -> [any PersistentModel.Type] {
        return pluginInstances
            .compactMap { $0 as? DataPlugin }
            .flatMap { $0.models }
    }
}
