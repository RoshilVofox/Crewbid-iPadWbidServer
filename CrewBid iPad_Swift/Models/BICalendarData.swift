//
//  BICalendarData.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/03/25.
//
import Foundation
import CoreData


import Foundation
import CoreData

class BICalendarDay: NSObject {
    var text: String = String()
    var dayOfWeekAbbreviation: String = String()
    var isCurrentMonth = false
    var isPreviousMonth = false
    var isNextMonth = false
    var isWeekend = false
}
class BICalendarData {
    
    var bidPeriod: BIBidPeriod?
    var year = 0
    var month = 0
    var calendar: Calendar?
    var dateComponents: DateComponents?
    var calendarDaysExpandedBidListView: NSArray = NSArray()
    var firstDateOfMonth: Date?
    var firstDateOfCalendar: Date?
    var daysInMonth = 0
    var weeksInMonth = 0
    var calendarDays : NSArray = NSArray()
    
    static func initWithManagedObjectContext(_ context: NSManagedObjectContext) -> BICalendarData? {
        // Fetch request for BIBidPeriod
        let fetchRequest = NSFetchRequest<BIBidPeriod>(entityName: "BidPeriod")
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if results.isEmpty {
                print("No bid period found")
                return nil
            } else if results.count > 1 {
                print("Too many (\(results.count)) bid period objects found")
                return nil
            }
            let bidPeriod = results[0]
            
            // Call your initializer-style function here
            return BICalendarData().initWithBidPeriod(bidPeriod: bidPeriod)
            
        } catch {
            print("Bid period fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getNextMonth() -> Int {
        let calendar = Calendar.current
        let currentDate = Date()
        // Add one month to the current date
        if let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            // Extract the month component from the new date
            let nextMonth = calendar.component(.month, from: nextMonthDate)
            return nextMonth
        }
        return 1
    }
    
    // Initialize BICalendarData with a given BIBidPeriod

    func initWithBidPeriod(bidPeriod: BIBidPeriod) -> BICalendarData? {
        self.bidPeriod = bidPeriod
        let month = bidPeriod.month?.intValue ?? getNextMonth()
        if !NSLocationInRange(month, NSRange(location: 1, length: 12)) {
            print("Bid period month (%zu) out of range", UInt(month))
            return nil
        }
        let year = Int(truncating: bidPeriod.year!)
        if !NSLocationInRange(year, NSRange(location: 2013, length: 2099)) {
            print("Bid period month (%zu) out of range", UInt(year))
            return nil
        }
        return  initWithYear(year: year, month: month)
    }
    
    // Initialize BICalendarData with a specific year and month

