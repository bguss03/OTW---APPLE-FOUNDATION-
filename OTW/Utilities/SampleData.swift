import Foundation
import SwiftData

/// Seed data reproducing the texts in the "v3 / Home" and "v3 / Calendar" Sketch frames,
/// placed relative to today so the strip, grid and lists are never empty.
enum SampleData {
    /// Bump when the sample set changes so an existing store is re-seeded.
    private static let seedVersion = 5
    private static let seedVersionKey = "OTW.sampleDataSeedVersion"

    /// Inserts sample events and reminders if the store is empty or seeded with an older set.
    static func seedIfNeeded(in context: ModelContext) {
        let eventCount = (try? context.fetchCount(FetchDescriptor<Event>())) ?? 0
        let reminderCount = (try? context.fetchCount(FetchDescriptor<Reminder>())) ?? 0
        let storedVersion = UserDefaults.standard.integer(forKey: seedVersionKey)

        if eventCount > 0 || reminderCount > 0 {
            guard storedVersion < seedVersion else { return }
            try? context.delete(model: Event.self)
            try? context.delete(model: Reminder.self)
        }

        let today = Calendar.current.startOfDay(for: .now)
        for event in events(relativeTo: today) { context.insert(event) }
        for reminder in reminders(relativeTo: today) { context.insert(reminder) }
        try? context.save()
        UserDefaults.standard.set(seedVersion, forKey: seedVersionKey)
    }

    // MARK: - Events

    static func events(relativeTo today: Date) -> [Event] {
        let calendar = Calendar.current
        let inTwoDays = day(today, offset: 2)

        // A multi-day event that is guaranteed to cross a week boundary: it starts two days
        // before the start of last week and ends two days after it.
        let lastWeekStart = startOfWeek(containing: day(today, offset: -7), calendar: calendar)
        let midtermStart = day(lastWeekStart, offset: -2)
        let midtermEnd = day(lastWeekStart, offset: 2)

        return [
            // v3 / Home – May 3 · Events → today
            Event(
                title: "Daily Standup",
                category: .work,
                tagColor: .blue,
                startDate: at(today, 9, 0),
                endDate: at(today, 10, 30),
                repeatRule: .weekdays,
                url: "meet.google.com/otw-sprint42",
                locationKind: .online,
                detail: "Sprint 42",
                remindBefore: .thirtyMinutes,
                notes: "Review Sprint 42 progress, design blockers on the Calendar page, and split prototype tasks for Monday demo."
            ),
            Event(
                title: "UI/UX Design Critique",
                category: .work,
                tagColor: .purple,
                startDate: at(today, 13, 0),
                endDate: at(today, 14, 15),
                location: "Creative Room 2A",
                locationKind: .place,
                detail: "Design Squad"
            ),
            Event(
                title: "1-on-1 Mentoring",
                category: .work,
                tagColor: .green,
                startDate: at(today, 16, 30),
                endDate: at(today, 17, 30),
                location: "Lead Designer",
                locationKind: .person,
                detail: "Q2 Goals"
            ),
            Event(
                title: "Organization Meeting",
                category: .organization,
                tagColor: .orange,
                startDate: at(today, 19, 0),
                endDate: at(today, 21, 0),
                location: "UC Tower, 7th Floor",
                locationKind: .place
            ),
            // v3 / Home – May 5 · Events → today + 2
            Event(
                title: "Calculus Class",
                category: .study,
                tagColor: .teal,
                startDate: at(inTwoDays, 10, 0),
                endDate: at(inTwoDays, 12, 0),
                location: "Room 301",
                locationKind: .place,
                detail: "Calculus II"
            ),
            Event(
                title: "Gym Session",
                category: .personal,
                tagColor: .red,
                startDate: at(inTwoDays, 15, 0),
                endDate: at(inTwoDays, 16, 0),
                location: "Fitness First",
                locationKind: .place,
                detail: "Leg Day"
            ),
            // v3 / Calendar → multi-day and scattered single-day events
            Event(
                title: "Sprint Review",
                category: .work,
                tagColor: .blue,
                startDate: at(day(today, offset: -12), 9, 0),
                endDate: at(day(today, offset: -10), 17, 0),
                location: "Main Hall",
                locationKind: .place,
                detail: "Sprint 41"
            ),
            Event(
                title: "Midterm Exams",
                category: .study,
                tagColor: .purple,
                startDate: at(midtermStart, 8, 0),
                endDate: at(midtermEnd, 12, 0),
                location: "Campus",
                locationKind: .place,
                detail: "Semester 4"
            ),
            Event(
                title: "Futsal",
                category: .personal,
                tagColor: .green,
                startDate: at(day(today, offset: -9), 19, 0),
                endDate: at(day(today, offset: -9), 21, 0),
                location: "Arena 5",
                locationKind: .place
            ),
            Event(
                title: "UI Workshop",
                category: .work,
                tagColor: .green,
                startDate: at(day(today, offset: 3), 9, 0),
                endDate: at(day(today, offset: 5), 16, 0),
                location: "Studio B",
                locationKind: .place,
                detail: "Design Squad"
            ),
            Event(
                title: "Calculus",
                category: .study,
                tagColor: .purple,
                startDate: at(day(today, offset: 8), 10, 0),
                endDate: at(day(today, offset: 8), 12, 0),
                location: "Room 301",
                locationKind: .place,
                detail: "Calculus II"
            ),
        ]
    }

