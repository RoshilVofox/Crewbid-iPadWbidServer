//
//  BIFilterRule+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//
//

import Foundation
import CoreData


extension BIFilterRule {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BIFilterRule> {
        return NSFetchRequest<BIFilterRule>(entityName: "FilterRule")
    }

    @NSManaged public var abbreviation: String?
    @NSManaged public var category: NSNumber?
    @NSManaged public var comparison: NSNumber?
    @NSManaged public var keyPath: String?
    @NSManaged public var name: String?
    @NSManaged public var type: NSNumber?
    @NSManaged public var variables: NSDictionary?
    @NSManaged public var bidPeriod: BIBidPeriod?

}
@objc enum BIWeekdaysFilterRuleType : Int {
    case BIWeekdaysCompoundType
    case BIWeekendsWeekdaysType
    case BISundaysWeekdaysType
    case BIMondaysWeekdaysType
    case BITuesdaysWeekdaysType
    case BIWednesdaysWeekdaysType
    case BIThurdaysWeekdaysType
    case BIFridaysWeekdaysType
    case BISaturdaysWeekdayType
    
    func name () -> Int {
        switch self
        {
        case .BIWeekdaysCompoundType: return 0
        case .BIWeekendsWeekdaysType: return 1
        case .BISundaysWeekdaysType: return 2
        case .BIMondaysWeekdaysType: return 3
        case .BITuesdaysWeekdaysType: return 4
        case .BIWednesdaysWeekdaysType: return 5
        case .BIThurdaysWeekdaysType: return 6
        case .BIFridaysWeekdaysType: return 7
        case .BISaturdaysWeekdayType: return 8
        }
    }
}
@objc enum BIDeadheadsFilterRuleType : Int {
    case BIDeadheadsType
    case BIDeadheadsAtStartType
    case BIDeadheadsAtEndType
    case BIDeadheadsAtEitherType
    
    func name () -> Int {
        switch self
        {
        case .BIDeadheadsType: return 0
        case .BIDeadheadsAtStartType: return 1
        case .BIDeadheadsAtEndType: return 2
        case .BIDeadheadsAtEitherType: return 3
        }
    }
}
@objc enum BICitiesFilterRuleType : Int {
    
    case BIOvernightCityType
    // 0
    case BILegCityType
    // 1
    case BICitiesFilterRuleTypeEastCoast
    // 2
    case BICitiesFilterRuleTypeWestCoast
    // 3
    case BICitiesFilterRuleTypeNonConus
    // 4
    case BICitiesFilterRuleTypeIntl
    // 5
    case BICitiesFilterRuleTypeAll
    // 6
    case BICitiesFilterRuleTypeNonConusLegs
    // 7
    case BICitiesFilterRuleTypeHawaii
    // 8
    
    func name () -> Int {
        switch self
        {
        case .BIOvernightCityType: return 0
        case .BILegCityType: return 1
        case .BICitiesFilterRuleTypeEastCoast: return 2
        case .BICitiesFilterRuleTypeWestCoast: return 3
        case .BICitiesFilterRuleTypeNonConus: return 4
        case .BICitiesFilterRuleTypeIntl: return 5
        case .BICitiesFilterRuleTypeAll: return 6
        case .BICitiesFilterRuleTypeNonConusLegs: return 7
        case .BICitiesFilterRuleTypeHawaii: return 8
            
        }
    }
}
extension BIFilterRule : Identifiable {
    class func menuItemsForBidPeriod() -> NSArray {
        var menuItems: NSArray!
        let ruleFileURL = Bundle.main.path(forResource: "FilterRules", ofType: "plist")
        let ruleDictionary = NSMutableDictionary(contentsOfFile: ruleFileURL!)!
        menuItems = (ruleDictionary["rules"]! as! NSArray)
        return menuItems! as NSArray
    }
}
