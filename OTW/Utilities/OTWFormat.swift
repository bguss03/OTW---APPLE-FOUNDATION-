import Foundation

/// Date formatting for the OTW screens. Day, weekday and month texts follow the device locale;
/// clock times are always 24-hour and zero padded, as in the Sketch frames.
enum OTWFormat {
    private static var locale: Locale { Locale.autoupdatingCurrent }

    /// "SUNDAY, MAY 3"
    static func eyebrow(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).weekday(.wide).month(.wide).day()).uppercased(with: locale)
    }

    /// "Sunday, May 3"
    static func dayTitle(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).weekday(.wide).month(.wide).day())
    }

    /// "Sunday, May 3, 2026"
    static func fullDate(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).weekday(.wide).month(.wide).day().year())
    }

    /// "May 2026"
    static func monthTitle(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).month(.wide).year())
    }

    /// "Sun" (or "Min" on an Indonesian device)
    static func weekday(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).weekday(.abbreviated))
    }

    /// "3"
    static func dayNumber(_ date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }

    /// "09:00" (always 24-hour, zero padded)
    static func time(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    /// "May 3, 2026"
    static func longDate(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).month(.abbreviated).day().year())
    }

    /// "May 7"
    static func shortDate(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).month(.abbreviated).day())
    }
}
