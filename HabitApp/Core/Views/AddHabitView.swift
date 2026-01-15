//
//  AddHabitView.swift
//  HabitApp
//
import UniformTypeIdentifiers
import SwiftUI

#if os(iOS)
import PhotosUI
#endif

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    let storageProvider: StorageProvider
    let onSave: (Habit) -> Void

    @EnvironmentObject private var config: AppConfig

    @State private var name = ""
    @State private var notes = ""
    @State private var frequency: HabitFrequency = .daily

    @State private var reminderTime = Date()

    // 1=L ... 7=D
    @State private var selectedWeekdays: Set<Int> = [1,2,3,4,5,6,7]

    @State private var monthlySelectedDate = Date()

    @State private var selectedIcon: String = "menu_book"
    @State private var imageData: Data?

    @State private var selectedCategoryId: UUID?
    @State private var categories: [HabitCategory] = []
    @State private var showingCategoryPicker = false

    @State private var availableHabits: [Habit] = []

    @State private var chainedHabitIds: [UUID] = []
    @State private var showingChainedHabitPicker = false

    #if os(iOS)
    @State private var pickedPhoto: PhotosPickerItem?
    #else
    @State private var showFilePicker = false
    #endif

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 18) {

                        headerMedia

                        field(title: "Nombre") {
                            TextField("Ej. Leer, Meditar, Gimnasio...", text: $name)
                            .textFieldStyle(.plain)
#if os(iOS)
                                .textInputAutocapitalization(.sentences)
#endif
                        }

                        field(title: "Categoría") {
                            Button {
                                Task {
                                    await loadCategories()
                                    showingCategoryPicker = true
                                }
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
                                    } else {
                                        Text("Sin categoría")
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(!categoriesUsable)
                            .opacity(categoriesUsable ? 1.0 : 0.6)
                        }

                        HStack(spacing: 12) {
                            field(title: "Frecuencia") {
                                Picker("", selection: $frequency) {
                                    Text("Diaria").tag(HabitFrequency.daily)
                                    Text("Semanal").tag(HabitFrequency.weekly)
                                    Text("Mensual").tag(HabitFrequency.monthly)
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }

                            field(title: "Hora") {
                                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                        }

                        if frequency == .weekly {
                            field(title: "Días de la semana") {
                                HStack(spacing: 10) {
                                    weekday("L", 1)
                                    weekday("M", 2)
                                    weekday("X", 3)
                                    weekday("J", 4)
                                    weekday("V", 5)
                                    weekday("S", 6)
                                    weekday("D", 7)
                                }
                            }
                        }

                        if frequency == .monthly {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Día del mes")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("Día \(Calendar.current.component(.day, from: monthlySelectedDate)) seleccionado")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.accentColor)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                                }

                                DatePicker("", selection: $monthlySelectedDate, displayedComponents: [.date])
                                    .labelsHidden()
                                    .datePickerStyle(.graphical)
                                    .padding(10)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }

                        field(title: "Notas") {
                            TextEditor(text: $notes)
                                .frame(minHeight: 90)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                        }

                        iconSuggestions
                        chainedHabitSection

                        Spacer(minLength: 100)
                    }
                    .padding(16)
                }

                saveBar
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .principal) {
                    Text("Nuevo hábito").font(.headline)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { } label: { Image(systemName: "square.and.arrow.up") }
                }
            }
        }
        .task {
            availableHabits = (try? await storageProvider.loadHabits()) ?? []
            await loadCategories()
        }
        .onChange(of: showingCategoryPicker) { _, isPresented in
            if isPresented {
                Task { await loadCategories() }
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerSheet(selectedCategoryId: $selectedCategoryId)
        }
        .sheet(isPresented: $showingChainedHabitPicker) {
            ChainedHabitPickerSheet(
                habits: availableHabits,
                selectedIds: $chainedHabitIds
            )
        }
    }

    // MARK: UI bits

    private var headerMedia: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.accentColor.opacity(0.10))
                    )
                    .frame(width: 110, height: 110)
                    .overlay {
                        if let imageData,
                           let image = platformImage(from: imageData) {
                            image
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        } else {
                            Image(systemName: "camera")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .clipped()

                Button {
                    // solo abre el selector
                    #if os(iOS)
                    // PhotosPicker se abre desde el control asociado
                    #else
                    showFilePicker = true
                    #endif
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.accentColor))
                        .overlay { Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1) }
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 14) {
                Button {
                    // solo iconos (ya abajo en sugerencias)
                } label: {
                    Text("ELEGIR ICONO")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
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
                Button {
                    showFilePicker = true
                } label: {
                    Text("SUBIR FOTO")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .fileImporter(
                    isPresented: $showFilePicker,
                    allowedContentTypes: [.image],
                    allowsMultipleSelection: false
                ) { result in
                    guard case let .success(urls) = result, let url = urls.first else { return }

                    let didStart = url.startAccessingSecurityScopedResource()
                    defer { if didStart { url.stopAccessingSecurityScopedResource() } }

                    do {
                        imageData = try Data(contentsOf: url)
                    } catch {
                        print("Failed to read image data: \(error)")
                        imageData = nil
                    }
                }
                #endif
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            content()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func weekday(_ label: String, _ day: Int) -> some View {
        Button {
            if selectedWeekdays.contains(day) { selectedWeekdays.remove(day) }
            else { selectedWeekdays.insert(day) }
        } label: {
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(selectedWeekdays.contains(day) ? Color.white : Color.secondary)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(selectedWeekdays.contains(day) ? Color.accentColor : Color.primary.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }

    private var iconSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUGERENCIAS DE ICONOS")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)

            HStack(spacing: 14) {
                iconButton("menu_book")
                iconButton("dumbbell")
                iconButton("figure.mind.and.body")
                iconButton("drop")
                iconButton("ellipsis")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private func iconButton(_ name: String) -> some View {
        Button {
            selectedIcon = name
            // NO borres imageData aquí.
            // La lógica de guardado decidirá: si hay imagen -> imagen; si no -> icono.
        } label: {
            Image(systemName: sfSymbol(for: name))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(selectedIcon == name ? Color.accentColor : Color.secondary)
                .frame(width: 48, height: 48)
                .background(.thinMaterial, in: Circle())
                .overlay {
                    Circle().stroke(selectedIcon == name ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var saveBar: some View {
        VStack {
            Button {
                let habit = Habit(
                    name: name,
                    description: notes,
                    frequency: frequency
                )

                habit.imageData = imageData
                habit.iconName = (imageData == nil) ? selectedIcon : nil
                habit.reminderTime = reminderTime

                switch frequency {
                case .daily:
                    habit.repeatDays = []
                    habit.monthlyDay = nil
                case .weekly:
                    habit.repeatDays = selectedWeekdays.sorted()
                    habit.monthlyDay = nil
                case .monthly:
                    habit.repeatDays = []
                    habit.monthlyDay = Calendar.current.component(.day, from: monthlySelectedDate)
                default:
                    habit.repeatDays = []
                    habit.monthlyDay = nil
                }

                onSave(habit)

                if categoriesUsable {
                    CategoryStorage.setAssignment(habitId: habit.id, categoryId: selectedCategoryId)
                }

                if config.enableReminders, SwiftDataContext.shared != nil {
                    let days: [Int]
                    switch frequency {
                    case .weekly:
                        days = selectedWeekdays.sorted()
                    default:
                        days = [1,2,3,4,5,6,7]
                    }

                    if let created = ReminderStorage.addReminder(
                        habitId: habit.id,
                        time: reminderTime,
                        isEnabled: true,
                        repeatDays: days
                    ) {
                        Task {
                            await ReminderNotifications.schedule(
                                reminderId: created.id,
                                habitName: habit.name,
                                time: created.reminderTime,
                                weekdays: Set(created.repeatDays)
                            )
                        }
                    }
                }

                if SwiftDataContext.shared != nil, !chainedHabitIds.isEmpty {
                    var ids: [UUID] = [habit.id]
                    for id in chainedHabitIds where !ids.contains(id) { ids.append(id) }
                    _ = ChainedHabitsStorage.createChain(name: "Hábito Encadenado", habitIds: ids)
                }
            } label: {
                Text("Guardar Hábito")
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
        }
        .padding(16)
        .background(.thinMaterial)
    }
    
    private func sfSymbol(for materialName: String) -> String {
        // mapeo simple a SF Symbols
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

    private var categoriesUsable: Bool {
        SwiftDataContext.shared != nil
    }

    private var selectedCategory: HabitCategory? {
        guard let id = selectedCategoryId else { return nil }
        return categories.first(where: { $0.id == id })
    }

    @MainActor
    private func loadCategories() async {
        guard categoriesUsable else { return }
        CategoryStorage.ensureDefaultCategoriesIfNeeded()
        categories = CategoryStorage.fetchCategories()
    }

    private var chainedHabitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HÁBITOS ENCADENADOS")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)

            if availableHabits.isEmpty {
                Text("No hay hábitos disponibles para encadenar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(availableHabits) { habit in
                    chainedHabitRow(habit)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private func chainedHabitRow(_ habit: Habit) -> some View {
        let isSelected = chainedHabitIds.contains(habit.id)

        return Button {
            if isSelected {
                chainedHabitIds.removeAll(where: { $0 == habit.id })
            } else {
                chainedHabitIds.append(habit.id)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)

                Text(habit.name.isEmpty ? "—" : habit.name)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
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
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.color)
                            }
                            .frame(width: 28, height: 28)

                            Text(category.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedCategoryId == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task { await load() }
            #if os(macOS)
            .frame(minWidth: 360, minHeight: 420)
            #endif
        }
    }

    @MainActor private func load() async {
        print("SwiftDataContext.shared nil? \(SwiftDataContext.shared == nil)")
        CategoryStorage.ensureDefaultCategoriesIfNeeded()
        let fetched = CategoryStorage.fetchCategories()
        print("Fetched categories count: \(fetched.count)")
        categories = fetched
    }
}

private struct ChainedHabitPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let habits: [Habit]
    @Binding var selectedIds: [UUID]

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    Button {
                        if !selectedIds.contains(habit.id) {
                            selectedIds.append(habit.id)
                        }
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .foregroundStyle(.secondary)

                            Text(habit.name.isEmpty ? "—" : habit.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedIds.contains(habit.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Encadenar hábito")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddHabitView(storageProvider: MockStorageProvider()) { _ in }
        .environmentObject(AppConfig())
}
