import SwiftUI

struct StatsDetailView: View {
    let habit: Habit
    let isEnabled: Bool

    @State private var stats = HabitStats(completionRate: 0, totalCompletions: 0, currentStreak: 0, lastSevenDays: [])

    var body: some View {
        if isEnabled {
            Section("Estadísticas") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Tasa de Finalización", systemImage: "chart.pie.fill")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.0f%%", stats.completionRate * 100))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    ProgressView(value: stats.completionRate).tint(.green)
                }
                .padding(.vertical, 4)

                LabeledContent {
                    Text("\(stats.totalCompletions) veces").foregroundColor(.secondary)
                } label: {
                    Label("Total Completado", systemImage: "checkmark.circle.fill")
                }

                LabeledContent {
                    Text("\(daysSinceCreation) días").foregroundColor(.secondary)
                } label: {
                    Label("Días Activo", systemImage: "calendar")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Últimos 7 Días", systemImage: "calendar.badge.clock")
                        .font(.subheadline)

                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { index in
                            VStack(spacing: 4) {
                                Text(dayLabel(for: index))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Circle()
                                    .fill(stats.lastSevenDays.indices.contains(index) && stats.lastSevenDays[index] ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if stats.lastSevenDays.indices.contains(index), stats.lastSevenDays[index] {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .task { await load() }
        }
    }

    private var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: habit.createdDate, to: Date()).day ?? 0
    }

    private func dayLabel(for index: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -(6 - index), to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }

    private func load() async {
        stats = StatsCalculator.calculate(for: habit)
    }
}