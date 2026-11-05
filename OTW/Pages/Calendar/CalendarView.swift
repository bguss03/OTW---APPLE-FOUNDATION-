// xcode: set sdk=iOS

import SwiftUI
import SwiftData

/// Rebuild of "v3 / Calendar": month title, weekday header, paged month grid with pills,
/// and the selected day's Event and Reminder cards.
struct CalendarView: View {
    /// Shared with Home so both screens stay on the same day.
    @Binding var selectedDate: Date

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Event.startDate) private var events: [Event]
    @Query(sort: \Reminder.createdAt) private var reminders: [Reminder]

    @State private var visibleMonth: Date?
    @State private var editorRequest: PlanEditorRequest?
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.zoomNamespace) private var zoomNamespace

    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: .now)
    private static let monthSpan = 24

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        _visibleMonth = State(initialValue: Self.startOfMonth(selectedDate.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
                .padding(.top, 2)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // "May 2026": tap to return to today.
                    Button(action: jumpToToday) {
                        Text(OTWFormat.monthTitle(visibleMonth ?? selectedDate))
                            .font(Theme.Fonts.monthTitle)
                            .foregroundStyle(Theme.Colors.label)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(height: 40)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentTransition(.numericText())
                    }
                    .buttonStyle(.pressable)
                    .padding(.horizontal, Theme.Spacing.screen)
                    .padding(.top, 4)

                    WeekdayHeaderView()
                        .padding(.top, 8)

                    monthPager
                        .padding(.top, 8)

                    selectedDaySection
                }
                .padding(.bottom, Theme.Spacing.screen)
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .background(BackSwipeEnabler())
        .edgeBackSwipe { dismiss() }
        .toolbar(.hidden, for: .navigationBar)
        // Month swipe: tick + light impact.
        .onChange(of: visibleMonth) { _, _ in
            TickFeedback.shared.tick()
            TickFeedback.shared.settle()
        }
        .onChange(of: selectedDate) { _, newValue in
            let month = Self.startOfMonth(newValue)
            if visibleMonth != month {
                withAnimation(Theme.Motion.standard) { visibleMonth = month }
            }
        }
        .fullScreenCover(item: $editorRequest) { request in
            PlanEditorView(selectedDate: request.date, mode: request.mode) { savedDate, _ in
                selectedDate = calendar.startOfDay(for: savedDate)
            } onViewInCalendar: { _ in
                // Already on the Calendar; the saved date is selected above.
            }
            .id(request.id)
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 0) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 22, height: 24)
                    Text("Home")
                        .font(Theme.Fonts.navBack)
                }
                .foregroundStyle(Theme.Colors.accent)
                .frame(height: 44)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Back to Home")

            Spacer()

            HeaderActionsView(
                onPetTap: {},
                onAddTap: { editorRequest = PlanEditorRequest(date: selectedDate, mode: .event) }
            )
        }
        .padding(.leading, 16)
        .padding(.trailing, Theme.Spacing.screen)
        .frame(height: 44)
    }

    // MARK: - Month pager

    private var months: [Date] {
        let base = Self.startOfMonth(today)
        return (-Self.monthSpan...Self.monthSpan).compactMap { calendar.date(byAdding: .month, value: $0, to: base) }
    }

    private var monthPager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(months, id: \.self) { month in
                    MonthGridView(
                        layout: MonthLayout(month: month, events: events, reminders: reminders, calendar: calendar),
                        today: today,
                        selectedDate: selectedDate,
                        onSelect: select
                    )
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $visibleMonth)
        .scrollIndicators(.hidden)
        .frame(height: MonthGridView.gridHeight)
    }

    // MARK: - Selected day

    private var selectedDaySection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.Colors.separator)
                .frame(height: 1)

            HStack(alignment: .firstTextBaseline) {
                Text(OTWFormat.dayTitle(selectedDate))
                    .font(Theme.Fonts.dayTitle)
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                Text(countText)
                    .font(Theme.Fonts.count)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .frame(height: 20)
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.top, 18)

            LazyVStack(spacing: Theme.Spacing.cardGap) {
                ForEach(eventsForDay) { event in
                    let zid = zoomID("calendar", PersistentIdentifierBox(event.persistentModelID))
                    Button { appModel.open(event, zoomSource: zid) } label: {
                        EventCardView(event: event)
                    }
                    .buttonStyle(.pressableCard)
                    .zoomTransitionSource(zid, in: zoomNamespace)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
                ForEach(remindersForDay) { reminder in
                    let zid = zoomID("calendar", PersistentIdentifierBox(reminder.persistentModelID))
                    Button { appModel.open(reminder, zoomSource: zid) } label: {
                        ReminderCardView(
                            reminder: reminder,
                            day: selectedDate,
                            isNextDue: reminder.persistentModelID == nextDueReminder?.persistentModelID,
                            onToggle: { toggle(reminder) }
                        )
                    }
                    .buttonStyle(.pressableCard)
                    .zoomTransitionSource(zid, in: zoomNamespace)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
                if eventsForDay.isEmpty && remindersForDay.isEmpty {
                    Text("Nothing planned for this day.")
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.top, 14)
            .animation(Theme.Motion.standard, value: selectedDate)
            .animation(Theme.Motion.standard, value: remindersForDay.map(\.persistentModelID))
        }
    }

    // MARK: - Data

    /// Events that cover the selected day, including multi-day ones.
    private var eventsForDay: [Event] {
        let day = calendar.startOfDay(for: selectedDate)
        return events.filter { event in
            let start = calendar.startOfDay(for: event.startDate)
            let end = calendar.startOfDay(for: event.endDate)
            return day >= start && day <= end
        }
    }

    private var remindersForDay: [Reminder] {
        reminders
            .filter { calendar.isDate($0.scheduledDate, inSameDayAs: selectedDate) }
            .sorted { lhs, rhs in
                if lhs.isDone != rhs.isDone { return !lhs.isDone }
                if lhs.priority != rhs.priority { return rank(lhs.priority) < rank(rhs.priority) }
                switch (lhs.dueDate, rhs.dueDate) {
                case let (l?, r?): return l < r
                case (nil, _?): return false
                case (_?, nil): return true
                default: return lhs.createdAt < rhs.createdAt
                }
            }
    }

    private var nextDueReminder: Reminder? {
        remindersForDay
            .filter { !$0.isDone }
            .filter { reminder in reminder.dueDate.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false }
            .min { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var countText: String {
        let eventCount = eventsForDay.count
        let reminderCount = remindersForDay.count
        let eventsText = "\(eventCount) \(eventCount == 1 ? "event" : "events")"
        let remindersText = "\(reminderCount) \(reminderCount == 1 ? "reminder" : "reminders")"
        return "\(eventsText) · \(remindersText)"
    }

    private func rank(_ priority: Priority) -> Int {
        switch priority {
        case .high: 0
        case .medium: 1
        case .low: 2
        }
    }

    // MARK: - Actions

    private func select(_ date: Date) {
        if !calendar.isDate(date, inSameDayAs: selectedDate) { TickFeedback.shared.tick() }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            selectedDate = calendar.startOfDay(for: date)
        }
    }

    private func jumpToToday() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            selectedDate = today
            visibleMonth = Self.startOfMonth(today)
        }
    }

    private func toggle(_ reminder: Reminder) {
        withAnimation(Theme.Motion.standard) {
            PlanActions.toggleDone(reminder, in: modelContext)
        }
        // Checkbox: success haptic only, no tick sound.
        if reminder.isDone { TickFeedback.shared.success() }
    }

    private static func startOfMonth(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: calendar.dateInterval(of: .month, for: date)?.start ?? date)
    }
}

#Preview {
    @Previewable @State var selected = Calendar.current.startOfDay(for: .now)
    let container = try! ModelContainer(
        for: Event.self, Reminder.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    SampleData.seedIfNeeded(in: container.mainContext)
    return NavigationStack {
        CalendarView(selectedDate: $selected)
    }
    .environment(AppModel())
    .modelContainer(container)
}
