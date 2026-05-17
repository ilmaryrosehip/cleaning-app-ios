import Foundation
import StoreKit
import SwiftUI

// MARK: - 商品ID定義
enum PremiumProduct {
    /// 月額サブスクリプション
    static let monthlyID = "com.hiroki.CleaningApp.premium.monthly"
    /// 年額サブスクリプション
    static let yearlyID  = "com.hiroki.CleaningApp.premium.yearly"

    static let allIDs: Set<String> = [monthlyID, yearlyID]
}

// MARK: - PremiumManager
@MainActor
@Observable
final class PremiumManager {

    static let shared = PremiumManager()
    private init() {}

    /// プレミアム有効フラグ
    var isPremium: Bool = false

    /// 購入済み商品
    var purchasedSubscriptions: [Transaction] = []

    /// 月額商品
    var monthlyProduct: Product? = nil
    /// 年額商品
    var yearlyProduct: Product?  = nil

    /// 購入処理中フラグ
    var isPurchasing: Bool = false

    /// エラーメッセージ
    var errorMessage: String? = nil

    /// トランザクション監視タスク
    private var updateListenerTask: Task<Void, Never>? = nil

    // MARK: - 初期化（アプリ起動時に呼ぶ）

    func initialize() async {
        // トランザクション監視開始
        updateListenerTask = listenForTransactions()

        // 商品情報を取得
        await loadProducts()

        // 購入状態を更新
        await updatePurchasedProducts()
    }

    // MARK: - 商品情報取得

    func loadProducts() async {
        do {
            let products = try await Product.products(for: PremiumProduct.allIDs)
            for product in products {
                switch product.id {
                case PremiumProduct.monthlyID: monthlyProduct = product
                case PremiumProduct.yearlyID:  yearlyProduct  = product
                default: break
                }
            }
        } catch {
            errorMessage = "商品情報の取得に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - 購入

    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                errorMessage = "購入が保留中です。承認をお待ちください。"
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "購入に失敗しました: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 購入復元

    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "購入の復元に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - 購入状態の更新

    func updatePurchasedProducts() async {
        var purchased: [Transaction] = []
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if PremiumProduct.allIDs.contains(transaction.productID) {
                    purchased.append(transaction)
                }
            } catch {
                // 無効なトランザクションは無視
            }
        }
        purchasedSubscriptions = purchased
        isPremium = !purchased.isEmpty
    }

    // MARK: - トランザクション監視

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await self?.updatePurchasedProducts()
                    await transaction?.finish()
                } catch {
                    // 検証失敗は無視
                }
            }
        }
    }

    // MARK: - 検証ヘルパー

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let value): return value
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
