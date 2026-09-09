import SwiftUI
import SwiftData

struct HabitEditorView: View {
    let group: HabitGroup
    var existing: Habit? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var frequency: FrequencyType = .daily
    @State private var targetCount: Int = 1
    @State private var isLuxe: Bool = false
    @State private var scheduledWeekdays: Set<Int> = []
    @State private var showEmojiPicker = false

    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols // Sun=0

    var body: some View {
        NavigationStack {
            Form {
                // Emoji
                Section {
                    Button {
                        showEmojiPicker = true
                    } label: {
                        HStack {
                            Text("Emoji")
                                .foregroundStyle(.primary)
                            Spacer()
                            if emoji.isEmpty {
                                Text("Tap to choose")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(emoji).font(.title2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Name
                Section("Name") {
                    TextField("e.g. Red light mask", text: $name)
                }

                // Luxe toggle
                Section {
                    Toggle(isOn: $isLuxe) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("✨ Luxe bonus habit")
                            Text("Shows as a bonus — doesn't count toward routine progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: isLuxe) { _, luxe in
                        if luxe { frequency = .daily; scheduledWeekdays = [] }
                    }
                }

                // Frequency (hidden for luxe)
                if !isLuxe {
                    Section("Frequency") {
                        Picker("Frequency", selection: $frequency) {
                            ForEach(FrequencyType.allCases, id: \.self) {
                                Text($0.label).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)

                        if frequency == .weekly {
                            Stepper("Target: \(targetCount)× per week", value: $targetCount, in: 1...7)
                        }

                        if frequency == .specificDays {
                            dayPicker
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || emoji.isEmpty)
                }
            }
            .onAppear { loadExisting() }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
    }

    // Day-of-week toggles (S M T W T F S)
    private var dayPicker: some View {
        HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { weekday in
                let symbol = weekdaySymbols[weekday - 1]
                let selected = scheduledWeekdays.contains(weekday)
                Button {
                    if selected { scheduledWeekdays.remove(weekday) }
                    else { scheduledWeekdays.insert(weekday) }
                } label: {
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selected ? .white : .primary)
                        .frame(width: 34, height: 34)
                        .background(
                            selected ? Color.primary : Color(.systemGray5),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadExisting() {
        guard let h = existing else { return }
        name = h.name
        emoji = h.emoji
        frequency = h.frequency
        targetCount = h.targetCount
        isLuxe = h.isLuxe
        scheduledWeekdays = h.scheduledWeekdays
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let h = existing {
            h.name = trimmed
            h.emoji = emoji
            h.isLuxe = isLuxe
            h.frequency = isLuxe ? .daily : frequency
            h.targetCount = frequency == .weekly ? targetCount : 1
            h.scheduledWeekdays = frequency == .specificDays ? scheduledWeekdays : []
        } else {
            let h = Habit(
                name: trimmed,
                emoji: emoji,
                frequency: isLuxe ? .daily : frequency,
                targetCount: frequency == .weekly ? targetCount : 1,
                sortOrder: group.habits.count,
                isLuxe: isLuxe,
                scheduledWeekdays: frequency == .specificDays ? scheduledWeekdays : []
            )
            h.group = group
            context.insert(h)
        }
        dismiss()
    }
}
