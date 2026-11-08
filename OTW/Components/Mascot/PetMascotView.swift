import SwiftUI

enum PetExpression: Hashable {
    case `default`, happy, wink, love, nervous
}

struct MascotState: Equatable {
    var expression: PetExpression = .default
    var isLive = false
    var bounceTrigger = 0
    var hopTrigger = 0
    var shakeTrigger = 0
}

struct PetMascotView: View {
    var expression: PetExpression = .default
    var isLive = true
    var bounceTrigger = 0
    var hopTrigger = 0
    var shakeTrigger = 0
    var hopHeight: CGFloat = 6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isBlinking = false
    @State private var earTrigger = 0
    @State private var nervousTrigger = 0

    private var loopsEnabled: Bool { isLive && !reduceMotion }

    var body: some View {
        ZStack {
            MascotBodyView(earTrigger: earTrigger, animatesEars: loopsEnabled)
            eyes
        }
        .phaseAnimator(loopsEnabled ? [false, true] : [false]) { content, up in
            content
                .scaleEffect(loopsEnabled && up ? 1.03 : 1, anchor: .bottom)
                .offset(y: loopsEnabled ? (up ? -2 : 2) : 0)
        } animation: { _ in
            .easeInOut(duration: 1.25)
        }
        .keyframeAnimator(initialValue: MascotMotion(), trigger: bounceTrigger) { content, motion in
            let m = reduceMotion ? MascotMotion() : motion
            content.scaleEffect(x: m.scaleX, y: m.scaleY, anchor: .bottom)
        } keyframes: { _ in
            KeyframeTrack(\.scaleX) {
                CubicKeyframe(1.1, duration: 0.08)
                SpringKeyframe(0.92, duration: 0.14, spring: .snappy)
                SpringKeyframe(1, duration: 0.24, spring: .bouncy)
            }
            KeyframeTrack(\.scaleY) {
                CubicKeyframe(0.86, duration: 0.08)
                SpringKeyframe(1.1, duration: 0.14, spring: .snappy)
                SpringKeyframe(1, duration: 0.24, spring: .bouncy)
            }
        }
        .keyframeAnimator(initialValue: MascotMotion(), trigger: hopTrigger) { content, motion in
            let m = reduceMotion ? MascotMotion() : motion
            content
                .scaleEffect(x: m.scaleX, y: m.scaleY, anchor: .bottom)
                .offset(y: m.y)
        } keyframes: { _ in
            KeyframeTrack(\.y) {
                CubicKeyframe(0, duration: 0.08)
                CubicKeyframe(-hopHeight, duration: 0.16)
                CubicKeyframe(0, duration: 0.16)
                SpringKeyframe(0, duration: 0.15)
            }
            KeyframeTrack(\.scaleX) {
                CubicKeyframe(1.08, duration: 0.08)
                CubicKeyframe(0.94, duration: 0.16)
                CubicKeyframe(1.08, duration: 0.16)
                SpringKeyframe(1, duration: 0.15, spring: .bouncy)
            }
            KeyframeTrack(\.scaleY) {
                CubicKeyframe(0.9, duration: 0.08)
                CubicKeyframe(1.08, duration: 0.16)
                CubicKeyframe(0.9, duration: 0.16)
                SpringKeyframe(1, duration: 0.15, spring: .bouncy)
            }
        }
        .keyframeAnimator(initialValue: MascotMotion(), trigger: shakeTrigger &+ nervousTrigger) { content, motion in
            let m = reduceMotion ? MascotMotion() : motion
            content
                .rotationEffect(.degrees(m.angle), anchor: .bottom)
                .offset(x: m.x)
        } keyframes: { _ in
            KeyframeTrack(\.x) {
                CubicKeyframe(-1.5, duration: 0.06)
                CubicKeyframe(1.5, duration: 0.07)
                CubicKeyframe(-1.2, duration: 0.07)
                CubicKeyframe(1, duration: 0.07)
                SpringKeyframe(0, duration: 0.12)
            }
            KeyframeTrack(\.angle) {
                CubicKeyframe(-4, duration: 0.06)
                CubicKeyframe(4, duration: 0.07)
                CubicKeyframe(-3, duration: 0.07)
                CubicKeyframe(2, duration: 0.07)
                SpringKeyframe(0, duration: 0.12)
            }
        }
        .task(id: loopsEnabled) {
            guard loopsEnabled else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3...6)))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.06)) { isBlinking = true }
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.spring(duration: 0.1)) { isBlinking = false }
            }
        }
        .task(id: loopsEnabled) {
            guard loopsEnabled else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 5...9)))
                guard !Task.isCancelled else { return }
                earTrigger &+= 1
            }
        }
        .task(id: loopsEnabled && expression == .nervous) {
            guard loopsEnabled && expression == .nervous else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3.5...5.5)))
                guard !Task.isCancelled else { return }
                nervousTrigger &+= 1
            }
        }
        .accessibilityHidden(true)
    }

    private var eyes: some View {
        ZStack {
            ForEach(Array(MascotArt.eyes(for: expression).enumerated()), id: \.offset) { _, eye in
                MascotShape(path: eye.path)
                    .fill(Color.white)
                    .scaleEffect(x: 1, y: eye.blinks && isBlinking ? 0.1 : 1, anchor: eye.anchor)
            }
        }
        .id(expression)
        .transition(.eyeMorph)
        .animation(.spring(duration: 0.3, bounce: 0.2), value: expression)
    }
}

