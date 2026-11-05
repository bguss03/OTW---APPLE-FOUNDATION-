import SwiftUI

/// How the pet feels about today's plans.
enum PetMood {
    case normal
    /// Every reminder scheduled today is done.
    case love
    /// A High reminder is past its due time and still open.
    case nervous

    /// Resting expression of the header mascot.
    var expression: PetExpression {
        switch self {
        case .normal: .default
        case .love: .love
        case .nervous: .nervous
        }
    }

    /// Pet inside the tip bubble (the Sketch frame uses the winking pet).
    var tipImage: String {
        switch self {
        case .normal: "PetWink"
        case .love: "PetLove"
        case .nervous: "PetNervous"
        }
    }
}

/// Rebuild of "v3 / Home – Pet Tip": a dim layer, the header actions highlighted in place,
/// and a white banner 12pt below them, trailing-aligned with the screen margin.
/// The banner slides down, its mascot plays an intro and then idles; tap the mascot to make it
/// react, tap or swipe up the banner to dismiss. It auto-dismisses after about 5 seconds.
struct PetTipOverlay: View {
    @Binding var isPresented: Bool
    let anchor: Anchor<CGRect>?
    let mood: PetMood
    let mascot: MascotState
    let title: String
    let message: String
    let onAdd: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0
    @State private var mascotTaps = 0
    /// Bumped by interaction to restart the auto-dismiss timer.
    @State private var dismissTimer = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            if isPresented {
                Theme.Colors.dim
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture(perform: dismiss)
                    .transition(.opacity)
                    .accessibilityLabel("Dismiss tip")
                    .accessibilityAddTraits(.isButton)
            }

            GeometryReader { proxy in
                if isPresented, let anchor {
                    let rect = proxy[anchor]
                    ZStack(alignment: .topLeading) {
                        HeaderActionsView(
                            mascot: mascot,
                            onPetTap: dismiss,
                            onAddTap: {
                                dismiss()
                                onAdd()
                            }
                        )
                        .frame(width: rect.width, height: rect.height)
                        .offset(x: rect.minX, y: rect.minY)

                        bubble
                            .frame(width: 352)
                            .offset(x: rect.maxX - 352, y: rect.maxY + 12 + dragOffset)
                            .transition(bannerTransition)
                    }
                }
            }
        }
        .allowsHitTesting(isPresented)
        .animation(reduceMotion ? .easeInOut(duration: 0.25) : Theme.Motion.bouncy, value: isPresented)
        .onChange(of: isPresented) { _, presented in
            if presented { dragOffset = 0 }
        }
    }

    /// Slides down on the way in and springs up on the way out; a plain fade with Reduce Motion.
    private var bannerTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .offset(y: -28).combined(with: .opacity),
            removal: .offset(y: -44).combined(with: .opacity)
        )
    }

    // MARK: - Bubble (352 x 120, radius 24, black 15% shadow y10 blur30)

    private var bubble: some View {
        HStack(alignment: .top, spacing: 14) {
            LiveMascotView(
                expression: mood == .normal ? .default : mood.expression,
                isLive: true,
                playsIntro: true,
                tapTrigger: mascotTaps,
                hopHeight: 6
            )
            .frame(width: 70, height: 76)
            .padding(.top, 2)
            .contentShape(Rectangle())
            // The mascot's own tap wins over the banner's dismiss tap.
            .onTapGesture {
                mascotTaps += 1
                dismissTimer += 1
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .accessibilityElement()
            .accessibilityLabel("Pet")
            .accessibilityAddTraits(.isButton)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Theme.Fonts.bubbleTitle)
                    .foregroundStyle(Theme.Colors.label)
                    .frame(minHeight: 20)
                Text(message)
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
        .padding(.leading, 18)
        .padding(.trailing, 14)
        .padding(.vertical, 20)
        .frame(minHeight: 120, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.bubble, style: .continuous)
                .fill(Color.white)
        )
        .themeShadow(Theme.Shadow.bubble)
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.bubble, style: .continuous))
        .onTapGesture(perform: dismiss)
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    // Follows the finger upward, resists downward pulls.
                    let dy = value.translation.height
                    dragOffset = dy < 0 ? dy : dy * 0.15
                }
                .onEnded { value in
                    if value.translation.height < -30 || value.predictedEndTranslation.height < -80 {
                        dismiss()
                    } else {
                        withAnimation(Theme.Motion.bouncy) { dragOffset = 0 }
                    }
                }
        )
        // Auto-dismiss ~5 s after appearing (or after the last mascot tap).
        .task(id: dismissTimer) {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            dismiss()
        }
        .accessibilityAction(named: "Dismiss", dismiss)
    }

    private func dismiss() {
        guard isPresented else { return }
        isPresented = false
    }
}
