//
//  BITextFile+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 05/12/25.
//
//

public import Foundation
public import CoreData


public typealias BITextFileCoreDataPropertiesSet = NSSet

extension BITextFile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BITextFile> {
        return NSFetchRequest<BITextFile>(entityName: "TextFile")
    }

    @NSManaged public var name: String?
    @NSManaged public var text: String?
    @NSManaged public var bidPeriod: BIBidPeriod?

}

extension BITextFile : Identifiable {

}
