import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle") }

            StreaksView()
                .tabItem { Label("Streaks", systemImage: "flame") }

            ManageView()
                .tabItem { Label("Manage", systemImage: "slider.horizontal.3") }
        }
        .tint(.accent)
    }
}
