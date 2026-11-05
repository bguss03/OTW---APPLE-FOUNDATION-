// xcode: set sdk=iOS

import SwiftUI

/// Sketch "Empty State" group: pet, title, subtitle and a tinted "+ Add …" button.
struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            PetMascotView(expression: .default, hopHeight: 10)
                .frame(width: Theme.Size.emptyPet.width, height: Theme.Size.emptyPet.height)

            Text(title)
                .font(Theme.Fonts.emptyTitle)
                .foregroundStyle(Theme.Colors.label)
                .frame(height: 23)
                .padding(.top, 20)

            Text(subtitle)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .frame(width: 300, height: 36, alignment: .top)
                .padding(.top, 7)

            Button(action: action) {
                Text("+  \(buttonTitle)")
                    .font(Theme.Fonts.button)
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(width: Theme.Size.emptyButton.width, height: Theme.Size.emptyButton.height)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.secondaryButton, style: .continuous)
                            .fill(Theme.Colors.accentTint)
                    )
            }
            .buttonStyle(.pressable)
            .padding(.top, 24)
        }
        .frame(maxWidth: .infinity)
        // Empty state starts 64pt below the top of the list area in the design.
        .padding(.top, 64)
    }
}

#Preview {
    EmptyStateView(
        title: "Nothing planned yet",
        subtitle: "Enjoy your free time, or plan something new.",
        buttonTitle: "Add Event",
        action: {}
    )
}
