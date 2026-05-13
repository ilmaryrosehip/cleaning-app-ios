import Foundation
import WidgetKit

// MARK: - App Groups識別子
let widgetAppGroupID = "group.com.hiroki.CleaningApp"

// MARK: - WidgetTaskEntry
struct WidgetTaskEntry: Codable, Identifiable {
    let id: UUID
    let title: String
    let roomName: String
    let isOverdue: Bool
    let isDueToday: Bool
    let nextDueDateText: String
}

// MARK: - WidgetPartEntry
struct WidgetPartEntry: Codable, Identifiable {
    let id: UUID
    let name: String
    let fixtureName: String
    let stockCount: Int
}

// MARK: - WidgetSharedData
struct WidgetSharedData: Codable {
    var todayTasks: [WidgetTaskEntry]
    var overdueTasks: [WidgetTaskEntry]
    var upcomingTask: WidgetTaskEntry?
    var lowStockParts: [WidgetPartEntry]
    var weeklyDoneCount: Int
    var weeklyTotalCount: Int
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

// MARK: - WidgetDataStore
enum WidgetDataStore {
    private static let key = "pikari_widget_data"

    static func save(_ data: WidgetSharedData) {
        guard let defaults = UserDefaults(suiteName: widgetAppGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: key)
        }
    }

    static func load() -> WidgetSharedData {
        guard let defaults = UserDefaults(suiteName: widgetAppGroupID),
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(WidgetSharedData.self, from: data)
        else { return .empty }
        return decoded
    }
}
