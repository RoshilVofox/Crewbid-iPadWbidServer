//
//  CommuteTime+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension CommuteTime {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CommuteTime> {
        return NSFetchRequest<CommuteTime>(entityName: "CommuteTime")
    }

    @NSManaged public var bidDay: Date?
    @NSManaged public var bidDayStringValue: String?
    @NSManaged public var earliestArrivel: Date?
    @NSManaged public var latestDeparture: Date?
    @NSManaged public var type: NSNumber?
    @NSManaged public var commutable: BIBidPeriod?

}

extension CommuteTime : Identifiable {

}
