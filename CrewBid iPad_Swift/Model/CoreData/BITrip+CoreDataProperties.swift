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

}
