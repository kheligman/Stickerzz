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
    case habit(PersistentIdentifier)
    case tag(String)
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
    @State private var showFilterSheet = false

    private let cal = Calendar.current
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    @Environment(AppNavigation.self) private var navigation

    private var selectedGroup: HabitGroup? {
        guard case .group(let id) = filter else { return nil }
        return groups.first { $0.id == id }
    }

    private var habitForFilter: Habit? {
        guard case .habit(let id) = filter else { return nil }
        return groups.flatMap { $0.habits }.first { $0.persistentModelID == id }
    }

    private var allTags: [String] {
        Array(Set(groups.flatMap { $0.habits }.flatMap { $0.tags })).sorted()
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

                if filter != .all {
                    HStack {
                        activeFilterChip
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    Divider()
                }

                switch viewMode {
                case .month:
                    weekdayHeader.padding(.horizontal, 4)
                    Divider()
                    calendarGrid.padding(.horizontal, 4)

                case .week:
                    SevenDayView(
                        completions: completions,
                        filter: filter,
                        groups: groups,
                        selectedDay: $selectedDay,
                        page: $sevenDayPage
                    )

                case .threeDay:
                    ThreeDayView(
                        completions: completions,
                        filter: filter,
                        groups: groups,
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showFilterSheet = true } label: {
                        Image(systemName: filter == .all
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                            .foregroundStyle(filter == .all ? .primary : Color.accent)
                    }
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
            sevenDayPage = 1000
            threeDayPage = 1000
        }
        .onAppear { applyPendingFilter() }
        .onChange(of: navigation.pendingCalendarFilter) { _, _ in applyPendingFilter() }
        .sheet(isPresented: $showFilterSheet) {
            CalendarFilterSheet(filter: $filter, groups: groups, allTags: allTags)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

    // MARK: - Active Filter Chip

    private var activeFilterChip: some View {
        HStack(spacing: 5) {
            Text(activeFilterLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accent)
            Button { filter = .all } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.accent.opacity(0.6))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.accent.opacity(0.1), in: Capsule())
    }

    private var activeFilterLabel: String {
        switch filter {
        case .all:   return ""
        case .luxe:  return "✨ Luxe"
        case .group(let id):
            guard let group = groups.first(where: { $0.id == id }) else { return "" }
            if group.isStandalone, let habit = group.sortedHabits.first {
                return "\(habit.emoji) \(habit.name)"
            }
            return group.emoji.isEmpty ? group.name : "\(group.emoji) \(group.name)"
        case .habit(let id):
            guard let habit = groups.flatMap({ $0.habits }).first(where: { $0.persistentModelID == id }) else { return "" }
            return "\(habit.emoji) \(habit.name)"
        case .tag(let name):
            return "#\(name)"
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

    func matchesFilter(_ c: HabitCompletion) -> Bool {
        switch filter {
        case .all:            return true
        case .luxe:           return c.habit?.isLuxe == true
        case .group(let id):  return c.habit?.group?.id == id
        case .habit(let id):  return c.habit?.persistentModelID == id
        case .tag(let name):  return c.habit?.tags.contains(name) == true
        }
    }

    private func applyPendingFilter() {
        guard let f = navigation.pendingCalendarFilter else { return }
        filter = f
        navigation.pendingCalendarFilter = nil
    }

    private func isPerfectDay(_ date: Date) -> Bool {
        if case .habit = filter { return false }
        if case .tag = filter { return false }
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

// MARK: - Filter Chip (used by StreaksView)

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

// MARK: - Calendar Filter Sheet

struct CalendarFilterSheet: View {
    @Binding var filter: CalendarFilter
    let groups: [HabitGroup]
    let allTags: [String]

    @Environment(\.dismiss) private var dismiss

    private var routines: [HabitGroup]   { groups.filter { !$0.isStandalone } }
    private var standalones: [HabitGroup] { groups.filter { $0.isStandalone } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    filterRow(label: "All", icon: { Image(systemName: "square.grid.2x2").foregroundStyle(.secondary) },
                              isSelected: filter == .all) { filter = .all }
                }

                if !routines.isEmpty {
                    Section("Routines") {
                        ForEach(routines) { group in
                            filterRow(
                                label: group.emoji.isEmpty ? group.name : "\(group.emoji) \(group.name)",
                                icon: {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(group.color)
                                        .frame(width: 22, height: 22)
                                },
                                isSelected: filter == .group(group.id)
                            ) { filter = .group(group.id) }
                        }
                    }
                }

                if !standalones.isEmpty {
                    Section("Habits") {
                        ForEach(standalones) { group in
                            if let habit = group.sortedHabits.first {
                                filterRow(
                                    label: "\(habit.emoji) \(habit.name)",
                                    icon: { EmptyView() },
                                    isSelected: filter == .group(group.id)
                                ) { filter = .group(group.id) }
                            }
                        }
                    }
                }

                if !allTags.isEmpty {
                    Section("Tags") {
                        ForEach(allTags, id: \.self) { tag in
                            filterRow(
                                label: "#\(tag)",
                                icon: { Image(systemName: "tag").foregroundStyle(.secondary) },
                                isSelected: filter == .tag(tag)
                            ) { filter = .tag(tag) }
                        }
                    }
                }

                Section {
                    filterRow(
                        label: "✨ Luxe",
                        icon: { EmptyView() },
                        isSelected: filter == .luxe
                    ) { filter = .luxe }
                }
            }
            .navigationTitle("Filter by")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func filterRow<Icon: View>(
        label: String,
        icon: () -> Icon,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                icon().frame(width: 22)
                Text(label).foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(Color.accent).fontWeight(.semibold)
                }
            }
        }
    }
}
