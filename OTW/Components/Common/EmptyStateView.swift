import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
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
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
    }
}

#Preview {
    EmptyStateView(
        title: "Nothing planned yet",
        subtitle: "Enjoy your free time, or plan something new.",
        action: {}
    )
}
