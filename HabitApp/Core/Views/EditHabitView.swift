import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import PhotosUI
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

@MainActor
struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var config: AppConfig

    @Binding var habit: Habit
    let onSave: () -> Void
    let onDelete: () -> Void

    @State private var name: String = ""
    @State private var detail: String = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var isActive: Bool = true

    @State private var selectedIcon: String = "menu_book"
    @State private var imageData: Data?

    @State private var categories: [HabitCategory] = []
    @State private var selectedCategoryId: UUID?
    @State private var showingCategoryPicker = false
    @State private var showingCategoryManagement = false
    @State private var showingIconPicker = false
    @State private var didLoad = false

    #if os(iOS)
    @State private var pickedPhoto: PhotosPickerItem?
    #else
    @State private var showFilePicker = false
    #endif

    private var hasSwiftData: Bool { SwiftDataContext.shared != nil }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 18) {
                    headerMedia

                    field(title: "NOMBRE DEL HÁBITO") {
                        TextField("Nombre", text: $name)
                            .textFieldStyle(.plain)
                    }

                    field(title: "DESCRIPCIÓN") {
                        TextEditor(text: $detail)
                            .frame(minHeight: 96)
                            .scrollContentBackground(.hidden)
                    }

                    if config.enableCategories, hasSwiftData {
                        categoryField
                    }

                    frequencyField

                    if config.enableReminders, hasSwiftData {
                        ReminderEditCard(habitId: habit.id, habitName: name.isEmpty ? habit.name : name)
                    }

                    habitActiveCard

                    Spacer(minLength: 120)
                }
                .padding(16)
            }

            footerBar
        }
        #if os(iOS)
        .background(Color(.systemGroupedBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Editar Hábito").font(.headline)
            }
        }
        #if os(iOS)
        .toolbarBackground(.thinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            loadFromHabit()
            if config.enableCategories, hasSwiftData {
                loadCategories()
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerSheet(selectedCategoryId: $selectedCategoryId)
        }
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView {
                loadCategories()
            }
        }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerSheet(selectedIcon: $selectedIcon)
        }
    }

    // MARK: Header

    private var headerMedia: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .overlay {
                        if let data = imageData, let image = platformImage(from: data) {
                            image.resizable().scaledToFill().clipShape(Circle())
                        } else {
                            Image(systemName: sfSymbol(for: selectedIcon))
                                .font(.system(size: 46, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .overlay { Circle().stroke(Color.white.opacity(0.9), lineWidth: 6) }
                    .clipped()

                Button { showingIconPicker = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.thinMaterial))
                        .overlay { Circle().stroke(Color.primary.opacity(0.06), lineWidth: 1) }
                }
                .buttonStyle(.plain)
            }

            Text("Cambiar icono")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.accentColor)

            HStack(spacing: 14) {
                Button("ELEGIR ICONO") { showingIconPicker = true }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .buttonStyle(.plain)

                Text("|").foregroundStyle(.tertiary)

                #if os(iOS)
                PhotosPicker(selection: $pickedPhoto, matching: .images) {
                    Text("SUBIR FOTO")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .onChange(of: pickedPhoto) { _, newValue in
                    guard let newValue else { return }
                    Task {
                        if let data = try? await newValue.loadTransferable(type: Data.self) {
                            await MainActor.run { imageData = data }
                        }
                    }
                }
                #else
                Button("SUBIR FOTO") { showFilePicker = true }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .buttonStyle(.plain)
                    .fileImporter(
                        isPresented: $showFilePicker,
                        allowedContentTypes: [.image],
                        allowsMultipleSelection: false
                    ) { result in
                        guard case let .success(urls) = result, let url = urls.first else { return }
                        let didStart = url.startAccessingSecurityScopedResource()
                        defer { if didStart { url.stopAccessingSecurityScopedResource() } }
                        imageData = try? Data(contentsOf: url)
                    }
                #endif
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    // MARK: Fields

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORÍA")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)

            HStack(spacing: 12) {
                Button {
                    loadCategories()
                    showingCategoryPicker = true
                } label: {
                    HStack(spacing: 10) {
                        if let selectedCategory {
                            ZStack {
                                Circle().fill(selectedCategory.color.opacity(0.15))
                                Image(systemName: selectedCategory.icon)
                                    .foregroundStyle(selectedCategory.color)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(width: 28, height: 28)

                            Text(selectedCategory.name)
                                .foregroundStyle(.primary)
                                .font(.body.weight(.semibold))
                        } else {
                            Text("Sin categoría")
                                .foregroundStyle(.secondary)
                                .font(.body.weight(.semibold))
                        }

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                Button { showingCategoryManagement = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 52, height: 52)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var frequencyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FRECUENCIA")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)

            Picker("", selection: $frequency) {
                Text("Diaria").tag(HabitFrequency.daily)
                Text("Semanal").tag(HabitFrequency.weekly)
                Text("Mensual").tag(HabitFrequency.monthly)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .tint(Color.accentColor)
            .padding(6)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var habitActiveCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hábito Activo")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Pausar este hábito temporalmente")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isActive)
                .labelsHidden()
                .tint(Color.accentColor)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)

            content()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                }
        }
    }

    // MARK: Footer

    private var footerBar: some View {
        VStack(spacing: 10) {
            Button {
                applyToHabit()

                if config.enableCategories, hasSwiftData {
                    CategoryStorage.setAssignment(habitId: habit.id, categoryId: selectedCategoryId)
                }

                onSave()
                dismiss()
            } label: {
                Label("Guardar Cambios", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.accentColor.opacity(0.25), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)

            Button {
                dismiss()
                onDelete()
            } label: {
                Text("Eliminar Hábito")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.thinMaterial)
    }

    // MARK: Data

    private func loadFromHabit() {
        name = habit.name
        detail = habit.detail
        frequency = habit.frequency
        isActive = habit.isActive
        selectedIcon = habit.iconName ?? "menu_book"
        imageData = habit.imageData

        if config.enableCategories, hasSwiftData {
            selectedCategoryId = CategoryStorage.fetchAssignmentCategoryId(for: habit.id)
        } else {
            selectedCategoryId = nil
        }
    }

    private func applyToHabit() {
        habit.name = name
        habit.detail = detail
        habit.frequency = frequency
        habit.isActive = isActive

        habit.imageData = imageData
        habit.iconName = (imageData == nil) ? selectedIcon : nil
    }

    private var selectedCategory: HabitCategory? {
        guard let id = selectedCategoryId else { return nil }
        return categories.first(where: { $0.id == id })
    }

    @MainActor
    private func loadCategories() {
        guard hasSwiftData else { return }
        CategoryStorage.ensureDefaultCategoriesIfNeeded()
        categories = CategoryStorage.fetchCategories()
    }

    private func sfSymbol(for materialName: String) -> String {
        switch materialName {
        case "menu_book": return "book.fill"
        case "dumbbell": return "dumbbell.fill"
        case "figure.mind.and.body": return "figure.mind.and.body"
        case "drop": return "drop.fill"
        default: return "ellipsis"
        }
    }

    private func platformImage(from data: Data) -> Image? {
        #if os(iOS)
        if let ui = UIImage(data: data) { return Image(uiImage: ui) }
        #else
        if let ns = NSImage(data: data) { return Image(nsImage: ns) }
        #endif
        return nil
    }
}

// MARK: - Sheets

private struct IconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String

    private let icons = ["menu_book", "dumbbell", "figure.mind.and.body", "drop", "ellipsis"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Selecciona un icono")
                    .font(.headline)
                    .padding(.top, 8)

                HStack(spacing: 14) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            Image(systemName: map(icon))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(selectedIcon == icon ? Color.accentColor : Color.secondary)
                                .frame(width: 52, height: 52)
                                .background(.thinMaterial, in: Circle())
                                .overlay {
                                    Circle().stroke(selectedIcon == icon ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 220)
        #endif
    }

    private func map(_ materialName: String) -> String {
        switch materialName {
        case "menu_book": return "book.fill"
        case "dumbbell": return "dumbbell.fill"
        case "figure.mind.and.body": return "figure.mind.and.body"
        case "drop": return "drop.fill"
        default: return "ellipsis"
        }
    }
}

private struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategoryId: UUID?
    @State private var categories: [HabitCategory] = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Sin categoría")
                        Spacer()
                        if selectedCategoryId == nil {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCategoryId = nil
                        dismiss()
                    }
                }

                Section("Categorías") {
                    ForEach(categories) { category in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(category.color.opacity(0.15))
                                Image(systemName: category.icon).foregroundStyle(category.color)
                            }
                            .frame(width: 28, height: 28)

                            Text(category.name).foregroundStyle(.primary)

                            Spacer()

                            if selectedCategoryId == category.id {
                                Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategoryId = category.id
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Categoría")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
            .task {
                CategoryStorage.ensureDefaultCategoriesIfNeeded()
                categories = CategoryStorage.fetchCategories()
            }
            #if os(macOS)
            .frame(minWidth: 360, minHeight: 420)
            #endif
        }
    }
}

