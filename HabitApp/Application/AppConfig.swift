//
//  AppConfig.swift
//  TaskApp
//
//  Created by Francisco José García García on 15/10/25.
//
import SwiftUI
import SwiftData
import Combine

@MainActor
class AppConfig: ObservableObject {
    // Toggles núcleo heredados
    @AppStorage("showDueDates") var showDueDates: Bool = true
    @AppStorage("showPriorities") var showPriorities: Bool = true

    // Toggles de plugins
    @AppStorage("enableReminders")   var enableReminders: Bool = false
    @AppStorage("enableStreaks")     var enableStreaks: Bool = false
    @AppStorage("enableDailyNotes")  var enableDailyNotes: Bool = false
    @AppStorage("enableCategories")  var enableCategories: Bool = false
    @AppStorage("enableStatistics")  var enableStatistics: Bool = false

    @AppStorage("storageType") var storageType: StorageType = .swiftData

    private var plugins: [FeaturePlugin] = []

    init() {
        if UserDefaults.standard.object(forKey: "storageType") == nil {
        storageType = .swiftData
         }
        // Descubrir y registrar plugins automáticamente
        let discoveredPlugins = PluginDiscovery.discoverPlugins()
        for pluginType in discoveredPlugins {
            PluginRegistry.shared.register(pluginType)
        }
        // Crear instancias de los plugins
        PluginRegistry.shared.clearAll()

        let basePlugins: [FeaturePlugin.Type] = [
            CategoryPlugin.self,
            ReminderPlugin.self,
            StreakPlugin.self,
            NotesPlugin.self,
            StatsPlugin.self,
        ]

        for t in basePlugins { PluginRegistry.shared.register(t) }

        #if PREMIUM
        // Rewards/ChainedHabits dependen de SwiftData; si el usuario dejó JSON guardado en AppStorage,
        // forzamos SwiftData en la build Premium para que funcionen.
        if storageType != .swiftData {
            storageType = .swiftData
        }
        PluginRegistry.shared.register(RewardsPlugin.self)
        PluginRegistry.shared.register(ChainedHabitsPlugin.self)
        #endif

        self.plugins = PluginRegistry.shared.createPluginInstances(config: self)
        print("Plugins instanciados: \(PluginRegistry.shared.count)")
        print(PluginRegistry.shared.pluginInstances)
        print("storageType:", storageType)
        print("SwiftDataContext.shared nil?", SwiftDataContext.shared == nil)
    }

    private lazy var swiftDataProvider: SwiftDataStorageProvider = {
        var schemas: [any PersistentModel.Type] = [Habit.self]
        schemas.append(contentsOf: PluginRegistry.shared.getEnabledModels(from: plugins))
        let schema = Schema(schemas)
        return SwiftDataStorageProvider(schema: schema)
    }()

    var storageProvider: StorageProvider {
        switch storageType {
        case .swiftData: return swiftDataProvider
        case .json:      return JSONStorageProvider.shared
        }
    }
}

enum StorageType: String, CaseIterable, Identifiable {
    case swiftData = "SwiftData Storage"
    case json      = "JSON Storage"
    var id: String { rawValue }
}