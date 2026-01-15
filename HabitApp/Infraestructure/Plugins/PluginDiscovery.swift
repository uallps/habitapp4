//
//  PluginDiscovery.swift
//  TaskApp
//
//  Created by GitHub Copilot on 12/11/25.
//

import Foundation
import Combine

/// Clase responsable de descubrir automáticamente plugins que implementan FeaturePlugin
class PluginDiscovery {
    
    /// Descubre automáticamente todas las clases que implementan FeaturePlugin
    /// - Returns: Array de tipos de plugins encontrados
    static func discoverPlugins() -> [FeaturePlugin.Type] {
        var plugins: [FeaturePlugin.Type] = []
        
        print("🔍 Iniciando discovery optimizado de plugins...")
        
        // Obtener el bundle principal de la app
        guard let executableName = Bundle.main.executablePath?.components(separatedBy: "/").last else {
            print("⚠️ No se pudo obtener el nombre del ejecutable")
            return []
        }
        
        print("� Ejecutable: \(executableName)")
        
        // Obtener todas las clases del runtime
        let expectedClassCount = objc_getClassList(nil, 0)
        let allClasses = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(expectedClassCount))
        let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
        let actualClassCount: Int32 = objc_getClassList(autoreleasingAllClasses, expectedClassCount)
        
        print("📊 Total de clases en runtime: \(actualClassCount)")
        
        var checkedCount = 0
        var skippedCount = 0
        var pluginCandidates = 0
        
        for i in 0 ..< actualClassCount {
            if let currentClass = allClasses[Int(i)] {
                let className = NSStringFromClass(currentClass)
                
                // OPTIMIZACIÓN 1: Filtrar solo clases de nuestro módulo/app
                guard className.hasPrefix(executableName) else {
                    skippedCount += 1
                    continue
                }
                
                checkedCount += 1
                print("� Revisando clase: \(className)")
                
                // Verificar si la clase implementa FeaturePlugin
                if let pluginType = currentClass as? FeaturePlugin.Type {
                    pluginCandidates += 1
                    print("🎯 Candidato encontrado: \(String(describing: pluginType))")
                    
                    plugins.append(pluginType)
                    print("✅ Plugin válido agregado: \(String(describing: pluginType))")
                }
            }
        }
        
        allClasses.deallocate()
        
        print("📈 Resumen:")
        print("   • Total runtime: \(actualClassCount) clases")
        print("   • Omitidas (filtros): \(skippedCount) clases")
        print("   • Revisadas: \(checkedCount) clases")
        print("   • Candidatos: \(pluginCandidates)")
        print("   • Plugins válidos: \(plugins.count)")
        print("🔍 Plugins descubiertos: \(plugins.map { String(describing: $0) })")
        
        return plugins
    }
}
