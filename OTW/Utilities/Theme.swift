import SwiftUI

/// Design tokens read from the "Team 5" Sketch document, Page 1, "v3 /" frames.
/// All values are exact Sketch layer values (colors, SF system font sizes and weights,
/// corner radii, spacing) so that SwiftUI screens can be rebuilt pixel-close.
enum Theme {

    // MARK: - Colors

    enum Colors {
        /// Primary brand orange. Active pill, segmented thumb, add button, High badge, Save button.
        static let accent = Color(hex: 0xFC6C01)
        /// Deeper orange used for "Today, 18:00" due text and the Medium badge label.
        static let accentDeep = Color(hex: 0xE05F00)
        /// Softer orange used for the Low badge label.
        static let accentSoft = Color(hex: 0xFD8F3E)
        /// Pale orange used for the reminder dot in the date strip.
        static let accentPale = Color(hex: 0xFDB27A)
        /// Very light orange tint: pet button background, selected category chip, empty-state button.
        static let accentTint = Color(hex: 0xFFEBDB)
        /// Medium badge background.
        static let accentTintMedium = Color(hex: 0xFFE1CC)
        /// Low badge background.
        static let accentTintLow = Color(hex: 0xFFF0E3)

        /// Screen background.
        static let background = Color.white
        /// Card and field background (iOS systemGray6).
        static let card = Color(hex: 0xF2F2F7)
        /// Segmented control track and nav-bar back button background (#787880 at 12%).
        static let track = Color(hex: 0x787880).opacity(0.12)
        /// Row separator inside cards (#3C3C43 at 20%).
        static let separator = Color(hex: 0x3C3C43).opacity(0.20)
        /// Checkbox border (iOS systemGray4).
        static let checkboxBorder = Color(hex: 0xD1D1D6)
        /// Modal dim layer (black at 25%).
        static let dim = Color.black.opacity(0.25)

        /// Primary text.
        static let label = Color.black
        /// Secondary text (iOS systemGray).
        static let secondaryLabel = Color(hex: 0x8E8E93)
        /// Inactive segment label and pet bubble body (#3C3C43 at 60%).
        static let tertiaryLabel = Color(hex: 0x3C3C43).opacity(0.60)
        /// Text field placeholder (#3C3C43 at 30%).
        static let placeholder = Color(hex: 0x3C3C43).opacity(0.30)
        /// Text on orange surfaces.
        static let onAccent = Color.white
        /// Title, due text and alarm icon of a completed reminder (iOS systemGray3).
        static let doneLabel = Color(hex: 0xC7C7CC)
        /// Badge label of a completed reminder (iOS systemGray2).
        static let doneBadgeLabel = Color(hex: 0xAEAEB2)

        /// Event tag palette from "v3 / Add · Event" › Tag Color.
        static let tagOrange = accent
        static let tagBlue = Color(hex: 0x007AFF)
        static let tagPurple = Color(hex: 0xAF52DE)
        static let tagGreen = Color(hex: 0x34C759)
        static let tagRed = Color(hex: 0xFF3B30)
        static let tagYellow = Color(hex: 0xFFCC00)
        static let tagTeal = Color(hex: 0x30B0C7)

        /// Softest orange: "Saving..." button and third loader dot.
        static let accentTintSoft = Color(hex: 0xFED4B3)
        /// Dark orange used as the hard shadow under the CONTINUE button.
        static let accentShadow = Color(hex: 0xB84E00)

        /// Calendar weekend column letters ("S").
        static let weekendHeader = Color(hex: 0xC4B8AF)
        /// Calendar weekend day numbers.
        static let weekendDate = Color(hex: 0xAEAEB2)
    }

    // MARK: - Typography (SF system font, fixed sizes from Sketch)

