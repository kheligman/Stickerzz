import SwiftData
import Foundation

enum CompletionType: String {
    case done
    case skipped
}

@Model
final class HabitCompletion {
    // Default values enable SwiftData lightweight migration
    var dateDay: Date = Date()
    var typeRaw: String = CompletionType.done.rawValue
    var habit: Habit?

    init(date: Date, type: CompletionType = .done, habit: Habit? = nil) {
        self.dateDay = Calendar.current.startOfDay(for: date)
        self.typeRaw = type.rawValue
        self.habit = habit
    }

    var type: CompletionType {
        get { CompletionType(rawValue: typeRaw) ?? .done }
        set { typeRaw = newValue.rawValue }
    }
}
