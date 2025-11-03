//
//  AwardDetails+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/10/25.
//
//

public import Foundation
public import CoreData


public typealias AwardDetailsCoreDataPropertiesSet = NSSet

extension AwardDetails {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AwardDetails> {
        return NSFetchRequest<AwardDetails>(entityName: "AwardDetails")
    }

    @NSManaged public var empNum: String?
    @NSManaged public var lineNum: Int16
    @NSManaged public var seqNumber: Int16
    @NSManaged public var position: String?
    @NSManaged public var empName: String?
    @NSManaged public var bidPeriod: BIBidPeriod?

}

extension AwardDetails : Identifiable {

}
