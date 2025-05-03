//
//  BILegInfo+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension BILegInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BILegInfo> {
        return NSFetchRequest<BILegInfo>(entityName: "LegInfo")
    }

    @NSManaged public var arriveCity: String?
    @NSManaged public var arriveMinutes: NSNumber?
    @NSManaged public var departCity: String?
    @NSManaged public var departMinutes: NSNumber?
    @NSManaged public var equipment: String?
    @NSManaged public var firstLegOfTrip: NSNumber?
    @NSManaged public var flight: String?
    @NSManaged public var isAircraftChange: NSNumber?
    @NSManaged public var isDeadhead: NSNumber?
    @NSManaged public var isDutyBreak: NSNumber?
    @NSManaged public var isEtopsFlight: NSNumber?
    @NSManaged public var isRedEyeFlight: NSNumber?
    @NSManaged public var lastLegOfTrip: NSNumber?
    @NSManaged public var pay: NSNumber?
    @NSManaged public var day: BIDayInfo?
    @NSManaged public var dayFirstLeg: BIDayInfo?
    @NSManaged public var legs: NSSet?
    @NSManaged public var nextLeg: BILegInfo?
    @NSManaged public var previousLeg: BILegInfo?

}

// MARK: Generated accessors for legs
extension BILegInfo {

    @objc(addLegsObject:)
    @NSManaged public func addToLegs(_ value: BILeg)

    @objc(removeLegsObject:)
    @NSManaged public func removeFromLegs(_ value: BILeg)

    @objc(addLegs:)
    @NSManaged public func addToLegs(_ values: NSSet)

    @objc(removeLegs:)
    @NSManaged public func removeFromLegs(_ values: NSSet)

}

extension BILegInfo : Identifiable {

}
