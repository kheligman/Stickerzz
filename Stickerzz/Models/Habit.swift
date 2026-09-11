import SwiftData
import Foundation

@Model
final class Habit {
    var name: String
    var emoji: String
    var frequencyRaw: String
    var targetCount: Int
    var sortOrder: Int
    var startDate: Date
    // Default values enable SwiftData lightweight migration
    var isLuxe: Bool = false
    var isRequired: Bool = true
    var scheduledWeekdaysRaw: String = ""
    var tagsRaw: String = ""
    var group: HabitGroup?
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    init(
        name: String,
        emoji: String,
        frequency: FrequencyType = .daily,
        targetCount: Int = 1,
        sortOrder: Int = 0,
        startDate: Date = .now,
        isLuxe: Bool = false,
        scheduledWeekdays: Set<Int> = []
    ) {
        self.name = name
        self.emoji = emoji
        self.frequencyRaw = frequency.rawValue
        self.targetCount = targetCount
        self.sortOrder = sortOrder
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.isLuxe = isLuxe
        self.scheduledWeekdaysRaw = scheduledWeekdays.sorted().map(String.init).joined(separator: ",")
    }

    var frequency: FrequencyType {
        get { FrequencyType(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    var scheduledWeekdays: Set<Int> {
        get { Set(scheduledWeekdaysRaw.split(separator: ",").compactMap { Int($0) }) }
        set { scheduledWeekdaysRaw = newValue.sorted().map(String.init).joined(separator: ",") }
    }

    var tags: Set<String> {
        get { Set(tagsRaw.split(separator: ",").map { String($0) }.filter { !$0.isEmpty }) }
        set { tagsRaw = newValue.sorted().joined(separator: ",") }
    }

    // MARK: - Completion state

    func isCompleted(on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return completions.contains { $0.dateDay == day && $0.type == .done }
    }

    func isSkipped(on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return completions.contains { $0.dateDay == day && $0.type == .skipped }
    }

    // MARK: - Scheduling

    // Is this habit's weekday schedule active on a given date?
    func isOnSchedule(on date: Date) -> Bool {
        guard frequency == .specificDays else { return true }
        let weekday = Calendar.current.component(.weekday, from: date)
        return scheduledWeekdays.contains(weekday)
    }

    // Should this habit appear in Today view on a given date?
    // For specificDays: shows on scheduled day OR as a makeup until next scheduled day arrives.
    func shouldAppearInToday(on date: Date = .now) -> Bool {
        guard !isLuxe else { return false }
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)

        switch frequency {
        case .daily, .weekly:
            return true
        case .specificDays:
            for offset in 0..<7 {
                guard let checkDate = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
                let weekday = cal.component(.weekday, from: checkDate)
                if scheduledWeekdays.contains(weekday) {
                    return !isCompleted(on: checkDate) && !isSkipped(on: checkDate)
                }
            }
            return false
        }
    }

    // The actual date this habit is "targeting" in Today view (may be a recent past scheduled day)
    func activeDate(for today: Date = .now) -> Date {
        guard frequency == .specificDays else { return Calendar.current.startOfDay(for: today) }
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: today)
        for offset in 0..<7 {
            guard let checkDate = cal.date(byAdding: .day, value: -offset, to: todayStart) else { continue }
            let weekday = cal.component(.weekday, from: checkDate)
            if scheduledWeekdays.contains(weekday) { return checkDate }
        }
        return todayStart
    }
}
