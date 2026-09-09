import SwiftData
import SwiftUI

@Model
final class HabitGroup {
    var name: String
    var colorHex: String
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \Habit.group)
    var habits: [Habit] = []

    // Defaults enable lightweight SwiftData migration
    var isStandalone: Bool = false
    var reminderEnabled: Bool = false
    var reminderHour: Int = 8
    var reminderMinute: Int = 0

    init(name: String, colorHex: String, sortOrder: Int = 0, isStandalone: Bool = false) {
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isStandalone = isStandalone
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    var sortedHabits: [Habit] {
        habits.sorted { $0.sortOrder < $1.sortOrder }
    }

    static let paletteHexes = [
        "#F2C6D0", // dusty rose
        "#C5B9E0", // lavender
        "#B5D5C5", // sage
        "#F5D5A0", // peach
        "#A8D5E2", // sky blue
        "#F2E6C2", // warm yellow
        "#D0B0C8", // mauve
        "#B0CCD0", // slate
    ]
}
