import SwiftUI
import SwiftData

struct StreakDetailView: View {
    let habitId: UUID
    let isEnabled: Bool

    @State private var streak: HabitStreak?

    var body: some View {
        if isEnabled {
            Section("Rachas") {
                if let streak {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Racha Actual", systemImage: "flame.fill").font(.subheadline)
                            Text("\(streak.currentStreak) días")
                                .font(.title2).fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("Mejor Racha", systemImage: "trophy.fill").font(.subheadline)
                            Text("\(streak.bestStreak) días")
                                .font(.title3).fontWeight(.semibold)
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(.vertical, 8)

                    if let last = streak.lastCompletedDate {
                        LabeledContent("Última vez") { Text(last, style: .date).foregroundColor(.secondary) }
                    }

                    LabeledContent("Total completado") {
                        Text("\(streak.completionDates.count) veces").foregroundColor(.secondary)
                    }
                } else {
                    Text("Cargando racha...").foregroundColor(.secondary)
                }
            }
            .task { await loadOrCreate() }
        }
    }

    private func loadOrCreate() async {
        streak = StreakStorage.loadOrCreateStreak(habitId: habitId)
    }
}