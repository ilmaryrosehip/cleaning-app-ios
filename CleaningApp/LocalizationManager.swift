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

// MARK: - L10nKey（翻訳キー定義）

enum L10nKey {
    // タブ
    case tabHome, tabFloorPlan, tabCalendar, tabSupply, tabReport, tabHistory, tabMyPage

    // ホーム
    case overdueTask, todayTask, weeklyDone, allTasks, addTask
    case complete, cancel, save, edit, delete, close, add
    case taskName, room, duration, memo, notes

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
}

extension L10nKey {
    var ja: String {
        switch self {
        // タブ
        case .tabHome:      return "ホーム"
        case .tabFloorPlan: return "間取り"
        case .tabCalendar:  return "カレンダー"
        case .tabSupply:    return "用品"
        case .tabReport:    return "レポート"
        case .tabHistory:   return "履歴"
        case .tabMyPage:    return "マイページ"
        // 共通
        case .complete:  return "完了"
        case .cancel:    return "キャンセル"
        case .save:      return "保存"
        case .edit:      return "編集"
        case .delete:    return "削除"
        case .close:     return "閉じる"
        case .add:       return "追加"
        case .taskName:  return "タスク名"
        case .room:      return "部屋"
        case .duration:  return "所要時間"
        case .memo:      return "メモ"
        case .notes:     return "備考"
        // ホーム
        case .overdueTask:  return "期限超過"
        case .todayTask:    return "今日のタスク"
        case .weeklyDone:   return "今週完了"
        case .allTasks:     return "すべてのタスク"
        case .addTask:      return "タスクを追加"
        // カレンダー
        case .calendar:       return "カレンダー"
        case .scheduledTasks: return "予定タスク"
        case .completed:      return "完了済み"
        // レポート
        case .report:           return "レポート"
        case .thisWeek:         return "今週"
        case .thisMonth:        return "今月"
        case .thisYear:         return "今年"
        case .completedTasks:   return "完了タスク"
        case .totalTime:        return "合計時間"
        case .roomsCleaned:     return "対応部屋数"
        case .avgTime:          return "平均時間/回"
        case .dailyChart:       return "日別完了タスク数"
        case .weekdayChart:     return "曜日別完了数"
        case .roomChart:        return "部屋別完了数"
        case .taskRanking:      return "よく完了するタスク TOP5"
        // 履歴
        case .history:           return "履歴"
        case .searchPlaceholder: return "タスク名・部屋名・メモで検索"
        case .noRecords:         return "記録がありません"
        case .photoRecord:       return "写真記録"
        case .addPhoto:          return "写真を追加する"
        case .noPhoto:           return "掃除前後の写真を記録できます"
        // 用品
        case .supply:           return "用品"
        case .supplyManagement: return "用品管理"
        case .purchaseList:     return "購入リスト"
        case .addSupply:        return "用品を追加"
        case .stockOk:          return "十分"
        case .stockLow:         return "残り少"
        case .stockOut:         return "切れ"
        case .reorderNeeded:    return "補充が必要"
        // エクスポート
        case .export:        return "エクスポート"
        case .exportData:    return "エクスポートするデータ"
        case .taskHistory:   return "タスク完了履歴"
        case .inventory:     return "消耗品在庫"
        case .maintenance:   return "設備メンテナンス記録"
        case .allData:       return "すべてのデータ"
        case .csvFormat:     return "ExcelやNumbersで開けます"
        case .pdfFormat:     return "印刷・共有に適したPDF形式"
        case .exporting:     return "生成中..."
        case .exportTarget:  return "エクスポート対象"
        // プレミアム
        case .premium:          return "プレミアム"
        case .premiumTitle:     return "Pikari プレミアム"
        case .premiumDesc:      return "買い切りですべての機能を解錠"
        case .buyNow:           return "今すぐ購入する"
        case .restore:          return "購入を復元する"
        case .premiumFeatures:  return "プレミアム特典"
        case .unlockAll:        return "すべての機能を解錠"
        case .oneTimePurchase:  return "一度の購入で永久にご利用いただけます"
        // マイページ
        case .myPage:             return "マイページ"
        case .profile:            return "プロフィール"
        case .statistics:         return "統計"
        case .totalCompleted:     return "総完了タスク"
        case .totalMinutes:       return "総掃除時間"
        case .streakDays:         return "連続完了日数"
        case .monthlyRate:        return "今月の達成率"
        case .familySharing:      return "家族共有"
        case .familyMembers:      return "メンバー"
        case .familyContribution: return "貢献度"
        case .inviteMember:       return "メンバーを招待"
        case .premiumPlan:        return "プレミアムプラン"
        case .freePlan:           return "無料プラン"
        case .purchaseDate:       return "購入日"
        case .notificationSettings: return "通知設定"
        case .notifyOnOff:        return "通知"
        case .notifyTime:         return "通知時間"
        case .customize:          return "カスタマイズ"
        case .colorTheme:         return "カラーテーマ"
        case .appIcon:            return "アプリアイコン"
        case .dataManagement:     return "データ管理"
        case .icloudSync:         return "iCloud同期"
        case .backup:             return "バックアップ"
        case .resetData:          return "データをリセット"
        case .languageSettings:   return "言語設定"
        case .language:           return "言語"
        case .support:            return "サポート"
        case .howToUse:           return "操作方法"
        case .sendFeedback:       return "フィードバックを送る"
        case .writeReview:        return "App Storeでレビューを書く"
        case .privacyPolicy:      return "プライバシーポリシー"
        case .termsOfService:     return "利用規約"
        case .appInfo:            return "アプリ情報"
        case .version:            return "バージョン"
        case .licenses:           return "ライセンス"
        // ヘルプ
        case .howToSetup:         return "はじめに（セットアップ）"
        case .howToDaily:         return "毎日の使い方"
        case .howToFixture:       return "設備・消耗品の管理"
        case .howToReport:        return "レポート・カレンダー"
        case .howToExport:        return "データのエクスポート"
        case .step:               return "ステップ"
        case .setupHome:          return "家を登録する"
        case .setupRoom:          return "部屋を追加する"
        case .setupTask:          return "タスクを作成する"
        case .dailyComplete:      return "タスクを完了する"
        case .dailyPhoto:         return "写真を記録する"
        case .dailyWidget:        return "ウィジェットを使う"
        case .fixtureRegister:    return "設備を登録する"
        case .fixturePartAdd:     return "消耗品パーツを追加する"
        case .fixtureStockRefill: return "在庫を補充する"
        }
    }

