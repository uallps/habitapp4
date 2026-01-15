import SwiftUI

struct StreakSettingsView: View {
    @ObservedObject var config: AppConfig

    var body: some View {
        Section("Rachas") {
            Toggle("Habilitar", isOn: $config.enableStreaks)
            if config.enableStreaks {
                Text("Rastrea tus rachas de días consecutivos completando hábitos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}