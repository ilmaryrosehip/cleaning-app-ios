import Foundation
import SwiftUI

// MARK: - 対応言語

enum AppLanguage: String, CaseIterable, Identifiable {
    case japanese = "ja"
    case english  = "en"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english:  return "English"
        }
    }
    var flag: String {
        switch self {
        case .japanese: return "🇯🇵"
        case .english:  return "🇺🇸"
        }
    }
}

// MARK: - LocalizationManager

@MainActor
@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()
    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "ja"
        language = AppLanguage(rawValue: saved) ?? .japanese
    }

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        }
    }

    func t(_ key: L10nKey) -> String {
        switch language {
        case .japanese: return key.ja
        case .english:  return key.en
        }
    }
}

// MARK: - グローバル翻訳関数（@MainActor）

@MainActor
func L(_ key: L10nKey) -> String {
    LocalizationManager.shared.t(key)
}

// MARK: - L10nKey（翻訳キー定義）

enum L10nKey {
    // タブ
    case tabHome, tabFloorPlan, tabCalendar, tabSupply, tabReport, tabHistory, tabMyPage

    // 共通
    case complete, cancel, save, edit, delete, close, add
    case taskName, room, duration, memo, notes

    // ホーム
    case overdueTask, todayTask, weeklyDone, allTasks, addTask

    // カレンダー
    case calendar, scheduledTasks, completed

    // レポート
    case report, thisWeek, thisMonth, thisYear
    case completedTasks, totalTime, roomsCleaned, avgTime
    case dailyChart, weekdayChart, roomChart, taskRanking

    // 履歴
    case history, searchPlaceholder, noRecords
    case photoRecord, addPhoto, noPhoto

    // 用品
    case supply, supplyManagement, purchaseList, addSupply
    case stockOk, stockLow, stockOut, reorderNeeded

    // エクスポート
    case export, exportData, taskHistory, inventory, maintenance, allData
    case csvFormat, pdfFormat, exporting, exportTarget

    // プレミアム
    case premium, premiumTitle, premiumDesc, buyNow, restore
    case premiumFeatures, unlockAll, oneTimePurchase

    // マイページ
    case myPage, profile, statistics
    case totalCompleted, totalMinutes, streakDays, monthlyRate
    case familySharing, familyMembers, familyContribution, inviteMember
    case premiumPlan, freePlan, purchaseDate
    case notificationSettings, notifyOnOff, notifyTime
    case customize, colorTheme, appIcon
    case dataManagement, icloudSync, backup, resetData
    case languageSettings, language
    case support, howToUse, sendFeedback, writeReview
    case privacyPolicy, termsOfService
    case appInfo, version, licenses

    // ヘルプ
    case howToSetup, howToDaily, howToFixture, howToReport, howToExport
    case step, setupHome, setupRoom, setupTask
    case dailyComplete, dailyPhoto, dailyWidget
    case fixtureRegister, fixturePartAdd, fixtureStockRefill

    // ホーム追加
    case today, upcoming, overdue, daysOverdue, daysLater, tomorrow
    case recordCompletion, duplicateWarning, duplicateMessage, recordAnyway
    case partsUsed, partsUsedFooter, stockCount, noTasks, noTasksHint, all
    // カレンダー追加
    case noSchedule
    // レポート追加
    case noData
    // 履歴追加
    case completedOn, elapsedTime
    // 用品追加
    case storeName, purchaseURL, category, openLink, addPurchaseMemo
    case linkedTasks, noLinkedTasks, purchaseMemo, noSupplies
    case quantity, estimatedPrice, total, markPurchased, noPurchaseMemo, addSupplyButton
    // 消耗品在庫追加
    case partsInventory, stockAdd, stockAfter, noPartsHint
    case purchaseCount, unitPrice, markAsReplaced, replacedDateUpdated
    case nextReplacement, lastReplaced, replacementCycle, daysUntil, daysExceeded
    // 間取り追加
    case addRoom, editRoom, roomName, roomIcon, addFixture, fixtures, tasks
    // 設備追加
    case fixture, fixtureManagement, addPart, partName, partNumber
    case replacementMonths, lastReplacedAt, purchaseInfo, fixturePresets, addFromPreset
    // オンボーディング追加
    case welcomeTitle, welcomeSubtitle, homeName, homeNamePlaceholder, getStarted
}

