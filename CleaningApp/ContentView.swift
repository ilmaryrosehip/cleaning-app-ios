import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var homes: [Home]
    @Environment(PremiumManager.self) private var premium

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
    @Environment(PremiumManager.self) private var premium

    var body: some View {
        TabView {
            // ホーム（無料）
            HomeView(home: home)
                .tabItem { Label("ホーム", systemImage: "square.grid.2x2") }

            // 間取り（無料）
            FloorPlanView(home: home)
                .tabItem { Label("間取り", systemImage: "house") }

            // 用品（無料）
            SupplyListView()
                .tabItem { Label("用品", systemImage: "bag") }

            // 消耗品在庫（無料）
            NavigationStack { ConsumablePartStockView() }
                .tabItem { Label("消耗品在庫", systemImage: "shippingbox") }

            // レポート（プレミアム）
            PremiumLockedView(
                featureName: "掃除レポート",
                featureDescription: "日別・曜日別・部屋別の統計を\nグラフで見える化します",
                featureIcon: "chart.bar.fill"
            ) {
                ReportView(home: home)
            }
            .tabItem { Label("レポート", systemImage: "chart.bar.fill") }
            .overlay(alignment: .topTrailing) {
                if !premium.isPremium {
                    PremiumBadge()
                        .padding(.top, 8).padding(.trailing, 8)
                }
            }

            // 履歴（無料）
            HistoryView(home: home)
                .tabItem { Label("履歴", systemImage: "clock") }
        }
        .tint(.teal)
    }
}

// MARK: - プレミアムバッジ

struct PremiumBadge: View {
    var body: some View {
        Label("プレミアム", systemImage: "sparkles")
            .font(.caption2).fontWeight(.semibold)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(
                LinearGradient(
                    colors: [Color(red:0.11,green:0.31,blue:0.87),
                             Color(red:0.37,green:0.51,blue:0.95)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}
