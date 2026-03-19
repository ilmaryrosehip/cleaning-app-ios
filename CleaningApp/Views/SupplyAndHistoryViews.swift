import SwiftUI
import SwiftData

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
            }
            Spacer()
            Text(supply.stockStatus.rawValue).font(.caption).fontWeight(.medium)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(statusColor.opacity(0.12)).foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
    }
}

struct SupplyDetailView: View {
    @Bindable var supply: Supply
    @Environment(\.modelContext) private var context
    @State private var showAddPurchase = false

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
        .sheet(isPresented: $showAddPurchase) { AddPurchaseItemSheet(supply: supply) }
    }
}

struct PurchaseItemRow: View {
    @Bindable var item: PurchaseItem
    @Environment(\.modelContext) private var context
    var body: some View {
        HStack {
            Button {
                item.markAsPurchased()
                try? context.save()
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

struct AddSupplySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var category: SupplyCategory = .tool
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
                Section("メモ") { TextField("任意", text: $memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle("用品を追加").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let s = Supply(name: name, category: category, memo: memo)
                        context.insert(s); try? context.save(); dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty).fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
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

struct HistoryView: View {
    let home: Home
    @State private var selectedPeriod: HistoryPeriod = .week

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

    private var logs: [TaskLog] {
        home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }
            .filter { $0.completedAt >= selectedPeriod.startDate }
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
                .pickerStyle(.segmented).padding(.horizontal).padding(.vertical, 12)

                HStack(spacing: 12) {
                    MetricCard(label: "完了タスク", value: "\(logs.count)", valueColor: .teal)
                    MetricCard(label: "合計時間", value: "\(totalMinutes)分", valueColor: .teal)
                }
                .padding(.horizontal).padding(.bottom, 12)

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
        }
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
