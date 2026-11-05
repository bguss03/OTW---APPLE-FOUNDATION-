import Foundation
import SwiftUI
import SwiftData

/// What a tapped calendar item opens.
enum PlanDetailTarget: Hashable, Identifiable {
    case event(Event)
    case reminder(Reminder)

    var id: PersistentIdentifierBox {
        switch self {
        case .event(let event): PersistentIdentifierBox(event.persistentModelID)
        case .reminder(let reminder): PersistentIdentifierBox(reminder.persistentModelID)
        }
    }

    var title: String {
        switch self {
        case .event(let event): event.title
        case .reminder(let reminder): reminder.title
        }
    }
}

/// Hashable wrapper so `PlanDetailTarget` can be used as an identifier.
struct PersistentIdentifierBox: Hashable {
    let id: PersistentIdentifier
    init(_ id: PersistentIdentifier) { self.id = id }
}

/// Pure layout of one month: 6 week rows, 7 columns, plus the pills and bars placed into lanes.
struct MonthLayout {
    static let rowCount = 6
    static let columnCount = 7
    /// Only two lanes of pills fit under the day number in a 78pt row.
    static let visibleLanes = 2

    struct Day: Hashable {
        let date: Date
        let isWeekend: Bool
    }

    enum PillStyle: Hashable {
        /// Single-day event: tinted background, tag-coloured text.
        case event(TagColor)
        /// Multi-day event bar: solid tag colour, white text.
        case span(TagColor)
        /// Reminder: pale orange background, soft orange text.
        case reminder
    }

    struct Segment: Identifiable, Hashable {
        let id: String
        let row: Int
        let column: Int
        let span: Int
        var lane: Int
        let title: String
        let style: PillStyle
        let target: PlanDetailTarget
        /// True when this segment continues a bar from the previous row.
        let continuesFromPreviousRow: Bool
    }

    struct Overflow: Identifiable, Hashable {
        var id: String { "\(row)-\(column)" }
        let row: Int
        let column: Int
        let count: Int
    }

    let month: Date
    /// 6 x 7 cells; `nil` for days outside the month.
    let cells: [[Day?]]
    let segments: [Segment]
    let overflows: [Overflow]

    // MARK: - Building

    init(month: Date, events: [Event], reminders: [Reminder], calendar: Calendar) {
        let monthStart = calendar.startOfDay(for: calendar.dateInterval(of: .month, for: month)?.start ?? month)
        self.month = monthStart

        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7

        // Grid cells.
        var cells: [[Day?]] = Array(repeating: Array(repeating: nil, count: Self.columnCount), count: Self.rowCount)
        var dateAt: [Int: Date] = [:] // slot index -> date
        for dayIndex in 0..<dayCount {
            let slot = leading + dayIndex
            guard slot < Self.rowCount * Self.columnCount,
                  let date = calendar.date(byAdding: .day, value: dayIndex, to: monthStart) else { continue }
            cells[slot / Self.columnCount][slot % Self.columnCount] = Day(date: date, isWeekend: calendar.isDateInWeekend(date))
            dateAt[slot] = date
        }
        self.cells = cells

        let lastSlot = leading + dayCount - 1
        func slot(for date: Date) -> Int? {
            let day = calendar.startOfDay(for: date)
            guard let offset = calendar.dateComponents([.day], from: monthStart, to: day).day else { return nil }
            return leading + offset
        }

        // Raw items, split into per-row segments. Ordering decides lane priority:
        // longer bars first, then single-day events by start, then reminders.
        struct RawItem {
            let title: String
            let style: PillStyle
            let target: PlanDetailTarget
            let startSlot: Int
            let endSlot: Int
            let sortDate: Date
        }

        var raw: [RawItem] = []
        for event in events {
            guard let start = slot(for: event.startDate), let end = slot(for: event.endDate) else { continue }
            let clippedStart = max(start, leading)
            let clippedEnd = min(end, lastSlot)
            guard clippedStart <= clippedEnd else { continue }
            let isSpan = end > start
            raw.append(RawItem(
                title: event.title,
                style: isSpan ? .span(event.tagColor) : .event(event.tagColor),
                target: .event(event),
                startSlot: clippedStart,
                endSlot: clippedEnd,
                sortDate: event.startDate
            ))
        }
        for reminder in reminders {
            guard let start = slot(for: reminder.scheduledDate), start >= leading, start <= lastSlot else { continue }
            raw.append(RawItem(
                title: reminder.title,
                style: .reminder,
                target: .reminder(reminder),
                startSlot: start,
                endSlot: start,
                sortDate: reminder.dueDate ?? reminder.scheduledDate
            ))
        }
        raw.sort { lhs, rhs in
            let lhsLength = lhs.endSlot - lhs.startSlot
            let rhsLength = rhs.endSlot - rhs.startSlot
            if lhsLength != rhsLength { return lhsLength > rhsLength }
            let lhsReminder = lhs.style == .reminder
            let rhsReminder = rhs.style == .reminder
            if lhsReminder != rhsReminder { return !lhsReminder }
            return lhs.sortDate < rhs.sortDate
        }

        // Lane assignment per row.
        var occupancy: [[[Bool]]] = Array(
            repeating: Array(repeating: Array(repeating: false, count: Self.columnCount), count: 8),
            count: Self.rowCount
        )
        var segments: [Segment] = []
        var hiddenPerSlot: [Int: Int] = [:]

        for (index, item) in raw.enumerated() {
            var cursor = item.startSlot
            while cursor <= item.endSlot {
                let row = cursor / Self.columnCount
                let column = cursor % Self.columnCount
                let rowEndSlot = row * Self.columnCount + Self.columnCount - 1
                let segmentEnd = min(item.endSlot, rowEndSlot)
                let span = segmentEnd - cursor + 1

                var lane = 0
                while lane < occupancy[row].count {
                    let free = (column..<(column + span)).allSatisfy { !occupancy[row][lane][$0] }
                    if free { break }
                    lane += 1
                }
                if lane < occupancy[row].count {
                    for c in column..<(column + span) { occupancy[row][lane][c] = true }
                }
                if lane < Self.visibleLanes {
                    segments.append(Segment(
                        id: "\(index)-\(row)",
                        row: row,
                        column: column,
                        span: span,
                        lane: lane,
                        title: item.title,
                        style: item.style,
                        target: item.target,
                        continuesFromPreviousRow: cursor != item.startSlot
                    ))
                } else {
                    for s in cursor...segmentEnd { hiddenPerSlot[s, default: 0] += 1 }
                }
                cursor = segmentEnd + 1
            }
        }

        // Days with hidden items show "+N" in the second lane, replacing a single-day pill there.
        var overflows: [Overflow] = []
        for (slotIndex, hidden) in hiddenPerSlot.sorted(by: { $0.key < $1.key }) {
            let row = slotIndex / Self.columnCount
            let column = slotIndex % Self.columnCount
            var count = hidden
            if let replaced = segments.firstIndex(where: { $0.row == row && $0.column == column && $0.span == 1 && $0.lane == Self.visibleLanes - 1 }) {
                segments.remove(at: replaced)
                count += 1
            }
            overflows.append(Overflow(row: row, column: column, count: count))
        }

        self.segments = segments
        self.overflows = overflows
    }

    /// Number of week rows actually used by this month (5 or 6).
    var usedRowCount: Int {
        cells.lastIndex { row in row.contains { $0 != nil } }.map { $0 + 1 } ?? Self.rowCount
    }
}
