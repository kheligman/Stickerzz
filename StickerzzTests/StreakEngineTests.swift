import Testing
import SwiftData
@testable import Stickerzz

// MARK: - Daily Streak

@MainActor
struct DailyStreakTests {

    @Test func zero_whenNeverLogged() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        #expect(StreakEngine.currentStreak(for: habit) == 0)
        #expect(StreakEngine.bestStreak(for: habit) == 0)
    }

    @Test func basic_consecutiveDays() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        for offset in 0...4 {
            log(habit, on: date(daysFromToday: -offset), type: .done, in: ctx)
        }
        #expect(StreakEngine.currentStreak(for: habit) == 5)
    }

    @Test func singleDay_streakIsOne() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        log(habit, on: .now, type: .done, in: ctx)
        #expect(StreakEngine.currentStreak(for: habit) == 1)
    }

    @Test func gracePeriod_todayNotDoneButYesterdayWas() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        // Done yesterday and the day before — but NOT today
        log(habit, on: date(daysFromToday: -1), type: .done, in: ctx)
        log(habit, on: date(daysFromToday: -2), type: .done, in: ctx)
        // Streak should still be 2 (today not yet done, grace period active)
        #expect(StreakEngine.currentStreak(for: habit) == 2)
    }

    @Test func gracePeriod_breaks_whenYesterdayAlsoMissed() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        // Done 2 days ago and earlier — yesterday AND today missed
        log(habit, on: date(daysFromToday: -2), type: .done, in: ctx)
        log(habit, on: date(daysFromToday: -3), type: .done, in: ctx)
        #expect(StreakEngine.currentStreak(for: habit) == 0)
    }

    @Test func gap_resetsStreak() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        // Done today and yesterday, then a gap, then more
        log(habit, on: date(daysFromToday:  0), type: .done, in: ctx)
        log(habit, on: date(daysFromToday: -1), type: .done, in: ctx)
        // gap on day -2
        log(habit, on: date(daysFromToday: -3), type: .done, in: ctx)
        log(habit, on: date(daysFromToday: -4), type: .done, in: ctx)
        log(habit, on: date(daysFromToday: -5), type: .done, in: ctx)
        // Current streak = 2 (today + yesterday); best = 3
        #expect(StreakEngine.currentStreak(for: habit) == 2)
        #expect(StreakEngine.bestStreak(for: habit) == 3)
    }

    @Test func skip_isTransparent_doesNotBreakStreak() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        log(habit, on: date(daysFromToday:  0), type: .done,    in: ctx)
        log(habit, on: date(daysFromToday: -1), type: .skipped, in: ctx) // transparent
        log(habit, on: date(daysFromToday: -2), type: .done,    in: ctx)
        log(habit, on: date(daysFromToday: -3), type: .done,    in: ctx)
        // Streak should be 3 done days (skip doesn't count or break)
        #expect(StreakEngine.currentStreak(for: habit) == 3)
    }

    @Test func skip_doesNotIncrementCount() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        // Done 3 days, skipped today — streak count = 3 (skip transparent at top)
        log(habit, on: date(daysFromToday:  0), type: .skipped, in: ctx)
        log(habit, on: date(daysFromToday: -1), type: .done,    in: ctx)
        log(habit, on: date(daysFromToday: -2), type: .done,    in: ctx)
        log(habit, on: date(daysFromToday: -3), type: .done,    in: ctx)
        #expect(StreakEngine.currentStreak(for: habit) == 3)
    }

    @Test func onlySkips_returnsZero() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        for offset in 0...4 {
            log(habit, on: date(daysFromToday: -offset), type: .skipped, in: ctx)
        }
        #expect(StreakEngine.currentStreak(for: habit) == 0)
    }

    @Test func bestStreak_tracksLongestRun() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        // Run of 5 (old), gap, run of 2 (recent)
        for offset in 10...14 {
            log(habit, on: date(daysFromToday: -offset), type: .done, in: ctx)
        }
        // gap at 8 and 9
        log(habit, on: date(daysFromToday: -7), type: .done, in: ctx)
        log(habit, on: date(daysFromToday: -6), type: .done, in: ctx)
        // gap at 3-5
        log(habit, on: date(daysFromToday: -2), type: .done, in: ctx)
        log(habit, on: date(daysFromToday: -1), type: .done, in: ctx)

        #expect(StreakEngine.bestStreak(for: habit) == 5)
        #expect(StreakEngine.currentStreak(for: habit) == 2)
    }

    @Test func bestStreak_withSkips() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .daily)
        // Done 5 days with a skip in the middle — best done-count = 4 (5 days, 1 skip)
        log(habit, on: date(daysFromToday:  0), type: .done,    in: ctx)
        log(habit, on: date(daysFromToday: -1), type: .done,    in: ctx)
        log(habit, on: date(daysFromToday: -2), type: .skipped, in: ctx)
        log(habit, on: date(daysFromToday: -3), type: .done,    in: ctx)
        log(habit, on: date(daysFromToday: -4), type: .done,    in: ctx)
        // 4 done days, no gap (skip is transparent)
        #expect(StreakEngine.bestStreak(for: habit) == 4)
    }
}

// MARK: - Weekly Streak

@MainActor
struct WeeklyStreakTests {