private struct ReminderEditCard: View {
    let habitId: UUID
    let habitName: String

    @State private var reminders: [HabitReminder] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECORDATORIOS")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)

            VStack(spacing: 0) {
                ForEach(reminders) { r in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.accentColor.opacity(0.12))
                            Image(systemName: "bell.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                        .frame(width: 40, height: 40)

                        DatePicker(
                            "",
                            selection: Binding(
                                get: { r.reminderTime },
                                set: { newValue in
                                    r.reminderTime = newValue
                                    ReminderStorage.save(r)
                                    Task {
                                        await ReminderNotifications.schedule(
                                            reminderId: r.id,
                                            habitName: habitName,
                                            time: newValue,
                                            weekdays: Set(r.repeatDays)
                                        )
                                    }
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()

                        Spacer()

                        Button {
                            ReminderNotifications.cancel(reminderId: r.id, weekdays: r.repeatDays)
                            ReminderStorage.deleteReminder(r)
                            load()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.secondary)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 10)

                    if r.id != reminders.last?.id {
                        Divider().opacity(0.35)
                    }
                }

                Button {
                    if let created = ReminderStorage.addReminder(habitId: habitId) {
                        Task {
                            await ReminderNotifications.schedule(
                                reminderId: created.id,
                                habitName: habitName,
                                time: created.reminderTime,
                                weekdays: Set(created.repeatDays)
                            )
                            await MainActor.run { load() }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Añadir Recordatorio")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
        }
        .onAppear { load() }
    }

    private func load() {
        reminders = ReminderStorage.fetchReminders(for: habitId)
    }
}