struct MascotMotion {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var angle: Double = 0
}

// MARK: - Body and ears

private struct MascotBodyView: View {
    let earTrigger: Int
    let animatesEars: Bool

    var body: some View {
        ZStack {
            MascotShape(path: MascotArt.body)
                .fill(Theme.Colors.accent)
                .mask(MascotEarCutout().fill(style: FillStyle(eoFill: true)))

            ForEach(Array(MascotArt.ears.enumerated()), id: \.offset) { index, ear in
                MascotShape(path: MascotArt.body)
                    .fill(Theme.Colors.accent)
                    .clipShape(MascotRect(rect: ear.piece))
                    .keyframeAnimator(initialValue: 0.0, trigger: earTrigger) { content, angle in
                        content.rotationEffect(.degrees(animatesEars ? angle * ear.direction : 0), anchor: ear.pivot)
                    } keyframes: { _ in
                        KeyframeTrack {
                            CubicKeyframe(0, duration: index == 0 ? 0 : 0.06)
                            CubicKeyframe(-9, duration: 0.1)
                            CubicKeyframe(7, duration: 0.12)
                            CubicKeyframe(-3, duration: 0.1)
                            SpringKeyframe(0, duration: 0.2)
                        }
                    }
            }
        }
    }
}

struct MascotShape: Shape {
    let path: Path

    func path(in rect: CGRect) -> Path {
        path.applying(CGAffineTransform(scaleX: rect.width / MascotArt.size.width, y: rect.height / MascotArt.size.height))
    }
}

private struct MascotRect: Shape {
    let rect: CGRect

    func path(in frame: CGRect) -> Path {
        let sx = frame.width / MascotArt.size.width
        let sy = frame.height / MascotArt.size.height
        return Path(CGRect(x: rect.minX * sx, y: rect.minY * sy, width: rect.width * sx, height: rect.height * sy))
    }
}

private struct MascotEarCutout: Shape {
    func path(in frame: CGRect) -> Path {
        let sx = frame.width / MascotArt.size.width
        let sy = frame.height / MascotArt.size.height
        var path = Path(CGRect(x: -10 * sx, y: -10 * sy, width: 132 * sx, height: 140 * sy))
        for ear in MascotArt.ears {
            let r = ear.cut
            path.addRect(CGRect(x: r.minX * sx, y: r.minY * sy, width: r.width * sx, height: r.height * sy))
        }
        return path
    }
}

private struct EyeSquash: ViewModifier {
    let amount: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: 1, y: amount, anchor: UnitPoint(x: 0.5, y: 0.58))
            .opacity(Double(min(1, amount * 4)))
    }
}

extension AnyTransition {
    static var eyeMorph: AnyTransition {
        .modifier(active: EyeSquash(amount: 0.05), identity: EyeSquash(amount: 1))
    }
}

// MARK: - Artwork

enum MascotArt {
    static let size = CGSize(width: 112, height: 120)

