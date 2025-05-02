//
//  OvernightBulk+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension OvernightBulk {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OvernightBulk> {
        return NSFetchRequest<OvernightBulk>(entityName: "OvernightBulk")
    }

    @NSManaged public var citystatus: NSObject?

}

extension OvernightBulk : Identifiable {

}
