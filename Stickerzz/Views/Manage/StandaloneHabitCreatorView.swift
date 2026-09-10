import SwiftUI
import SwiftData

struct StandaloneHabitCreatorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HabitGroup.sortOrder) private var groups: [HabitGroup]

    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var frequency: FrequencyType = .daily
    @State private var targetCount: Int = 1
    @State private var scheduledWeekdays: Set<Int> = []
    @State private var showEmojiPicker = false
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Self.defaultReminderTime
    @State private var tags: Set<String> = []
    @State private var newTagText: String = ""

    @Query private var allHabits: [Habit]

    private var allTagsInSystem: [String] {
        Array(Set(allHabits.flatMap { $0.tags })).sorted()
    }

    private static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
    }

    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { showEmojiPicker = true } label: {
                        HStack {
                            Text("Emoji").foregroundStyle(.primary)
                            Spacer()
                            if emoji.isEmpty {
                                Text("Tap to choose").foregroundStyle(.secondary)
                            } else {
                                Text(emoji).font(.title2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section("Name") {
                    TextField("e.g. Stretch, Vitamins, Journaling…", text: $name)
                }

                Section("Tags") {
                    if !allTagsInSystem.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(allTagsInSystem, id: \.self) { tag in
                                    Button {
                                        if tags.contains(tag) { tags.remove(tag) }
                                        else { tags.insert(tag) }
                                    } label: {
                                        Text(tag)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(tags.contains(tag) ? .white : Color.accent)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                tags.contains(tag) ? Color.accent : Color.accent.opacity(0.1),
                                                in: Capsule()
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    HStack {
                        TextField("New tag…", text: $newTagText)
                            .submitLabel(.done)
                            .onSubmit { addNewTag() }
                        if !newTagText.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button("Add") { addNewTag() }
                                .foregroundStyle(Color.accent)
                        }
                    }
                }

                Section("Reminder") {
                    Toggle("Daily reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

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
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(
                            name.trimmingCharacters(in: .whitespaces).isEmpty ||
                            emoji.isEmpty ||
                            (frequency == .specificDays && scheduledWeekdays.isEmpty)
                        )
                }
            }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
    }

    @ViewBuilder
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
                        .background(selected ? Color.accent : Color(.systemGray5), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)

        if scheduledWeekdays.isEmpty {
            Text("Select at least one day")
                .font(.caption)
                .foregroundStyle(.red.opacity(0.8))
        }
    }

    private func addNewTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tags.insert(trimmed)
        newTagText = ""
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let cal = Calendar.current
        let group = HabitGroup(
            name: trimmed,
            colorHex: HabitGroup.paletteHexes[groups.count % HabitGroup.paletteHexes.count],
            sortOrder: groups.count,
            isStandalone: true
        )
        group.reminderEnabled = reminderEnabled
        group.reminderHour = cal.component(.hour, from: reminderTime)
        group.reminderMinute = cal.component(.minute, from: reminderTime)
        context.insert(group)

        let habit = Habit(
            name: trimmed,
            emoji: emoji,
            frequency: frequency,
            targetCount: frequency == .weekly ? targetCount : 1,
            sortOrder: 0,
            scheduledWeekdays: frequency == .specificDays ? scheduledWeekdays : []
        )
        habit.group = group
        habit.tags = tags
        context.insert(habit)

        NotificationManager.shared.reschedule(for: group)
        dismiss()
    }
}
