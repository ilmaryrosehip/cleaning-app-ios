import SwiftUI
import StoreKit

// MARK: - PremiumGateView

struct PremiumGateView: View {
    let featureName: String
    let featureDescription: String
    let featureIcon: String
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red:0.11,green:0.31,blue:0.87),
                                     Color(red:0.07,green:0.20,blue:0.55)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    Image(systemName: featureIcon).font(.system(size: 34)).foregroundStyle(.white)
                }
                VStack(spacing: 8) {
                    Text(featureName).font(.title2).fontWeight(.bold)
                    Text(featureDescription).font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                }
                VStack(alignment: .leading, spacing: 10) {
                    PremiumBenefit(icon: "chart.bar.fill",      text: "掃除レポート・統計グラフ")
                    PremiumBenefit(icon: "camera.fill",         text: "写真記録（Before/After）")
                    PremiumBenefit(icon: "icloud.fill",         text: "iCloud同期（家族と共有）")
                    PremiumBenefit(icon: "calendar",            text: "カレンダー表示")
                    PremiumBenefit(icon: "square.and.arrow.up", text: "データエクスポート")
                }
                .padding(.horizontal, 32)

                Button { showPaywall = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Pikari プレミアムを見る")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(LinearGradient(
                        colors: [Color(red:0.11,green:0.31,blue:0.87),
                                 Color(red:0.37,green:0.51,blue:0.95)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 40)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

// MARK: - PremiumBenefit

struct PremiumBenefit: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.subheadline)
                .foregroundStyle(Color(red:0.11,green:0.31,blue:0.87)).frame(width: 20)
            Text(text).font(.subheadline)
            Spacer()
            Image(systemName: "checkmark").font(.caption).fontWeight(.semibold).foregroundStyle(.teal)
        }
    }
}

// MARK: - PaywallView（買い切り購入画面）

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var premium = PremiumManager.shared
    @State private var showRestoreAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ヘッダー
                    ZStack {
                        LinearGradient(
                            colors: [Color(red:0.07,green:0.20,blue:0.55),
                                     Color(red:0.11,green:0.31,blue:0.87)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        VStack(spacing: 12) {
                            Image(systemName: "house.fill").font(.system(size: 48)).foregroundStyle(.white)
                            Text("Pikari プレミアム").font(.title).fontWeight(.bold).foregroundStyle(.white)
                            Text("買い切りですべての機能を解鎖")
                                .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.vertical, 40)
                    }

                    VStack(spacing: 20) {
                        // 特典リスト
                        VStack(alignment: .leading, spacing: 14) {
                            Text("プレミアム特典").font(.headline)
                            PremiumBenefit(icon: "chart.bar.fill",      text: "掃除レポート・統計グラフ")
                            PremiumBenefit(icon: "camera.fill",          text: "写真記録（Before/After）")
                            PremiumBenefit(icon: "icloud.fill",          text: "iCloud同期（家族と共有）")
                            PremiumBenefit(icon: "calendar",             text: "カレンダー表示")
                            PremiumBenefit(icon: "square.and.arrow.up",  text: "データエクスポート（CSV/PDF）")
                            PremiumBenefit(icon: "arrow.clockwise.circle.fill", text: "将来の新機能もすべて無料")
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // 価格表示
                        VStack(spacing: 8) {
                            if let product = premium.premiumProduct {
                                Text(product.displayPrice)
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundStyle(Color(red:0.11,green:0.31,blue:0.87))
                                Text("一度の購入で永久に使えます")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            } else {
                                ProgressView()
                                Text("商品情報を読み込み中...")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 10)

                        // 購入ボタン
                        Button {
                            Task {
                                let success = await premium.purchase()
                                if success { dismiss() }
                            }
                        } label: {
                            HStack {
                                if premium.isPurchasing {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("事人購入する")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(LinearGradient(
                                colors: [Color(red:0.11,green:0.31,blue:0.87),
                                         Color(red:0.37,green:0.51,blue:0.95)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(premium.isPurchasing || premium.premiumProduct == nil)

                        if let error = premium.errorMessage {
                            Text(error).font(.caption).foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        // 購入復元
                        Button("購入を復元する") {
                            Task {
                                await premium.restore()
                                if premium.isPremium { dismiss() }
                                else { showRestoreAlert = true }
                            }
                        }
                        .font(.subheadline).foregroundStyle(.secondary)

                        Text("一度購入すると、追加費用なしですべてのプレミアム機能を永久ご利用いただけます。\n将来のアップデートによる機能追加も無料で提供します。")
                            .font(.caption2).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center).padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20).padding(.top, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } }
            }
            .alert("復元完了", isPresented: $showRestoreAlert) {
                Button("OK") {}
            } message: {
                Text("復元できる購入履歴が見つかりませんでした。")
            }
        }
        .task { await premium.loadProducts() }
    }
}

// MARK: - PremiumLockedView

struct PremiumLockedView<Content: View>: View {
    let featureName: String
    let featureDescription: String
    let featureIcon: String
    @ViewBuilder let content: () -> Content
    @State private var premium = PremiumManager.shared

    var body: some View {
        ZStack {
            content().disabled(!premium.isPremium)
            if !premium.isPremium {
                PremiumGateView(
                    featureName: featureName,
                    featureDescription: featureDescription,
                    featureIcon: featureIcon
                )
            }
        }
    }
}
