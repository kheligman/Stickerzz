import SwiftUI
import SwiftData

struct GroupDetailView: View {
    let group: HabitGroup

    @Environment(\.modelContext) private var context
    @Environment(PurchaseManager.self) private var purchases

    @State private var showEditGroup = false
    @State private var showNewHabit = false
    @State private var showPaywall = false
    @State private var editingHabit: Habit? = nil
    @State private var habitToDelete: Habit? = nil

    private var requiredHabits: [Habit] { group.sortedHabits.filter { !$0.isLuxe && $0.isRequired } }
    private var preferredHabits: [Habit] { group.sortedHabits.filter { !$0.isLuxe && !$0.isRequired } }
    private var luxeHabits: [Habit] { group.sortedHabits.filter { $0.isLuxe } }

    var body: some View {
        List {
            if !requiredHabits.isEmpty {
                Section("Habits") {
                    ForEach(requiredHabits) { habit in
                        habitRow(habit)
                    }
                    .onMove { moveHabits(from: $0, to: $1, in: requiredHabits) }
                }
            }

            if !preferredHabits.isEmpty {
                Section("Preferred") {
                    ForEach(preferredHabits) { habit in
                        habitRow(habit)
                    }
                    .onMove { moveHabits(from: $0, to: $1, in: preferredHabits) }
                }
            }

            if !luxeHabits.isEmpty {
                Section("✨ Luxe Bonus") {
                    ForEach(luxeHabits) { habit in
                        habitRow(habit, showLuxeStats: true)
                    }
                    .onMove { moveHabits(from: $0, to: $1, in: luxeHabits) }
                }
            }
        }
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if purchases.canAddHabitToRoutine(currentCount: group.habits.count) {
                        showNewHabit = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Routine") { showEditGroup = true }
                    EditButton()
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditGroup) { GroupEditorView(existing: group) }
        .sheet(isPresented: $showNewHabit) { HabitEditorView(group: group) }
        .sheet(item: $editingHabit) { HabitEditorView(group: group, existing: $0) }
        .sheet(isPresented: $showPaywall) { PaywallView().environment(PurchaseManager.shared) }
        .alert("Delete \"\(habitToDelete?.name ?? "Habit")\"?", isPresented: Binding(
            get: { habitToDelete != nil },
            set: { if !$0 { habitToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let h = habitToDelete { context.delete(h) }
                habitToDelete = nil
            }
            Button("Cancel", role: .cancel) { habitToDelete = nil }
        } message: {
            Text("This habit and all its history will be permanently deleted.")
        }
    }

    @ViewBuilder
    private func habitRow(_ habit: Habit, showLuxeStats: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(habit.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name).font(.body)
                if showLuxeStats {
                    Text(luxeStats(habit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(frequencyLabel(habit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !habit.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(habit.tags.sorted(), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.accent)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.accent.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { habitToDelete = habit } label: {
                Label("Delete", systemImage: "trash")
            }
            Button { editingHabit = habit } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
    }

    private func moveHabits(from source: IndexSet, to destination: Int, in subset: [Habit]) {
        var reordered = group.sortedHabits
        let subsetIndices = subset.compactMap { h in reordered.firstIndex(where: { $0.id == h.id }) }
        var subOrdered = subset
        subOrdered.move(fromOffsets: source, toOffset: destination)
        for (subIdx, habit) in subOrdered.enumerated() {
            if let globalIdx = subsetIndices[safe: subIdx] {
                reordered[globalIdx] = habit
            }
        }
        for (i, habit) in reordered.enumerated() { habit.sortOrder = i }
    }

    private func frequencyLabel(_ habit: Habit) -> String {
        switch habit.frequency {
        case .daily: return "Daily"
        case .weekly: return "\(habit.targetCount)× per week"
        case .specificDays:
            let symbols = Calendar.current.veryShortWeekdaySymbols
            let days = habit.scheduledWeekdays.sorted().compactMap { symbols[safe: $0 - 1] }.joined(separator: "/")
            return days.isEmpty ? "Specific days" : days
        }
    }

    private func luxeStats(_ habit: Habit) -> String {
        let uses = habit.completions.filter { $0.type == .done }.count
        guard let lastDate = habit.completions
            .filter({ $0.type == .done })
            .max(by: { $0.dateDay < $1.dateDay })?.dateDay else {
            return "Never used · 0 total uses"
        }
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: .now).day ?? 0
        let lastStr = days == 0 ? "today" : days == 1 ? "yesterday" : "\(days) days ago"
        return "Last used \(lastStr) · \(uses) total"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
