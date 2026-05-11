import AppIntents
import SwiftUI
import WidgetKit

// Control Widget（iOS 18+）: 将来のコントロールセンター連携用
@available(iOS 18.0, *)
struct PikariWidgetControl: ControlWidget {
    static let kind: String = "com.hiroki.CleaningApp.control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind,
            provider: PikariControlProvider()
        ) { value in
            ControlWidgetToggle(
                "掃除モード",
                isOn: value,
                action: ToggleCleaningModeIntent()
            ) { isOn in
                Label(
                    isOn ? "掃除中" : "Pikari",
                    systemImage: isOn ? "sparkles" : "house.fill"
                )
            }
        }
        .displayName("Pikari")
        .description("掃除モードを切り替えます")
    }
}

@available(iOS 18.0, *)
struct PikariControlProvider: ControlValueProvider {
    var previewValue: Bool { false }
    func currentValue() async throws -> Bool { false }
}

struct ToggleCleaningModeIntent: SetValueIntent {
    static var title: LocalizedStringResource = "掃除モード切替"
    @Parameter(title: "ON/OFF")
    var value: Bool
    func perform() async throws -> some IntentResult { .result() }
}
