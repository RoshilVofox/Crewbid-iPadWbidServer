//
//  BIBidReceipt+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension BIBidReceipt {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BIBidReceipt> {
        return NSFetchRequest<BIBidReceipt>(entityName: "BidReceipt")
    }

    @NSManaged public var bidLineNumbers: NSObject?
    @NSManaged public var condensedText: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var optionalEmployeeNumbers: NSObject?
    @NSManaged public var submittedBy: String?
    @NSManaged public var submittedByUserId: String?
    @NSManaged public var submittedDateString: String?
    @NSManaged public var submittedFor: String?
    @NSManaged public var submittedForUserId: String?
    @NSManaged public var submittedLineNumbersString: String?
    @NSManaged public var text: String?
    @NSManaged public var timeStamp: Date?
    @NSManaged public var bidPeriod: BIBidPeriod?

}

extension BIBidReceipt : Identifiable {

}
