import SwiftUI
import SwiftData

struct StreakRowView: View {
    let habitId: UUID
    let isEnabled: Bool

    @State private var streak: HabitStreak?

    var body: some View {
        Group {
            if isEnabled, let streak, streak.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption2)
                    Text("\(streak.currentStreak)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(6)
            }
        }
        .task { await load() }
        .onChange(of: habitId) { _, _ in Task { await load() } }
    }

    private func load() async {
        streak = StreakStorage.fetchStreak(habitId: habitId)
    }
}