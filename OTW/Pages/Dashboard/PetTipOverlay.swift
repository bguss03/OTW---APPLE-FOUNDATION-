import SwiftUI

enum PetMood {
    case normal
    case love
    case nervous

    var expression: PetExpression {
        switch self {
        case .normal: .default
        case .love: .love
        case .nervous: .nervous
        }
    }

    var tipImage: String {
        switch self {
        case .normal: "PetWink"
        case .love: "PetLove"
        case .nervous: "PetNervous"
        }
    }
}

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

    private var bannerTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .offset(y: -28).combined(with: .opacity),
            removal: .offset(y: -44).combined(with: .opacity)
        )
    }

    // MARK: - Bubble

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
