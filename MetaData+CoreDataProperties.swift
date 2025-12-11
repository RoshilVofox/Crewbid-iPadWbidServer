//
//  MetaData+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 06/12/25.
//
//

public import Foundation
public import CoreData


public typealias MetaDataCoreDataPropertiesSet = NSSet

extension MetaData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetaData> {
        return NSFetchRequest<MetaData>(entityName: "MetaData")
    }

    @NSManaged public var abcdPositions: Int32
    @NSManaged public var abcPositions: Int32
    @NSManaged public var aPositions: Int32
    @NSManaged public var bcPositions: Int32
    @NSManaged public var bidPeriodBegin: String?
    @NSManaged public var bidPeriodEnd: String?
    @NSManaged public var dPositions: Int32
    @NSManaged public var estimatedReserveLines: Int32
    @NSManaged public var bidPeriod: BIBidPeriod?

}

extension MetaData : Identifiable {

}
