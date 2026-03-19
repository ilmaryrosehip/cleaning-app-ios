import SwiftUI
import SwiftData

struct FloorPlanView: View {
    @Bindable var home: Home
    @State private var showAddRoom = false
    @State private var selectedRoom: Room? = nil

    private var sortedRooms: [Room] {
        home.rooms.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(sortedRooms) { room in
                            RoomGridCard(room: room).onTapGesture { selectedRoom = room }
                        }
                        Button { showAddRoom = true } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "plus").font(.title2).foregroundStyle(.secondary)
                                Text("部屋を追加").font(.subheadline).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity).frame(height: 90)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(Color(.systemGray3)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("間取り")
            .navigationDestination(item: $selectedRoom) { room in RoomDetailView(room: room) }
            .sheet(isPresented: $showAddRoom) { AddRoomSheet(home: home) }
        }
    }
}

struct RoomGridCard: View {
    @Bindable var room: Room
    private var pendingCount: Int {
        room.tasks.filter { $0.isActive && ($0.isOverdue || $0.isDueToday) }.count
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: room.icon).font(.title3).foregroundStyle(.teal)
                Spacer()
                if pendingCount > 0 {
                    Text("\(pendingCount)").font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15)).foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
            Text(room.name).font(.subheadline).fontWeight(.semibold)
            Text("タスク \(room.tasks.filter { $0.isActive }.count)件").font(.caption).foregroundStyle(.secondary)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).frame(height: 90)
        .background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray5), lineWidth: 0.5))
    }
}

struct RoomDetailView: View {
    @Bindable var room: Room
    @Environment(\.modelContext) private var context
    @State private var showAddTask = false
    @State private var selectedTab = 0

    private var activeTasks: [CleaningTask] {
        room.tasks.filter { $0.isActive }.sorted { $0.nextDueDate < $1.nextDueDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("タスク").tag(0)
                Text("設備・器具").tag(1)
            }
            .pickerStyle(.segmented).padding(.horizontal).padding(.vertical, 8)

            if selectedTab == 0 {
                taskList
            } else {
                FixtureListView(room: room)
            }
        }
        .navigationTitle(room.name).navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if selectedTab == 0 {
                    Button { showAddTask = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(home: room.home!, preselectedRoom: room)
        }
    }

    private var taskList: some View {
        List {
            if activeTasks.isEmpty {
                ContentUnavailableView("タスクがありません", systemImage: "sparkles",
                                       description: Text("＋ボタンからタスクを追加しましょう"))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(activeTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) { TaskListRow(task: task) }
                }
                .onDelete(perform: deleteTasks)
            }
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets { context.delete(activeTasks[index]) }
        try? context.save()
    }
}

