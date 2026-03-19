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

    /// 既存の通知を全削除してから登録し直す
    func scheduleAll(tasks: [CleaningTask]) async {
        // まず全削除
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

        // このタスクの既存通知を削除
        let existingIDs = notificationIDs(for: task)
        center.removePendingNotificationRequests(withIdentifiers: existingIDs)

        switch task.frequency {
        case .daily:
            await scheduleDailyNotification(for: task)

        case .weekly:
            await scheduleWeekdayNotifications(for: task, weekMultiplier: 1)

        case .biweekly:
            await scheduleWeekdayNotifications(for: task, weekMultiplier: 2)

        case .monthly:
            await scheduleMonthlyNotification(for: task)

        case .custom:
            await scheduleCustomNotification(for: task)
        }
    }

    // MARK: - タスク通知削除

    func cancelNotifications(for task: CleaningTask) {
        let ids = notificationIDs(for: task)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private helpers

    private func notificationIDs(for task: CleaningTask) -> [String] {
        // 曜日ごとのIDを7つ生成（余分なものは登録されない）
        (0..<7).map { "task-\(task.id.uuidString)-weekday-\($0)" }
        + ["task-\(task.id.uuidString)-single"]
    }

    private func content(for task: CleaningTask) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "掃除の時間です 🏠"
        let roomName = task.room?.name ?? ""
        content.body = roomName.isEmpty ? task.title : "\(roomName)：\(task.title)"
        content.sound = .default
        content.badge = 1
        return content
    }

    /// 毎日 午前9時に通知
    private func scheduleDailyNotification(for task: CleaningTask) async {
        var trigger = DateComponents()
        trigger.hour = 9
        trigger.minute = 0

        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)-single",
            content: content(for: task),
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    /// 毎週 or 隔週: 指定曜日に 午前9時に通知
    private func scheduleWeekdayNotifications(for task: CleaningTask, weekMultiplier: Int) async {
        let weekdays = task.weekdays.isEmpty
            ? [Calendar.current.component(.weekday, from: task.nextDueDate) - 1]
            : task.weekdays

        for weekdayRaw in weekdays {
            // UNCalendarNotificationTrigger の weekday は 1=日〜7=土
            let calWeekday = weekdayRaw + 1

            var trigger = DateComponents()
            trigger.weekday = calWeekday
            trigger.hour = 9
            trigger.minute = 0

            let identifier = "task-\(task.id.uuidString)-weekday-\(weekdayRaw)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content(for: task),
                trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
            )
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    /// 毎月: nextDueDate の日付(日)に 午前9時に通知
    private func scheduleMonthlyNotification(for task: CleaningTask) async {
        let day = Calendar.current.component(.day, from: task.nextDueDate)

        var trigger = DateComponents()
        trigger.day = day
        trigger.hour = 9
        trigger.minute = 0

        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)-single",
            content: content(for: task),
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    /// カスタム: nextDueDate に一度だけ通知
    private func scheduleCustomNotification(for task: CleaningTask) async {
        guard task.nextDueDate > .now else { return }

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: task.nextDueDate)
        comps.hour = 9
        comps.minute = 0

        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)-single",
            content: content(for: task),
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
