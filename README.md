# HabitApp — SwiftUI Habit Tracker (iOS + macOS)

App de seguimiento de hábitos construida en **SwiftUI** con arquitectura modular basada en **plugins**. Soporta múltiples frecuencias (diaria, semanal, mensual, personalizada) y permite extender funcionalidad mediante features enchufables sin acoplar el Core. La persistencia está abstraída mediante `StorageProvider` (SwiftData/JSON/Mock).

---

## 📋 Índice

- [Características principales](#-características-principales)
- [Arquitectura](#-arquitectura)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Requisitos](#-requisitos)
- [Instalación y ejecución](#-instalación-y-ejecución)
- [Tests](#-tests)
- [Persistencia](#-persistencia)
- [Sistema de plugins](#-sistema-de-plugins)
- [CI/CD con GitHub Actions](#-cicd-con-github-actions)
- [Convenciones de código](#-convenciones-de-código)
- [Contribución](#-contribución)
- [Roadmap](#-roadmap)
- [Licencia](#-licencia)

---

## ✨ Características principales

- ✅ **SwiftUI nativo** para iOS y macOS con UI adaptada por plataforma
- ✅ **Modelo `Habit`** con SwiftData (`@Model`) + `Codable` para export/import
- ✅ **Frecuencias flexibles**: diaria, semanal, mensual y personalizada
- ✅ **Persistencia intercambiable**: SwiftData, JSON o Mock (sin reescribir UI)
- ✅ **Sistema de plugins modular**:
  - Reaccionar a eventos del dominio (borrado, completion)
  - Aportar vistas extra (row, detail, settings)
  - Gestionar modelos y storage propios por feature
- ✅ **Features incluidas**:
  - Categories (categorización con colores)
  - Streaks (rachas de cumplimiento)
  - Statistics (métricas y gráficos)
  - Rewards (sistema de XP y logros)
  - Daily Notes (notas por día)
  - Reminders (notificaciones locales)
  - Due Date (fechas límite)
  - Chained Habits (dependencias entre hábitos)

---

## 🏗️ Arquitectura

### Principios de diseño

1. **Separación de responsabilidades**: Core → Features → Infrastructure
2. **Inversión de dependencias**: Core depende de abstracciones (`StorageProvider`, `PluginRegistry`), no de implementaciones
3. **Extensibilidad**: nuevas features se enchufan sin modificar el Core
4. **Testabilidad**: toda persistencia es inyectable y mockeable

### Capas del sistema

- **Core** (`HabitApp/Core`):
  - Contiene el modelo principal (`Habit`)
  - View model (`HabitListViewModel`) que usa `StorageProvider`
  - Vistas “base” (listado, detalle, add/edit)
- **Features** (`HabitApp/Features/*`):
  - Módulos independientes (categorías, streaks, estadísticas, etc.)
  - Se integran a través del `PluginRegistry`
- **Infrastructure** (`HabitApp/Infraestructure`):
  - Persistencia real (SwiftData/JSON)
  - Infraestructura de plugins (registro/descubrimiento/protocolos)

La idea: **Core no conoce features concretas**, solo contratos. Las features se enchufan.

---

## 📁 Estructura del proyecto

```text
HabitApp/
├── Application/
│   ├── AppConfig.swift           # DI container + configuración global
│   ├── Notifications.swift       # Gestión de notificaciones locales
│   └── TaskApp.swift             # Entry point (@main)
├── Core/
│   ├── Models/
│   │   └── Habit.swift           # Modelo principal (@Model + Codable)
│   ├── ViewModels/
│   │   └── HabitListViewModel.swift  # Lógica CRUD de hábitos
│   └── Views/
│       ├── HabitListView.swift
│       ├── HabitDetailView.swift
│       ├── AddHabitView.swift
│       ├── EditHabitView.swift
│       └── HabitRowView.swift
├── Features/                     # Plugins modulares
│   ├── Categories/               # Categorización con colores
│   ├── ChainedHabits/            # Dependencias entre hábitos
│   ├── DailyNotes/               # Notas por día
│   ├── DueDate/                  # Fechas límite
│   ├── Reminders/                # Notificaciones
│   ├── Rewards/                  # Sistema XP + logros
│   ├── Settings/                 # Configuración
│   ├── Statistics/               # Métricas y gráficos
│   └── Streaks/                  # Rachas de cumplimiento
└── Infrastructure/
    ├── Persistence/
    │   ├── StorageProvider.swift          # Protocolo base
    │   ├── SwiftDataStorageProvider.swift # Implementación SwiftData
    │   ├── JSONStorageProvider.swift      # Implementación JSON
    │   └── MockStorageProvider.swift      # Mock para tests/previews
    └── Plugins/
        ├── FeaturePlugin.swift      # Protocolo base de plugins
        ├── DataPlugin.swift         # Extensión para eventos de dominio
        ├── ViewPlugin.swift         # Extensión para UI adicional
        ├── PluginRegistry.swift     # Registro + event bus
        └── PluginDiscovery.swift    # Auto-descubrimiento de plugins

HabitAppTests/
├── HabitTests.swift               # Tests del modelo Habit
└── HabitListViewModelTests.swift  # Tests del ViewModel
````

---

## 📦 Requisitos

- **macOS** con **Xcode 15+** instalado
- **iOS Simulator** para ejecutar tests de iOS (en local o CI)
- **Swift 5.9+** (para soporte de macros `@Model`, `@Test`, etc.)

---

## 🚀 Instalación y ejecución

### Desde Xcode

1. **Clona** el repositorio:
   ```bash
   git clone https://github.com/uallps/habitapp4.git
   cd habitapp4
   ```

2. **Abre** el proyecto en Xcode (`HabitApp.xcodeproj`).

3. **Selecciona** el scheme:
   - `HabitApp` (scheme principal, incluye tests)
   - `HabitApp Premium` (build alternativo, sin tests)

4. **Ejecuta** (⌘R) en:
   - iOS Simulator (iPhone/iPad)
   - macOS (My Mac - Designed for iPad o nativo según target)

> **Nota**: el entry point es `TaskAppMain` en `HabitApp/Application/TaskApp.swift`. El nombre del `@main` struct no coincide necesariamente con el nombre del scheme/target.

### Desde la terminal

Para ejecutar la app en un simulador específico:

```bash
xcrun simctl boot "iPhone 15"
open -a Simulator
```

Luego, en otra terminal, dentro del directorio del proyecto:

```bash
xcodebuild \
  -project HabitApp.xcodeproj \
  -scheme "HabitApp" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  build
```

---

## Apartado 7: Tests

```md
---

## 🧪 Tests

Los tests viven en [HabitAppTests](http://_vscodecontentref_/0) y usan el **Swift Testing framework** (macros `@Test`, `@Suite`, `#expect`).

### Qué se testea

| Archivo | Scope | Validaciones |
|---------|-------|--------------|
| [HabitTests.swift](http://_vscodecontentref_/1) | Modelo `Habit` | Inicialización, completion por periodo, serialización `Codable` |
| `HabitListViewModelTests.swift` | `HabitListViewModel` | CRUD operations con `StorageProvider` mockeado (load/add/remove/toggle) |

### Ejecutar tests

```bash
# Desde Xcode: ⌘U en el scheme "HabitApp"
# O por terminal:
xcodebuild test \
  -project HabitApp.xcodeproj \
  -scheme "HabitApp" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```
`````

```md
### Ejemplo de test (Swift Testing)

```swift
@Test("Habit toggles completion for current period")
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
---

## Apartado 8: Persistencia

```md
### Implementaciones disponibles

| Provider | Uso | Detalles |
|----------|-----|----------|
| `SwiftDataStorageProvider` | **Producción (por defecto)** | Persistencia nativa con SwiftData + `ModelContainer` |
| `JSONStorageProvider` | Export/import manual | Guarda hábitos en JSON en disco (útil para backup) |
| `MockStorageProvider` | Previews y tests | En memoria; no persiste entre ejecuciones |

### Cambiar el backend de persistencia

Edita `AppConfig.swift`:

```swift
// Cambiar de SwiftData a JSON:
let storageProvider: StorageProvider = JSONStorageProvider()

// O usar Mock para desarrollo sin side effects:
let storageProvider: StorageProvider = MockStorageProvider()

---

## 💾 Persistencia

### Contrato base

[StorageProvider.swift](http://_vscodecontentref_/2):

```swift
@MainActor
protocol StorageProvider: AnyObject {
    func loadHabits() async throws -> [Habit]
    func saveHabits(habits: [Habit]) async throws
}
`````

---

## Apartado 9: Sistema de plugins

```md
#### 2. `DataPlugin`

Permite reaccionar a eventos del dominio:

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
---

## 🔌 Sistema de plugins

Infraestructura en `HabitApp/Infrastructure/Plugins/`.

### Protocolos clave

#### 1. `FeaturePlugin`

Base para todas las features:

```swift
protocol FeaturePlugin {
    var isEnabled: Bool { get }
    init(config: AppConfig)
}
```

---

## 🔄 Flujo de datos y eventos

Ejemplo: marcar un hábito como completado.

1. User → View → ViewModel.toggleCompletion()
              ├─ Update model
              ├─ StorageProvider.save()
              └─ PluginRegistry.notify()
                 └─ All DataPlugins react:
                    ├─ StreakPlugin updates streaks
                    ├─ StatsPlugin recalculates metrics
                    └─ RewardsPlugin grants XP

### Flujo de datos típico

1. **Usuario** interactúa con una `View` (ej. marca hábito completado)
2. **View** llama al `ViewModel.toggleCompletion(...)`
3. **ViewModel**:
   - Actualiza el modelo `Habit`
   - Persiste vía `StorageProvider.saveHabits(...)`
   - Notifica a `PluginRegistry.notifyHabitCompletionDidChange(...)`
4. **Plugins** suscritos (`StreakPlugin`, `StatsPlugin`, `RewardsPlugin`):
   - Reciben el evento
   - Actualizan su estado interno (rachas, estadísticas, XP, etc.)
   - Persisten sus propios datos si es necesario

**Ventaja clave**: el Core nunca conoce qué plugins existen → desacoplamiento total.
```

---

## Apartado 10: CI/CD con GitHub Actions

```md
### Triggers

```yaml
on:
  push:
    branches: [main, develop, "feature/**"]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:
  
---

## 🔄 CI/CD con GitHub Actions

Configuración en `.github/workflows/build.yml`.

### Jobs principales

1. **`build`**: compila + ejecuta tests en matriz (iOS/macOS × schemes)
2. **`create-release`**: empaqueta builds y crea releases automáticas en `main`

### Configuración de matrix

```yaml
strategy:
  matrix:
    platform: [iOS, macOS]
    scheme: ["HabitApp", "HabitApp Premium"]
    include:
      - platform: iOS
        sdk: iphonesimulator
        destination: "platform=iOS Simulator,name=iPhone 15,OS=latest"
      - platform: macOS
        sdk: macosx
        destination: "platform=macOS"
```
`````

---

## Apartado 11: Convenciones de código

```md
---

## 📝 Convenciones de código

### Naming

- **Archivos y carpetas**: PascalCase (`HabitListView.swift`, `Models/`)
- **Protocolos**: sufijo descriptivo (`StorageProvider`, `DataPlugin`)
- **ViewModels**: sufijo `ViewModel` (`HabitListViewModel`)

### Async/await

- Toda persistencia es `async throws`
- Compatible con Swift Concurrency (no callbacks)

### MainActor

- `@MainActor` en ViewModels y StorageProviders
- Simplifica binding con SwiftUI (no necesita `DispatchQueue.main.async`)

### Testing

- Framework: **Swift Testing** (no XCTest clásico)
- Macros: `@Test`, `@Suite`, `#expect`
- Mock providers para inyección de dependencias

### Commits

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

---

## 🤝 Contribución

¡Contribuciones bienvenidas! Sigue estos pasos:

1. **Fork** el repositorio
2. **Crea una branch** desde `develop`:
   ```bash
   git checkout develop
   git checkout -b feature/mi-nueva-feature


---

## Apartado 13: Roadmap

```md
---

## 🗺️ Roadmap

### v1.1 (Q1 2026)
- [ ] Tests unitarios por feature (`StreakPluginTests`, `CategoryPluginTests`)
- [ ] Export/import completo a JSON/CSV
- [ ] Localización (i18n) a inglés y español

### v1.2 (Q2 2026)
- [ ] Widgets iOS 17+ (pantalla de inicio + lock screen)
- [ ] Soporte de temas (light/dark/auto + temas custom)
- [ ] Integración con HealthKit (opcional)

### v2.0 (Q3 2026)
- [ ] Sincronización con iCloud (CloudKit)
- [ ] Modo offline-first con reconciliación automática
- [ ] App para watchOS

### Futuro
- [ ] Compartir hábitos con otros usuarios
- [ ] Comunidad y desafíos públicos
- [ ] Estadísticas avanzadas con ML (predicción de rachas)

---

## 📚 Recursos y referencias

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Swift Testing (SE-0384)](https://github.com/apple/swift-testing)
- [WWDC 2023: Meet SwiftData](https://developer.apple.com/videos/play/wwdc2023/10187/)
- [Plugin Architecture Pattern](https://martinfowler.com/articles/plugin.html)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

## 📄 Licencia

Pendiente. Añade aquí la licencia cuando corresponda (MIT, Apache 2.0, GPL, etc.).

---

## 💬 Contacto y soporte

- **Issues**: [Reportar bugs o solicitar features](https://github.com/uallps/habitapp4/issues)
- **Discussions**: [Preguntas generales o ideas](https://github.com/uallps/habitapp4/discussions)
- **Pull Requests**: siempre bienvenidos (revisa [Contribución](#-contribución))

---

**Hecho con ❤️ en SwiftUI**