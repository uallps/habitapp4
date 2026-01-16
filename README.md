# HabitApp — SwiftUI Habit Tracker (iOS + macOS)

App de seguimiento de hábitos construida en **SwiftUI** con arquitectura modular basada en **plugins**. Soporta múltiples frecuencias (diaria, semanal, mensual, personalizada) y permite extender funcionalidad mediante *features* enchufables sin acoplar el Core. La persistencia está abstraída mediante `StorageProvider` (SwiftData / JSON / Mock).

---

## 📋 Índice

* [Características principales](#-características-principales)
* [Arquitectura](#-arquitectura)
* [Estructura del proyecto](#-estructura-del-proyecto)
* [Requisitos](#-requisitos)
* [Instalación y ejecución](#-instalación-y-ejecución)
* [Tests](#-tests)
* [Persistencia](#-persistencia)
* [Sistema de plugins](#-sistema-de-plugins)
* [Features incluidas](#-features-incluidas)
* [Versiones (Base vs Premium)](#-versiones-base-vs-premium)
* [CI/CD con GitHub Actions](#-cicd-con-github-actions)
* [Convenciones de código](#-convenciones-de-código)
* [Contribución](#-contribución)
* [Roadmap](#-roadmap)
* [Licencia](#-licencia)

---

## ✨ Características principales

* ✅ **SwiftUI nativo** para iOS y macOS con UI adaptada por plataforma
* ✅ **Modelo `Habit`** con SwiftData (`@Model`) + `Codable` para export/import
* ✅ **Frecuencias flexibles**: diaria, semanal, mensual y personalizada
* ✅ **Persistencia intercambiable**: SwiftData, JSON o Mock
* ✅ **Sistema de plugins modular**
  * Reacción a eventos del dominio (borrado, completion)
  * Vistas extra (row, detail, settings)
  * Modelos y storage propios por feature
* ✅ **Features incluidas**:
  * Categories (organización por categorías)
  * Streaks (rachas de días consecutivos)
  * Statistics (dashboard de progreso)
  * Daily Notes (notas por día)
  * Reminders (notificaciones programables)
  * **Rewards** (sistema XP/niveles) — *Premium*
  * **Chained Habits** (rutinas secuenciales) — *Premium*
* ✅ **Dos versiones**: Base (features core) y Premium (Rewards + ChainedHabits)

---

## 🏗️ Arquitectura

### Principios de diseño

1. **Separación de responsabilidades**: Core → Features → Infrastructure
2. **Inversión de dependencias**: Core depende de abstracciones (`FeaturePlugin`, `DataPlugin`, `ViewPlugin`)
3. **Extensibilidad**: nuevas features sin modificar el Core
4. **Testabilidad**: persistencia inyectable y mockeable
5. **Event-driven**: `PluginRegistry` actúa como event bus entre Core y plugins

### Capas del sistema

* **Core** (`HabitApp/Core`)
  * Modelo `Habit` (SwiftData + Codable)
  * `HabitListViewModel` (lógica CRUD)
  * Vistas base (List, Detail, Add, Edit)
* **Features** (`HabitApp/Features/*`)
  * Módulos independientes con sus propios modelos/storage/vistas
  * Integración vía `PluginRegistry` (sin dependencias directas del Core)
* **Infrastructure** (`HabitApp/Infrastructure`)
  * Persistencia (SwiftData / JSON)
  * Infraestructura de plugins (`FeaturePlugin`, `DataPlugin`, `ViewPlugin`)

> El **Core no conoce features concretas**, solo contratos (protocolos). Esto permite añadir/quitar features compilando con flags (`#if PREMIUM`).

### Patrones aplicados

| Patrón | Dónde | Por qué |
|--------|-------|---------|
| **MVVM** | Core/Views | Separar lógica de presentación |
| **Repository** | StorageProvider | Abstraer persistencia |
| **Plugin/Event Bus** | PluginRegistry | Desacoplar features del Core |
| **Dependency Injection** | AppConfig → ViewModels | Inyectar storage provider |
| **Strategy** | StorageProvider implementations | Intercambiar backends |

---

## 📁 Estructura del proyecto

```text
HabitApp/
├── Application/
│   ├── AppConfig.swift          # Configuración global + registro de plugins
│   ├── Notifications.swift      # Setup de notificaciones locales
│   └── TaskApp.swift            # @main entry point (iOS/macOS adaptive)
├── Core/
│   ├── Models/
│   │   └── Habit.swift          # @Model + Codable, frecuencias, completion
│   ├── ViewModels/
│   │   └── HabitListViewModel.swift  # CRUD + event dispatch a plugins
│   └── Views/
│       ├── HabitListView.swift
│       ├── HabitDetailView.swift
│       ├── AddHabitView.swift
│       ├── EditHabitView.swift
│       └── HabitRowView.swift
├── Features/
│   ├── Categories/              # Organización por categorías
│   │   ├── CategoryPlugin.swift
│   │   ├── Models/
│   │   ├── Storage/
│   │   └── Views/
│   ├── ChainedHabits/           # 🔒 PREMIUM: rutinas secuenciales
│   │   ├── ChainedHabitsPlugin.swift
│   │   ├── Models/
│   │   ├── Storage/
│   │   └── Views/
│   ├── DailyNotes/              # Notas por hábito/día
│   ├── DueDate/                 # (legacy, deshabilitado)
│   ├── Reminders/               # Notificaciones programables
│   ├── Rewards/                 # 🔒 PREMIUM: XP/niveles
│   │   ├── RewardsPlugin.swift
│   │   ├── Storage/
│   │   └── Views/
│   ├── Settings/                # Pantalla de configuración
│   ├── Statistics/              # Dashboard de progreso
│   └── Streaks/                 # Rachas de días consecutivos
└── Infrastructure/
    ├── Persistence/
    │   ├── StorageProvider.swift         # Protocolo base
    │   ├── SwiftDataStorageProvider.swift
    │   ├── JSONStorageProvider.swift
    │   └── MockStorageProvider.swift
    └── Plugins/
        ├── FeaturePlugin.swift           # Protocolo base
        ├── DataPlugin.swift              # + modelos SwiftData + eventos
        ├── ViewPlugin.swift              # + vistas inyectables
        ├── PluginRegistry.swift          # Event bus + descubrimiento
        └── PluginDiscovery.swift         # Runtime discovery (opcional)

HabitAppTests/
├── HabitTests.swift                      # Unit tests del modelo
└── HabitListViewModelTests.swift         # Tests del ViewModel con mock
```

---

## 📦 Requisitos

* **macOS 15.0+** con **Xcode 16+**
* **Swift 6.0+**
* **iOS Simulator** para tests

---

## 🚀 Instalación y ejecución

### Desde Xcode

1. Clona el repositorio:

   ```bash
   git clone https://github.com/uallps/habitapp4.git
   cd habitapp4
   ```
2. Abre `HabitApp.xcodeproj`
3. Selecciona el scheme:

   * `HabitApp`
   * `HabitApp Premium`
4. Ejecuta con ⌘R


### Desde terminal

```bash
# Boot simulator
xcrun simctl boot "iPhone 17"
open -a Simulator

# Build + Run (iOS)
xcodebuild \
  -project HabitApp.xcodeproj \
  -scheme "HabitApp Premium" \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  build

# Build + Run (macOS)
xcodebuild \
  -project HabitApp.xcodeproj \
  -scheme "HabitApp" \
  -destination 'platform=macOS' \
  build
```

---

## 🧪 Tests

Los tests viven en `HabitAppTests` y usan **Swift Testing**.

### Qué se testea

| Archivo                       | Scope     | Validaciones                        |
| ----------------------------- | --------- | ----------------------------------- |
| HabitTests.swift              | Modelo    | Inicialización, completion, Codable |
| HabitListViewModelTests.swift | ViewModel | CRUD con StorageProvider mock       |

### Ejecutar tests

```bash
# iOS
xcodebuild test \
  -project HabitApp.xcodeproj \
  -scheme "HabitApp" \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'

# macOS
xcodebuild test \
  -project HabitApp.xcodeproj \
  -scheme "HabitApp" \
  -destination 'platform=macOS'
```

### Ejemplo de test

```swift
@Test("Habit toggles completion for current period (daily)")
func testToggleCompletionDaily() {
    let habit = Habit(name: "Agua", frequency: .daily)
    
    #expect(habit.isCompletedForCurrentPeriod == false)
    habit.toggleCompletion()
    #expect(habit.lastCompletedDate != nil)
    #expect(habit.isCompletedForCurrentPeriod == true)
    
    habit.toggleCompletion()
    #expect(habit.lastCompletedDate == nil)
    #expect(habit.isCompletedForCurrentPeriod == false)
}
```

---

## 💾 Persistencia

### Implementaciones disponibles

| Provider                 | Uso        | Detalles                   |
| ------------------------ | ---------- | -------------------------- |
| SwiftDataStorageProvider | Producción | SwiftData + ModelContainer |
| JSONStorageProvider      | Backup     | Export/import JSON         |
| MockStorageProvider      | Tests      | En memoria, sin I/O        |

### Contrato base

```swift
@MainActor
protocol StorageProvider: AnyObject {
    func loadHabits() async throws -> [Habit]
    func saveHabits(habits: [Habit]) async throws
}
```
Cambiar provider `AppConfig` : 

```swift
@AppStorage("storageType") var storageType: StorageType = .swiftData

var storageProvider: StorageProvider {
    switch storageType {
    case .swiftData: return swiftDataProvider
    case .json:      return JSONStorageProvider.shared
    }
}
```
> **Importante:** las features Premium (Rewards, ChainedHabits) requieren SwiftData porque dependen de SwiftDataContext.shared. Si cambias a JSON, esas features quedarán inactivas.

---

## 🔌 Sistema de plugins

Infraestructura en `Infrastructure/Plugins`.

### FeaturePlugin

```swift
protocol FeaturePlugin {
    var isEnabled: Bool { get }
    init(config: AppConfig)
}
```
Todas las features implementan este protocolo.

### DataPlugin

```swift
protocol DataPlugin: FeaturePlugin {
    var models: [any PersistentModel.Type] { get }

    func willDeleteHabit(_ habit: Habit) async
    func didDeleteHabit(habitId: UUID) async
    func habitCompletionDidChange(
        habitId: UUID,
        isCompleted: Bool,
        completionDate: Date?
    ) async
}
```
Permite a features:

- **Exponer modelos SwiftData** (se añaden al `Schema` automáticamente).

- **Reaccionar a eventos del Core** (borrado, completion) sin acoplamiento

Ejemplo : `StreakPlugin`
```swift
@MainActor
final class StreakPlugin: DataPlugin {
    var models: [any PersistentModel.Type] { [HabitStreak.self] }
    var isEnabled: Bool { config.enableStreaks }
    
    func habitCompletionDidChange(
        habitId: UUID,
        isCompleted: Bool,
        completionDate: Date?
    ) async {
        StreakStorage.applyCompletionChange(habitId: habitId, isCompleted: isCompleted)
    }
}
```
ViewPlugin (UI inyectable)
```swift
@MainActor
protocol ViewPlugin: FeaturePlugin {
    func habitRowView(for habit: Habit) -> AnyView
    func habitDetailView(for habit: Binding<Habit>) -> AnyView
    func settingsView() -> AnyView
}
```
Permite a features:

- **Inyectar vistas** en las pantallas del Core (row, detail, settings)
- El Core las renderiza sin conocer qué feature las provee.

**Ejemplo:** mostrar racha en cada row
```swift
ForEach(habits) { habit in
    HStack {
        Text(habit.name)
        ForEach(PluginRegistry.shared.getHabitRowViews(for: habit), id: \.self) { view in
            view
        }
    }
}
```
PluginRegistry (event bus)

Centraliza el registro y dispatch de eventos:
```swift
@MainActor
class PluginRegistry {
    static let shared = PluginRegistry()
    
    func register(_ pluginType: FeaturePlugin.Type)
    func createPluginInstances(config: AppConfig) -> [FeaturePlugin]
    
    func notifyHabitWillBeDeleted(_ habit: Habit) async
    func notifyHabitCompletionDidChange(habitId: UUID, isCompleted: Bool, ...) async
    
    func getHabitRowViews(for habit: Habit) -> [AnyView]
    func getHabitDetailViews(for habit: Binding<Habit>) -> [AnyView]
}
```
**Flujo completo:**

1. Usuario completa un hábito
2. `HabitListViewModel.toggleHabitCompletion(...)` actualiza modelo y persiste
3. ViewModel llama `PluginRegistry.shared.notifyHabitCompletionDidChange(...)`
4. Registry fan-out a todos los DataPlugin activos
5. `StreakPlugin`, `RewardsPlugin`, etc. reaccionan sin que el Core los conozca
---

## 🔄 Flujo de datos y eventos

1. Usuario interactúa con una View
2. View → ViewModel
3. ViewModel actualiza modelo y persiste
4. `PluginRegistry` notifica a los plugins

Ventaja clave: **desacoplamiento total**.

---

## 🔄 CI/CD con GitHub Actions

Configuración en `.github/workflows/build.yml`.

### Triggers

```yaml
on:
  push:
    branches: [main, develop, "feature/**"]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:
```

### Matrix

```yaml
strategy:
  matrix:
    platform: [iOS, macOS]
    scheme: ["HabitApp", "HabitApp Premium"]
```
Builds:

- iOS Base
- iOS Premium
- macOS Base
- macOS Premium

Steps destacados

1. **Build** con `xcodebuild` (sin firma)
2. **Test** (solo para scheme `HabitApp` en iOS)
3. **Archivar artifacts** (`.app` bundles)
4. **Release automático** en `main` (tags `v1.0.X`)

---

## 📝 Convenciones de código

Nombres
* **Archivos:** PascalCase (HabitListView.swift)
* **Protocolos:** sustantivo o `-able` (`FeaturePlugin`, `Codable`)
ViewModels: sufijo `ViewModel` (`HabitListViewModel`)
* **Storage/Repository:** sufijo `Storage` o `Provider` (`CategoryStorage`, `StorageProvider`)

Estilo

* **Async/Await** para persistencia (no callbacks)
* **MainActor** para ViewModels y plugins (Swift 6 concurrency)
* **Swift Testing** para tests ( `@Test`, `#expect`)
* **MARK:** para seccionar archivos largos

---

## 🤝 Contribución

1. Fork del repo
2. Crea branch desde `develop`

   ```bash
   git checkout develop
   git checkout -b feature/mi-feature
   ```
3. Commits descriptivos:
   ```bash
      git commit -m "feat(streaks): añadir cálculo de racha mensual"
   ```
4. Pull Request a `develop`

Agregar una nueva feature

1. Crea carpeta en `HabitApp/Features/MiFeature/`
2. Implementa `MiFeaturePlugin`: `DataPlugin` o `ViewPlugin`
3. Registra en `AppConfig.init()`:
```swift
PluginRegistry.shared.register(MiFeaturePlugin.self)
```
4. Añade tests en `HabitAppTests/MiFeatureTests.swift`

---

## 🗺️ Roadmap

### v1.1 (Q1 2026)

* Tests unitarios por feature (Streaks, Rewards, etc.)
* Export/import CSV (además de JSON)
* i18n ES / EN
* Dark mode manual toggle

### v1.2 (Q2 2026)

* Widgets iOS 17+
* Temas custom
* HealthKit (opcional)
* Siri Shortcuts para marcar completado

### v2.0 (Q3 2026)

* iCloud / CloudKit
* Offline-first
* watchOS

---

## 📄 Licencia

Este proyecto está licenciado bajo la **MIT License**. Ver el archivo [LICENSE](LICENSE) para más detalles.

Copyright (c) 2026 habitapp4 contributors

---

**Hecho con ❤️ en SwiftUI**
