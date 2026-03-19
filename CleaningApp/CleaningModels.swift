import Foundation
import SwiftData

// MARK: - Home（家）

@Model
final class Home {
    var id: UUID
    var name: String
    var floorPlanNote: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var rooms: [Room] = []

    init(name: String, floorPlanNote: String = "") {
        self.id = UUID()
        self.name = name
        self.floorPlanNote = floorPlanNote
        self.createdAt = .now
    }
}

// MARK: - Room（部屋）

@Model
final class Room {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int

    var home: Home?

    @Relationship(deleteRule: .cascade)
    var tasks: [CleaningTask] = []

    @Relationship(deleteRule: .cascade)
    var fixtures: [Fixture] = []

    init(name: String, icon: String = "house", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
    }
}

// MARK: - Weekday（曜日）

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sun = 0, mon, tue, wed, thu, fri, sat
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .sun: return "日"
        case .mon: return "月"
        case .tue: return "火"
        case .wed: return "水"
        case .thu: return "木"
        case .fri: return "金"
        case .sat: return "土"
        }
    }
}

// MARK: - CleaningTask（掃除タスク）

@Model
final class CleaningTask {
    var id: UUID
    var title: String
    var notes: String
    var frequency: Frequency
    var intervalDays: Int
    var weekdays: [Int]
    var nextDueDate: Date
    var estimatedMinutes: Int
    var isActive: Bool

    var room: Room?

    @Relationship(deleteRule: .cascade)
    var logs: [TaskLog] = []

    @Relationship
    var supplies: [Supply] = []

    @Relationship
    var fixtures: [Fixture] = []

    init(
        title: String,
        frequency: Frequency = .weekly,
        weekdays: [Int] = [],
        intervalDays: Int = 7,
        nextDueDate: Date = .now,
        estimatedMinutes: Int = 15,
        notes: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.frequency = frequency
        self.weekdays = weekdays
        self.intervalDays = intervalDays
        self.nextDueDate = nextDueDate
        self.estimatedMinutes = estimatedMinutes
        self.isActive = true
    }

    func markCompleted(duration: Int = 0, memo: String = "") -> TaskLog {
        let log = TaskLog(task: self, durationMinutes: duration, memo: memo)
        logs.append(log)
        nextDueDate = frequency.nextDate(from: .now, intervalDays: intervalDays, weekdays: weekdays)
        return log
    }

    var isOverdue: Bool {
        nextDueDate < Calendar.current.startOfDay(for: .now)
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(nextDueDate)
    }

    var weekdaysLabel: String {
        guard !weekdays.isEmpty else { return "" }
        return weekdays.sorted()
            .compactMap { Weekday(rawValue: $0)?.label }
            .joined(separator: "・")
    }
}

// MARK: - Frequency（繰り返し種別）

enum Frequency: String, Codable, CaseIterable {
    case daily   = "毎日"
    case weekly  = "毎週"
    case biweekly = "隔週"
    case monthly = "毎月"
    case custom  = "カスタム"

    func nextDate(from base: Date, intervalDays: Int, weekdays: [Int] = []) -> Date {
        let cal = Calendar.current
        switch self {
        case .daily:
            return cal.date(byAdding: .day, value: 1, to: base) ?? base
        case .weekly, .biweekly:
            let weekMultiplier = self == .biweekly ? 2 : 1
            guard !weekdays.isEmpty else {
                return cal.date(byAdding: .day, value: 7 * weekMultiplier, to: base) ?? base
            }
            let sorted = weekdays.sorted()
            for dayOffset in 1...(7 * weekMultiplier + 6) {
                guard let candidate = cal.date(byAdding: .day, value: dayOffset, to: base) else { continue }
                let weekday = cal.component(.weekday, from: candidate) - 1
                if sorted.contains(weekday) { return candidate }
            }
            return cal.date(byAdding: .day, value: 7 * weekMultiplier, to: base) ?? base
        case .monthly:
            return cal.date(byAdding: .month, value: 1, to: base) ?? base
        case .custom:
            return cal.date(byAdding: .day, value: max(1, intervalDays), to: base) ?? base
        }
    }

    var supportsWeekdays: Bool { self == .weekly || self == .biweekly }
}

// MARK: - TaskLog

@Model
final class TaskLog {
    var id: UUID
    var completedAt: Date
    var durationMinutes: Int
    var memo: String
    var task: CleaningTask?

    init(task: CleaningTask? = nil, durationMinutes: Int = 0, memo: String = "") {
        self.id = UUID()
        self.completedAt = .now
        self.durationMinutes = durationMinutes
        self.memo = memo
        self.task = task
    }
}

// MARK: - Supply（掃除用品）

