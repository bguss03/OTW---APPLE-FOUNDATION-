import Foundation
import SwiftData

@Model
final class Reminder {
    var title: String
    var category: PlanCategory
    var categoryLabel: String
    var scheduledDate: Date
    var dueDate: Date?
    var priority: Priority
    var remindBefore: RemindOffset
    var repeatRule: RepeatRule
    var notes: String
    var isDone: Bool
    var completedAt: Date?
    var createdAt: Date
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
