import SwiftUI
import SwiftData

struct DaySummarySheet: View {
    @Query(sort: \HabitGroup.sortOrder) private var groups: [HabitGroup]
    @Environment(\.dismiss) private var dismiss

    private let today = Calendar.current.startOfDay(for: .now)

    private var completedRoutines: [HabitGroup] {
        groups.filter { !$0.isStandalone }.filter { group in
            group.sortedHabits.contains { !$0.isLuxe && $0.isCompleted(on: today) }
        }
    }

    private var completedStandalones: [Habit] {
        groups.filter { $0.isStandalone }
            .compactMap { $0.sortedHabits.first }
            .filter { $0.isCompleted(on: today) }
    }

    private var completedLuxe: [Habit] {
        groups.flatMap { $0.sortedHabits }.filter { $0.isLuxe && $0.isCompleted(on: today) }
    }

    private var hasPerfectDay: Bool {
        let allScheduled = groups.flatMap { $0.sortedHabits }
            .filter { !$0.isLuxe && $0.isOnSchedule(on: today) }
        guard !allScheduled.isEmpty else { return false }
        return allScheduled.allSatisfy { $0.isCompleted(on: today) }
    }

    private var topStreak: (Habit, Int)? {
        groups.flatMap { $0.sortedHabits }
            .filter { !$0.isLuxe }
            .map { ($0, StreakEngine.currentStreak(for: $0)) }
            .filter { $0.1 > 1 }
            .max(by: { $0.1 < $1.1 })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                DaySummaryCard(
                    completedRoutines: completedRoutines,
                    completedStandalones: completedStandalones,
                    completedLuxe: completedLuxe,
                    hasPerfectDay: hasPerfectDay,
                    topStreak: topStreak
                )
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Share Your Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Card

struct DaySummaryCard: View {
    let completedRoutines: [HabitGroup]
    let completedStandalones: [Habit]
    let completedLuxe: [Habit]
    let hasPerfectDay: Bool
    let topStreak: (Habit, Int)?

    private let today = Calendar.current.startOfDay(for: .now)

    private var hasCompletions: Bool {
        !completedRoutines.isEmpty || !completedStandalones.isEmpty
    }

    private var headline: String {
        if hasPerfectDay { return "✨ Perfect Day" }
        if let (_, count) = topStreak, count >= 7 { return "🔥 \(count)-day streak" }
        if hasCompletions { return "I showed up today" }
        return "Day is just getting started"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date + headline
            VStack(alignment: .leading, spacing: 6) {
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accent.opacity(0.6))
                Text(headline)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.accent)
            }
            .padding(.bottom, 28)

            // Completed routines
            if !completedRoutines.isEmpty {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(completedRoutines) { group in
                        routineSection(group)
                    }
                }
                .padding(.bottom, completedStandalones.isEmpty ? 0 : 20)
            }

            // Completed standalone habits
            if !completedStandalones.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(completedStandalones) { habit in
                        habitRow(emoji: habit.emoji, name: habit.name,
                                 streak: StreakEngine.currentStreak(for: habit))
                    }
                }
            }

            // Luxe
            if !completedLuxe.isEmpty {
                Divider().padding(.vertical, 18)
                VStack(alignment: .leading, spacing: 10) {
                    Text("✨ Bonus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(completedLuxe) { habit in
                        habitRow(emoji: habit.emoji, name: habit.name, streak: nil)
                    }
                }
            }

            if !hasCompletions && completedLuxe.isEmpty {
                Text("Complete a habit to see it here.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
            }

            Spacer(minLength: 40)

            // Branding
            HStack {
                Spacer()
                Text("Stickerzz")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accent.opacity(0.35))
            }
        }
        .padding(28)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.accent.opacity(0.08), radius: 24, y: 10)
    }

    private func routineSection(_ group: HabitGroup) -> some View {
        let doneHabits = group.sortedHabits.filter { !$0.isLuxe && $0.isCompleted(on: today) }
        let required = group.sortedHabits.filter { !$0.isLuxe && $0.isRequired && $0.isOnSchedule(on: today) }
        let isPerfect = !required.isEmpty && required.allSatisfy { $0.isCompleted(on: today) }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if group.emoji.isEmpty {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(group.color)
                        .frame(width: 14, height: 14)
                } else {
                    Text(group.emoji).font(.subheadline)
                }
                Text(group.name)
                    .font(.subheadline.weight(.semibold))
                if isPerfect {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(doneHabits) { habit in
                    habitRow(emoji: habit.emoji, name: habit.name,
                             streak: StreakEngine.currentStreak(for: habit))
                }
            }
            .padding(.leading, 22)
        }
    }

    private func habitRow(emoji: String, name: String, streak: Int?) -> some View {
        HStack(spacing: 10) {
            Text(emoji).font(.body)
            Text(name)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
            if let streak, streak > 1 {
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
        }
    }
}
