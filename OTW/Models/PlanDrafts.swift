import Foundation

/// Editable copy of an `Event` used by the New Plan / Edit screens.
struct EventDraft: Equatable {
    var title = ""
    var category: PlanCategory = .organization
    var tagColor: TagColor = .orange
    var startDate: Date
    var endDate: Date
    var location = ""
    var url = ""
    var remindBefore: RemindOffset = .thirtyMinutes
    var repeatRule: RepeatRule = .never
    var notes = ""

    /// New event: starts at the next full hour on the day selected on Home, lasts one hour.
    init(selectedDate: Date, now: Date = .now) {
        startDate = PlanDefaults.nextFullHour(on: selectedDate, now: now)
        endDate = startDate.addingTimeInterval(PlanDefaults.defaultDuration)
    }

    /// Prefill from an existing event (used by Edit later).
    init(event: Event) {
        title = event.title
        category = event.category
        tagColor = event.tagColor
        startDate = event.startDate
        endDate = event.endDate
        location = event.location
        url = event.url
        remindBefore = event.remindBefore
        repeatRule = event.repeatRule
        notes = event.notes
    }

    var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { !trimmedTitle.isEmpty }

    /// Soft URL check: empty is fine, otherwise it must look like a host with a dot.
    var isURLValid: Bool {
        PlanDefaults.looksLikeURL(url)
    }

    /// Moves the start and keeps the end after it, preserving the previous duration.
    mutating func setStart(_ newStart: Date) {
        let duration = max(endDate.timeIntervalSince(startDate), 60)
        startDate = newStart
        if endDate <= newStart {
            endDate = newStart.addingTimeInterval(duration)
        }
    }

    mutating func setEnd(_ newEnd: Date) {
        endDate = max(newEnd, startDate.addingTimeInterval(60))
    }

    private var locationKind: LocationKind {
        if location.isEmpty && !url.isEmpty { return .online }
        return .place
    }

    func makeEvent() -> Event {
        Event(
            title: trimmedTitle,
            category: category,
            tagColor: tagColor,
            startDate: startDate,
            endDate: endDate,
            repeatRule: repeatRule,
            location: location.trimmingCharacters(in: .whitespaces),
            url: url.trimmingCharacters(in: .whitespaces),
            locationKind: locationKind,
            remindBefore: remindBefore,
            notes: notes
        )
    }

    func apply(to event: Event) {
        event.title = trimmedTitle
        event.category = category
        event.tagColor = tagColor
        event.startDate = startDate
        event.endDate = endDate
        event.repeatRule = repeatRule
        event.location = location.trimmingCharacters(in: .whitespaces)
        event.url = url.trimmingCharacters(in: .whitespaces)
        event.locationKind = locationKind
        event.remindBefore = remindBefore
        event.notes = notes
    }
}

/// Editable copy of a `Reminder` used by the New Plan / Edit screens.
struct ReminderDraft: Equatable {
    var title = ""
    var category: PlanCategory = .organization
    /// Free-form label such as "Design System"; kept when the category is unchanged.
    var categoryLabel = ""
    private var originalCategory: PlanCategory?
    var dueDate: Date
    var priority: Priority = .high
    var remindBefore: RemindOffset = .oneHour
    var repeatRule: RepeatRule = .never
    var notes = ""

    init(selectedDate: Date, now: Date = .now) {
        dueDate = PlanDefaults.nextFullHour(on: selectedDate, now: now)
    }

    init(reminder: Reminder) {
        title = reminder.title
        category = reminder.category
        categoryLabel = reminder.categoryLabel
        originalCategory = reminder.category
        dueDate = reminder.dueDate ?? reminder.scheduledDate
        priority = reminder.priority
        remindBefore = reminder.remindBefore
        repeatRule = reminder.repeatRule
        notes = reminder.notes
    }

    var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { !trimmedTitle.isEmpty }

    private var resolvedCategoryLabel: String {
        if category == originalCategory, !categoryLabel.isEmpty { return categoryLabel }
        return category.rawValue
    }

    func makeReminder() -> Reminder {
        Reminder(
            title: trimmedTitle,
            category: category,
            categoryLabel: category.rawValue,
            scheduledDate: dueDate,
            dueDate: dueDate,
            priority: priority,
            remindBefore: remindBefore,
            repeatRule: repeatRule,
            notes: notes
        )
    }

    func apply(to reminder: Reminder) {
        reminder.title = trimmedTitle
        reminder.category = category
        reminder.categoryLabel = resolvedCategoryLabel
        reminder.scheduledDate = Calendar.current.startOfDay(for: dueDate)
        reminder.dueDate = dueDate
        reminder.priority = priority
        reminder.remindBefore = remindBefore
        reminder.repeatRule = repeatRule
        reminder.notes = notes
    }
}

enum PlanDefaults {
    static let defaultDuration: TimeInterval = 60 * 60

    /// The next full hour of `now`, placed on `day`.
    static func nextFullHour(on day: Date, now: Date) -> Date {
        let calendar = Calendar.current
        let hour = min(calendar.component(.hour, from: now) + 1, 23)
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    /// Accepts "meet.google.com/abc" or "https://example.com"; rejects strings without a dotted host.
    static func looksLikeURL(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        if trimmed.contains(" ") { return false }
        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let components = URLComponents(string: candidate), let host = components.host else { return false }
        return host.contains(".") && !host.hasPrefix(".") && !host.hasSuffix(".")
    }
}
