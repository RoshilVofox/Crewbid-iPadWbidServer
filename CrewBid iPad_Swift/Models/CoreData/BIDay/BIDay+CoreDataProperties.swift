//
//  BIDay+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension BIDay {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BIDay> {
        return NSFetchRequest<BIDay>(entityName: "Day")
    }

    @NSManaged public var date: Date?
    @NSManaged public var displayType: NSNumber?
    @NSManaged public var holidayPayment: NSNumber?
    @NSManaged public var info: BIDayInfo?
    @NSManaged public var legs: NSSet?
    @NSManaged public var line: BILine?
    @NSManaged public var trip: BITrip?
    @NSManaged public var workBlock: WorkBlockList?

}

@objc enum BIDayDisplayType: Int {
    case normal
    case fullPay     // ＄
    case partialPay  // ￠
    case noPay       // X
    case inValid     // X
}


// MARK: Generated accessors for legs
extension BIDay {

    @objc(addLegsObject:)
    @NSManaged public func addToLegs(_ value: BILeg)

    @objc(removeLegsObject:)
    @NSManaged public func removeFromLegs(_ value: BILeg)

    @objc(addLegs:)
    @NSManaged public func addToLegs(_ values: NSSet)

    @objc(removeLegs:)
    @NSManaged public func removeFromLegs(_ values: NSSet)

}

extension BIDay : Identifiable {

}
