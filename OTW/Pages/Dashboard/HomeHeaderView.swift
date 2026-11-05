import SwiftUI

/// Sketch "Header" group: eyebrow, month button with chevron, and the pet / add buttons.
struct HomeHeaderView: View {
    let selectedDate: Date
    var mascot = MascotState()
    let onMonthTap: () -> Void
    let onPetTap: () -> Void
    var onPetLongPress: (() -> Void)? = nil
    let onAddTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // "SUNDAY, MAY 3"
            Text(OTWFormat.eyebrow(selectedDate))
                .font(Theme.Fonts.eyebrow)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(height: 16)

            HStack(alignment: .top, spacing: 0) {
                // "May 2026 ›"
                Button(action: onMonthTap) {
                    HStack(spacing: 6) {
                        Text(OTWFormat.monthTitle(selectedDate))
                            .font(Theme.Fonts.monthTitle)
                            .foregroundStyle(Theme.Colors.label)
                            // Long month names ("November 2026") shrink slightly instead of truncating.
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 20, height: 20)
                    }
                    .frame(height: 40)
                    .expandedHitArea(dy: 2)
                }
                .buttonStyle(.pressable)
                .accessibilityHint("Opens the calendar")

                Spacer(minLength: 8)

                // Header Actions symbol: pet button + add button (96 x 44).
                HeaderActionsView(
                    mascot: mascot,
                    onPetTap: onPetTap,
                    onPetLongPress: onPetLongPress,
                    onAddTap: onAddTap
                )
                .anchorPreference(key: HeaderActionsAnchorKey.self, value: .bounds) { $0 }
                // Actions sit 2pt above the month row in the design.
                .padding(.top, -2)
            }
            .frame(height: 42, alignment: .top)
        }
    }
}

#Preview {
    HomeHeaderView(selectedDate: Calendar.current.startOfDay(for: .now), onMonthTap: {}, onPetTap: {}, onAddTap: {})
        .padding(.horizontal, Theme.Spacing.screen)
}