    func initWithYear(year: Int, month: Int) -> BICalendarData {
        self.year = year
        self.month = month
        calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        calendar?.locale = Locale(identifier: "en_US")
        calendar?.timeZone = TimeZone(identifier: "US/Central")!
        var dc: DateComponents = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = 1
        dc.hour = 12
        dateComponents = dc
        firstDateOfMonth = calendar?.date(from: dc)
        let daysInMonthRange = calendar?.range(of: .day, in: .month, for: firstDateOfMonth!)
        let numDays = daysInMonthRange?.count
        self.daysInMonth = numDays!
        let weeksInMonthRange = calendar?.range(of: .weekOfMonth, in: .month, for: firstDateOfMonth!)
        let numMonths = weeksInMonthRange?.count
        self.weeksInMonth = numMonths!
        let firstDayOfWeekComponents = calendar?.dateComponents([.weekday], from: firstDateOfMonth!)
        let firstDayWeekday = firstDayOfWeekComponents?.weekday
        dc.day = -firstDayWeekday! + 2
        self.firstDateOfCalendar = calendar?.date(from: dc)
        
            // Ensure that third day of following month is included in calendar so
            // that four-day trips will be displayed.
        if (month == 2) {
            dc.day = self.daysInMonth + 6
        }else {
            dc.day = self.daysInMonth + 4
        }
        let requiredLastDate = calendar?.date(from: dc)
        let daysInCalendar = weeksInMonth * 7
        let requiredDaysInCalendar = (calendar?.dateComponents([.day], from: firstDateOfCalendar!, to: requiredLastDate!))
        let requireDaysInCalendar = requiredDaysInCalendar?.day
        if requireDaysInCalendar! > daysInCalendar {
            self.weeksInMonth += 1
        }
        
        if month == 2 && (firstDateOfCalendar?.compare(firstDateOfMonth!) == .orderedSame) {
                // If the month is February and January 31 is not showing, we need to
                // change the first date of the calendar to make sure that it is showing
                // so that FA trips show up properly.
                // This scenario would only happen if February 1 is a Sunday
            dc.month = 1
            dc.day = 25
            self.firstDateOfCalendar = calendar?.date(from: dc)
            self.weeksInMonth += 1
        }else {
            dc.day = -firstDayWeekday! + 2
        }
        
        let AWeek = NSMutableArray()
        let BWeek = NSMutableArray()
        let CWeek = NSMutableArray()
        let DWeek = NSMutableArray()
        let EWeek = NSMutableArray()
        let FWeek = NSMutableArray()
        let calendarDays = NSMutableArray(capacity: 7 * self.weeksInMonth)
        
        for week in 0..<weeksInMonth {
            for _ in 0..<7 {
                let date = calendar?.date(from: dc)
                let dayComps = calendar?.dateComponents([.month, .day, .weekday, .year], from: date!)
                let calDay = BICalendarDay()
                calDay.text = "\(dayComps?.day ?? 0)"
                let dayDateText = String(format: "%02ld/%02ld/%zd", dayComps!.day!, dayComps!.month!, dayComps!.year!)
                if week == 0 {
                    AWeek.add(dayDateText)
                }else if week == 1 {
                    BWeek.add(dayDateText)
                } else if week == 2 {
                    CWeek.add(dayDateText)
                } else if week == 3 {
                    DWeek.add(dayDateText)
                } else if week == 4 {
                    EWeek.add(dayDateText)
                } else if week == 5 {
                    FWeek.add(dayDateText)
                }
                calDay.isCurrentMonth = (self.month == dayComps?.month)
                if ((dayComps?.month)! < self.month ) {
                    calDay.isPreviousMonth = true
                }
                if ((dayComps?.month)! > self.month) {
                    calDay.isNextMonth = true
                }
                if (dayComps?.month == 12 && self.month == 1) {
                    calDay.isPreviousMonth = true
                    calDay.isNextMonth = false
                }
                if (dayComps?.month == 1 && self.month == 12) {
                    calDay.isPreviousMonth = false
                    calDay.isNextMonth = true
                }
               
                switch (dayComps?.weekday) {
                    case 1:
                        calDay.dayOfWeekAbbreviation = "Su"
                        calDay.isWeekend = true
                        break;
                    case 2:
                        calDay.dayOfWeekAbbreviation = "Mo"
                        calDay.isWeekend = false
                        break;
                    case 3:
                        calDay.dayOfWeekAbbreviation = "Tu"
                        calDay.isWeekend = false
                        break;
                    case 4:
                        calDay.dayOfWeekAbbreviation = "We"
                        calDay.isWeekend = false
                        break;
                    case 5:
                        calDay.dayOfWeekAbbreviation = "Th"
                        calDay.isWeekend = false
                        break;
                    case 6:
                        calDay.dayOfWeekAbbreviation = "Fr"
                        calDay.isWeekend = false
                        break;
                    case 7:
                        calDay.dayOfWeekAbbreviation = "Sa"
                        calDay.isWeekend = true
                        break;
                    default:
                        break;
                }
                calendarDays.add(calDay)
                dc.day! += 1
            }
        }
        
        if AWeek.count > 0 {
            self.bidPeriod?.aWeekDays = AWeek.componentsJoined(by: ",")
        }
        if (BWeek.count > 0) {
            self.bidPeriod?.bWeekDays = BWeek.componentsJoined(by: ",")
        }
        if (CWeek.count > 0) {
            self.bidPeriod?.cWeekDays = CWeek.componentsJoined(by: ",")
        }
        if (DWeek.count > 0) {
            self.bidPeriod?.dWeekDays = DWeek.componentsJoined(by: ",")
        }
        if (EWeek.count > 0) {
            self.bidPeriod?.eWeekDays = EWeek.componentsJoined(by: ",")
        }
        if (FWeek.count > 0) {
            self.bidPeriod?.fWeekDays = FWeek.componentsJoined(by: ",")
        }
        self.calendarDays = calendarDays
        
        if (month == 2){
            dateComponents?.month = 2
        }
        return self
    }
    