extension L10nKey {
    var ja: String {
        switch self {
        case .tabHome:      return "ホーム"
        case .tabFloorPlan: return "間取り"
        case .tabCalendar:  return "カレンダー"
        case .tabSupply:    return "用品"
        case .tabReport:    return "レポート"
        case .tabHistory:   return "履歴"
        case .tabMyPage:    return "マイページ"
        case .complete:     return "完了"
        case .cancel:       return "キャンセル"
        case .save:         return "保存"
        case .edit:         return "編集"
        case .delete:       return "削除"
        case .close:        return "閉じる"
        case .add:          return "追加"
        case .taskName:     return "タスク名"
        case .room:         return "部屋"
        case .duration:     return "所要時間"
        case .memo:         return "メモ"
        case .notes:        return "備考"
        case .overdueTask:  return "期限超過"
        case .todayTask:    return "今日のタスク"
        case .weeklyDone:   return "今週完了"
        case .allTasks:     return "すべてのタスク"
        case .addTask:      return "タスクを追加"
        case .calendar:     return "カレンダー"
        case .scheduledTasks: return "予定タスク"
        case .completed:    return "完了済み"
        case .report:       return "レポート"
        case .thisWeek:     return "今週"
        case .thisMonth:    return "今月"
        case .thisYear:     return "今年"
        case .completedTasks: return "完了タスク"
        case .totalTime:    return "合計時間"
        case .roomsCleaned: return "対応部屋数"
        case .avgTime:      return "平均時間/回"
        case .dailyChart:   return "日別完了タスク数"
        case .weekdayChart: return "曜日別完了数"
        case .roomChart:    return "部屋別完了数"
        case .taskRanking:  return "よく完了するタスク TOP5"
        case .history:      return "履歴"
        case .searchPlaceholder: return "タスク名・部屋名・メモで検索"
        case .noRecords:    return "記録がありません"
        case .photoRecord:  return "写真記録"
        case .addPhoto:     return "写真を追加する"
        case .noPhoto:      return "掃除前後の写真を記録できます"
        case .supply:       return "用品"
        case .supplyManagement: return "用品管理"
        case .purchaseList: return "購入リスト"
        case .addSupply:    return "用品を追加"
        case .stockOk:      return "十分"
        case .stockLow:     return "残り少"
        case .stockOut:     return "切れ"
        case .reorderNeeded: return "補充が必要"
        case .export:       return "エクスポート"
        case .exportData:   return "エクスポートするデータ"
        case .taskHistory:  return "タスク完了履歴"
        case .inventory:    return "消耗品在庫"
        case .maintenance:  return "設備メンテナンス記録"
        case .allData:      return "すべてのデータ"
        case .csvFormat:    return "ExcelやNumbersで開けます"
        case .pdfFormat:    return "印刷・共有に適したPDF形式"
        case .exporting:    return "生成中..."
        case .exportTarget: return "エクスポート対象"
        case .premium:      return "プレミアム"
        case .premiumTitle: return "Pikari プレミアム"
        case .premiumDesc:  return "買い切りですべての機能を解錠"
        case .buyNow:       return "今すぐ購入する"
        case .restore:      return "購入を復元する"
        case .premiumFeatures: return "プレミアム特典"
        case .unlockAll:    return "すべての機能を解錠"
        case .oneTimePurchase: return "一度の購入で永久にご利用いただけます"
        case .myPage:       return "マイページ"
        case .profile:      return "プロフィール"
        case .statistics:   return "統計"
        case .totalCompleted: return "総完了タスク"
        case .totalMinutes: return "総掃除時間"
        case .streakDays:   return "連続完了日数"
        case .monthlyRate:  return "今月の達成率"
        case .familySharing: return "家族共有"
        case .familyMembers: return "メンバー"
        case .familyContribution: return "貢献度"
        case .inviteMember: return "メンバーを招待"
        case .premiumPlan:  return "プレミアムプラン"
        case .freePlan:     return "無料プラン"
        case .purchaseDate: return "購入日"
        case .notificationSettings: return "通知設定"
        case .notifyOnOff:  return "通知"
        case .notifyTime:   return "通知時間"
        case .customize:    return "カスタマイズ"
        case .colorTheme:   return "カラーテーマ"
        case .appIcon:      return "アプリアイコン"
        case .dataManagement: return "データ管理"
        case .icloudSync:   return "iCloud同期"
        case .backup:       return "バックアップ"
        case .resetData:    return "データをリセット"
        case .languageSettings: return "言語設定"
        case .language:     return "言語"
        case .support:      return "サポート"
        case .howToUse:     return "操作方法"
        case .sendFeedback: return "フィードバックを送る"
        case .writeReview:  return "App Storeでレビューを書く"
        case .privacyPolicy: return "プライバシーポリシー"
        case .termsOfService: return "利用規約"
        case .appInfo:      return "アプリ情報"
        case .version:      return "バージョン"
        case .licenses:     return "ライセンス"
        case .howToSetup:   return "はじめに（セットアップ）"
        case .howToDaily:   return "毎日の使い方"
        case .howToFixture: return "設備・消耗品の管理"
        case .howToReport:  return "レポート・カレンダー"
        case .howToExport:  return "データのエクスポート"
        case .step:         return "ステップ"
        case .setupHome:    return "家を登録する"
        case .setupRoom:    return "部屋を追加する"
        case .setupTask:    return "タスクを作成する"
        case .dailyComplete: return "タスクを完了する"
        case .dailyPhoto:   return "写真を記録する"
        case .dailyWidget:  return "ウィジェットを使う"
        case .fixtureRegister: return "設備を登録する"
        case .fixturePartAdd: return "消耗品パーツを追加する"
        case .fixtureStockRefill: return "在庫を補充する"

        case .today: return "今日"
        case .upcoming: return "近日中"
        case .overdue: return "期限超過"
        case .daysOverdue: return "日超過"
        case .daysLater: return "日後"
        case .tomorrow: return "明日"
        case .recordCompletion: return "完了を記録"
        case .duplicateWarning: return "二重完了の確認"
        case .duplicateMessage: return "本日すでに完了が記録されています。続けて記録しますか？"
        case .recordAnyway: return "それでも記録する"
        case .partsUsed: return "消耗品パーツの使用数"
        case .partsUsedFooter: return "使用した分だけ在庫から差し引かれます"
        case .stockCount: return "在庫"
        case .noTasks: return "タスクがありません"
        case .noTasksHint: return "右上の＋ボタンでタスクを追加しましょう"
        case .all: return "すべて"
        case .noSchedule: return "この日の予定・記録はありません"
        case .noData: return "データがありません"
        case .completedOn: return "完了日時"
        case .elapsedTime: return "所要時間"
        case .storeName: return "店名"
        case .purchaseURL: return "購入URL"
        case .category: return "カテゴリ"
        case .openLink: return "購入ページを開く"
        case .addPurchaseMemo: return "購入メモを追加"
        case .linkedTasks: return "使用しているタスク"
        case .noLinkedTasks: return "紐づいたタスクがありません"
        case .purchaseMemo: return "購入メモ"
        case .noSupplies: return "購入先が未登録です"
        case .quantity: return "数量"
        case .estimatedPrice: return "予算"
        case .total: return "合計（目安）"
        case .markPurchased: return "購入済みにする"
        case .noPurchaseMemo: return "購入メモがありません"
        case .addSupplyButton: return "用品画面から購入メモを追加できます"
        case .partsInventory: return "消耗品在庫"
        case .stockAdd: return "在庫を追加"
        case .stockAfter: return "購入後の在庫"
        case .noPartsHint: return "「間取り」タブ → 部屋 → 設備 → パーツを追加"
        case .purchaseCount: return "購入数"
        case .unitPrice: return "単価"
        case .markAsReplaced: return "今回購入分を交換済みとして記録"
        case .replacedDateUpdated: return "最終交換日が更新されます"
        case .nextReplacement: return "次回交換予定"
        case .lastReplaced: return "最終交換"
        case .replacementCycle: return "交換周期"
        case .daysUntil: return "交換まで"
        case .daysExceeded: return "日超過"
        case .addRoom: return "部屋を追加"
        case .editRoom: return "部屋を編集"
        case .roomName: return "部屋名"
        case .roomIcon: return "アイコン"
        case .addFixture: return "設備を追加"
        case .fixtures: return "設備・器具"
        case .tasks: return "タスク"
        case .fixture: return "設備"
        case .fixtureManagement: return "設備管理"
        case .addPart: return "パーツを追加"
        case .partName: return "パーツ名"
        case .partNumber: return "型番"
        case .replacementMonths: return "交換周期（月）"
        case .lastReplacedAt: return "最終交換日"
        case .purchaseInfo: return "購入情報"
        case .fixturePresets: return "プリセットから追加"
        case .addFromPreset: return "プリセットを選択"
        case .welcomeTitle: return "ようこそ Pikari へ"
        case .welcomeSubtitle: return "あなたの家のお掃除管理アプリ"
        case .homeName: return "家の名前"
        case .homeNamePlaceholder: return "例: 我が家"
        case .getStarted: return "はじめる"
        }
    }