    // MARK: - Reminders

    static func reminders(relativeTo today: Date) -> [Reminder] {
        let tomorrow = day(today, offset: 1)
        let inThreeDays = day(today, offset: 3)
        return [
            // v3 / Home – May 3 · Reminders → today
            Reminder(
                title: "Finalize Mobile Prototype",
                category: .work,
                categoryLabel: "Design System",
                scheduledDate: today,
                dueDate: at(today, 18, 0),
                priority: .high,
                remindBefore: .oneHour,
                notes: "Polish the Home & Calendar flow, then share the prototype link with the team before 18:00."
            ),
            Reminder(
                title: "Send Client Invoice",
                category: .work,
                categoryLabel: "Finance",
                scheduledDate: today,
                dueDate: at(today, 20, 0),
                priority: .high
            ),
            Reminder(
                title: "Review PR & Code Cleanup",
                category: .work,
                categoryLabel: "GitHub Repo",
                scheduledDate: today,
                dueDate: at(tomorrow, 12, 0),
                priority: .medium
            ),
            Reminder(
                title: "Update Notion Docs",
                category: .organization,
                categoryLabel: "Team Wiki",
                scheduledDate: today,
                dueDate: nil,
                priority: .low
            ),
            // v3 / Home – May 6 · Reminders → today + 3
            Reminder(
                title: "Calculus Assignment",
                category: .study,
                categoryLabel: "Calculus II",
                scheduledDate: inThreeDays,
                dueDate: at(inThreeDays, 23, 59),
                priority: .high
            ),
            Reminder(
                title: "Buy Groceries",
                category: .personal,
                categoryLabel: "Personal",
                scheduledDate: inThreeDays,
                dueDate: at(inThreeDays, 17, 0),
                priority: .low
            ),
            // v3 / Calendar → scattered reminders
            Reminder(
                title: "Pay Rent",
                category: .personal,
                categoryLabel: "Finance",
                scheduledDate: day(today, offset: -20),
                dueDate: at(day(today, offset: -20), 10, 0),
                priority: .high,
                isDone: true,
                completedAt: at(day(today, offset: -20), 9, 12)
            ),
            Reminder(
                title: "Calc HW",
                category: .study,
                categoryLabel: "Calculus II",
                scheduledDate: day(today, offset: -14),
                dueDate: at(day(today, offset: -14), 20, 0),
                priority: .medium,
                isDone: true,
                completedAt: at(day(today, offset: -14), 19, 40)
            ),
            Reminder(
                title: "Deadline",
                category: .work,
                categoryLabel: "Client Project",
                scheduledDate: day(today, offset: 9),
                dueDate: at(day(today, offset: 9), 17, 0),
                priority: .high
            ),
        ]
    }

    // MARK: - Helpers

    private static func day(_ base: Date, offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: base) ?? base
    }

    private static func at(_ day: Date, _ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static func startOfWeek(containing date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
}
