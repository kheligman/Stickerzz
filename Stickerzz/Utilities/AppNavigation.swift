import Observation
import SwiftData

@Observable
final class AppNavigation {
    static let shared = AppNavigation()
    private init() {}

    var selectedTab: Int = 1               // 0=Calendar 1=Today 2=Streaks 3=Manage
    var pendingCalendarFilter: CalendarFilter? = nil
    var retappedTab: Int? = nil

    func showCalendar(filteredTo habit: Habit) {
        pendingCalendarFilter = .habit(habit.persistentModelID)
        selectedTab = 0
    }

    func showCalendar(filteredToTag tag: String) {
        pendingCalendarFilter = .tag(tag)
        selectedTab = 0
    }
}
