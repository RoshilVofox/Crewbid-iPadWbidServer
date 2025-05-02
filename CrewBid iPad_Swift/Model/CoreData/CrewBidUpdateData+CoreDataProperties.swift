//
//  CrewBidUpdateData+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension CrewBidUpdateData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CrewBidUpdateData> {
        return NSFetchRequest<CrewBidUpdateData>(entityName: "CrewBidUpdateData")
    }

    @NSManaged public var cities: String?
    @NSManaged public var defenitions: String?
    @NSManaged public var faq: String?
    @NSManaged public var helpVideos: String?
    @NSManaged public var hotels: String?
    @NSManaged public var inappPurchase: String?
    @NSManaged public var latestNews: String?
    @NSManaged public var receiptValidationURL: String?
    @NSManaged public var secretUser: String?
    @NSManaged public var swaptimizerDefinitions: String?
    @NSManaged public var swaptimizerFaq: String?

}

extension CrewBidUpdateData : Identifiable {

}
