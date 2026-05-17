import Foundation

extension Date {
    // MARK: - Japanese Date Formatting

    func toJapaneseDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日(E)"
        return formatter.string(from: self)
    }

    func toJapaneseTimeString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    func toJapaneseDateTimeString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E) HH:mm"
        return formatter.string(from: self)
    }

    func toShortJapaneseDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d(E)"
        return formatter.string(from: self)
    }

    func toRelativeString() -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(self, inSameDayAs: now) {
            return "今日"
        }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        if calendar.isDate(self, inSameDayAs: tomorrow) {
            return "明日"
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        if calendar.isDate(self, inSameDayAs: yesterday) {
            return "昨日"
        }

        let daysFromNow = calendar.dateComponents([.day], from: now, to: self).day ?? 0

        if daysFromNow > 0 && daysFromNow <= 7 {
            return "\(daysFromNow)日後"
        } else if daysFromNow < 0 && daysFromNow >= -7 {
            return "\(abs(daysFromNow))日前"
        }

        return toShortJapaneseDateString()
    }

    // MARK: - Age Calculation

    func age(at date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: self, to: date)
        return ageComponents.year ?? 0
    }

    // MARK: - Date Comparison

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    var isPast: Bool {
        self < Date()
    }

    var isFuture: Bool {
        self > Date()
    }

    // MARK: - Date Calculation

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        let startOfDay = self.startOfDay
        return Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfWeek: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }

    // MARK: - Weekday Helpers

    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }

    var isWeekend: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        return weekday == 1 || weekday == 7 // Sunday or Saturday
    }

    var isWeekday: Bool {
        !isWeekend
    }

    // MARK: - Time Formatting

    func timeUntilString() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: self)

        if let days = components.day, days > 0 {
            if days == 1 {
                return "明日"
            } else {
                return "\(days)日後"
            }
        }

        if let hours = components.hour, hours > 0 {
            return "\(hours)時間後"
        }

        if let minutes = components.minute, minutes > 0 {
            return "\(minutes)分後"
        }

        return "まもなく"
    }

    func timeSinceString() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: self, to: now)

        if let days = components.day, days > 0 {
            if days == 1 {
                return "昨日"
            } else {
                return "\(days)日前"
            }
        }

        if let hours = components.hour, hours > 0 {
            return "\(hours)時間前"
        }

        if let minutes = components.minute, minutes > 0 {
            return "\(minutes)分前"
        }

        return "今"
    }

    // MARK: - School Specific

    func schoolYear() -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: self)
        let month = calendar.component(.month, from: self)

        // School year starts in April in Japan
        return month >= 4 ? year : year - 1
    }

    func gradeFromBirthday() -> Grade? {
        let schoolYear = Date().schoolYear()
        let birthSchoolYear = self.schoolYear()
        let age = schoolYear - birthSchoolYear

        switch age {
        case 6: return .first
        case 7: return .second
        case 8: return .third
        case 9: return .fourth
        case 10: return .fifth
        case 11: return .sixth
        default: return nil
        }
    }
}