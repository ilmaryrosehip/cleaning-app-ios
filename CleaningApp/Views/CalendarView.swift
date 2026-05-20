import SwiftUI
import SwiftData

// MARK: - CalendarView（月間カレンダー）

struct CalendarView: View {
    let home: Home
    @State private var displayMonth: Date = Calendar.current.startOfMonth(for: .now)
    @State private var selectedDate: Date? = nil

    private let cal = Calendar.current

    // 表示月のタスクをまとめる
    private var tasksByDate: [Date: [CleaningTask]] {
        var dict: [Date: [CleaningTask]] = [:]
        let allTasks = home.rooms.flatMap { $0.tasks }.filter { $0.isActive }
        let days = daysInMonth

        for task in allTasks {
            for day in days {
                if isSameDay(task.nextDueDate, day) ||
                   isTaskDueOn(task: task, date: day) {
                    dict[day, default: []].append(task)
                }
            }
        }
        return dict
    }

    // 完了ログをまとめる
    private var completedByDate: [Date: Int] {
        var dict: [Date: Int] = [:]
        let logs = home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }
        for log in logs {
            let day = cal.startOfDay(for: log.completedAt)
            dict[day, default: 0] += 1
        }
        return dict
    }

    // 月の日付一覧
    private var daysInMonth: [Date] {
        guard let range = cal.range(of: .day, in: .month, for: displayMonth) else { return [] }
        return range.compactMap { day in
            cal.date(byAdding: .day, value: day - 1, to: displayMonth)
        }
    }

    // カレンダーグリッドの日付（前月・翌月の日も含む）
    private var calendarDays: [Date?] {
        let firstWeekday = cal.component(.weekday, from: displayMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        days += daysInMonth.map { Optional($0) }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: displayMonth)
    }

    private var selectedTasks: [CleaningTask] {
        guard let date = selectedDate else { return [] }
        return tasksByDate[cal.startOfDay(for: date)] ?? []
    }

    private var selectedLogs: [TaskLog] {
        guard let date = selectedDate else { return [] }
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }
            .filter { $0.completedAt >= start && $0.completedAt < end }
            .sorted { $0.completedAt < $1.completedAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 月ナビゲーション
                monthNavigator
                    .padding(.horizontal).padding(.top, 8)

                // 曜日ヘッダー
                weekdayHeader
                    .padding(.horizontal, 4).padding(.top, 8)

                // カレンダーグリッド
                calendarGrid
                    .padding(.horizontal, 4)

                Divider().padding(.top, 8)

                // 選択日のタスク・完了一覧
                selectedDayDetail
            }
            .navigationTitle(L(.calendar))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 月ナビゲーター

    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayMonth = cal.date(byAdding: .month, value: -1, to: displayMonth)!
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3).foregroundStyle(.teal)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text(monthTitle)
                .font(.title3).fontWeight(.bold)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayMonth = cal.date(byAdding: .month, value: 1, to: displayMonth)!
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3).foregroundStyle(.teal)
                    .frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - 曜日ヘッダー

    private var weekdayHeader: some View {
        let labels = ["日", "月", "火", "水", "木", "金", "土"]
        return HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self) { i in
                Text(labels[i])
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(i == 0 ? .red : i == 6 ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - カレンダーグリッド

    private var calendarGrid: some View {
        let weeks = calendarDays.chunked(into: 7)
        return VStack(spacing: 2) {
            ForEach(weeks.indices, id: \.self) { wi in
                HStack(spacing: 2) {
                    ForEach(weeks[wi].indices, id: \.self) { di in
                        if let date = weeks[wi][di] {
                            CalendarDayCell(
                                date: date,
                                isToday: isSameDay(date, .now),
                                isSelected: selectedDate.map { isSameDay($0, date) } ?? false,
                                taskCount: tasksByDate[cal.startOfDay(for: date)]?.count ?? 0,
                                completedCount: completedByDate[cal.startOfDay(for: date)] ?? 0,
                                weekdayIndex: di
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedDate = isSameDay(selectedDate ?? .distantPast, date) ? nil : date
                                }
                            }
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 48)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 選択日の詳細

    private var selectedDayDetail: some View {
        Group {
            if let date = selectedDate {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // 日付ヘッダー
                        let formatter: DateFormatter = {
                            let f = DateFormatter()
                            f.dateFormat = "M月d日（E）"
                            f.locale = Locale(identifier: "ja_JP")
                            return f
                        }()
                        Text(formatter.string(from: date))
                            .font(.headline).padding(.horizontal)

                        // タスク
                        if !selectedTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label(L(.scheduledTasks), systemImage: "checklist")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(.teal)
                                    .padding(.horizontal)

                                ForEach(selectedTasks) { task in
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(task.isOverdue ? Color.red : Color.teal)
                                            .frame(width: 6, height: 6)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(task.title)
                                                .font(.subheadline).fontWeight(.medium)
                                            Text(task.room?.name ?? "")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if task.isOverdue {
                                            Text(LocalizationManager.shared.language == .japanese ? "超過" : "Overdue").font(.caption2).foregroundStyle(.red)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // 完了ログ
                        if !selectedLogs.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label(L(.completed), systemImage: "checkmark.circle.fill")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(.green)
                                    .padding(.horizontal)

                                ForEach(selectedLogs) { log in
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green).font(.caption)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(log.task?.title ?? "削除済みタスク")
                                                .font(.subheadline)
                                            Text(log.completedAt.formatted(date: .omitted, time: .shortened))
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if log.durationMinutes > 0 {
                                            Text("\(log.durationMinutes)分")
                                                .font(.caption2)
                                                .padding(.horizontal, 6).padding(.vertical, 2)
                                                .background(Color.teal.opacity(0.1))
                                                .foregroundStyle(.teal)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        if selectedTasks.isEmpty && selectedLogs.isEmpty {
                            Text(L(.noSchedule))
                                .font(.subheadline).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 12)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 32)).foregroundStyle(.secondary.opacity(0.5))
                    Text(LocalizationManager.shared.language == .japanese ? "日付をタップして詳細を確認" : "Tap a date to see details")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }

    // MARK: - ヘルパー

    private func isSameDay(_ a: Date, _ b: Date) -> Bool {
        cal.isDate(a, inSameDayAs: b)
    }

    /// タスクが指定日に予定されているか（繰り返しパターンを考慮）
    private func isTaskDueOn(task: CleaningTask, date: Date) -> Bool {
        let dayStart = cal.startOfDay(for: date)
        let taskDay  = cal.startOfDay(for: task.nextDueDate)
        return dayStart == taskDay
    }
}

// MARK: - CalendarDayCell

struct CalendarDayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let taskCount: Int
    let completedCount: Int
    let weekdayIndex: Int

    private var dayNum: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    private var textColor: Color {
        if isSelected { return .white }
        if isToday { return .teal }
        if weekdayIndex == 0 { return .red }
        if weekdayIndex == 6 { return .blue }
        return .primary
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if isSelected {
                    Circle().fill(Color.teal).frame(width: 28, height: 28)
                } else if isToday {
                    Circle().stroke(Color.teal, lineWidth: 1.5).frame(width: 28, height: 28)
                }
                Text(dayNum)
                    .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundStyle(textColor)
            }
            .frame(width: 28, height: 28)

            // タスクドット
            HStack(spacing: 2) {
                if taskCount > 0 {
                    ForEach(0..<min(taskCount, 3), id: \.self) { _ in
                        Circle().fill(Color.orange).frame(width: 4, height: 4)
                    }
                }
                if completedCount > 0 {
                    Circle().fill(Color.green).frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(isSelected ? Color.teal.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
