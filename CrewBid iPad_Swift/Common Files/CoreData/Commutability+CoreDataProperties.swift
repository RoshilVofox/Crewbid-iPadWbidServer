//
//  Commutability+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension Commutability {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Commutability> {
        return NSFetchRequest<Commutability>(entityName: "Commutability")
    }

    @NSManaged public var baseTime: NSNumber?
    @NSManaged public var checkInTime: NSNumber?
    @NSManaged public var city: String?
    @NSManaged public var commutableType: NSNumber?
    @NSManaged public var commuteCity: NSNumber?
    @NSManaged public var connectTime: NSNumber?
    @NSManaged public var isNonStop: NSNumber?
    @NSManaged public var secondCellValue: NSNumber?
    @NSManaged public var thirdCellValue: NSNumber?
    @NSManaged public var type: NSNumber?
    @NSManaged public var value: NSNumber?
    @NSManaged public var weight: NSNumber?

}

extension Commutability : Identifiable {

}
