import SwiftUI

// Building blocks for the New Plan forms, sized from "v3 / Add · Event" and "v3 / Add · Reminder".

/// "NAME", "CATEGORY" … 13 semibold grey, inset 16 from the card edge.
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Fonts.section)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .frame(height: 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Theme.Spacing.cardPadding)
    }
}

/// Grey rounded card (F2F2F7, radius 22) that stacks rows vertically.
struct FormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Colors.card)
        )
    }
}

/// 1pt separator (#3C3C43 at 20%) starting 16pt in, like the Sketch rows.
struct FormSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Colors.separator)
            .frame(height: 1)
            .padding(.leading, Theme.Spacing.cardPadding)
    }
}

/// 44pt circular nav button: grey track (back) or solid orange (check).
struct CircleIconButton: View {
    enum Style { case neutral, accent, soft }

    let systemName: String
    let style: Style
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(fillColor)
                .frame(width: Theme.Size.headerButton, height: Theme.Size.headerButton)
                .overlay {
                    Image(systemName: systemName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(iconColor)
                }
        }
        .buttonStyle(.pressable)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }

    private var fillColor: Color {
        switch style {
        case .neutral: Theme.Colors.track
        case .accent: Theme.Colors.accent
        case .soft: Theme.Colors.accentTint
        }
    }

    private var iconColor: Color {
        switch style {
        case .neutral: Theme.Colors.label
        case .accent: Theme.Colors.onAccent
        case .soft: Theme.Colors.accent
        }
    }
}

/// Single-line field in a 52pt card: "Event name" / "Reminder name".
struct NameField: View {
    let placeholder: String
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var showsClearButton = false

    var body: some View {
        FormCard {
            HStack(spacing: 8) {
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Theme.Colors.placeholder))
                    .font(Theme.Fonts.formValue)
                    .foregroundStyle(Theme.Colors.label)
                    .focused(isFocused)
                    .submitLabel(.done)
                if showsClearButton && !text.isEmpty {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.placeholder)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressable)
                    .padding(.trailing, -12)
                    .accessibilityLabel("Clear name")
                }
            }
            .frame(height: 52)
            .padding(.horizontal, Theme.Spacing.cardPadding)
        }
    }
}

/// Horizontal row of single-select category chips (38pt, radius 19, gap 10).
struct CategoryChips: View {
    @Binding var selection: PlanCategory

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(PlanCategory.allCases) { category in
                    let isSelected = category == selection
                    Button {
                        if category != selection { TickFeedback.shared.tick() }
                        withAnimation(Theme.Motion.snappy) { selection = category }
                    } label: {
                        Text(category.rawValue)
                            .font(Theme.Fonts.chip)
                            .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.label)
                            .padding(.horizontal, 16)
                            .frame(height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                                    .fill(isSelected ? Theme.Colors.accentTint : Theme.Colors.card)
                            )
                            .overlay {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                                        .strokeBorder(Theme.Colors.accent, lineWidth: 1.5)
                                }
                            }
                            .expandedHitArea(dy: 3)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .padding(.horizontal, -Theme.Spacing.screen)
    }
}

/// "Tag Color" card: title, selected colour name, and seven 32pt dots; the selected one has a ring.
struct TagColorCard: View {
    @Binding var selection: TagColor

    var body: some View {
        FormCard {
            HStack {
                Text("Tag Color")
                    .font(Theme.Fonts.formValue)
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                Text(selection.rawValue)
                    .font(Theme.Fonts.formValue)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .contentTransition(.numericText())
            }
            .frame(height: 20)
            .padding(.horizontal, Theme.Spacing.cardPadding)
            .padding(.top, 14)

            HStack(spacing: 0) {
                ForEach(Array(TagColor.allCases.enumerated()), id: \.element) { index, color in
                    let isSelected = color == selection
                    Button {
                        if color != selection { TickFeedback.shared.tick() }
                        withAnimation(Theme.Motion.bouncy) { selection = color }
                    } label: {
                        ZStack {
                            if isSelected {
                                Circle()
                                    .strokeBorder(Theme.Colors.accent, lineWidth: 2.5)
                                    .frame(width: 38, height: 38)
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().strokeBorder(Theme.Colors.card, lineWidth: 3))
                            } else {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .frame(width: 38, height: 38)
                        .expandedHitArea(dx: 3, dy: 3)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(color.rawValue)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])

                    if index < TagColor.allCases.count - 1 {
                        Spacer(minLength: 4)
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 13)
        }
    }
}

/// Grey value chip (radius 17, 34pt tall) used for dates and times.
struct ValueChip: View {
    let text: String
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Theme.Fonts.formValue)
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: width, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.valueChip, style: .continuous)
                        .fill(Theme.Colors.track)
                )
                .expandedHitArea(dy: 5)
        }
        .buttonStyle(.pressable)
    }
}

/// "Starts  [May 3, 2026] [09:00]" row. Tapping a chip opens a compact native picker in a popover.
struct DateTimeRow: View {
    let label: String
    @Binding var date: Date
    var showsDate = true
    var showsTime = true
    var minimumDate: Date? = nil

