import SwiftUI
import SwiftData
import WidgetKit

struct HomeView: View {
    let home: Home
    @State private var selectedRoom: Room? = nil
    @State private var showAddTask = false

    private var allTasks: [CleaningTask] {
        home.rooms.flatMap { $0.tasks }.filter { $0.isActive }
    }

    private var filteredTasks: [CleaningTask] {
        let tasks = selectedRoom == nil ? allTasks : (selectedRoom?.tasks.filter { $0.isActive } ?? [])
        return tasks.sorted {
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
        return allTasks.flatMap { $0.logs }.filter { $0.completedAt >= weekAgo }.count
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
                            RoomFilterChip(name: L(.all), icon: "square.grid.2x2", isSelected: selectedRoom == nil) {
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
                            if !overdueTasks.isEmpty  { TaskSectionView(title: L(.overdue), tasks: overdueTasks, style: .overdue) }
                            if !todayTasks.isEmpty    { TaskSectionView(title: L(.today), tasks: todayTasks, style: .today) }
                            if !upcomingTasks.isEmpty { TaskSectionView(title: L(.upcoming), tasks: upcomingTasks, style: .upcoming) }
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
                await NotificationManager.shared.scheduleAll(tasks: allTasks)
                updateWidgetData()
            }
            .onChange(of: allTasks.count) { _, _ in updateWidgetData() }
        }
    }

