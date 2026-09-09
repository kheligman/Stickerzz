import Testing
import SwiftData
@testable import Stickerzz

@MainActor
struct HabitModelTests {

    // MARK: - isCompleted

    @Test func isCompleted_trueWhenDoneLogged() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx)
        log(habit, on: .now, type: .done, in: ctx)
        #expect(habit.isCompleted(on: .now) == true)
    }

    @Test func isCompleted_falseWhenSkipped() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx)
        log(habit, on: .now, type: .skipped, in: ctx)
        #expect(habit.isCompleted(on: .now) == false)
    }

    @Test func isCompleted_falseWhenNothingLogged() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx)
        #expect(habit.isCompleted(on: .now) == false)
    }

    @Test func isCompleted_matchesByDay_notTime() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx)
        // Log at noon
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        log(habit, on: noon, type: .done, in: ctx)
        // Query at a different time of day — should still find it
        let evening = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now)!
        #expect(habit.isCompleted(on: evening) == true)
    }

    // MARK: - isSkipped

    @Test func isSkipped_trueWhenSkippedLogged() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx)
        log(habit, on: .now, type: .skipped, in: ctx)
        #expect(habit.isSkipped(on: .now) == true)
    }

    @Test func isSkipped_falseWhenDone() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx)
        log(habit, on: .now, type: .done, in: ctx)
        #expect(habit.isSkipped(on: .now) == false)
    }

    @Test func isSkipped_falseWhenNothingLogged() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx)
        #expect(habit.isSkipped(on: .now) == false)
    }

    // MARK: - isOnSchedule

    @Test func isOnSchedule_dailyAlwaysTrue() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        #expect(habit.isOnSchedule(on: .now) == true)
        #expect(habit.isOnSchedule(on: date(daysFromToday: -3)) == true)
    }

    @Test func isOnSchedule_weeklyAlwaysTrue() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .weekly)
        #expect(habit.isOnSchedule(on: .now) == true)
    }

    @Test func isOnSchedule_specificDays_trueOnScheduledWeekday() throws {
        let (_, ctx) = try makeTestContainer()
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])
        #expect(habit.isOnSchedule(on: .now) == true)
    }

    @Test func isOnSchedule_specificDays_falseOnUnscheduledDay() throws {
        let (_, ctx) = try makeTestContainer()
        let cal = Calendar.current
        let todayWeekday = cal.component(.weekday, from: .now)
        // Schedule on every day EXCEPT today
        let allWeekdays = Set(1...7)
        let otherDays = allWeekdays.subtracting([todayWeekday])
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: otherDays)
        #expect(habit.isOnSchedule(on: .now) == false)
    }

    // MARK: - shouldAppearInToday

    @Test func shouldAppearInToday_daily_alwaysTrue() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        #expect(habit.shouldAppearInToday(on: .now) == true)
    }

    @Test func shouldAppearInToday_luxe_alwaysFalse() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily, isLuxe: true)
        #expect(habit.shouldAppearInToday(on: .now) == false)
    }

    @Test func shouldAppearInToday_specificDays_trueOnScheduledDay() throws {
        let (_, ctx) = try makeTestContainer()
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])
        // Not yet done — should appear
        #expect(habit.shouldAppearInToday(on: .now) == true)
    }

    @Test func shouldAppearInToday_specificDays_hidesAfterDone() throws {
        let (_, ctx) = try makeTestContainer()
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])
        log(habit, on: .now, type: .done, in: ctx)
        // Done today — should no longer appear as outstanding
        #expect(habit.shouldAppearInToday(on: .now) == false)
    }

    @Test func shouldAppearInToday_specificDays_hidesAfterSkipped() throws {
        let (_, ctx) = try makeTestContainer()
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])
        log(habit, on: .now, type: .skipped, in: ctx)
        #expect(habit.shouldAppearInToday(on: .now) == false)
    }

    @Test func shouldAppearInToday_specificDays_makeupDay() throws {
        let (_, ctx) = try makeTestContainer()
        let cal = Calendar.current
        let todayWeekday = cal.component(.weekday, from: .now)
        // Schedule ONLY yesterday's weekday — today is unscheduled
        let yesterday = date(daysFromToday: -1)
        let yesterdayWeekday = cal.component(.weekday, from: yesterday)
        guard yesterdayWeekday != todayWeekday else { return } // skip if same (shouldn't happen ±1 day)
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [yesterdayWeekday])
        // Yesterday not done — should appear today as makeup
        #expect(habit.shouldAppearInToday(on: .now) == true)
    }

    @Test func shouldAppearInToday_specificDays_noMakeup_whenYesterdayDone() throws {
        let (_, ctx) = try makeTestContainer()
        let cal = Calendar.current
        let todayWeekday = cal.component(.weekday, from: .now)
        let yesterday = date(daysFromToday: -1)
        let yesterdayWeekday = cal.component(.weekday, from: yesterday)
        guard yesterdayWeekday != todayWeekday else { return }
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [yesterdayWeekday])
        log(habit, on: yesterday, type: .done, in: ctx)
        // Yesterday done — no longer a makeup day
        #expect(habit.shouldAppearInToday(on: .now) == false)
    }

    // MARK: - activeDate

    @Test func activeDate_daily_returnsToday() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        let today = Calendar.current.startOfDay(for: .now)
        #expect(habit.activeDate(for: .now) == today)
    }

    @Test func activeDate_weekly_returnsToday() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .weekly)
        let today = Calendar.current.startOfDay(for: .now)
        #expect(habit.activeDate(for: .now) == today)
    }

    @Test func activeDate_specificDays_returnsToday_whenScheduled() throws {
        let (_, ctx) = try makeTestContainer()
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])
        let today = Calendar.current.startOfDay(for: .now)
        #expect(habit.activeDate(for: .now) == today)
    }

    @Test func activeDate_specificDays_returnsMostRecentScheduledDay() throws {
        let (_, ctx) = try makeTestContainer()
        let cal = Calendar.current
        let todayWeekday = cal.component(.weekday, from: .now)
        let yesterday = date(daysFromToday: -1)
        let yesterdayWeekday = cal.component(.weekday, from: yesterday)
        guard yesterdayWeekday != todayWeekday else { return }
        // Only yesterday's weekday is scheduled
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [yesterdayWeekday])
        #expect(habit.activeDate(for: .now) == yesterday)
    }
}
