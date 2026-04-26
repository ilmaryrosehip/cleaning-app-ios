import SwiftUI
import SwiftData

// MARK: - SupplyListView

struct SupplyListView: View {
    @Query(sort: \Supply.name) private var supplies: [Supply]
    @Environment(\.modelContext) private var context
    @State private var showAddSupply = false
    @State private var showPurchaseList = false

    private var needsReorder: [Supply] { supplies.filter { $0.stockStatus.needsReorder } }

    var body: some View {
        NavigationStack {
            List {
                if !needsReorder.isEmpty {
                    Section {
                        ForEach(needsReorder) { supply in
                            NavigationLink(destination: SupplyDetailView(supply: supply)) { SupplyRow(supply: supply) }
                        }
                    } header: {
                        Label("補充が必要", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                    }
                }
                ForEach(SupplyCategory.allCases, id: \.self) { category in
                    let inCategory = supplies.filter { $0.category == category }
                    if !inCategory.isEmpty {
                        Section(category.rawValue) {
                            ForEach(inCategory) { supply in
                                NavigationLink(destination: SupplyDetailView(supply: supply)) { SupplyRow(supply: supply) }
                            }
                            .onDelete { offsets in
                                for i in offsets { context.delete(inCategory[i]) }
                                try? context.save()
                            }
                        }
                    }
                }
            }
            .navigationTitle("用品管理")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddSupply = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button { showPurchaseList = true } label: { Label("購入リスト", systemImage: "cart") }
                }
            }
            .sheet(isPresented: $showAddSupply) { AddSupplySheet() }
            .sheet(isPresented: $showPurchaseList) { PurchaseListSheet() }
        }
    }
}

struct SupplyRow: View {
    let supply: Supply
    var statusColor: Color {
        switch supply.stockStatus {
        case .ok: return .teal
        case .low: return .orange
        case .outOfStock: return .red
        }
    }
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(statusColor).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(supply.name).font(.subheadline).fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(supply.category.rawValue)
                    if let used = supply.lastUsedAt {
                        Text("·")
                        Text(used.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
                if !supply.purchaseStoreName.isEmpty {
                    Label(supply.purchaseStoreName, systemImage: "cart")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(supply.stockStatus.rawValue).font(.caption).fontWeight(.medium)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(statusColor.opacity(0.12)).foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
    }
}

// MARK: - SupplyDetailView

struct SupplyDetailView: View {
    @Bindable var supply: Supply
    @Environment(\.modelContext) private var context
    @State private var showAddPurchase = false
    @State private var showEdit = false

    var body: some View {
        List {
            Section("状態") {
                Picker("在庫状況", selection: $supply.stockStatus) {
                    ForEach(StockStatus.allCases, id: \.self) { s in Text(s.rawValue).tag(s) }
                }
                .onChange(of: supply.stockStatus) { _, _ in try? context.save() }
                LabeledContent("カテゴリ", value: supply.category.rawValue)
                if let used = supply.lastUsedAt {
                    LabeledContent("最終使用", value: used.formatted(date: .abbreviated, time: .omitted))
                }
            }

            Section("購入先") {
                if supply.purchaseStoreName.isEmpty && supply.purchaseURL.isEmpty {
                    Text("購入先が未登録です")
                        .font(.subheadline).foregroundStyle(.tertiary)
                } else {
                    if !supply.purchaseStoreName.isEmpty {
                        LabeledContent("店名", value: supply.purchaseStoreName)
                    }
                    if !supply.purchaseURL.isEmpty,
                       let url = URL(string: supply.purchaseURL) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "arrow.up.right.square").foregroundStyle(.teal)
                                Text("購入ページを開く").foregroundStyle(.teal)
                                Spacer()
                                Text(supply.purchaseStoreName.isEmpty ? supply.purchaseURL : supply.purchaseStoreName)
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                }
            }

            Section("使用しているタスク") {
                if supply.tasks.isEmpty {
                    Text("紐づいたタスクがありません").foregroundStyle(.tertiary).font(.subheadline)
                } else {
                    ForEach(supply.tasks) { task in
                        HStack {
                            Text(task.room?.name ?? "").foregroundStyle(.secondary).font(.caption)
                            Text(task.title).font(.subheadline)
                        }
                    }
                }
            }

            Section("購入メモ") {
                ForEach(supply.purchaseItems.sorted { $0.isPurchased == false && $1.isPurchased }) { item in
                    PurchaseItemRow(item: item)
                }
                Button { showAddPurchase = true } label: { Label("購入メモを追加", systemImage: "plus") }
            }

            if !supply.memo.isEmpty {
                Section("メモ") { Text(supply.memo).foregroundStyle(.secondary).font(.subheadline) }
            }
        }
        .navigationTitle(supply.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("編集") { showEdit = true }
            }
        }
        .sheet(isPresented: $showAddPurchase) { AddPurchaseItemSheet(supply: supply) }
        .sheet(isPresented: $showEdit) { EditSupplySheet(supply: supply) }
    }
}

