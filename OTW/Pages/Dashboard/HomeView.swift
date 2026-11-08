import SwiftUI
import SwiftData

enum PlanMode: String, CaseIterable, Identifiable {
    case event = "Event"
    case reminders = "Reminders"
    
    var id: String { rawValue }
}

struct HomeView: View {
    let today: Date
    
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.startDate) private var events: [Event]
    @Query(sort: \Reminder.createdAt) private var reminders: [Reminder]
    
    @State private var mode: PlanMode = .event
    @State private var editorRequest: PlanEditorRequest?
    @State private var isShowingPetTip = false
    @State private var debugToast: String?
    @Environment(\.zoomNamespace) private var zoomNamespace
    
    @State private var transientExpression: PetExpression?
    @State private var transientToken = 0
    @State private var mascotBounce = 0
    @State private var mascotHop = 0
    @State private var mascotShake = 0
    
    private let calendar = Calendar.current
    
    init(today: Date) {
        self.today = today
    }
    
    private var selectedDate: Date { appModel.selectedDate }
    
    var body: some View {
        @Bindable var appModel = appModel
        
        VStack(spacing: 0) {
            HomeHeaderView(
                selectedDate: selectedDate,
                mascot: mascotState,
                onMonthTap: { appModel.openCalendar() },
                onPetTap: petTapped,
                onPetLongPress: debugLongPressAction,
                onAddTap: presentEditor
            )
            .padding(.top, 2)
            
            DateStripView(
                today: today,
                selectedDate: $appModel.selectedDate,
                hasEvents: { hasEvents(on: $0) },
                hasReminders: { hasReminders(on: $0) }
            )
            .padding(.horizontal, -Theme.Spacing.screen)
            .padding(.top, Theme.Spacing.section)
            
            SegmentedToggle(selection: $mode)
                .padding(.top, Theme.Spacing.section)
            
            HStack {
                Spacer()
                Text(countText)
                    .font(Theme.Fonts.count)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .frame(height: 16)
            .padding(.top, Theme.Spacing.section)
            
            ScrollView(showsIndicators: false) {
                listContent
                    .id(mode)
                    .transition(.opacity)
                    .padding(.top, Theme.Spacing.listTop)
                    .padding(.bottom, Theme.Spacing.screen)
            }
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Home")
        .toolbar(.hidden, for: .navigationBar)
        .overlayPreferenceValue(HeaderActionsAnchorKey.self) { anchor in
            PetTipOverlay(
                isPresented: $isShowingPetTip,
                anchor: anchor,
                mood: petMood,
                mascot: mascotState,
                title: petTip.title,
                message: petTip.message,
                onAdd: presentEditor
            )
        }
        .overlay(alignment: .bottom) {
            if let debugToast {
                Text(debugToast)
                    .font(Theme.Fonts.count)
                    .foregroundStyle(Theme.Colors.onAccent)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(Capsule().fill(Color.black.opacity(0.8)))
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(item: $editorRequest) { request in
            PlanEditorView(selectedDate: request.date, mode: request.mode) { savedDate, savedMode in
                appModel.selectedDate = calendar.startOfDay(for: savedDate)
                mode = savedMode
            } onViewInCalendar: { _ in
                appModel.openCalendar()
            }
            .id(request.id)
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .otwReminderCompleted) {
                mascotHop += 1
                showTransient(.happy)
            }
        }
        .onAppear {
            if petMood == .nervous { mascotShake += 1 }
        }
        .onChange(of: petMood) { _, mood in
            if mood == .nervous { mascotShake += 1 }
        }
    }
    
    private func presentEditor() {
        editorRequest = PlanEditorRequest(date: selectedDate, mode: mode)
    }
    
    // MARK: - List
    
    @ViewBuilder
    private var listContent: some View {
        switch mode {
        case .event:
            if eventsForDay.isEmpty {
                EmptyStateView(
                    title: "Nothing planned yet",
                    subtitle: "Enjoy your free time, or plan something new.",      action: presentEditor
                )
            } else {
                LazyVStack(spacing: Theme.Spacing.cardGap) {
                    ForEach(eventsForDay) { event in
                        let zid = zoomID("home", PersistentIdentifierBox(event.persistentModelID))
                        Button { appModel.open(event, zoomSource: zid) } label: {
                            EventCardView(event: event)
                        }
                        .buttonStyle(.pressableCard)
                        .zoomTransitionSource(zid, in: zoomNamespace)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }
                }
                .animation(Theme.Motion.standard, value: eventsForDay.map(\.persistentModelID))
            }
        case .reminders:
            if remindersForDay.isEmpty {
                EmptyStateView(
                    title: "All caught up!",
                    subtitle: "No reminders for this day. Nice and easy.",
                    action: presentEditor
                )
            } else {
                LazyVStack(spacing: Theme.Spacing.cardGap) {
                    ForEach(remindersForDay) { reminder in
                        let zid = zoomID("home", PersistentIdentifierBox(reminder.persistentModelID))
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
                }
                .animation(Theme.Motion.standard, value: remindersForDay.map(\.persistentModelID))
            }
        }
    }
    
    // MARK: - Derived data
    
    private var eventsForDay: [Event] {
        events.filter { covers($0, selectedDate) }
    }
    
    private func covers(_ event: Event, _ day: Date) -> Bool {
        let day = calendar.startOfDay(for: day)
        return day >= calendar.startOfDay(for: event.startDate) && day <= calendar.startOfDay(for: event.endDate)
    }
    
    private var remindersForDay: [Reminder] {
        reminders
            .filter { calendar.isDate($0.scheduledDate, inSameDayAs: selectedDate) }
            .sorted { lhs, rhs in
                if lhs.isDone != rhs.isDone { return !lhs.isDone }
                if lhs.priority != rhs.priority {
                    return priorityRank(lhs.priority) < priorityRank(rhs.priority)
                }
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
            .filter { due in due.dueDate.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false }
            .min { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    private var countText: String {
        switch mode {
        case .event:
            let count = eventsForDay.count
            return "\(count) active \(count == 1 ? "event" : "events")"
        case .reminders:
            let count = remindersForDay.filter { !$0.isDone }.count
            return "\(count) \(count == 1 ? "reminder" : "reminders") left"
        }
    }
    
    private func hasEvents(on day: Date) -> Bool {
        events.contains { covers($0, day) }
    }
    
    private func hasReminders(on day: Date) -> Bool {
        reminders.contains { calendar.isDate($0.scheduledDate, inSameDayAs: day) }
    }
    
    private func priorityRank(_ priority: Priority) -> Int {
        switch priority {
        case .high: 0
        case .medium: 1
        case .low: 2
        }
    }
    
    private func toggle(_ reminder: Reminder) {
        withAnimation(Theme.Motion.standard) {
            PlanActions.toggleDone(reminder, in: modelContext)
        }
        if reminder.isDone { TickFeedback.shared.success() }
    }
    
    // MARK: - Pet
    
    private var todaysReminders: [Reminder] {
        reminders.filter { calendar.isDateInToday($0.scheduledDate) }
    }
    
    private var todaysEvents: [Event] {
        events.filter { covers($0, .now) }
    }
    
    private var overdueHighReminders: [Reminder] {
        let now = Date.now
        return reminders.filter { reminder in
            guard !reminder.isDone, reminder.priority == .high, let due = reminder.dueDate else { return false }
            return due < now
        }
    }
    
    private var petMood: PetMood {
        if !overdueHighReminders.isEmpty { return .nervous }
        if !todaysReminders.isEmpty && todaysReminders.allSatisfy(\.isDone) { return .love }
        return .normal
    }
    
    private var petTip: (title: String, message: String) {
        switch petMood {
        case .nervous:
            let count = overdueHighReminders.count
            return (
                "Some High ones are overdue!",
                "\(count) High \(count == 1 ? "reminder is" : "reminders are") past due. Let's knock \(count == 1 ? "it" : "them") out first!"
            )
        case .love:
            return ("All done for today!", "You finished every reminder today. Time to relax!")
        case .normal:
            let eventCount = todaysEvents.count
            let open = todaysReminders.filter { !$0.isDone }
            if eventCount == 0 && open.isEmpty {
                return ("A free day!", "Nothing on your list today. Tap + to plan something new.")
            }
            let events = "\(eventCount) \(eventCount == 1 ? "event" : "events")"
            let remindersText = "\(open.count) \(open.count == 1 ? "reminder" : "reminders")"
            let nudge = open.contains { $0.priority == .high } ? "Start with the High ones!" : "You've got this!"
            return ("Don't forget your agenda!", "You have \(events) and \(remindersText) today. \(nudge)")
        }
    }
    
    // MARK: - Mascot
    
    private var mascotState: MascotState {
        MascotState(
            expression: transientExpression ?? petMood.expression,
            isLive: true,
            bounceTrigger: mascotBounce,
            hopTrigger: mascotHop,
            shakeTrigger: mascotShake
        )
    }
    
    private func petTapped() {
        isShowingPetTip.toggle()
    }
    
    private func showTransient(_ expression: PetExpression) {
        transientToken += 1
        let token = transientToken
        transientExpression = expression
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if token == transientToken { transientExpression = nil }
        }
    }
    
    // MARK: - Debug
    
    private var debugLongPressAction: (() -> Void)? {
#if DEBUG
        return {
            let event = todaysEvents.first { !$0.url.isEmpty } ?? todaysEvents.first ?? events.first
            let reminder = todaysReminders.first { !$0.isDone } ?? reminders.first { !$0.isDone }
            Task { await NotificationManager.shared.scheduleTestNotifications(event: event, reminder: reminder) }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(Theme.Motion.bouncy) {
                debugToast = "Test notifications in 5 s"
            }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(Theme.Motion.snappy) { debugToast = nil }
            }
        }
#else
        return nil
#endif
    }
}

struct PlanEditorRequest: Identifiable {
    let id = UUID()
    let date: Date
    let mode: PlanMode
}

#Preview {
    let container = try! ModelContainer(
        for: Event.self, Reminder.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    SampleData.seedIfNeeded(in: container.mainContext)
    return NavigationStack {
        HomeView(today: .now)
    }
    .environment(AppModel())
    .modelContainer(container)
}
