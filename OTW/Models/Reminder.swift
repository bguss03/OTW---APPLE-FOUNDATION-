import Foundation
import SwiftData

/// A to-do reminder. Fields mirror "v3 / Add · Reminder" and "v3 / Reminder Detail".
@Model
final class Reminder {
    /// NAME field.
    var title: String
    /// CATEGORY chips: Organization, Work, Study, Personal.
    var category: PlanCategory
    /// Free-form label shown next to the folder icon, e.g. "Design System", "Finance".
    var categoryLabel: String
    /// The day this reminder is listed on in Home (start of day).
    var scheduledDate: Date
    /// DATE & TIME chips. `nil` means the reminder is flexible (no deadline).
    var dueDate: Date?
    /// PRIORITY: High, Medium, Low.
    var priority: Priority
    /// OPTIONS › Remind Me.
    var remindBefore: RemindOffset
    /// OPTIONS › Repeat.
    var repeatRule: RepeatRule
    /// NOTES card.
    var notes: String
    /// Checkbox / "Mark as Done".
    var isDone: Bool
    /// When the reminder was marked done; drives "Done · 09:41".
    var completedAt: Date?
    var createdAt: Date
    /// Stable identifier for the local notification scheduled for this reminder.
    var notificationIdentifier: String = UUID().uuidString

    init(
        title: String,
        category: PlanCategory,
        categoryLabel: String,
        scheduledDate: Date,
        dueDate: Date?,
        priority: Priority,
        remindBefore: RemindOffset = .oneHour,
        repeatRule: RepeatRule = .never,
        notes: String = "",
        isDone: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.title = title
        self.category = category
        self.categoryLabel = categoryLabel
        self.scheduledDate = Calendar.current.startOfDay(for: scheduledDate)
        self.dueDate = dueDate
        self.priority = priority
        self.remindBefore = remindBefore
        self.repeatRule = repeatRule
        self.notes = notes
        self.isDone = isDone
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.notificationIdentifier = UUID().uuidString
    }

    /// Toggles completion and records the completion time.
    func toggleDone(at date: Date = .now) {
        isDone.toggle()
        completedAt = isDone ? date : nil
    }
}

nonisolated enum Priority: String, Codable, CaseIterable, Identifiable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var id: String { rawValue }
}
