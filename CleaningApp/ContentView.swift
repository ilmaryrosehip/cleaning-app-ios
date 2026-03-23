import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var homes: [Home]

    var body: some View {
        Group {
            if homes.isEmpty {
                OnboardingView()
            } else {
                MainTabView(home: homes[0])
            }
        }
        .animation(.none, value: homes.isEmpty)
    }
}

struct MainTabView: View {
    let home: Home

    var body: some View {
        TabView {
            HomeView(home: home)
                .tabItem { Label("ホーム", systemImage: "square.grid.2x2") }

            FloorPlanView(home: home)
                .tabItem { Label("間取り", systemImage: "house") }

            SupplyListView()
                .tabItem { Label("用品", systemImage: "bag") }

            NavigationStack {
                ConsumablePartStockView()
            }
            .tabItem { Label("消耗品在庫", systemImage: "shippingbox") }

            HistoryView(home: home)
                .tabItem { Label("履歴", systemImage: "clock") }
        }
        .tint(.teal)
    }
}
