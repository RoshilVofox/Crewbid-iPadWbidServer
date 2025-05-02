//
//  VacationArrayFromServer+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension VacationArrayFromServer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VacationArrayFromServer> {
        return NSFetchRequest<VacationArrayFromServer>(entityName: "VacationArrayFromServer")
    }

    @NSManaged public var endDate: Date?
    @NSManaged public var fvEnddate: Date?
    @NSManaged public var fvLength: NSNumber?
    @NSManaged public var fvStartdate: Date?
    @NSManaged public var length: NSNumber?
    @NSManaged public var startDate: Date?
    @NSManaged public var vacationType: String?
    @NSManaged public var bidPeriod: BIBidPeriod?
    @NSManaged public var line: BILine?

}

extension VacationArrayFromServer : Identifiable {

}
