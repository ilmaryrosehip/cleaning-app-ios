import Foundation
import StoreKit
import SwiftUI

// Swift 6でTransaction型が曖昧になるため型エイリアスを定義
private typealias SKTransaction = StoreKit.Transaction

// MARK: - 商品ID定義（買い切り）
enum PremiumProduct {
    static let premiumID = "com.hiroki.CleaningApp.premium"
    static let allIDs: Set<String> = [premiumID]
}

// MARK: - PremiumManager
@MainActor
@Observable
final class PremiumManager {

    static let shared = PremiumManager()
    private init() {}

    var isPremium: Bool = false
    var premiumProduct: Product? = nil
    var isPurchasing: Bool = false
    var errorMessage: String? = nil

    private var updateListenerTask: Task<Void, Never>? = nil

    // MARK: - 初期化

    func initialize() async {
        updateListenerTask = listenForTransactions()
        await loadProducts()
        await updatePurchasedProducts()
    }

    // MARK: - 商品情報取得

    func loadProducts() async {
        do {
            let products = try await Product.products(for: PremiumProduct.allIDs)
            premiumProduct = products.first
        } catch {
            errorMessage = "商品情報の取得に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - 購入

    func purchase() async -> Bool {
        guard let product = premiumProduct else {
            errorMessage = "商品情報を読み込み中です。しばらくお待ちください。"
            return false
        }
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

    // MARK: - 購入状態更新

    func updatePurchasedProducts() async {
        var hasPremium = false
        for await result in SKTransaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if PremiumProduct.allIDs.contains(transaction.productID) {
                    hasPremium = true
                }
            } catch {}
        }
        isPremium = hasPremium
    }

    // MARK: - トランザクション監視

    private nonisolated func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in SKTransaction.updates {
                if case .verified(let transaction) = result {
                    await self?.finishAndRefresh(transaction)
                }
            }
        }
    }

    private func finishAndRefresh(_ transaction: SKTransaction) async {
        await transaction.finish()
        await updatePurchasedProducts()
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
