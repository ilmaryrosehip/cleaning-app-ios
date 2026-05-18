import SwiftUI
import SwiftData

// MARK: - CalendarView

struct CalendarView: View {
    let home: Home
    @State private var currentMonth: Date = Calendar.current.startOfMonth(for: .now)
    @State private var selectedDate: Date? = nil

    private var allTasks: [CleaningTask] {
        home.rooms.flatMap { $0.tasks }.filter { $0.isActive }
    }

    // 月の日一覧
    private var daysInMonth: [Date?] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: currentMonth),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))
        else { return [] }

        let weekdayOffset = cal.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: weekdayOffset)
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        // 6行分に截診
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    // 日付ごとのタスクマップ
    private var tasksByDate: [String: [CleaningTask]] {
        var map: [String: [CleaningTask]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for task in allTasks {
            let key = formatter.string(from: task.nextDueDate)
            map[key, default: []].append(task)
        }
        return map
    }

    // 選択日のタスク
    private var selectedTasks: [CleaningTask] {
        guard let date = selectedDate else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        return (tasksByDate[key] ?? []).sorted { $0.title < $1.title }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 月ナビゲーション
                monthNavigator

                // 曜日ヘッダー
                weekdayHeader

                // カレンダーグリッド
                calendarGrid
                    .padding(.horizontal, 8)

                Divider().padding(.top, 8)

                // 選択日のタスク一覧
                selectedTaskList
            }
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 月ナビゲーション

    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundStyle(.teal)
                    .padding(8)
            }

            Spacer()

            Text(currentMonth.formatted(.dateTime.year().month(.wide).locale(Locale(identifier: "ja_JP"))))
                .font(.title3).fontWeight(.bold)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundStyle(.teal)
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - 曜日ヘッダー

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                Text(day)
                    .font(.caption).fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(
                        day == "日" ? .red :
                        day == "土" ? .blue : .secondary
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    // MARK: - カレンダーグリッド

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { idx, date in
                if let date {
                    DayCell(
                        date: date,
                        tasks: tasksByDate[DateFormatter.dayKey.string(from: date)] ?? [],
                        isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false,
                        isToday: Calendar.current.isDateInToday(date)
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if let sel = selectedDate, Calendar.current.isDate(sel, inSameDayAs: date) {
                                selectedDate = nil
                            } else {
                                selectedDate = date
                            }
                        }
                    }
                } else {
                    Color.clear.frame(height: 52)
                }
            }
        }
    }

    // MARK: - 選択日タスク一覧

    private var selectedTaskList: some View {
        Group {
            if let date = selectedDate {
                VStack(alignment: .leading, spacing: 0) {
                    // 選択日ヘッダー
                    HStack {
                        Text(date.formatted(.dateTime.month().day().weekday().locale(Locale(identifier: "ja_JP"))))
                            .font(.subheadline).fontWeight(.semibold)
                        Spacer()
                        Text("(selectedTasks.count)件")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if selectedTasks.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                    .font(.title2).foregroundStyle(.teal.opacity(0.5))
                                Text("タスクなし")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            .padding(.top, 16)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(selectedTasks) { task in
                                    CalendarTaskRow(task: task)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }
                    }
                }
            } else {
                // 月のタスク概要
                monthSummary
            }
        }
    }

    // MARK: - 月のタスク概要

    private var monthSummary: some View {
        let cal = Calendar.current
        let monthTasks = allTasks.filter {
            cal.isDate($0.nextDueDate, equalTo: currentMonth, toGranularity: .month)
        }
        let overdueTasks = allTasks.filter { $0.isOverdue }

        return ScrollView {
            VStack(spacing: 12) {
                // 今月のサマリー
                HStack(spacing: 12) {
                    CalendarSummaryCard(
                        icon: "calendar",
                        label: "今月のタスク",
                        value: "\(monthTasks.count)件",
                        color: .teal
                    )
                    CalendarSummaryCard(
                        icon: "exclamationmark.triangle.fill",
                        label: "期限超過",
                        value: "\(overdueTasks.count)件",
                        color: overdueTasks.isEmpty ? .secondary : .red
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // 期限超過タスクがあれば表示
                if !overdueTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("期限超過")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                        ForEach(overdueTasks.prefix(3)) { task in
                            CalendarTaskRow(task: task)
                                .padding(.horizontal, 16)
                        }
                    }
                }

                Text("日付をタップするとその日のタスクを確認できます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
            }
        }
    }
}

// MARK: - DayCell

struct DayCell: View {
    let date: Date
    let tasks: [CleaningTask]
    let isSelected: Bool
    let isToday: Bool

    private var hasOverdue: Bool { tasks.contains { $0.isOverdue } }
    private var hasToday: Bool { tasks.contains { $0.isDueToday } }

    private var dotColor: Color {
        if hasOverdue { return .red }
        if hasToday { return .orange }
        if !tasks.isEmpty { return .teal }
        return .clear
    }

    private var weekday: Int {
        Calendar.current.component(.weekday, from: date)
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // 選択背景
                Circle()
                    .fill(isSelected ? Color.teal : (isToday ? Color.teal.opacity(0.15) : Color.clear))
                    .frame(width: 32, height: 32)

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 15, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundStyle(
                        isSelected ? .white :
                        isToday ? .teal :
                        weekday == 1 ? .red :
                        weekday == 7 ? .blue : .primary
                    )
            }

            // タスクドット
            if tasks.isEmpty {
                Color.clear.frame(width: 6, height: 6)
            } else {
                HStack(spacing: 2) {
                    ForEach(0..<min(tasks.count, 3), id: \.self) { i in
                        Circle()
                            .fill(i == 0 ? dotColor : Color.teal.opacity(0.4))
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
        }
        .frame(height: 52)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - CalendarTaskRow

struct CalendarTaskRow: View {
    let task: CleaningTask

    private var statusColor: Color {
        if task.isOverdue { return .red }
        if task.isDueToday { return .orange }
        return .teal
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 3, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline).fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let roomName = task.room?.name {
                        Text(roomName)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if task.isOverdue {
                        let days = Calendar.current.dateComponents([.day], from: task.nextDueDate, to: .now).day ?? 0
                        Text("\(days)日超過")
                            .font(.caption).foregroundStyle(.red)
                    } else if task.isDueToday {
                        Text("今日")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Text(task.frequency.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(statusColor.opacity(0.1))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray5), lineWidth: 0.5))
    }
}

// MARK: - CalendarSummaryCard

struct CalendarSummaryCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon).foregroundStyle(color).font(.caption)
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            Text(value).font(.title3).fontWeight(.bold).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Date Extension

extension Date {
    var startOfMonth: Date {
        Calendar.current.startOfMonth(for: self)
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

extension DateFormatter {
    static let dayKey: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