// MARK: - EditSupplySheet

struct EditSupplySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var supply: Supply

    var body: some View {
        NavigationStack {
            Form {
                Section("用品名") { TextField("用品名", text: $supply.name) }
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $supply.category) {
                        ForEach(SupplyCategory.allCases, id: \.self) { c in Text(c.rawValue).tag(c) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("購入先") {
                    TextField("店名（例: Amazon、ヨドバシ）", text: $supply.purchaseStoreName)
                    TextField("購入URL（任意）", text: $supply.purchaseURL)
                        .keyboardType(.URL).autocorrectionDisabled().textInputAutocapitalization(.never)
                    if !supply.purchaseURL.isEmpty, let url = URL(string: supply.purchaseURL) {
                        Link(destination: url) {
                            Label("リンクを確認", systemImage: "arrow.up.right.square")
                                .font(.caption).foregroundStyle(.teal)
                        }
                    }
                }
                Section("メモ") { TextField("任意", text: $supply.memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle("用品を編集").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { try? context.save(); dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct PurchaseItemRow: View {
    @Bindable var item: PurchaseItem
    @Environment(\.modelContext) private var context
    var body: some View {
        HStack {
            Button {
                item.markAsPurchased(); try? context.save()
            } label: {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPurchased ? .teal : .secondary)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline).strikethrough(item.isPurchased)
                    .foregroundStyle(item.isPurchased ? .secondary : .primary)
                Text("×\(item.quantity)  ¥\(item.estimatedPrice.formatted())")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - AddSupplySheet

struct AddSupplySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var category: SupplyCategory = .tool
    @State private var purchaseStoreName = ""
    @State private var purchaseURL = ""
    @State private var memo = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("用品名") { TextField("例: ダイソン V11", text: $name) }
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(SupplyCategory.allCases, id: \.self) { c in Text(c.rawValue).tag(c) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("購入先（任意）") {
                    TextField("店名（例: Amazon）", text: $purchaseStoreName)
                    TextField("購入URL", text: $purchaseURL)
                        .keyboardType(.URL).autocorrectionDisabled().textInputAutocapitalization(.never)
                }
                Section("メモ") { TextField("任意", text: $memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle("用品を追加").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let s = Supply(name: name, category: category, memo: memo,
                                       purchaseStoreName: purchaseStoreName, purchaseURL: purchaseURL)
                        context.insert(s); try? context.save(); dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty).fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct AddPurchaseItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let supply: Supply
    @State private var name = ""
    @State private var quantity = 1
    @State private var price = 0
    var body: some View {
        NavigationStack {
            Form {
                Section("品名") { TextField("例: 重曹スプレー 詰め替え", text: $name) }
                Section("数量・価格") {
                    Stepper("数量: \(quantity)個", value: $quantity, in: 1...99)
                    LabeledContent("予算") {
                        TextField("円", value: $price, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("購入メモを追加").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let item = PurchaseItem(name: name, quantity: quantity, estimatedPrice: price)
                        item.supply = supply; context.insert(item); try? context.save(); dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty).fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct PurchaseListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var supplies: [Supply]
    private var pendingItems: [PurchaseItem] {
        supplies.flatMap { $0.purchaseItems }.filter { !$0.isPurchased }
    }
    private var totalEstimate: Int { pendingItems.reduce(0) { $0 + $1.estimatedPrice * $1.quantity } }
    var body: some View {
        NavigationStack {
            List {
                if pendingItems.isEmpty {
                    ContentUnavailableView("購入メモがありません", systemImage: "cart",
                                           description: Text("用品画面から購入メモを追加できます"))
                } else {
                    ForEach(pendingItems) { item in PurchaseItemRow(item: item) }
                    Section {
                        HStack {
                            Text("合計（目安）").fontWeight(.medium)
                            Spacer()
                            Text("¥\(totalEstimate.formatted())").fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("購入リスト").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } }
            }
        }
    }
}

// MARK: - HistoryView

struct HistoryView: View {
    let home: Home
    @State private var selectedPeriod: HistoryPeriod = .week
    @State private var searchText = ""
    @State private var selectedTaskID: UUID? = nil

    enum HistoryPeriod: String, CaseIterable {
        case week = "今週", month = "今月", all = "すべて"
        var startDate: Date {
            let cal = Calendar.current
            switch self {
            case .week:  return cal.date(byAdding: .day, value: -7, to: .now)!
            case .month: return cal.date(byAdding: .month, value: -1, to: .now)!
            case .all:   return .distantPast
            }
        }
    }

    private var allTasks: [CleaningTask] {
        home.rooms.flatMap { $0.tasks }.sorted { $0.title < $1.title }
    }

    private var logs: [TaskLog] {
        home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }
            .filter { log in
                guard log.completedAt >= selectedPeriod.startDate else { return false }
                if let id = selectedTaskID { guard log.task?.id == id else { return false } }
                if !searchText.isEmpty {
                    let q = searchText.lowercased()
                    let titleMatch = (log.task?.title ?? "").lowercased().contains(q)
                    let roomMatch  = (log.task?.room?.name ?? "").lowercased().contains(q)
                    let memoMatch  = log.memo.lowercased().contains(q)
                    guard titleMatch || roomMatch || memoMatch else { return false }
                }
                return true
            }
            .sorted { $0.completedAt > $1.completedAt }
    }

    private var totalMinutes: Int { logs.reduce(0) { $0 + $1.durationMinutes } }

    private var groupedLogs: [(String, [TaskLog])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日（E）"
        formatter.locale = Locale(identifier: "ja_JP")
        let grouped = Dictionary(grouping: logs) { formatter.string(from: $0.completedAt) }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("期間", selection: $selectedPeriod) {
                    ForEach(HistoryPeriod.allCases, id: \.self) { p in Text(p.rawValue).tag(p) }
                }
                .pickerStyle(.segmented).padding(.horizontal).padding(.top, 12)

                if !allTasks.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            TaskFilterChip(name: "すべて", isSelected: selectedTaskID == nil) { selectedTaskID = nil }
                            ForEach(allTasks) { task in
                                TaskFilterChip(name: task.title, isSelected: selectedTaskID == task.id) {
                                    selectedTaskID = selectedTaskID == task.id ? nil : task.id
                                }
                            }
                        }
                        .padding(.horizontal).padding(.vertical, 8)
                    }
                }

                HStack(spacing: 12) {
                    MetricCard(label: "完了タスク", value: "\(logs.count)", valueColor: .teal)
                    MetricCard(label: "合計時間",   value: "\(totalMinutes)分", valueColor: .teal)
                }
                .padding(.horizontal).padding(.bottom, 8)

                if logs.isEmpty {
                    ContentUnavailableView("記録がありません", systemImage: "clock",
                                           description: Text("タスクを完了すると履歴が表示されます"))
                } else {
                    List {
                        ForEach(groupedLogs, id: \.0) { date, dayLogs in
                            Section(date) { ForEach(dayLogs) { log in HistoryLogRow(log: log) } }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("履歴")
            .searchable(text: $searchText, prompt: "タスク名・部屋名・メモで検索")
        }
    }
}

struct TaskFilterChip: View {
    let name: String; let isSelected: Bool; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Text(name).font(.caption).fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.teal.opacity(0.15) : Color(.systemGray6))
                .foregroundStyle(isSelected ? .teal : .secondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.teal : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

struct HistoryLogRow: View {
    let log: TaskLog
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(log.task?.title ?? "削除済みタスク").font(.subheadline).fontWeight(.medium)
                if let roomName = log.task?.room?.name {
                    Text(roomName).font(.caption).foregroundStyle(.secondary)
                }
                if !log.memo.isEmpty {
                    Text(log.memo).font(.caption).foregroundStyle(.secondary).italic()
                }
                if !log.partUsages.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(log.partUsages) { usage in
                            Text("\(usage.partName) ×\(usage.usedCount)")
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .foregroundStyle(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(log.completedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                if log.durationMinutes > 0 {
                    Text("\(log.durationMinutes)分").font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.teal.opacity(0.1)).foregroundStyle(.teal)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - ConsumablePartStockView

struct ConsumablePartStockView: View {
    @Query private var fixtures: [Fixture]
    @Environment(\.modelContext) private var context
    @State private var showAddRecord: ConsumablePart? = nil

    private var allParts: [ConsumablePart] {
        fixtures.flatMap { $0.parts }.sorted { $0.name < $1.name }
    }
    private var sortedParts: [ConsumablePart] {
        allParts.sorted {
            let s0 = $0.stockCount == 0 ? 0 : ($0.stockCount <= 1 ? 1 : 2)
            let s1 = $1.stockCount == 0 ? 0 : ($1.stockCount <= 1 ? 1 : 2)
            return s0 != s1 ? s0 < s1 : $0.name < $1.name
        }
    }

    var body: some View {
        List {
            if allParts.isEmpty {
                // メッセージをより具体的な案内に変更
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 40)).foregroundStyle(.secondary)
                        Text("消耗品パーツがありません")
                            .font(.headline)
                        Text("パーツを追加するには：\n「間取り」タブ → 部屋を選択 →「設備・器具」タブ → 設備を選択 → パーツを追加")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .listRowBackground(Color.clear)
            } else {
                let lowStock = sortedParts.filter { $0.stockCount <= 1 }
                if !lowStock.isEmpty {
                    Section {
                        ForEach(lowStock) { part in PartStockRow(part: part) { showAddRecord = part } }
                    } header: {
                        Label("在庫少・なし", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                    }
                }
                let normalStock = sortedParts.filter { $0.stockCount > 1 }
                if !normalStock.isEmpty {
                    Section("在庫あり") {
                        ForEach(normalStock) { part in PartStockRow(part: part) { showAddRecord = part } }
                    }
                }
            }
        }
        .navigationTitle("消耗品在庫").navigationBarTitleDisplayMode(.large)
        .sheet(item: $showAddRecord) { part in QuickStockAddSheet(part: part) }
    }
}

struct PartStockRow: View {
    let part: ConsumablePart; let onAddStock: () -> Void
    private var stockColor: Color {
        part.stockCount == 0 ? .red : (part.stockCount <= 1 ? .orange : .teal)
    }
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(stockColor.opacity(0.12)).frame(width: 40, height: 40)
                VStack(spacing: 0) {
                    Text("\(part.stockCount)").font(.system(size: 16, weight: .bold)).foregroundStyle(stockColor)
                    Text("個").font(.system(size: 9)).foregroundStyle(stockColor.opacity(0.8))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(part.name).font(.subheadline).fontWeight(.medium)
                if let fixtureName = part.fixture?.name {
                    Text(fixtureName).font(.caption).foregroundStyle(.secondary)
                }
                if let next = part.nextReplacementDate {
                    let days = Calendar.current.dateComponents([.day], from: .now, to: next).day ?? 0
                    if days < 0 { Text("交換期限 \(abs(days))日超過").font(.caption).foregroundStyle(.red) }
                    else if days <= 30 { Text("交換まで \(days)日").font(.caption).foregroundStyle(.orange) }
                }
            }
            Spacer()
            Button { onAddStock() } label: {
                Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(.teal)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}

struct QuickStockAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var part: ConsumablePart
    @State private var quantity = 1
    @State private var unitPrice: Int
    @State private var storeName: String
    @State private var purchasedAt = Date.now
    @State private var markAsReplaced = false

    init(part: ConsumablePart) {
        self.part = part
        _unitPrice = State(initialValue: part.unitPrice)
        _storeName = State(initialValue: part.purchaseStoreName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "shippingbox.fill").font(.title2).foregroundStyle(.teal)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(part.name).font(.headline)
                            if let fixtureName = part.fixture?.name {
                                Text(fixtureName).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text("現在 \(part.stockCount)個").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                Section("購入数量") {
                    Stepper("購入数: \(quantity)個", value: $quantity, in: 1...99)
                    Text("購入後の在庫: \(part.stockCount + quantity)個")
                        .font(.caption).foregroundStyle(.teal)
                }
                Section("購入情報") {
                    DatePicker("購入日", selection: $purchasedAt, displayedComponents: .date)
                    TextField("購入店名（例: Amazon）", text: $storeName)
                    LabeledContent("単価") {
                        TextField("円", value: $unitPrice, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    if unitPrice > 0 { LabeledContent("合計", value: "¥\((unitPrice * quantity).formatted())") }
                }
                Section {
                    Toggle("今回購入分を交換済みとして記録", isOn: $markAsReplaced).tint(.teal)
                    if markAsReplaced {
                        Text("最終交換日が \(purchasedAt.formatted(date: .abbreviated, time: .omitted)) に更新されます")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("在庫を追加").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") { saveStock() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func saveStock() {
        part.stockCount += quantity
        let record = PurchaseRecord(quantity: quantity, unitPrice: unitPrice, storeName: storeName, memo: "在庫補充")
        record.purchasedAt = purchasedAt
        record.part = part
        context.insert(record)
        if !storeName.isEmpty { part.purchaseStoreName = storeName }
        if unitPrice > 0 { part.unitPrice = unitPrice }
        if markAsReplaced { part.lastReplacedAt = purchasedAt }
        try? context.save()
        dismiss()
    }
}