struct TaskListRow: View {
    let task: CleaningTask
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(task.title).font(.subheadline).fontWeight(.medium)
                Spacer()
                StatusBadge(task: task)
            }
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise").font(.caption2)
                Text(task.frequency.rawValue).font(.caption)
                if task.frequency.supportsWeekdays && !task.weekdays.isEmpty {
                    Text("(\(task.weekdaysLabel))").font(.caption)
                }
                if task.estimatedMinutes > 0 {
                    Text("·")
                    Image(systemName: "clock").font(.caption2)
                    Text("約\(task.estimatedMinutes)分").font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct TaskDetailView: View {
    @Bindable var task: CleaningTask
    @Environment(\.modelContext) private var context
    @State private var showComplete = false
    @Query private var allSupplies: [Supply]

    var body: some View {
        List {
            Section("基本情報") {
                LabeledContent("部屋", value: task.room?.name ?? "-")
                LabeledContent("頻度", value: task.frequency.rawValue)
                if task.frequency.supportsWeekdays && !task.weekdays.isEmpty {
                    LabeledContent("曜日", value: task.weekdaysLabel)
                }
                LabeledContent("次回", value: task.nextDueDate.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("目安時間", value: "\(task.estimatedMinutes)分")
            }
            if !task.notes.isEmpty {
                Section("メモ") { Text(task.notes).font(.subheadline).foregroundStyle(.secondary) }
            }
            Section("使用用品") {
                ForEach(task.supplies) { supply in Label(supply.name, systemImage: "bag") }
                if task.supplies.isEmpty {
                    Text("用品が未登録です").font(.subheadline).foregroundStyle(.tertiary)
                }
            }
            if !task.fixtures.isEmpty {
                Section("対象の設備・器具") {
                    ForEach(task.fixtures.sorted { $0.name < $1.name }) { fixture in
                        NavigationLink(destination: FixtureDetailView(fixture: fixture)) {
                            HStack(spacing: 10) {
                                Image(systemName: fixture.icon).foregroundStyle(.teal).frame(width: 24)
                                Text(fixture.name).font(.subheadline)
                            }
                        }
                    }
                }
            }
            Section("実施記録（直近5件）") {
                let recentLogs = task.logs.sorted { $0.completedAt > $1.completedAt }.prefix(5)
                ForEach(Array(recentLogs)) { log in
                    HStack {
                        Text(log.completedAt.formatted(date: .abbreviated, time: .omitted)).font(.subheadline)
                        Spacer()
                        Text("\(log.durationMinutes)分").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if task.logs.isEmpty {
                    Text("まだ記録がありません").font(.subheadline).foregroundStyle(.tertiary)
                }
            }
        }
        .navigationTitle(task.title).navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showComplete = true } label: { Label("完了", systemImage: "checkmark.circle") }
                    .tint(.teal)
            }
        }
        .sheet(isPresented: $showComplete) { CompleteTaskSheet(task: task) }
    }
}

struct AddRoomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let home: Home
    @State private var name = ""
    @State private var icon = "house"
    private let iconOptions = [
        "sofa","fork.knife","bed.double","shower","door.left.hand.open","toilet",
        "books.vertical","drop","washer","refrigerator","stove","window.horizontal"
    ]
    var body: some View {
        NavigationStack {
            Form {
                Section("部屋名") { TextField("例: ダイニング", text: $name) }
                Section("アイコン") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { n in
                            Button { icon = n } label: {
                                Image(systemName: n).font(.title3).frame(width: 40, height: 40)
                                    .background(icon == n ? Color.teal.opacity(0.15) : Color(.systemGray6))
                                    .foregroundStyle(icon == n ? .teal : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }.buttonStyle(.plain)
                        }
                    }.padding(.vertical, 4)
                }
            }
            .navigationTitle("部屋を追加").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let room = Room(name: name, icon: icon, sortOrder: home.rooms.count)
                        room.home = home
                        context.insert(room)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty).fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let home: Home
    var preselectedRoom: Room? = nil

    @State private var title = ""
    @State private var selectedRoom: Room? = nil
    @State private var frequency: Frequency = .weekly
    @State private var selectedWeekdays: Set<Int> = []
    @State private var nextDueDate = Date.now
    @State private var estimatedMinutes = 15
    @State private var notes = ""

    @Query private var allSupplies: [Supply]
    @State private var selectedSupplyIDs: Set<UUID> = []
    @State private var selectedFixtureIDs: Set<UUID> = []

    private var roomFixtures: [Fixture] {
        (selectedRoom?.fixtures ?? []).sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タスク名") { TextField("例: フィルター清掃", text: $title) }
                Section("設定") {
                    Picker("部屋", selection: $selectedRoom) {
                        Text("選択してください").tag(Optional<Room>.none)
                        ForEach(home.rooms) { room in Text(room.name).tag(Optional(room)) }
                    }
                    .onChange(of: selectedRoom) { _, _ in selectedFixtureIDs = [] }

                    Picker("頻度", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) { f in Text(f.rawValue).tag(f) }
                    }
                    if frequency.supportsWeekdays {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(frequency == .weekly ? "毎週の曜日" : "隔週の曜日")
                                .font(.subheadline).foregroundStyle(.secondary)
                            WeekdayPicker(selectedWeekdays: $selectedWeekdays)
                        }
                        .padding(.vertical, 4)
                    }
                    DatePicker("初回日", selection: $nextDueDate, displayedComponents: .date)
                    Stepper("目安: \(estimatedMinutes)分", value: $estimatedMinutes, in: 5...180, step: 5)
                }
                if !roomFixtures.isEmpty {
                    Section {
                        ForEach(roomFixtures) { fixture in
                            FixtureSelectionRow(fixture: fixture,
                                                isSelected: selectedFixtureIDs.contains(fixture.id)) {
                                if selectedFixtureIDs.contains(fixture.id) {
                                    selectedFixtureIDs.remove(fixture.id)
                                } else {
                                    selectedFixtureIDs.insert(fixture.id)
                                    if title.trimmingCharacters(in: .whitespaces).isEmpty {
                                        title = fixture.name + "の清掃"
                                    }
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("対象の設備・器具")
                            Spacer()
                            Text("\(selectedFixtureIDs.count)件選択").font(.caption).foregroundStyle(.secondary)
                        }
                    } footer: {
                        Text("複数選択可。選択した設備に紐づくタスクとして管理されます").font(.caption)
                    }
                }
                if !allSupplies.isEmpty {
                    Section("使用用品") {
                        ForEach(allSupplies) { supply in
                            HStack {
                                Text(supply.name)
                                Spacer()
                                if selectedSupplyIDs.contains(supply.id) {
                                    Image(systemName: "checkmark").foregroundStyle(.teal)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedSupplyIDs.contains(supply.id) { selectedSupplyIDs.remove(supply.id) }
                                else { selectedSupplyIDs.insert(supply.id) }
                            }
                        }
                    }
                }
                Section("メモ") { TextField("任意", text: $notes, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle("タスクを追加").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") { saveTask() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedRoom == nil)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { selectedRoom = preselectedRoom ?? home.rooms.first }
        }
    }

    private func saveTask() {
        guard let room = selectedRoom else { return }
        let task = CleaningTask(title: title, frequency: frequency, weekdays: Array(selectedWeekdays),
                                intervalDays: 7, nextDueDate: nextDueDate,
                                estimatedMinutes: estimatedMinutes, notes: notes)
        task.room = room
        task.supplies = allSupplies.filter { selectedSupplyIDs.contains($0.id) }
        task.fixtures = roomFixtures.filter { selectedFixtureIDs.contains($0.id) }
        context.insert(task)
        try? context.save()
        dismiss()
    }
}

struct FixtureSelectionRow: View {
    let fixture: Fixture; let isSelected: Bool; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: fixture.icon).font(.title3)
                    .foregroundStyle(isSelected ? .teal : .secondary).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(fixture.name).font(.subheadline).fontWeight(.medium).foregroundStyle(.primary)
                    if !fixture.parts.isEmpty {
                        Text("パーツ \(fixture.parts.count)件").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .teal : Color(.systemGray3)).font(.title3)
            }
        }
        .buttonStyle(.plain)
    }
}

struct WeekdayPicker: View {
    @Binding var selectedWeekdays: Set<Int>
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.allCases) { weekday in
                let isSelected = selectedWeekdays.contains(weekday.rawValue)
                Button {
                    if isSelected { selectedWeekdays.remove(weekday.rawValue) }
                    else { selectedWeekdays.insert(weekday.rawValue) }
                } label: {
                    Text(weekday.label).font(.subheadline).fontWeight(.medium)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(isSelected ? Color.teal : Color(.systemGray6))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
