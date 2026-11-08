import SwiftUI

struct DetailNavBar: View {
    let title: String
    let onBack: () -> Void
    let onEdit: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(Theme.Fonts.navTitle)
                .foregroundStyle(Theme.Colors.label)
            HStack {
                CircleIconButton(systemName: "chevron.left", style: .neutral, action: onBack)
                    .accessibilityLabel("Back")
                Spacer()
                CircleIconButton(systemName: "pencil", style: .soft, action: onEdit)
                    .accessibilityLabel("Edit")
            }
        }
        .frame(height: 44)
    }
}

struct StaticChip: View {
    let text: String
    let width: CGFloat

    var body: some View {
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
    }
}

struct DetailDateTimeRow: View {
    let label: String
    var dateText: String?
    var timeText: String?

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(Theme.Fonts.formValue)
                .foregroundStyle(Theme.Colors.label)
            Spacer(minLength: 8)
            if let dateText { StaticChip(text: dateText, width: 128) }
            if let timeText { StaticChip(text: timeText, width: 72) }
        }
        .padding(.leading, Theme.Spacing.cardPadding)
        .padding(.trailing, 8)
        .frame(height: 52)
        .accessibilityElement(children: .combine)
    }
}

struct DetailValueRow: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.Colors.secondaryLabel
    var valueFont: Font = Theme.Fonts.formValue

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(Theme.Fonts.formValue)
                .foregroundStyle(Theme.Colors.label)
            Spacer(minLength: 8)
            Text(value)
                .font(valueFont)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, Theme.Spacing.cardPadding)
        .frame(height: 52)
        .accessibilityElement(children: .combine)
    }
}

struct NotesCard: View {
    let notes: String

    var body: some View {
        FormCard {
            Text(notes.isEmpty ? "No notes yet." : notes)
                .font(Theme.Fonts.formValue)
                .foregroundStyle(notes.isEmpty ? Theme.Colors.placeholder : Theme.Colors.label)
                .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
                .padding(.horizontal, Theme.Spacing.cardPadding)
                .padding(.top, 14)
                .padding(.bottom, 14)
        }
    }
}

struct HeroChip<Leading: View>: View {
    let text: String
    let foreground: Color
    let background: Color
    @ViewBuilder var leading: Leading

    var body: some View {
        HStack(spacing: 4) {
            leading
            Text(text)
                .font(Theme.Fonts.section)
                .foregroundStyle(foreground)
        }
        .padding(.horizontal, 12)
        .frame(height: 26)
        .background(Capsule().fill(background))
    }
}

extension HeroChip where Leading == EmptyView {
    init(text: String, foreground: Color, background: Color) {
        self.init(text: text, foreground: foreground, background: background) { EmptyView() }
    }
}

struct DetailActionBar: View {
    let primaryTitle: String
    var primaryIsMuted = false
    let onDelete: () -> Void
    let onPrimary: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDelete) {
                Text("Delete")
                    .font(Theme.Fonts.navTitle)
                    .foregroundStyle(Theme.Colors.accentDeep)
                    .frame(width: 120, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.primaryButton, style: .continuous)
                            .fill(Theme.Colors.accentTint)
                    )
            }
            .buttonStyle(.pressable)

            if primaryIsMuted {
                Button(action: onPrimary) {
                    Text(primaryTitle)
                        .font(Theme.Fonts.navTitle)
                        .foregroundStyle(Theme.Colors.label)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.primaryButton, style: .continuous)
                                .fill(Theme.Colors.card)
                        )
                }
                .buttonStyle(.pressable)
            } else {
                PrimaryButton(title: primaryTitle, action: onPrimary)
            }
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Theme.Colors.background)
    }
}
