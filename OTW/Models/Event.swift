import Foundation
import SwiftData

@Model
final class Event {
    var title: String
    var category: PlanCategory
    var tagColor: TagColor
    var startDate: Date
    var endDate: Date
    var repeatRule: RepeatRule
    var location: String
    var url: String
    var locationKind: LocationKind
    var detail: String
    var remindBefore: RemindOffset
    var notes: String
    var createdAt: Date
    var notificationIdentifier: String = UUID().uuidString

    init(
        title: String,
        category: PlanCategory,
        tagColor: TagColor,
        startDate: Date,
        endDate: Date,
        repeatRule: RepeatRule = .never,
        location: String = "",
        url: String = "",
        locationKind: LocationKind = .place,
        detail: String = "",
        remindBefore: RemindOffset = .thirtyMinutes,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.title = title
        self.category = category
        self.tagColor = tagColor
        self.startDate = startDate
        self.endDate = endDate
        self.repeatRule = repeatRule
        self.location = location
        self.url = url
        self.locationKind = locationKind
        self.detail = detail
        self.remindBefore = remindBefore
        self.notes = notes
        self.createdAt = createdAt
        self.notificationIdentifier = UUID().uuidString
    }

    var metaText: String {
        var parts: [String] = []
        if !location.isEmpty {
            parts.append(location)
        } else if !url.isEmpty {
            parts.append(Event.friendlyName(forURL: url))
        }
        if !detail.isEmpty {
            parts.append(detail)
        }
        return parts.joined(separator: " · ")
    }

    private static func friendlyName(forURL raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("meet.google") { return "Google Meet" }
        if lower.contains("zoom.us") { return "Zoom" }
        if lower.contains("teams.microsoft") { return "Microsoft Teams" }
        return raw.split(separator: "/").first.map(String.init) ?? raw
    }
}

// MARK: - Shared enums

nonisolated enum PlanCategory: String, Codable, CaseIterable, Identifiable {
    case organization = "Organization"
    case work = "Work"
    case study = "Study"
    case personal = "Personal"

    var id: String { rawValue }
}

nonisolated enum TagColor: String, Codable, CaseIterable, Identifiable {
    case orange = "Orange"
    case blue = "Blue"
    case purple = "Purple"
    case green = "Green"
    case red = "Red"
    case yellow = "Yellow"
    case teal = "Teal"

    var id: String { rawValue }
}

nonisolated enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case never = "Never"
    case daily = "Every day"
    case weekdays = "Every weekday"
    case weekly = "Every week"
    case monthly = "Every month"

    var id: String { rawValue }
}

nonisolated enum RemindOffset: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case atTime = "At time of event"
    case fiveMinutes = "5 min before"
    case fifteenMinutes = "15 min before"
    case thirtyMinutes = "30 min before"
    case oneHour = "1 hour before"
    case oneDay = "1 day before"

    var id: String { rawValue }

    var timeInterval: TimeInterval? {
        switch self {
        case .none: nil
        case .atTime: 0
        case .fiveMinutes: 5 * 60
        case .fifteenMinutes: 15 * 60
        case .thirtyMinutes: 30 * 60
        case .oneHour: 60 * 60
        case .oneDay: 24 * 60 * 60
        }
    }
}

nonisolated enum LocationKind: String, Codable, CaseIterable {
    case online
    case place
    case person
}
