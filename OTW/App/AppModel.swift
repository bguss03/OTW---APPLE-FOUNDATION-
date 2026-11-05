// xcode: set sdk=iOS

import SwiftUI
import SwiftData

/// Screens pushed on the main navigation stack.
enum AppRoute: Hashable {
    case calendar
    case event(PersistentIdentifier, zoomSource: String? = nil)
    case reminder(PersistentIdentifier, zoomSource: String? = nil)
}

extension Notification.Name {
    /// Posted when a reminder is checked done anywhere in the app.
    static let otwReminderCompleted = Notification.Name("OTW.reminderCompleted")
}

/// App-wide navigation and the day shared by Home and Calendar.
@Observable
final class AppModel {
    var path: [AppRoute] = []
    /// The day selected on Home's date strip and in the Calendar grid.
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)

    func openCalendar() {
        path.append(.calendar)
    }

    /// `zoomSource` is the card's transition id for the iOS 18 zoom; nil uses a normal push.
    func open(_ event: Event, zoomSource: String? = nil) {
        path.append(.event(event.persistentModelID, zoomSource: zoomSource))
    }

    func open(_ reminder: Reminder, zoomSource: String? = nil) {
        path.append(.reminder(reminder.persistentModelID, zoomSource: zoomSource))
    }
}

/// Mutations that must keep SwiftData and scheduled notifications in sync.
enum PlanActions {
    static func toggleDone(_ reminder: Reminder, in context: ModelContext) {
        reminder.toggleDone()
        try? context.save()
        if reminder.isDone {
            NotificationCenter.default.post(name: .otwReminderCompleted, object: nil)
        }
        Task { await NotificationManager.shared.schedule(reminder, requestingPermission: false) }
    }

    static func delete(_ event: Event, in context: ModelContext) {
        let identifier = event.notificationIdentifier
        context.delete(event)
        try? context.save()
        Task { await NotificationManager.shared.cancel(identifier) }
    }

    static func delete(_ reminder: Reminder, in context: ModelContext) {
        let identifier = reminder.notificationIdentifier
        context.delete(reminder)
        try? context.save()
        Task { await NotificationManager.shared.cancel(identifier) }
    }
}
