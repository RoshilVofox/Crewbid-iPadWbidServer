//
//  BITrip+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData



extension BITrip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BITrip> {
        return NSFetchRequest<BITrip>(entityName: "Trip")
    }

    @NSManaged public var bidListHighlighted: NSNumber?
    @NSManaged public var dropForFiltersSorts: NSNumber?
    @NSManaged public var endDate: Date?
    @NSManaged public var endDateOnly: Date?
    @NSManaged public var endWeekday: NSNumber?
    @NSManaged public var highlightCount: NSNumber?
    @NSManaged public var isReserveFa: NSNumber?
    @NSManaged public var number: String?
    @NSManaged public var position: NSNumber?
    @NSManaged public var positionString: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var startDay: NSNumber?
    @NSManaged public var startWeekday: NSNumber?
    @NSManaged public var tripEndDay: String?
    @NSManaged public var tripStartDay: String?
    @NSManaged public var vacationOverlapType: NSNumber?
    @NSManaged public var vBackVoPay: NSNumber?
    @NSManaged public var vFrontVoPay: NSNumber?
    @NSManaged public var days: NSSet?
    @NSManaged public var info: BITripInfo?
    @NSManaged public var legs: NSSet?
    @NSManaged public var line: BILine?
    @NSManaged public var lineFirstTrip: BILine?
    @NSManaged public var nextTrip: BITrip?
    @NSManaged public var previousTrip: BITrip?

}

// MARK: Generated accessors for days
extension BITrip {

    @objc(addDaysObject:)
    @NSManaged public func addToDays(_ value: BIDay)

    @objc(removeDaysObject:)
    @NSManaged public func removeFromDays(_ value: BIDay)

    @objc(addDays:)
    @NSManaged public func addToDays(_ values: NSSet)

    @objc(removeDays:)
    @NSManaged public func removeFromDays(_ values: NSSet)

}

enum BITripVacationOverlapType: Int {
    case none = 0
    case front
    case back
    case full
}


// MARK: Generated accessors for legs
extension BITrip {

    @objc(addLegsObject:)
    @NSManaged public func addToLegs(_ value: BILeg)

    @objc(removeLegsObject:)
    @NSManaged public func removeFromLegs(_ value: BILeg)

    @objc(addLegs:)
    @NSManaged public func addToLegs(_ values: NSSet)

    @objc(removeLegs:)
    @NSManaged public func removeFromLegs(_ values: NSSet)

}

extension BITrip : Identifiable {
    static func staticTimeForReserveType(trip: BITrip, line: BILine, key: String, timeZone: String) -> String? {
        guard let bidPeriod = line.bidPeriod else { return nil }
        if bidPeriod.isFirstRoundBid() || !bidPeriod.isFABid() || !trip.isReserve {
            return nil}
        let type = trip.line?.faReserveLineType?.intValue
        var timeStr: String?
        switch type {
        case BIFaReserveLineType.SnrAMres.rawValue:
            timeStr = (key == "depart") ? "0300" : "1100"
        case BIFaReserveLineType.SnrPMres.rawValue:
            timeStr = (key == "depart") ? "1000" : "1800"
        case BIFaReserveLineType.JnrAMres.rawValue:
            timeStr = (key == "depart") ? "0300" : "1500"
        case BIFaReserveLineType.JnrPMres.rawValue:
            timeStr = (key == "depart") ? "1000" : "2200"
        case BIFaReserveLineType.JnrLateRes.rawValue:
            timeStr = (key == "depart") ? "1500" : "0259"
        default:
            break
        }
        guard let timeStrUnwrapped = timeStr else { return nil }
        let timeZoneSetting = UserDefaults.standard.integer(forKey: kCBTimeZoneSetting)
        if timeZoneSetting == CBTimeZoneSetting.localTime.rawValue {
            return timeStrUnwrapped
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HHmm"
        formatter.timeZone = TimeZone(identifier: timeZone)

        guard let localTime = formatter.date(from: timeStrUnwrapped) else {
            return nil
        }

        formatter.timeZone = TimeZone(identifier: "US/Central")
        return formatter.string(from: localTime)
    }
    
    var orderedDays: [BIDay] {
        let daysArray = (self.days as? Set<BIDay>) ?? []

        return daysArray.sorted { day1, day2 in
            let minDepart1 = day1.info?.legs?.compactMap { ($0 as? BILegInfo)?.departMinutes?.intValue }.min() ?? Int.max
            let minDepart2 = day2.info?.legs?.compactMap { ($0 as? BILegInfo)?.departMinutes?.intValue }.min() ?? Int.max
            return minDepart1 < minDepart2
        }
    }
    
    var redEyeCount: NSNumber {
        let myArray = legs?.allObjects
        let predicate = NSPredicate(format: "info.isRedEyeFlight == YES")
        let filteredArray = (myArray! as NSArray).filtered(using: predicate)
        return NSNumber(value: filteredArray.count)
    }


    
    var isRedEyeTrip: Bool {
        return redEyeCount.intValue > 0
    }


    
    var isReserve: Bool {
        if line?.bidPeriod?.isFABid() == true {
            return isReserveFa?.boolValue ?? false
        } else {
            if let number = info?.number, number.count > 1 {
                let index = number.index(number.startIndex, offsetBy: 1)
                return number[index] >= "W"
            }
            return false
        }
    }
}
