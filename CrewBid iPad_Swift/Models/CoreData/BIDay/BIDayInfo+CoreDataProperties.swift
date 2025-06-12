//
//  BIDayInfo+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension BIDayInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BIDayInfo> {
        return NSFetchRequest<BIDayInfo>(entityName: "DayInfo")
    }

    @NSManaged public var blockMinutes: NSNumber?
    @NSManaged public var city: String?
    @NSManaged public var dayPayWithRig: NSNumber?
    @NSManaged public var departTimeFirstLeg: NSNumber?
    @NSManaged public var dutyMinutes: NSNumber?
    @NSManaged public var isHolidayPaycalculated: NSNumber?
    @NSManaged public var isOvernightBulkRed: String?
    @NSManaged public var pay: NSNumber?
    @NSManaged public var releaseTime: NSNumber?
    @NSManaged public var reportTime: NSNumber?
    @NSManaged public var days: NSSet?
    @NSManaged public var firstLeg: BILegInfo?
    @NSManaged public var legs: NSSet?
    @NSManaged public var nextDay: BIDayInfo?
    @NSManaged public var previousDay: BIDayInfo?
    @NSManaged public var trip: BITripInfo?
    @NSManaged public var tripFirstDay: BITripInfo?

}

// MARK: Generated accessors for days
extension BIDayInfo {

    @objc(addDaysObject:)
    @NSManaged public func addToDays(_ value: BIDay)

    @objc(removeDaysObject:)
    @NSManaged public func removeFromDays(_ value: BIDay)

    @objc(addDays:)
    @NSManaged public func addToDays(_ values: NSSet)

    @objc(removeDays:)
    @NSManaged public func removeFromDays(_ values: NSSet)

}

// MARK: Generated accessors for legs
extension BIDayInfo {

    @objc(addLegsObject:)
    @NSManaged public func addToLegs(_ value: BILegInfo)

    @objc(removeLegsObject:)
    @NSManaged public func removeFromLegs(_ value: BILegInfo)

    @objc(addLegs:)
    @NSManaged public func addToLegs(_ values: NSSet)

    @objc(removeLegs:)
    @NSManaged public func removeFromLegs(_ values: NSSet)

}

extension BIDayInfo : Identifiable {
    var orderedLegs: [Any] {
        let allLegs = self.legs?.allObjects ?? []
        let orderedLegs = allLegs.sorted {
            guard
                let minutes1 = ($0 as AnyObject).value(forKey: "departMinutes") as? Int,
                let minutes2 = ($1 as AnyObject).value(forKey: "departMinutes") as? Int
            else {
                return false
            }
            return minutes1 < minutes2
        }
        return orderedLegs
    }
    
    var dayPay: CGFloat {
        return orderedLegs.reduce(0) { total, legInfo in
            total + CGFloat((legInfo as! BILegInfo).pay?.floatValue ?? 0)
        }
    }
}
