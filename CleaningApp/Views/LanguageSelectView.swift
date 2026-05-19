import SwiftUI

// MARK: - 初回起動時の言語選択画面

struct LanguageSelectView: View {
    @State private var localization = LocalizationManager.shared
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.20, blue: 0.55),
                    Color(red: 0.11, green: 0.31, blue: 0.87)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // アプリアイコン・タイトル
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white)

                    Text("Pikari")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)

                    Text("ようこそ / Welcome")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // 言語選択
                VStack(spacing: 12) {
                    Text("言語を選択してください\nPlease select your language")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                localization.language = lang
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onComplete()
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Text(lang.flag)
                                    .font(.title2)
                                Text(lang.displayName)
                                    .font(.title3).fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.white.opacity(0.6))
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)
                            .background(.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // フッター
                Text("後からマイページで変更できます\nYou can change this later in My Page")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)
            }
        }
    }
}
