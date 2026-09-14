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
    @State private var isRequired: Bool = true
    @State private var scheduledWeekdays: Set<Int> = []
    @State private var emojiKeyboardActive = false
    @State private var tags: Set<String> = []
    @State private var newTagText: String = ""

    @Query private var allHabits: [Habit]

    private var allTagsInSystem: [String] {
        Array(Set(allHabits.flatMap { $0.tags })).sorted()
    }

    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols // Sun=0

    var body: some View {
        NavigationStack {
            Form {
                // Emoji
                Section {
                    Button {
                        emojiKeyboardActive = true
                    } label: {
                        HStack {
                            Text("Emoji")
                                .foregroundStyle(.primary)
                            Spacer()
                            if emoji.isEmpty {
                                Text("Required — tap to choose")
                                    .foregroundStyle(!name.trimmingCharacters(in: .whitespaces).isEmpty ? .red.opacity(0.7) : .secondary)
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
                        if luxe { frequency = .daily; scheduledWeekdays = []; isRequired = true }
                    }

                    if !isLuxe && !group.isStandalone {
                        Toggle(isOn: Binding(get: { !isRequired }, set: { isRequired = !$0 })) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Preferred (optional)")
                                Text("Part of the routine, but not required to mark it complete")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Tags
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
                        .disabled(
                            name.trimmingCharacters(in: .whitespaces).isEmpty ||
                            emoji.isEmpty ||
                            (frequency == .specificDays && scheduledWeekdays.isEmpty && !isLuxe)
                        )
                }
            }
            .onAppear { loadExisting() }
            .overlay(
                EmojiTextField(text: $emoji, isFirstResponder: $emojiKeyboardActive)
                    .frame(width: 0, height: 0)
            )
        }
    }

    // Day-of-week toggles (S M T W T F S)
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
                        .background(
                            selected ? Color.primary : Color(.systemGray5),
                            in: Circle()
                        )
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

    private func loadExisting() {
        guard let h = existing else { return }
        name = h.name
        emoji = h.emoji
        frequency = h.frequency
        targetCount = h.targetCount
        isLuxe = h.isLuxe
        isRequired = h.isRequired
        scheduledWeekdays = h.scheduledWeekdays
        tags = h.tags
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let h = existing {
            h.name = trimmed
            h.emoji = emoji
            h.isLuxe = isLuxe
            h.isRequired = isLuxe ? true : isRequired
            h.frequency = isLuxe ? .daily : frequency
            h.targetCount = frequency == .weekly ? targetCount : 1
            h.scheduledWeekdays = frequency == .specificDays ? scheduledWeekdays : []
            h.tags = tags
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
            h.isRequired = isLuxe ? true : isRequired
            h.tags = tags
            context.insert(h)
        }
        dismiss()
    }
}
