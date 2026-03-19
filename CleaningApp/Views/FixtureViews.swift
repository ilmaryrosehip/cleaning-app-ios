import SwiftUI
import SwiftData

struct FixtureListView: View {
    @Bindable var room: Room
    @Environment(\.modelContext) private var context
    @State private var showAddFixture = false
    private var sortedFixtures: [Fixture] { room.fixtures.sorted { $0.name < $1.name } }

    var body: some View {
        List {
            if sortedFixtures.isEmpty {
                ContentUnavailableView("設備が登録されていません", systemImage: "wrench.and.screwdriver",
                                       description: Text("＋ボタンから設備を追加しましょう"))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(sortedFixtures) { fixture in
                    NavigationLink(destination: FixtureDetailView(fixture: fixture)) { FixtureRow(fixture: fixture) }
                }
                .onDelete { offsets in
                    for i in offsets { context.delete(sortedFixtures[i]) }
                    try? context.save()
                }
            }
        }
        .navigationTitle("\(room.name)の設備").navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddFixture = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddFixture) { AddFixtureSheet(room: room) }
    }
}

struct FixtureRow: View {
    let fixture: Fixture
    private var worstStatus: ReplacementStatus {
        let s = fixture.parts.map { $0.replacementStatus }
        if s.contains(.overdue) { return .overdue }
        if s.contains(.soon)    { return .soon }
        if s.contains(.ok)      { return .ok }
        return .unknown
    }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: fixture.icon).font(.title3).foregroundStyle(.teal).frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(fixture.name).font(.subheadline).fontWeight(.medium)
                HStack(spacing: 6) {
                    if !fixture.makerName.isEmpty { Text(fixture.makerName).font(.caption).foregroundStyle(.secondary) }
                    if !fixture.modelNumber.isEmpty { Text(fixture.modelNumber).font(.caption).foregroundStyle(.secondary) }
                }
                Text("パーツ \(fixture.parts.count)件").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            StatusDot(status: worstStatus)
        }
    }
}

struct FixtureDetailView: View {
    @Bindable var fixture: Fixture
    @Environment(\.modelContext) private var context
    @State private var showAddPart = false
    @State private var showEditFixture = false

    var body: some View {
        List {
            Section("設備情報") {
                if !fixture.makerName.isEmpty { LabeledContent("メーカー", value: fixture.makerName) }
                if !fixture.modelNumber.isEmpty { LabeledContent("型番", value: fixture.modelNumber) }
                if let installed = fixture.installedAt {
                    LabeledContent("設置日", value: installed.formatted(date: .abbreviated, time: .omitted))
                }
                if !fixture.memo.isEmpty { Text(fixture.memo).font(.subheadline).foregroundStyle(.secondary) }
            }
            Section("消耗品パーツ") {
                ForEach(fixture.parts.sorted { $0.name < $1.name }) { part in
                    NavigationLink(destination: ConsumablePartDetailView(part: part)) { ConsumablePartRow(part: part) }
                }
                .onDelete { offsets in
                    let sorted = fixture.parts.sorted { $0.name < $1.name }
                    for i in offsets { context.delete(sorted[i]) }
                    try? context.save()
                }
                Button { showAddPart = true } label: { Label("パーツを追加", systemImage: "plus") }
            }
        }
        .navigationTitle(fixture.name).navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showEditFixture = true } label: { Text("編集") }
            }
        }
        .sheet(isPresented: $showAddPart) { AddConsumablePartSheet(fixture: fixture) }
        .sheet(isPresented: $showEditFixture) { EditFixtureSheet(fixture: fixture) }
    }
}

