import SwiftUI
import SwiftData

struct StatsDashboardView: View {
    enum Timeframe: String, CaseIterable, Identifiable {
        case week = "Semana"
        case month = "Mes"
        case year = "Año"
        var id: String { rawValue }
    }

    let storageProvider: StorageProvider
    @EnvironmentObject private var config: AppConfig
    @Environment(\.dismiss) private var dismiss

    @State private var timeframe: Timeframe = .week

    @State private var habits: [Habit] = []
    @State private var weekly: WeeklySummary = .empty
    @State private var records: Records = .empty
    @State private var categories: [CategorySlice] = []
    @State private var streaks: [HabitStreak] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    timeframePicker

                    weeklyCard

                    Text("Récords Personales")
                        .font(.title3.bold())
                        .padding(.top, 6)

                    recordsGrid

                    Text("Distribución por Categoría")
                        .font(.title3.bold())
                        .padding(.top, 6)

                    categoryDistribution

                    tipCard
                }
                .padding(16)
            }
            .navigationTitle("Estadísticas de Progreso")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: { Image(systemName: "square.and.arrow.up") }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { } label: { Image(systemName: "square.and.arrow.up") }
                }
                #endif
            }
            #if os(iOS)
            .toolbarBackground(.thinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .task { await load() }
            .onReceive(NotificationCenter.default.publisher(for: .habitsDidChange)) { _ in
                Task { await load() }
            }
        }
    }

    // MARK: UI

    private var timeframePicker: some View {
        Picker("Timeframe", selection: $timeframe) {
            ForEach(Timeframe.allCases) { tf in
                Text(tf.rawValue).tag(tf)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color.accentColor)
        .onChange(of: timeframe) { _, _ in
            recompute()
        }
    }

    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                        Text(timeframeTitle)                       
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text("\(weekly.percent)%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: weekly.delta >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                        .font(.caption.weight(.bold))
                    Text(weekly.deltaText)
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(weekly.delta >= 0 ? Color.green : Color.red)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((weekly.delta >= 0 ? Color.green : Color.red).opacity(0.12), in: Capsule())
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(weekly.bars) { bar in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentColor.opacity(0.18))
                            .frame(height: 140)
                            .overlay(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.accentColor)
                                    .frame(height: max(8, bar.value * 140))
                            }

                        Text(bar.label)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var recordsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            recordCard(
                icon: "flame.fill",
                iconTint: .orange,
                title: "\(records.bestStreak) Días",
                subtitle: "Racha más larga"
            )

            recordCard(
                icon: "target",
                iconTint: Color.accentColor,
                title: "\(records.monthlySuccess)%", // aproximado
                subtitle: "Éxito mensual"
            )

            recordCard(
                icon: "checkmark.circle.fill",
                iconTint: .green,
                title: "\(records.totalCompletions)",
                subtitle: "Total completados"
            )

            recordCard(
                icon: "calendar",
                iconTint: .purple,
                title: "\(records.activeDays)",
                subtitle: "Días activos"
            )
        }
    }

    private func recordCard(icon: String, iconTint: Color, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconTint.opacity(0.14))
                Image(systemName: icon)
                    .foregroundStyle(iconTint)
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(width: 44, height: 44)

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var categoryDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            if categories.isEmpty {
                Text("Activa Categorías y usa SwiftData para ver esta sección.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 16) {
                    donut
                        .frame(width: 120, height: 120)

                    VStack(spacing: 10) {
                        ForEach(categories.prefix(3)) { slice in
                            HStack {
                                Circle().fill(slice.color).frame(width: 10, height: 10)
                                Text(slice.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(slice.percent)%")
                                    .font(.subheadline.bold())
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var donut: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 14)

            ForEach(donutSlices) { s in
                Circle()
                    .trim(from: s.start, to: s.end)
                    .stroke(s.color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text("\(min(99, categories.count))")
                    .font(.title3.bold())
                Text("TIPOS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor)
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text("Consejo del Día")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.accentColor)

                Text("Mantén constancia: una pequeña acción diaria suma más que un gran esfuerzo ocasional.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)
        }
    }

    // MARK: Data

    private var activeHabits: [Habit] { habits.filter { $0.isActive } }

    private func load() async {
        do {
            habits = try await storageProvider.loadHabits()
        } catch {
            habits = []
        }

        streaks = fetchStreaks()
        categories = fetchCategoryDistribution(activeHabits: activeHabits)
        recompute()
    }

    private func fetchStreaks() -> [HabitStreak] {
        guard let ctx = SwiftDataContext.shared else { return [] }
        let fetch = FetchDescriptor<HabitStreak>()
        return (try? ctx.fetch(fetch)) ?? []
    }

    private func fetchCategoryDistribution(activeHabits: [Habit]) -> [CategorySlice] {
        guard config.enableCategories, let ctx = SwiftDataContext.shared else { return [] }

        let cats = ((try? ctx.fetch(FetchDescriptor<HabitCategory>())) ?? [])
        let assigns = ((try? ctx.fetch(FetchDescriptor<HabitCategoryAssignment>())) ?? [])
        if cats.isEmpty || assigns.isEmpty { return [] }

        let activeSet = Set(activeHabits.map { $0.id })
        var counts: [UUID: Int] = [:]

        for a in assigns where activeSet.contains(a.habitId) {
            counts[a.categoryId, default: 0] += 1
        }

        let total = max(1, counts.values.reduce(0, +))

        let slices: [CategorySlice] = cats.compactMap { c in
            let count = counts[c.id, default: 0]
            guard count > 0 else { return nil }
            let pct = Int((Double(count) / Double(total) * 100).rounded())
            return CategorySlice(id: c.id, name: c.name, percent: pct, color: c.color)
        }
        .sorted { $0.percent > $1.percent }

        return slices
    }

    private var donutSlices: [DonutSlice] {
        let total = max(1, categories.map(\.percent).reduce(0, +))
        var start: Double = 0
        return categories.map { c in
            let frac = Double(c.percent) / Double(total)
            let end = start + frac
            defer { start = end }
            return DonutSlice(start: start, end: end, color: c.color)
        }
    }

    private var timeframeTitle: String {
        switch timeframe {
        case .week: return "Cumplimiento Semanal"
        case .month: return "Cumplimiento Mensual"
        case .year: return "Cumplimiento Anual"
        }
    }

    private func recompute() {
        weekly = WeeklySummary.compute(timeframe: timeframe, activeHabits: activeHabits, streaks: streaks)
        records = Records.compute(habits: habits, streaks: streaks)
    }
}

// MARK: - Models

private struct WeeklySummary {
    struct DayBar: Identifiable {
        let id = UUID()
        let label: String
        let value: CGFloat
    }

    let percent: Int
    let delta: Double
    let bars: [DayBar]

    static let empty = WeeklySummary(percent: 0, delta: 0, bars: ["L","M","X","J","V","S","D"].map { DayBar(label: $0, value: 0) })

    var deltaText: String {
        let pct = Int((delta * 100).rounded())
        return pct >= 0 ? "+\(pct)%" : "\(pct)%"
    }

        static func compute(
    timeframe: StatsDashboardView.Timeframe,
    activeHabits: [Habit],
    streaks: [HabitStreak]
) -> WeeklySummary {
    var calendar = Calendar.current
    calendar.firstWeekday = 2 // lunes
    let now = Date()

    let labels = ["L","M","X","J","V","S","D"]

    func weekdayIndex(_ date: Date) -> Int {
        // 0=lunes ... 6=domingo
        (calendar.component(.weekday, from: date) + 5) % 7
    }

    let totalHabits = max(1, activeHabits.count)
    let activeSet = Set(activeHabits.map { $0.id })

    func dayKey(_ date: Date) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 0) * 10_000 + (c.month ?? 0) * 100 + (c.day ?? 0)
    }

    // habitId -> set(dayKey) completados
    var completedDaysByHabit: [UUID: Set<Int>] = [:]
    for s in streaks where activeSet.contains(s.habitId) {
        completedDaysByHabit[s.habitId] = Set(s.completionDates.map(dayKey))
    }

    func completionRatio(on day: Date) -> Double {
        let key = dayKey(day)
        var completed = 0
        for habitId in activeSet {
            if completedDaysByHabit[habitId]?.contains(key) == true {
                completed += 1
            }
        }
        return Double(completed) / Double(totalHabits)
    }

    func interval(for timeframe: StatsDashboardView.Timeframe, anchor: Date) -> DateInterval {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: anchor)) ?? anchor

        switch timeframe {
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start ?? calendar.startOfDay(for: anchor)
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? tomorrow
            return DateInterval(start: start, end: end)
        case .month:
            let start = calendar.dateInterval(of: .month, for: anchor)?.start ?? calendar.startOfDay(for: anchor)
            return DateInterval(start: start, end: tomorrow)
        case .year:
            let start = calendar.dateInterval(of: .year, for: anchor)?.start ?? calendar.startOfDay(for: anchor)
            return DateInterval(start: start, end: tomorrow)
        }
    }

    func averageRatio(in interval: DateInterval) -> Double {
        var sum = 0.0
        var count = 0

        var day = calendar.startOfDay(for: interval.start)
        while day < interval.end {
            sum += completionRatio(on: day)
            count += 1
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? interval.end
        }

        return count > 0 ? (sum / Double(count)) : 0
    }

    let current = interval(for: timeframe, anchor: now)
    let daysCount = max(1, calendar.dateComponents([.day], from: current.start, to: current.end).day ?? 1)

    let previousEnd = current.start
    let previousStart = calendar.date(byAdding: .day, value: -daysCount, to: previousEnd) ?? previousEnd
    let previous = DateInterval(start: previousStart, end: previousEnd)

    let thisAvg = averageRatio(in: current)
    let lastAvg = averageRatio(in: previous)

    // Barras: semana actual si es .week; si no, últimos 7 días (para mantener el diseño L..D)
    let barsInterval: DateInterval = {
        switch timeframe {
        case .week:
            return current
        case .month, .year:
            let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? current.start
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? current.end
            return DateInterval(start: start, end: end)
        }
    }()

    var bars: [DayBar] = []
    var d = calendar.startOfDay(for: barsInterval.start)
    while d < barsInterval.end, bars.count < 7 {
        let idx = weekdayIndex(d)
        bars.append(DayBar(label: labels[idx], value: CGFloat(completionRatio(on: d))))
        d = calendar.date(byAdding: .day, value: 1, to: d) ?? barsInterval.end
    }
    while bars.count < 7 {
        bars.append(DayBar(label: "", value: 0))
    }

    return WeeklySummary(
        percent: Int((thisAvg * 100).rounded()),
        delta: thisAvg - lastAvg,
        bars: bars
    )
}
}

private struct Records {
    let bestStreak: Int
    let monthlySuccess: Int
    let totalCompletions: Int
    let activeDays: Int

    static let empty = Records(bestStreak: 0, monthlySuccess: 0, totalCompletions: 0, activeDays: 0)

    static func compute(habits: [Habit], streaks: [HabitStreak]) -> Records {
        let best = streaks.map(\.bestStreak).max() ?? 0
        let total = streaks.map { $0.completionDates.count }.reduce(0, +)

        let firstCreated = habits.map(\.createdDate).min() ?? Date()
        let activeDays = max(1, Calendar.current.dateComponents([.day], from: firstCreated, to: Date()).day ?? 1)

      var calendar = Calendar.current
calendar.firstWeekday = 2

let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? calendar.startOfDay(for: Date())
let endExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
let daysSoFar = max(1, calendar.dateComponents([.day], from: startOfMonth, to: endExclusive).day ?? 1)

let activeCount = max(1, habits.filter { $0.isActive }.count)
let target = activeCount * daysSoFar

func dayKey(_ date: Date) -> Int {
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    return (c.year ?? 0) * 10_000 + (c.month ?? 0) * 100 + (c.day ?? 0)
}

var uniqueCompletions = 0
for s in streaks {
    // unique habit-day en este mes
    let keys = Set(s.completionDates
        .filter { $0 >= startOfMonth && $0 < endExclusive }
        .map(dayKey)
    )
    uniqueCompletions += keys.count
}

let monthly = min(100, Int((Double(uniqueCompletions) / Double(target) * 100).rounded()))

        return Records(bestStreak: best, monthlySuccess: monthly, totalCompletions: total, activeDays: activeDays)
    }
}

private struct CategorySlice: Identifiable {
    let id: UUID
    let name: String
    let percent: Int
    let color: Color
}

private struct DonutSlice: Identifiable {
    let id = UUID()
    let start: Double
    let end: Double
    let color: Color
}