    enum Fonts {
        /// "May 2026" month title.
        static let monthTitle = Font.system(size: 34, weight: .bold)
        /// "SUNDAY, MAY 3" eyebrow.
        static let eyebrow = Font.system(size: 13, weight: .semibold)
        /// Date strip weekday ("Sun").
        static let dayLabel = Font.system(size: 13, weight: .medium)
        /// Date strip day number ("3").
        static let dayNumber = Font.system(size: 20, weight: .semibold)
        /// Active segment label.
        static let segmentActive = Font.system(size: 15, weight: .semibold)
        /// Inactive segment label.
        static let segmentInactive = Font.system(size: 15, weight: .medium)
        /// "4 active events" counter.
        static let count = Font.system(size: 13, weight: .semibold)
        /// Card title and event start time.
        static let cardTitle = Font.system(size: 17, weight: .semibold)
        /// Card meta line, event end time, reminder category.
        static let cardMeta = Font.system(size: 13, weight: .regular)
        /// Highlighted reminder due text ("Today, 18:00").
        static let cardMetaEmphasis = Font.system(size: 13, weight: .semibold)
        /// Priority badge.
        static let badge = Font.system(size: 12, weight: .semibold)
        /// Empty state title.
        static let emptyTitle = Font.system(size: 20, weight: .bold)
        /// Empty state subtitle, pet bubble body.
        static let body = Font.system(size: 15, weight: .regular)
        /// Empty state button, category chips.
        static let button = Font.system(size: 15, weight: .semibold)
        /// Pet bubble title.
        static let bubbleTitle = Font.system(size: 17, weight: .bold)
        /// Nav bar title, form labels and values.
        static let navTitle = Font.system(size: 17, weight: .semibold)
        static let formLabel = Font.system(size: 17, weight: .regular)
        /// "NAME", "CATEGORY" section labels.
        static let section = Font.system(size: 13, weight: .semibold)
        /// Headline such as "Add New Plans".
        static let headline = Font.system(size: 20, weight: .bold)
        /// Detail hero title.
        static let heroTitle = Font.system(size: 28, weight: .bold)
        /// Category chips ("Organization").
        static let chip = Font.system(size: 14, weight: .semibold)
        /// Priority buttons ("High").
        static let priority = Font.system(size: 16, weight: .semibold)
        /// Form values, chips and inputs (17 regular).
        static let formValue = Font.system(size: 17, weight: .regular)
        /// "Saving your plan..." title.
        static let savingTitle = Font.system(size: 22, weight: .bold)
        /// "Saved!" title.
        static let savedTitle = Font.system(size: 34, weight: .bold)
        /// "CONTINUE" label.
        static let continueLabel = Font.system(size: 17, weight: .bold)
        /// "+1 plan today" chip.
        static let streak = Font.system(size: 14, weight: .semibold)
        /// Calendar grid day number.
        static let calendarDay = Font.system(size: 16, weight: .regular)
        /// Calendar "today" day number.
        static let calendarToday = Font.system(size: 16, weight: .bold)
        /// Calendar event / reminder pill label.
        static let calendarPill = Font.system(size: 10, weight: .semibold)
        /// Calendar selected-day header ("Sunday, May 3").
        static let dayTitle = Font.system(size: 17, weight: .bold)
        /// Plain nav back label ("Home").
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
        /// Horizontal screen margin.
        static let screen: CGFloat = 24
        /// Vertical gap between stacked cards.
        static let cardGap: CGFloat = 12
        /// Inner card padding.
        static let cardPadding: CGFloat = 16
        /// Gap between header, date strip, segmented control and counter.
        static let section: CGFloat = 16
        /// Gap between counter and first card.
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

    // MARK: - Motion (spring-based, 0.25–0.45 s)

    enum Motion {
        /// Small UI changes: chips, toggles, toasts.
        static let snappy = Animation.spring(duration: 0.28, bounce: 0.15)
        /// Default for list and content changes.
        static let standard = Animation.spring(duration: 0.36, bounce: 0.18)
        /// Playful moments: segmented thumb, save screen hand-off.
        static let bouncy = Animation.spring(duration: 0.42, bounce: 0.32)
    }

    // MARK: - Shadows

    enum Shadow {
        /// Active date pill: #FC6C01 at 35%, y 6, blur 16.
        static let activePill = ShadowStyle(color: Colors.accent.opacity(0.35), radius: 8, y: 6)
        /// Segmented thumb: #FC6C01 at 25%, y 3, blur 8.
        static let segmentThumb = ShadowStyle(color: Colors.accent.opacity(0.25), radius: 4, y: 3)
        /// Primary button: #FC6C01 at 35%, y 8, blur 20.
        static let primaryButton = ShadowStyle(color: Colors.accent.opacity(0.35), radius: 10, y: 8)
        /// Pet bubble: black at 15%, y 10, blur 30.
        static let bubble = ShadowStyle(color: Color.black.opacity(0.15), radius: 15, y: 10)
    }

    /// Sketch blur values are diameters; SwiftUI `radius` is roughly half of that.
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }
}

// MARK: - Helpers

extension Color {
    /// Creates an opaque color from a 24-bit RGB hex value such as `0xFC6C01`.
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

extension View {
    /// Applies one of the Sketch shadow presets.
    func themeShadow(_ style: Theme.ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: 0, y: style.y)
    }
}