    var en: String {
        switch self {
        case .tabHome:      return "Home"
        case .tabFloorPlan: return "Floor Plan"
        case .tabCalendar:  return "Calendar"
        case .tabSupply:    return "Supplies"
        case .tabReport:    return "Report"
        case .tabHistory:   return "History"
        case .tabMyPage:    return "My Page"
        case .complete:     return "Complete"
        case .cancel:       return "Cancel"
        case .save:         return "Save"
        case .edit:         return "Edit"
        case .delete:       return "Delete"
        case .close:        return "Close"
        case .add:          return "Add"
        case .taskName:     return "Task Name"
        case .room:         return "Room"
        case .duration:     return "Duration"
        case .memo:         return "Memo"
        case .notes:        return "Notes"
        case .overdueTask:  return "Overdue"
        case .todayTask:    return "Today's Tasks"
        case .weeklyDone:   return "This Week"
        case .allTasks:     return "All Tasks"
        case .addTask:      return "Add Task"
        case .calendar:     return "Calendar"
        case .scheduledTasks: return "Scheduled Tasks"
        case .completed:    return "Completed"
        case .report:       return "Report"
        case .thisWeek:     return "This Week"
        case .thisMonth:    return "This Month"
        case .thisYear:     return "This Year"
        case .completedTasks: return "Completed Tasks"
        case .totalTime:    return "Total Time"
        case .roomsCleaned: return "Rooms Cleaned"
        case .avgTime:      return "Avg. Time/Task"
        case .dailyChart:   return "Daily Completed Tasks"
        case .weekdayChart: return "By Day of Week"
        case .roomChart:    return "By Room"
        case .taskRanking:  return "Top 5 Most Completed Tasks"
        case .history:      return "History"
        case .searchPlaceholder: return "Search by task, room, or memo"
        case .noRecords:    return "No records found"
        case .photoRecord:  return "Photo Record"
        case .addPhoto:     return "Add Photos"
        case .noPhoto:      return "Record before/after cleaning photos"
        case .supply:       return "Supplies"
        case .supplyManagement: return "Supply Management"
        case .purchaseList: return "Shopping List"
        case .addSupply:    return "Add Supply"
        case .stockOk:      return "In Stock"
        case .stockLow:     return "Low Stock"
        case .stockOut:     return "Out of Stock"
        case .reorderNeeded: return "Needs Reorder"
        case .export:       return "Export"
        case .exportData:   return "Data to Export"
        case .taskHistory:  return "Task History"
        case .inventory:    return "Parts Inventory"
        case .maintenance:  return "Maintenance Records"
        case .allData:      return "All Data"
        case .csvFormat:    return "Open with Excel or Numbers"
        case .pdfFormat:    return "PDF format for printing & sharing"
        case .exporting:    return "Generating..."
        case .exportTarget: return "Export Target"
        case .premium:      return "Premium"
        case .premiumTitle: return "Pikari Premium"
        case .premiumDesc:  return "Unlock all features with one-time purchase"
        case .buyNow:       return "Buy Now"
        case .restore:      return "Restore Purchase"
        case .premiumFeatures: return "Premium Features"
        case .unlockAll:    return "Unlock All Features"
        case .oneTimePurchase: return "One-time purchase, yours forever"
        case .myPage:       return "My Page"
        case .profile:      return "Profile"
        case .statistics:   return "Statistics"
        case .totalCompleted: return "Total Completed"
        case .totalMinutes: return "Total Cleaning Time"
        case .streakDays:   return "Streak Days"
        case .monthlyRate:  return "Monthly Rate"
        case .familySharing: return "Family Sharing"
        case .familyMembers: return "Members"
        case .familyContribution: return "Contribution"
        case .inviteMember: return "Invite Member"
        case .premiumPlan:  return "Premium Plan"
        case .freePlan:     return "Free Plan"
        case .purchaseDate: return "Purchase Date"
        case .notificationSettings: return "Notifications"
        case .notifyOnOff:  return "Notifications"
        case .notifyTime:   return "Notification Time"
        case .customize:    return "Customize"
        case .colorTheme:   return "Color Theme"
        case .appIcon:      return "App Icon"
        case .dataManagement: return "Data Management"
        case .icloudSync:   return "iCloud Sync"
        case .backup:       return "Backup"
        case .resetData:    return "Reset Data"
        case .languageSettings: return "Language"
        case .language:     return "Language"
        case .support:      return "Support"
        case .howToUse:     return "How to Use"
        case .sendFeedback: return "Send Feedback"
        case .writeReview:  return "Write a Review"
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfService: return "Terms of Service"
        case .appInfo:      return "App Info"
        case .version:      return "Version"
        case .licenses:     return "Licenses"
        case .howToSetup:   return "Getting Started"
        case .howToDaily:   return "Daily Use"
        case .howToFixture: return "Managing Fixtures & Parts"
        case .howToReport:  return "Reports & Calendar"
        case .howToExport:  return "Exporting Data"
        case .step:         return "Step"
        case .setupHome:    return "Register your home"
        case .setupRoom:    return "Add rooms"
        case .setupTask:    return "Create tasks"
        case .dailyComplete: return "Complete a task"
        case .dailyPhoto:   return "Record photos"
        case .dailyWidget:  return "Use widgets"
        case .fixtureRegister: return "Register a fixture"
        case .fixturePartAdd: return "Add consumable parts"
        case .fixtureStockRefill: return "Refill stock"

        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .overdue: return "Overdue"
        case .daysOverdue: return " days overdue"
        case .daysLater: return " days"
        case .tomorrow: return "Tomorrow"
        case .recordCompletion: return "Record Completion"
        case .duplicateWarning: return "Duplicate Completion"
        case .duplicateMessage: return "A completion is already recorded today. Record again?"
        case .recordAnyway: return "Record Anyway"
        case .partsUsed: return "Parts Used"
        case .partsUsedFooter: return "Stock will be reduced by the amount used"
        case .stockCount: return "Stock"
        case .noTasks: return "No Tasks"
        case .noTasksHint: return "Tap + to add your first task"
        case .all: return "All"
        case .noSchedule: return "No tasks or records for this day"
        case .noData: return "No data available"
        case .completedOn: return "Completed At"
        case .elapsedTime: return "Duration"
        case .storeName: return "Store Name"
        case .purchaseURL: return "Purchase URL"
        case .category: return "Category"
        case .openLink: return "Open Purchase Page"
        case .addPurchaseMemo: return "Add Shopping Memo"
        case .linkedTasks: return "Linked Tasks"
        case .noLinkedTasks: return "No linked tasks"
        case .purchaseMemo: return "Shopping Memo"
        case .noSupplies: return "No store registered"
        case .quantity: return "Quantity"
        case .estimatedPrice: return "Budget"
        case .total: return "Total (Est.)"
        case .markPurchased: return "Mark as Purchased"
        case .noPurchaseMemo: return "No shopping memos"
        case .addSupplyButton: return "Add memos from the Supplies screen"
        case .partsInventory: return "Parts Inventory"
        case .stockAdd: return "Add Stock"
        case .stockAfter: return "Stock after purchase"
        case .noPartsHint: return "Floor Plan → Room → Fixture → Add Part"
        case .purchaseCount: return "Purchase Qty"
        case .unitPrice: return "Unit Price"
        case .markAsReplaced: return "Mark as replaced"
        case .replacedDateUpdated: return "Last replaced date will be updated"
        case .nextReplacement: return "Next Replacement"
        case .lastReplaced: return "Last Replaced"
        case .replacementCycle: return "Cycle"
        case .daysUntil: return "days until replacement"
        case .daysExceeded: return "days overdue"
        case .addRoom: return "Add Room"
        case .editRoom: return "Edit Room"
        case .roomName: return "Room Name"
        case .roomIcon: return "Icon"
        case .addFixture: return "Add Fixture"
        case .fixtures: return "Fixtures"
        case .tasks: return "Tasks"
        case .fixture: return "Fixture"
        case .fixtureManagement: return "Fixture Management"
        case .addPart: return "Add Part"
        case .partName: return "Part Name"
        case .partNumber: return "Part Number"
        case .replacementMonths: return "Replacement Cycle (months)"
        case .lastReplacedAt: return "Last Replaced"
        case .purchaseInfo: return "Purchase Info"
        case .fixturePresets: return "Add from Preset"
        case .addFromPreset: return "Select Preset"
        case .welcomeTitle: return "Welcome to Pikari"
        case .welcomeSubtitle: return "Your home cleaning management app"
        case .homeName: return "Home Name"
        case .homeNamePlaceholder: return "e.g. My Home"
        case .getStarted: return "Get Started"
        }
    }
}
