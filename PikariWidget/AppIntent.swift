import AppIntents
import WidgetKit

// ウィジェットのリロードを要求するIntent
struct RefreshWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "ウィジェットを更新"
    static var description = IntentDescription("Pikariウィジェットのデータを更新します")

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
