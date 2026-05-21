import AppIntents
import WidgetKit

struct RefreshWidgetIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "ウィジェットを更新"
    nonisolated(unsafe) static var description = IntentDescription("Pikariウィジェットのデータを更新します")
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
