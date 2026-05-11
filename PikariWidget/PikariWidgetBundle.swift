import WidgetKit
import SwiftUI

@main
struct PikariWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayTasksWidget()
        NextTaskWidget()
        LowStockWidget()
        WeeklyProgressWidget()
    }
}
