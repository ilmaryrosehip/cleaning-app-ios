import SwiftUI
import SwiftData

struct HomeView: View {
    let home: Home
    @State private var selectedRoom: Room? = nil
    @State private var showAddTask = false

    private var filteredTasks: [CleaningTask] {
        let tasks = selectedRoom == nil
            ? home.rooms.flatMap { $0.tasks }
            : (selectedRoom?.tasks ?? [])
        return tasks.filter { $0.isActive }.sorted {
            if $0.isOverdue != $1.isOverdue { return $0.isOverdue }
            if $0.isDueToday != $1.isDueToday { return $0.isDueToday }
            return $0.nextDueDate < $1.nextDueDate
        }
    }

    private var overdueTasks:  [CleaningTask] { filteredTasks.filter { $0.isOverdue } }
    private var todayTasks:    [CleaningTask] { filteredTasks.filter { $0.isDueToday } }
    private var upcomingTasks: [CleaningTask] { filteredTasks.filter { !$0.isOverdue && !$0.isDueToday } }

    private var completedThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        return home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }
            .filter { $0.completedAt >= weekAgo }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SummaryCardsView(overdueCount: overdueTasks.count,
                                     todayCount: todayTasks.count,
                                     weeklyDone: completedThisWeek)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            RoomFilterChip(name: "すべて", icon: "square.grid.2x2", isSelected: selectedRoom == nil) {
                                selectedRoom = nil
                            }
                            ForEach(home.rooms.sorted { $0.sortOrder < $1.sortOrder }) { room in
                                RoomFilterChip(name: room.name, icon: room.icon, isSelected: selectedRoom == room) {
                                    selectedRoom = selectedRoom == room ? nil : room
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    if overdueTasks.isEmpty && todayTasks.isEmpty && upcomingTasks.isEmpty {
                        EmptyTasksView().padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            if !overdueTasks.isEmpty  { TaskSectionView(title: "期限超過", tasks: overdueTasks, style: .overdue) }
                            if !todayTasks.isEmpty    { TaskSectionView(title: "今日",     tasks: todayTasks,   style: .today) }
                            if !upcomingTasks.isEmpty { TaskSectionView(title: "近日中",   tasks: upcomingTasks, style: .upcoming) }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(home.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddTask = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAddTask) { AddTaskSheet(home: home) }
            .task {
                let allTasks = home.rooms.flatMap { $0.tasks }
                await NotificationManager.shared.scheduleAll(tasks: allTasks)
            }
        }
    }
}

struct SummaryCardsView: View {
    let overdueCount: Int; let todayCount: Int; let weeklyDone: Int
    var body: some View {
        HStack(spacing: 12) {
            MetricCard(label: "期限超過",    value: "\(overdueCount)", valueColor: overdueCount > 0 ? .red : .secondary)
            MetricCard(label: "今日のタスク", value: "\(todayCount)",  valueColor: todayCount > 0  ? .orange : .secondary)
            MetricCard(label: "今週完了",    value: "\(weeklyDone)",  valueColor: .teal)
        }
    }
}

struct MetricCard: View {
    let label: String; let value: String
    var valueColor: Color = .primary
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2).fontWeight(.semibold).foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct RoomFilterChip: View {
    let name: String; let icon: String; let isSelected: Bool; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Label(name, systemImage: icon).font(.subheadline)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? Color.teal.opacity(0.12) : Color(.systemGray6))
                .foregroundStyle(isSelected ? .teal : .secondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.teal : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

enum TaskSectionStyle { case overdue, today, upcoming }

struct TaskSectionView: View {
    let title: String; let tasks: [CleaningTask]; let style: TaskSectionStyle
    var accentColor: Color {
        switch style {
        case .overdue:  return .red
        case .today:    return .orange
        case .upcoming: return .secondary
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.footnote).fontWeight(.semibold).foregroundStyle(accentColor)
            ForEach(tasks) { task in TaskCardView(task: task) }
        }
    }
}

struct TaskCardView: View {
    @Environment(\.modelContext) private var context
    @Bindable var task: CleaningTask
    @State private var showComplete = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { showComplete = true } label: {
                Circle().stroke(Color.teal.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.teal).opacity(0.4))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.room?.name ?? "").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    StatusBadge(task: task)
                }
                Text(task.title).font(.subheadline).fontWeight(.medium)

                if !task.fixtures.isEmpty || !task.supplies.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(task.fixtures.prefix(2))) { fixture in
                            Label(fixture.name, systemImage: fixture.icon)
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.teal.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .foregroundStyle(.teal)
                        }
                        ForEach(Array(task.supplies.prefix(2))) { supply in
                            Text(supply.name)
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 0.5))
        .sheet(isPresented: $showComplete) { CompleteTaskSheet(task: task) }
    }
}