struct ConsumablePartRow: View {
    let part: ConsumablePart
    var body: some View {
        HStack(spacing: 12) {
            StatusDot(status: part.replacementStatus)
            VStack(alignment: .leading, spacing: 3) {
                Text(part.name).font(.subheadline).fontWeight(.medium)
                if let next = part.nextReplacementDate {
                    let days = Calendar.current.dateComponents([.day], from: .now, to: next).day ?? 0
                    Group {
                        if days < 0 { Text("交換期限 \(abs(days))日超過").foregroundStyle(.red) }
                        else if days == 0 { Text("本日交換推奨").foregroundStyle(.orange) }
                        else { Text("次回交換まで \(days)日").foregroundStyle(.secondary) }
                    }.font(.caption)
                } else if part.lastReplacedAt == nil {
                    Text("未交換").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if part.stockCount > 0 {
                    Text("在庫 \(part.stockCount)個").font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.teal.opacity(0.1)).foregroundStyle(.teal).clipShape(Capsule())
                }
                if part.unitPrice > 0 {
                    Text("¥\(part.unitPrice.formatted())").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ConsumablePartDetailView: View {
    @Bindable var part: ConsumablePart
    @Environment(\.modelContext) private var context
    @State private var showAddRecord = false
    @State private var showEditPart = false
    private var sortedRecords: [PurchaseRecord] { part.purchaseRecords.sorted { $0.purchasedAt > $1.purchasedAt } }

    var body: some View {
        List {
            Section("パーツ情報") {
                if !part.partNumber.isEmpty { LabeledContent("品番", value: part.partNumber) }
                if part.replacementMonths > 0 { LabeledContent("交換目安", value: "\(part.replacementMonths)ヶ月ごと") }
                if let last = part.lastReplacedAt {
                    LabeledContent("最終交換", value: last.formatted(date: .abbreviated, time: .omitted))
                }
                if let next = part.nextReplacementDate {
                    LabeledContent("次回推奨", value: next.formatted(date: .abbreviated, time: .omitted))
                }
                LabeledContent("在庫数", value: "\(part.stockCount)個")
                if !part.memo.isEmpty { Text(part.memo).font(.subheadline).foregroundStyle(.secondary) }
            }
            Section("購入先") {
                if !part.purchaseStoreName.isEmpty { LabeledContent("購入店", value: part.purchaseStoreName) }
                if part.unitPrice > 0 { LabeledContent("単価", value: "¥\(part.unitPrice.formatted())") }
                if !part.purchaseURL.isEmpty {
                    Link(destination: URL(string: part.purchaseURL) ?? URL(string: "https://")!) {
                        Label("購入ページを開く", systemImage: "arrow.up.right.square").font(.subheadline)
                    }
                }
            }
            Section {
                if sortedRecords.isEmpty {
                    Text("購入履歴がありません").font(.subheadline).foregroundStyle(.tertiary)
                } else {
                    ForEach(sortedRecords) { record in PurchaseRecordRow(record: record) }
                        .onDelete { offsets in
                            for i in offsets { context.delete(sortedRecords[i]) }
                            try? context.save()
                        }
                }
                Button { showAddRecord = true } label: { Label("購入を記録", systemImage: "cart.badge.plus") }
            } header: {
                HStack {
                    Text("購入履歴")
                    Spacer()
                    if !sortedRecords.isEmpty {
                        Text("合計 ¥\(sortedRecords.reduce(0) { $0 + $1.totalPrice }.formatted())")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(part.name).navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { Button { showEditPart = true } label: { Text("編集") } }
        }
        .sheet(isPresented: $showAddRecord) { AddPurchaseRecordSheet(part: part) }
        .sheet(isPresented: $showEditPart) { EditConsumablePartSheet(part: part) }
    }
}

struct PurchaseRecordRow: View {
    let record: PurchaseRecord
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(record.purchasedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline).fontWeight(.medium)
                HStack(spacing: 6) {
                    if !record.storeName.isEmpty { Text(record.storeName).font(.caption).foregroundStyle(.secondary) }
                    if !record.memo.isEmpty { Text(record.memo).font(.caption).foregroundStyle(.secondary) }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("¥\(record.totalPrice.formatted())").font(.subheadline).fontWeight(.medium)
                Text("×\(record.quantity)個 @¥\(record.unitPrice.formatted())").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

struct AddFixtureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let room: Room
    @State private var name = ""
    @State private var icon = "wrench.and.screwdriver"
    @State private var makerName = ""
    @State private var modelNumber = ""
    @State private var memo = ""
    @State private var selectedPresetParts: Set<String> = []
    private let iconOptions = [
        "wind","flame","arrow.up.to.line","drop.triangle",
        "refrigerator","washer","air.conditioner.horizontal",
        "aqi.medium","lightbulb","wrench.and.screwdriver","shower","bathtub","toilet","sink",
    ]
    private var suggestedPresets: [FixturePreset] { FixturePreset.byRoomIcon[room.icon] ?? [] }

    var body: some View {
        NavigationStack {
            Form {
                if !suggestedPresets.isEmpty {
                    Section("よくある設備（タップで選択）") {
                        ForEach(suggestedPresets) { preset in
                            Button {
                                name = preset.name; icon = preset.icon
                                selectedPresetParts = Set(preset.parts.map { $0.id })
                            } label: {
                                HStack {
                                    Image(systemName: preset.icon).foregroundStyle(.teal).frame(width: 24)
                                    Text(preset.name).foregroundStyle(.primary)
                                    Spacer()
                                    if name == preset.name { Image(systemName: "checkmark").foregroundStyle(.teal) }
                                }
                            }
                        }
                    }
                }
                Section("設備名") { TextField("例: 浴室乾燥機", text: $name) }
                Section("アイコン") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
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
                Section("メーカー・型番（任意）") {
                    TextField("メーカー名", text: $makerName)
                    TextField("型番", text: $modelNumber)
                }
                if !suggestedPresets.isEmpty,
                   let preset = suggestedPresets.first(where: { $0.name == name }),
                   !preset.parts.isEmpty {
                    Section("消耗品パーツを追加") {
                        ForEach(preset.parts) { part in
                            HStack {
                                Text(part.name).font(.subheadline)
                                Spacer()
                                if selectedPresetParts.contains(part.id) {
                                    Image(systemName: "checkmark").foregroundStyle(.teal)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedPresetParts.contains(part.id) { selectedPresetParts.remove(part.id) }
                                else { selectedPresetParts.insert(part.id) }
                            }
                        }
                    }
                }
                Section("メモ") { TextField("任意", text: $memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle("設備を追加").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") { saveFixture() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty).fontWeight(.semibold)
                }
            }
        }
    }

    private func saveFixture() {
        let fixture = Fixture(name: name, icon: icon, memo: memo, makerName: makerName, modelNumber: modelNumber)
        fixture.room = room
        context.insert(fixture)
        if let preset = suggestedPresets.first(where: { $0.name == name }) {
            for p in preset.parts where selectedPresetParts.contains(p.id) {
                let part = ConsumablePart(name: p.name, replacementMonths: p.replacementMonths, memo: p.memo)
                part.fixture = fixture
                context.insert(part)
            }
        }
        try? context.save()
        dismiss()
    }
}

struct EditFixtureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var fixture: Fixture
    var body: some View {
        NavigationStack {
            Form {
                Section("設備名") { TextField("設備名", text: $fixture.name) }
                Section("メーカー・型番") {
                    TextField("メーカー名", text: $fixture.makerName)
                    TextField("型番", text: $fixture.modelNumber)
                }
                Section("設置日") {
                    DatePicker("設置日", selection: Binding(
                        get: { fixture.installedAt ?? .now },
                        set: { fixture.installedAt = $0 }
                    ), displayedComponents: .date)
                }
                Section("メモ") { TextField("任意", text: $fixture.memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle("設備を編集").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { try? context.save(); dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddConsumablePartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let fixture: Fixture
    @State private var name = ""
    @State private var partNumber = ""
    @State private var replacementMonths = 12
    @State private var purchaseStoreName = ""
    @State private var purchaseURL = ""
    @State private var unitPrice = 0
    @State private var memo = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("パーツ名") { TextField("例: 排気フィルター", text: $name) }
                Section("品番・交換サイクル") {
                    TextField("品番（任意）", text: $partNumber)
                    Stepper(replacementMonths == 0 ? "交換サイクル: 都度" : "交換サイクル: \(replacementMonths)ヶ月",
                            value: $replacementMonths, in: 0...120, step: 1)
                }
                Section("購入先") {
                    TextField("購入店名（例: Amazon）", text: $purchaseStoreName)
                    TextField("購入URL（任意）", text: $purchaseURL).keyboardType(.URL).autocorrectionDisabled()
                    LabeledContent("単価") {
                        TextField("円", value: $unitPrice, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
                Section("メモ") { TextField("任意", text: $memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle("パーツを追加").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let part = ConsumablePart(name: name, partNumber: partNumber,
                                                   replacementMonths: replacementMonths,
                                                   purchaseURL: purchaseURL, purchaseStoreName: purchaseStoreName,
                                                   unitPrice: unitPrice, memo: memo)
                        part.fixture = fixture; context.insert(part); try? context.save(); dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty).fontWeight(.semibold)
                }
            }
        }
    }
}

struct EditConsumablePartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var part: ConsumablePart
    var body: some View {
        NavigationStack {
            Form {
                Section("パーツ名") { TextField("パーツ名", text: $part.name) }
                Section("品番・交換サイクル") {
                    TextField("品番", text: $part.partNumber)
                    Stepper(part.replacementMonths == 0 ? "交換サイクル: 都度" : "交換サイクル: \(part.replacementMonths)ヶ月",
                            value: $part.replacementMonths, in: 0...120)
                }
                Section("最終交換日") {
                    DatePicker("最終交換日", selection: Binding(
                        get: { part.lastReplacedAt ?? .now },
                        set: { part.lastReplacedAt = $0 }
                    ), displayedComponents: .date)
                    Toggle("交換済みとして記録", isOn: Binding(
                        get: { part.lastReplacedAt != nil },
                        set: { part.lastReplacedAt = $0 ? .now : nil }
                    )).tint(.teal)
                }
                Section("在庫数") { Stepper("在庫: \(part.stockCount)個", value: $part.stockCount, in: 0...99) }
                Section("購入先") {
                    TextField("購入店名", text: $part.purchaseStoreName)
                    TextField("購入URL", text: $part.purchaseURL).keyboardType(.URL).autocorrectionDisabled()
                    LabeledContent("単価") {
                        TextField("円", value: $part.unitPrice, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
                Section("メモ") { TextField("任意", text: $part.memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle(part.name).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { try? context.save(); dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}

struct AddPurchaseRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let part: ConsumablePart
    @State private var purchasedAt = Date.now
    @State private var quantity = 1
    @State private var unitPrice: Int
    @State private var storeName: String
    @State private var memo = ""
    @State private var markAsReplaced = true

    init(part: ConsumablePart) {
        self.part = part
        _unitPrice = State(initialValue: part.unitPrice)
        _storeName = State(initialValue: part.purchaseStoreName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("購入情報") {
                    DatePicker("購入日", selection: $purchasedAt, displayedComponents: .date)
                    Stepper("数量: \(quantity)個", value: $quantity, in: 1...99)
                    LabeledContent("単価") {
                        TextField("円", value: $unitPrice, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    TextField("購入店名", text: $storeName)
                }
                Section {
                    Toggle("最終交換日を今日に更新", isOn: $markAsReplaced).tint(.teal)
                    if markAsReplaced {
                        Text("交換日: \(purchasedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("合計") {
                    LabeledContent("合計金額", value: "¥\((unitPrice * quantity).formatted())")
                }
                Section("メモ") { TextField("任意", text: $memo, axis: .vertical).lineLimit(2) }
            }
            .navigationTitle("購入を記録").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("記録") {
                        let record = PurchaseRecord(quantity: quantity, unitPrice: unitPrice,
                                                     storeName: storeName, memo: memo)
                        record.purchasedAt = purchasedAt
                        record.part = part
                        context.insert(record)
                        part.stockCount += quantity
                        if markAsReplaced { part.lastReplacedAt = purchasedAt }
                        try? context.save()
                        dismiss()
                    }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct StatusDot: View {
    let status: ReplacementStatus
    var color: Color {
        switch status {
        case .ok:      return .teal
        case .soon:    return .orange
        case .overdue: return .red
        case .unknown: return Color(.systemGray3)
        }
    }
    var body: some View { Circle().fill(color).frame(width: 8, height: 8) }
}
