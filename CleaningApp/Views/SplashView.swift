import SwiftUI

struct SplashView: View {
    @State private var houseScale: CGFloat = 0.6
    @State private var houseOpacity: Double = 0
    @State private var sparkleOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var bgOpacity: Double = 0
    @State private var iconOffsets: [CGSize] = Array(repeating: .zero, count: 6)
    @State private var iconOpacities: [Double] = Array(repeating: 0, count: 6)

    let onFinished: () -> Void

    // 周囲に浮かぶアイコン
    private let floatingIcons: [(symbol: String, color: Color, angle: Double, radius: CGFloat)] = [
        ("bubbles.and.sparkles",  .teal,   -30,  110),
        ("sparkles",              .orange,  30,  120),
        ("leaf.fill",             .green,   80,  100),
        ("moon.stars.fill",       .indigo, -80,  105),
        ("sun.max.fill",          .yellow,  150, 115),
        ("cloud.fill",            .cyan,   -150, 108),
    ]

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.18, blue: 0.22),
                    Color(red: 0.07, green: 0.28, blue: 0.32),
                    Color(red: 0.10, green: 0.35, blue: 0.38),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(bgOpacity)

            // 背景の光彩
            Circle()
                .fill(Color.teal.opacity(0.15))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -60, y: -80)
                .opacity(bgOpacity)

            Circle()
                .fill(Color.cyan.opacity(0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: 80, y: 120)
                .opacity(bgOpacity)

            VStack(spacing: 0) {
                Spacer()

                // メインアイコンエリア
                ZStack {
                    // 外側のリング
                    Circle()
                        .stroke(Color.teal.opacity(0.2), lineWidth: 1)
                        .frame(width: 200, height: 200)
                        .scaleEffect(houseScale)
                        .opacity(sparkleOpacity)

                    Circle()
                        .stroke(Color.teal.opacity(0.1), lineWidth: 1)
                        .frame(width: 240, height: 240)
                        .scaleEffect(houseScale)
                        .opacity(sparkleOpacity * 0.6)

                    // 周囲の浮遊アイコン
                    ForEach(0..<floatingIcons.count, id: \.self) { i in
                        let info = floatingIcons[i]
                        let rad = info.angle * Double.pi / 180
                        let x = info.radius * CGFloat(cos(rad))
                        let y = info.radius * CGFloat(sin(rad))

                        Image(systemName: info.symbol)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(info.color.opacity(0.7))
                            .offset(x: x + iconOffsets[i].width,
                                    y: y + iconOffsets[i].height)
                            .opacity(iconOpacities[i])
                    }

                    // メインの家アイコン
                    ZStack {
                        // グロー効果
                        Image(systemName: "house.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.teal.opacity(0.3))
                            .blur(radius: 20)

                        // メインアイコン
                        Image(systemName: "house.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.teal.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .scaleEffect(houseScale)
                    .opacity(houseOpacity)
                }
                .frame(width: 280, height: 280)

                Spacer().frame(height: 48)

                // タイトル
                VStack(spacing: 8) {
                    Text("おうちのお掃除")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(titleOpacity)

                    Text("タスクを管理して、いつも清潔な住まいを")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .opacity(subtitleOpacity)
                }

                Spacer()

                // ローディングドット
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.teal.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .opacity(subtitleOpacity)
                            .animation(
                                .easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(i) * 0.15),
                                value: subtitleOpacity
                            )
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // 背景フェードイン
        withAnimation(.easeIn(duration: 0.4)) {
            bgOpacity = 1
        }

        // 家アイコン登場
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            houseScale = 1.0
            houseOpacity = 1
        }

        // スパークル
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            sparkleOpacity = 1
        }

        // 周囲アイコンを順番に表示
        for i in 0..<floatingIcons.count {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4 + Double(i) * 0.08)) {
                iconOpacities[i] = 1
            }
        }

        // タイトル
        withAnimation(.easeIn(duration: 0.5).delay(0.7)) {
            titleOpacity = 1
        }

        // サブタイトル
        withAnimation(.easeIn(duration: 0.5).delay(0.9)) {
            subtitleOpacity = 1
        }

        // 2.2秒後に完了
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                houseOpacity = 0
                sparkleOpacity = 0
                bgOpacity = 0
                titleOpacity = 0
                subtitleOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onFinished()
            }
        }
    }
}
