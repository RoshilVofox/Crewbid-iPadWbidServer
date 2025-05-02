//
//  BILineSortKeyMap+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension BILineSortKeyMap {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BILineSortKeyMap> {
        return NSFetchRequest<BILineSortKeyMap>(entityName: "LineSortKeyMap")
    }

    @NSManaged public var lineKey: String?
    @NSManaged public var sortKey: String?
    @NSManaged public var bidPeriod: BIBidPeriod?
    @NSManaged public var lineSort: BILineSort?

}

extension BILineSortKeyMap : Identifiable {

}
