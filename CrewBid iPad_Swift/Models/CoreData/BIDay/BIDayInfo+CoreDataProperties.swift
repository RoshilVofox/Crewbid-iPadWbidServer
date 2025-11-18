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
    @NSManaged public var dutyPeriodNumber: NSNumber?
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
//    var orderedLegs: [Any] {
//        let allLegs = self.legs?.allObjects ?? []
//        let orderedLegs = allLegs.sorted {
//            guard
//                let minutes1 = ($0 as AnyObject).value(forKey: "departMinutes") as? Int,
//                let minutes2 = ($1 as AnyObject).value(forKey: "departMinutes") as? Int
//            else {
//                return false
//            }
//            return minutes1 < minutes2
//        }
//        return orderedLegs
//    }
    
    var orderedLegs: [BILegInfo] {
        guard let legSet = legs as? Set<BILegInfo> else { return [] }
        
        return legSet.sorted {
            let minutes1 = $0.departMinutes as? Int ?? 0
            let minutes2 = $1.departMinutes as? Int ?? 0
            return minutes1 < minutes2
        }
    }
    
    var dayPay: CGFloat {
        var total: CGFloat = 0.0
        for legInfo in orderedLegs {
            if let pay = legInfo.pay {
                total += CGFloat(truncating: pay)
            }
        }
        return total
    }
}
