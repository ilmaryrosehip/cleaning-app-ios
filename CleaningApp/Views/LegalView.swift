import SwiftUI

// MARK: - LegalType

enum LegalType {
    case privacyPolicy
    case termsOfService

    func title(language: AppLanguage) -> String {
        switch (self, language) {
        case (.privacyPolicy, .japanese):   return "プライバシーポリシー"
        case (.privacyPolicy, .english):    return "Privacy Policy"
        case (.termsOfService, .japanese):  return "利用規約"
        case (.termsOfService, .english):   return "Terms of Service"
        }
    }
}

// MARK: - LegalView

struct LegalView: View {
    let type: LegalType
    @Environment(\.dismiss) private var dismiss
    @State private var localization = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if localization.language == .japanese {
                        switch type {
                        case .privacyPolicy:  privacyPolicyJA
                        case .termsOfService: termsOfServiceJA
                        }
                    } else {
                        switch type {
                        case .privacyPolicy:  privacyPolicyEN
                        case .termsOfService: termsOfServiceEN
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(type.title(language: localization.language))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L(.close)) { dismiss() }
                }
            }
        }
    }

    // MARK: - 共通ヘルパー

    private func sectionView(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 20)
    }

    private func headerView(date: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(date).font(.caption).foregroundStyle(.secondary)
            Divider()
        }
        .padding(.bottom, 16)
    }

    // MARK: - プライバシーポリシー（日本語）

    private var privacyPolicyJA: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView(date: "最終更新日：2026年5月20日")
            sectionView(title: "1. はじめに",
                body: "Pikari（以下「本アプリ」）は、ユーザーのプライバシーを尊重し、個人情報の保護に努めます。本プライバシーポリシーは、本アプリが収集する情報とその利用方法について説明します。")
            sectionView(title: "2. 収集する情報",
                body: "本アプリは以下の情報を収集します：\n\n• デバイス上に保存されるデータ：掃除タスク、設備情報、用品情報、完了履歴、写真など\n• iCloud同期を有効にした場合：上記データがAppleのiCloudサービスに保存されます\n\n本アプリは、個人を特定できる情報（氏名、メールアドレス、位置情報など）を独自に収集・送信することはありません。")
            sectionView(title: "3. 情報の利用目的",
                body: "収集した情報は以下の目的にのみ使用されます：\n\n• アプリ機能の提供（タスク管理、履歴表示、統計等）\n• iCloud経由でのデバイス間データ同期\n• アプリの改善")
            sectionView(title: "4. 第三者への提供",
                body: "本アプリは、ユーザーの個人情報を第三者に販売・提供・開示することはありません。ただし、法令に基づく開示要請があった場合はこの限りではありません。")
            sectionView(title: "5. データの保管",
                body: "データはお使いのデバイス内、またはAppleのiCloudサービスに保管されます。iCloudの取り扱いについては、Appleのプライバシーポリシーをご参照ください。")
            sectionView(title: "6. 広告・分析",
                body: "本アプリは現在、広告サービスや外部分析ツールを使用していません。")
            sectionView(title: "7. 子どものプライバシー",
                body: "本アプリは13歳未満の子どもを対象としておらず、意図的に13歳未満の子どもから個人情報を収集することはありません。")
            sectionView(title: "8. ポリシーの変更",
                body: "本プライバシーポリシーは予告なく変更される場合があります。変更後はアプリのアップデートを通じてお知らせします。")
            sectionView(title: "9. お問い合わせ",
                body: "本プライバシーポリシーに関するご質問は、マイページ→フィードバックを送るよりお問い合わせください。")
        }
    }

    // MARK: - プライバシーポリシー（English）

    private var privacyPolicyEN: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView(date: "Last updated: May 20, 2026")
            sectionView(title: "1. Introduction",
                body: "Pikari (the \"App\") respects your privacy and is committed to protecting your personal information. This Privacy Policy explains what information the App collects and how it is used.")
            sectionView(title: "2. Information We Collect",
                body: "The App collects the following information:\n\n• Data stored on your device: cleaning tasks, fixture information, supply information, completion history, photos, etc.\n• If iCloud Sync is enabled: the above data is stored in Apple's iCloud service.\n\nThe App does not independently collect or transmit personally identifiable information such as your name, email address, or location.")
            sectionView(title: "3. Use of Information",
                body: "Collected information is used only for the following purposes:\n\n• Providing app features (task management, history, statistics, etc.)\n• Syncing data between devices via iCloud\n• Improving the App")
            sectionView(title: "4. Sharing of Information",
                body: "The App does not sell, provide, or disclose your personal information to third parties, except as required by law.")
            sectionView(title: "5. Data Storage",
                body: "Data is stored on your device or in Apple's iCloud service. For information about iCloud's handling of data, please refer to Apple's Privacy Policy.")
            sectionView(title: "6. Advertising & Analytics",
                body: "The App currently does not use any advertising services or third-party analytics tools.")
            sectionView(title: "7. Children's Privacy",
                body: "The App is not directed at children under 13 and does not knowingly collect personal information from children under 13.")
            sectionView(title: "8. Changes to This Policy",
                body: "This Privacy Policy may be updated without prior notice. You will be notified of changes through app updates.")
            sectionView(title: "9. Contact Us",
                body: "For questions about this Privacy Policy, please contact us via My Page → Send Feedback.")
        }
    }

    // MARK: - 利用規約（日本語）

    private var termsOfServiceJA: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView(date: "最終更新日：2026年5月20日")
            sectionView(title: "1. 同意",
                body: "本アプリをダウンロード・使用することにより、本利用規約に同意したものとみなします。同意いただけない場合は、本アプリの使用を中止してください。")
            sectionView(title: "2. 使用許可",
                body: "本アプリの使用は個人・非商業的な目的に限られます。本アプリを無断で複製、変更、配布することは禁止されています。")
            sectionView(title: "3. アプリ内課金",
                body: "本アプリは買い切り型のプレミアムプランを提供しています。一度購入されると、追加費用なしですべてのプレミアム機能をご利用いただけます。購入はAppleのApp Storeを通じて処理されます。")
            sectionView(title: "4. データの責任",
                body: "ユーザーが本アプリに入力・保存するデータの管理はユーザー自身の責任となります。データのバックアップを定期的に行うことを推奨します。")
            sectionView(title: "5. 免責事項",
                body: "本アプリは「現状のまま」提供されます。アプリの使用により生じた損害について、開発者は一切の責任を負いません。")
            sectionView(title: "6. サービスの変更・終了",
                body: "開発者は予告なく本アプリの機能変更・サービス終了を行う場合があります。")
            sectionView(title: "7. 知的財産",
                body: "本アプリのデザイン、ロゴ、コンテンツに関するすべての知的財産権は開発者に帰属します。")
            sectionView(title: "8. 準拠法",
                body: "本利用規約は日本法に準拠します。")
            sectionView(title: "9. お問い合わせ",
                body: "本利用規約に関するご質問は、マイページ→フィードバックを送るよりお問い合わせください。")
        }
    }

    // MARK: - 利用規約（English）

    private var termsOfServiceEN: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView(date: "Last updated: May 20, 2026")
            sectionView(title: "1. Agreement",
                body: "By downloading or using the App, you agree to these Terms of Service. If you do not agree, please stop using the App.")
            sectionView(title: "2. License",
                body: "Use of the App is limited to personal, non-commercial purposes. Unauthorized copying, modification, or distribution of the App is prohibited.")
            sectionView(title: "3. In-App Purchases",
                body: "The App offers a one-time purchase premium plan. Once purchased, you can use all premium features without any additional charges. Purchases are processed through Apple's App Store.")
            sectionView(title: "4. Data Responsibility",
                body: "Users are responsible for managing the data they enter and store in the App. We recommend regularly backing up your data.")
            sectionView(title: "5. Disclaimer",
                body: "The App is provided \"as is.\" The developer is not liable for any damages arising from the use of the App, including loss of data.")
            sectionView(title: "6. Changes & Termination",
                body: "The developer may modify or terminate App features or services without prior notice.")
            sectionView(title: "7. Intellectual Property",
                body: "All intellectual property rights in the App's design, logo, and content belong to the developer.")
            sectionView(title: "8. Governing Law",
                body: "These Terms are governed by the laws of Japan.")
            sectionView(title: "9. Contact Us",
                body: "For questions about these Terms, please contact us via My Page → Send Feedback.")
        }
    }
}
