import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let emojis: [String]
    let isToday: Bool
    let isSelected: Bool
    let isPerfectDay: Bool

    private let maxVisible = 6
    private let cal = Calendar.current

    private var dayNumber: String { "\(cal.component(.day, from: date))" }
    private var displayEmojis: [String] { Array(emojis.prefix(maxVisible)) }
    private var overflow: Int { max(0, emojis.count - maxVisible) }
    private var emojiRows: [[String]] { displayEmojis.chunked(into: 3) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top, spacing: 2) {
                    Text(dayNumber)
                        .font(.caption2.weight(isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? .white : .primary)
                        .frame(width: 18, height: 18)
                        .background(isToday ? Color.accent : .clear, in: Circle())

                    if isPerfectDay && !emojis.isEmpty {
                        Image(systemName: "sparkles")
                            .font(.system(size: 7))
                            .foregroundStyle(.yellow)
                            .offset(y: 1)
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(emojiRows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 0) {
                            ForEach(row, id: \.self) { emoji in
                                Text(emoji).font(.system(size: 12))
                            }
                        }
                    }
                    if overflow > 0 {
                        Text("+\(overflow)")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(4)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .background(
            isSelected ? Color.accent.opacity(0.13) :
            isToday    ? Color.accent.opacity(0.07) : .clear
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? Color.accent : .clear, lineWidth: 2)
        )
    }
}
