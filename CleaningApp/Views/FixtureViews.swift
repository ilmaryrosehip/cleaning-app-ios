import SwiftUI
import SwiftData

struct FixtureListView: View {
    @Bindable var room: Room
    @Environment(\.modelContext) private var context
    @State private var showAddFixture = false
    @Query private var allFixtures: [Fixture]
    private var sortedFixtures: [Fixture] {
        allFixtures.filter { $0.room?.id == room.id }.sorted { $0.name < $1.name }
    }
    init(room: Room) {
        self.room = room
        _allFixtures = Query(filter: #Predicate<Fixture> { _ in true })
    }

    var body: some View {
        List {
            if sortedFixtures.isEmpty {
                ContentUnavailableView(LocalizationManager.shared.language == .japanese ? "設備が登録されていません" : "No fixtures registered", systemImage: "wrench.and.screwdriver",
                                       description: Text(LocalizationManager.shared.language == .japanese ? "＋ボタンから設備を追加しましょう" : "Tap + to add a fixture"))
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
        .navigationTitle(LocalizationManager.shared.language == .japanese ? "\(room.name)の設備" : "\(room.name) Fixtures").navigationBarTitleDisplayMode(.large)
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
                Text(LocalizationManager.shared.language == .japanese ? "パーツ \(fixture.parts.count)件" : "\(fixture.parts.count) parts").font(.caption).foregroundStyle(.secondary)
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
            Section(LocalizationManager.shared.language == .japanese ? "設備情報" : "Fixture Info") {
                if !fixture.makerName.isEmpty { LabeledContent(LocalizationManager.shared.language == .japanese ? "メーカー" : "Maker", value: fixture.makerName) }
                if !fixture.modelNumber.isEmpty { LabeledContent(L(.partNumber), value: fixture.modelNumber) }
                if let installed = fixture.installedAt {
                    LabeledContent(LocalizationManager.shared.language == .japanese ? "設置日" : "Installed", value: installed.formatted(date: .abbreviated, time: .omitted))
                }
                if !fixture.memo.isEmpty { Text(fixture.memo).font(.subheadline).foregroundStyle(.secondary) }
            }
            Section(LocalizationManager.shared.language == .japanese ? "消耗品パーツ" : "Consumable Parts") {
                ForEach(fixture.parts.sorted { $0.name < $1.name }) { part in
                    NavigationLink(destination: ConsumablePartDetailView(part: part)) { ConsumablePartRow(part: part) }
                }
                .onDelete { offsets in
                    let sorted = fixture.parts.sorted { $0.name < $1.name }
                    for i in offsets { context.delete(sorted[i]) }
                    try? context.save()
                }
                Button { showAddPart = true } label: { Label(L(.addPart), systemImage: "plus") }
            }
        }
        .navigationTitle(fixture.name).navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showEditFixture = true } label: { Text(L(.edit)) }
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
                        if days < 0 { Text(LocalizationManager.shared.language == .japanese ? "交換期限 \(abs(days))日超過" : "\(abs(days))d overdue").foregroundStyle(.red) }
                        else if days == 0 { Text(LocalizationManager.shared.language == .japanese ? "本日交換推奨" : "Replace today").foregroundStyle(.orange) }
                        else { Text(LocalizationManager.shared.language == .japanese ? "次回交換まで \(days)日" : "\(days)d until replacement").foregroundStyle(.secondary) }
                    }.font(.caption)
                } else if part.lastReplacedAt == nil {
                    Text(LocalizationManager.shared.language == .japanese ? "未交換" : "Not replaced").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if part.stockCount > 0 {
                    Text(LocalizationManager.shared.language == .japanese ? "在庫 \(part.stockCount)個" : "Stock: \(part.stockCount)").font(.caption2)
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
            Section(LocalizationManager.shared.language == .japanese ? "パーツ情報" : "Part Info") {
                if !part.partNumber.isEmpty { LabeledContent(LocalizationManager.shared.language == .japanese ? "品番" : "Part No.", value: part.partNumber) }
                if part.replacementMonths > 0 { LabeledContent("交換目安", value: LocalizationManager.shared.language == .japanese ? "\(part.replacementMonths)ヶ月ごと" : "Every \(part.replacementMonths) months") }
                if let last = part.lastReplacedAt {
                    LabeledContent(L(.lastReplaced), value: last.formatted(date: .abbreviated, time: .omitted))
                }
                if let next = part.nextReplacementDate {
                    LabeledContent(LocalizationManager.shared.language == .japanese ? "次回推奨" : "Next Due", value: next.formatted(date: .abbreviated, time: .omitted))
                }
                LabeledContent(LocalizationManager.shared.language == .japanese ? "在庫数" : "Stock", value: LocalizationManager.shared.language == .japanese ? "\(part.stockCount)個" : "\(part.stockCount)")
                if !part.memo.isEmpty { Text(part.memo).font(.subheadline).foregroundStyle(.secondary) }
            }
            Section(L(.purchaseInfo)) {
                if !part.purchaseStoreName.isEmpty { LabeledContent(L(.storeName), value: part.purchaseStoreName) }
                if part.unitPrice > 0 { LabeledContent(L(.unitPrice), value: "¥\(part.unitPrice.formatted())") }
                if !part.purchaseURL.isEmpty {
                    Link(destination: URL(string: part.purchaseURL) ?? URL(string: "https://")!) {
                        Label(L(.openLink), systemImage: "arrow.up.right.square").font(.subheadline)
                    }
                }
            }
            Section {
                if sortedRecords.isEmpty {
                    Text(LocalizationManager.shared.language == .japanese ? "購入履歴がありません" : "No purchase history").font(.subheadline).foregroundStyle(.tertiary)
                } else {
                    ForEach(sortedRecords) { record in PurchaseRecordRow(record: record) }
                        .onDelete { offsets in
                            for i in offsets { context.delete(sortedRecords[i]) }
                            try? context.save()
                        }
                }
                Button { showAddRecord = true } label: { Label(LocalizationManager.shared.language == .japanese ? "購入を記録" : "Record Purchase", systemImage: "cart.badge.plus") }
            } header: {
                HStack {
                    Text(LocalizationManager.shared.language == .japanese ? "購入履歴" : "Purchase History")
                    Spacer()
                    if !sortedRecords.isEmpty {
                        Text(LocalizationManager.shared.language == .japanese ? "合計 ¥\(sortedRecords.reduce(0) { $0 + $1.totalPrice }.formatted())" : "Total: ¥\(sortedRecords.reduce(0) { $0 + $1.totalPrice }.formatted())")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(part.name).navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { Button { showEditPart = true } label: { Text(L(.edit)) } }
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
                Text(LocalizationManager.shared.language == .japanese ? "×\(record.quantity)個 @¥\(record.unitPrice.formatted())" : "×\(record.quantity) @¥\(record.unitPrice.formatted())").font(.caption2).foregroundStyle(.secondary)
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
                    Section(LocalizationManager.shared.language == .japanese ? "よくある設備（タップで選択）" : "Common Fixtures (tap to select)") {
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
                Section(L(.fixture)) { TextField(LocalizationManager.shared.language == .japanese ? "例: 浴室乾燥機" : "e.g. Bath dryer", text: $name) }
                Section(L(.roomIcon)) {
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
                Section(LocalizationManager.shared.language == .japanese ? "メーカー・型番（任意）" : "Maker & Model (Optional)") {
                    TextField(LocalizationManager.shared.language == .japanese ? "メーカー名" : "Maker", text: $makerName)
                    TextField(LocalizationManager.shared.language == .japanese ? "型番" : "Model No.", text: $modelNumber)
                }
                if !suggestedPresets.isEmpty,
                   let preset = suggestedPresets.first(where: { $0.name == name }),
                   !preset.parts.isEmpty {
                    Section(L(.addPart)) {
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
                Section(L(.memo)) { TextField(LocalizationManager.shared.language == .japanese ? "任意" : "Optional", text: $memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle(L(.addFixture)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L(.add)) { saveFixture() }
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
                Section(L(.fixture)) { TextField(L(.fixture), text: $fixture.name) }
                Section(LocalizationManager.shared.language == .japanese ? "メーカー・型番" : "Maker & Model") {
                    TextField(LocalizationManager.shared.language == .japanese ? "メーカー名" : "Maker", text: $fixture.makerName)
                    TextField(LocalizationManager.shared.language == .japanese ? "型番" : "Model No.", text: $fixture.modelNumber)
                }
                Section(LocalizationManager.shared.language == .japanese ? "設置日" : "Installed Date") {
                    DatePicker(LocalizationManager.shared.language == .japanese ? "設置日" : "Date", selection: Binding(
                        get: { fixture.installedAt ?? .now },
                        set: { fixture.installedAt = $0 }
                    ), displayedComponents: .date)
                }
                Section(L(.memo)) { TextField(LocalizationManager.shared.language == .japanese ? "任意" : "Optional", text: $fixture.memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle(LocalizationManager.shared.language == .japanese ? "設備を編集" : "Edit Fixture").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L(.save)) { try? context.save(); dismiss() }.fontWeight(.semibold)
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
                Section(L(.partName)) { TextField(LocalizationManager.shared.language == .japanese ? "例: 排気フィルター" : "e.g. Exhaust filter", text: $name) }
                Section(LocalizationManager.shared.language == .japanese ? "品番・交換サイクル" : "Part No. & Cycle") {
                    TextField(LocalizationManager.shared.language == .japanese ? "品番（任意）" : "Part No. (optional)", text: $partNumber)
                    Stepper(replacementMonths == 0 ? LocalizationManager.shared.language == .japanese ? LocalizationManager.shared.language == .japanese ? "交換サイクル: 都度" : "Cycle: As needed" : "Cycle: As needed" : LocalizationManager.shared.language == .japanese ? "交換サイクル: \(replacementMonths)ヶ月" : "Cycle: \(replacementMonths) months",
                            value: $replacementMonths, in: 0...120, step: 1)
                }
                Section(L(.purchaseInfo)) {
                    TextField(LocalizationManager.shared.language == .japanese ? "購入店名（例: Amazon）" : "Store (e.g. Amazon)", text: $purchaseStoreName)
                    TextField(L(.purchaseURL), text: $purchaseURL).keyboardType(.URL).autocorrectionDisabled()
                    LabeledContent(L(.unitPrice)) {
                        TextField(LocalizationManager.shared.language == .japanese ? "円" : "¥", value: $unitPrice, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
                Section(L(.memo)) { TextField(LocalizationManager.shared.language == .japanese ? "任意" : "Optional", text: $memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle(L(.addPart)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L(.add)) {
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
                Section(L(.partName)) { TextField(L(.partName), text: $part.name) }
                Section(LocalizationManager.shared.language == .japanese ? "品番・交換サイクル" : "Part No. & Cycle") {
                    TextField(LocalizationManager.shared.language == .japanese ? "品番" : "Part No.", text: $part.partNumber)
                    Stepper(part.replacementMonths == 0 ? "交換サイクル: 都度" : LocalizationManager.shared.language == .japanese ? "交換サイクル: \(part.replacementMonths)ヶ月" : "Cycle: \(part.replacementMonths) months",
                            value: $part.replacementMonths, in: 0...120)
                }
                Section(L(.lastReplacedAt)) {
                    DatePicker(L(.lastReplacedAt), selection: Binding(
                        get: { part.lastReplacedAt ?? .now },
                        set: { part.lastReplacedAt = $0 }
                    ), displayedComponents: .date)
                    Toggle(LocalizationManager.shared.language == .japanese ? "交換済みとして記録" : "Mark as replaced", isOn: Binding(
                        get: { part.lastReplacedAt != nil },
                        set: { part.lastReplacedAt = $0 ? .now : nil }
                    )).tint(.teal)
                }
                Section(L(.stockCount)) { Stepper(LocalizationManager.shared.language == .japanese ? "在庫: \(part.stockCount)個" : "Stock: \(part.stockCount)", value: $part.stockCount, in: 0...99) }
                Section(L(.purchaseInfo)) {
                    TextField(LocalizationManager.shared.language == .japanese ? "購入店名" : "Store name", text: $part.purchaseStoreName)
                    TextField(L(.purchaseURL), text: $part.purchaseURL).keyboardType(.URL).autocorrectionDisabled()
                    LabeledContent(L(.unitPrice)) {
                        TextField(LocalizationManager.shared.language == .japanese ? "円" : "¥", value: $part.unitPrice, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
                Section("メモ") { TextField(LocalizationManager.shared.language == .japanese ? "任意" : "Optional", text: $part.memo, axis: .vertical).lineLimit(3) }
            }
            .navigationTitle(part.name).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L(.save)) { try? context.save(); dismiss() }.fontWeight(.semibold)
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
                Section(L(.purchaseInfo)) {
                    DatePicker(L(.purchaseDate), selection: $purchasedAt, displayedComponents: .date)
                    Stepper(LocalizationManager.shared.language == .japanese ? "数量: \(quantity)個" : "Qty: \(quantity)", value: $quantity, in: 1...99)
                    LabeledContent(L(.unitPrice)) {
                        TextField(LocalizationManager.shared.language == .japanese ? "円" : "¥", value: $unitPrice, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    TextField(LocalizationManager.shared.language == .japanese ? "購入店名" : "Store name", text: $storeName)
                }
                Section {
                    Toggle(LocalizationManager.shared.language == .japanese ? "最終交換日を今日に更新" : "Update last replaced date", isOn: $markAsReplaced).tint(.teal)
                    if markAsReplaced {
                        Text(LocalizationManager.shared.language == .japanese ? "交換日: \(purchasedAt.formatted(date: .abbreviated, time: .omitted))" : "Replaced: \(purchasedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section(L(.total)) {
                    LabeledContent(LocalizationManager.shared.language == .japanese ? "合計金額" : "Total", value: "¥\((unitPrice * quantity).formatted())")
                }
                Section("メモ") { TextField(LocalizationManager.shared.language == .japanese ? "任意" : "Optional", text: $memo, axis: .vertical).lineLimit(2) }
            }
            .navigationTitle(LocalizationManager.shared.language == .japanese ? "購入を記録" : "Record Purchase").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationManager.shared.language == .japanese ? "記録" : "Record") {
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
