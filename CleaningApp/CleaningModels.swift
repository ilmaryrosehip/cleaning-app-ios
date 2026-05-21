import Foundation
import SwiftData

@Model final class Home {
    var id: UUID; var name: String; var floorPlanNote: String; var createdAt: Date
    @Relationship(deleteRule: .cascade) var rooms: [Room] = []
    init(name: String, floorPlanNote: String = "") {
        self.id = UUID(); self.name = name; self.floorPlanNote = floorPlanNote; self.createdAt = .now
    }
}

@Model final class Room {
    var id: UUID; var name: String; var icon: String; var sortOrder: Int; var home: Home?
    @Relationship(deleteRule: .cascade) var tasks: [CleaningTask] = []
    @Relationship(deleteRule: .cascade) var fixtures: [Fixture] = []
    init(name: String, icon: String = "house", sortOrder: Int = 0) {
        self.id = UUID(); self.name = name; self.icon = icon; self.sortOrder = sortOrder
    }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sun=0,mon,tue,wed,thu,fri,sat
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .sun: return "日"; case .mon: return "月"; case .tue: return "火"
        case .wed: return "水"; case .thu: return "木"; case .fri: return "金"; case .sat: return "土"
        }
    }
}

@Model final class CleaningTask {
    var id: UUID; var title: String; var notes: String; var frequency: Frequency
    var intervalDays: Int; var weekdays: [Int]; var nextDueDate: Date
    var estimatedMinutes: Int; var isActive: Bool; var room: Room?
    @Relationship(deleteRule: .cascade) var logs: [TaskLog] = []
    @Relationship var supplies: [Supply] = []
    @Relationship var fixtures: [Fixture] = []
    init(title: String, frequency: Frequency = .weekly, weekdays: [Int] = [],
         intervalDays: Int = 7, nextDueDate: Date = .now, estimatedMinutes: Int = 15, notes: String = "") {
        self.id=UUID(); self.title=title; self.notes=notes; self.frequency=frequency
        self.weekdays=weekdays; self.intervalDays=intervalDays; self.nextDueDate=nextDueDate
        self.estimatedMinutes=estimatedMinutes; self.isActive=true
    }
    func markCompleted(duration: Int=0, memo: String="") -> TaskLog {
        let log=TaskLog(task:self,durationMinutes:duration,memo:memo); logs.append(log)
        nextDueDate=frequency.nextDate(from:.now,intervalDays:intervalDays,weekdays:weekdays); return log
    }
    var isOverdue: Bool { nextDueDate < Calendar.current.startOfDay(for:.now) }
    var isDueToday: Bool { Calendar.current.isDateInToday(nextDueDate) }
    var weekdaysLabel: String {
        guard !weekdays.isEmpty else { return "" }
        return weekdays.sorted().compactMap{Weekday(rawValue:$0)?.label}.joined(separator:"・")
    }
}

enum Frequency: String, Codable, CaseIterable {
    case daily="daily",weekly="weekly",biweekly="biweekly",monthly="monthly",custom="custom"
    var label: String {
        let isJP = (UserDefaults.standard.string(forKey:"app_language") ?? "ja") == "ja"
        switch self {
        case .daily: return isJP ? "毎日":"Daily"; case .weekly: return isJP ? "毎週":"Weekly"
        case .biweekly: return isJP ? "隔週":"Biweekly"; case .monthly: return isJP ? "毎月":"Monthly"
        case .custom: return isJP ? "カスタム":"Custom"
        }
    }
    func nextDate(from base: Date, intervalDays: Int, weekdays: [Int]=[]) -> Date {
        let cal=Calendar.current
        switch self {
        case .daily: return cal.date(byAdding:.day,value:1,to:base) ?? base
        case .monthly: return cal.date(byAdding:.month,value:1,to:base) ?? base
        case .custom: return cal.date(byAdding:.day,value:max(1,intervalDays),to:base) ?? base
        case .weekly,.biweekly:
            let mult=self == .biweekly ? 2:1
            guard !weekdays.isEmpty else { return cal.date(byAdding:.day,value:7*mult,to:base) ?? base }
            let sorted=weekdays.sorted()
            for offset in 1...(7*mult+6) {
                guard let c=cal.date(byAdding:.day,value:offset,to:base) else { continue }
                if sorted.contains(cal.component(.weekday,from:c)-1) { return c }
            }
            return cal.date(byAdding:.day,value:7*mult,to:base) ?? base
        }
    }
    var supportsWeekdays: Bool { self == .weekly || self == .biweekly }
}

