import Testing
import Foundation
import SwiftData
@testable import CleaningApp

// MARK: - Frequency Tests

@Suite("Frequency")
struct FrequencyTests {

    @Test("daily は1日後を返す")
    func dailyNextDate() {
        let base = Date.now
        let next = Frequency.daily.nextDate(from: base, intervalDays: 1)
        let diff = Calendar.current.dateComponents([.day], from: base, to: next).day
        #expect(diff == 1)
    }

    @Test("weekly は7日後を返す（曜日未指定）")
    func weeklyNextDate() {
        let base = Date.now
        let next = Frequency.weekly.nextDate(from: base, intervalDays: 7)
        let diff = Calendar.current.dateComponents([.day], from: base, to: next).day
        #expect(diff == 7)
    }

    @Test("biweekly は14日後を返す（曜日未指定）")
    func biweeklyNextDate() {
        let base = Date.now
        let next = Frequency.biweekly.nextDate(from: base, intervalDays: 14)
        let diff = Calendar.current.dateComponents([.day], from: base, to: next).day
        #expect(diff == 14)
    }

    @Test("monthly は約1ヶ月後を返す")
    func monthlyNextDate() {
        let base = Date.now
        let next = Frequency.monthly.nextDate(from: base, intervalDays: 30)
        let diff = Calendar.current.dateComponents([.day], from: base, to: next).day ?? 0
        #expect(diff >= 28 && diff <= 31)
    }

    @Test("custom は intervalDays 日後を返す")
    func customNextDate() {
        let base = Date.now
        let next = Frequency.custom.nextDate(from: base, intervalDays: 5)
        let diff = Calendar.current.dateComponents([.day], from: base, to: next).day
        #expect(diff == 5)
    }

    @Test("custom に 0 を渡すと最低1日になる")
    func customZeroIntervalClamped() {
        let base = Date.now
        let next = Frequency.custom.nextDate(from: base, intervalDays: 0)
        let diff = Calendar.current.dateComponents([.day], from: base, to: next).day
        #expect(diff == 1)
    }

    @Test("weekly + 曜日指定: 次の該当曜日が返る")
    func weeklyWithWeekday() {
        let cal = Calendar.current
        let comps = DateComponents(year: 2025, month: 1, day: 6) // 月曜
        let monday = cal.date(from: comps)!
        let next = Frequency.weekly.nextDate(from: monday, intervalDays: 7, weekdays: [3])
        let weekday = cal.component(.weekday, from: next) - 1
        #expect(weekday == 3)
        let diff = cal.dateComponents([.day], from: monday, to: next).day ?? 0
        #expect(diff > 0 && diff <= 7)
    }

    @Test("supportsWeekdays: weekly と biweekly のみ true")
    func supportsWeekdays() {
        #expect(Frequency.weekly.supportsWeekdays == true)
        #expect(Frequency.biweekly.supportsWeekdays == true)
        #expect(Frequency.daily.supportsWeekdays == false)
        #expect(Frequency.monthly.supportsWeekdays == false)
        #expect(Frequency.custom.supportsWeekdays == false)
    }
}

// MARK: - StockStatus Tests

@Suite("StockStatus")
struct StockStatusTests {

    @Test("ok は補充不要")
    func okNoReorder() {
        #expect(StockStatus.ok.needsReorder == false)
    }

    @Test("low は補充が必要")
    func lowNeedsReorder() {
        #expect(StockStatus.low.needsReorder == true)
    }

    @Test("outOfStock は補充が必要")
    func outOfStockNeedsReorder() {
        #expect(StockStatus.outOfStock.needsReorder == true)
    }
}

// MARK: - CleaningTask Model Tests

@Suite("CleaningTask")
struct CleaningTaskTests {

    func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Home.self, Room.self, CleaningTask.self,
            TaskLog.self, Supply.self, PurchaseItem.self,
            Fixture.self, ConsumablePart.self, PurchaseRecord.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    @Test("isOverdue: 過去の日付のタスクは期限超過")
    func isOverdueTrue() throws {
        let task = CleaningTask(title: "test")
        task.nextDueDate = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        #expect(task.isOverdue == true)
    }

