import SwiftUI
import SwiftData

@main
struct StickerzzApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task { await NotificationManager.shared.requestPermission() }
                .environment(PurchaseManager.shared)
        }
        .modelContainer(for: [HabitGroup.self, Habit.self, HabitCompletion.self])
    }
}
