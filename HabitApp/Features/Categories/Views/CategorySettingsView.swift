import SwiftUI

struct CategorySettingsView: View {
    @ObservedObject var config: AppConfig

    var body: some View {
        Section("Categorías") {
            Toggle("Habilitar", isOn: $config.enableCategories)
            if config.enableCategories {
                Text("Organiza tus hábitos con categorías personalizadas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}