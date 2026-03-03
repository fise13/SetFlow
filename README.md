# SetFlow

**SetFlow** — мобильное приложение для планирования и выполнения тренировок в связке тренер ↔ атлет. Тренер создаёт недельные планы и назначает дни тренировок, атлет видит расписание, выполняет тренировки с таймером отдыха и ведёт историю. Поддерживаются Live Activity (Dynamic Island, экран блокировки) и синхронизация с Apple Watch.

---

## Возможности

### Роли

- **Тренер (Coach)**  
  Дашборд атлетов, создание и редактирование планов по неделям, выбор упражнений из каталога, дублирование недель, шаблоны, отправка обновлений атлетам, инвайт по коду, профиль.

- **Атлет (Athlete)**  
  Домашний экран с календарём недели и сегодняшней тренировкой, экран «Тренировка» с живым выполнением (подходы, отдых, смена упражнений), история и прогресс (графики, объём), профиль и настройки.

### Тренировка в реальном времени

- Показ текущего упражнения, подходов, повторений и веса.
- Таймер отдыха между подходами с возможностью пропуска.
- Сохранение прогресса при уходе с экрана и восстановление при возврате.
- Завершение тренировки с итоговой сводкой и сохранением лога.

### Live Activity и Dynamic Island (iOS 16.2+)

- Во время активной тренировки запускается Live Activity.
- **Dynamic Island**: компактный и развёрнутый вид (название тренировки, упражнение, подходы, отдых, объём).
- **Экран блокировки**: виджет с прогрессом и таймером отдыха.
- Активность **не завершается** при сворачивании приложения в фон — остаётся в Dynamic Island и на Lock Screen до выхода с экрана тренировки или завершения/досрочного окончания.

### Apple Watch

- Отдельные экраны для списка тренировок, живого выполнения и таймера отдыха (WatchConnectivity).

### Остальное

- **Авторизация**: Firebase Auth (email/пароль), выбор роли при первом входе, привязка к тренеру по инвайт-коду.
- **Данные**: Firebase Firestore (пользователи, планы, логи тренировок).
- **Локализация**: английский и русский (`en.lproj`, `ru.lproj`).
- **Дизайн**: единая тема (цвета, типографика, отступы, карточки) в `AppDesignSystem` / `AppTheme`, стеклянные карточки, скелетоны загрузки.

---

## Стек и зависимости

| Технология | Назначение |
|------------|------------|
| **SwiftUI** | UI приложения |
| **Firebase** (SPM) | Auth, Firestore, Analytics, AI (FirebaseAI / FirebaseAILogic) |
| **ActivityKit** | Live Activity (Dynamic Island, Lock Screen) |
| **WatchConnectivity** | Синхронизация с Apple Watch |

- Минимальная версия iOS задаётся в Xcode (Target → General → Minimum Deployments).  
- Live Activity и виджет требуют **iOS 16.2+** (в коде используется `@available(iOS 16.2, *)` и `#available(iOS 16.2, *)`).

---

## Структура проекта

```
SetFlow/
├── SetFlowApp.swift              # @main, Firebase init, RootView
├── App/
│   └── FitnessCoachApp.swift    # AppState, навигация по ролям, загрузка профиля
├── Views/
│   ├── Auth/                     # Welcome, SignIn, SignUp, RoleSelection, InviteCode
│   ├── Athlete/                  # AthleteViews: Home, Workout, LiveWorkout, History, Progress, Profile
│   ├── Coach/                    # CoachViews: Dashboard, Programs, PlanBuilder, WorkoutEditor, Invite, Profile
│   └── Watch/                    # WatchViews: список тренировок, живая тренировка, таймер отдыха
├── Services/
│   ├── AuthService.swift
│   ├── UserService.swift
│   ├── WorkoutPlanService.swift
│   ├── WorkoutLogService.swift
│   ├── WorkoutLiveActivityService.swift   # Старт/обновление/завершение Live Activity
│   ├── CoachRequestService.swift
│   ├── InviteCodeService.swift
│   ├── NotificationScheduler.swift
│   └── WatchConnectivityManager.swift
├── Models/
│   ├── WorkoutModels.swift      # User, WorkoutPlan, WorkoutDay, Exercise, Logs, Catalog
│   └── WorkoutLiveActivityModels.swift  # WorkoutActivityAttributes (общий с виджетом)
├── DesignSystem/
│   └── AppDesignSystem.swift    # AppTheme, AppColors, AppTypography, AppSpacing, компоненты
├── Components/
│   └── AppComponents.swift      # Кнопки, карточки, скелетоны, общие UI
├── MockData/
│   └── MockData.swift
├── Persistence.swift
├── en.lproj / ru.lproj          # Localizable.strings
├── Assets.xcassets
├── GoogleService-Info.plist     # Конфиг Firebase (не в репозитории — добавить вручную)
└── SetFlow.xcdatamodeld

SetFlowWidget/                   # Widget Extension (Live Activity)
├── SetFlowWorkoutLiveActivity.swift  # Lock Screen + Dynamic Island UI
└── en.lproj / ru.lproj

SetFlow/Models/ (Shared)         # WorkoutLiveActivityModels — общий с виджетом
```