    // Expand calendar days for bid lines view

    func calendarDaysExpandedBidLinesView() -> NSArray {
        var startingIndex = indexForDate(date: self.firstDateOfMonth)
        if (self.month == 2 && startingIndex > 0) {
            // Account for february
            startingIndex -= 1
        }
        // Find ending index, 3rd of the next month
        var dc: DateComponents = DateComponents()
        dc.month = 1
        dc.day = 2
        var thirdOfNextMonth: Date?
        thirdOfNextMonth = calendar?.date(byAdding: dc, to: firstDateOfMonth!)
        var endingIndex = indexForDate(date: thirdOfNextMonth)
        if (startingIndex < 0) {
            startingIndex = 0
        }
        
        if (endingIndex > self.calendarDays.count - 1) {
            endingIndex = self.calendarDays.count - 1
        }
        
        let arrayRange = NSRange(location: startingIndex, length: endingIndex - startingIndex + 1)
        calendarDaysExpandedBidListView = (calendarDays.subarray(with: arrayRange) as NSArray)
        return calendarDaysExpandedBidListView
    }
    // Calculate the index for a given date

    func indexForDate(date: Date?) -> Int {
        let from = calendar?.startOfDay(for: firstDateOfCalendar!)
        let to = calendar?.startOfDay(for: date!)
        let dateComponents = (calendar?.dateComponents([.day], from: from!, to: to!))
        return (dateComponents?.day)!
    }
    // Calculate the index of the first day in the expanded view

    func indexForDateGMT(date: Date) -> Int {
        var myNewCalendar = calendar
        myNewCalendar = Calendar(identifier: Calendar.Identifier.gregorian)
        //myNewCalendar?.locale = Locale(identifier: "en_US")
        myNewCalendar?.timeZone = TimeZone(secondsFromGMT: 0)!
        var dc: DateComponents = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = 1
        dc.hour = 0
        //dateComponents = dc
        firstDateOfMonth = myNewCalendar?.date(from: dc)
        let daysInMonthRange = myNewCalendar?.range(of: .day, in: .month, for: firstDateOfMonth!)
        let numDays = daysInMonthRange?.count
        self.daysInMonth = numDays!
        let weeksInMonthRange = myNewCalendar?.range(of: .weekOfMonth, in: .month, for: firstDateOfMonth!)
        let numMonths = weeksInMonthRange?.count
        self.weeksInMonth = numMonths!
        let firstDayOfWeekComponents = myNewCalendar?.dateComponents([.weekday], from: firstDateOfMonth!)
        let firstDayWeekday = firstDayOfWeekComponents?.weekday
        dc.day = -firstDayWeekday! + 2
        let firstDateOfCalendar = myNewCalendar?.date(from: dc)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let timeStamp = dateFormatter.string(from: date)
        guard let gmtDate = dateFormatter.date(from: timeStamp) else { return 0 }

        let firstDateString = dateFormatter.string(from: firstDateOfCalendar!)
        guard let firstDate = dateFormatter.date(from: firstDateString) else { return 0 }

        let dateComponentsFinal = myNewCalendar!.dateComponents([.day], from: firstDate, to: gmtDate)
        return dateComponentsFinal.day ?? 0
    }
    
    func indexOfFirstDayExpandedView() -> Int {
            // Find starting index
        var startingIndex = indexForDate(date: firstDateOfMonth)
        if month == 2 && startingIndex > 0 {
                // Account for february
            startingIndex -= 1
        }
        return startingIndex
    }
    
    // Calculate the number of days for the expanded bid lines view

