import SwiftUI

struct RootTabView: View {
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        @Bindable var nav = navigation
        TabView(selection: Binding(
            get: { nav.selectedTab },
            set: { tapped in
                if tapped == nav.selectedTab {
                    nav.retappedTab = tapped
                } else {
                    nav.selectedTab = tapped
                }
            }
        )) {
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
        .onChange(of: nav.retappedTab) { _, tab in
            guard let tab, tab != 0, tab != 1 else { return }
            nav.retappedTab = nil
        }
    }
}
