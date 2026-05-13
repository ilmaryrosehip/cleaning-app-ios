import AppIntents
import SwiftUI
import WidgetKit

// MARK: - 共通カラー
private extension Color {
    static let pikariBlue = Color(red: 0.11, green: 0.31, blue: 0.87)
    static let pikariDark = Color(red: 0.07, green: 0.20, blue: 0.55)
}

// MARK: - 共通タイムライン生成
private func makeTimeline<E: TimelineEntry>(entry: E) -> Timeline<E> {
    let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
    return Timeline(entries: [entry], policy: .after(next))
}

// ===========================================================
// MARK: - 1. 今日のタスク ウィジェット（中・大サイズ）
// ===========================================================

struct TodayTasksEntry: TimelineEntry {
    let date: Date
    let data: WidgetSharedData
}

struct TodayTasksProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayTasksEntry {
        TodayTasksEntry(date: .now, data: .empty)
    }
    func getSnapshot(in context: Context, completion: @escaping (TodayTasksEntry) -> Void) {
        completion(TodayTasksEntry(date: .now, data: WidgetDataStore.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayTasksEntry>) -> Void) {
        let entry = TodayTasksEntry(date: .now, data: WidgetDataStore.load())
        completion(makeTimeline(entry: entry))
    }
}

struct TodayTasksWidgetView: View {
    let data: WidgetSharedData
    private var allUrgent: [WidgetTaskEntry] { data.overdueTasks + data.todayTasks }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.pikariDark, .pikariBlue],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "house.fill").font(.caption2).foregroundStyle(.white.opacity(0.8))
                    Text("Pikari").font(.caption2).fontWeight(.semibold).foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text("今日のタスク").font(.caption2).foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 12).padding(.top, 10)
                Divider().background(.white.opacity(0.2)).padding(.horizontal, 12).padding(.vertical, 6)

                if allUrgent.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(.white.opacity(0.7))
                            Text("今日のタスクは\nすべて完了！")
                                .font(.caption).foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(allUrgent.prefix(4))) { task in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(task.isOverdue ? Color.orange : Color.white.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(task.title).font(.caption).fontWeight(.medium)
                                        .foregroundStyle(.white).lineLimit(1)
                                    Text(task.roomName).font(.caption2).foregroundStyle(.white.opacity(0.6))
                                }
                                Spacer()
                                Text(task.nextDueDateText).font(.caption2)
                                    .foregroundStyle(task.isOverdue ? .orange : .white.opacity(0.5))
                            }
                        }
                        if allUrgent.count > 4 {
                            Text("他 \(allUrgent.count - 4) 件").font(.caption2).foregroundStyle(.white.opacity(0.5))
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                Spacer()
                HStack {
                    Text("今週 \(data.weeklyDoneCount)/\(data.weeklyTotalCount) 件")
                        .font(.caption2).foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    if !data.overdueTasks.isEmpty {
                        Label("\(data.overdueTasks.count)件超過", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2).foregroundStyle(Color.orange)
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 8)
            }
        }
    }
}

struct TodayTasksWidget: Widget {
    let kind = "com.hiroki.CleaningApp.todayTasks"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTasksProvider()) { entry in
            TodayTasksWidgetView(data: entry.data).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("今日のタスク")
        .description("期限が迫っているタスクを表示します")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// ===========================================================
// MARK: - 2. 次のタスク ウィジェット（小サイズ）
// ===========================================================

struct NextTaskEntry: TimelineEntry {
    let date: Date
    let task: WidgetTaskEntry?
}

struct NextTaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextTaskEntry { NextTaskEntry(date: .now, task: nil) }
    func getSnapshot(in context: Context, completion: @escaping (NextTaskEntry) -> Void) {
        let data = WidgetDataStore.load()
        completion(NextTaskEntry(date: .now, task: data.upcomingTask ?? data.todayTasks.first))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTaskEntry>) -> Void) {
        let data = WidgetDataStore.load()
        let task = data.overdueTasks.first ?? data.todayTasks.first ?? data.upcomingTask
        completion(makeTimeline(entry: NextTaskEntry(date: .now, task: task)))
    }
}

struct NextTaskWidgetView: View {
    let task: WidgetTaskEntry?
    var body: some View {
        ZStack {
            LinearGradient(colors: [.pikariDark, .pikariBlue],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 4) {
                Image(systemName: "house.fill").font(.caption).foregroundStyle(.white.opacity(0.6))
                if let task {
                    Spacer()
                    Text(task.roomName).font(.caption2).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                    Text(task.title).font(.caption).fontWeight(.semibold).foregroundStyle(.white)
                        .multilineTextAlignment(.center).lineLimit(2)
                    Spacer()
                    Text(task.nextDueDateText).font(.caption2).fontWeight(.medium)
                        .foregroundStyle(task.isOverdue ? .orange : .white.opacity(0.7))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.white.opacity(0.15)).clipShape(Capsule())
                } else {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").font(.title3).foregroundStyle(.white.opacity(0.7))
                    Text("タスクなし").font(.caption2).foregroundStyle(.white.opacity(0.6))
                    Spacer()
                }
            }
            .padding(10)
        }
    }
}

