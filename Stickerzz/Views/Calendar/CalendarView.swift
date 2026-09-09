import SwiftUI
import SwiftData

enum CalendarViewMode: String, CaseIterable {
    case month    = "Month"
    case week     = "7 Day"
    case threeDay = "3 Day"
}

enum CalendarFilter: Equatable {
    case all
    case group(PersistentIdentifier)
    case luxe
}

struct CalendarView: View {
    @Query(sort: \HabitGroup.sortOrder) private var groups: [HabitGroup]
    @Query private var completions: [HabitCompletion]

    @State private var displayedMonth: Date = Calendar.current.firstDayOfMonth(for: .now)
    @State private var filter: CalendarFilter = .all
    @State private var selectedDay: Date? = nil
    @State private var viewMode: CalendarViewMode = .month
    @State private var sevenDayPage: Int = 1000
    @State private var threeDayPage: Int = 1000

    private let cal = Calendar.current
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var selectedGroup: HabitGroup? {
        guard case .group(let id) = filter else { return nil }
        return groups.first { $0.id == id }
    }

    private var isShowingToday: Bool {
        switch viewMode {
        case .month:    return cal.isDate(displayedMonth, equalTo: .now, toGranularity: .month)
        case .week:     return sevenDayPage == 1000
        case .threeDay: return threeDayPage == 1000
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode
                Picker("View", selection: $viewMode) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 6)

                // Period header
                if viewMode == .month {
                    monthNavigator.padding(.horizontal)
                } else {
                    Text(periodLabel)
                        .font(.subheadline.weight(.medium))
                        .padding(.vertical, 2)
                }

                groupFilterRow.padding(.vertical, 8)

                Divider()

                switch viewMode {
                case .month:
                    weekdayHeader.padding(.horizontal, 4)
                    Divider()
                    calendarGrid.padding(.horizontal, 4)

                case .week:
                    SevenDayView(
                        completions: completions,
                        filter: filter,
                        selectedDay: $selectedDay,
                        page: $sevenDayPage
                    )

                case .threeDay:
                    ThreeDayView(
                        completions: completions,
                        filter: filter,
                        selectedDay: $selectedDay,
                        page: $threeDayPage
                    )
                }
            }
            .navigationTitle("Stickerzz")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") { jumpToToday() }
                        .opacity(isShowingToday ? 0 : 1)
                        .disabled(isShowingToday)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedDay != nil },
            set: { if !$0 { selectedDay = nil } }
        )) {
            if let day = selectedDay {
                DayDetailSheet(date: day, group: selectedGroup)
                    .presentationDetents([.medium, .large])
            }
        }
        .onChange(of: viewMode) { _, _ in
            // Reset to today when switching modes
            sevenDayPage = 1000
            threeDayPage = 1000
        }
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: "chevron.left").font(.body.weight(.semibold)).foregroundStyle(.primary)
            }
            Spacer()
            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.title3.weight(.semibold))
            Spacer()
            Button { shiftMonth(by: 1) } label: {
                Image(systemName: "chevron.right").font(.body.weight(.semibold)).foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Period Label (week / 3-day)

    private var periodLabel: String {
        let today = cal.startOfDay(for: .now)
        let fmt: Date.FormatStyle = .dateTime.month(.abbreviated).day()

        switch viewMode {
        case .month: return ""
        case .week:
            let center = cal.date(byAdding: .day, value: sevenDayPage - 1000, to: today)!
            let start  = cal.date(byAdding: .day, value: -3, to: center)!
            let end    = cal.date(byAdding: .day, value:  3, to: center)!
            return "\(start.formatted(fmt)) – \(end.formatted(fmt))"
        case .threeDay:
            let center = cal.date(byAdding: .day, value: threeDayPage - 1000, to: today)!
            let start  = cal.date(byAdding: .day, value: -1, to: center)!
            let end    = cal.date(byAdding: .day, value:  1, to: center)!
            return "\(start.formatted(fmt)) – \(end.formatted(fmt))"
        }
    }

    // MARK: - Group Filter

    private var groupFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", color: .accent, isSelected: filter == .all) {
                    filter = .all
                }
                FilterChip(label: "✨ Luxe", color: .orange, isSelected: filter == .luxe) {
                    filter = (filter == .luxe) ? .all : .luxe
                }
                ForEach(groups) { group in
                    FilterChip(
                        label: group.name,
                        color: group.color,
                        isSelected: filter == .group(group.id)
                    ) {
                        filter = (filter == .group(group.id)) ? .all : .group(group.id)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Weekday Header (month only)

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Month Calendar Grid

    private var calendarGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        CalendarDayCell(
                            date: day,
                            emojis: emojis(for: day),
                            isToday: cal.isDateInToday(day),
                            isSelected: selectedDay.map { cal.isDate($0, inSameDayAs: day) } ?? false,
                            isPerfectDay: filter != .luxe && isPerfectDay(day)
                        )
                        .onTapGesture { selectedDay = day }
                    } else {
                        Color.clear.frame(minHeight: 64)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var calendarDays: [Date?] {
        let offset   = cal.leadingOffset(for: displayedMonth)
        let dayCount = cal.daysInMonth(for: displayedMonth)
        var days: [Date?] = Array(repeating: nil, count: offset)
        for i in 0..<dayCount {
            days.append(cal.date(byAdding: .day, value: i, to: displayedMonth))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    func emojis(for date: Date) -> [String] {
        let day = cal.startOfDay(for: date)
        return completions.filter { c in
            c.dateDay == day && c.type == .done && matchesFilter(c)
        }.compactMap { $0.habit?.emoji }
    }

    func matchesFilter(_ c: HabitCompletion) -> Bool {
        switch filter {
        case .all:            return true
        case .luxe:           return c.habit?.isLuxe == true
        case .group(let id):  return c.habit?.group?.id == id
        }
    }

    private func isPerfectDay(_ date: Date) -> Bool {
        let relevantGroups: [HabitGroup] = {
            if case .group(let id) = filter { return groups.filter { $0.id == id } }
            return groups
        }()
        return relevantGroups.contains { grp in
            let scheduled = grp.sortedHabits.filter { !$0.isLuxe && $0.isOnSchedule(on: date) }
            guard !scheduled.isEmpty else { return false }
            return scheduled.allSatisfy { $0.isCompleted(on: date) }
        }
    }

    private func shiftMonth(by value: Int) {
        guard let shifted = cal.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = shifted
    }

    private func jumpToToday() {
        switch viewMode {
        case .month:
            withAnimation { displayedMonth = cal.firstDayOfMonth(for: .now) }
        case .week:
            sevenDayPage = 1000
        case .threeDay:
            threeDayPage = 1000
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : Color(.systemGray6), in: Capsule())
        }
    }
}