@Model final class TaskLog {
    var id: UUID; var completedAt: Date; var durationMinutes: Int; var memo: String
    var task: CleaningTask?; var photoDataList: [Data] = []
    @Relationship(deleteRule: .cascade) var partUsages: [TaskPartUsage] = []
    init(task: CleaningTask?=nil, durationMinutes: Int=0, memo: String="") {
        self.id=UUID(); self.completedAt = .now; self.durationMinutes=durationMinutes; self.memo=memo; self.task=task
    }
}

@Model final class TaskPartUsage {
    var id: UUID; var usedCount: Int; var partName: String; var log: TaskLog?; var part: ConsumablePart?
    init(part: ConsumablePart, usedCount: Int) {
        self.id=UUID(); self.usedCount=usedCount; self.partName=part.name; self.part=part
    }
}

@Model final class Supply {
    var id: UUID; var name: String; var category: SupplyCategory; var stockStatus: StockStatus
    var lastUsedAt: Date?; var memo: String; var purchaseStoreName: String; var purchaseURL: String
    @Relationship(deleteRule: .cascade) var purchaseItems: [PurchaseItem] = []
    @Relationship(inverse: \CleaningTask.supplies) var tasks: [CleaningTask] = []
    init(name: String, category: SupplyCategory = .tool, memo: String="", purchaseStoreName: String="", purchaseURL: String="") {
        self.id=UUID(); self.name=name; self.category=category; self.stockStatus = .ok
        self.memo=memo; self.purchaseStoreName=purchaseStoreName; self.purchaseURL=purchaseURL
    }
}

enum SupplyCategory: String, Codable, CaseIterable {
    case tool="tool",cloth="cloth",chemical="chemical",disposable="disposable",other="other"
    var label: String {
        let isJP = (UserDefaults.standard.string(forKey:"app_language") ?? "ja") == "ja"
        switch self {
        case .tool: return isJP ? "電動工具":"Tools"; case .cloth: return isJP ? "クロス・布":"Cloth"
        case .chemical: return isJP ? "洗剤・薬剤":"Detergent"; case .disposable: return isJP ? "消耗品":"Disposables"
        case .other: return isJP ? "その他":"Other"
        }
    }
}

enum StockStatus: String, Codable, CaseIterable {
    case ok="ok",low="low",outOfStock="outOfStock"
    var needsReorder: Bool { self == .low || self == .outOfStock }
    var label: String {
        let isJP = (UserDefaults.standard.string(forKey:"app_language") ?? "ja") == "ja"
        switch self {
        case .ok: return isJP ? "十分":"In Stock"; case .low: return isJP ? "残り少":"Low Stock"
        case .outOfStock: return isJP ? "切れ":"Out of Stock"
        }
    }
}

@Model final class PurchaseItem {
    var id: UUID; var name: String; var quantity: Int; var estimatedPrice: Int
    var isPurchased: Bool; var purchasedAt: Date?; var supply: Supply?
    init(name: String, quantity: Int=1, estimatedPrice: Int=0) {
        self.id=UUID(); self.name=name; self.quantity=quantity; self.estimatedPrice=estimatedPrice; self.isPurchased=false
    }
    func markAsPurchased() { isPurchased=true; purchasedAt = .now }
}

@Model final class Fixture {
    var id: UUID; var name: String; var icon: String; var memo: String
    var installedAt: Date?; var makerName: String; var modelNumber: String; var room: Room?
    @Relationship(deleteRule: .cascade) var parts: [ConsumablePart] = []
    @Relationship(inverse: \CleaningTask.fixtures) var tasks: [CleaningTask] = []
    init(name: String, icon: String="wrench.and.screwdriver", memo: String="", makerName: String="", modelNumber: String="") {
        self.id=UUID(); self.name=name; self.icon=icon; self.memo=memo; self.makerName=makerName; self.modelNumber=modelNumber
    }
}

@Model final class ConsumablePart {
    var id: UUID; var name: String; var partNumber: String; var replacementMonths: Int
    var lastReplacedAt: Date?; var purchaseURL: String; var purchaseStoreName: String
    var unitPrice: Int; var stockCount: Int; var memo: String; var fixture: Fixture?
    @Relationship(deleteRule: .cascade) var purchaseRecords: [PurchaseRecord] = []
    init(name: String, partNumber: String="", replacementMonths: Int=12, purchaseURL: String="",
         purchaseStoreName: String="", unitPrice: Int=0, memo: String="") {
        self.id=UUID(); self.name=name; self.partNumber=partNumber; self.replacementMonths=replacementMonths
        self.purchaseURL=purchaseURL; self.purchaseStoreName=purchaseStoreName; self.unitPrice=unitPrice; self.stockCount=0; self.memo=memo
    }
    var nextReplacementDate: Date? {
        guard let last=lastReplacedAt, replacementMonths>0 else { return nil }
        return Calendar.current.date(byAdding:.month,value:replacementMonths,to:last)
    }
    var replacementStatus: ReplacementStatus {
        guard let next=nextReplacementDate else { return .unknown }
        let days=Calendar.current.dateComponents([.day],from:.now,to:next).day ?? 0
        if days<0 { return .overdue }; if days<=30 { return .soon }; return .ok
    }
}

