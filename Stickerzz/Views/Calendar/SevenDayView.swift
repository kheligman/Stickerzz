import SwiftUI
import SwiftData

struct SevenDayView: View {
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
                SevenDayPage(
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

// MARK: - Page (7 columns)

private struct SevenDayPage: View {
    let centerDate: Date
    let completions: [HabitCompletion]
    let filter: CalendarFilter
    let groups: [HabitGroup]
    @Binding var selectedDay: Date?

    private var days: [Date] {
        let cal = Calendar.current
        return (-3...3).compactMap { cal.date(byAdding: .day, value: $0, to: centerDate) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                SevenDayColumn(
                    date: day,
                    emojis: emojis(for: day),
                    isToday: Calendar.current.isDateInToday(day),
                    isSelected: selectedDay.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false
                )
                .onTapGesture { selectedDay = day }
            }
        }
        .padding(.horizontal, 2)
        .padding(.top, 8)
    }

    private func emojis(for date: Date) -> [String] {
        let day = Calendar.current.startOfDay(for: date)

        if case .all = filter {
            var result: [String] = []
            for group in groups {
                let hasCompletion = completions.contains { c in
                    c.dateDay == day && c.type == .done && c.habit?.group?.id == group.id && !(c.habit?.isLuxe ?? false)
                }
                guard hasCompletion else { continue }
                if group.isStandalone {
                    if let emoji = completions.first(where: { c in
                        c.dateDay == day && c.type == .done && c.habit?.group?.id == group.id
                    })?.habit?.emoji {
                        result.append(emoji)
                    }
                } else {
                    result.append(group.emoji.isEmpty ? "📋" : group.emoji)
                }
            }
            return result
        }

        return completions.filter { c in
            c.dateDay == day && c.type == .done && matchesFilter(c)
        }.compactMap { $0.habit?.emoji }
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

private struct SevenDayColumn: View {
    let date: Date
    let emojis: [String]
    let isToday: Bool
    let isSelected: Bool

    private var dayLetter: String {
        date.formatted(.dateTime.weekday(.narrow))
    }

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        VStack(spacing: 4) {
            // Day header
            VStack(spacing: 2) {
                Text(dayLetter)
                    .font(.caption2)
                    .foregroundStyle(isToday ? .primary : .secondary)

                Text(dayNumber)
                    .font(.caption2.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? .white : .primary)
                    .frame(width: 22, height: 22)
                    .background(isToday ? Color.accent : .clear, in: Circle())
            }

            // Emojis
            VStack(spacing: 1) {
                ForEach(Array(emojis.prefix(8).enumerated()), id: \.offset) { _, emoji in
                    Text(emoji).font(.system(size: 17))
                }
                if emojis.count > 8 {
                    Text("+\(emojis.count - 8)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 6)
        .background(
            isSelected ? Color(.systemGray5) : .clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isToday ? Color(.systemGray3) : Color(.systemGray5),
                    lineWidth: isToday ? 1 : 0.5
                )
        )
        .padding(.horizontal, 1)
    }
}