@Model
final class Supply {
    var id: UUID
    var name: String
    var category: SupplyCategory
    var stockStatus: StockStatus
    var lastUsedAt: Date?
    var memo: String

    @Relationship(deleteRule: .cascade)
    var purchaseItems: [PurchaseItem] = []

    @Relationship(inverse: \CleaningTask.supplies)
    var tasks: [CleaningTask] = []

    init(name: String, category: SupplyCategory = .tool, memo: String = "") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.stockStatus = .ok
        self.memo = memo
    }
}

enum SupplyCategory: String, Codable, CaseIterable {
    case tool        = "電動工具"
    case cloth       = "クロス・布"
    case chemical    = "洗剤・薬剤"
    case disposable  = "消耗品"
    case other       = "その他"
}

enum StockStatus: String, Codable, CaseIterable {
    case ok         = "十分"
    case low        = "残り少"
    case outOfStock = "切れ"

    var needsReorder: Bool { self == .low || self == .outOfStock }
}

// MARK: - PurchaseItem

@Model
final class PurchaseItem {
    var id: UUID
    var name: String
    var quantity: Int
    var estimatedPrice: Int
    var isPurchased: Bool
    var purchasedAt: Date?
    var supply: Supply?

    init(name: String, quantity: Int = 1, estimatedPrice: Int = 0) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.estimatedPrice = estimatedPrice
        self.isPurchased = false
    }

    func markAsPurchased() {
        isPurchased = true
        purchasedAt = .now
    }
}

// MARK: - Fixture（設備・器具）

@Model
final class Fixture {
    var id: UUID
    var name: String
    var icon: String
    var memo: String
    var installedAt: Date?
    var makerName: String
    var modelNumber: String

    var room: Room?

    @Relationship(deleteRule: .cascade)
    var parts: [ConsumablePart] = []

    @Relationship(inverse: \CleaningTask.fixtures)
    var tasks: [CleaningTask] = []

    init(name: String, icon: String = "wrench.and.screwdriver", memo: String = "",
         makerName: String = "", modelNumber: String = "") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.memo = memo
        self.makerName = makerName
        self.modelNumber = modelNumber
    }
}

// MARK: - ConsumablePart（消耗品パーツ）

@Model
final class ConsumablePart {
    var id: UUID
    var name: String
    var partNumber: String
    var replacementMonths: Int
    var lastReplacedAt: Date?
    var purchaseURL: String
    var purchaseStoreName: String
    var unitPrice: Int
    var stockCount: Int
    var memo: String

    var fixture: Fixture?

    @Relationship(deleteRule: .cascade)
    var purchaseRecords: [PurchaseRecord] = []

    init(name: String, partNumber: String = "", replacementMonths: Int = 12,
         purchaseURL: String = "", purchaseStoreName: String = "",
         unitPrice: Int = 0, memo: String = "") {
        self.id = UUID()
        self.name = name
        self.partNumber = partNumber
        self.replacementMonths = replacementMonths
        self.lastReplacedAt = nil
        self.purchaseURL = purchaseURL
        self.purchaseStoreName = purchaseStoreName
        self.unitPrice = unitPrice
        self.stockCount = 0
        self.memo = memo
    }

    var nextReplacementDate: Date? {
        guard let last = lastReplacedAt, replacementMonths > 0 else { return nil }
        return Calendar.current.date(byAdding: .month, value: replacementMonths, to: last)
    }

    var replacementStatus: ReplacementStatus {
        guard let next = nextReplacementDate else { return .unknown }
        let days = Calendar.current.dateComponents([.day], from: .now, to: next).day ?? 0
        if days < 0 { return .overdue }
        if days <= 30 { return .soon }
        return .ok
    }
}

// MARK: - ReplacementStatus

enum ReplacementStatus {
    case ok, soon, overdue, unknown

    var label: String {
        switch self {
        case .ok:      return "正常"
        case .soon:    return "交換まもなく"
        case .overdue: return "交換時期超過"
        case .unknown: return "未記録"
        }
    }
}

// MARK: - PurchaseRecord（購入履歴）

@Model
final class PurchaseRecord {
    var id: UUID
    var purchasedAt: Date
    var quantity: Int
    var unitPrice: Int
    var storeName: String
    var memo: String
    var part: ConsumablePart?

    init(quantity: Int = 1, unitPrice: Int = 0, storeName: String = "", memo: String = "") {
        self.id = UUID()
        self.purchasedAt = .now
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.storeName = storeName
        self.memo = memo
    }

    var totalPrice: Int { unitPrice * quantity }
}

// MARK: - FixturePreset

struct FixturePreset: Identifiable {
    let id: String
    let name: String
    let icon: String
    let parts: [PartPreset]
}

struct PartPreset: Identifiable {
    let id: String
    let name: String
    let replacementMonths: Int
    let memo: String
}

