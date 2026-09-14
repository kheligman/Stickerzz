import SwiftUI
import SwiftData

struct ThreeDayView: View {
    let completions: [HabitCompletion]
    let filter: CalendarFilter
    let groups: [HabitGroup]
    @Binding var selectedDay: Date?
    @Binding var page: Int

    static let centerPage = 1000
    static let pageCount  = 2001

    private let today = Calendar.current.startOfDay(for: .now)

    private func centerDate(for p: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: p - Self.centerPage, to: today)!
    }

    var body: some View {
        TabView(selection: $page) {
            ForEach(0..<Self.pageCount, id: \.self) { p in
                ThreeDayPage(
                    centerDate: centerDate(for: p),
                    completions: completions,
                    filter: filter,
                    groups: groups,
                    selectedDay: $selectedDay
                )
                .tag(p)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Page (3 columns)

private struct ThreeDayPage: View {
    let centerDate: Date
    let completions: [HabitCompletion]
    let filter: CalendarFilter
    let groups: [HabitGroup]
    @Binding var selectedDay: Date?

    private var days: [Date] {
        let cal = Calendar.current
        return (-1...1).compactMap { cal.date(byAdding: .day, value: $0, to: centerDate) }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.self) { day in
                ThreeDayColumn(
                    date: day,
                    habits: completedHabits(for: day),
                    isToday: Calendar.current.isDateInToday(day),
                    isSelected: selectedDay.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false
                )
                .onTapGesture { selectedDay = day }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    private func completedHabits(for date: Date) -> [(emoji: String, name: String)] {
        let day = Calendar.current.startOfDay(for: date)
        return completions
            .filter { c in
                c.dateDay == day &&
                c.type == .done &&
                matchesFilter(c) &&
                (filter == .luxe || !(c.habit?.isLuxe ?? false))
            }
            .compactMap { c in
                guard let e = c.habit?.emoji, let n = c.habit?.name else { return nil }
                return (emoji: e, name: n)
            }
    }

    private func matchesFilter(_ c: HabitCompletion) -> Bool {
        switch filter {
        case .all:            return true
        case .luxe:           return c.habit?.isLuxe == true
        case .group(let id):  return c.habit?.group?.id == id
        case .habit(let id):  return c.habit?.persistentModelID == id
        case .tag(let name):  return c.habit?.tags.contains(name) == true
        }
    }
}

// MARK: - Column

private struct ThreeDayColumn: View {
    let date: Date
    let habits: [(emoji: String, name: String)]
    let isToday: Bool
    let isSelected: Bool

    private let cal = Calendar.current

    private var headerLabel: String {
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        if cal.isDateInTomorrow(date)  { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.abbreviated))
    }

    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(headerLabel)
                    .font(.caption2.weight(isToday ? .semibold : .regular))
                    .foregroundStyle(isToday ? .primary : .secondary)

                Text(dayNumber)
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? .white : .primary)
                    .frame(width: 30, height: 30)
                    .background(isToday ? Color.accent : .clear, in: Circle())
            }
            .padding(.top, 10)
            .padding(.bottom, 10)

            Divider()

            // Habit rows
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    if habits.isEmpty {
                        Text("—")
                            .font(.caption2)
                            .foregroundStyle(Color(.systemGray4))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    } else {
                        ForEach(Array(habits.prefix(12).enumerated()), id: \.offset) { _, habit in
                            HStack(spacing: 5) {
                                Text(habit.emoji)
                                    .font(.system(size: 14))
                                Text(habit.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                            }
                        }
                        if habits.count > 12 {
                            Text("+\(habits.count - 12) more")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            isSelected
                ? Color(.systemGray5)
                : (isToday ? Color.primary.opacity(0.04) : .clear),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isToday ? Color.primary.opacity(0.25) : Color(.systemGray4),
                    lineWidth: isToday ? 1.5 : 0.5
                )
        )
    }
}
