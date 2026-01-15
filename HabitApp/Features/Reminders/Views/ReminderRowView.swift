import SwiftUI
import SwiftData

struct ReminderRowView: View {
    let habitId: UUID
    let isEnabled: Bool

    @State private var hasActiveReminder = false

    var body: some View {
        Group {
            if isEnabled && hasActiveReminder {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .task { await check() }
    }

    private func check() async {
        guard let ctx = SwiftDataContext.shared else { return }
        let fetch = FetchDescriptor<HabitReminder>(
            predicate: #Predicate { $0.habitId == habitId && $0.isEnabled }
        )
        hasActiveReminder = (try? ctx.fetch(fetch).first) != nil
    }
}