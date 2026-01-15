import SwiftUI

struct StatsSettingsView: View {
    @ObservedObject var config: AppConfig
    @State private var totalHabits = 0
    @State private var activeHabits = 0

    var body: some View {
        Section("Estadísticas") {
            Toggle("Habilitar", isOn: $config.enableStatistics)

            if config.enableStatistics {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Total de Hábitos", systemImage: "list.bullet")
                        Spacer()
                        Text("\(totalHabits)").fontWeight(.semibold)
                    }

                    HStack {
                        Label("Hábitos Activos", systemImage: "checkmark.circle")
                        Spacer()
                        Text("\(activeHabits)")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                .font(.subheadline)
                .padding(.vertical, 4)

                Text("Visualiza métricas detalladas de progreso")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .task { await load() }
    }

    private func load() async {
        let result = StatsCalculator.loadGlobalStats()
        totalHabits = result.totalHabits
        activeHabits = result.activeHabits
    }
}