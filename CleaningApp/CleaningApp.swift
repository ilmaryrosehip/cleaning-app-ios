import SwiftUI
import SwiftData

@main
struct CleaningApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashView {
                        withAnimation(.easeIn(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeIn(duration: 0.3), value: showSplash)
        }
        .modelContainer(ModelContainer.cleaningApp)
    }
}
