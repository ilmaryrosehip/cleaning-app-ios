import SwiftUI
import SwiftData
import StoreKit

// MARK: - MyPageView

struct MyPageView: View {
    let home: Home
    @State private var localization = LocalizationManager.shared
    @State private var premium = PremiumManager.shared
    @State private var showHelp = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showResetAlert = false
    @State private var notificationsEnabled = true
    @State private var notificationHour = 9
    @State private var iCloudEnabled = true
    @State private var selectedTheme: AppTheme = .teal

    // 統計
    private var totalCompleted: Int {
        home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }.count
    }
    private var totalMinutes: Int {
        home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }
            .reduce(0) { $0 + $1.durationMinutes }
    }
    private var streakDays: Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: .now)
        let allLogs = home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }
        while true {
            let hasLog = allLogs.contains { cal.isDate($0.completedAt, inSameDayAs: checkDate) }
            if hasLog { streak += 1 } else { break }
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }
    private var monthlyRate: Int {
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: .now))!
        let activeTasks = home.rooms.flatMap { $0.tasks }.filter { $0.isActive }
        let completedThisMonth = activeTasks.flatMap { $0.logs }
            .filter { $0.completedAt >= monthStart }.count
        guard !activeTasks.isEmpty else { return 0 }
        return min(100, completedThisMonth * 100 / max(1, activeTasks.count))
    }

    var body: some View {
        NavigationStack {
            List {
                statisticsSection
                familySharingSection
                premiumSection
                notificationSection
                customizeSection
                dataSection
                languageSection
                supportSection
                appInfoSection
            }
            .navigationTitle(L(.myPage))
            .sheet(isPresented: $showHelp)             { HelpView() }
            .sheet(isPresented: $showPrivacyPolicy)    { LegalView(type: .privacyPolicy) }
            .sheet(isPresented: $showTermsOfService)   { LegalView(type: .termsOfService) }
            .alert(L(.resetData), isPresented: $showResetAlert) {
                Button(L(.cancel), role: .cancel) {}
                Button(L(.delete), role: .destructive) {}
            } message: {
                Text(localization.language == .japanese
                     ? LocalizationManager.shared.language == .japanese ? "All data will be deleted. This cannot be undone." : "All data will be deleted. This cannot be undone."
                     : "All data will be deleted. This action cannot be undone.")
            }
        }
    }

    // MARK: - 統計

    private var statisticsSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(icon: "checkmark.circle.fill", label: L(.totalCompleted),
                         value: "\(totalCompleted)",
                         unit: localization.language == .japanese ? "件" : "tasks", color: .teal)
                StatCard(icon: "clock.fill", label: L(.totalMinutes),
                         value: totalMinutes >= 60 ? "\(totalMinutes / 60)" : "\(totalMinutes)",
                         unit: totalMinutes >= 60
                            ? (localization.language == .japanese ? "時間" : "hrs")
                            : (localization.language == .japanese ? "分" : "min"),
                         color: .blue)
                StatCard(icon: "flame.fill", label: L(.streakDays),
                         value: "\(streakDays)",
                         unit: localization.language == .japanese ? "日" : "days", color: .orange)
                StatCard(icon: "chart.line.uptrend.xyaxis", label: L(.monthlyRate),
                         value: "\(monthlyRate)", unit: "%", color: .green)
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)
        } header: {
            Label(L(.statistics), systemImage: "chart.bar.fill")
        }
    }

    // MARK: - 家族共有

    private var familySharingSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "person.2.fill").foregroundStyle(.teal).font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.language == .japanese
                         ? LocalizationManager.shared.language == .japanese ? "家族や同居人と掃除を共有できます" : "Share cleaning tasks with family members"
                         : "Share cleaning tasks with family members")
                        .font(.subheadline)
                    Text(localization.language == .japanese
                         ? LocalizationManager.shared.language == .japanese ? "iCloud同期を有効にして招待してください" : "Enable iCloud sync and invite members"
                         : "Enable iCloud sync and send an invite")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            Button {
            } label: {
                Label(L(.inviteMember), systemImage: "person.badge.plus").foregroundStyle(.teal)
            }
        } header: {
            Label(L(.familySharing), systemImage: "person.2.fill")
        }
    }

    // MARK: - プレミアム

    private var premiumSection: some View {
        Section {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(premium.isPremium
                              ? LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                              : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: premium.isPremium ? "crown.fill" : "lock.fill")
                        .foregroundStyle(.white).font(.subheadline)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(premium.isPremium ? L(.premiumPlan) : L(.freePlan))
                        .font(.subheadline).fontWeight(.semibold)
                    Text(premium.isPremium
                         ? (localization.language == .japanese ? "すべての機能が利用可能です" : "All features unlocked")
                         : (localization.language == .japanese ? "プレミアムにアップグレードして全機能を解鎖" : "Upgrade to unlock all features"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            if !premium.isPremium {
                Button {
                    Task { _ = await premium.purchase() }
                } label: {
                    HStack {
                        Spacer()
                        Text(L(.buyNow)).fontWeight(.semibold).foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .background(LinearGradient(
                        colors: [Color(red:0.11,green:0.31,blue:0.87), Color(red:0.37,green:0.51,blue:0.95)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)

                Button(L(.restore)) { Task { await premium.restore() } }
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        } header: {
            Label(L(.premium), systemImage: "crown.fill")
        }
    }

    // MARK: - 通知設定

    private var notificationSection: some View {
        Section {
            Toggle(L(.notifyOnOff), isOn: $notificationsEnabled).tint(.teal)
            if notificationsEnabled {
                Picker(L(.notifyTime), selection: $notificationHour) {
                    ForEach(6..<23) { hour in Text("\(hour):00").tag(hour) }
                }
            }
        } header: {
            Label(L(.notificationSettings), systemImage: "bell.fill")
        }
    }

    // MARK: - カスタマイズ

    private var customizeSection: some View {
        Section {
            HStack {
                Text(L(.colorTheme))
                Spacer()
                HStack(spacing: 8) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Circle().fill(theme.color).frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color.white, lineWidth: selectedTheme == theme ? 2 : 0))
                            .shadow(color: selectedTheme == theme ? theme.color.opacity(0.5) : .clear, radius: 4)
                            .onTapGesture { selectedTheme = theme }
                    }
                }
            }
        } header: {
            Label(L(.customize), systemImage: "paintbrush.fill")
        }
    }

    // MARK: - データ管理

    private var dataSection: some View {
        Section {
            Toggle(L(.icloudSync), isOn: $iCloudEnabled).tint(.teal)
            Button { showResetAlert = true } label: {
                Label(L(.resetData), systemImage: "trash.fill").foregroundStyle(.red)
            }
        } header: {
            Label(L(.dataManagement), systemImage: "externaldrive.fill")
        }
    }

    // MARK: - 言語設定

    private var languageSection: some View {
        Section {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    withAnimation { localization.language = lang }
                } label: {
                    HStack {
                        Text(lang.flag)
                        Text(lang.displayName).foregroundStyle(.primary)
                        Spacer()
                        if localization.language == lang {
                            Image(systemName: "checkmark").foregroundStyle(.teal).fontWeight(.semibold)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Label(L(.languageSettings), systemImage: "globe")
        }
    }

    // MARK: - サポート

    private var supportSection: some View {
        Section {
            Button { showHelp = true } label: {
                Label(L(.howToUse), systemImage: "book.fill").foregroundStyle(.primary)
            }
            Link(destination: URL(string: "mailto:ilmary.rosehip@gmail.com")!) {
                Label(L(.sendFeedback), systemImage: "envelope.fill")
            }
            Button {
                if let url = URL(string: "itms-apps://itunes.apple.com/app/id0000000000?action=write-review") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(L(.writeReview), systemImage: "star.fill").foregroundStyle(.primary)
            }
            // アプリ内遺移に変更
            Button { showPrivacyPolicy = true } label: {
                Label(L(.privacyPolicy), systemImage: "lock.shield.fill").foregroundStyle(.primary)
            }
            Button { showTermsOfService = true } label: {
                Label(L(.termsOfService), systemImage: "doc.text.fill").foregroundStyle(.primary)
            }
        } header: {
            Label(L(.support), systemImage: "questionmark.circle.fill")
        }
    }

    // MARK: - アプリ情報

    private var appInfoSection: some View {
        Section {
            LabeledContent(L(.version)) {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label(L(.appInfo), systemImage: "info.circle.fill")
        }
    }
}

// MARK: - StatCard

struct StatCard: View {
    let icon: String; let label: String; let value: String; let unit: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Image(systemName: icon).foregroundStyle(color).font(.subheadline); Spacer() }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.title2).fontWeight(.bold).foregroundStyle(color)
                Text(unit).font(.caption).foregroundStyle(color.opacity(0.8))
            }
            Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - AppTheme

enum AppTheme: CaseIterable {
    case teal, blue, purple, orange, green
    var color: Color {
        switch self {
        case .teal: return .teal; case .blue: return .blue
        case .purple: return .purple; case .orange: return .orange; case .green: return .green
        }
    }
}

// MARK: - HelpView

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var localization = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            List {
                HelpSection(
                    title: L(.howToSetup), icon: "house.fill", color: .teal,
                    steps: [
                        ("1", L(.setupHome), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "アプリを初めて起動すると家の名前を入力する画面が表示されます。" : "When you first launch the app, you'll be asked to name your home."
                            : "When you first launch the app, you'll be asked to name your home. Enter a name like 'My Home'."),
                        ("2", L(.setupRoom), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "「間取り」タブから部屋を追加できます。リビング、キッチンなどを登録しましょう。" : "Add rooms from the Floor Plan tab. Register rooms like living room, kitchen, bathroom."
                            : LocalizationManager.shared.language == .japanese ? "「間取り」タブから部屋を追加できます。リビング、キッチンなどを登録しましょう。" : "Add rooms from the Floor Plan tab. Register rooms like living room, kitchen, bathroom."),
                        ("3", L(.setupTask), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "ホームタブの「＋」ボタンからタスクを追加します。頻度も設定できます。" : "Add tasks using the '+' button on the Home tab. Set frequency (daily, weekly, monthly)."
                            : LocalizationManager.shared.language == .japanese ? "ホームタブの「＋」ボタンからタスクを追加します。頻度も設定できます。" : "Add tasks using the '+' button on the Home tab. Set frequency (daily, weekly, monthly)."),
                    ]
                )
                HelpSection(
                    title: L(.howToDaily), icon: "checkmark.circle.fill", color: .green,
                    steps: [
                        ("1", L(.dailyComplete), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "ホームタブでタスクをタップし、「完了」ボタンを押します。所要時間やメモも記録できます。" : "Tap a task on the Home tab and press Complete. You can also record duration and notes."
                            : LocalizationManager.shared.language == .japanese ? "ホームタブでタスクをタップし、「完了」ボタンを押します。所要時間やメモも記録できます。" : "Tap a task on the Home tab and press Complete. You can also record duration and notes."),
                        ("2", L(.dailyPhoto), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "「履歴」タブから完了記録を開き、「写真を追加する」で写真を記録できます。" : "Open a completion record in History, then tap 'Add Photos' to capture before/after photos."
                            : LocalizationManager.shared.language == .japanese ? "「履歴」タブから完了記録を開き、「写真を追加する」で写真を記録できます。" : "Open a completion record in History, then tap 'Add Photos' to capture before/after photos."),
                        ("3", L(.dailyWidget), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "ホーム画面を長押しして「＋」からPikariウィジェットを追加すると、今日のタスクが一目でわかります。" : "Long-press your home screen, tap '+', and add a Pikari widget to see today's tasks."
                            : LocalizationManager.shared.language == .japanese ? "ホーム画面を長押しして「＋」からPikariウィジェットを追加すると、今日のタスクが一目でわかります。" : "Long-press your home screen, tap '+', and add a Pikari widget to see today's tasks."),
                    ]
                )
                HelpSection(
                    title: L(.howToFixture), icon: "wrench.and.screwdriver.fill", color: .orange,
                    steps: [
                        ("1", L(.fixtureRegister), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "「間取り」タブで部屋を選択し、「設備・器具」タブから設備を追加します。" : "Select a room in the Floor Plan tab, then add fixtures from the Fixtures tab."
                            : LocalizationManager.shared.language == .japanese ? "「間取り」タブで部屋を選択し、「設備・器具」タブから設備を追加します。" : "Select a room in the Floor Plan tab, then add fixtures from the Fixtures tab."),
                        ("2", L(.fixturePartAdd), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "設備を選択してパーツを追加します。交換周期を設定すると通知します。" : "Select a fixture and add parts. Set replacement intervals to receive reminders."
                            : LocalizationManager.shared.language == .japanese ? "設備を選択してパーツを追加します。交換周期を設定すると通知します。" : "Select a fixture and add parts. Set replacement intervals to receive reminders."),
                        ("3", L(.fixtureStockRefill), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "「消耗品在庫」タブで在庫を管理します。在庫が少なくなるとウィジェットにアラートが表示されます。" : "Manage stock in the Parts Inventory tab. Low stock alerts will appear in your widget."
                            : LocalizationManager.shared.language == .japanese ? "「消耗品在庫」タブで在庫を管理します。在庫が少なくなるとウィジェットにアラートが表示されます。" : "Manage stock in the Parts Inventory tab. Low stock alerts will appear in your widget."),
                    ]
                )
                HelpSection(
                    title: L(.howToReport), icon: "chart.bar.fill", color: .blue,
                    steps: [
                        ("1", L(.tabReport), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "「レポート」タブで掃除の統計を確認できます。今週・今月・今年の期間で切り替えられます。（プレミアム）" : "View cleaning statistics in the Report tab. Switch between week, month, and year. (Premium)"
                            : "View stats in the Report tab. Switch between this week, month, and year. (Premium)"),
                        ("2", L(.tabCalendar), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "「カレンダー」タブで月間カレンダーにタスクを表示します。（プレミアム）" : "The Calendar tab shows tasks on a monthly calendar. (Premium)"
                            : LocalizationManager.shared.language == .japanese ? "「カレンダー」タブで月間カレンダーにタスクを表示します。（プレミアム）" : "The Calendar tab shows tasks on a monthly calendar. (Premium)"),
                    ]
                )
                HelpSection(
                    title: L(.howToExport), icon: "square.and.arrow.up.fill", color: .purple,
                    steps: [
                        ("1", L(.export), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "「履歴」タブ右上のエクスポートボタンをタップします。（プレミアム）" : "Tap the export button in the top right of the History tab. (Premium)"
                            : LocalizationManager.shared.language == .japanese ? "「履歴」タブ右上のエクスポートボタンをタップします。（プレミアム）" : "Tap the export button in the top right of the History tab. (Premium)"),
                        ("2", L(.exportData), localization.language == .japanese
                            ? LocalizationManager.shared.language == .japanese ? "データの種類とファイル形式（CSV/PDF）を選択します。" : "Select the data type and file format (CSV/PDF)."
                            : LocalizationManager.shared.language == .japanese ? "データの種類とファイル形式（CSV/PDF）を選択します。" : "Select the data type and file format (CSV/PDF)."),
                    ]
                )
            }
            .navigationTitle(L(.howToUse))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(L(.close)) { dismiss() } }
            }
        }
    }
}

// MARK: - HelpSection

struct HelpSection: View {
    let title: String; let icon: String; let color: Color
    let steps: [(String, String, String)]
    var body: some View {
        Section {
            ForEach(steps.indices, id: \.self) { i in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(color.opacity(0.15)).frame(width: 28, height: 28)
                            Text(steps[i].0).font(.caption).fontWeight(.bold).foregroundStyle(color)
                        }
                        Text(steps[i].1).font(.subheadline).fontWeight(.semibold)
                    }
                    Text(steps[i].2).font(.caption).foregroundStyle(.secondary).padding(.leading, 36)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Label(title, systemImage: icon).foregroundStyle(color)
        }
    }
}