extension FixturePreset {
    static let byRoomIcon: [String: [FixturePreset]] = [
        "shower": bathroomPresets,
        "drop":   bathroomPresets,
        "fork.knife": kitchenPresets,
        "washer": laundryPresets,
        "sofa":   livingPresets,
        "bed.double": bedroomPresets,
    ]

    static let bathroomPresets: [FixturePreset] = [
        FixturePreset(id: "bath_dryer", name: "浴室乾燥機", icon: "wind", parts: [
            PartPreset(id: "exhaust_filter", name: "排気フィルター", replacementMonths: 6, memo: "目詰まりで乾燥効率低下"),
            PartPreset(id: "intake_filter",  name: "吸気グリルフィルター", replacementMonths: 3, memo: "月1回掃除推奨"),
        ]),
        FixturePreset(id: "water_heater", name: "給湯器", icon: "flame", parts: [
            PartPreset(id: "heater_filter", name: "給水フィルター", replacementMonths: 12, memo: "年1回点検"),
        ]),
    ]

    static let kitchenPresets: [FixturePreset] = [
        FixturePreset(id: "range_hood", name: "レンジフード・換気扇", icon: "arrow.up.to.line", parts: [
            PartPreset(id: "grease_filter",   name: "グリスフィルター",        replacementMonths: 3, memo: "油汚れが溜まりやすい"),
            PartPreset(id: "charcoal_filter", name: "整流板・活性炭フィルター", replacementMonths: 6, memo: "脱臭効果が落ちたら交換"),
        ]),
        FixturePreset(id: "dishwasher", name: "食洗機", icon: "drop.triangle", parts: [
            PartPreset(id: "mesh_filter", name: "残菜フィルター", replacementMonths: 0, memo: "毎回使用後に清掃"),
            PartPreset(id: "rinse_aid",   name: "リンス剤",       replacementMonths: 1, memo: "なくなったら補充"),
        ]),
        FixturePreset(id: "refrigerator", name: "冷蔵庫", icon: "refrigerator", parts: [
            PartPreset(id: "deodorizer",   name: "脱臭剤",         replacementMonths: 12, memo: "1〜2年で交換"),
            PartPreset(id: "water_filter", name: "浄水フィルター", replacementMonths: 6,  memo: "製氷機付きの場合"),
        ]),
    ]

    static let laundryPresets: [FixturePreset] = [
        FixturePreset(id: "washer_dryer", name: "洗濯乾燥機", icon: "washer", parts: [
            PartPreset(id: "lint_filter",  name: "糸くずフィルター", replacementMonths: 0, memo: "毎回使用後に清掃"),
            PartPreset(id: "dry_filter",   name: "乾燥フィルター",   replacementMonths: 0, memo: "乾燥後に清掃"),
            PartPreset(id: "drum_cleaner", name: "槽洗浄剤",         replacementMonths: 1, memo: "月1回の槽クリーン"),
        ]),
    ]

    static let livingPresets: [FixturePreset] = [
        FixturePreset(id: "aircon", name: "エアコン", icon: "air.conditioner.horizontal", parts: [
            PartPreset(id: "aircon_filter",    name: "フィルター",     replacementMonths: 0,  memo: "2週間に1回清掃推奨"),
            PartPreset(id: "aircon_deodorize", name: "脱臭フィルター", replacementMonths: 12, memo: "年1回交換"),
        ]),
        FixturePreset(id: "air_purifier", name: "空気清浄機", icon: "aqi.medium", parts: [
            PartPreset(id: "hepa_filter",    name: "HEPAフィルター",  replacementMonths: 24, memo: "2年に1回が目安"),
            PartPreset(id: "deodor_filter2", name: "脱臭フィルター",  replacementMonths: 12, memo: "年1回交換"),
            PartPreset(id: "prefilter",      name: "プレフィルター",  replacementMonths: 0,  memo: "2週間に1回清掃"),
        ]),
    ]

    static let bedroomPresets: [FixturePreset] = [
        FixturePreset(id: "aircon_bed", name: "エアコン", icon: "air.conditioner.horizontal", parts: [
            PartPreset(id: "aircon_filter2", name: "フィルター", replacementMonths: 0, memo: "2週間に1回清掃推奨"),
        ]),
    ]
}

// MARK: - ModelContainer

extension ModelContainer {
    @MainActor
    static let cleaningApp: ModelContainer = {
        let schema = Schema([
            Home.self, Room.self, CleaningTask.self, TaskLog.self,
            Supply.self, PurchaseItem.self,
            Fixture.self, ConsumablePart.self, PurchaseRecord.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("ModelContainer の初期化に失敗しました: \(error)")
        }
    }()
}
