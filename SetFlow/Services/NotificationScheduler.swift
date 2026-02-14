//
//  NotificationScheduler.swift
//  SetFlow
//

import Foundation
import UserNotifications

/// Schedules local notifications for workout reminders. If athlete has a workout
/// scheduled for today, schedules a reminder at the default time (e.g. 6 PM).
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleWorkoutReminderIfNeeded(workoutTitle: String, workoutDate: Date, reminderHour: Int = 18) {
        let calendar = Calendar.current
        guard calendar.isDateInToday(workoutDate) else { return }
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized else { return }
            self?.scheduleReminder(title: workoutTitle, hour: reminderHour)
        }
    }

    func cancelWorkoutReminders() {
        center.removePendingNotificationRequests(withIdentifiers: ["setflow-workout-reminder"])
    }

    private func scheduleReminder(title: String, hour: Int) {
        cancelWorkoutReminders()
        let content = UNMutableNotificationContent()
        content.title = "Time to train"
        content.body = "\(title) is on your schedule for today."
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "setflow-workout-reminder", content: content, trigger: trigger)
        center.add(request)
    }
}
