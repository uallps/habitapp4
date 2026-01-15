import SwiftUI

struct RewardsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var totalXP: Int = 0
    @State private var info: RewardsStorage.LevelInfo = .init(level: 1, currentXP: 0, nextLevelXP: RewardsStorage.nextLevelXP)
    @State private var canClaim: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    xpRing
                        .padding(.top, 6)

                    statsRow

                    achievementsSection

                    upcomingRewardsSection

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }

            claimButton
                .padding(.horizontal, 16)
                .padding(.bottom, 22)
        }
        #if os(iOS)
        .background(Color(.systemGroupedBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Recompensas y XP").font(.headline)
            }
        }
        #if os(iOS)
        .toolbarBackground(.thinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .xpDidChange)) { _ in refresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Explorador de Hábitos")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Text("\(info.currentXP) XP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(info.nextLevelXP) XP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: info.progress)
                .tint(Color.accentColor)

            Text("¡Faltan \(info.remainingXP) XP para el nivel \(info.level + 1)!")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var xpRing: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.10), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: info.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(info.level)")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                    Text("NIVEL")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Racha Actual", value: "—")
            statCard(title: "Logros Totales", value: "\(unlockedCount) Badges")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mis Logros")
                    .font(.title3.bold())
                Spacer()
                Button("Ver todos") { }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(achievements) { a in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(a.isUnlocked ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
                            Image(systemName: a.icon)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(a.isUnlocked ? Color.accentColor : .secondary)
                        }
                        .frame(height: 68)

                        Text(a.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(a.isUnlocked ? .primary : .secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.top, 6)
    }

    private var upcomingRewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Próximas Recompensas")
                .font(.title3.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    rewardCard(level: 15, title: "Avatar de Neón", subtitle: "Personalización Pro", progress: 0.30)
                    rewardCard(level: 20, title: "Tema Golden", subtitle: "Interfaz de Lujo", progress: 0.10)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 6)
    }

    private func rewardCard(level: Int, title: String, subtitle: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NIVEL \(level)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor, in: Capsule())
                Spacer()
            }

            Spacer(minLength: 6)

            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)

            ProgressView(value: progress)
                .tint(Color.accentColor)
        }
        .frame(width: 180, height: 170)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var claimButton: some View {
        Button {
            _ = RewardsStorage.claimDailyXP()
            refresh()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                Text("¡Reclamar XP Diaria!")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentColor, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canClaim)
        .opacity(canClaim ? 1.0 : 0.55)
        .background(.thinMaterial.opacity(0.0001))
    }

    private func refresh() {
        totalXP = RewardsStorage.fetchOrCreateProfile()?.totalXP ?? 0
        info = RewardsStorage.levelInfo(totalXP: totalXP)
        canClaim = RewardsStorage.canClaimDailyXP()
    }

    private var achievements: [Achievement] {
        // MVP: 6 logros, 2 bloqueados (como tu mock)
        let unlocked = unlockedCount
        return [
            .init(title: "Constancia", icon: "star.fill", isUnlocked: unlocked >= 1),
            .init(title: "Bienestar", icon: "heart.fill", isUnlocked: unlocked >= 2),
            .init(title: "Maestría", icon: "crown.fill", isUnlocked: unlocked >= 3),
            .init(title: "Madrugador", icon: "sunrise.fill", isUnlocked: unlocked >= 4),
            .init(title: "Enfocado", icon: "target", isUnlocked: unlocked >= 5),
            .init(title: "Social", icon: "person.2.fill", isUnlocked: unlocked >= 6),
        ]
    }

    private var unlockedCount: Int {
        // MVP: desbloqueo por XP (ajustable luego)
        switch totalXP {
        case 0..<200: return 1
        case 200..<500: return 2
        case 500..<900: return 3
        case 900..<1300: return 4
        case 1300..<1700: return 5
        default: return 6
        }
    }

    private struct Achievement: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let isUnlocked: Bool
    }
}