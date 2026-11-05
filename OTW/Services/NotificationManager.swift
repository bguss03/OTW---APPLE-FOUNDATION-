import Foundation
import SwiftData
import UIKit
import UserNotifications

/// Schedules "Remind Me" notifications, handles their actions, and routes taps to Detail screens.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private enum Category {
        static let event = "OTW_EVENT"
        static let eventWithURL = "OTW_EVENT_URL"
        static let reminder = "OTW_REMINDER"
    }

    private enum Action {
        static let join = "OTW_JOIN"
        static let markDone = "OTW_MARK_DONE"
        static let snooze = "OTW_SNOOZE"
    }

    private enum Key {
        static let kind = "kind"
        static let planID = "planID"
        static let url = "url"
    }

    private let center = UNUserNotificationCenter.current()
    /// Bundled at the app bundle root (required by UNNotificationSound).
    private static let sound = UNNotificationSound(named: UNNotificationSoundName("notification_sound.caf"))
    private var container: ModelContainer?
    private weak var appModel: AppModel?

    /// Call once at launch, before any notification can be delivered.
    func configure(container: ModelContainer, appModel: AppModel) {
        self.container = container
        self.appModel = appModel
        center.delegate = self
        registerCategories()
    }

    // MARK: - Authorization

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Asks the first time; returns whether OTW may post notifications.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        switch await authorizationStatus() {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    // MARK: - Scheduling

    /// Schedules (or reschedules) the event's reminder at start − offset.
    func schedule(_ event: Event, requestingPermission: Bool = true) async {
        let base = event.notificationIdentifier
        await cancel(base)
        guard let offset = event.remindBefore.timeInterval else { return }
        guard await isAllowed(requestingPermission: requestingPermission) else { return }

        let content = makeContent(for: event)
        let triggers = Self.triggers(for: event.startDate, repeatRule: event.repeatRule, offset: offset)
        await add(content: content, triggers: triggers, base: base)
    }

    /// Schedules (or reschedules) the reminder at due − offset; done or flexible reminders get nothing.
    func schedule(_ reminder: Reminder, requestingPermission: Bool = true) async {
        let base = reminder.notificationIdentifier
        await cancel(base)
        guard !reminder.isDone, let dueDate = reminder.dueDate, let offset = reminder.remindBefore.timeInterval else { return }
        guard await isAllowed(requestingPermission: requestingPermission) else { return }

        let content = makeContent(for: reminder, dueDate: dueDate)
        let triggers = Self.triggers(for: dueDate, repeatRule: reminder.repeatRule, offset: offset)
        await add(content: content, triggers: triggers, base: base)
    }

    /// Rebuilds every plan's notifications (e.g. after the sound changed). Never prompts.
    func rescheduleAll() async {
        guard let context = container?.mainContext else { return }
        guard await isAllowed(requestingPermission: false) else { return }
        let events = (try? context.fetch(FetchDescriptor<Event>())) ?? []
        let reminders = (try? context.fetch(FetchDescriptor<Reminder>())) ?? []
        for event in events { await schedule(event, requestingPermission: false) }
        for reminder in reminders { await schedule(reminder, requestingPermission: false) }
    }

    private func isAllowed(requestingPermission: Bool) async -> Bool {
        if requestingPermission { return await requestAuthorizationIfNeeded() }
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    /// Removes every pending and delivered notification that belongs to one plan.
    func cancel(_ base: String) async {
        let pending = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(base) || $0.hasPrefix("debug-" + base) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        let delivered = await center.deliveredNotifications()
            .map(\.request.identifier)
            .filter { $0.hasPrefix(base) || $0.hasPrefix("debug-" + base) }
        center.removeDeliveredNotifications(withIdentifiers: delivered)
    }

    /// Repeat rules map to repeating calendar triggers; "Never" is a single trigger that is
    /// skipped when its fire date has already passed.
    static func triggers(
        for date: Date,
        repeatRule: RepeatRule,
        offset: TimeInterval,
        now: Date = .now
    ) -> [UNCalendarNotificationTrigger] {
        let calendar = Calendar.current
        let fireDate = date.addingTimeInterval(-offset)

        func repeating(_ components: Set<Calendar.Component>, from date: Date) -> UNCalendarNotificationTrigger {
            UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents(components, from: date), repeats: true)
        }

        switch repeatRule {
        case .never:
            guard fireDate > now else { return [] }
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            return [UNCalendarNotificationTrigger(dateMatching: components, repeats: false)]
        case .daily:
            return [repeating([.hour, .minute], from: fireDate)]
        case .weekly:
            return [repeating([.weekday, .hour, .minute], from: fireDate)]
        case .monthly:
            return [repeating([.day, .hour, .minute], from: fireDate)]
        case .weekdays:
            // One trigger per Monday–Friday occurrence (Gregorian weekday 2...6), shifted by the offset.
            let time = calendar.dateComponents([.hour, .minute], from: date)
            return (2...6).compactMap { weekday in
                var match = DateComponents()
                match.weekday = weekday
                match.hour = time.hour
                match.minute = time.minute
                guard let occurrence = calendar.nextDate(
                    after: date.addingTimeInterval(-1),
                    matching: match,
                    matchingPolicy: .nextTime
                ) else { return nil }
                return repeating([.weekday, .hour, .minute], from: occurrence.addingTimeInterval(-offset))
            }
        }
    }

    // MARK: - Debug

    #if DEBUG
    /// Fires test notifications for real items 5 (event) and 12 (reminder) seconds from now.
    func scheduleTestNotifications(event: Event?, reminder: Reminder?) async {
        guard await requestAuthorizationIfNeeded() else { return }
        if let event {
            let request = UNNotificationRequest(
                identifier: "debug-" + event.notificationIdentifier,
                content: withMascot(makeContent(for: event)),
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            )
            try? await center.add(request)
        }
        if let reminder {
            let request = UNNotificationRequest(
                identifier: "debug-" + reminder.notificationIdentifier,
                content: withMascot(makeContent(for: reminder, dueDate: reminder.dueDate ?? .now)),
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 12, repeats: false)
            )
            try? await center.add(request)
        }
    }
    #endif

    // MARK: - Delegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show banners while the app is in the foreground.
        #if DEBUG
        let content = notification.request.content
        print("[OTW] presenting \(content.title) sound: \(content.sound.map { String(describing: $0) } ?? "none")")
        #endif
        return [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let content = response.notification.request.content
        let info = content.userInfo
        let payload = Payload(
            action: response.actionIdentifier,
            kind: info[Key.kind] as? String ?? "",
            planID: info[Key.planID] as? String ?? "",
            url: info[Key.url] as? String,
            title: content.title,
            body: content.body,
            category: content.categoryIdentifier
        )
        await handle(payload)
    }

    // MARK: - Private

    private struct Payload: Sendable {
        let action: String
        let kind: String
        let planID: String
        let url: String?
        let title: String
        let body: String
        let category: String
    }

    private func handle(_ payload: Payload) async {
        switch payload.action {
        case Action.join:
            if let raw = payload.url, let url = Self.webURL(from: raw) {
                await UIApplication.shared.open(url)
            }
        case Action.markDone:
            if let reminder = fetchReminder(payload.planID), !reminder.isDone, let context = container?.mainContext {
                PlanActions.toggleDone(reminder, in: context)
            }
        case Action.snooze:
            let content = UNMutableNotificationContent()
            content.title = payload.title
            content.body = payload.body
            content.sound = Self.sound
            content.categoryIdentifier = payload.category
            content.userInfo = [Key.kind: payload.kind, Key.planID: payload.planID]
            let request = UNNotificationRequest(
                identifier: payload.planID + "-snooze",
                content: withMascot(content),
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false)
            )
            try? await center.add(request)
        case UNNotificationDefaultActionIdentifier:
            openDetail(kind: payload.kind, planID: payload.planID)
        default:
            break
        }
    }

    private func openDetail(kind: String, planID: String) {
        guard let appModel else { return }
        if kind == "event", let event = fetchEvent(planID) {
            appModel.open(event)
        } else if kind == "reminder", let reminder = fetchReminder(planID) {
            appModel.open(reminder)
        }
    }

    private func fetchEvent(_ planID: String) -> Event? {
        let descriptor = FetchDescriptor<Event>(predicate: #Predicate { $0.notificationIdentifier == planID })
        return try? container?.mainContext.fetch(descriptor).first
    }

    private func fetchReminder(_ planID: String) -> Reminder? {
        let descriptor = FetchDescriptor<Reminder>(predicate: #Predicate { $0.notificationIdentifier == planID })
        return try? container?.mainContext.fetch(descriptor).first
    }

    private func makeContent(for event: Event) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = event.title
        let time = OTWFormat.time(event.startDate)
        let meta = event.metaText
        content.body = (event.remindBefore == .atTime ? "Starting now · \(time)" : "Starts at \(time)")
            + (meta.isEmpty ? "" : " · \(meta)")
        content.sound = Self.sound
        content.categoryIdentifier = event.url.isEmpty ? Category.event : Category.eventWithURL
        var info: [String: String] = [Key.kind: "event", Key.planID: event.notificationIdentifier]
        if !event.url.isEmpty { info[Key.url] = event.url }
        content.userInfo = info
        return content
    }

    private func makeContent(for reminder: Reminder, dueDate: Date) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = "Due at \(OTWFormat.time(dueDate)) · \(reminder.priority.rawValue) priority"
        content.sound = Self.sound
        content.categoryIdentifier = Category.reminder
        content.userInfo = [Key.kind: "reminder", Key.planID: reminder.notificationIdentifier]
        return content
    }

    private func add(content: UNMutableNotificationContent, triggers: [UNCalendarNotificationTrigger], base: String) async {
        for (index, trigger) in triggers.enumerated() {
            let request = UNNotificationRequest(identifier: "\(base)-\(index)", content: withMascot(content), trigger: trigger)
            try? await center.add(request)
        }
    }

    /// Returns a copy of `content` with the mascot thumbnail attached: Wink for events,
    /// Happy for reminders. Each request gets its own temporary file because the system
    /// moves attachment files into its own store.
    private func withMascot(_ content: UNMutableNotificationContent) -> UNMutableNotificationContent {
        guard let copy = content.mutableCopy() as? UNMutableNotificationContent else { return content }
        let kind = content.userInfo[Key.kind] as? String
        let name = kind == "reminder" ? "notification_happy" : "notification_wink"
        guard let source = Bundle.main.url(forResource: name, withExtension: "png") else { return copy }

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("OTWAttachments", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent("\(name)-\(UUID().uuidString).png")
        do {
            try FileManager.default.copyItem(at: source, to: destination)
            let attachment = try UNNotificationAttachment(identifier: name, url: destination, options: nil)
            copy.attachments = [attachment]
            #if DEBUG
            print("[OTW] attached \(name) to \(content.title)")
            #endif
        } catch {
            #if DEBUG
            print("[OTW] attachment failed: \(error)")
            #endif
        }
        return copy
    }

    private func registerCategories() {
        let join = UNNotificationAction(identifier: Action.join, title: "Join", options: [.foreground])
        let done = UNNotificationAction(identifier: Action.markDone, title: "Mark as Done", options: [])
        let snooze = UNNotificationAction(identifier: Action.snooze, title: "Snooze 10 min", options: [])
        center.setNotificationCategories([
            UNNotificationCategory(identifier: Category.event, actions: [], intentIdentifiers: []),
            UNNotificationCategory(identifier: Category.eventWithURL, actions: [join], intentIdentifiers: []),
            UNNotificationCategory(identifier: Category.reminder, actions: [done, snooze], intentIdentifiers: []),
        ])
    }

    /// "meet.google.com/abc" → "https://meet.google.com/abc".
    static func webURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed.contains("://") ? trimmed : "https://" + trimmed)
    }
}
