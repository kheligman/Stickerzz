import SwiftUI
import SwiftData

struct GroupEditorView: View {
    var existing: HabitGroup? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HabitGroup.sortOrder) private var groups: [HabitGroup]

    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var showEmojiPicker = false
    @State private var selectedHex: String = HabitGroup.paletteHexes[0]
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Self.defaultReminderTime

    private static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
    }

    var body: some View {
        NavigationStack {
            Form {
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

                Section("Name") {
                    TextField("e.g. Morning Routine", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(HabitGroup.paletteHexes, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(height: 40)
                                .overlay(
                                    Circle().stroke(
                                        selectedHex == hex ? Color.primary : .clear,
                                        lineWidth: 3
                                    )
                                )
                                .onTapGesture { selectedHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Reminder") {
                    Toggle("Daily reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExisting() }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
    }

    private func loadExisting() {
        guard let g = existing else { return }
        name = g.name
        emoji = g.emoji
        selectedHex = g.colorHex
        reminderEnabled = g.reminderEnabled
        let cal = Calendar.current
        reminderTime = cal.date(bySettingHour: g.reminderHour, minute: g.reminderMinute, second: 0, of: .now)!
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let cal = Calendar.current
        let hour = cal.component(.hour, from: reminderTime)
        let minute = cal.component(.minute, from: reminderTime)

        if let g = existing {
            g.name = trimmed
            g.emoji = emoji
            g.colorHex = selectedHex
            g.reminderEnabled = reminderEnabled
            g.reminderHour = hour
            g.reminderMinute = minute
            NotificationManager.shared.reschedule(for: g)
        } else {
            let g = HabitGroup(name: trimmed, colorHex: selectedHex, sortOrder: groups.count)
            g.emoji = emoji
            g.reminderEnabled = reminderEnabled
            g.reminderHour = hour
            g.reminderMinute = minute
            context.insert(g)
            NotificationManager.shared.reschedule(for: g)
        }
        dismiss()
    }
}
