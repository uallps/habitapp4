import SwiftUI

struct NotesSettingsView: View {
    @ObservedObject var config: AppConfig

    var body: some View {
        Section("Notas Diarias") {
            Toggle("Habilitar", isOn: $config.enableDailyNotes)
            if config.enableDailyNotes {
                Text("Añade notas diarias a cada hábito para registrar tu progreso")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}