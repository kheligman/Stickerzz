import SwiftUI
import SwiftData

struct RoutineCard: View {
    let group: HabitGroup

    @Environment(\.modelContext) private var context
    @State private var isExpanded = false
    @State private var showTimer = false

    private var coreHabits: [Habit] { group.sortedHabits.filter { !$0.isLuxe && $0.shouldAppearInToday() } }
    private var luxeHabits: [Habit]  { group.sortedHabits.filter { $0.isLuxe } }
    private var done: Int    { coreHabits.filter { $0.isCompleted(on: $0.activeDate()) }.count }
    private var skipped: Int { coreHabits.filter { $0.isSkipped(on: $0.activeDate()) }.count }
    private var total: Int   { coreHabits.count }
    private var allHandled: Bool { total > 0 && (done + skipped) == total }

    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            if isExpanded {
                Divider().padding(.horizontal, 12)
                habitList
            }
        }
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .sheet(isPresented: $showTimer) {
            RoutineSessionView(group: group)
        }
    }

    // MARK: - Header

    private var cardHeader: some View {
        HStack(spacing: 10) {
            // Expand/collapse tappable zone
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(group.color)
                        .frame(width: 4, height: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.name).font(.headline)
                        Text(statsLabel)
                            .font(.caption)
                            .foregroundStyle(allHandled ? Color.accent : .secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Divider().frame(height: 24)

            // Navigate to detail
            NavigationLink(value: group) {
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            // Timer (opt-in)
            Button { showTimer = true } label: {
                Image(systemName: "timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private var statsLabel: String {
        guard total > 0 else { return "No habits scheduled" }
        if allHandled { return "All done ✓" }
        return "\(done) of \(total) done"
    }

    // MARK: - Habit List

    private var habitList: some View {
        VStack(spacing: 0) {
            ForEach(coreHabits) { habit in
                InlineHabitRow(habit: habit, date: habit.activeDate())
                if habit.id != coreHabits.last?.id {
                    Divider().padding(.leading, 52)
                }
            }

            if !luxeHabits.isEmpty {
                Divider()
                DisclosureGroup {
                    ForEach(luxeHabits) { habit in
                        InlineHabitRow(habit: habit, date: .now)
                    }
                } label: {
                    Label("Bonus", systemImage: "sparkles")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Inline Habit Row (shared across card + session)

struct InlineHabitRow: View {
    let habit: Habit
    let date: Date

    @Environment(\.modelContext) private var context

    private enum ToggleState { case none, done, skipped }

    private var state: ToggleState {
        if habit.isCompleted(on: date) { return .done }
        if habit.isSkipped(on: date)   { return .skipped }
        return .none
    }

    var body: some View {
        Button(action: cycle) {
            HStack(spacing: 14) {
                Text(habit.emoji).font(.title3).frame(width: 28)

                Text(habit.name)
                    .font(.body)
                    .foregroundStyle(state == .none ? .primary : .secondary)
                    .strikethrough(state == .done)

                Spacer()

                stateIcon
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