    struct Eye {
        let path: Path
        let blinks: Bool
        var anchor: UnitPoint {
            let box = path.boundingRect
            return UnitPoint(x: box.midX / MascotArt.size.width, y: box.midY / MascotArt.size.height)
        }
    }

    struct Ear {
        let piece: CGRect
        let cut: CGRect
        let pivot: UnitPoint
        let direction: Double
    }

    static let body = SVGPathParser.path(
        "M27.6974155,119.7 C2.97669482,116.4 -4.99447635,98.3 2.97669482,63.9 C6.30642455,49.4 12.6631813,32.8 23.5604786,10.8 C27.0920101,3.6 28.20192,2 30.320839,1.4 C33.6505687,0.4 35.5676858,3.1 37.1821002,10.9 C38.4938119,16.9 40.0073255,19.1 43.6397579,20.2 C51.0055237,22.4 69.0667849,21 76.3316498,17.7 C80.9730912,15.6 85.0091273,11.2 86.5226408,6.6 C87.9352534,2.3 89.9532714,0 92.4757939,0 C95.3010191,0 96.8145327,1.9 99.7406588,8.6 C106.904623,25.1 111.848767,48.1 112.25237,66.4 C112.857776,91.6 106.400118,107.6 92.4757939,115.7 C90.356875,117 85.7154336,118.6 81.8811993,119.5 C78.8541723,120.2 32.5406588,120.4 27.6974155,119.7 Z"
    )

    static let ears: [Ear] = [
        Ear(
            piece: CGRect(x: 14, y: -6, width: 31, height: 30),
            cut: CGRect(x: 14, y: -6, width: 31, height: 26),
            pivot: UnitPoint(x: 30 / 112, y: 20 / 120),
            direction: 1
        ),
        Ear(
            piece: CGRect(x: 80, y: -6, width: 32, height: 28),
            cut: CGRect(x: 80, y: -6, width: 32, height: 24),
            pivot: UnitPoint(x: 93 / 112, y: 17 / 120),
            direction: -1
        ),
    ]

    static func eyes(for expression: PetExpression) -> [Eye] {
        switch expression {
        case .default: defaultEyes
        case .happy: happyEyes
        case .wink: winkEyes
        case .love: loveEyes
        case .nervous: nervousEyes
        }
    }

    private static let defaultEyes: [Eye] = [
        Eye(path: SVGPathParser.path("M24.7712894,87.6 C17.2037218,83.6 13.7730912,65 18.8181363,54.9 C24.4685867,43.5 35.2649831,54.5 35.2649831,71.6 C35.2649831,83 30.320839,90.5 24.7712894,87.6 Z"), blinks: true),
        Eye(path: SVGPathParser.path("M58.3712894,89.4 C49.9965146,84.4 51.2073255,60.4 60.3893074,50.5 C71.2866047,38.6 79.6613795,59.2 71.8920101,78.9 C69.974893,83.7 66.2415597,88.4 63.5172354,89.5 C62.0037218,90.2 59.4811993,90.1 58.3712894,89.4 Z"), blinks: true),
    ]

    private static let happyEyes: [Eye] = [
        Eye(path: SVGPathParser.path("M39.1372012,72.197462 C38.8398561,71.997462 38.0469357,70.497462 37.3531304,68.797462 C34.7761393,62.197462 31.5053428,59.297462 27.441626,59.697462 C23.9725994,59.997462 21.2964932,62.597462 19.0168472,67.797462 C17.4310065,71.497462 16.4398561,72.397462 15.5478207,71.197462 C12.9708295,68.097462 15.5478207,58.297462 19.9088826,54.097462 C29.0274667,45.397462 41.6150773,52.997462 41.6150773,67.097462 C41.6150773,71.097462 40.5248118,73.297462 39.1372012,72.197462 Z"), blinks: false),
        Eye(path: SVGPathParser.path("M81.3602101,72.097462 C81.0628649,71.797462 80.4681747,70.397462 79.9725994,68.897462 C78.6841039,65.297462 77.5938384,63.297462 75.4133074,61.197462 C70.2593251,55.997462 64.2133074,58.197462 59.9513605,66.897462 C58.9602101,68.997462 57.8699446,70.797462 57.4734844,71.097462 C55.7885286,72.197462 54.5991481,68.197462 55.2929534,63.697462 C56.8787941,53.997462 64.2133074,47.597462 72.1425109,48.897462 C78.6841039,49.997462 83.1442809,55.497462 84.3336614,63.797462 C85.1265817,69.197462 83.3425109,74.297462 81.3602101,72.097462 Z"), blinks: false),
    ]

