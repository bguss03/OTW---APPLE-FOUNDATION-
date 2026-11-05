import SwiftUI

/// Sketch "Card/<Event>" group from the Home › Event list (392 x 80, radius 22).
struct EventCardView: View {
    let event: Event

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Start 17 semibold at y 18, end 13 regular at y 41.
            VStack(alignment: .leading, spacing: 1) {
                Text(OTWFormat.time(event.startDate))
                    .font(Theme.Fonts.cardTitle)
                    .foregroundStyle(Theme.Colors.label)
                Text(OTWFormat.time(event.endDate))
                    .font(Theme.Fonts.cardMeta)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .frame(width: 56, alignment: .leading)
            .padding(.top, 18)

            // Coloured bar 4 x 48 at x 78.
            RoundedRectangle(cornerRadius: Theme.Radius.eventBar, style: .continuous)
                .fill(event.tagColor.color)
                .frame(width: Theme.Size.eventBar.width, height: Theme.Size.eventBar.height)
                .padding(.leading, 6)
                .padding(.top, Theme.Spacing.cardPadding)

            // Title at x 96 / y 16, meta row at y 42.
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(Theme.Fonts.cardTitle)
                    .foregroundStyle(Theme.Colors.label)
                    .lineLimit(1)

                if !event.metaText.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: event.locationKind.symbolName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(event.tagColor.color)
                            .frame(width: Theme.Size.metaIcon, height: Theme.Size.metaIcon)
                        Text(event.metaText)
                            .font(Theme.Fonts.cardMeta)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.leading, 14)
            .padding(.top, Theme.Spacing.cardPadding)

            Spacer(minLength: Theme.Spacing.cardPadding)
        }
        .padding(.leading, Theme.Spacing.cardPadding)
        .frame(maxWidth: .infinity, minHeight: Theme.Size.cardHeight, maxHeight: Theme.Size.cardHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Colors.card)
        )
    }
}

extension TagColor {
    var color: Color {
        switch self {
        case .orange: Theme.Colors.tagOrange
        case .blue: Theme.Colors.tagBlue
        case .purple: Theme.Colors.tagPurple
        case .green: Theme.Colors.tagGreen
        case .red: Theme.Colors.tagRed
        case .yellow: Theme.Colors.tagYellow
        case .teal: Theme.Colors.tagTeal
        }
    }
}

extension LocationKind {
    /// SF Symbol matching the Sketch meta icon (video camera, map pin, person).
    var symbolName: String {
        switch self {
        case .online: "video"
        case .place: "mappin"
        case .person: "person"
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.cardGap) {
        ForEach(SampleData.events(relativeTo: Calendar.current.startOfDay(for: .now)).prefix(4), id: \.title) { event in
            EventCardView(event: event)
        }
    }
    .padding(.horizontal, Theme.Spacing.screen)
}
