import SwiftUI
import SwiftData

struct RoutineSessionView: View {
    let group: HabitGroup

    @Environment(\.dismiss) private var dismiss

    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var isRunning = false
    @State private var showBonusSection = false

    private var coreHabits: [Habit] { group.sortedHabits.filter { !$0.isLuxe && $0.shouldAppearInToday() } }
    private var luxeHabits: [Habit]  { group.sortedHabits.filter { $0.isLuxe } }
    private var done: Int    { coreHabits.filter { $0.isCompleted(on: $0.activeDate()) }.count }
    private var skipped: Int { coreHabits.filter { $0.isSkipped(on: $0.activeDate()) }.count }
    private var allHandled: Bool { !coreHabits.isEmpty && (done + skipped) == coreHabits.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                timerHeader

                List {
                    Section {
                        ForEach(coreHabits) { habit in
                            InlineHabitRow(habit: habit, date: habit.activeDate())
                        }
                    }

                    if !luxeHabits.isEmpty {
                        Section {
                            DisclosureGroup(isExpanded: $showBonusSection) {
                                ForEach(luxeHabits) { habit in
                                    InlineHabitRow(habit: habit, date: .now)
                                }
                            } label: {
                                HStack {
                                    Text("✨ Bonus").font(.headline)
                                    let bonusDone = luxeHabits.filter { $0.isCompleted(on: .now) }.count
                                    if bonusDone > 0 {
                                        Text("\(bonusDone) done").font(.caption).foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)

                VStack(spacing: 12) {
                    if allHandled {
                        Button { stopTimer(); dismiss() } label: {
                            Text("Done")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accent, in: RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        Button(isRunning ? "Pause" : "Resume") { toggleTimer() }
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button("Close") { stopTimer(); dismiss() }
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .padding()
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { stopTimer(); dismiss() }
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private var timerHeader: some View {
        VStack(spacing: 8) {
            Text(formatted(elapsed))
                .font(.system(size: 48, weight: .thin, design: .monospaced))
                .contentTransition(.numericText())
            Text("\(done) of \(coreHabits.count) complete")
                .font(.subheadline).foregroundStyle(.secondary)
            ProgressView(value: coreHabits.isEmpty ? 0 : Double(done + skipped) / Double(coreHabits.count))
                .tint(Color.accent).padding(.horizontal)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in elapsed += 1 }
    }
    private func toggleTimer() { if isRunning { stopTimer() } else { startTimer() } }
    private func stopTimer() { isRunning = false; timer?.invalidate(); timer = nil }

    private func formatted(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600, m = (Int(t) % 3600) / 60, s = Int(t) % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}
