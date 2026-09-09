import Testing
import SwiftUI
import Foundation
import SwiftData
@testable import Stickerzz

// MARK: - Shared test infrastructure

/// Creates a fresh in-memory SwiftData container.
/// Each test that calls this gets full isolation.
@MainActor
func makeTestContainer() throws -> (ModelContainer, ModelContext) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: HabitGroup.self, Habit.self, HabitCompletion.self,
        configurations: config
    )
    return (container, ModelContext(container))
}

// MARK: - Shared model factories

@MainActor
func makeHabit(
    in context: ModelContext,
    frequency: FrequencyType = .daily,
    targetCount: Int = 1,
    scheduledWeekdays: Set<Int> = [],
    isLuxe: Bool = false,
    startDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: .now)!
) -> Habit {
    let group = HabitGroup(name: "Test Group", colorHex: "#A8D5E2")
    context.insert(group)
    let habit = Habit(
        name: "Test Habit",
        emoji: "🧪",
        frequency: frequency,
        targetCount: targetCount,
        startDate: startDate,
        isLuxe: isLuxe,
        scheduledWeekdays: scheduledWeekdays
    )
    habit.group = group
    context.insert(habit)
    return habit
}

@MainActor
func log(_ habit: Habit, on date: Date, type: CompletionType = .done, in context: ModelContext) {
    let c = HabitCompletion(date: date, type: type, habit: habit)
    context.insert(c)
}

/// Returns today offset by N days (negative = past).
func date(daysFromToday offset: Int) -> Date {
    Calendar.current.date(
        byAdding: .day,
        value: offset,
        to: Calendar.current.startOfDay(for: .now)
    )!
}

/// Returns the Nth most recent occurrence of a given weekday (1=Sun…7=Sat).
/// n=1 = most recent (may be today), n=2 = one week before that, etc.
func nthPastOccurrence(of weekday: Int, n: Int) -> Date {
    let cal = Calendar.current
    var cursor = cal.startOfDay(for: .now)
    var found = 0
    while true {
        if cal.component(.weekday, from: cursor) == weekday {
            found += 1
            if found == n { return cursor }
        }
        cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
    }
}

// MARK: - Smoke tests

@MainActor
struct StickerzzTests {

    @Test func habitCreation_setsFieldsCorrectly() throws {
        let (_, context) = try makeTestContainer()
        let habit = makeHabit(in: context, frequency: .daily)
        #expect(habit.name == "Test Habit")
        #expect(habit.emoji == "🧪")
        #expect(habit.frequency == .daily)
        #expect(habit.completions.isEmpty)
    }

    @Test func completionLogging_appearsOnHabit() throws {
        let (_, context) = try makeTestContainer()
        let habit = makeHabit(in: context)
        log(habit, on: .now, type: .done, in: context)
        #expect(habit.completions.count == 1)
        #expect(habit.completions.first?.type == .done)
    }

    @Test func skippedCompletion_distinctFromDone() throws {
        let (_, context) = try makeTestContainer()
        let habit = makeHabit(in: context)
        log(habit, on: .now, type: .skipped, in: context)
        #expect(habit.isCompleted(on: .now) == false)
        #expect(habit.isSkipped(on: .now) == true)
    }

    @Test func colorHex_parsesCorrectly() {
        #expect(Color(hex: "#A8D5E2") != nil)
        #expect(Color(hex: "A8D5E2") != nil)  // without #
        #expect(Color(hex: "ZZZZZZ") == nil)  // invalid
        #expect(Color(hex: "#FFF") == nil)     // short form not supported
    }

    @Test func arrayChunked_splitsCorrectly() {
        let arr = [1, 2, 3, 4, 5]
        let chunks = arr.chunked(into: 2)
        #expect(chunks.count == 3)
        #expect(chunks[0] == [1, 2])
        #expect(chunks[1] == [3, 4])
        #expect(chunks[2] == [5])
    }

    @Test func arrayChunked_emptyArray() {
        let arr: [Int] = []
        #expect(arr.chunked(into: 3).isEmpty)
    }

    @Test func calendarExtensions_daysInMonth() {
        // September 2026 has 30 days
        let sep = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 1))!
        #expect(Calendar.current.daysInMonth(for: sep) == 30)

        // February 2024 (leap year) has 29 days
        let feb2024 = Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 1))!
        #expect(Calendar.current.daysInMonth(for: feb2024) == 29)

        // February 2023 (non-leap) has 28 days
        let feb2023 = Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 1))!
        #expect(Calendar.current.daysInMonth(for: feb2023) == 28)
    }

    @Test func frequencyType_rawValues() {
        #expect(FrequencyType(rawValue: "daily") == .daily)
        #expect(FrequencyType(rawValue: "weekly") == .weekly)
        #expect(FrequencyType(rawValue: "specificDays") == .specificDays)
        #expect(FrequencyType(rawValue: "unknown") == nil)
    }
}
