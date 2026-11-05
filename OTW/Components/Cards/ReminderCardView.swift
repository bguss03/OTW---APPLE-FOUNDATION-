import SwiftUI

/// Sketch "Card/<Reminder>" group from the Home › Reminders list (392 x 80, radius 22).
struct ReminderCardView: View {
    let reminder: Reminder
    /// The day the list is showing; drives "Today" / "Tomorrow" wording.
    let day: Date
    /// True for the earliest unfinished reminder due today; its due text is orange.
    let isNextDue: Bool
    let onToggle: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 0) {
                // Checkbox 26 x 26 drawn at (16, 27), with a 44 x 44 tap target around it.
                Button(action: onToggle) {
                    checkbox
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .padding(.leading, -9)
                .padding(.top, 18)
                .accessibilityLabel(reminder.isDone ? "Mark as not done" : "Mark as done")

                // Title at x 56 / y 16, meta row at y 42.
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(Theme.Fonts.cardTitle)
                        .foregroundStyle(reminder.isDone ? Theme.Colors.doneLabel : Theme.Colors.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        // Keep the title clear of the badge; the meta row may run below it.
                        .padding(.trailing, badgeClearance)

                    HStack(spacing: 0) {
                        Image(systemName: "alarm")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(dueColor)
                            .frame(width: Theme.Size.metaIcon, height: Theme.Size.metaIcon)

                        Text(dueText)
                            .font(isHighlighted ? Theme.Fonts.cardMetaEmphasis : Theme.Fonts.cardMeta)
                            .foregroundStyle(dueColor)
                            .lineLimit(1)
                            .padding(.leading, 4)
                            .frame(width: 92, alignment: .leading)

                        Image(systemName: "folder")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                            .frame(width: Theme.Size.metaIcon, height: Theme.Size.metaIcon)
                            .padding(.leading, 3)

                        Text(reminder.categoryLabel)
                            .font(Theme.Fonts.cardMeta)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                            .lineLimit(1)
                            .padding(.leading, 4)
                            .padding(.trailing, Theme.Spacing.cardPadding)
                    }
                }
                // 7 (button start) + 44 (button) + 5 = 56, matching the Sketch title x.
                .padding(.leading, 5)
                .padding(.top, Theme.Spacing.cardPadding)

                Spacer(minLength: 0)
            }
            .padding(.leading, Theme.Spacing.cardPadding)

            PriorityBadge(priority: reminder.priority, isDone: reminder.isDone)
                .padding(.top, Theme.Spacing.cardPadding)
                .padding(.trailing, Theme.Spacing.cardPadding)
        }
        .frame(maxWidth: .infinity, minHeight: Theme.Size.cardHeight, maxHeight: Theme.Size.cardHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Colors.card)
        )
    }

    // MARK: - Pieces

    private var checkbox: some View {
        ZStack {
            if reminder.isDone {
                Circle()
                    .fill(Theme.Colors.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Theme.Colors.onAccent)
            } else {
                Circle()
                    .fill(Color.white)
                Circle()
                    .strokeBorder(Theme.Colors.checkboxBorder, lineWidth: Theme.Size.checkboxBorder)
            }
        }
        .frame(width: Theme.Size.checkbox, height: Theme.Size.checkbox)
        .contentShape(Circle())
    }

    /// Badge width (50 / 66 / 44 in Sketch) plus its 16pt trailing inset and an 8pt gap.
    private var badgeClearance: CGFloat {
        let badgeWidth: CGFloat = switch reminder.priority {
        case .high: 50
        case .medium: 66
        case .low: 44
        }
        return badgeWidth + Theme.Spacing.cardPadding + 8
    }

    private var isHighlighted: Bool {
        isNextDue && !reminder.isDone
    }

    private var dueColor: Color {
        if reminder.isDone { return Theme.Colors.doneLabel }
        return isHighlighted ? Theme.Colors.accentDeep : Theme.Colors.secondaryLabel
    }

    /// "Today, 18:00", "20:00", "Tomorrow", "Flexible" or "Done · 09:41".
    private var dueText: String {
        if reminder.isDone {
            let stamp = reminder.completedAt ?? reminder.dueDate ?? day
            return "Done · \(OTWFormat.time(stamp))"
        }
        guard let due = reminder.dueDate else { return "Flexible" }
        if calendar.isDate(due, inSameDayAs: day) {
            return isHighlighted ? "Today, \(OTWFormat.time(due))" : OTWFormat.time(due)
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: day),
           calendar.isDate(due, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return OTWFormat.shortDate(due)
    }
}

/// Priority pill: High (orange / white), Medium (light orange / deep orange), Low (pale / soft orange).
struct PriorityBadge: View {
    let priority: Priority
    let isDone: Bool

    var body: some View {
        Text(priority.rawValue)
            .font(Theme.Fonts.badge)
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .frame(height: Theme.Size.badgeHeight)
            .background(
                Capsule()
                    .fill(background)
            )
            .overlay {
                if isDone {
                    Capsule()
                        .strokeBorder(Theme.Colors.checkboxBorder, lineWidth: 1)
                }
            }
    }

    private var foreground: Color {
        if isDone { return Theme.Colors.doneBadgeLabel }
        switch priority {
        case .high: return Theme.Colors.onAccent
        case .medium: return Theme.Colors.accentDeep
        case .low: return Theme.Colors.accentSoft
        }
    }

    private var background: Color {
        if isDone { return Theme.Colors.card }
        switch priority {
        case .high: return Theme.Colors.accent
        case .medium: return Theme.Colors.accentTintMedium
        case .low: return Theme.Colors.accentTintLow
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.cardGap) {
        ForEach(Array(SampleData.reminders(relativeTo: Calendar.current.startOfDay(for: .now)).prefix(4).enumerated()), id: \.offset) { index, reminder in
            ReminderCardView(reminder: reminder, day: Calendar.current.startOfDay(for: .now), isNextDue: index == 0, onToggle: {})
        }
    }
    .padding(.horizontal, Theme.Spacing.screen)
}
