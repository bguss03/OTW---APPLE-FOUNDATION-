import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppModel.self) private var appModel
    @Environment(\.openURL) private var openURL
    @Query private var events: [Event]

    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    private let calendar = Calendar.current

    init(eventID: PersistentIdentifier) {
        _events = Query(filter: #Predicate<Event> { $0.persistentModelID == eventID })
    }

    var body: some View {
        Group {
            if let event = events.first {
                content(event)
            } else {
                Theme.Colors.background
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .background(BackSwipeEnabler())
        .edgeBackSwipe { dismiss() }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func content(_ event: Event) -> some View {
        VStack(spacing: 0) {
            DetailNavBar(title: "Event Detail", onBack: { dismiss() }, onEdit: { isEditing = true })
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.top, 2)
                .padding(.bottom, 6)
                .background(Theme.Colors.background)
                .zIndex(1)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    hero(event)
                        .padding(.top, 12)

                    SectionLabel(text: "DATE & TIME")
                        .padding(.top, 22)
                    FormCard {
                        DetailDateTimeRow(
                            label: "Starts",
                            dateText: OTWFormat.longDate(event.startDate),
                            timeText: OTWFormat.time(event.startDate)
                        )
                        FormSeparator()
                        DetailDateTimeRow(
                            label: "Ends",
                            dateText: OTWFormat.longDate(event.endDate),
                            timeText: OTWFormat.time(event.endDate)
                        )
                    }
                    .padding(.top, 8)

                    SectionLabel(text: "WHERE")
                        .padding(.top, 20)
                    FormCard {
                        DetailValueRow(
                            label: "Location",
                            value: event.location.isEmpty ? "Not set" : event.location,
                            valueColor: event.location.isEmpty ? Theme.Colors.secondaryLabel : Theme.Colors.label
                        )
                        FormSeparator()
                        urlRow(event)
                    }
                    .padding(.top, 8)

                    SectionLabel(text: "OPTIONS")
                        .padding(.top, 20)
                    FormCard {
                        DetailValueRow(label: "Remind Me", value: event.remindBefore.rawValue)
                        FormSeparator()
                        DetailValueRow(label: "Repeat", value: event.repeatRule.rawValue)
                    }
                    .padding(.top, 8)

                    SectionLabel(text: "NOTES")
                        .padding(.top, 20)
                    NotesCard(notes: event.notes)
                        .padding(.top, 8)

                    Button {
                        isConfirmingDelete = true
                    } label: {
                        Text("Delete")
                            .font(.headline)
                            .foregroundStyle(Color(hex: 0xFFFFFF))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.primaryButton, style: .continuous)
                                    .fill(Color(hex: 0xFC6C01))
                            )
                    }
                    .buttonStyle(.pressable)
                    .padding(.top, 20)
                }
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.bottom, Theme.Spacing.screen)
            }
        }
        .alert("Delete this event?", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive) { delete(event) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("“\(event.title)” will be removed and its reminders cancelled.")
        }
        .fullScreenCover(isPresented: $isEditing) {
            PlanEditorView(selectedDate: event.startDate, event: event) { _, _ in
            } onViewInCalendar: { date in
                appModel.selectedDate = Calendar.current.startOfDay(for: date)
                appModel.openCalendar()
            }
        }
    }

    // MARK: - Pieces

    private func hero(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HeroChip(
                text: event.category.rawValue,
                foreground: event.tagColor.color,
                background: event.tagColor.color.opacity(0.12)
            ) {
                Circle()
                    .fill(event.tagColor.color)
                    .frame(width: 8, height: 8)
            }
            .padding(.leading, -2)

            Text(event.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(2)
                .padding(.top, 8)

            Text(subtitle(event))
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func urlRow(_ event: Event) -> some View {
        if let url = NotificationManager.webURL(from: event.url) {
            Button { openURL(url) } label: {
                DetailValueRow(
                    label: "URL",
                    value: event.url,
                    valueColor: Theme.Colors.accent,
                    valueFont: Theme.Fonts.navTitle
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressableCard)
            .accessibilityHint("Opens the link in Safari")
        } else {
            DetailValueRow(label: "URL", value: "Not set")
        }
    }

    private func subtitle(_ event: Event) -> String {
        if calendar.isDate(event.startDate, inSameDayAs: event.endDate) {
            return OTWFormat.fullDate(event.startDate)
        }
        return "\(OTWFormat.shortDate(event.startDate)) – \(OTWFormat.longDate(event.endDate))"
    }

    private func delete(_ event: Event) {
        dismiss()
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            PlanActions.delete(event, in: modelContext)
        }
    }
}
