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
        self.plugins = PluginRegistry.shared.createPluginInstances(config: self)
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