    func numDaysForExpandedBidLinesView() -> Int {
        var numDays = daysInMonth + 4 // Account for trips extending beyond month
        if month == 2 {
                // Added Jan 31 for February
            numDays += 1
        }
        return numDays
    }
    
    // Get the weekday abbreviation (e.g., "Su" for Sunday) for a given date

    func weekdayAbbreviationForDate(for date: Date?) -> String? {
        var dc: DateComponents? = nil
        dc = calendar?.dateComponents([.weekday], from: date!)
        switch dc?.weekday {
            case 1:return "Su"
            case 2:return "Mo"
            case 3:return "Tu"
            case 4:return "We"
            case 5:return "Th"
            case 6:return "Fr"
            case 7:return "Sa"
            default:return nil
        }
    }
    
    // Calculate the index path for a given date

    func indexPathForDate(date: Date?) -> IndexPath? {
        let indexPath = IndexPath(row: indexForDate(date: date), section: 0)
        return indexPath
    }
    
    // Calculate the index for a given date in the expanded view

    func expandedViewIndexForDate(date: Date?) -> Int {
        let dateComponents = calendar?.dateComponents([.day], from: firstDateOfCalendar!, to: date!)
        var index = dateComponents?.day
        index! -= indexOfFirstDayExpandedView()
        return index!
    }
    
    // Convert a date to a standardized format (setting hour to 12:00 PM)

    func dateForDate(date: Date?) -> Date? {
        var comps: DateComponents? = nil
        comps = Calendar.current.dateComponents([.day,.month,.year], from: date!)
        let day = comps?.day ?? 0
        let month = comps?.month ?? 0
        comps?.day = day
        comps?.month = month
        comps?.hour = 12
        //let returnDate = calendar?.date(from: comps!) // Updated by raja on 13 Feb 2024 - To fix the date conversion issue
        let returnDate = Calendar(identifier: .gregorian).date(from: comps!)
        return returnDate
    }
    
    // Create a date for a specific day of the month

    func dateForDayOfMonth(dayOfMonth: Int) -> Date? {
        dateComponents?.day = dayOfMonth
        let dateForDayOfMonth = calendar?.date(from: dateComponents!)
        return dateForDayOfMonth
    }
    
    func dateForDayOfMonthJanuary31(dayOfMonth: Int) -> Date? {
        dateComponents?.day = dayOfMonth
        dateComponents?.month = 1
        let dateForDayOfMonth = calendar?.date(from: dateComponents!)
        dateComponents?.month = 2
        return dateForDayOfMonth
    }
    
    func dateForDayOfMonthMarch1(dayOfMonth: Int) -> Date? {
        dateComponents?.day = dayOfMonth
        dateComponents?.month = 3
        let dateForDayOfMonth = calendar?.date(from: dateComponents!)
        dateComponents?.month = 2
        return dateForDayOfMonth
    }

    // Get the date for a specific index in the calendar

    func dateForIndex(index: Int) -> Date? {
        var day = BICalendarDay()
        day = self.calendarDays[index] as! BICalendarDay
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = Int(day.text)
        dateComponents.hour = 12
        
        if (!day.isCurrentMonth && Int(day.text) ?? 0 < 20) {
            dateComponents.month! += 1
        } else if (!day.isCurrentMonth && Int(day.text) ?? 0  > 19) {
            dateComponents.month! -= 1
        }
        let date = calendar?.date(from: dateComponents)
        return date
    }
    
    // Calculate the number of days between two dates

    func daysBetweenDate(fromDateTime: Date,toDateTime: Date) -> Int {
        let calendar = Calendar.current
        let fromDate : Date?
        fromDate = calendar.startOfDay(for:fromDateTime)
        let toDate : Date?
        toDate = calendar.startOfDay(for: toDateTime)
        let difference = calendar.dateComponents( [.day],from: fromDate!,to: toDate!)
        return (difference.day) ?? 0
    }
    
    // Calculate the number of days between two dates, inclusive

