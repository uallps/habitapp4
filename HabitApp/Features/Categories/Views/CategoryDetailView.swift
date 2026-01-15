import SwiftUI

struct CategoryDetailView: View {
    let habitId: UUID
    let isEnabled: Bool

    @State private var categories: [HabitCategory] = []
    @State private var selectedCategoryId: UUID?
    @State private var showingManagement = false

    var body: some View {
        if isEnabled {
            Section("Categoría") {
                Picker("Seleccionar", selection: $selectedCategoryId) {
                    Text("Sin categoría").tag(UUID?.none)
                    ForEach(categories) { category in
                        Label {
                            Text(category.name)
                        } icon: {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                        }
                        .tag(UUID?.some(category.id))
                    }
                }
                .onChange(of: selectedCategoryId) { _, newValue in
                    CategoryStorage.setAssignment(habitId: habitId, categoryId: newValue)
                }

                Button("Gestionar Categorías") { showingManagement = true }
            }
            .task { await load() }
            .sheet(isPresented: $showingManagement) {
                CategoryManagementView {
                    Task { await load() }
                }
            }
        }
    }

    @MainActor private func load() async {
        CategoryStorage.ensureDefaultCategoriesIfNeeded()
        categories = CategoryStorage.fetchCategories()
        selectedCategoryId = CategoryStorage.fetchAssignmentCategoryId(for: habitId)
    }
}