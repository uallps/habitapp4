//
//  FeaturePlugin.swift
//  TaskApp
//

import Foundation

@MainActor
protocol FeaturePlugin {
    init(config: AppConfig)
    var isEnabled: Bool { get }
}

