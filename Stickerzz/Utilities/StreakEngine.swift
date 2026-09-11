import Foundation

enum StreakEngine {

    // MARK: - Public API

    static func currentStreak(for group: HabitGroup) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let required = group.habits.filter { !$0.isLuxe && $0.isRequired }
        guard !required.isEmpty else { return 0 }

        let mvpDates = mvpDoneSet(required: required, cal: cal)

        let anchor: Date
        if mvpDates.contains(today) {
            anchor = today
        } else {
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            guard mvpDates.contains(yesterday) else { return 0 }
            anchor = yesterday
        }

        var streak = 0
        var cursor = anchor
        while mvpDates.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    static func bestStreak(for group: HabitGroup) -> Int {
        let cal = Calendar.current
        let required = group.habits.filter { !$0.isLuxe && $0.isRequired }
        guard !required.isEmpty else { return 0 }
        let mvpDates = mvpDoneSet(required: required, cal: cal).sorted()
        guard !mvpDates.isEmpty else { return 0 }

        var best = 0, current = 0
        var last: Date? = nil
        for date in mvpDates {
            if let prev = last {
                let gap = cal.dateComponents([.day], from: prev, to: date).day ?? 0
                if gap > 1 { current = 0 }
            }
            current += 1
            best = max(best, current)
            last = date
        }
        return best
    }

    static func currentStreak(for habit: Habit) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let dones = doneSet(habit)
        let skips = skipSet(habit)

        switch habit.frequency {
        case .daily:
            return dailyCurrent(dones: dones, skips: skips, today: today, cal: cal)
        case .weekly:
            return weeklyCurrent(dones: dones, target: habit.targetCount, today: today, cal: cal)
        case .specificDays:
            return specificDaysCurrent(habit: habit, dones: dones, skips: skips, today: today, cal: cal)
        }
    }

    static func bestStreak(for habit: Habit) -> Int {
        let cal = Calendar.current
        let dones = doneSet(habit)
        let skips = skipSet(habit)

        switch habit.frequency {
        case .daily:
            return dailyBest(dones: dones, skips: skips, cal: cal)
        case .weekly:
            return weeklyBest(dones: dones, target: habit.targetCount, cal: cal)
        case .specificDays:
            return specificDaysBest(habit: habit, dones: dones, skips: skips, cal: cal)
        }
    }

    // MARK: - Daily
    // Skipped days are transparent: don't break the streak, don't increment the count.

    private static func dailyCurrent(dones: Set<Date>, skips: Set<Date>, today: Date, cal: Calendar) -> Int {
        let anchor: Date
        if dones.contains(today) || skips.contains(today) {
            anchor = today
        } else {
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            guard dones.contains(yesterday) || skips.contains(yesterday) else { return 0 }
            anchor = yesterday
        }

        var streak = 0
        var cursor = anchor
        while true {
            if dones.contains(cursor) {
                streak += 1
            } else if skips.contains(cursor) {
                // transparent — continue going back
            } else {
                break
            }
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    private static func dailyBest(dones: Set<Date>, skips: Set<Date>, cal: Calendar) -> Int {
        guard !dones.isEmpty else { return 0 }
        let allDates = dones.union(skips).sorted()
        var best = 0
        var current = 0
        var lastDate: Date? = nil

        for date in allDates {
            if let prev = lastDate {
                let gap = cal.dateComponents([.day], from: prev, to: date).day ?? 0
                if gap > 1 { current = 0 }
            }
            if dones.contains(date) { current += 1 }
            best = max(best, current)
            lastDate = date
        }
        return best
    }

    // MARK: - Weekly

    private static func weeklyCurrent(dones: Set<Date>, target: Int, today: Date, cal: Calendar) -> Int {
        var weekStart = cal.date(byAdding: .weekOfYear, value: -1, to: cal.startOfWeek(for: today))!
        var streak = 0
        while true {
            let weekEnd = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            let count = dones.filter { $0 >= weekStart && $0 < weekEnd }.count
            guard count >= target else { break }
            streak += 1
            weekStart = cal.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
        }
        return streak
    }

    private static func weeklyBest(dones: Set<Date>, target: Int, cal: Calendar) -> Int {
        guard !dones.isEmpty else { return 0 }
        var weekStart = cal.startOfWeek(for: dones.min()!)
        let stop = cal.date(byAdding: .weekOfYear, value: 1, to: cal.startOfWeek(for: .now))!
        var best = 0, current = 0
        while weekStart < stop {
            let weekEnd = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            let count = dones.filter { $0 >= weekStart && $0 < weekEnd }.count
            if count >= target { current += 1; best = max(best, current) }
            else { current = 0 }
            weekStart = weekEnd
        }
        return best
    }

    // MARK: - Specific Days
    // Counts consecutive SCHEDULED days that were done. Skips are transparent.

    private static func specificDaysCurrent(habit: Habit, dones: Set<Date>, skips: Set<Date>, today: Date, cal: Calendar) -> Int {
        let weekdays = habit.scheduledWeekdays
        guard !weekdays.isEmpty else { return 0 }

        var streak = 0
        var cursor = today

        // If today is a scheduled day but not yet done/skipped: grace (start from yesterday)
        let todayWeekday = cal.component(.weekday, from: today)
        if weekdays.contains(todayWeekday) && !dones.contains(today) && !skips.contains(today) {
            cursor = cal.date(byAdding: .day, value: -1, to: today)!
        }

        let startDate = cal.startOfDay(for: habit.startDate)
        while cursor >= startDate {
            let weekday = cal.component(.weekday, from: cursor)
            if weekdays.contains(weekday) {
                if dones.contains(cursor) {
                    streak += 1
                } else if skips.contains(cursor) {
                    // transparent
                } else {
                    break // missed scheduled day
                }
            }
            // non-scheduled days: transparent
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    private static func specificDaysBest(habit: Habit, dones: Set<Date>, skips: Set<Date>, cal: Calendar) -> Int {
        let weekdays = habit.scheduledWeekdays
        guard !weekdays.isEmpty else { return 0 }

        let startDate = cal.startOfDay(for: habit.startDate)
        let today = cal.startOfDay(for: .now)
        var best = 0, current = 0
        var cursor = startDate

        while cursor <= today {
            let weekday = cal.component(.weekday, from: cursor)
            if weekdays.contains(weekday) {
                if dones.contains(cursor) {
                    current += 1
                    best = max(best, current)
                } else if skips.contains(cursor) {
                    // transparent
                } else if cursor < today {
                    current = 0 // missed past scheduled day
                }
            }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        return best
    }

    // MARK: - Helpers

    private static func mvpDoneSet(required: [Habit], cal: Calendar) -> Set<Date> {
        guard !required.isEmpty else { return [] }
        var result = Set(required[0].completions.filter { $0.type == .done }.map(\.dateDay))
        for habit in required.dropFirst() {
            let doneDates = Set(habit.completions.filter { $0.type == .done }.map(\.dateDay))
            result = result.intersection(doneDates)
        }
        return result
    }

    private static func doneSet(_ habit: Habit) -> Set<Date> {
        Set(habit.completions.filter { $0.type == .done }.map(\.dateDay))
    }

    private static func skipSet(_ habit: Habit) -> Set<Date> {
        Set(habit.completions.filter { $0.type == .skipped }.map(\.dateDay))
    }
}
