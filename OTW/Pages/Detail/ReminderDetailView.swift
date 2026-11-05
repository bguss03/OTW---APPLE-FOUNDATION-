import SwiftUI
import SwiftData

/// Rebuild of "v3 / Reminder Detail".
struct ReminderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppModel.self) private var appModel
    @Query private var reminders: [Reminder]

    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    private let calendar = Calendar.current

    init(reminderID: PersistentIdentifier) {
        _reminders = Query(filter: #Predicate<Reminder> { $0.persistentModelID == reminderID })
    }

    var body: some View {
        Group {
            if let reminder = reminders.first {
                content(reminder)
            } else {
                Theme.Colors.background
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .background(BackSwipeEnabler())
        .edgeBackSwipe { dismiss() }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func content(_ reminder: Reminder) -> some View {
        VStack(spacing: 0) {
            DetailNavBar(title: "Reminder Detail", onBack: { dismiss() }, onEdit: { isEditing = true })
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.top, 2)
                .padding(.bottom, 6)
                .background(Theme.Colors.background)
                .zIndex(1)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    hero(reminder)
                        .padding(.top, 12)

                    SectionLabel(text: "DATE & TIME")
                        .padding(.top, 22)
                    FormCard {
                        DetailDateTimeRow(
                            label: "Date",
                            dateText: OTWFormat.longDate(reminder.dueDate ?? reminder.scheduledDate)
                        )
                        FormSeparator()
                        DetailDateTimeRow(
                            label: "Time",
                            timeText: reminder.dueDate.map(OTWFormat.time) ?? "Flexible"
                        )
                    }
                    .padding(.top, 8)

                    SectionLabel(text: "PRIORITY")
                        .padding(.top, 20)
                    FormCard {
                        DetailValueRow(
                            label: "Priority",
                            value: reminder.priority.rawValue,
                            valueColor: priorityColor(reminder.priority),
                            valueFont: Theme.Fonts.navTitle
                        )
                    }
                    .padding(.top, 8)

                    SectionLabel(text: "OPTIONS")
                        .padding(.top, 20)
                    FormCard {
                        DetailValueRow(label: "Remind Me", value: reminder.remindBefore.rawValue)
                        FormSeparator()
                        DetailValueRow(label: "Repeat", value: reminder.repeatRule.rawValue)
                    }
                    .padding(.top, 8)

                    SectionLabel(text: "NOTES")
                        .padding(.top, 20)
                    NotesCard(notes: reminder.notes)
                        .padding(.top, 8)
                }
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.bottom, Theme.Spacing.screen)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                DetailActionBar(
                    primaryTitle: reminder.isDone ? "Mark as Not Done" : "Mark as Done",
                    primaryIsMuted: reminder.isDone,
                    onDelete: { isConfirmingDelete = true },
                    onPrimary: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            PlanActions.toggleDone(reminder, in: modelContext)
                        }
                    }
                )
            }
        }
        .alert("Delete this reminder?", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive) { delete(reminder) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("“\(reminder.title)” will be removed and its notifications cancelled.")
        }
        .fullScreenCover(isPresented: $isEditing) {
            PlanEditorView(selectedDate: reminder.scheduledDate, reminder: reminder) { _, _ in
            } onViewInCalendar: { date in
                appModel.selectedDate = Calendar.current.startOfDay(for: date)
                appModel.openCalendar()
            }
        }
    }

    // MARK: - Pieces

    /// Priority badge + category chip, 28pt bold title, "Due today · Design System".
    private func hero(_ reminder: Reminder) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                HeroChip(
                    text: reminder.isDone ? "Done" : reminder.priority.rawValue,
                    foreground: reminder.isDone ? Theme.Colors.doneBadgeLabel : badgeColors(reminder.priority).foreground,
                    background: reminder.isDone ? Theme.Colors.card : badgeColors(reminder.priority).background
                )
                .padding(.horizontal, 2)
                HeroChip(
                    text: reminder.categoryLabel,
                    foreground: Theme.Colors.accentDeep,
                    background: Theme.Colors.accentTint
                )
            }

            Text(reminder.title)
                .font(Theme.Fonts.heroTitle)
                .foregroundStyle(reminder.isDone ? Theme.Colors.doneLabel : Theme.Colors.label)
                .lineLimit(2)
                .padding(.top, 8)

            Text(subtitle(reminder))
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .padding(.top, 7)
        }
    }

    private func subtitle(_ reminder: Reminder) -> String {
        let label = reminder.categoryLabel
        if reminder.isDone {
            return "Done · \(OTWFormat.time(reminder.completedAt ?? .now)) · \(label)"
        }
        guard let due = reminder.dueDate else { return "Flexible · \(label)" }
        if calendar.isDateInToday(due) { return "Due today · \(label)" }
        if calendar.isDateInTomorrow(due) { return "Due tomorrow · \(label)" }
        if calendar.isDateInYesterday(due) { return "Was due yesterday · \(label)" }
        return "\(due < .now ? "Was due" : "Due") \(OTWFormat.shortDate(due)) · \(label)"
    }

    private func badgeColors(_ priority: Priority) -> (foreground: Color, background: Color) {
        switch priority {
        case .high: (Theme.Colors.onAccent, Theme.Colors.accent)
        case .medium: (Theme.Colors.accentDeep, Theme.Colors.accentTintMedium)
        case .low: (Theme.Colors.accentSoft, Theme.Colors.accentTintLow)
        }
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: Theme.Colors.accent
        case .medium: Theme.Colors.accentDeep
        case .low: Theme.Colors.accentSoft
        }
    }

    private func delete(_ reminder: Reminder) {
        dismiss()
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            PlanActions.delete(reminder, in: modelContext)
        }
    }
}