    private static let winkEyes: [Eye] = [
        Eye(path: SVGPathParser.path("M24.7186216,87.667365 C16.2429459,83.467365 13.5186216,60.667365 20.4807838,52.367365 C26.5348378,45.267365 35.2123153,56.667365 35.2123153,71.767365 C35.2123153,83.067365 30.369072,90.367365 24.7186216,87.667365 Z"), blinks: true),
        Eye(path: SVGPathParser.path("M57.1078108,74.267365 C55.0897928,72.067365 61.7492522,64.567365 68.4087117,61.567365 C73.151054,59.367365 80.6177207,58.767365 83.6447477,60.267365 C85.360063,61.067365 85.0573603,61.367365 82.1312342,61.667365 C77.8933964,61.967365 71.133036,64.267365 70.2249279,65.667365 C70.2249279,65.767365 71.7384414,65.867365 73.6555585,65.867365 C79.8105135,65.867365 85.6627657,68.367365 88.7906937,72.267365 C89.7997027,73.667365 89.2951982,73.667365 86.7726756,72.567365 C78.3979009,68.967365 69.4177207,69.467365 60.8411441,73.967365 C58.924027,74.967365 57.8141171,75.067365 57.1078108,74.267365 Z"), blinks: false),
    ]

    private static let loveEyes: [Eye] = [
        Eye(path: SVGPathParser.path("M24.3628218,80.465658 C17.0979569,75.765658 13.1628218,71.965658 11.3466056,68.265658 C7.71417314,60.565658 16.1898488,54.365658 22.5466056,60.065658 L24.16102,61.565658 L24.5646236,60.265658 C26.179038,55.665658 30.8204794,53.365658 34.5538128,55.265658 C39.2961551,57.665658 39.4979569,63.765658 35.0583173,72.465658 C33.343002,75.765658 29.0042632,82.865658 28.4997587,83.065658 C28.3988578,83.065658 26.4817407,81.965658 24.3628218,80.465658 Z"), blinks: false),
        Eye(path: SVGPathParser.path("M59.3754344,80.965658 C51.0006596,68.365658 48.8817407,59.765658 53.2204794,55.065658 C55.0366957,53.165658 56.4493083,52.565658 58.9718308,52.565658 C62.6042632,52.565658 65.1267858,54.365658 66.943002,58.165658 L67.8511101,60.065658 L69.2637227,58.765658 C73.5015605,54.865658 78.4457047,54.665658 81.7754344,58.465658 C83.0871461,60.065658 83.5916506,61.265658 83.5916506,63.565658 C83.5916506,68.165658 80.4637227,72.565658 73.0979569,78.365658 C69.8691281,80.965658 63.2096686,85.465658 62.7051641,85.465658 C62.5033623,85.465658 60.9898488,83.465658 59.3754344,80.965658 Z"), blinks: false),
    ]

