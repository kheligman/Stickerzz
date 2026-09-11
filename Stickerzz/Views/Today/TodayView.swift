import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \HabitGroup.sortOrder) private var groups: [HabitGroup]
    @State private var showSummary = false
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @State private var weekAnchor: Date = Calendar.current.startOfDay(for: .now)
    @State private var showDatePicker = false

    private let cal = Calendar.current

    private var greeting: String {
        let hour = cal.component(.hour, from: .now)
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:     return "Good evening"
        }
    }

    private var navigationTitle: String {
        if cal.isDateInToday(selectedDate) { return greeting }
        if cal.isDateInYesterday(selectedDate) { return "Yesterday" }
        return selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var allTodayHabits: [Habit] {
        groups.flatMap { $0.sortedHabits.filter { !$0.isLuxe && $0.shouldAppearInToday(on: selectedDate) } }
    }

    private var doneCount: Int {
        allTodayHabits.filter { $0.isCompleted(on: $0.activeDate(for: selectedDate)) }.count
    }

    private var weekDays: [Date] {
        guard let interval = cal.dateInterval(of: .weekOfYear, for: weekAnchor) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: interval.start) }
    }

    // Returns true when a group is fully handled and should sink to the bottom
    private func isGroupDone(_ group: HabitGroup) -> Bool {
        if group.isStandalone {
            guard let habit = group.sortedHabits.first, !habit.isLuxe else { return false }
            return habit.isCompleted(on: habit.activeDate(for: selectedDate))
        }
        let core = group.sortedHabits.filter { !$0.isLuxe && $0.shouldAppearInToday(on: selectedDate) }
        guard !core.isEmpty else { return false }
        let required = core.filter { $0.isRequired }
        let preferred = core.filter { !$0.isRequired }
        let done    = core.filter { $0.isCompleted(on: $0.activeDate(for: selectedDate)) }.count
        let skipped = core.filter { $0.isSkipped(on: $0.activeDate(for: selectedDate)) }.count
        let mvpDone = !required.isEmpty && required.allSatisfy { $0.isCompleted(on: $0.activeDate(for: selectedDate)) }
        return preferred.isEmpty ? (done + skipped) == core.count : mvpDone
    }

    private var sortedGroups: [HabitGroup] {
        groups.sorted { a, b in
            let aDone = isGroupDone(a)
            let bDone = isGroupDone(b)
            if aDone != bDone { return !aDone }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayStrip
                Divider()

                Group {
                    if groups.isEmpty {
                        todayEmptyState
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                progressHeader
                                    .padding(.horizontal)

                                ForEach(sortedGroups) { group in
                                    if group.isStandalone, let habit = group.sortedHabits.first {
                                        if habit.shouldAppearInToday(on: selectedDate) || habit.isLuxe {
                                            StandaloneHabitCard(habit: habit, date: selectedDate)
                                                .padding(.horizontal)
                                        }
                                    } else if !group.isStandalone {
                                        RoutineCard(group: group, date: selectedDate)
                                            .padding(.horizontal)
                                    }
                                }

                                Spacer(minLength: 32)
                            }
                            .padding(.top, 8)
                            .animation(.spring(response: 0.45, dampingFraction: 0.8),
                                       value: sortedGroups.map { isGroupDone($0) })
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: HabitGroup.self) { group in
                GroupDetailView(group: group)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSummary = true } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showDatePicker = true } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showSummary) {
                DaySummarySheet()
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { selectedDate },
                            set: { newDate in
                                selectedDate = cal.startOfDay(for: newDate)
                                weekAnchor = cal.startOfDay(for: newDate)
                            }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.accent)
                    .padding()
                    .navigationTitle("Jump to Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showDatePicker = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Day Strip

    private var dayStrip: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    weekAnchor = cal.date(byAdding: .day, value: -7, to: weekAnchor) ?? weekAnchor
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                    .contentShape(Rectangle())
            }

            ForEach(weekDays, id: \.self) { day in
                DayPill(
                    date: day,
                    isSelected: cal.isDate(day, inSameDayAs: selectedDate),
                    isToday: cal.isDateInToday(day)
                ) {
                    withAnimation(.spring(response: 0.2)) {
                        selectedDate = day
                    }
                }
            }

            Button {
                withAnimation(.spring(response: 0.3)) {
                    weekAnchor = cal.date(byAdding: .day, value: 7, to: weekAnchor) ?? weekAnchor
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
    }

    // MARK: - Subviews

    private var todayEmptyState: some View {
        VStack(spacing: 16) {
            Text("🌱")
                .font(.system(size: 56))
            Text("Nothing here yet")
                .font(.headline)
            Text("Add a habit or routine in the Manage tab to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var progressHeader: some View {
        let total = allTodayHabits.count
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(total == 0 ? "Nothing scheduled" : "\(doneCount) of \(total) done")
                    .font(.headline)
            }
            Spacer()
            CircularProgress(fraction: total > 0 ? Double(doneCount) / Double(total) : 0)
                .frame(width: 48, height: 48)
        }
    }
}

// MARK: - Day Pill

private struct DayPill: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    private let cal = Calendar.current
    private var dayLetter: String { date.formatted(.dateTime.weekday(.narrow)) }
    private var dayNumber: String { "\(cal.component(.day, from: date))" }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(dayLetter)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .secondary)
                ZStack {
                    Circle()
                        .fill(isToday && !isSelected ? Color.accent : .clear)
                        .frame(width: 26, height: 26)
                    Text(dayNumber)
                        .font(.system(size: 15, weight: (isToday || isSelected) ? .bold : .regular))
                        .foregroundStyle(isSelected || isToday ? .white : .primary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accent : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Circular Progress

struct CircularProgress: View {
    let fraction: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color(.systemGray5), lineWidth: 5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(fraction * 100))%")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.accent)
        }
    }
}

// MARK: - Standalone Habit Card

struct StandaloneHabitCard: View {
    let habit: Habit
    let date: Date
    @Environment(\.modelContext) private var context
    @Environment(AppNavigation.self) private var navigation

    private var streak: Int { StreakEngine.currentStreak(for: habit) }
    private enum ToggleState { case none, done, skipped }

    private var state: ToggleState {
        if habit.isCompleted(on: date) { return .done }
        if habit.isSkipped(on: date)   { return .skipped }
        return .none
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(habit.emoji).font(.title2)

            Text(habit.name)
                .font(.body)
                .foregroundStyle(state == .none ? .primary : .secondary)
                .strikethrough(state == .done)

            Spacer()

            if streak > 0 {
                Button { navigation.showCalendar(filteredTo: habit) } label: {
                    HStack(spacing: 3) {
                        Text("\(streak)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accent)
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.accent.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Button(action: cycle) { stateIcon }
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    @ViewBuilder private var stateIcon: some View {
        switch state {
        case .none:    Image(systemName: "circle").foregroundStyle(Color(.systemGray3)).font(.title3)
        case .done:    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accent).font(.title3)
        case .skipped: Image(systemName: "minus.circle.fill").foregroundStyle(Color(.systemGray3)).font(.title3)
        }
    }

    private func cycle() {
        switch state {
        case .none:
            context.insert(HabitCompletion(date: date, type: .done, habit: habit))
        case .done:
            removeExisting()
            context.insert(HabitCompletion(date: date, type: .skipped, habit: habit))
        case .skipped:
            removeExisting()
        }
    }

    private func removeExisting() {
        if let c = habit.completions.first(where: { Calendar.current.isDate($0.dateDay, inSameDayAs: date) }) {
            context.delete(c)
        }
    }
}
