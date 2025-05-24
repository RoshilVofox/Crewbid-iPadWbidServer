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
}
