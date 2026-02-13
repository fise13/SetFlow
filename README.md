## SetFlow – SwiftUI UI Prototype

This is a UI-only SwiftUI prototype for a fitness coaching app targeting **iOS** and **watchOS**, using a lightweight MVVM structure and an internal design system.

### Structure

- `App/` – Entry point (`FitnessCoachApp`) and root navigation.
- `DesignSystem/` – Colors, typography, spacing.
- `Models/` – User, WorkoutPlan, WorkoutDay, Exercise, WorkoutLog.
- `MockData/` – In-memory mock data used by all views.
- `Components/` – Reusable UI components (buttons, cards, progress bar, etc.).
- `Views/Auth/` – Auth and onboarding flow.
- `Views/Athlete/` – Athlete home, workout detail, live workout, summary, history.
- `Views/Coach/` – Coach dashboard, athlete profile, plan builder, editors, send update.
- `Views/Watch/` – Watch workout list, live workout, rest timer, finish screen.

### Notes

- No external dependencies; everything uses SwiftUI and system frameworks.
- All major screens include `PreviewProvider` implementations and support light/dark mode.
- Haptic feedback and timers are stubbed in a way that is safe for UI previews and can be fleshed out later.

