import SwiftUI
import SwiftData

struct DayDetailSheet: View {
    let date: Date
    let group: HabitGroup?

    @Environment(\.modelContext) private var context
    @Query(sort: \HabitGroup.sortOrder) private var allGroups: [HabitGroup]

    private var displayedGroups: [HabitGroup] {
        group.map { [$0] } ?? allGroups
    }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(displayedGroups) { grp in
                    let coreHabits = grp.sortedHabits.filter { !$0.isLuxe }
                    let luxeHabits = grp.sortedHabits.filter { $0.isLuxe }

                    if !coreHabits.isEmpty {
                        Section(grp.name) {
                            ForEach(coreHabits) { habit in
                                HabitToggleRow(habit: habit, date: date)
                            }
                        }
                    }

                    if !luxeHabits.isEmpty {
                        Section("\(grp.name) — Luxe ✨") {
                            ForEach(luxeHabits) { habit in
                                HabitToggleRow(habit: habit, date: date)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(date.formatted(.dateTime.weekday(.wide).month().day()))
                            .font(.headline)
                        if let group {
                            Text(group.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 3-State Toggle Row

struct HabitToggleRow: View {
    let habit: Habit
    let date: Date

    @Environment(\.modelContext) private var context

    private enum ToggleState { case none, done, skipped }

    private var state: ToggleState {
        if habit.isCompleted(on: date) { return .done }
        if habit.isSkipped(on: date) { return .skipped }
        return .none
    }

    var body: some View {
        Button(action: cycle) {
            HStack(spacing: 12) {
                Text(habit.emoji).font(.title3)

                Text(habit.name)
                    .foregroundStyle(state == .none ? .primary : .secondary)
                    .strikethrough(state == .done)

                Spacer()

                stateIcon
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .none:
            Image(systemName: "circle")
                .foregroundStyle(Color(.systemGray3))
                .font(.title3)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accent)
                .font(.title3)
        case .skipped:
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(Color(.systemGray3))
                .font(.title3)
        }
    }

    // none → done → skipped → none
    private func cycle() {
        switch state {
        case .none:
            let c = HabitCompletion(date: date, type: .done, habit: habit)
            context.insert(c)
        case .done:
            removeExisting()
            let c = HabitCompletion(date: date, type: .skipped, habit: habit)
            context.insert(c)
        case .skipped:
            removeExisting()
        }
    }

    private func removeExisting() {
        if let existing = habit.completions.first(where: {
            Calendar.current.isDate($0.dateDay, inSameDayAs: date)
        }) {
            context.delete(existing)
        }
    }
}
