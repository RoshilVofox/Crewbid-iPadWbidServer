//
//  BIInsertionPoint+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 09/08/25.
//
//

import Foundation
import CoreData


extension BIInsertionPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BIInsertionPoint> {
        return NSFetchRequest<BIInsertionPoint>(entityName: "InsertionPoint")
    }

    @NSManaged public var above: NSNumber?
    @NSManaged public var index: NSNumber?
    @NSManaged public var line: BILine?
    @NSManaged public var bidPeriod: BIBidPeriod?
}

extension BIInsertionPoint : Identifiable {

}
