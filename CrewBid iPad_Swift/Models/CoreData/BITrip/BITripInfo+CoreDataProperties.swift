//
//  BITripInfo+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData

enum BIAMPMTripType:Int{
    case AMTrip = 1
    case PMTrip
}
extension BITripInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BITripInfo> {
        return NSFetchRequest<BITripInfo>(entityName: "TripInfo")
    }

    @NSManaged public var aircraftType800Count: NSNumber?
    @NSManaged public var amPM: NSNumber?
    @NSManaged public var blockMinutes: NSNumber?
    @NSManaged public var briefMinutes: NSNumber?
    @NSManaged public var calendarDaysCount: NSNumber?
    @NSManaged public var commutesRequired: NSNumber?
    @NSManaged public var containsMidTripPTB: NSNumber?
    @NSManaged public var debriefMinutes: NSNumber?
    @NSManaged public var departTime: NSNumber?
    @NSManaged public var dutyMinutes: NSNumber?
    @NSManaged public var dutyPeriodsCount: NSNumber?
    @NSManaged public var earliestDepartureTime: NSNumber?
    @NSManaged public var faPay: NSNumber?
    @NSManaged public var isETOPS: NSNumber?
    @NSManaged public var isFullyCommutable: NSNumber?
    @NSManaged public var jsonPay: NSNumber?
    @NSManaged public var latestArrivalTimes: NSNumber?
    @NSManaged public var maxLegsInADay: NSNumber?
    @NSManaged public var numAircraftChanges: NSNumber?
    @NSManaged public var number: String?
    @NSManaged public var numLegs: NSNumber?
    @NSManaged public var overnightsInBase: NSNumber?
    @NSManaged public var partialTrip: NSNumber?
    @NSManaged public var passesThruBase: NSNumber?
    @NSManaged public var returnTime: NSNumber?
    @NSManaged public var tafbJson: NSNumber?
    @NSManaged public var days: NSSet?
    @NSManaged public var firstDay: BIDayInfo?
    @NSManaged public var trips: NSSet?

}

// MARK: Generated accessors for days
extension BITripInfo {

    @objc(addDaysObject:)
    @NSManaged public func addToDays(_ value: BIDayInfo)

    @objc(removeDaysObject:)
    @NSManaged public func removeFromDays(_ value: BIDayInfo)

    @objc(addDays:)
    @NSManaged public func addToDays(_ values: NSSet)

    @objc(removeDays:)
    @NSManaged public func removeFromDays(_ values: NSSet)

}

// MARK: Generated accessors for trips
extension BITripInfo {

    @objc(addTripsObject:)
    @NSManaged public func addToTrips(_ value: BITrip)

    @objc(removeTripsObject:)
    @NSManaged public func removeFromTrips(_ value: BITrip)

    @objc(addTrips:)
    @NSManaged public func addToTrips(_ values: NSSet)

    @objc(removeTrips:)
    @NSManaged public func removeFromTrips(_ values: NSSet)

}

extension BITripInfo : Identifiable {
    var orderedDays: [Any] {
        return (days!.allObjects as NSArray).sortedArray(comparator: { day1, day2 in
            let value1 = (day1 as AnyObject).value(forKeyPath: "firstLeg.departMinutes") as? NSNumber
            let value2 = (day2 as AnyObject).value(forKeyPath: "firstLeg.departMinutes") as? NSNumber
            return value1?.compare(value2 ?? 0) ?? .orderedSame
        })
    }
    var isPilotReserve: Bool {
        guard number!.count > 1 else { return false }
        let index = number!.index(number!.startIndex, offsetBy: 1)
        return number![index] >= "W"
    }
    
    var tafbMinutes: NSNumber? {
        guard
            let lastDay = self.orderedDays.last as? BIDayInfo,
            let lastLeg = lastDay.orderedLegs.last as? BILegInfo,
            let firstLeg = firstDay?.firstLeg
        else {
            return nil
        }
        let tafb = lastLeg.arriveMinutes!.intValue - firstLeg.departMinutes!.intValue + briefMinutes!.intValue + debriefMinutes!.intValue
        return NSNumber(value: tafb)
    }
}