enum ReplacementStatus {
    case ok,soon,overdue,unknown
    var label: String {
        let isJP = (UserDefaults.standard.string(forKey:"app_language") ?? "ja") == "ja"
        switch self {
        case .ok: return isJP ? "正常":"OK"; case .soon: return isJP ? "交換まもなく":"Due Soon"
        case .overdue: return isJP ? "交換時期超過":"Overdue"; case .unknown: return isJP ? "未記録":"N/A"
        }
    }
}

@Model final class PurchaseRecord {
    var id: UUID; var purchasedAt: Date; var quantity: Int; var unitPrice: Int; var storeName: String; var memo: String; var part: ConsumablePart?
    init(quantity: Int=1, unitPrice: Int=0, storeName: String="", memo: String="") {
        self.id=UUID(); self.purchasedAt = .now; self.quantity=quantity; self.unitPrice=unitPrice; self.storeName=storeName; self.memo=memo
    }
    var totalPrice: Int { unitPrice * quantity }
}

struct FixturePreset: Identifiable {
    let id: String; let nameJA: String; let nameEN: String; let icon: String; let parts: [PartPreset]
    var name: String { (UserDefaults.standard.string(forKey: "app_language") ?? "ja") == "ja" ? nameJA : nameEN }
}
struct PartPreset: Identifiable {
    let id: String; let nameJA: String; let nameEN: String; let replacementMonths: Int; let memo: String
    var name: String { (UserDefaults.standard.string(forKey: "app_language") ?? "ja") == "ja" ? nameJA : nameEN }
}
extension FixturePreset {
    static let byRoomIcon: [String:[FixturePreset]] = ["shower":bathroomPresets,"drop":bathroomPresets,"fork.knife":kitchenPresets,"washer":laundryPresets,"sofa":livingPresets,"bed.double":bedroomPresets]
    static let bathroomPresets:[FixturePreset] = [
        FixturePreset(id:"bath_dryer",nameJA:"浴室乾燥機",nameEN:"Bath Dryer",icon:"wind",parts:[
            PartPreset(id:"exhaust_filter",nameJA:"排気フィルター",nameEN:"Exhaust Filter",replacementMonths:6,memo:""),
            PartPreset(id:"intake_filter",nameJA:"吸気グリルフィルター",nameEN:"Intake Filter",replacementMonths:3,memo:"")]),
        FixturePreset(id:"water_heater",nameJA:"給湯器",nameEN:"Water Heater",icon:"flame",parts:[
            PartPreset(id:"heater_filter",nameJA:"給水フィルター",nameEN:"Water Filter",replacementMonths:12,memo:"")])]
    static let kitchenPresets:[FixturePreset] = [
        FixturePreset(id:"range_hood",nameJA:"レンジフード・換気扇",nameEN:"Range Hood",icon:"arrow.up.to.line",parts:[
            PartPreset(id:"grease_filter",nameJA:"グリスフィルター",nameEN:"Grease Filter",replacementMonths:3,memo:""),
            PartPreset(id:"charcoal_filter",nameJA:"整流板・活性炭フィルター",nameEN:"Charcoal Filter",replacementMonths:6,memo:"")]),
        FixturePreset(id:"dishwasher",nameJA:"食洗機",nameEN:"Dishwasher",icon:"drop.triangle",parts:[
            PartPreset(id:"mesh_filter",nameJA:"残菜フィルター",nameEN:"Mesh Filter",replacementMonths:0,memo:""),
            PartPreset(id:"rinse_aid",nameJA:"リンス剤",nameEN:"Rinse Aid",replacementMonths:1,memo:"")]),
        FixturePreset(id:"refrigerator",nameJA:"冷蔵庫",nameEN:"Refrigerator",icon:"refrigerator",parts:[
            PartPreset(id:"deodorizer",nameJA:"脱臭剤",nameEN:"Deodorizer",replacementMonths:12,memo:""),
            PartPreset(id:"water_filter",nameJA:"浄水フィルター",nameEN:"Water Filter",replacementMonths:6,memo:"")])]
    static let laundryPresets:[FixturePreset] = [
        FixturePreset(id:"washer_dryer",nameJA:"洗濯乾燥機",nameEN:"Washer/Dryer",icon:"washer",parts:[
            PartPreset(id:"lint_filter",nameJA:"糸くずフィルター",nameEN:"Lint Filter",replacementMonths:0,memo:""),
            PartPreset(id:"dry_filter",nameJA:"乾燥フィルター",nameEN:"Dry Filter",replacementMonths:0,memo:""),
            PartPreset(id:"drum_cleaner",nameJA:"槽洗浄剤",nameEN:"Drum Cleaner",replacementMonths:1,memo:"")])]
    static let livingPresets:[FixturePreset] = [
        FixturePreset(id:"aircon",nameJA:"エアコン",nameEN:"Air Conditioner",icon:"air.conditioner.horizontal",parts:[
            PartPreset(id:"aircon_filter",nameJA:"フィルター",nameEN:"Filter",replacementMonths:0,memo:""),
            PartPreset(id:"aircon_deodorize",nameJA:"脱臭フィルター",nameEN:"Deodorizing Filter",replacementMonths:12,memo:"")]),
        FixturePreset(id:"air_purifier",nameJA:"空気清浄機",nameEN:"Air Purifier",icon:"aqi.medium",parts:[
            PartPreset(id:"hepa_filter",nameJA:"HEPAフィルター",nameEN:"HEPA Filter",replacementMonths:24,memo:""),
            PartPreset(id:"deodor_filter2",nameJA:"脱臭フィルター",nameEN:"Deodorizing Filter",replacementMonths:12,memo:""),
            PartPreset(id:"prefilter",nameJA:"プレフィルター",nameEN:"Pre-Filter",replacementMonths:0,memo:"")])]
    static let bedroomPresets:[FixturePreset] = [
        FixturePreset(id:"aircon_bed",nameJA:"エアコン",nameEN:"Air Conditioner",icon:"air.conditioner.horizontal",parts:[
            PartPreset(id:"aircon_filter2",nameJA:"フィルター",nameEN:"Filter",replacementMonths:0,memo:"")])]
}

