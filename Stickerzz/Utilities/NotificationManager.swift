import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    // Schedule (or reschedule) a daily reminder for a group/habit.
    // Safe to call after every save — it cancels the old request first.
    func reschedule(for group: HabitGroup) {
        let id = notificationID(for: group)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        guard group.reminderEnabled else { return }

        let content = UNMutableNotificationContent()
        if group.isStandalone, let habit = group.sortedHabits.first {
            content.title = "\(habit.emoji) \(habit.name)"
            content.body = "Time to check in."
        } else {
            content.title = group.name
            content.body = "Time to check in on your routine."
        }
        content.sound = .default

        var components = DateComponents()
        components.hour = group.reminderHour
        components.minute = group.reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancel(for group: HabitGroup) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID(for: group)])
    }

    private func notificationID(for group: HabitGroup) -> String {
        "stickerzz-\(String(describing: group.persistentModelID))"
    }
}
