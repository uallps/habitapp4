//
//  TaskApp.swift
//  HabitApp
//

import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit
#endif

@main
struct TaskAppMain: App {
    @StateObject var config = AppConfig()

    enum MainTab: Hashable {
        case home
        case progress
        case ranking
        case profile
    }

    @State private var tab: MainTab = .home
    @State private var showAddHabit = false

    // mac
    @State private var selectedDetailView: String?

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            ZStack(alignment: .bottom) {
                TabView(selection: $tab) {
                    HabitListView(storageProvider: config.storageProvider)
                        .tag(MainTab.home)

                    StatsDashboardView(storageProvider: config.storageProvider)
                        .tag(MainTab.progress)

                    NavigationStack { RewardsView() }
                        .tag(MainTab.ranking)

                    SettingsView()
                        .tag(MainTab.profile)
                }
                .toolbar(.hidden, for: .tabBar)
                .environmentObject(config)
                .onAppear { requestNotificationPermission() }

                BottomMenuBar(
                    tab: $tab,
                    onAdd: {
                        tab = .home
                        showAddHabit = true
                    }
                )
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView(storageProvider: config.storageProvider) { newHabit in
                    Task {
                        do {
                            var list = try await config.storageProvider.loadHabits()
                            list.append(newHabit)
                            try await config.storageProvider.saveHabits(habits: list)
                            NotificationCenter.default.post(name: .habitsDidChange, object: nil)
                        } catch {
                            // si quieres, aquí puedes loguear
                        }
                        showAddHabit = false
                    }
                }
                .environmentObject(config) // <- IMPORTANTE
            }
            #else
            NavigationSplitView {
                List(selection: $selectedDetailView) {
                    NavigationLink(value: "inicio") { Label("Inicio", systemImage: "house") }
                    NavigationLink(value: "progreso") { Label("Progreso", systemImage: "chart.bar") }
                    NavigationLink(value: "ranking") { Label("Logros", systemImage: "sparkles") }
                    NavigationLink(value: "perfil") { Label("Perfil", systemImage: "person") }
                }
            } detail: {
                switch selectedDetailView {
                case "inicio":
                    HabitListView(storageProvider: config.storageProvider)
                case "progreso":
                    StatsDashboardView(storageProvider: config.storageProvider)
                case "ranking":
                    RewardsView()
                case "perfil":
                    SettingsView()
                default:
                    Text("Seleccione una opción")
                }
            }
            .environmentObject(config)
            #endif
        }
    }

    private func requestNotificationPermission() {
        #if os(iOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
            } else if let error = error {
                let nsError = error as NSError
                if nsError.code != 1 { print("⚠️ Notification permission error: \(error.localizedDescription)") }
            }
        }
        #endif
    }
}

// MARK: - iOS Bottom Menu

private struct BottomMenuBar: View {
    @Binding var tab: TaskAppMain.MainTab
    let onAdd: () -> Void

    var body: some View {
        HStack {
            item(tab: .home, title: "INICIO", icon: "house.fill")
            item(tab: .progress, title: "PROGRESO", icon: "chart.bar.fill")

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.accentColor))
                    .overlay {
                        Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                    .offset(y: -18)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            item(tab: .ranking, title: "LOGROS", icon: "sparkles")
            item(tab: .profile, title: "PERFIL", icon: "person.fill")
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(.thinMaterial)
        .overlay(alignment: .top) {
            Divider().opacity(0.35)
        }
    }

    private func item(tab target: TaskAppMain.MainTab, title: String, icon: String) -> some View {
        Button {
            tab = target
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(tab == target ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }
}
