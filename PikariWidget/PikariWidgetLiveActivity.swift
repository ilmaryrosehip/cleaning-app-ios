import ActivityKit
import WidgetKit
import SwiftUI

// Live Activity（将来の掃除タイマー機能用に予約）
struct PikariWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var taskTitle: String
        var elapsedMinutes: Int
    }
    var taskTitle: String
}
