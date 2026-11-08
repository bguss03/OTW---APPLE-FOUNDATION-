import SwiftUI
import UIKit

struct DateStripView: View {
    let today: Date
    @Binding var selectedDate: Date
    let hasEvents: (Date) -> Bool
    let hasReminders: (Date) -> Bool

    @State private var days: [Date]
    @State private var position: Date?
    @State private var isSettled = false

    @State private var tickDay: Date?
    @State private var measuredDayCount = 0
    @State private var isProgrammaticScroll = false
    @State private var settleTask: Task<Void, Never>?
    @State private var hasMovedSinceSettle = false
    @State private var isVisible = false
    @State private var hasPendingTick = false

    private let calendar = Calendar.current

    private static let visibleDays: CGFloat = 7
    private static let initialSpan = 365
    private static let extensionSpan = 180
    private static let extensionThreshold = 30

    init(
        today: Date,
        selectedDate: Binding<Date>,
        hasEvents: @escaping (Date) -> Bool,
        hasReminders: @escaping (Date) -> Bool
    ) {
        self.today = today
        _selectedDate = selectedDate
        self.hasEvents = hasEvents
        self.hasReminders = hasReminders

        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: today)
        _days = State(initialValue: Self.makeDays(
            from: calendar.date(byAdding: .day, value: -Self.initialSpan, to: anchor) ?? anchor,
            count: Self.initialSpan * 2 + 1,
            calendar: calendar
        ))
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let cellWidth = (width / Self.visibleDays).rounded(.down)
            let sideMargin = (width - cellWidth) / 2

            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.activePill, style: .continuous)
                    .fill(Theme.Colors.accent)
                    .frame(width: Theme.Size.activePillWidth, height: Theme.Size.dateStripHeight)
                    .themeShadow(Theme.Shadow.activePill)

                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(days, id: \.self) { day in
                            Button {
                                if !calendar.isDate(day, inSameDayAs: selectedDate) {
                                    isProgrammaticScroll = true
                                    selectedDate = day
                                }
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    position = day
                                }
                            } label: {
                                DateCell(
                                    day: day,
                                    width: cellWidth,
                                    showsEventDot: hasEvents(day),
                                    showsReminderDot: hasReminders(day)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.pressable)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(OTWFormat.eyebrow(day).capitalized)
                            .accessibilityAddTraits(day == position ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                    .scrollTargetLayout()
                    .onGeometryChange(for: CGFloat.self) { geometry in
                        geometry.frame(in: .scrollView(axis: .horizontal)).minX
                    } action: { minX in
                        centeredDayChanged(minX: minX, cellWidth: cellWidth, sideMargin: sideMargin)
                    }
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $position, anchor: .center)
                .contentMargins(.horizontal, sideMargin, for: .scrollContent)
                .defaultScrollAnchor(.center)
                .scrollIndicators(.hidden)
                .onScrollIdle { scrollDidSettle() }
                .onChange(of: selectedDate) { _, newValue in
                    let day = calendar.startOfDay(for: newValue)
                    guard position != day else { return }
                    isProgrammaticScroll = true
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        position = day
                    }
                }
                .task {
                    try? await Task.sleep(for: .milliseconds(150))
                    let day = calendar.startOfDay(for: selectedDate)
                    if position != day {
                        position = day
                    }
                    try? await Task.sleep(for: .milliseconds(350))
                    isSettled = true
                }
            }
            .frame(width: width, height: Theme.Size.dateStripHeight)
        }
        .frame(height: Theme.Size.dateStripHeight)
        .onAppear {
            isVisible = true
            if hasPendingTick {
                hasPendingTick = false
                TickFeedback.shared.tick()
            }
        }
        .onDisappear { isVisible = false }
        .onChange(of: position) { _, newValue in
            guard let newValue else { return }
            if !isSettled {
                let day = calendar.startOfDay(for: selectedDate)
                if !calendar.isDate(newValue, inSameDayAs: day) {
                    position = day
                }
                return
            }
            if !calendar.isDate(newValue, inSameDayAs: selectedDate) {
                selectedDate = newValue
            }
            extendRangeIfNeeded(around: newValue)
        }
    }

    // MARK: - Picker feedback

    private func centeredDayChanged(minX: CGFloat, cellWidth: CGFloat, sideMargin: CGFloat) {
        guard isSettled, cellWidth > 0 else { return }
        let index = Int(((sideMargin - minX) / cellWidth).rounded())
        guard days.indices.contains(index) else { return }
        let day = days[index]

        if days.count != measuredDayCount || tickDay == nil {
            measuredDayCount = days.count
            tickDay = day
            return
        }
        guard day != tickDay else { return }
        tickDay = day

        if !isProgrammaticScroll && isVisible {
            if !hasMovedSinceSettle { TickFeedback.shared.prepare() }
            TickFeedback.shared.tick()
        }
        hasMovedSinceSettle = true
        if #available(iOS 18.0, *) { scheduleFallbackSettle(after: .milliseconds(600)) } else { scheduleFallbackSettle(after: .milliseconds(300)) }
    }

    private func scrollDidSettle() {
        guard hasMovedSinceSettle else { return }
        hasMovedSinceSettle = false
        settleTask?.cancel()
        settleTask = nil
        if isProgrammaticScroll {
            isProgrammaticScroll = false
            if isVisible { TickFeedback.shared.tick() } else { hasPendingTick = true }
        } else if isVisible {
            TickFeedback.shared.settle()
        }
    }

    private func scheduleFallbackSettle(after delay: Duration) {
        settleTask?.cancel()
        settleTask = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            scrollDidSettle()
        }
    }

    // MARK: - Date range

    private static func makeDays(from start: Date, count: Int, calendar: Calendar) -> [Date] {
        (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func extendRangeIfNeeded(around day: Date) {
        guard let index = days.firstIndex(of: day), let first = days.first, let last = days.last else { return }

        if index < Self.extensionThreshold {
            let newStart = calendar.date(byAdding: .day, value: -Self.extensionSpan, to: first) ?? first
            let earlier = Self.makeDays(from: newStart, count: Self.extensionSpan, calendar: calendar)
            days.insert(contentsOf: earlier, at: 0)
        } else if index > days.count - 1 - Self.extensionThreshold {
            let newStart = calendar.date(byAdding: .day, value: 1, to: last) ?? last
            let later = Self.makeDays(from: newStart, count: Self.extensionSpan, calendar: calendar)
            days.append(contentsOf: later)
        }
    }
}

// MARK: - Cell

private struct DateCell: View {
    let day: Date
    let width: CGFloat
    let showsEventDot: Bool
    let showsReminderDot: Bool

    var body: some View {
        ZStack {
            layer(selected: false)
                .visualEffect { content, proxy in
                    content.opacity(1 - DateCell.selection(for: proxy))
                }
            layer(selected: true)
                .visualEffect { content, proxy in
                    content.opacity(DateCell.selection(for: proxy))
                }
        }
        .frame(width: width, height: Theme.Size.dateStripHeight)
    }

    private func layer(selected: Bool) -> some View {
        VStack(spacing: 0) {
            Text(OTWFormat.weekday(day))
                .font(Theme.Fonts.dayLabel)
                .foregroundStyle(selected ? Theme.Colors.onAccent : Theme.Colors.secondaryLabel)
                .frame(height: 16)

            Text(OTWFormat.dayNumber(day))
                .font(Theme.Fonts.dayNumber)
                .foregroundStyle(selected ? Theme.Colors.onAccent : Theme.Colors.label)
                .frame(height: 23)
                .padding(.top, 5)

            HStack(spacing: 4) {
                if showsEventDot {
                    Circle()
                        .fill(selected ? Theme.Colors.onAccent : Theme.Colors.accent)
                        .frame(width: Theme.Size.dateDot, height: Theme.Size.dateDot)
                }
                if showsReminderDot {
                    Circle()
                        .fill(selected ? Theme.Colors.onAccent.opacity(0.6) : Theme.Colors.accentPale)
                        .frame(width: Theme.Size.dateDot, height: Theme.Size.dateDot)
                }
            }
            .frame(height: Theme.Size.dateDot)
            .padding(.top, 8)
        }
        .padding(.top, 11)
        .frame(width: width, height: Theme.Size.dateStripHeight, alignment: .top)
    }

    nonisolated private static func selection(for proxy: GeometryProxy) -> Double {
        let frame = proxy.frame(in: .scrollView(axis: .horizontal))
        guard let bounds = proxy.bounds(of: .scrollView(axis: .horizontal)) else { return 0 }
        let distance = abs(frame.midX - bounds.midX)
        let cellWidth = max(frame.width, 1)
        return max(0, 1 - distance / cellWidth)
    }
}

#Preview {
    @Previewable @State var selected = Calendar.current.startOfDay(for: .now)
    DateStripView(
        today: .now,
        selectedDate: $selected,
        hasEvents: { Calendar.current.isDateInToday($0) },
        hasReminders: { Calendar.current.isDateInTomorrow($0) || Calendar.current.isDateInToday($0) }
    )
}

private extension View {
    @ViewBuilder
    func onScrollIdle(_ action: @escaping () -> Void) -> some View {
        if #available(iOS 18.0, *) {
            onScrollPhaseChange { oldPhase, newPhase in
                if newPhase == .idle && oldPhase != .idle { action() }
            }
        } else {
            self
        }
    }
}