struct NextTaskWidget: Widget {
    let kind = "com.hiroki.CleaningApp.nextTask"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextTaskProvider()) { entry in
            NextTaskWidgetView(task: entry.task).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("次のタスク")
        .description("次に期限が来るタスクを表示します")
        .supportedFamilies([.systemSmall])
    }
}

// ===========================================================
// MARK: - 3. 在庫アラート ウィジェット（中サイズ）
// ===========================================================

struct LowStockEntry: TimelineEntry {
    let date: Date
    let parts: [WidgetPartEntry]
}

struct LowStockProvider: TimelineProvider {
    func placeholder(in context: Context) -> LowStockEntry { LowStockEntry(date: .now, parts: []) }
    func getSnapshot(in context: Context, completion: @escaping (LowStockEntry) -> Void) {
        completion(LowStockEntry(date: .now, parts: WidgetDataStore.load().lowStockParts))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LowStockEntry>) -> Void) {
        completion(makeTimeline(entry: LowStockEntry(date: .now, parts: WidgetDataStore.load().lowStockParts)))
    }
}

struct LowStockWidgetView: View {
    let parts: [WidgetPartEntry]
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red:0.12, green:0.18, blue:0.35), Color(red:0.11, green:0.31, blue:0.60)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "shippingbox.fill").font(.caption2).foregroundStyle(.orange)
                    Text("在庫アラート").font(.caption2).fontWeight(.semibold).foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("Pikari").font(.caption2).foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 12).padding(.top, 10)
                Divider().background(.white.opacity(0.2)).padding(.horizontal, 12).padding(.vertical, 6)

                if parts.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill").font(.title3).foregroundStyle(.white.opacity(0.6))
                            Text("在庫は十分あります").font(.caption).foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(parts.prefix(4))) { part in
                            HStack(spacing: 6) {
                                Circle().fill(part.stockCount == 0 ? Color.red : Color.orange).frame(width: 6, height: 6)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(part.name).font(.caption).fontWeight(.medium).foregroundStyle(.white).lineLimit(1)
                                    Text(part.fixtureName).font(.caption2).foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                Text(part.stockCount == 0 ? "在庫なし" : "残\(part.stockCount)個")
                                    .font(.caption2).fontWeight(.medium)
                                    .foregroundStyle(part.stockCount == 0 ? .red : .orange)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                Spacer()
            }
        }
    }
}

struct LowStockWidget: Widget {
    let kind = "com.hiroki.CleaningApp.lowStock"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LowStockProvider()) { entry in
            LowStockWidgetView(parts: entry.parts).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("在庫アラート")
        .description("消耗品の在庫が少ない部品を表示します")
        .supportedFamilies([.systemMedium])
    }
}

// ===========================================================
// MARK: - 4. 週間達成率 ウィジェット（小サイズ）
// ===========================================================

struct WeeklyProgressEntry: TimelineEntry {
    let date: Date
    let done: Int
    let total: Int
}

struct WeeklyProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyProgressEntry { WeeklyProgressEntry(date: .now, done: 0, total: 0) }
    func getSnapshot(in context: Context, completion: @escaping (WeeklyProgressEntry) -> Void) {
        let d = WidgetDataStore.load()
        completion(WeeklyProgressEntry(date: .now, done: d.weeklyDoneCount, total: d.weeklyTotalCount))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyProgressEntry>) -> Void) {
        let d = WidgetDataStore.load()
        completion(makeTimeline(entry: WeeklyProgressEntry(date: .now, done: d.weeklyDoneCount, total: d.weeklyTotalCount)))
    }
}

struct WeeklyProgressWidgetView: View {
    let done: Int
    let total: Int
    private var progress: Double { total == 0 ? 0 : min(1.0, Double(done) / Double(total)) }
    private var percent: Int { Int(progress * 100) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.pikariDark, .pikariBlue],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 6) {
                Image(systemName: "house.fill").font(.caption2).foregroundStyle(.white.opacity(0.6))
                ZStack {
                    Circle().stroke(.white.opacity(0.15), lineWidth: 6)
                    Circle().trim(from: 0, to: progress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progress)
                    VStack(spacing: 0) {
                        Text("\(percent)%").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                        Text("達成").font(.system(size: 9)).foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(width: 64, height: 64)
                Text("\(done)/\(total) 件").font(.caption2).foregroundStyle(.white.opacity(0.7))
                Text("今週").font(.caption2).foregroundStyle(.white.opacity(0.4))
            }
            .padding(10)
        }
    }
}

struct WeeklyProgressWidget: Widget {
    let kind = "com.hiroki.CleaningApp.weeklyProgress"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyProgressProvider()) { entry in
            WeeklyProgressWidgetView(done: entry.done, total: entry.total)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("週間達成率")
        .description("今週の掃除達成率を円グラフで表示します")
        .supportedFamilies([.systemSmall])
    }
}
