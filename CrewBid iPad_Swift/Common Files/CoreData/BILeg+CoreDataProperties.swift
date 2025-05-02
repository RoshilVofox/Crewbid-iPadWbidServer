//
//  BILeg+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension BILeg {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BILeg> {
        return NSFetchRequest<BILeg>(entityName: "Leg")
    }

    @NSManaged public var day: BIDay?
    @NSManaged public var info: BILegInfo?
    @NSManaged public var line: BILine?
    @NSManaged public var trip: BITrip?

}

extension BILeg : Identifiable {

}
