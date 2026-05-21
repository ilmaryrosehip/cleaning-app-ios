import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var homes: [Home]
    @State private var localization = LocalizationManager.shared

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
    @State private var localization = LocalizationManager.shared
    @State private var premium = PremiumManager.shared
    // 言語変更を検知してタブを再描画するためのID
    @State private var tabViewID = UUID()

    var body: some View {
        TabView {

            HomeView(home: home)
                .tabItem { Label(L(.tabHome), systemImage: "square.grid.2x2") }

            FloorPlanView(home: home)
                .tabItem { Label(L(.tabFloorPlan), systemImage: "house") }

            PremiumLockedView(
                featureName: L(.tabCalendar),
                featureDescription: localization.language == .japanese
                    ? (LocalizationManager.shared.language == .japanese ? "月間カレンダーでタスクを\n一目で確認できます" : "View tasks on a\nmonthly calendar")
                    : LocalizationManager.shared.language == .japanese ? "月間カレンダーでタスクを一目で確認できます" : (LocalizationManager.shared.language == .japanese ? "月間カレンダーでタスクを\n一目で確認できます" : "View tasks on a\nmonthly calendar"),
                featureIcon: "calendar"
            ) {
                CalendarView(home: home)
            }
            .tabItem { Label(L(.tabCalendar), systemImage: "calendar") }
            .overlay(alignment: .topTrailing) {
                if !premium.isPremium {
                    PremiumBadge().padding(.top, 8).padding(.trailing, 8)
                }
            }

            TabView {
                SupplyListView()
                    .tabItem { Label(L(.supplyManagement), systemImage: "bag") }
                ConsumablePartStockView()
                    .tabItem { Label(L(.partsInventory), systemImage: "shippingbox.fill") }
            }
            .tabItem { Label(L(.tabSupply), systemImage: "bag") }

            PremiumLockedView(
                featureName: L(.tabReport),
                featureDescription: localization.language == .japanese
                    ? (LocalizationManager.shared.language == .japanese ? "日別・曜日別・部屋別の統計を\nグラフで見える化します" : "Visualize cleaning stats\nwith beautiful charts")
                    : LocalizationManager.shared.language == .japanese ? "日別・曜日別・部屋別の統計をグラフで見える化します" : "Visualize your cleaning stats with beautiful charts",
                featureIcon: "chart.bar.fill"
            ) {
                ReportView(home: home)
            }
            .tabItem { Label(L(.tabReport), systemImage: "chart.bar.fill") }
            .overlay(alignment: .topTrailing) {
                if !premium.isPremium {
                    PremiumBadge().padding(.top, 8).padding(.trailing, 8)
                }
            }

            HistoryView(home: home)
                .tabItem { Label(L(.tabHistory), systemImage: "clock") }

            MyPageView(home: home)
                .tabItem { Label(L(.tabMyPage), systemImage: "person.circle.fill") }
        }
        .tint(.teal)
        .id(tabViewID)
        .onChange(of: localization.language) { _, _ in
            tabViewID = UUID()
        }
    }
}

// MARK: - プレミアムバッジ

struct PremiumBadge: View {
    var body: some View {
        Label(L(.premium), systemImage: "sparkles")
            .font(.caption2).fontWeight(.semibold)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(LinearGradient(
                colors: [Color(red:0.11,green:0.31,blue:0.87),
                         Color(red:0.37,green:0.51,blue:0.95)],
                startPoint: .leading, endPoint: .trailing
            ))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}
