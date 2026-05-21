import SwiftUI
import SwiftData

@main
struct CleaningApp: App {
    @State private var showSplash = true
    @State private var showLanguageSelect = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showSplash || showLanguageSelect ? 0 : 1)

                if showLanguageSelect {
                    LanguageSelectView {
                        withAnimation(.easeIn(duration: 0.4)) {
                            showLanguageSelect = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }

                if showSplash {
                    SplashView {
                        withAnimation(.easeIn(duration: 0.3)) {
                            showSplash = false
                        }
                        // 初回起動時のみ言語選択を表示
                        let hasSelectedLanguage = UserDefaults.standard.bool(forKey: "has_selected_language")
                        if !hasSelectedLanguage {
                            UserDefaults.standard.set(true, forKey: "has_selected_language")
                            showLanguageSelect = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeIn(duration: 0.3), value: showSplash)
            .animation(.easeIn(duration: 0.4), value: showLanguageSelect)
            .task {
                #if !DEBUG
                await PremiumManager.shared.initialize()
                #endif
            }
        }
        .modelContainer(ModelContainer.cleaningApp)
    }
}
