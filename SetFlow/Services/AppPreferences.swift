//
//  AppPreferences.swift
//  SetFlow
//

import Foundation
import SwiftUI
import Combine

enum WeightUnit: String, CaseIterable, Codable {
    case kg
    case lb

    var displayName: String {
        switch self {
        case .kg: return String(localized: "unit_kilograms")
        case .lb: return String(localized: "unit_pounds")
        }
    }

    func displayWeight(kg: Double) -> String {
        switch self {
        case .kg: return "\(Int(kg)) kg"
        case .lb: return "\(Int(kg * 2.205)) lb"
        }
    }

    func displayVolume(kg: Double) -> String {
        switch self {
        case .kg: return "\(Int(kg)) kg"
        case .lb: return "\(Int(kg * 2.205)) lb"
        }
    }
}

final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    private enum Keys {
        static let weightUnit = "app.preferences.weightUnit"
        static let notificationsEnabled = "app.preferences.notificationsEnabled"
        static let reminderHour = "app.preferences.reminderHour"
        
        static func athleteFirstRunOnboardingSeen(userId: String) -> String {
            "app.preferences.onboarding.athlete.\(userId)"
        }
        
        static func coachFirstRunOnboardingSeen(userId: String) -> String {
            "app.preferences.onboarding.coach.\(userId)"
        }

        static func coachWorkoutTemplates(userId: String) -> String {
            "app.preferences.workoutTemplates.coach.\(userId)"
        }
    }

    private let defaults = UserDefaults.standard

    @Published var weightUnit: WeightUnit {
        didSet {
            defaults.set(weightUnit.rawValue, forKey: Keys.weightUnit)
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
            if !notificationsEnabled {
                NotificationScheduler.shared.cancelWorkoutReminders()
            }
        }
    }

    @Published var reminderHour: Int {
        didSet {
            let clamped = min(23, max(0, reminderHour))
            if clamped != reminderHour { reminderHour = clamped }
            defaults.set(reminderHour, forKey: Keys.reminderHour)
        }
    }

    private init() {
        let rawUnit = defaults.string(forKey: Keys.weightUnit) ?? WeightUnit.kg.rawValue
        self.weightUnit = WeightUnit(rawValue: rawUnit) ?? .kg
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        if defaults.object(forKey: Keys.reminderHour) != nil {
            self.reminderHour = min(23, max(0, defaults.integer(forKey: Keys.reminderHour)))
        } else {
            self.reminderHour = 18
        }
    }

    func displayWeight(kg: Double) -> String {
        weightUnit.displayWeight(kg: kg)
    }

    func displayVolume(kg: Double) -> String {
        weightUnit.displayVolume(kg: kg)
    }
    
    func hasSeenFirstRunOnboarding(role: UserRole, userId: String) -> Bool {
        switch role {
        case .athlete:
            return defaults.bool(forKey: Keys.athleteFirstRunOnboardingSeen(userId: userId))
        case .coach:
            return defaults.bool(forKey: Keys.coachFirstRunOnboardingSeen(userId: userId))
        }
    }
    
    func markFirstRunOnboardingSeen(role: UserRole, userId: String) {
        switch role {
        case .athlete:
            defaults.set(true, forKey: Keys.athleteFirstRunOnboardingSeen(userId: userId))
        case .coach:
            defaults.set(true, forKey: Keys.coachFirstRunOnboardingSeen(userId: userId))
        }
    }

    func coachWorkoutTemplates(userId: String) -> [WorkoutTemplate] {
        let key = Keys.coachWorkoutTemplates(userId: userId)
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([WorkoutTemplate].self, from: data)) ?? []
    }

    func saveCoachWorkoutTemplate(userId: String, template: WorkoutTemplate) {
        var templates = coachWorkoutTemplates(userId: userId)
        templates.removeAll { $0.id == template.id }
        templates.insert(template, at: 0)
        if templates.count > 40 {
            templates = Array(templates.prefix(40))
        }
        let key = Keys.coachWorkoutTemplates(userId: userId)
        if let data = try? JSONEncoder().encode(templates) {
            defaults.set(data, forKey: key)
        }
    }
}
