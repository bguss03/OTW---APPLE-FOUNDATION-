import SwiftUI

enum Theme {

    // MARK: - Colors

    enum Colors {
        static let accent = Color(hex: 0xFC6C01)
        static let accentDeep = Color(hex: 0xE05F00)
        static let accentSoft = Color(hex: 0xFD8F3E)
        static let accentPale = Color(hex: 0xFDB27A)
        static let accentTint = Color(hex: 0xFFEBDB)
        static let accentTintMedium = Color(hex: 0xFFE1CC)
        static let accentTintLow = Color(hex: 0xFFF0E3)

        static let background = Color.white
        static let card = Color(hex: 0xF2F2F7)
        static let track = Color(hex: 0x787880).opacity(0.12)
        static let separator = Color(hex: 0x3C3C43).opacity(0.20)
        static let checkboxBorder = Color(hex: 0xD1D1D6)
        static let dim = Color.black.opacity(0.25)

        static let label = Color.black
        static let secondaryLabel = Color(hex: 0x8E8E93)
        static let tertiaryLabel = Color(hex: 0x3C3C43).opacity(0.60)
        static let placeholder = Color(hex: 0x3C3C43).opacity(0.30)
        static let onAccent = Color.white
        static let doneLabel = Color(hex: 0xC7C7CC)
        static let doneBadgeLabel = Color(hex: 0xAEAEB2)

        static let tagOrange = accent
        static let tagBlue = Color(hex: 0x007AFF)
        static let tagPurple = Color(hex: 0xAF52DE)
        static let tagGreen = Color(hex: 0x34C759)
        static let tagRed = Color(hex: 0xFF3B30)
        static let tagYellow = Color(hex: 0xFFCC00)
        static let tagTeal = Color(hex: 0x30B0C7)

        static let accentTintSoft = Color(hex: 0xFED4B3)
        static let accentShadow = Color(hex: 0xB84E00)

        static let weekendHeader = Color(hex: 0xC4B8AF)
        static let weekendDate = Color(hex: 0xAEAEB2)
    }

    // MARK: - Typography

    enum Fonts {
        static let monthTitle = Font.system(size: 34, weight: .bold)
        static let eyebrow = Font.system(size: 13, weight: .semibold)
        static let dayLabel = Font.system(size: 13, weight: .medium)
        static let dayNumber = Font.system(size: 20, weight: .semibold)
        static let segmentActive = Font.system(size: 15, weight: .semibold)
        static let segmentInactive = Font.system(size: 15, weight: .medium)
        static let count = Font.system(size: 13, weight: .semibold)
        static let cardTitle = Font.system(size: 17, weight: .semibold)
        static let cardMeta = Font.system(size: 13, weight: .regular)
        static let cardMetaEmphasis = Font.system(size: 13, weight: .semibold)
        static let badge = Font.system(size: 12, weight: .semibold)
        static let emptyTitle = Font.system(size: 20, weight: .bold)
        static let body = Font.system(size: 15, weight: .regular)
        static let button = Font.system(size: 15, weight: .semibold)
        static let bubbleTitle = Font.system(size: 17, weight: .bold)
        static let navTitle = Font.system(size: 17, weight: .semibold)
        static let formLabel = Font.system(size: 17, weight: .regular)
        static let section = Font.system(size: 13, weight: .semibold)
        static let headline = Font.system(size: 20, weight: .bold)
        static let heroTitle = Font.system(size: 28, weight: .bold)
        static let chip = Font.system(size: 14, weight: .semibold)
        static let priority = Font.system(size: 16, weight: .semibold)
        static let formValue = Font.system(size: 17, weight: .regular)
        static let savingTitle = Font.system(size: 22, weight: .bold)
        static let savedTitle = Font.system(size: 34, weight: .bold)
        static let continueLabel = Font.system(size: 17, weight: .bold)
        static let streak = Font.system(size: 14, weight: .semibold)
        static let calendarDay = Font.system(size: 16, weight: .regular)
        static let calendarToday = Font.system(size: 16, weight: .bold)
        static let calendarPill = Font.system(size: 10, weight: .semibold)
        static let dayTitle = Font.system(size: 17, weight: .bold)
        static let navBack = Font.system(size: 17, weight: .regular)
    }

    // MARK: - Corner radii

    enum Radius {
        static let card: CGFloat = 22
        static let activePill: CGFloat = 24
        static let segmentTrack: CGFloat = 20
        static let segmentThumb: CGFloat = 17
        static let badge: CGFloat = 12
        static let eventBar: CGFloat = 2
        static let chip: CGFloat = 19
        static let valueChip: CGFloat = 17
        static let primaryButton: CGFloat = 28
        static let secondaryButton: CGFloat = 22
        static let heroChip: CGFloat = 13
        static let bubble: CGFloat = 24
        static let priorityPill: CGFloat = 24
    }

    // MARK: - Spacing and sizes

    enum Spacing {
        static let screen: CGFloat = 24
        static let cardGap: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let section: CGFloat = 16
        static let listTop: CGFloat = 10
    }

    enum Size {
        static let cardHeight: CGFloat = 80
        static let dateCellWidth: CGFloat = 56
        static let dateStripHeight: CGFloat = 76
        static let activePillWidth: CGFloat = 48
        static let dateDot: CGFloat = 5
        static let segmentHeight: CGFloat = 40
        static let segmentInset: CGFloat = 3
        static let headerButton: CGFloat = 44
        static let headerPetImage = CGSize(width: 26, height: 28)
        static let checkbox: CGFloat = 26
        static let checkboxBorder: CGFloat = 2
        static let eventBar = CGSize(width: 4, height: 48)
        static let metaIcon: CGFloat = 15
        static let badgeHeight: CGFloat = 24
        static let emptyPet = CGSize(width: 96, height: 104)
        static let emptyButton = CGSize(width: 168, height: 44)
    }

    // MARK: - Motion

    enum Motion {
        static let snappy = Animation.spring(duration: 0.28, bounce: 0.15)
        static let standard = Animation.spring(duration: 0.36, bounce: 0.18)
        static let bouncy = Animation.spring(duration: 0.42, bounce: 0.32)
    }

    // MARK: - Shadows

    enum Shadow {
        static let activePill = ShadowStyle(color: Colors.accent.opacity(0.35), radius: 8, y: 6)
        static let segmentThumb = ShadowStyle(color: Colors.accent.opacity(0.25), radius: 4, y: 3)
        static let primaryButton = ShadowStyle(color: Colors.accent.opacity(0.35), radius: 10, y: 8)
        static let bubble = ShadowStyle(color: Color.black.opacity(0.15), radius: 15, y: 10)
    }

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }
}

// MARK: - Helpers

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

extension View {
    func themeShadow(_ style: Theme.ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: 0, y: style.y)
    }
}
