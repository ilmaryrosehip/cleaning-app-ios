import SwiftUI
import StoreKit

// MARK: - PremiumGateView
// プレミアム機能をロックして購入を促すオーバーレイ

struct PremiumGateView: View {
    let featureName: String
    let featureDescription: String
    let featureIcon: String

    @State private var showPaywall = false

    var body: some View {
        ZStack {
            // ぼかし背景
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red:0.11,green:0.31,blue:0.87),
                                         Color(red:0.07,green:0.20,blue:0.55)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    Image(systemName: featureIcon)
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text(featureName)
                        .font(.title2).fontWeight(.bold)

                    Text(featureDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // プレミアム特典リスト
                VStack(alignment: .leading, spacing: 10) {
                    PremiumBenefit(icon: "chart.bar.fill",   text: "掃除レポート・統計グラフ")
                    PremiumBenefit(icon: "camera.fill",      text: "写真記録（Before/After）")
                    PremiumBenefit(icon: "icloud.fill",      text: "iCloud同期（家族と共有）")
                    PremiumBenefit(icon: "calendar",         text: "カレンダー表示")
                    PremiumBenefit(icon: "square.and.arrow.up", text: "データエクスポート")
                }
                .padding(.horizontal, 32)

                // 購入ボタン
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Pikari プレミアムを見る")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(red:0.11,green:0.31,blue:0.87),
                                     Color(red:0.37,green:0.51,blue:0.95)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 40)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - PremiumBenefit

struct PremiumBenefit: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color(red:0.11,green:0.31,blue:0.87))
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.teal)
        }
    }
}

// MARK: - PaywallView（購入画面）

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var premium = PremiumManager.shared
    @State private var selectedPlan: String = PremiumProduct.yearlyID
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
                            Image(systemName: "house.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.white)
                            Text("Pikari プレミアム")
                                .font(.title).fontWeight(.bold)
                                .foregroundStyle(.white)
                            Text("すべての機能を使って\n理想のお掃除ライフを")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    }

                    VStack(spacing: 20) {
                        // 特典リスト
                        VStack(alignment: .leading, spacing: 14) {
                            Text("プレミアム特典")
                                .font(.headline)
                            PremiumBenefit(icon: "chart.bar.fill",      text: "掃除レポート・統計グラフ")
                            PremiumBenefit(icon: "camera.fill",          text: "写真記録（Before/After）")
                            PremiumBenefit(icon: "icloud.fill",          text: "iCloud同期（家族と共有）")
                            PremiumBenefit(icon: "calendar",             text: "カレンダー表示")
                            PremiumBenefit(icon: "square.and.arrow.up",  text: "データエクスポート（CSV/PDF）")
                            PremiumBenefit(icon: "bell.badge.fill",      text: "通知のカスタマイズ")
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // プラン選択
                        VStack(spacing: 12) {
                            Text("プランを選択")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // 年額プラン
                            PlanCard(
                                title: "年額プラン",
                                badge: "お得",
                                price: premium.yearlyProduct?.displayPrice ?? "---",
                                description: "月あたり約150円相当",
                                isSelected: selectedPlan == PremiumProduct.yearlyID
                            ) { selectedPlan = PremiumProduct.yearlyID }

                            // 月額プラン
                            PlanCard(
                                title: "月額プラン",
                                badge: nil,
                                price: premium.monthlyProduct?.displayPrice ?? "---",
                                description: "いつでもキャンセル可能",
                                isSelected: selectedPlan == PremiumProduct.monthlyID
                            ) { selectedPlan = PremiumProduct.monthlyID }
                        }

                        // 購入ボタン
                        Button {
                            Task {
                                let product = selectedPlan == PremiumProduct.yearlyID
                                    ? premium.yearlyProduct
                                    : premium.monthlyProduct
                                if let p = product {
                                    let success = await premium.purchase(p)
                                    if success { dismiss() }
                                }
                            }
                        } label: {
                            HStack {
                                if premium.isPurchasing {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("今すぐ始める")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(red:0.11,green:0.31,blue:0.87),
                                             Color(red:0.37,green:0.51,blue:0.95)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(premium.isPurchasing)

                        if let error = premium.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
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
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        // 注記
                        Text("サブスクリプションは各期間終了の24時間前に自動更新されます。\nApp Storeの設定からいつでもキャンセルできます。")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("復元完了", isPresented: $showRestoreAlert) {
                Button("OK") {}
            } message: {
                Text("復元できる購入履歴が見つかりませんでした。")
            }
        }
        .task {
            await premium.loadProducts()
        }
    }
}

// MARK: - PlanCard

struct PlanCard: View {
    let title: String
    let badge: String?
    let price: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 選択インジケーター
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color(red:0.11,green:0.31,blue:0.87) : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title).font(.subheadline).fontWeight(.semibold)
                        if let badge {
                            Text(badge)
                                .font(.caption2).fontWeight(.bold)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(description).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                Text(price)
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(isSelected ? Color(red:0.11,green:0.31,blue:0.87) : .primary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color(red:0.11,green:0.31,blue:0.87) : Color(.systemGray4),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PremiumLockedView
// 機能をロックして表示するラッパービュー

struct PremiumLockedView<Content: View>: View {
    let featureName: String
    let featureDescription: String
    let featureIcon: String
    @ViewBuilder let content: () -> Content

    @State private var premium = PremiumManager.shared

    var body: some View {
        ZStack {
            content()
                .disabled(!premium.isPremium)

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