struct StatusBadge: View {
    let task: CleaningTask
    var body: some View {
        Group {
            if task.isOverdue {
                let days = Calendar.current.dateComponents([.day], from: task.nextDueDate, to: .now).day ?? 0
                Text("\(days)日超過").foregroundStyle(.red).background(Color.red.opacity(0.1))
            } else if task.isDueToday {
                Text("今日").foregroundStyle(.orange).background(Color.orange.opacity(0.1))
            } else {
                let days = Calendar.current.dateComponents([.day], from: .now, to: task.nextDueDate).day ?? 0
                Text("\(days)日後").foregroundStyle(.secondary).background(Color(.systemGray6))
            }
        }
        .font(.caption2).fontWeight(.medium)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - CompleteTaskSheet（二重完了ワーニング＋パーツ使用数記録付き）

struct CompleteTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var task: CleaningTask
    @State private var duration = 15
    @State private var memo = ""
    @State private var showDuplicateWarning = false

    /// タスクに紐づいた設備のパーツ一覧（在庫管理対象）
    private var availableParts: [ConsumablePart] {
        task.fixtures.flatMap { $0.parts }.sorted { $0.name < $1.name }
    }

    /// パーツID → 使用数のマップ（0 = 使用しない）
    @State private var partUsageMap: [UUID: Int] = [:]

    private var completedTodayCount: Int {
        task.logs.filter { Calendar.current.isDateInToday($0.completedAt) }.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タスク") {
                    LabeledContent("部屋", value: task.room?.name ?? "-")
                    LabeledContent("内容", value: task.title)
                }

                // 二重完了ワーニング
                if completedTodayCount > 0 {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("本日 \(completedTodayCount) 回完了済み")
                                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.orange)
                                Text("本日すでに完了が記録されています。続けて記録しますか？")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // 消耗品パーツ使用数セクション
                if !availableParts.isEmpty {
                    Section {
                        ForEach(availableParts) { part in
                            let usedCount = partUsageMap[part.id] ?? 0
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(part.name).font(.subheadline).fontWeight(.medium)
                                    HStack(spacing: 6) {
                                        if let fixtureName = part.fixture?.name {
                                            Text(fixtureName).font(.caption).foregroundStyle(.secondary)
                                        }
                                        // 在庫数表示
                                        Text("在庫 \(part.stockCount)個")
                                            .font(.caption)
                                            .foregroundStyle(part.stockCount == 0 ? .red : .secondary)
                                    }
                                }
                                Spacer()
                                // 使用数ステッパー
                                HStack(spacing: 8) {
                                    Button {
                                        let current = partUsageMap[part.id] ?? 0
                                        if current > 0 { partUsageMap[part.id] = current - 1 }
                                    } label: {
                                        Image(systemName: "minus.circle")
                                            .foregroundStyle(usedCount > 0 ? .teal : Color(.systemGray3))
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(usedCount)個")
                                        .font(.subheadline).fontWeight(.semibold)
                                        .frame(minWidth: 36)
                                        .foregroundStyle(usedCount > 0 ? .teal : .secondary)

                                    Button {
                                        let current = partUsageMap[part.id] ?? 0
                                        partUsageMap[part.id] = current + 1
                                    } label: {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.teal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text("消耗品パーツの使用数")
                    } footer: {
                        Text("使用した分だけ在庫から差し引かれます")
                            .font(.caption)
                    }
                }

                Section("記録") {
                    Stepper("所要時間: \(duration)分", value: $duration, in: 1...180, step: 5)
                    TextField("メモ（任意）", text: $memo, axis: .vertical).lineLimit(3)
                }
            }
            .navigationTitle("完了を記録").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        if completedTodayCount > 0 {
                            showDuplicateWarning = true
                        } else {
                            saveCompletion()
                        }
                    }.fontWeight(.semibold)
                }
            }
            .alert("二重完了の確認", isPresented: $showDuplicateWarning) {
                Button("キャンセル", role: .cancel) {}
                Button("それでも記録する", role: .destructive) { saveCompletion() }
            } message: {
                Text("本日すでに \(completedTodayCount) 回完了が記録されています。\nもう一度記録してよいですか？")
            }
        }
        .presentationDetents([.large])
        .onAppear {
            // 初期化：全パーツの使用数を0に設定
            for part in availableParts {
                partUsageMap[part.id] = 0
            }
        }
    }

    private func saveCompletion() {
        let log = task.markCompleted(duration: duration, memo: memo)

        // パーツ使用数を記録して在庫を差し引く
        for part in availableParts {
            let used = partUsageMap[part.id] ?? 0
            guard used > 0 else { continue }

            // 使用記録を作成
            let usage = TaskPartUsage(part: part, usedCount: used)
            usage.log = log
            context.insert(usage)

            // 在庫から差し引く（0未満にはならない）
            part.stockCount = max(0, part.stockCount - used)
        }

        try? context.save()
        Task {
            await NotificationManager.shared.scheduleNotifications(for: task)
        }
        dismiss()
    }
}

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle").font(.system(size: 48)).foregroundStyle(.teal.opacity(0.5))
            Text("タスクがありません").font(.headline)
            Text("右上の＋ボタンでタスクを追加しましょう").font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}
