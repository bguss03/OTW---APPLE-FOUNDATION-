import SwiftUI

struct HomeHeaderView: View {
    let selectedDate: Date
    var mascot = MascotState()
    let onMonthTap: () -> Void
    let onPetTap: () -> Void
    var onPetLongPress: (() -> Void)? = nil
    let onAddTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(OTWFormat.eyebrow(selectedDate))
                .font(Theme.Fonts.eyebrow)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(height: 16)

            HStack(alignment: .top, spacing: 0) {
                Button(action: onMonthTap) {
                    HStack(spacing: 6) {
                        Text(OTWFormat.monthTitle(selectedDate))
                            .font(Theme.Fonts.monthTitle)
                            .foregroundStyle(Theme.Colors.label)
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

                HeaderActionsView(
                    mascot: mascot,
                    onPetTap: onPetTap,
                    onPetLongPress: onPetLongPress,
                    onAddTap: onAddTap
                )
                .anchorPreference(key: HeaderActionsAnchorKey.self, value: .bounds) { $0 }
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