    @Test func zero_whenNeverLogged() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .weekly, targetCount: 3)
        #expect(StreakEngine.currentStreak(for: habit) == 0)
    }

    @Test func currentWeekInProgress_doesNotBreakStreak() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .weekly, targetCount: 2)

        // Last week: 2 completions (hits target) → streak = 1
        let lastWeekStart = Calendar.current.startOfWeek(for: date(daysFromToday: -7))
        log(habit, on: Calendar.current.date(byAdding: .day, value: 1, to: lastWeekStart)!, in: ctx)
        log(habit, on: Calendar.current.date(byAdding: .day, value: 2, to: lastWeekStart)!, in: ctx)

        // This week: only 1 completion so far (in progress — shouldn't break streak)
        log(habit, on: date(daysFromToday: 0), in: ctx)

        #expect(StreakEngine.currentStreak(for: habit) == 1)
    }

    @Test func missedWeek_resetsStreak() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .weekly, targetCount: 2)

        let cal = Calendar.current
        // 3 weeks ago: hit target
        let threeWeeksAgo = cal.startOfWeek(for: date(daysFromToday: -21))
        log(habit, on: cal.date(byAdding: .day, value: 1, to: threeWeeksAgo)!, in: ctx)
        log(habit, on: cal.date(byAdding: .day, value: 2, to: threeWeeksAgo)!, in: ctx)

        // 2 weeks ago: MISSED (no completions that week)

        // Last week: hit target
        let lastWeekStart = cal.startOfWeek(for: date(daysFromToday: -7))
        log(habit, on: cal.date(byAdding: .day, value: 1, to: lastWeekStart)!, in: ctx)
        log(habit, on: cal.date(byAdding: .day, value: 2, to: lastWeekStart)!, in: ctx)

        // Current streak = 1 (only last week, broken by 2-weeks-ago miss)
        #expect(StreakEngine.currentStreak(for: habit) == 1)
    }

    @Test func bestWeeklyStreak_tracksCorrectly() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .weekly, targetCount: 1)

        let cal = Calendar.current
        // 4 consecutive completed weeks (weeks 5-8 ago), then a gap, then 1 week (last week)
        for weeksAgo in [8, 7, 6, 5] {
            let ws = cal.startOfWeek(for: date(daysFromToday: -(weeksAgo * 7)))
            log(habit, on: cal.date(byAdding: .day, value: 1, to: ws)!, in: ctx)
        }
        // week 4 ago: miss
        // week 3 ago: miss
        // 2 weeks ago and last week: done
        for weeksAgo in [2, 1] {
            let ws = cal.startOfWeek(for: date(daysFromToday: -(weeksAgo * 7)))
            log(habit, on: cal.date(byAdding: .day, value: 1, to: ws)!, in: ctx)
        }

        #expect(StreakEngine.bestStreak(for: habit) == 4)
        #expect(StreakEngine.currentStreak(for: habit) == 2)
    }

    @Test func belowTarget_doesNotCountWeek() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .weekly, targetCount: 3)

        let lastWeekStart = Calendar.current.startOfWeek(for: date(daysFromToday: -7))
        // Only 2 completions when target is 3
        log(habit, on: Calendar.current.date(byAdding: .day, value: 1, to: lastWeekStart)!, in: ctx)
        log(habit, on: Calendar.current.date(byAdding: .day, value: 2, to: lastWeekStart)!, in: ctx)

        #expect(StreakEngine.currentStreak(for: habit) == 0)
    }
}

// MARK: - Specific Days Streak

@MainActor
struct SpecificDayStreakTests {

    /// Returns the weekday number for today (1=Sun…7=Sat)
    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: Calendar.current.startOfDay(for: .now))
    }

    @Test func zero_whenNeverLogged() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])
        #expect(StreakEngine.currentStreak(for: habit) == 0)
    }

    @Test func onlyCountsScheduledDays() throws {
        let (_, ctx) = try makeTestContainer()
        // Schedule ONLY on today's weekday
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])

        // Log 3 consecutive occurrences of today's weekday (today, -7, -14)
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 1), in: ctx)
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 2), in: ctx)
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 3), in: ctx)

        #expect(StreakEngine.currentStreak(for: habit) == 3)
    }

    @Test func missedScheduledDay_breaksStreak() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])

        // Done on most recent occurrence, missed second most recent, done on third
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 1), in: ctx)
        // n=2 is missed
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 3), in: ctx)

        // Streak = 1 (only the most recent consecutive run)
        #expect(StreakEngine.currentStreak(for: habit) == 1)
    }

    @Test func skipOnScheduledDay_isTransparent() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])

        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 1), type: .done,    in: ctx)
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 2), type: .skipped, in: ctx) // transparent
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 3), type: .done,    in: ctx)

        // Streak = 2 done days (skip doesn't break, doesn't count)
        #expect(StreakEngine.currentStreak(for: habit) == 2)
    }

    @Test func gracePeriod_todayScheduledButNotYetDone() throws {
        let (_, ctx) = try makeTestContainer()
        // Schedule includes today
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])

        // Done on all previous occurrences but NOT today yet
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 2), in: ctx)
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 3), in: ctx)

        // Streak should still be 2 (today not done yet but grace period active)
        #expect(StreakEngine.currentStreak(for: habit) == 2)
    }

    @Test func bestStreak_tracksCorrectly() throws {
        let (_, ctx) = try makeTestContainer()
        let habit = makeHabit(in: ctx, frequency: .specificDays, scheduledWeekdays: [todayWeekday])

        // Done 4 consecutive, gap at n=5, done 2 consecutive at n=6 and n=7
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 1), in: ctx)
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 2), in: ctx)
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 3), in: ctx)
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 4), in: ctx)
        // n=5 missed
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 6), in: ctx)
        log(habit, on: nthPastOccurrence(of: todayWeekday, n: 7), in: ctx)

        #expect(StreakEngine.bestStreak(for: habit) == 4)
        #expect(StreakEngine.currentStreak(for: habit) == 4)
    }
}
