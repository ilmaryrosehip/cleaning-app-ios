import SwiftUI
import SwiftData

@main
struct CleaningApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ModelContainer.cleaningApp)
    }
}