    @State private var isShowingDate = false
    @State private var isShowingTime = false

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(Theme.Fonts.formValue)
                .foregroundStyle(Theme.Colors.label)
            Spacer(minLength: 8)
            if showsDate {
                ValueChip(text: OTWFormat.longDate(date), width: 128) {
                    isShowingDate = true
                }
                .popover(isPresented: $isShowingDate, arrowEdge: .top) {
                    datePicker(components: .date)
                        .datePickerStyle(.graphical)
                        .frame(width: 320)
                        .padding(.horizontal, 8)
                        .presentationCompactAdaptation(.popover)
                }
            }
            if showsTime {
                ValueChip(text: OTWFormat.time(date), width: 72) {
                    isShowingTime = true
                }
                .popover(isPresented: $isShowingTime, arrowEdge: .top) {
                    datePicker(components: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .frame(width: 240, height: 200)
                        .presentationCompactAdaptation(.popover)
                }
            }
        }
        .padding(.leading, Theme.Spacing.cardPadding)
        .padding(.trailing, 8)
        .frame(height: 52)
    }

    @ViewBuilder
    private func datePicker(components: DatePickerComponents) -> some View {
        if let minimumDate {
            DatePicker("", selection: $date, in: minimumDate..., displayedComponents: components)
                .labelsHidden()
                .tint(Theme.Colors.accent)
        } else {
            DatePicker("", selection: $date, displayedComponents: components)
                .labelsHidden()
                .tint(Theme.Colors.accent)
        }
    }
}

/// Placeholder-style text input row inside a card ("Add location", "Add URL (meeting link)").
struct InputRow: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isValid = true

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Theme.Colors.placeholder))
            .font(Theme.Fonts.formValue)
            .foregroundStyle(isValid ? Theme.Colors.label : Theme.Colors.tagRed)
            .keyboardType(keyboard)
            .textInputAutocapitalization(keyboard == .URL ? .never : .sentences)
            .autocorrectionDisabled(keyboard == .URL)
            .submitLabel(.done)
            .frame(height: 52)
            .padding(.horizontal, Theme.Spacing.cardPadding)
    }
}

/// "Remind Me   30 min before ›" row backed by a menu.
struct OptionRow<Option>: View where Option: CaseIterable & Identifiable & Hashable & RawRepresentable,
                                     Option.RawValue == String, Option.AllCases: RandomAccessCollection {
    let label: String
    @Binding var selection: Option

    var body: some View {
        Menu {
            Picker(label, selection: $selection) {
                ForEach(Array(Option.allCases)) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(label)
                    .font(Theme.Fonts.formValue)
                    .foregroundStyle(Theme.Colors.label)
                Spacer(minLength: 8)
                Text(selection.rawValue)
                    .font(Theme.Fonts.formValue)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.placeholder)
                    .frame(width: 14, height: 18)
            }
            .padding(.leading, Theme.Spacing.cardPadding)
            .padding(.trailing, 12)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .tint(Theme.Colors.accent)
        // Remind Me / Repeat choices tick like a picker.
        .tickFeedback(trigger: selection)
    }
}

/// High / Medium / Low pills (48pt, radius 24). The selected one is solid orange.
struct PriorityPicker: View {
    @Binding var selection: Priority

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Priority.allCases) { priority in
                let isSelected = priority == selection
                Button {
                    if priority != selection { TickFeedback.shared.tick() }
                    withAnimation(Theme.Motion.snappy) { selection = priority }
                } label: {
                    Text(priority.rawValue)
                        .font(Theme.Fonts.priority)
                        .foregroundStyle(isSelected ? Theme.Colors.onAccent : tint(for: priority).foreground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.priorityPill, style: .continuous)
                                .fill(isSelected ? Theme.Colors.accent : tint(for: priority).background)
                        )
                        .shadow(color: isSelected ? Theme.Colors.accent.opacity(0.3) : .clear, radius: 5, y: 4)
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    /// Unselected look per priority, as drawn in "v3 / Add · Reminder".
    private func tint(for priority: Priority) -> (background: Color, foreground: Color) {
        switch priority {
        case .high: (Theme.Colors.accentTint, Theme.Colors.accent)
        case .medium: (Theme.Colors.accentTintMedium, Theme.Colors.accentDeep)
        case .low: (Theme.Colors.accentTintLow, Theme.Colors.accentSoft)
        }
    }
}

/// Big orange button (56pt, radius 28) with the orange glow.
struct PrimaryButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.navTitle)
                .foregroundStyle(Theme.Colors.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.primaryButton, style: .continuous)
                        .fill(Theme.Colors.accent)
                )
                .themeShadow(Theme.Shadow.primaryButton)
        }
        .buttonStyle(.pressable)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .animation(Theme.Motion.snappy, value: isEnabled)
    }
}

/// Inline note shown under OPTIONS when notifications are denied for OTW.
struct NotificationsOffNote: View {
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications are off")
                    .font(Theme.Fonts.section)
                    .foregroundStyle(Theme.Colors.label)
                Text("Turn them on so OTW can remind you.")
                    .font(Theme.Fonts.cardMeta)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer(minLength: 8)
            Button(action: onOpenSettings) {
                Text("Open Settings")
                    .font(Theme.Fonts.section)
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.Colors.accentTintLow)
        )
    }
}
