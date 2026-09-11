import SwiftUI
import SwiftData

struct ManageView: View {
    @Query(sort: \HabitGroup.sortOrder) private var groups: [HabitGroup]
    @Environment(\.modelContext) private var context

    @Environment(PurchaseManager.self) private var purchases

    @State private var showNewRoutine = false
    @State private var showNewHabit = false
    @State private var groupToDelete: HabitGroup? = nil
    @State private var showPaywall = false

    private var routines: [HabitGroup]   { groups.filter { !$0.isStandalone } }
    private var standalone: [HabitGroup] { groups.filter { $0.isStandalone } }

    // True in Simulator, DEBUG builds, and TestFlight (sandbox receipt). False on App Store.
    private var isTestableBuild: Bool {
        #if DEBUG
        return true
        #else
        let url = Bundle.main.appStoreReceiptURL
        return url?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    var body: some View {
        NavigationStack {
            List {
                if !routines.isEmpty {
                    Section("Routines") {
                        ForEach(routines) { group in
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                routineRow(group)
                            }
                        }
                        .onDelete { offsets in
                            if let first = offsets.map({ routines[$0] }).first {
                                groupToDelete = first
                            }
                        }
                        .onMove { source, dest in reorder(routines, from: source, to: dest) }
                    }
                }

                if !standalone.isEmpty {
                    Section("Habits") {
                        ForEach(standalone) { group in
                            if let habit = group.sortedHabits.first {
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    standaloneRow(habit)
                                }
                            }
                        }
                        .onDelete { offsets in
                            if let first = offsets.map({ standalone[$0] }).first {
                                groupToDelete = first
                            }
                        }
                        .onMove { source, dest in reorder(standalone, from: source, to: dest) }
                    }
                }

                if routines.isEmpty && standalone.isEmpty {
                    emptyState
                }

                if isTestableBuild {
                    Section("Developer") {
                        Toggle("Pro Unlocked", isOn: Binding(
                            get: { purchases.isPro },
                            set: { _ in purchases.debugTogglePro() }
                        ))
                        .tint(.accent)
                    }
                }
            }
            .navigationTitle("My Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            if purchases.canAddRoutine(currentCount: routines.count) {
                                showNewRoutine = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            Label("New Routine", systemImage: "list.bullet")
                        }
                        Button {
                            if purchases.canAddStandalone(currentCount: standalone.count) {
                                showNewHabit = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            Label("New Habit", systemImage: "plus.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewRoutine) { GroupEditorView() }
            .sheet(isPresented: $showNewHabit)   { StandaloneHabitCreatorView() }
            .sheet(isPresented: $showPaywall)     { PaywallView().environment(PurchaseManager.shared) }
            .alert(deleteAlertTitle, isPresented: Binding(
                get: { groupToDelete != nil },
                set: { if !$0 { groupToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let g = groupToDelete {
                        NotificationManager.shared.cancel(for: g)
                        context.delete(g)
                    }
                    groupToDelete = nil
                }
                Button("Cancel", role: .cancel) { groupToDelete = nil }
            } message: {
                if let g = groupToDelete {
                    let habitCount = g.habits.filter { !$0.isLuxe }.count
                    if g.isStandalone {
                        Text("This habit and all its history will be permanently deleted.")
                    } else {
                        let plural = habitCount == 1 ? "habit" : "habits"
                        Text("All \(habitCount) \(plural) inside this routine will also be deleted. This cannot be undone.")
                    }
                }
            }
        }
    }

    // MARK: - Rows

    private func routineRow(_ group: HabitGroup) -> some View {
        HStack(spacing: 12) {
            if group.emoji.isEmpty {
                RoundedRectangle(cornerRadius: 6)
                    .fill(group.color)
                    .frame(width: 32, height: 32)
            } else {
                Text(group.emoji).font(.title2).frame(width: 32)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name).font(.headline)
                Text("\(group.habits.filter { !$0.isLuxe }.count) habits")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func standaloneRow(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            Text(habit.emoji).font(.title2).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.headline)
                Text(frequencyLabel(habit)).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No habits yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Tap + to add a habit or routine.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }

    // MARK: - Helpers

    private var deleteAlertTitle: String {
        guard let g = groupToDelete else { return "Delete?" }
        return g.isStandalone
            ? "Delete \"\(g.sortedHabits.first?.name ?? "Habit")\"?"
            : "Delete \"\(g.name)\"?"
    }

    private func reorder(_ subset: [HabitGroup], from source: IndexSet, to destination: Int) {
        var all = groups
        let subsetIds = subset.compactMap { g in all.firstIndex(where: { $0.id == g.id }) }
        var sub = subset
        sub.move(fromOffsets: source, toOffset: destination)
        for (i, habit) in sub.enumerated() {
            if let globalIdx = subsetIds[safe: i] {
                all[globalIdx] = habit
            }
        }
        for (i, group) in all.enumerated() { group.sortOrder = i }
    }

    private func frequencyLabel(_ habit: Habit) -> String {
        switch habit.frequency {
        case .daily: return "Daily"
        case .weekly: return "\(habit.targetCount)× per week"
        case .specificDays:
            let syms = Calendar.current.veryShortWeekdaySymbols
            return habit.scheduledWeekdays.sorted().compactMap { syms[safe: $0 - 1] }.joined(separator: "/")
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
