import SwiftUI
import SwiftData

struct StreaksView: View {
    @Query(sort: \HabitGroup.sortOrder) private var groups: [HabitGroup]
    @State private var selectedGroup: HabitGroup? = nil

    // Filter chips only show routines (not standalone groups)
    private var routineGroups: [HabitGroup] { groups.filter { !$0.isStandalone } }

    private var displayedGroups: [HabitGroup] {
        if let selected = selectedGroup { return [selected] }
        return groups // includes standalone
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                groupFilterRow.padding(.vertical, 8)
                Divider()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(displayedGroups) { group in
                            let coreHabits = group.sortedHabits.filter { !$0.isLuxe }
                            ForEach(coreHabits) { habit in
                                StreakCard(habit: habit, groupColor: group.color)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Streaks")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var groupFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", color: .primary, isSelected: selectedGroup == nil) {
                    selectedGroup = nil
                }
                ForEach(routineGroups) { group in
                    FilterChip(
                        label: group.name,
                        color: group.color,
                        isSelected: selectedGroup?.id == group.id
                    ) {
                        selectedGroup = (selectedGroup?.id == group.id) ? nil : group
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct StreakCard: View {
    let habit: Habit
    let groupColor: Color

    private var current: Int { StreakEngine.currentStreak(for: habit) }
    private var best: Int { StreakEngine.bestStreak(for: habit) }

    var body: some View {
        HStack(spacing: 16) {
            Text(habit.emoji).font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name).font(.headline)
                Text(streakLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(current)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Image(systemName: "flame.fill")
                        .foregroundStyle(current > 0 ? .orange : Color(.systemGray3))
                        .font(.title3)
                }
                Text("best \(best)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(groupColor.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private var streakLabel: String {
        switch habit.frequency {
        case .daily: return "day streak"
        case .weekly: return "week streak · \(habit.targetCount)×/wk"
        case .specificDays:
            let symbols = Calendar.current.veryShortWeekdaySymbols
            let days = habit.scheduledWeekdays.sorted().compactMap { symbols[safe: $0 - 1] }.joined(separator: "/")
            return "scheduled day streak · \(days)"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