    func noOfDaysBetweenDates(startDate: Date?,endDate: Date?) -> Int {
        let calendar = Calendar.current
        var dateComponent: DateComponents? = nil
        if let startDate = startDate, let endDate = endDate {
            dateComponent = calendar.dateComponents([.day], from: startDate, to: endDate)
        }
        let totalDays = Int(dateComponent?.day ?? 0)
        return totalDays
        
    }
    
    // Check if a date falls within a specified range

    func date(date: Date?,beginDate: Date?,endDate: Date?) -> Bool {
        if date?.compare(beginDate!) == .orderedAscending {
            return false
        }
        if date?.compare(endDate!) == .orderedDescending {
            return false
        }
        return true
    }
    
    // Check if a date is within the bid month

    func dateIsInBidMonth(date: Date?) -> Bool {
        let numDaysInBidMonth = CBUtils.numberOfDays(inMonth: month, forYear: year)
        var startDc: DateComponents?
        startDc = calendar?.dateComponents( [.month,.year,.day],from: firstDateOfMonth!)
        startDc?.hour = 0
        startDc?.minute = 0
        startDc?.timeZone = TimeZone(identifier: "US/Central")!
        startDc?.second = 0
        let startDate = calendar?.date(from: startDc!)
            // Add the number of days in the bid month to get the end date
        var dc = DateComponents()
        dc.day = numDaysInBidMonth - 1
        var endDate: Date?
        endDate = calendar?.date(byAdding: dc, to: firstDateOfMonth!)
        var endDc: DateComponents?
        endDc = (calendar?.dateComponents([.day,.year,.month], from: endDate!))
        endDc?.hour = 23
        endDc?.minute = 59
        endDc?.second = 59
        endDc?.timeZone = TimeZone(identifier: "US/Central")!
        endDate = calendar?.date(from: endDc!)
        return self.date(date: date, beginDate: startDate, endDate: endDate)
    }
    // Check if a given date is before the first date of the bid month

    func dateIsBeforeFirstDateOfBidMonth(date: Date?) -> Bool {
        if (date?.compare(firstDateOfMonth!) == .orderedDescending) || ((date?.compare(firstDateOfMonth!)) != nil) {
            return false
        } else {
            return true
        }
    }
    
    func daysBetweenDateForWorkBlock(from fromDateTime: Date, to toDateTime: Date) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        guard let fromDateStr = dateFormatter.string(from: fromDateTime) as String?,
              let toDateStr = dateFormatter.string(from: toDateTime) as String?,
              let startDate = dateFormatter.date(from: fromDateStr),
              let endDate = dateFormatter.date(from: toDateStr) else {
            return 0
        }

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }
    
    
    
    
//MARK: - Coding Protocol
private let kMonthKey = "month"
private let kYearKey = "year"
// Encode the month and year properties for archiving

func encodeWithCoder(coder: NSCoder) {
    coder.encode(month, forKey: kMonthKey)
    coder.encode(year, forKey: kYearKey)
}
// Initialize a BICalendarData object using the provided decoder

func initWithCoder(decoder: NSCoder) -> BICalendarData {
    let month = decoder.decodeInteger(forKey: kMonthKey)
    let year = decoder.decodeInteger(forKey: kYearKey)
    return initWithYear(year: year, month: month)
}
// Return the Calendar used for the bid period

func bidPeriodCalendar() -> Calendar? {
    return calendar
}
// Return the NSTimeZone representing the timezone for the bid period

func bidPeriodTimezone() -> TimeZone? {
    return TimeZone(identifier: "US/Central")!
}
// Return a Calendar object for the bid period

class func bidPeriodCalendar() -> Calendar? {
    var bidPeriodCalendar = Calendar(identifier: Calendar.Identifier.gregorian)
    bidPeriodCalendar.locale = Locale(identifier: "en_US") as Locale
    if let timeZone = TimeZone(identifier: "US/Central") {
        bidPeriodCalendar.timeZone = timeZone as TimeZone
        }
    return bidPeriodCalendar
    }
    
    func monthNumber(from month: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Ensures consistent parsing
        if let date = formatter.date(from: month.capitalized) {
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }
        return nil
    }

}
