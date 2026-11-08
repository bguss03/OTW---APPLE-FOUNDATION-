import SwiftUI

struct MonthGridView: View {
    static let rowHeight: CGFloat = 78
    static let gridHeight: CGFloat = rowHeight * CGFloat(MonthLayout.rowCount)
    private static let pillHeight: CGFloat = 17
    private static let pillTop: CGFloat = 38
    private static let lanePitch: CGFloat = 19
    private static let pillInset: CGFloat = 2

    let layout: MonthLayout
    let today: Date
    let selectedDate: Date
    let onSelect: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        GeometryReader { proxy in
            let cellWidth = proxy.size.width / CGFloat(MonthLayout.columnCount)

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<MonthLayout.rowCount, id: \.self) { row in
                        ZStack(alignment: .top) {
                            if row < layout.usedRowCount {
                                Rectangle()
                                    .fill(Theme.Colors.separator)
                                    .frame(height: 1)
                            }
                            HStack(spacing: 0) {
                                ForEach(0..<MonthLayout.columnCount, id: \.self) { column in
                                    dayCell(layout.cells[row][column])
                                        .frame(width: cellWidth, height: Self.rowHeight, alignment: .top)
                                }
                            }
                        }
                        .frame(height: Self.rowHeight)
                    }
                }

                ForEach(layout.segments) { segment in
                    pill(segment)
                        .frame(
                            width: CGFloat(segment.span) * cellWidth - Self.pillInset * 2,
                            height: Self.pillHeight
                        )
                        .offset(
                            x: CGFloat(segment.column) * cellWidth + Self.pillInset,
                            y: CGFloat(segment.row) * Self.rowHeight + Self.pillTop + CGFloat(segment.lane) * Self.lanePitch
                        )
                }

                ForEach(layout.overflows) { overflow in
                    Text("+\(overflow.count)")
                        .font(Theme.Fonts.calendarPill)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(width: cellWidth - Self.pillInset * 2, height: Self.pillHeight)
                        .offset(
                            x: CGFloat(overflow.column) * cellWidth + Self.pillInset,
                            y: CGFloat(overflow.row) * Self.rowHeight + Self.pillTop + CGFloat(MonthLayout.visibleLanes - 1) * Self.lanePitch
                        )
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(height: Self.gridHeight)
    }

    // MARK: - Pieces

    @ViewBuilder
    private func dayCell(_ day: MonthLayout.Day?) -> some View {
        if let day {
            let isToday = calendar.isDate(day.date, inSameDayAs: today)
            let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
            Button {
                onSelect(day.date)
            } label: {
                ZStack {
                    if isToday {
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: 30, height: 30)
                            .shadow(color: Theme.Colors.accent.opacity(0.35), radius: 5, y: 4)
                    } else if isSelected {
                        Circle()
                            .fill(Theme.Colors.accentTint)
                            .frame(width: 30, height: 30)
                    }
                    Text(OTWFormat.dayNumber(day.date))
                        .font(isToday ? Theme.Fonts.calendarToday : Theme.Fonts.calendarDay)
                        .foregroundStyle(numberColor(isToday: isToday, isSelected: isSelected, isWeekend: day.isWeekend))
                }
                .frame(width: 30, height: 30)
                .padding(.top, 4)
                .frame(maxWidth: .infinity)
                .frame(height: Self.rowHeight, alignment: .top)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(OTWFormat.dayTitle(day.date))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            Color.clear
        }
    }

    private func numberColor(isToday: Bool, isSelected: Bool, isWeekend: Bool) -> Color {
        if isToday { return Theme.Colors.onAccent }
        if isSelected { return Theme.Colors.accent }
        return isWeekend ? Theme.Colors.weekendDate : Theme.Colors.label
    }

    private func pill(_ segment: MonthLayout.Segment) -> some View {
        let colors = pillColors(segment.style)
        return Group {
            Text(segment.title)
                .font(Theme.Fonts.calendarPill)
                .foregroundStyle(colors.foreground)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .frame(height: Self.pillHeight)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(colors.background)
                )
                .contentShape(Rectangle())
        }
        .allowsHitTesting(false)
        .accessibilityLabel(segment.title)
    }

    private func pillColors(_ style: MonthLayout.PillStyle) -> (background: Color, foreground: Color) {
        switch style {
        case .event(let tag): (tag.color.opacity(0.15), tag.color)
        case .span(let tag): (tag.color, Theme.Colors.onAccent)
        case .reminder: (Theme.Colors.accentTintLow, Theme.Colors.accentSoft)
        }
    }
}

struct WeekdayHeaderView: View {
    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<MonthLayout.columnCount, id: \.self) { column in
                let weekday = ((calendar.firstWeekday - 1 + column) % 7) + 1
                Text(calendar.veryShortWeekdaySymbols[weekday - 1])
                    .font(Theme.Fonts.section)
                    .foregroundStyle(isWeekend(weekday) ? Theme.Colors.weekendHeader : Theme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 16)
    }

    private func isWeekend(_ weekday: Int) -> Bool {
        var components = DateComponents()
        components.weekday = weekday
        components.weekdayOrdinal = 1
        components.month = 1
        components.year = 2024
        guard let date = calendar.date(from: components) else { return weekday == 1 || weekday == 7 }
        return calendar.isDateInWeekend(date)
    }
}
