import SwiftUI
import SwiftData

enum AppRoute: Hashable {
    case calendar
    case event(PersistentIdentifier, zoomSource: String? = nil)
    case reminder(PersistentIdentifier, zoomSource: String? = nil)
}

extension Notification.Name {
    static let otwReminderCompleted = Notification.Name("OTW.reminderCompleted")
}

@Observable
final class AppModel {
    var path: [AppRoute] = []
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)

    func openCalendar() {
        path.append(.calendar)
    }

    func open(_ event: Event, zoomSource: String? = nil) {
        path.append(.event(event.persistentModelID, zoomSource: zoomSource))
    }

    func open(_ reminder: Reminder, zoomSource: String? = nil) {
        path.append(.reminder(reminder.persistentModelID, zoomSource: zoomSource))
    }
}

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
