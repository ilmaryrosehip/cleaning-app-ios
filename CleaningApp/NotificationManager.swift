import Foundation
import UserNotifications
import SwiftData

// MARK: - NotificationManager

@MainActor
final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    // MARK: - 許可リクエスト

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - 全タスクの通知をスケジュール

    func scheduleAll(tasks: [CleaningTask]) async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let granted = await requestAuthorization()
        guard granted else { return }
        for task in tasks where task.isActive {
            await scheduleNotifications(for: task)
        }
    }

    // MARK: - 単一タスクの通知スケジュール

    func scheduleNotifications(for task: CleaningTask) async {
        guard task.isActive else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: notificationIDs(for: task))

        // タスクのデータをMainActor上でコピーしてからスケジュール
        let taskID      = task.id.uuidString
        let taskTitle   = task.title
        let roomName    = task.room?.name ?? ""
        let frequency   = task.frequency
        let weekdays    = task.weekdays
        let nextDueDate = task.nextDueDate

        await scheduleRequests(
            taskID: taskID,
            taskTitle: taskTitle,
            roomName: roomName,
            frequency: frequency,
            weekdays: weekdays,
            nextDueDate: nextDueDate
        )
    }

    // MARK: - タスク通知削除

    func cancelNotifications(for task: CleaningTask) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: notificationIDs(for: task))
    }

    // MARK: - Private helpers

    private func notificationIDs(for task: CleaningTask) -> [String] {
        (0..<7).map { "task-\(task.id.uuidString)-weekday-\($0)" }
            + ["task-\(task.id.uuidString)-single"]
    }

    /// MainActorから切り離してスケジュール（Sendable な値型のみ受け取る）
    private nonisolated func scheduleRequests(
        taskID: String,
        taskTitle: String,
        roomName: String,
        frequency: Frequency,
        weekdays: [Int],
        nextDueDate: Date
    ) async {
        let body = roomName.isEmpty ? taskTitle : "\(roomName)：\(taskTitle)"
        let center = UNUserNotificationCenter.current()

        func makeContent() -> UNMutableNotificationContent {
            let c = UNMutableNotificationContent()
            c.title = "掃除の時間です 🏠"
            c.body  = body
            c.sound = .default
            c.badge = 1
            return c
        }

        func addRequest(identifier: String, components: DateComponents, repeats: Bool) async {
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
            let req = UNNotificationRequest(identifier: identifier, content: makeContent(), trigger: trigger)
            try? await center.add(req)
        }

        switch frequency {
        case .daily:
            var comps = DateComponents(); comps.hour = 9; comps.minute = 0
            await addRequest(identifier: "task-\(taskID)-single", components: comps, repeats: true)

        case .weekly, .biweekly:
            let days = weekdays.isEmpty
                ? [Calendar.current.component(.weekday, from: nextDueDate) - 1]
                : weekdays
            for wd in days {
                var comps = DateComponents()
                comps.weekday = wd + 1; comps.hour = 9; comps.minute = 0
                await addRequest(identifier: "task-\(taskID)-weekday-\(wd)", components: comps, repeats: true)
            }

        case .monthly:
            let day = Calendar.current.component(.day, from: nextDueDate)
            var comps = DateComponents(); comps.day = day; comps.hour = 9; comps.minute = 0
            await addRequest(identifier: "task-\(taskID)-single", components: comps, repeats: true)

        case .custom:
            guard nextDueDate > .now else { return }
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: nextDueDate)
            comps.hour = 9; comps.minute = 0
            await addRequest(identifier: "task-\(taskID)-single", components: comps, repeats: false)
        }
    }
}
