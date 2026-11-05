import SwiftUI

/// Sketch "OTW3/Header Actions": pet button and orange add button (96 x 44), shared by Home,
/// Calendar and the Pet Tip highlight.
struct HeaderActionsView: View {
    var mascot = MascotState()
    let onPetTap: () -> Void
    var onPetLongPress: (() -> Void)? = nil
    let onAddTap: () -> Void

    @State private var isPressingPet = false
    @State private var petTaps = 0

    var body: some View {
        HStack(spacing: 8) {
            if let onPetLongPress {
                // Tap and long press are exclusive gestures, so a hold never also opens the tip.
                petCircle
                    .scaleEffect(isPressingPet ? 0.95 : 1)
                    .opacity(isPressingPet ? 0.75 : 1)
                    .animation(Theme.Motion.snappy, value: isPressingPet)
                    .contentShape(Circle())
                    .onTapGesture(perform: petTapped)
                    .onLongPressGesture(minimumDuration: 0.6, perform: onPetLongPress) { pressing in
                        isPressingPet = pressing
                    }
                    .accessibilityElement()
                    .accessibilityLabel("Pet")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { petTapped() }
            } else {
                Button(action: petTapped) { petCircle }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Pet")
            }

            Button(action: onAddTap) {
                Circle()
                    .fill(Theme.Colors.accent)
                    .frame(width: Theme.Size.headerButton, height: Theme.Size.headerButton)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.Colors.onAccent)
                    }
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Add")
        }
    }

    private func petTapped() {
        petTaps += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onPetTap()
    }

    private var petCircle: some View {
        Circle()
            .fill(Theme.Colors.accentTint)
            .frame(width: Theme.Size.headerButton, height: Theme.Size.headerButton)
            .overlay {
                LiveMascotView(
                    expression: mascot.expression,
                    isLive: mascot.isLive,
                    tapTrigger: petTaps,
                    hopTrigger: mascot.hopTrigger,
                    shakeTrigger: mascot.shakeTrigger,
                    hopHeight: 5
                )
                .frame(width: Theme.Size.headerPetImage.width, height: Theme.Size.headerPetImage.height)
            }
    }
}

/// Reports where Home's header actions are drawn so the Pet Tip can highlight them in place.
struct HeaderActionsAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}
