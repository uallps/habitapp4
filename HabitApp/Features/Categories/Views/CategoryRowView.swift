import SwiftUI

struct CategoryRowView: View {
    let habitId: UUID
    let isEnabled: Bool

    @State private var category: HabitCategory?

    var body: some View {
        Group {
            if isEnabled, let category {
                HStack(spacing: 4) {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                    Text(category.name)
                        .font(.caption)
                        .foregroundColor(category.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(category.color.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .task { await load() }
    }

    @MainActor private func load() async {
        category = CategoryStorage.fetchCategory(for: habitId)
    }
}