---

## Запуск

1. **Клонировать репозиторий**
   ```bash
   git clone <repo-url>
   cd SetFlow
   ```

2. **Добавить Firebase**
   - В [Firebase Console](https://console.firebase.google.com/) создать проект и добавить iOS-приложение с bundle ID `fise.SetFlow`.
   - Скачать `GoogleService-Info.plist` и положить в папку `SetFlow/` (корень основного таргета).

3. **Firestore**
   - Включить Firestore в проекте Firebase.
   - При необходимости задеплоить индексы:
     ```bash
     firebase deploy --only firestore:indexes
     ```
   - Индексы описаны в `firestore.indexes.json` (например, для `workoutPlans` по `coachId`/`athleteId` и `createdAt`).

4. **Сборка и запуск**
   - Открыть `SetFlow.xcodeproj` в Xcode.
   - Выбрать таргет **SetFlow** и симулятор/устройство.
   - Собрать и запустить (⌘R).

5. **Виджет (Live Activity)**
   - Таргет **SetFlowWidgetExtension** собирается вместе с приложением. Модели Live Activity (`WorkoutActivityAttributes`) лежат в основном таргете и в shared-группе, виджет использует ту же модель для контента.

---

## Важные нюансы

### Роль и профиль

- После входа через Firebase загружается профиль из Firestore; по нему определяется роль (`athlete` / `coach`). Если профиля нет — показывается экран выбора роли и создаётся запись пользователя.
- Атлет может привязаться к тренеру по инвайт-коду (экран ввода кода после выбора роли или в настройках).

### Планы и «сегодня»

- План — это список дней (дата + упражнения). «Сегодняшняя» тренировка для атлета определяется по дате дня в плане. Один день плана = одна тренировка в календаре.

### Live Activity

- Запуск: при появлении экрана живой тренировки (`LiveWorkoutView`) вызывается `WorkoutLiveActivityService.start(...)`.
- Обновления: при смене подхода, упражнения и при тике таймера отдыха вызываются соответствующие методы `updateForSetDone`, `updateForExerciseChange`, `updateRest`.
- Завершение: при нажатии «Завершить тренировку» или досрочном окончании — `WorkoutLiveActivityService.complete(...)`; при уходе с экрана тренировки (onDisappear) — `endIfNeeded()`. При переходе приложения в фон активность **не** завершается.

### Редактирование плана (тренер)

- В разделе «План / Неделя» список дней — это кнопки: тап по дню открывает редактор дня в **sheet** (то же поведение, что и «Редактировать» в контекстном меню). Свайпы: удаление и дублирование дня.

### Локализация

- Ключи в коде через `String(localized: "key")`. Строки в `SetFlow/en.lproj/Localizable.strings` и `SetFlow/ru.lproj/Localizable.strings`. Отдельные файлы для виджета в `SetFlowWidget/.../Localizable.strings`.

---

## Документация

- `docs/UI-UX-GLOBAL-IMPROVEMENTS.md` — идеи по пустым состояниям, загрузке, онбордингу и плотности экранов.

---

## Лицензия

Проприетарный проект. Все права сохраняются.
