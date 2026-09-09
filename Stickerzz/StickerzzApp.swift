import SwiftUI
import SwiftData

@main
struct StickerzzApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [HabitGroup.self, Habit.self, HabitCompletion.self])
    }
}
