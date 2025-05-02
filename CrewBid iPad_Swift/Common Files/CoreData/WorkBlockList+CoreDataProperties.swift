//
//  WorkBlockList+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension WorkBlockList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkBlockList> {
        return NSFetchRequest<WorkBlockList>(entityName: "WorkBlockList")
    }

    @NSManaged public var backToBackCount: NSNumber?
    @NSManaged public var briefMinutes: NSNumber?
    @NSManaged public var deBriefMinutes: NSNumber?
    @NSManaged public var endDateOnly: Date?
    @NSManaged public var endDateTime: Date?
    @NSManaged public var endDay: String?
    @NSManaged public var nightINDomicile: NSNumber?
    @NSManaged public var startDateTakeOffTime: Date?
    @NSManaged public var startDateTime: Date?
    @NSManaged public var startDay: String?
    @NSManaged public var trips: NSObject?
    @NSManaged public var days: NSSet?
    @NSManaged public var line: BILine?

}

// MARK: Generated accessors for days
extension WorkBlockList {

    @objc(addDaysObject:)
    @NSManaged public func addToDays(_ value: BIDay)

    @objc(removeDaysObject:)
    @NSManaged public func removeFromDays(_ value: BIDay)

    @objc(addDays:)
    @NSManaged public func addToDays(_ values: NSSet)

    @objc(removeDays:)
    @NSManaged public func removeFromDays(_ values: NSSet)

}

extension WorkBlockList : Identifiable {

}
