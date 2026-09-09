import SwiftUI

struct RootTabView: View {
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        @Bindable var nav = navigation
        TabView(selection: $nav.selectedTab) {
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(0)

            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle") }
                .tag(1)

            StreaksView()
                .tabItem { Label("Streaks", systemImage: "flame") }
                .tag(2)

            ManageView()
                .tabItem { Label("Manage", systemImage: "slider.horizontal.3") }
                .tag(3)
        }
        .tint(.accent)
    }
}
