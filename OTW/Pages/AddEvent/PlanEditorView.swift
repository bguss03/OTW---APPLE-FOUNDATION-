// xcode: set sdk=iOS

import SwiftUI
import SwiftData

/// "v3 / Add · Event" and "v3 / Add · Reminder": the New Plan screen.
/// Pass an existing `Event` or `Reminder` to prefill the form for editing.
struct PlanEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    /// Called after the user taps Continue on the Saved screen, with the saved plan's date and type.
    let onSaved: (Date, PlanMode) -> Void
    /// Called from "View in Calendar" with the saved plan's date.
    private let onViewInCalendar: ((Date) -> Void)?

    private let existingEvent: Event?
    private let existingReminder: Reminder?
    private let eventBaseline: EventDraft
    private let reminderBaseline: ReminderDraft

    @State private var mode: PlanMode
    @State private var eventDraft: EventDraft
    @State private var reminderDraft: ReminderDraft
    @State private var phase: SavePhase = .editing
    @State private var savedDate: Date = .now
    @State private var isShowingDiscardDialog = false
    @State private var notificationsDenied = false
    @FocusState private var isNameFocused: Bool

    private enum SavePhase { case editing, saving, saved }

    init(
        selectedDate: Date,
        mode: PlanMode = .event,
        event: Event? = nil,
        reminder: Reminder? = nil,
        onSaved: @escaping (Date, PlanMode) -> Void,
        onViewInCalendar: ((Date) -> Void)? = nil
    ) {
        self.onSaved = onSaved
        self.onViewInCalendar = onViewInCalendar
        existingEvent = event
        existingReminder = reminder

        let eventDraft = event.map(EventDraft.init(event:)) ?? EventDraft(selectedDate: selectedDate)
        let reminderDraft = reminder.map(ReminderDraft.init(reminder:)) ?? ReminderDraft(selectedDate: selectedDate)
        eventBaseline = eventDraft
        reminderBaseline = reminderDraft
        _eventDraft = State(initialValue: eventDraft)
        _reminderDraft = State(initialValue: reminderDraft)
        _mode = State(initialValue: reminder != nil ? .reminders : mode)
    }

    var body: some View {
        ZStack {
            editor
                .disabled(phase != .editing)

            if phase != .editing {
                SaveConfirmationView(
                    isSaved: phase == .saved,
                    savedDate: savedDate,
                    onContinue: finish,
                    isEditing: isEditing,
                    onViewInCalendar: viewInCalendar
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .alert("Discard changes?", isPresented: $isShowingDiscardDialog) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard Changes", role: .destructive) { dismiss() }
        } message: {
            Text(isEditing ? "Your changes have not been saved yet." : "Your new plan has not been saved yet.")
        }
        .onAppear {
            // Preload the save sound so it plays exactly with the badge pop.
            SoundEffects.shared.prepare()
            // New plans start typing right away; edits keep the keyboard down like the Sketch frame.
            guard !isEditing else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                isNameFocused = true
            }
        }
        .task { await refreshNotificationStatus() }
        .onChange(of: scenePhase) { _, phase in
            // Coming back from Settings.
            if phase == .active { Task { await refreshNotificationStatus() } }
        }
    }

    // MARK: - Editor

    private var editor: some View {
        VStack(spacing: 0) {
            navBar
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.top, 2)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Image("PetDefault")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 78)
                        .padding(.top, 10)

                    Text(isEditing ? "Update your plan" : "Add New Plans")
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.Colors.label)
                        .frame(height: 23)
                        .padding(.top, 10)

                    // Editing keeps the plan's type, so the Event / Reminders toggle is hidden.
                    if !isEditing {
                        SegmentedToggle(selection: $mode)
                            .padding(.top, 17)
                    }

                    Group {
                        switch mode {
                        case .event:
                            eventForm
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .reminders:
                            reminderForm
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.top, isEditing ? 21 : 20)
                    .animation(Theme.Motion.standard, value: mode)

                    // Breathing room below the last card (the nav-bar check is the only save action).
                    Color.clear
                        .frame(height: 32)
                }
                .padding(.horizontal, Theme.Spacing.screen)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var navBar: some View {
        ZStack {
            Text(navTitle)
                .font(Theme.Fonts.navTitle)
                .foregroundStyle(Theme.Colors.label)
            HStack {
                CircleIconButton(systemName: "chevron.left", style: .neutral, action: back)
                    .accessibilityLabel("Back")
                Spacer()
                CircleIconButton(systemName: "checkmark", style: .accent, isEnabled: canSave, action: save)
                    .accessibilityLabel("Save")
            }
        }
        .frame(height: 44)
    }

    // MARK: - Forms

    private var eventForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "NAME")
            NameField(placeholder: "Event name", text: $eventDraft.title, isFocused: $isNameFocused, showsClearButton: isEditing)
                .padding(.top, 8)

            SectionLabel(text: "CATEGORY")
                .padding(.top, 20)
            CategoryChips(selection: $eventDraft.category)
                .padding(.top, 8)

            TagColorCard(selection: $eventDraft.tagColor)
                .padding(.top, 16)

            SectionLabel(text: "DATE & TIME")
                .padding(.top, 20)
            FormCard {
                DateTimeRow(
                    label: "Starts",
                    date: Binding(get: { eventDraft.startDate }, set: { eventDraft.setStart($0) })
                )
                FormSeparator()
                DateTimeRow(
                    label: "Ends",
                    date: Binding(get: { eventDraft.endDate }, set: { eventDraft.setEnd($0) }),
                    minimumDate: eventDraft.startDate
                )
            }
            .padding(.top, 8)

            SectionLabel(text: "WHERE · OPTIONAL")
                .padding(.top, 20)
            FormCard {
                InputRow(placeholder: "Add location", text: $eventDraft.location)
                FormSeparator()
                InputRow(placeholder: "Add URL (meeting link)", text: $eventDraft.url, keyboard: .URL, isValid: eventDraft.isURLValid)
            }
            .padding(.top, 8)

            SectionLabel(text: "OPTIONS")
                .padding(.top, 20)
            FormCard {
                OptionRow(label: "Remind Me", selection: $eventDraft.remindBefore)
                FormSeparator()
                OptionRow(label: "Repeat", selection: $eventDraft.repeatRule)
            }
            .padding(.top, 8)

            if notificationsDenied && eventDraft.remindBefore != .none {
                NotificationsOffNote(onOpenSettings: openSettings)
                    .padding(.top, 12)
            }
        }
    }

    private var reminderForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "NAME")
            NameField(placeholder: "Reminder name", text: $reminderDraft.title, isFocused: $isNameFocused, showsClearButton: isEditing)
                .padding(.top, 8)

            SectionLabel(text: "CATEGORY")
                .padding(.top, 20)
            CategoryChips(selection: $reminderDraft.category)
                .padding(.top, 8)

            SectionLabel(text: "DATE & TIME")
                .padding(.top, 20)
            FormCard {
                DateTimeRow(label: "Date", date: $reminderDraft.dueDate, showsTime: false)
                FormSeparator()
                DateTimeRow(label: "Time", date: $reminderDraft.dueDate, showsDate: false)
            }
            .padding(.top, 8)

            SectionLabel(text: "PRIORITY")
                .padding(.top, 20)
            PriorityPicker(selection: $reminderDraft.priority)
                .padding(.top, 8)

            SectionLabel(text: "OPTIONS")
                .padding(.top, 20)
            FormCard {
                OptionRow(label: "Remind Me", selection: $reminderDraft.remindBefore)
                FormSeparator()
                OptionRow(label: "Repeat", selection: $reminderDraft.repeatRule)
            }
            .padding(.top, 8)

            if notificationsDenied && reminderDraft.remindBefore != .none {
                NotificationsOffNote(onOpenSettings: openSettings)
                    .padding(.top, 12)
            }
        }
    }

    // MARK: - State

    private var isEditing: Bool { existingEvent != nil || existingReminder != nil }

    private var navTitle: String {
        guard isEditing else { return "New Plan" }
        return mode == .event ? "Edit Event" : "Edit Reminder"
    }

    private var canSave: Bool {
        switch mode {
        case .event: eventDraft.isValid
        case .reminders: reminderDraft.isValid
        }
    }

    private var hasUnsavedChanges: Bool {
        eventDraft != eventBaseline || reminderDraft != reminderBaseline
    }

    // MARK: - Actions

    private func back() {
        isNameFocused = false
        if hasUnsavedChanges {
            isShowingDiscardDialog = true
        } else {
            dismiss()
        }
    }

    private func save() {
        guard canSave, phase == .editing else { return }
        isNameFocused = false

        switch mode {
        case .event:
            let event: Event
            if let existingEvent {
                eventDraft.apply(to: existingEvent)
                event = existingEvent
            } else {
                event = eventDraft.makeEvent()
                modelContext.insert(event)
            }
            savedDate = event.startDate
            try? modelContext.save()
            Task {
                await NotificationManager.shared.schedule(event)
                await refreshNotificationStatus()
            }
        case .reminders:
            let reminder: Reminder
            if let existingReminder {
                reminderDraft.apply(to: existingReminder)
                reminder = existingReminder
            } else {
                reminder = reminderDraft.makeReminder()
                modelContext.insert(reminder)
            }
            savedDate = reminder.scheduledDate
            try? modelContext.save()
            Task {
                await NotificationManager.shared.schedule(reminder)
                await refreshNotificationStatus()
            }
        }

        withAnimation(Theme.Motion.standard) {
            phase = .saving
        }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(Theme.Motion.bouncy) {
                phase = .saved
            }
        }
    }

    private func finish() {
        onSaved(savedDate, mode)
        dismiss()
    }

    private func viewInCalendar() {
        onSaved(savedDate, mode)
        onViewInCalendar?(savedDate)
        dismiss()
    }

    private func refreshNotificationStatus() async {
        notificationsDenied = await NotificationManager.shared.authorizationStatus() == .denied
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        }
    }
}

#Preview("Event") {
    PlanEditorView(selectedDate: .now) { _, _ in }
        .modelContainer(for: [Event.self, Reminder.self], inMemory: true)
}

#Preview("Reminder") {
    PlanEditorView(selectedDate: .now, mode: .reminders) { _, _ in }
        .modelContainer(for: [Event.self, Reminder.self], inMemory: true)
}