    var en: String {
        switch self {
        // Tabs
        case .tabHome:      return "Home"
        case .tabFloorPlan: return "Floor Plan"
        case .tabCalendar:  return "Calendar"
        case .tabSupply:    return "Supplies"
        case .tabReport:    return "Report"
        case .tabHistory:   return "History"
        case .tabMyPage:    return "My Page"
        // Common
        case .complete:  return "Complete"
        case .cancel:    return "Cancel"
        case .save:      return "Save"
        case .edit:      return "Edit"
        case .delete:    return "Delete"
        case .close:     return "Close"
        case .add:       return "Add"
        case .taskName:  return "Task Name"
        case .room:      return "Room"
        case .duration:  return "Duration"
        case .memo:      return "Memo"
        case .notes:     return "Notes"
        // Home
        case .overdueTask:  return "Overdue"
        case .todayTask:    return "Today's Tasks"
        case .weeklyDone:   return "This Week"
        case .allTasks:     return "All Tasks"
        case .addTask:      return "Add Task"
        // Calendar
        case .calendar:       return "Calendar"
        case .scheduledTasks: return "Scheduled Tasks"
        case .completed:      return "Completed"
        // Report
        case .report:           return "Report"
        case .thisWeek:         return "This Week"
        case .thisMonth:        return "This Month"
        case .thisYear:         return "This Year"
        case .completedTasks:   return "Completed Tasks"
        case .totalTime:        return "Total Time"
        case .roomsCleaned:     return "Rooms Cleaned"
        case .avgTime:          return "Avg. Time/Task"
        case .dailyChart:       return "Daily Completed Tasks"
        case .weekdayChart:     return "By Day of Week"
        case .roomChart:        return "By Room"
        case .taskRanking:      return "Top 5 Most Completed Tasks"
        // History
        case .history:           return "History"
        case .searchPlaceholder: return "Search by task, room, or memo"
        case .noRecords:         return "No records found"
        case .photoRecord:       return "Photo Record"
        case .addPhoto:          return "Add Photos"
        case .noPhoto:           return "Record before/after cleaning photos"
        // Supply
        case .supply:           return "Supplies"
        case .supplyManagement: return "Supply Management"
        case .purchaseList:     return "Shopping List"
        case .addSupply:        return "Add Supply"
        case .stockOk:          return "In Stock"
        case .stockLow:         return "Low Stock"
        case .stockOut:         return "Out of Stock"
        case .reorderNeeded:    return "Needs Reorder"
        // Export
        case .export:        return "Export"
        case .exportData:    return "Data to Export"
        case .taskHistory:   return "Task History"
        case .inventory:     return "Parts Inventory"
        case .maintenance:   return "Maintenance Records"
        case .allData:       return "All Data"
        case .csvFormat:     return "Open with Excel or Numbers"
        case .pdfFormat:     return "PDF format for printing & sharing"
        case .exporting:     return "Generating..."
        case .exportTarget:  return "Export Target"
        // Premium
        case .premium:          return "Premium"
        case .premiumTitle:     return "Pikari Premium"
        case .premiumDesc:      return "Unlock all features with one-time purchase"
        case .buyNow:           return "Buy Now"
        case .restore:          return "Restore Purchase"
        case .premiumFeatures:  return "Premium Features"
        case .unlockAll:        return "Unlock All Features"
        case .oneTimePurchase:  return "One-time purchase, yours forever"
        // My Page
        case .myPage:             return "My Page"
        case .profile:            return "Profile"
        case .statistics:         return "Statistics"
        case .totalCompleted:     return "Total Completed"
        case .totalMinutes:       return "Total Cleaning Time"
        case .streakDays:         return "Streak Days"
        case .monthlyRate:        return "Monthly Rate"
        case .familySharing:      return "Family Sharing"
        case .familyMembers:      return "Members"
        case .familyContribution: return "Contribution"
        case .inviteMember:       return "Invite Member"
        case .premiumPlan:        return "Premium Plan"
        case .freePlan:           return "Free Plan"
        case .purchaseDate:       return "Purchase Date"
        case .notificationSettings: return "Notifications"
        case .notifyOnOff:        return "Notifications"
        case .notifyTime:         return "Notification Time"
        case .customize:          return "Customize"
        case .colorTheme:         return "Color Theme"
        case .appIcon:            return "App Icon"
        case .dataManagement:     return "Data Management"
        case .icloudSync:         return "iCloud Sync"
        case .backup:             return "Backup"
        case .resetData:          return "Reset Data"
        case .languageSettings:   return "Language"
        case .language:           return "Language"
        case .support:            return "Support"
        case .howToUse:           return "How to Use"
        case .sendFeedback:       return "Send Feedback"
        case .writeReview:        return "Write a Review"
        case .privacyPolicy:      return "Privacy Policy"
        case .termsOfService:     return "Terms of Service"
        case .appInfo:            return "App Info"
        case .version:            return "Version"
        case .licenses:           return "Licenses"
        // Help
        case .howToSetup:         return "Getting Started"
        case .howToDaily:         return "Daily Use"
        case .howToFixture:       return "Managing Fixtures & Parts"
        case .howToReport:        return "Reports & Calendar"
        case .howToExport:        return "Exporting Data"
        case .step:               return "Step"
        case .setupHome:          return "Register your home"
        case .setupRoom:          return "Add rooms"
        case .setupTask:          return "Create tasks"
        case .dailyComplete:      return "Complete a task"
        case .dailyPhoto:         return "Record photos"
        case .dailyWidget:        return "Use widgets"
        case .fixtureRegister:    return "Register a fixture"
        case .fixturePartAdd:     return "Add consumable parts"
        case .fixtureStockRefill: return "Refill stock"
        }
    }
}

// MARK: - View拡張（便利メソッド）

extension View {
    /// LocalizationManager.shared を使って翻訳する
    func L(_ key: L10nKey) -> String {
        LocalizationManager.shared.t(key)
    }
}

/// グローバル関数として使える翻訳ショートカット
func L(_ key: L10nKey) -> String {
    LocalizationManager.shared.t(key)
}
