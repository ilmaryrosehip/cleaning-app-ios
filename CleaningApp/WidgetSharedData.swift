import Foundation

// MARK: - ウィジェット共有データ
// メインアプリとウィジェット間でUserDefaults(App Groups)でデータを共有する

/// App Groups識別子（Xcodeで設定するものと一致させること）
let widgetAppGroupID = "group.com.hiroki.CleaningApp"

// MARK: - WidgetTaskEntry（ウィジェット用タスクデータ）

struct WidgetTaskEntry: Codable, Identifiable {
    let id: UUID
    let title: String
    let roomName: String
    let isOverdue: Bool
    let isDueToday: Bool
    let nextDueDateText: String   // "今日" / "明日" / "3日後" など
}

// MARK: - WidgetPartEntry（ウィジェット用在庫アラートデータ）

struct WidgetPartEntry: Codable, Identifiable {
    let id: UUID
    let name: String
    let fixtureName: String
    let stockCount: Int
}

// MARK: - WidgetSharedData（共有データコンテナ）

struct WidgetSharedData: Codable {
    var todayTasks: [WidgetTaskEntry]       // 今日のタスク
    var overdueTasks: [WidgetTaskEntry]     // 期限超過タスク
    var upcomingTask: WidgetTaskEntry?      // 次の直近タスク
    var lowStockParts: [WidgetPartEntry]    // 在庫不足パーツ
    var weeklyDoneCount: Int                // 今週完了数
    var weeklyTotalCount: Int               // 今週の全タスク数
    var updatedAt: Date

    static var empty: WidgetSharedData {
        WidgetSharedData(
            todayTasks: [],
            overdueTasks: [],
            upcomingTask: nil,
            lowStockParts: [],
            weeklyDoneCount: 0,
            weeklyTotalCount: 0,
            updatedAt: .now
        )
    }
}

// MARK: - WidgetDataStore（読み書きユーティリティ）

enum WidgetDataStore {
    private static let key = "pikari_widget_data"

    /// メインアプリ側から書き込む
    static func save(_ data: WidgetSharedData) {
        guard let defaults = UserDefaults(suiteName: widgetAppGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: key)
        }
    }

    /// ウィジェット側から読み込む
    static func load() -> WidgetSharedData {
        guard let defaults = UserDefaults(suiteName: widgetAppGroupID),
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(WidgetSharedData.self, from: data)
        else { return .empty }
        return decoded
    }
}