enum PikariSchemaV1: VersionedSchema {
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Home.self,Room.self,CleaningTask.self,TaskLog.self,TaskPartUsage.self,Supply.self,PurchaseItem.self,Fixture.self,ConsumablePart.self,PurchaseRecord.self]
    }
}

enum PikariMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [PikariSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

extension ModelContainer {
    @MainActor
    static let cleaningApp: ModelContainer = {
        let schema = Schema(PikariSchemaV1.models)

        // 1: iCloud
        if let c = try? ModelContainer(for: schema, migrationPlan: PikariMigrationPlan.self,
            configurations: ModelConfiguration(schema:schema, isStoredInMemoryOnly:false, cloudKitDatabase:.private("iCloud.com.hiroki.CleaningApp"))) { return c }

        // 2: ローカル永続
        if let c = try? ModelContainer(for: schema, migrationPlan: PikariMigrationPlan.self,
            configurations: ModelConfiguration(schema:schema, isStoredInMemoryOnly:false)) { return c }

        // 3: ストア削除後に再作成
        let fm = FileManager.default
        for dir in [fm.urls(for:.applicationSupportDirectory,in:.userDomainMask).first, fm.urls(for:.documentDirectory,in:.userDomainMask).first].compactMap({$0}) {
            if let files = try? fm.contentsOfDirectory(at:dir, includingPropertiesForKeys:nil) {
                for f in files where f.lastPathComponent.lowercased().contains("store") || f.lastPathComponent.hasSuffix("-shm") || f.lastPathComponent.hasSuffix("-wal") {
                    try? fm.removeItem(at:f)
                }
            }
        }
        if let c = try? ModelContainer(for: schema, configurations: ModelConfiguration(schema:schema, isStoredInMemoryOnly:false)) { return c }

        // 4: マイグレーションなし
        if let c = try? ModelContainer(for: schema) { return c }

        // 5: Homeのみのインメモリ（最小限）
        let memConfig = ModelConfiguration(isStoredInMemoryOnly: true)
        // 段階的に追加して問題のあるモデルを特定
        let testModels: [any PersistentModel.Type] = [
            Home.self, Room.self, CleaningTask.self, TaskLog.self, TaskPartUsage.self,
            Supply.self, PurchaseItem.self, Fixture.self, ConsumablePart.self, PurchaseRecord.self
        ]
        // 1モデルずつ試す
        for count in stride(from: testModels.count, through: 1, by: -1) {
            let subset = Array(testModels.prefix(count))
            let subSchema = Schema(subset)
            let subConfig = ModelConfiguration(schema: subSchema, isStoredInMemoryOnly: true)
            if let c = try? ModelContainer(for: subSchema, configurations: subConfig) {
                print("✅ Started with \(count) models")
                return c
            }
            print("❌ Failed with \(count) models")
        }
        // Homeだけで強制起動
        let minSchema = Schema([Home.self])
        let minConfig = ModelConfiguration(schema: minSchema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: minSchema, configurations: minConfig)
    }()
}
