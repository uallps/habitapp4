import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var categories: [HabitCategory] = []
    @State private var newName = ""
    @State private var selectedColorHex = "#3B82F6"
    @State private var selectedIcon = "tag.fill"

    let onDismiss: () -> Void

    let colorOptions = [
        ("Azul", "#3B82F6"),
        ("Verde", "#10B981"),
        ("Morado", "#8B5CF6"),
        ("Naranja", "#F59E0B"),
        ("Rosa", "#EC4899"),
        ("Rojo", "#EF4444")
    ]

    let iconOptions = [
        "tag.fill", "star.fill", "heart.fill", "bolt.fill",
        "leaf.fill", "flame.fill", "book.fill", "music.note"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Nueva Categoría") {
                    TextField("Nombre", text: $newName)

                    Picker("Color", selection: $selectedColorHex) {
                        ForEach(colorOptions, id: \.1) { name, hex in
                            HStack {
                                Circle().fill(Color(hex: hex)).frame(width: 20, height: 20)
                                Text(name)
                            }
                            .tag(hex)
                        }
                    }

                    Picker("Icono", selection: $selectedIcon) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon).tag(icon)
                        }
                    }

                    Button("Añadir") {
                        CategoryStorage.addCategory(name: newName, colorHex: selectedColorHex, icon: selectedIcon)
                        newName = ""
                        Task { await load() }
                    }
                    .disabled(newName.isEmpty)
                }

                Section("Existentes") {
                    ForEach(categories) { category in
                        HStack {
                            Image(systemName: category.icon).foregroundColor(category.color)
                            Text(category.name)
                            Spacer()
                            Circle().fill(category.color).frame(width: 12, height: 12)
                        }
                    }
                    .onDelete { offsets in
                        CategoryStorage.deleteCategories(categories, at: offsets)
                        Task { await load() }
                    }
                }
            }
            .navigationTitle("Categorías")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
            .task { await load() }
        }
    }

    @MainActor private func load() async {
        categories = CategoryStorage.fetchCategories()
    }
}