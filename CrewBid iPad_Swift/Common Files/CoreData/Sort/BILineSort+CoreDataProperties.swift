//
//  BILineSort+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension BILineSort {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BILineSort> {
        return NSFetchRequest<BILineSort>(entityName: "LineSort")
    }

    @NSManaged public var abbreviation: String?
    @NSManaged public var arrayVariables: NSObject?
    @NSManaged public var ascending: NSNumber?
    @NSManaged public var category: NSNumber?
    @NSManaged public var city: String?
    @NSManaged public var expression: String?
    @NSManaged public var isBidListSort: NSNumber?
    @NSManaged public var isMutable: NSNumber?
    @NSManaged public var keyPath: String?
    @NSManaged public var name: String?
    @NSManaged public var order: NSNumber?
    @NSManaged public var type: NSNumber?
    @NSManaged public var variables: NSObject?
    @NSManaged public var bidPeriod: BIBidPeriod?
    @NSManaged public var lineSortKeyMap: BILineSortKeyMap?

}

extension BILineSort : Identifiable {
    class func lineSortCategories() -> NSArray {
        var lineSortArray: NSArray!
        let lineSortsURL = Bundle.main.path(forResource: "LineSorts", ofType: "plist")
        let sortDictionary = NSMutableDictionary(contentsOfFile: lineSortsURL!)!
        lineSortArray = (sortDictionary["sorts"]! as! NSArray)
        return lineSortArray
    }
}