    // MARK: - ウィジェットデータ更新
    private func updateWidgetData() {
        let cal = Calendar.current
        let weekAgo = cal.date(byAdding: .day, value: -7, to: .now)!

        func dueDateText(_ task: CleaningTask) -> String {
            if task.isOverdue {
                let days = cal.dateComponents([.day], from: task.nextDueDate, to: .now).day ?? 0
                return LocalizationManager.shared.language == .japanese ? "\(days)日超過" : "\(days)d overdue"
            }
            if task.isDueToday { return LocalizationManager.shared.language == .japanese ? "今日" : "Today" }
            let days = cal.dateComponents([.day], from: .now, to: task.nextDueDate).day ?? 0
            if days == 1 { return L(.tomorrow) }
            return LocalizationManager.shared.language == .japanese ? "\(days)日後" : "in \(days)d"
        }

        func toWidgetEntry(_ task: CleaningTask) -> WidgetTaskEntry {
            WidgetTaskEntry(
                id: task.id,
                title: task.title,
                roomName: task.room?.name ?? "",
                isOverdue: task.isOverdue,
                isDueToday: task.isDueToday,
                nextDueDateText: dueDateText(task)
            )
        }

        let overdue  = allTasks.filter { $0.isOverdue }.map { toWidgetEntry($0) }
        let today    = allTasks.filter { $0.isDueToday }.map { toWidgetEntry($0) }
        let upcoming = allTasks.filter { !$0.isOverdue && !$0.isDueToday }
            .sorted { $0.nextDueDate < $1.nextDueDate }
            .first.map { toWidgetEntry($0) }

        // 在庫不足パーツ
        let lowStock: [WidgetPartEntry] = home.rooms
            .flatMap { $0.fixtures }
            .flatMap { $0.parts }
            .filter { $0.stockCount <= 1 }
            .sorted { $0.stockCount < $1.stockCount }
            .map { WidgetPartEntry(id: $0.id, name: $0.name, fixtureName: $0.fixture?.name ?? "", stockCount: $0.stockCount) }

        // 週間達成数
        let weeklyDone = allTasks.flatMap { $0.logs }.filter { $0.completedAt >= weekAgo }.count

        let data = WidgetSharedData(
            todayTasks: today,
            overdueTasks: overdue,
            upcomingTask: upcoming,
            lowStockParts: lowStock,
            weeklyDoneCount: weeklyDone,
            weeklyTotalCount: allTasks.count,
            updatedAt: .now
        )
        WidgetDataStore.save(data)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct SummaryCardsView: View {
    let overdueCount: Int; let todayCount: Int; let weeklyDone: Int
    var body: some View {
        HStack(spacing: 12) {
            MetricCard(label: L(.overdueTask),    value: "\(overdueCount)", valueColor: overdueCount > 0 ? .red : .secondary)
            MetricCard(label: L(.todayTask), value: "\(todayCount)",  valueColor: todayCount > 0  ? .orange : .secondary)
            MetricCard(label: L(.weeklyDone),    value: "\(weeklyDone)",  valueColor: .teal)
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
                Text(L(.today)).foregroundStyle(.orange).background(Color.orange.opacity(0.1))
            } else {
                let days = Calendar.current.dateComponents([.day], from: .now, to: task.nextDueDate).day ?? 0
                let d = days == 1 ? L(.tomorrow) : (LocalizationManager.shared.language == .japanese ? "\(days)日後" : "in \(days)d")
                Text(d).foregroundStyle(.secondary).background(Color(.systemGray6))
            }
        }
        .font(.caption2).fontWeight(.medium)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - CompleteTaskSheet

struct CompleteTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var task: CleaningTask
    @State private var duration = 15
    @State private var memo = ""
    @State private var showDuplicateWarning = false
    @State private var partUsageMap: [UUID: Int] = [:]

    private var availableParts: [ConsumablePart] {
        task.fixtures.flatMap { $0.parts }.sorted { $0.name < $1.name }
    }

    private var completedTodayCount: Int {
        task.logs.filter { Calendar.current.isDateInToday($0.completedAt) }.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L(.taskName)) {
                    LabeledContent(L(.room), value: task.room?.name ?? "-")
                    LabeledContent(L(.taskName), value: task.title)
                }
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
                                        Text(LocalizationManager.shared.language == .japanese ? "在庫 \(part.stockCount)個" : "Stock: \(part.stockCount)")
                                            .font(.caption)
                                            .foregroundStyle(part.stockCount == 0 ? .red : .secondary)
                                    }
                                }
                                Spacer()
                                HStack(spacing: 8) {
                                    Button {
                                        let c = partUsageMap[part.id] ?? 0
                                        if c > 0 { partUsageMap[part.id] = c - 1 }
                                    } label: {
                                        Image(systemName: "minus.circle")
                                            .foregroundStyle(usedCount > 0 ? .teal : Color(.systemGray3))
                                    }.buttonStyle(.plain)
                                    Text(LocalizationManager.shared.language == .japanese ? "\(usedCount)個" : "\(usedCount)")
                                        .font(.subheadline).fontWeight(.semibold)
                                        .frame(minWidth: 36)
                                        .foregroundStyle(usedCount > 0 ? .teal : .secondary)
                                    Button {
                                        partUsageMap[part.id] = (partUsageMap[part.id] ?? 0) + 1
                                    } label: {
                                        Image(systemName: "plus.circle").foregroundStyle(.teal)
                                    }.buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } header: { Text(L(.partsUsed)) }
                    footer: { Text(L(.partsUsedFooter)).font(.caption) }
                }
                Section(L(.memo)) {
                    Stepper((LocalizationManager.shared.language == .japanese ? "所要時間: \(duration)分" : "Duration: \(duration) min"), value: $duration, in: 1...180, step: 5)
                    TextField((LocalizationManager.shared.language == .japanese ? "メモ（任意）" : "Memo (optional)"), text: $memo, axis: .vertical).lineLimit(3)
                }
            }
            .navigationTitle(L(.recordCompletion)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L(.complete)) {
                        if completedTodayCount > 0 { showDuplicateWarning = true }
                        else { saveCompletion() }
                    }.fontWeight(.semibold)
                }
            }
            .alert(L(.duplicateWarning), isPresented: $showDuplicateWarning) {
                Button("キャンセル", role: .cancel) {}
                Button(L(.recordAnyway), role: .destructive) { saveCompletion() }
            } message: {
                Text("本日すでに \(completedTodayCount) 回完了が記録されています。\nもう一度記録してよいですか？")
            }
        }
        .presentationDetents([.large])
        .onAppear { for part in availableParts { partUsageMap[part.id] = 0 } }
    }

    private func saveCompletion() {
        let log = task.markCompleted(duration: duration, memo: memo)
        for part in availableParts {
            let used = partUsageMap[part.id] ?? 0
            guard used > 0 else { continue }
            let usage = TaskPartUsage(part: part, usedCount: used)
            usage.log = log
            context.insert(usage)
            part.stockCount = max(0, part.stockCount - used)
        }
        try? context.save()
        Task { await NotificationManager.shared.scheduleNotifications(for: task) }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle").font(.system(size: 48)).foregroundStyle(.teal.opacity(0.5))
            Text(L(.noTasks)).font(.headline)
            Text(L(.noTasksHint)).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}
