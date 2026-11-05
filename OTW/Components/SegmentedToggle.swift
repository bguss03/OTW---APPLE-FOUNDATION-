import SwiftUI

/// Sketch "Segmented Control": grey track, orange sliding thumb, Event / Reminders labels.
/// The thumb is one capsule that slides between segments with matchedGeometryEffect.
struct SegmentedToggle: View {
    @Binding var selection: PlanMode

    @Namespace private var thumbNamespace
    private let modes = PlanMode.allCases

    var body: some View {
        let inset = Theme.Size.segmentInset

        HStack(spacing: 0) {
            ForEach(modes) { mode in
                let isActive = mode == selection
                Text(mode.rawValue)
                    .font(isActive ? Theme.Fonts.segmentActive : Theme.Fonts.segmentInactive)
                    .foregroundStyle(isActive ? Theme.Colors.onAccent : Theme.Colors.tertiaryLabel)
                    .frame(maxWidth: .infinity)
                    .frame(height: Theme.Size.segmentHeight - inset * 2)
                    .background {
                        if isActive {
                            RoundedRectangle(cornerRadius: Theme.Radius.segmentThumb, style: .continuous)
                                .fill(Theme.Colors.accent)
                                .themeShadow(Theme.Shadow.segmentThumb)
                                .matchedGeometryEffect(id: "thumb", in: thumbNamespace)
                        }
                    }
                    .expandedHitArea(dy: 5)
                    .onTapGesture {
                        guard mode != selection else { return }
                        TickFeedback.shared.tick()
                        withAnimation(Theme.Motion.bouncy) {
                            selection = mode
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(inset)
        .frame(height: Theme.Size.segmentHeight)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.segmentTrack, style: .continuous)
                .fill(Theme.Colors.track)
        )
    }
}

#Preview {
    @Previewable @State var mode: PlanMode = .event
    SegmentedToggle(selection: $mode)
        .padding(.horizontal, Theme.Spacing.screen)
}