    private static let nervousEyes: [Eye] = [
        Eye(path: SVGPathParser.path("M29.26729,84.8159223 C28.4600828,84.5159223 27.2492719,83.7159223 26.0384611,82.4159223 C16.95738,73.3159223 16.4528755,49.2159223 25.130353,38.8159223 C31.7898125,30.9159223 40.3663891,35.9159223 43.7970197,49.5159223 C48.4384611,68.0159223 39.9627855,88.7159223 29.26729,84.8159223 Z"), blinks: true),
        Eye(path: SVGPathParser.path("M73.5627855,74.1159223 C72.0492719,73.4159223 69.8294521,71.0159223 68.8204431,69.1159223 C67.7105332,66.8159223 67.6096323,62.5159223 68.7195422,60.4159223 C70.6366593,56.6159223 73.7645873,54.7159223 78.3051278,54.7159223 C81.6348575,54.7159223 82.9465692,55.2159223 84.7627855,57.2159223 C88.6979206,61.8159223 87.5880107,71.4159223 82.8456683,73.8159223 C81.3321548,74.6159223 75.076299,74.7159223 73.5627855,74.1159223 Z"), blinks: true),
        Eye(path: SVGPathParser.path("M53.5844071,96.8159223 C53.0799026,96.4159223 51.9699927,95.3159223 51.0618846,94.2159223 C48.8420647,91.3159223 48.4384611,91.0159223 48.1357584,91.0159223 C47.3285512,91.0159223 45.7141368,92.2159223 43.1916143,94.6159223 L40.46729,97.2159223 L38.8528755,95.7159223 L37.2384611,94.3159223 L40.2654882,91.3159223 C46.521344,85.2159223 49.7501728,85.0159223 54.0889116,90.8159223 C55.9051278,93.2159223 55.9051278,93.2159223 57.3177404,91.8159223 C57.9231458,91.1159223 59.1339566,89.7159223 59.8402629,88.6159223 C63.3717945,83.7159223 66.2979206,82.0159223 69.1231458,83.4159223 C70.1321548,83.9159223 71.8474701,86.2159223 73.4618846,89.0159223 C74.06729,90.2159223 74.5717945,91.2159223 74.6726954,91.3159223 C74.9753981,91.6159223 76.6907134,89.2159223 78.103326,86.7159223 C78.9105332,85.3159223 79.7177404,84.2159223 79.8186413,84.2159223 C81.130353,84.8159223 83.148371,86.0159223 83.2492719,86.2159223 C83.5519746,86.7159223 79.2132359,93.3159223 77.6997224,94.6159223 C74.7735963,97.1159223 72.3519746,96.0159223 69.4258485,90.8159223 C66.903326,86.6159223 66.903326,86.6159223 63.4726954,91.3159223 C59.1339566,97.1159223 56.3087314,98.7159223 53.5844071,96.8159223 Z"), blinks: false),
    ]
}

enum SVGPathParser {
    static func path(_ data: String) -> Path {
        var path = Path()
        let tokens = tokenize(data)
        var index = 0
        var command: Character = "M"
        var current = CGPoint.zero

        func number() -> CGFloat {
            guard index < tokens.count, let value = Double(tokens[index]) else { index += 1; return 0 }
            index += 1
            return CGFloat(value)
        }

        while index < tokens.count {
            if let first = tokens[index].first, first.isLetter, tokens[index].count == 1 {
                command = first
                index += 1
                if command == "Z" || command == "z" {
                    path.closeSubpath()
                    continue
                }
            }
            switch command {
            case "M":
                current = CGPoint(x: number(), y: number())
                path.move(to: current)
                command = "L"
            case "L":
                current = CGPoint(x: number(), y: number())
                path.addLine(to: current)
            case "H":
                current = CGPoint(x: number(), y: current.y)
                path.addLine(to: current)
            case "V":
                current = CGPoint(x: current.x, y: number())
                path.addLine(to: current)
            case "C":
                let c1 = CGPoint(x: number(), y: number())
                let c2 = CGPoint(x: number(), y: number())
                current = CGPoint(x: number(), y: number())
                path.addCurve(to: current, control1: c1, control2: c2)
            default:
                index += 1
            }
        }
        return path
    }

    private static func tokenize(_ data: String) -> [String] {
        var tokens: [String] = []
        var currentNumber = ""
        func flush() {
            if !currentNumber.isEmpty { tokens.append(currentNumber); currentNumber = "" }
        }
        for char in data {
            if "MLHVCZmlhvcz".contains(char) {
                flush()
                tokens.append(String(char))
            } else if char == "-" {
                if let last = currentNumber.last, last == "e" || last == "E" {
                    currentNumber.append(char)
                } else {
                    flush()
                    currentNumber.append(char)
                }
            } else if char.isNumber || char == "." || char == "e" || char == "E" {
                currentNumber.append(char)
            } else {
                flush()
            }
        }
        flush()
        return tokens
    }
}

#Preview {
    HStack(spacing: 16) {
        PetMascotView(expression: .default).frame(width: 56, height: 60)
        PetMascotView(expression: .happy).frame(width: 56, height: 60)
        PetMascotView(expression: .wink).frame(width: 56, height: 60)
        PetMascotView(expression: .love).frame(width: 56, height: 60)
        PetMascotView(expression: .nervous).frame(width: 56, height: 60)
    }
}
