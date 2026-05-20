import SwiftUI
import SwiftData
import Charts

// MARK: - ReportView（掃除レポート・統計グラフ）

struct ReportView: View {
    let home: Home
    @State private var selectedPeriod: ReportPeriod = .month

    enum ReportPeriod: String, CaseIterable {
        case week  = "今週"
        case month = "今月"
        case year  = "今年"

        var label: String {
            switch self {
            case .week:  return L10nKey.thisWeek.ja
            case .month: return L10nKey.thisMonth.ja
            case .year:  return L10nKey.thisYear.ja
            }
        }
        var startDate: Date {
            let cal = Calendar.current
            switch self {
            case .week:  return cal.date(byAdding: .day,   value: -7,  to: .now)!
            case .month: return cal.date(byAdding: .month, value: -1,  to: .now)!
            case .year:  return cal.date(byAdding: .year,  value: -1,  to: .now)!
            }
        }
    }

    private var allTasks: [CleaningTask] { home.rooms.flatMap { $0.tasks } }

    private var logs: [TaskLog] {
        allTasks.flatMap { $0.logs }
            .filter { $0.completedAt >= selectedPeriod.startDate }
            .sorted { $0.completedAt < $1.completedAt }
    }

    private var totalMinutes: Int { logs.reduce(0) { $0 + $1.durationMinutes } }
    private var totalCount: Int { logs.count }

    // 日別完了数
    private var dailyData: [(date: Date, count: Int)] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: logs) {
            cal.startOfDay(for: $0.completedAt)
        }
        return grouped.map { (date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    // 部屋別完了数
    private var roomData: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: logs) { $0.task?.room?.name ?? (LocalizationManager.shared.language == .japanese ? "不明" : "Unknown") }
        return grouped.map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    // 曜日別完了数
    private var weekdayData: [(label: String, count: Int)] {
        let labels = LocalizationManager.shared.language == .japanese ? ["日", "月", "火", "水", "木", "金", "土"] : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var counts = Array(repeating: 0, count: 7)
        for log in logs {
            let wd = Calendar.current.component(.weekday, from: log.completedAt) - 1
            counts[wd] += 1
        }
        return labels.enumerated().map { (label: $0.element, count: counts[$0.offset]) }
    }

    // タスク別完了ランキング
    private var taskRankData: [(title: String, count: Int)] {
        let grouped = Dictionary(grouping: logs) { $0.task?.title ?? (LocalizationManager.shared.language == .japanese ? "不明" : "Unknown") }
        return grouped.map { (title: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択
                    Picker(LocalizationManager.shared.language == .japanese ? "期間" : "Period", selection: $selectedPeriod) {
                        ForEach(ReportPeriod.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // サマリーカード
                    summarySection

                    // 日別完了グラフ
                    if !dailyData.isEmpty {
                        dailyChartSection
                    }

                    // 曜日別グラフ
                    weekdayChartSection

                    // 部屋別グラフ
                    if !roomData.isEmpty {
                        roomChartSection
                    }

                    // タスク別ランキング
                    if !taskRankData.isEmpty {
                        taskRankSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(L(.report))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - サマリー

    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ReportMetricCard(
                    icon: "checkmark.circle.fill",
                    label: L(.completedTasks),
                    value: LocalizationManager.shared.language == .japanese ? "\(totalCount)件" : "\(totalCount) tasks",
                    color: .teal
                )
                ReportMetricCard(
                    icon: "clock.fill",
                    label: L(.totalTime),
                    value: totalMinutes >= 60
                        ? (LocalizationManager.shared.language == .japanese ? "\(totalMinutes / 60)時間\(totalMinutes % 60)分" : "\(totalMinutes / 60)h \(totalMinutes % 60)m")
                        : (LocalizationManager.shared.language == .japanese ? "\(totalMinutes)分" : "\(totalMinutes) min"),
                    color: .blue
                )
            }
            HStack(spacing: 12) {
                ReportMetricCard(
                    icon: "house.fill",
                    label: L(.roomsCleaned),
                    value: LocalizationManager.shared.language == .japanese ? "\(Set(logs.compactMap { $0.task?.room?.name }).count)部屋" : "\(Set(logs.compactMap { $0.task?.room?.name }).count) rooms",
                    color: .orange
                )
                ReportMetricCard(
                    icon: "timer",
                    label: L(.avgTime),
                    value: totalCount > 0 ? (LocalizationManager.shared.language == .japanese ? "\(totalMinutes / totalCount)分" : "\(totalMinutes / totalCount) min") : "-",
                    color: .purple
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 日別グラフ

    private var dailyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L(.dailyChart))
                .font(.headline)
                .padding(.horizontal)

            Chart(dailyData, id: \.date) { item in
                BarMark(
                    x: .value(LocalizationManager.shared.language == .japanese ? "日付" : "Date", item.date, unit: .day),
                    y: .value(LocalizationManager.shared.language == .japanese ? "件数" : "Count", item.count)
                )
                .foregroundStyle(Color.teal.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month(.twoDigits).day(.twoDigits))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 160)
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - 曜日別グラフ

    private var weekdayChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L(.weekdayChart))
                .font(.headline)
                .padding(.horizontal)

            Chart(weekdayData, id: \.label) { item in
                BarMark(
                    x: .value(LocalizationManager.shared.language == .japanese ? "曜日" : "Day", item.label),
                    y: .value("件数", item.count)
                )
                .foregroundStyle(
                    item.label == (LocalizationManager.shared.language == .japanese ? "日" : "Sun") ? Color.red.gradient :
                    item.label == (LocalizationManager.shared.language == .japanese ? "土" : "Sat") ? Color.blue.gradient :
                    Color.teal.gradient
                )
                .cornerRadius(4)
            }
            .frame(height: 140)
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - 部屋別グラフ

    private var roomChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L(.roomChart))
                .font(.headline)
                .padding(.horizontal)

            Chart(roomData, id: \.name) { item in
                SectorMark(
                    angle: .value(LocalizationManager.shared.language == .japanese ? "件数" : "Count", item.count),
                    innerRadius: .ratio(0.55),
                    angularInset: 2
                )
                .foregroundStyle(by: .value(L(.room), item.name))
                .cornerRadius(4)
            }
            .frame(height: 200)
            .padding(.horizontal)

            // 凡例
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(roomData.prefix(5).enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(roomColor(index: index))
                            .frame(width: 12, height: 12)
                        Text(item.name).font(.caption)
                        Spacer()
                        Text(LocalizationManager.shared.language == .japanese ? "\(item.count)件" : "\(item.count)").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - タスクランキング

    private var taskRankSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L(.taskRanking))
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(Array(taskRankData.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        // 順位バッジ
                        ZStack {
                            Circle()
                                .fill(rankColor(index: index))
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.caption).fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        Text(item.title).font(.subheadline).lineLimit(1)
                        Spacer()
                        Text("\(item.count)回")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(.teal)
                    }

                    // プログレスバー
                    if let max = taskRankData.first?.count, max > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.teal)
                                    .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(max), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func roomColor(index: Int) -> Color {
        let colors: [Color] = [.teal, .blue, .orange, .purple, .green]
        return colors[index % colors.count]
    }

    private func rankColor(index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return Color(.systemGray)
        case 2: return .orange
        default: return .teal
        }
    }
}

// MARK: - ReportMetricCard

struct ReportMetricCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3).fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
