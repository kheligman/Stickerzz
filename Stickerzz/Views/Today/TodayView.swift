import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \HabitGroup.sortOrder) private var groups: [HabitGroup]

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:     return "Good evening"
        }
    }

    private var allTodayHabits: [Habit] {
        groups.flatMap { $0.sortedHabits.filter { !$0.isLuxe && $0.shouldAppearInToday() } }
    }

    private var doneCount: Int {
        allTodayHabits.filter { $0.isCompleted(on: $0.activeDate()) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    progressHeader
                        .padding(.horizontal)

                    ForEach(groups) { group in
                        if group.isStandalone, let habit = group.sortedHabits.first {
                            if habit.shouldAppearInToday() || habit.isLuxe {
                                StandaloneHabitCard(habit: habit)
                                    .padding(.horizontal)
                            }
                        } else if !group.isStandalone {
                            RoutineCard(group: group)
                                .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .navigationTitle(greeting)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: HabitGroup.self) { group in
                GroupDetailView(group: group)
            }
        }
    }

    private var progressHeader: some View {
        let total = allTodayHabits.count
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("\(doneCount) of \(total) done today")
                    .font(.headline)
            }
            Spacer()
            CircularProgress(fraction: total > 0 ? Double(doneCount) / Double(total) : 0)
                .frame(width: 48, height: 48)
        }
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
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(fraction * 100))%")
                .font(.system(size: 10, weight: .semibold))
        }
    }
}

// MARK: - Standalone Habit Card

struct StandaloneHabitCard: View {
    let habit: Habit
    @Environment(\.modelContext) private var context

    private enum ToggleState { case none, done, skipped }

    private var state: ToggleState {
        let date = habit.activeDate()
        if habit.isCompleted(on: date) { return .done }
        if habit.isSkipped(on: date) { return .skipped }
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
        case .done:    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.title3)
        case .skipped: Image(systemName: "minus.circle.fill").foregroundStyle(Color(.systemGray3)).font(.title3)
        }
    }

    private func cycle() {
        let date = habit.activeDate()
        switch state {
        case .none:
            context.insert(HabitCompletion(date: date, type: .done, habit: habit))
        case .done:
            removeExisting(on: date)
            context.insert(HabitCompletion(date: date, type: .skipped, habit: habit))
        case .skipped:
            removeExisting(on: date)
        }
    }

    private func removeExisting(on date: Date) {
        if let c = habit.completions.first(where: { Calendar.current.isDate($0.dateDay, inSameDayAs: date) }) {
            context.delete(c)
        }
    }
}
