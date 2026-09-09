import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    private let categories: [(String, [String])] = [
        ("Beauty & Skin", ["💄", "💋", "💅", "💆", "🧖", "🪞", "🧴", "🧼", "🫧", "🪷", "🌹", "🌸"]),
        ("Sleep & Rest", ["🌙", "😴", "🛌", "⭐", "✨", "🌟", "💤", "🛏", "🌛", "🫶"]),
        ("Health & Body", ["💪", "🏃", "🧘", "🚶", "🏋️", "🤸", "🏊", "🚴", "❤️", "🩺", "💊"]),
        ("Teeth & Face", ["🦷", "🪥", "😁", "🫦", "🧏", "💧", "🫁"]),
        ("Food & Drink", ["💧", "🥤", "🧃", "☕", "🍵", "🫖", "🍎", "🥗", "🥦", "🫐", "🍋"]),
        ("Mind & Spirit", ["🧠", "🌿", "🍃", "🌺", "🌻", "☀️", "🌊", "🦋", "🕊", "📔", "📝"]),
        ("Treatments", ["🪨", "🧊", "🌡", "💎", "🔮", "🌀", "⚗️", "🛁", "🚿", "🧸"]),
        ("Goals", ["⏱", "🎯", "🏆", "🔥", "⚡", "🌈", "🎉", "✅"]),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.0) { name, emojis in
                    Section(name) {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: 6),
                            spacing: 10
                        ) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button {
                                    selectedEmoji = emoji
                                    dismiss()
                                } label: {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selectedEmoji == emoji
                                                ? Color(.systemGray4)
                                                : Color(.systemGray6),
                                            in: RoundedRectangle(cornerRadius: 10)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
