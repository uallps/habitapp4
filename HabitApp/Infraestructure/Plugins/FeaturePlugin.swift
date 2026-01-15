//
//  FeaturePlugin.swift
//  TaskApp
//

import Foundation

protocol FeaturePlugin {
    init(config: AppConfig)
    var isEnabled: Bool { get }
}

