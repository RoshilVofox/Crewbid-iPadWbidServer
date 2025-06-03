//
//  BICalendarData.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/03/25.
//
import Foundation
import CoreData


class BICalendarData {
    var daysInMonth: Int = 0
//    var weeksInMonth: Int = 0
//    var year: Int
//    var month: Int
//    var calendar: Calendar
//    var bidPeriodTimezone: TimeZone
//    var firstDateOfMonth: Date
//    var firstDateOfCalendar: Date
//    
//    init(year: Int, month: Int, bidPeriodTimezone: TimeZone) {
//        self.year = year
//        self.month = month
//        self.bidPeriodTimezone = bidPeriodTimezone
//
//        var calendar = Calendar(identifier: .gregorian)
//        calendar.locale = Locale(identifier: "en_US")
//        calendar.timeZone = bidPeriodTimezone
//        self.calendar = calendar
//
//        var components = DateComponents()
//        components.year = year
//        components.month = month
//        components.day = 1
//        components.hour = 12
//        
//        self.firstDateOfMonth = calendar.date(from: components)!
//        let daysInMonthRange = calendar.range(of: .day, in: .month, for: firstDateOfMonth)!
//        self.daysInMonth = daysInMonthRange.count
//        let weeksInMonthRange = calendar.range(of: .weekOfMonth, in: .month, for: firstDateOfMonth)!
//        self.weeksInMonth = weeksInMonthRange.count
//        let firstDayOfWeekComponents = calendar.dateComponents([.weekday], from: firstDateOfMonth)
//        let firstDayWeekday = firstDayOfWeekComponents.weekday ?? 1
//        components.day = -firstDayWeekday + 2
//        self.firstDateOfCalendar = calendar.date(from: components)!
//        
//        if month == 12{
//            components.day = self.daysInMonth + 6
//        }else{
//            components.day = self.daysInMonth + 4
//        }
//        let requiredLastDate = calendar.date(from: components)!
//        let daysInCalendar =  7 * self.weeksInMonth
//        let requiredDaysInCalendar = calendar.dateComponents([.day], from: firstDateOfCalendar, to: requiredLastDate).day
//        if requiredDaysInCalendar! > daysInCalendar {
//            self.weeksInMonth += 1
//        }
//        
//        if month == 2 && self.firstDateOfCalendar.compare(self.firstDateOfMonth) == .orderedSame {
//            components.month = 1
//            components.day = 25
//            
//            self.firstDateOfCalendar = calendar.date(from: components)!
//            self.weeksInMonth += 1
//        }else{
//            components.day = -firstDayWeekday + 2
//        }
//        // needs code
//    }
    
    
    func date(for date: Date) -> Date? {
        let calendar = Calendar.current

        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        var comps = DateComponents()
        comps.day = day
        comps.month = month
        comps.year = year
        comps.hour = 12
        return calendar.date(from: comps)
    }
    
    func getDay(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    func daysBetweenDate(_ fromDateTime: Date, andDate toDateTime: Date) -> Int {
        var fromDate: Date = Date()
        var toDate: Date = Date()
        
        // Assuming _calendar is an instance of Calendar, e.g. Calendar.current
        let calendar = _calendar // or use Calendar.current if _calendar is not defined
        
        calendar.range(of: .day, start: &fromDate, interval: nil, for: fromDateTime)
        calendar.range(of: .day, start: &toDate, interval: nil, for: toDateTime)
        
        let difference = calendar.dateComponents([.day], from: fromDate, to: toDate)
        return difference.day ?? 0
    }

    
    func dateforDayOfMonth(_ dayOfMonth: Int) -> Date? {
        var dc = DateComponents()
        dc.year = GlobalBidInfo.shared.year
        dc.month = GlobalBidInfo.shared.month
        dc.day = dayOfMonth
        dc.hour = 12
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = TimeZone(identifier: "US/Central") ?? TimeZone(identifier: "America/Chicago")!
        let dateForDayOfMonth = calendar.date(from: dc)!
        return dateForDayOfMonth
    }
    
    func bidPeriodCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = TimeZone(identifier: "US/Central") ?? TimeZone.current
        return calendar
    }
    func bidPeriodTimezone() -> TimeZone? {
        return TimeZone(identifier: "US/Central")
    }

    
//    func index(for date: Date) -> Int {
//        let components = calendar.dateComponents([.day], from: firstDateOfCalendar, to: date)
//        return components.day ?? 0
//    }
}