    @Test("isOverdue: 今日のタスクは期限超過でない")
    func isOverdueFalse() throws {
        let task = CleaningTask(title: "test")
        task.nextDueDate = Calendar.current.startOfDay(for: .now)
        #expect(task.isOverdue == false)
    }

    @Test("isDueToday: 今日の日付なら true")
    func isDueTodayTrue() throws {
        let task = CleaningTask(title: "test")
        task.nextDueDate = Calendar.current.startOfDay(for: .now)
        #expect(task.isDueToday == true)
    }

    @Test("isDueToday: 明日の日付なら false")
    func isDueTodayFalse() throws {
        let task = CleaningTask(title: "test")
        task.nextDueDate = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        #expect(task.isDueToday == false)
    }

    @Test("markCompleted: TaskLog が追加され nextDueDate が更新される")
    func markCompleted() throws {
        let c = try makeContainer()
        let context = ModelContext(c)

        let task = CleaningTask(title: "掃除機がけ", frequency: .weekly, weekdays: [])
        let originalDue = task.nextDueDate
        context.insert(task)

        let log = task.markCompleted(duration: 20, memo: "完了")

        #expect(task.logs.count == 1)
        #expect(log.durationMinutes == 20)
        #expect(log.memo == "完了")
        #expect(task.nextDueDate > originalDue)
    }
}

// MARK: - PurchaseItem Tests

@Suite("PurchaseItem")
struct PurchaseItemTests {

    @Test("初期状態は isPurchased = false")
    func initialState() {
        let item = PurchaseItem(name: "重曹スプレー", quantity: 2, estimatedPrice: 600)
        #expect(item.isPurchased == false)
        #expect(item.purchasedAt == nil)
        #expect(item.quantity == 2)
        #expect(item.estimatedPrice == 600)
    }

    @Test("markAsPurchased で isPurchased = true かつ purchasedAt が設定される")
    func markAsPurchased() {
        let item = PurchaseItem(name: "重曹スプレー")
        item.markAsPurchased()
        #expect(item.isPurchased == true)
        #expect(item.purchasedAt != nil)
    }
}

// MARK: - ModelContainer Integration Test

@Suite("ModelContainer 統合")
struct ModelContainerIntegrationTests {

    @Test("Home → Room → CleaningTask のカスケード作成")
    func cascadeInsert() throws {
        let schema = Schema([
            Home.self, Room.self, CleaningTask.self,
            TaskLog.self, Supply.self, PurchaseItem.self,
            Fixture.self, ConsumablePart.self, PurchaseRecord.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        let home = Home(name: "テスト邸")
        context.insert(home)

        let room = Room(name: "リビング", icon: "sofa", sortOrder: 0)
        room.home = home
        context.insert(room)

        let task = CleaningTask(title: "掃除機がけ", frequency: .weekly)
        task.room = room
        context.insert(task)

        try context.save()

        let homes = try context.fetch(FetchDescriptor<Home>())
        #expect(homes.count == 1)
        #expect(homes[0].rooms.count == 1)
        #expect(homes[0].rooms[0].tasks.count == 1)
    }

    @Test("Fixture → Task の多対多紐づけ")
    func fixtureTaskRelation() throws {
        let schema = Schema([
            Home.self, Room.self, CleaningTask.self,
            TaskLog.self, Supply.self, PurchaseItem.self,
            Fixture.self, ConsumablePart.self, PurchaseRecord.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        let home = Home(name: "テスト邸")
        let room = Room(name: "リビング", icon: "sofa", sortOrder: 0)
        room.home = home
        context.insert(home)
        context.insert(room)

        let fixture = Fixture(name: "エアコン", icon: "air.conditioner.horizontal")
        fixture.room = room
        context.insert(fixture)

        let task = CleaningTask(title: "フィルター清掃", frequency: .monthly)
        task.room = room
        task.fixtures = [fixture]
        context.insert(task)

        try context.save()

        #expect(task.fixtures.count == 1)
        #expect(task.fixtures[0].name == "エアコン")
    }
}
