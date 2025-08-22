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

    var orderedDays: [Any] {
        return days!.allObjects.sorted { day1, day2 in
            guard
                let date1 = (day1 as AnyObject).value(forKeyPath: "date") as? Date,
                let date2 = (day2 as AnyObject).value(forKeyPath: "date") as? Date
            else {
                return false
            }
            return date1 < date2
        }
    }
    
    func orderedNoVacDays() -> [Any] {
        // Retrieve the "days" attribute as an NSArray
        var arrDays  = (days ?? NSSet()).allObjects as NSArray
        //Filter all not vacation days (It meas dispay type normal)
        arrDays = arrDays.filtered(using: NSPredicate(format: "displayType == 0")) as NSArray
        // Sort the days array using a custom comparator
        let orderedDays = arrDays.sortedArray(options: [], usingComparator: {(_ day1: Any, _ day2: Any) -> ComparisonResult in
            // Extract the "date" attribute from each day object
            let value1 : NSDate = (day1 as AnyObject).value(forKey: "date") as! NSDate
            let value2 : NSDate = (day2 as AnyObject).value(forKey: "date")  as! NSDate
            let result: ComparisonResult? = value1.compare(value2 as Date)
            return result!
        })
        return orderedDays
    }

}
