import StoreKit
import SwiftUI

// MARK: - 商品ID定義
// App Store Connect で登録するIDと一致させること

enum PikariProduct: String, CaseIterable {
    case lifetime     = "com.hiroki.CleaningApp.premium.lifetime"   // 買い切り
    case yearly       = "com.hiroki.CleaningApp.premium.yearly"     // 年額サブスク

    var displayName: String {
        switch self {
        case .lifetime: return "Pikari プレミアム（買い切り）"
        case .yearly:   return "Pikari プレミアム（年額）"
        }
    }

    var description: String {
        switch self {
        case .lifetime: return "一度の購入で全機能を永久に利用できます"
        case .yearly:   return "年間サブスクリプションで全機能を利用できます"
        }
    }
}

// MARK: - PurchaseManager

@MainActor
@Observable
final class PurchaseManager {

    static let shared = PurchaseManager()
    private init() {}

    // MARK: - 状態

    /// プレミアム機能が有効かどうか
    private(set) var isPremium: Bool = false

    /// 利用可能な商品一覧
    private(set) var products: [Product] = []

    /// 購入処理中
    private(set) var isPurchasing: Bool = false

    /// エラーメッセージ
    private(set) var errorMessage: String? = nil

    /// トランザクション監視タスク
    private var updateListenerTask: Task<Void, Never>? = nil

    // MARK: - 初期化・監視開始

    func initialize() async {
        // トランザクション更新を監視
        updateListenerTask = Task {
            for await update in Transaction.updates {
                await handle(transactionUpdate: update)
            }
        }
        // 購入状態を確認
        await refreshPurchaseStatus()
        // 商品情報を取得
        await loadProducts()
    }

    // MARK: - 商品情報取得

    func loadProducts() async {
        do {
            let ids = PikariProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = (UserDefaults.standard.string(forKey:"app_language") == "en" ? "Failed to load products" : "商品情報の取得に失敗しました")
            print("Product load error: \(error)")
        }
    }

    // MARK: - 購入処理

    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(transactionUpdate: verification)
            case .userCancelled:
                break
            case .pending:
                errorMessage = (UserDefaults.standard.string(forKey:"app_language") == "en" ? "Purchase pending approval" : "購入が保留中です。確認後に有効になります")
            @unknown default:
                break
            }
        } catch {
            errorMessage = (UserDefaults.standard.string(forKey:"app_language") == "en" ? "Purchase failed" : "購入処理中にエラーが発生しました")
            print("Purchase error: \(error)")
        }

        isPurchasing = false
    }

    // MARK: - 購入復元

    func restorePurchases() async {
        isPurchasing = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            errorMessage = (UserDefaults.standard.string(forKey:"app_language") == "en" ? "Restore failed" : "購入の復元に失敗しました")
        }

        isPurchasing = false
    }

    // MARK: - 購入状態の確認

    func refreshPurchaseStatus() async {
        var hasPremium = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if PikariProduct.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                    // 有効なトランザクションがあればプレミアム
                    if transaction.revocationDate == nil {
                        hasPremium = true
                    }
                }
            }
        }

        isPremium = hasPremium
    }

    // MARK: - トランザクション処理

    private func handle(transactionUpdate: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transactionUpdate else { return }

        if transaction.revocationDate == nil {
            // 有効な購入
            if PikariProduct.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                isPremium = true
            }
        } else {
            // 取り消し（返金など）
            await refreshPurchaseStatus()
        }

        await transaction.finish()
    }

    // MARK: - 商品検索ヘルパー

    func product(for pikariProduct: PikariProduct) -> Product? {
        products.first { $0.id == pikariProduct.rawValue }
    }
}

// MARK: - PremiumBadge（プレミアムバッジ）

struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 9))
            Text("PRO")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(
            LinearGradient(
                colors: [Color(red:0.85, green:0.65, blue:0.1), Color(red:0.95, green:0.80, blue:0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
    }
}

// MARK: - PremiumGateView（プレミアム機能ゲート）

struct PremiumGateView: View {
    let featureName: String
    let featureDescription: String
    let featureIcon: String
    @State private var showPaywall = false
    @Environment(PurchaseManager.self) private var purchaseManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red:0.85, green:0.65, blue:0.1).opacity(0.2),
                                     Color(red:0.95, green:0.80, blue:0.2).opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                Image(systemName: featureIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red:0.85, green:0.65, blue:0.1),
                                     Color(red:0.95, green:0.80, blue:0.2)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                PremiumBadge()
                Text(featureName)
                    .font(.title2).fontWeight(.bold)
                Text(featureDescription)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                    Text(UserDefaults.standard.string(forKey:"app_language") == "en" ? "Upgrade to Premium" : "プレミアムにアップグレード")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red:0.85, green:0.65, blue:0.1),
                                 Color(red:0.95, green:0.80, blue:0.2)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - PaywallView（購入画面）

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var selectedProduct: PikariProduct = .yearly

    private let features: [(icon: String, text: String)] = [
        ("chart.bar.fill", UserDefaults.standard.string(forKey:"app_language") == "en" ? "Cleaning Reports & Charts" : "掃除レポート・統計グラフ"),
        ("photo.fill", UserDefaults.standard.string(forKey:"app_language") == "en" ? "Photo Records (Before/After)" : "写真記録（掃除前後の記録）"),
        ("icloud.fill", UserDefaults.standard.string(forKey:"app_language") == "en" ? "iCloud Sync (Family Sharing)" : "iCloud同期（家族間で共有）"),
        ("rectangle.3.group.fill", UserDefaults.standard.string(forKey:"app_language") == "en" ? "Home Screen Widget" : "ホーム画面ウィジェット"),
        ("calendar", UserDefaults.standard.string(forKey:"app_language") == "en" ? "Calendar View" : "カレンダー表示"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // ヘッダー
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(red:0.85, green:0.65, blue:0.1).opacity(0.15),
                                             Color(red:0.95, green:0.80, blue:0.2).opacity(0.08)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 90, height: 90)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(LinearGradient(
                                    colors: [Color(red:0.85, green:0.65, blue:0.1),
                                             Color(red:0.95, green:0.80, blue:0.2)],
                                    startPoint: .top, endPoint: .bottom
                                ))
                        }
                        Text(UserDefaults.standard.string(forKey:"app_language") == "en" ? "Pikari Premium" : "Pikari プレミアム")
                            .font(.title).fontWeight(.bold)
                        Text(UserDefaults.standard.string(forKey:"app_language") == "en" ? "Unlock all features for better cleaning management" : "すべての機能をアンロックして\nより快適な掃除管理を")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // 機能一覧
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(features, id: \.text) { feature in
                            HStack(spacing: 14) {
                                Image(systemName: feature.icon)
                                    .font(.title3)
                                    .foregroundStyle(LinearGradient(
                                        colors: [Color(red:0.85, green:0.65, blue:0.1),
                                                 Color(red:0.95, green:0.80, blue:0.2)],
                                        startPoint: .top, endPoint: .bottom
                                    ))
                                    .frame(width: 32)
                                Text(feature.text)
                                    .font(.subheadline).fontWeight(.medium)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundStyle(.teal)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // プラン選択
                    VStack(spacing: 10) {
                        ForEach(PikariProduct.allCases, id: \.self) { plan in
                            PlanCard(
                                plan: plan,
                                product: purchaseManager.product(for: plan),
                                isSelected: selectedProduct == plan
                            ) {
                                selectedProduct = plan
                            }
                        }
                    }
                    .padding(.horizontal)

                    // 購入ボタン
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                if let product = purchaseManager.product(for: selectedProduct) {
                                    await purchaseManager.purchase(product)
                                    if purchaseManager.isPremium { dismiss() }
                                }
                            }
                        } label: {
                            Group {
                                if purchaseManager.isPurchasing {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(UserDefaults.standard.string(forKey:"app_language") == "en" ? "Get Started" : "今すぐ始める")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(
                                colors: [Color(red:0.85, green:0.65, blue:0.1),
                                         Color(red:0.95, green:0.80, blue:0.2)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(purchaseManager.isPurchasing || purchaseManager.products.isEmpty)

                        Button(UserDefaults.standard.string(forKey:"app_language") == "en" ? "Restore Purchase" : "購入を復元する") {
                            Task { await purchaseManager.restorePurchases() }
                        }
                        .font(.subheadline).foregroundStyle(.secondary)

                        if let error = purchaseManager.errorMessage {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }

                        // 注記
                        Text(UserDefaults.standard.string(forKey:"app_language") == "en" ? "Charged to your Apple ID. Subscriptions auto-renew unless cancelled 24 hours before the period ends." : "購入はApple IDに請求されます。サブスクリプションは期間終了の24時間前までキャンセルしない限り自動更新されます。")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UserDefaults.standard.string(forKey:"app_language") == "en" ? "Close" : "閉じる") { dismiss() }
                }
            }
        }
    }
}

// MARK: - PlanCard

struct PlanCard: View {
    let plan: PikariProduct
    let product: Product?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 選択インジケーター
                ZStack {
                    Circle()
                        .stroke(isSelected
                            ? Color(red:0.85, green:0.65, blue:0.1)
                            : Color(.systemGray3),
                            lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color(red:0.85, green:0.65, blue:0.1))
                            .frame(width: 13, height: 13)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(plan.displayName)
                            .font(.subheadline).fontWeight(.semibold)
                        if plan == .yearly {
                            Text(UserDefaults.standard.string(forKey:"app_language") == "en" ? "Recommended" : "おすすめ")
                                .font(.caption2).fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.teal)
                                .clipShape(Capsule())
                        }
                    }
                    Text(plan.description)
                        .font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                // 価格
                if let product {
                    Text(product.displayPrice)
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundStyle(isSelected
                            ? Color(red:0.85, green:0.65, blue:0.1)
                            : .primary)
                } else {
                    ProgressView().scaleEffect(0.8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected
                                ? Color(red:0.85, green:0.65, blue:0.1)
                                : Color(.systemGray4),
                                lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Extension（プレミアムゲート）

extension View {
    /// プレミアム機能へのアクセスをゲートするモディファイア
    @MainActor
    func premiumGated(
        featureName: String,
        description: String,
        icon: String
    ) -> some View {
        modifier(PremiumGateModifier(
            featureName: featureName,
            description: description,
            icon: icon
        ))
    }
}

struct PremiumGateModifier: ViewModifier {
    let featureName: String
    let description: String
    let icon: String
    @Environment(PurchaseManager.self) private var purchaseManager

    func body(content: Content) -> some View {
        if purchaseManager.isPremium {
            content
        } else {
            PremiumGateView(
                featureName: featureName,
                featureDescription: description,
                featureIcon: icon
            )
        }
    }
}
