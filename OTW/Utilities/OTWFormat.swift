import Foundation

enum OTWFormat {
    private static var locale: Locale { Locale.autoupdatingCurrent }

    static func eyebrow(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).weekday(.wide).month(.wide).day()).uppercased(with: locale)
    }

    static func dayTitle(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).weekday(.wide).month(.wide).day())
    }

    static func fullDate(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).weekday(.wide).month(.wide).day().year())
    }

    static func monthTitle(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).month(.wide).year())
    }

    static func weekday(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).weekday(.abbreviated))
    }

    static func dayNumber(_ date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }

    static func time(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    static func longDate(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).month(.abbreviated).day().year())
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).month(.abbreviated).day())
    }
}
