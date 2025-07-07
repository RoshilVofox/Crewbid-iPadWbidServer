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

enum BIPassesThruBaseFilterRuleType: Int {
    case midTrip
    case standard
}

extension BIFilterRule : Identifiable, NSFetchedResultsControllerDelegate {
    class func menuItemsForBidPeriod() -> NSArray {
        var menuItems: NSArray!
        let ruleFileURL = Bundle.main.path(forResource: "FilterRules", ofType: "plist")
        let ruleDictionary = NSMutableDictionary(contentsOfFile: ruleFileURL!)!
        menuItems = (ruleDictionary["rules"]! as! NSArray)
        return menuItems! as NSArray
    }
    
    func ruleHighlightsTrips() -> Bool {
        
        if self.category == nil {
            return false
        }
        let category = Int(truncating: self.category!)
        let type = Int(truncating: self.type!)
        if (category == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue) {
            if (BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConusLegs.rawValue == type) {
                return false
            }
            else if (BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue == type) {
                return true
            }
            else {
                let city = self.variables![BIFilterRuleCityVariablesKey] as? String
                if (!city!.isEmpty) {
                    return false
                }
                else {
                    return true
                }
            }
        }
        else if (category == BIFilterRuleCategory.BIOvernightCitiesBulkRuleCategory.rawValue) {
            return false
        }
        else if (category == BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue) {
            return true
        }
        else if (category == BIFilterRuleCategory.BIPassesThruBaseFilterRuleCategory.rawValue && BIPassesThruBaseFilterRuleType.midTrip.rawValue == type) {
            return true
        }
        else if (category == BIFilterRuleCategory.BIPassesThruBaseFilterRuleCategory.rawValue && BIPassesThruBaseFilterRuleType.standard.rawValue == type) {
            return true
        }
        else if (category == BIFilterRuleCategory.BIWorkBlockRuleCategory.rawValue) {
            return true
        }
        else if (category == BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue) {
            return true
        } else {
            return false
        }
    }
    
    func highlightTrips() {
        // Fetch the trips fetch controller. Add the highlightCount to trips
        let tripsFetch: NSFetchRequest<BITrip> = BITrip.fetchRequest()
        tripsFetch.predicate = self.predicateForTripHighlight()
        if (tripsFetch == nil) {
            return
        }
        tripsFetch.sortDescriptors = [NSSortDescriptor(key: "info.number", ascending: true)]
        
        let tripsFetchController = NSFetchedResultsController(
            fetchRequest: tripsFetch,
            managedObjectContext: self.managedObjectContext!,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        tripsFetchController.delegate = self
        
        do {
            try tripsFetchController.performFetch()
            if let fetchedObjects = tripsFetchController.fetchedObjects {
                for trip in fetchedObjects {
                    trip.highlightCount = (Int(truncating: trip.highlightCount!) + 1 as NSNumber)
                }
            }
        }
        catch {
            print("error executing trips fetch: \(error.localizedDescription)")
        }
    }
    
    func predicateForTripHighlight() -> NSPredicate? {
        let category = self.category?.intValue
        let type = self.type?.intValue
        let domicileCity = UserDefaults.standard.string(forKey: "kCBCrewBaseDefaultKey")
        var format: NSPredicate?
        if (BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue == category) {
            if (BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue == type) {
                let formatString = "SUBQUERY(days, $DAY, ($DAY.info.city IN $SET) && $DAY.trip.dropForFiltersSorts == 0).@count > 0"
                let format = NSPredicate(format: formatString)

                if let filterVars = (self.variables as? NSMutableDictionary),
                   let citiesArray = self.selectedRegionalCities() as? [String] {
                    
                    let set = Set(citiesArray)
                    filterVars["SET"] = set
                    self.variables = filterVars
                }

            }
            else {
                let city = self.variables![BIFilterRuleCityVariablesKey] as? String ?? ""
                if (city == "") {
                    return nil
                }
                // Overnight city predicate.
                if (BICitiesFilterRuleType.BIOvernightCityType.rawValue == self.type?.intValue) {
                    if (city == domicileCity) {
                        return nil
                    }
                    else {
                        let formatString = "SUBQUERY(days, $DAY, $DAY.info.city == $\(BIFilterRuleCityVariablesKey) && $DAY.trip.dropForFiltersSorts == 0).@count > 0"
                        format = NSPredicate(format: formatString)
                    }
                }
                // Leg city predicate.
                else {
                    let formatString = """
                    SUBQUERY(legs, $LEG, $LEG.info.arriveCity == $\(BIFilterRuleCityVariablesKey) && $LEG.info.lastLegOfTrip == NO && $LEG.trip.dropForFiltersSorts == 0).@count > 0
                    """
                    let format = NSPredicate(format: formatString)
                }
            }
        }
        else if (BIFilterRuleCategory.BIOvernightCitiesBulkRuleCategory.rawValue == category) {
            let arrData = CBUtils.checkOvernightPredicate()
            if arrData.count > 0 {
                format = NSCompoundPredicate(andPredicateWithSubpredicates: CBUtils.checkOvernightPredicate() as! [NSPredicate])
            }
            else {
                let dic: NSMutableDictionary = [:]
                dic["CITY"] = "SIVA"
                let formatString = "SUBQUERY(days, $DAY, $DAY.info.city == $\(BIFilterRuleCityVariablesKey) && $DAY.trip.dropForFiltersSorts == 0).@count > 0"
                format = NSPredicate(format: formatString)
                return format!.withSubstitutionVariables(dic as! [String : Any])
            }
        }
        else if (category == BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue && type == BIDeadheadsFilterRuleType.BIDeadheadsType.rawValue) {
            let formatString = "SUBQUERY(legs, $LEG, $LEG.info.isDeadhead == YES && $LEG.trip.dropForFiltersSorts == 0).@count > 0"
            format = NSPredicate(format: formatString)
        }
        else if (category == BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue && (type == BIDeadheadsFilterRuleType.BIDeadheadsAtStartType.rawValue || type == BIDeadheadsFilterRuleType.BIDeadheadsAtEndType.rawValue || type == BIDeadheadsFilterRuleType.BIDeadheadsAtEitherType.rawValue)) {
            let city = self.variables![BIFilterRuleCityVariablesKey] as? String ?? ""
            if (city.isEmpty) {
                if type == BIDeadheadsFilterRuleType.BIDeadheadsAtStartType.rawValue {
                    let formatString = "SUBQUERY(legs, $LEG, ($LEG.info.firstLegOfTrip == YES && $LEG.info.isDeadhead == YES && $LEG.trip.dropForFiltersSorts == 0)).@count > 0"
                    format = NSPredicate(format: formatString)
                }
                else if type == BIDeadheadsFilterRuleType.BIDeadheadsAtEndType.rawValue {
                    let formatString = "SUBQUERY(legs, $LEG, ($LEG.info.lastLegOfTrip == YES && $LEG.info.isDeadhead == YES && $LEG.trip.dropForFiltersSorts == 0)).@count > 0"
                    format = NSPredicate(format: formatString)
                }
                else {
                    let formatString = "SUBQUERY(legs, $LEG, ($LEG.trip.dropForFiltersSorts == 0 && (($LEG.info.firstLegOfTrip == 1 && $LEG.info.isDeadhead == 1) || ($LEG.info.lastLegOfTrip == 1 && $LEG.info.isDeadhead == 1)))).@count > 0"
                    format = NSPredicate(format: formatString)
                }
            }
            else {
                if type == BIDeadheadsFilterRuleType.BIDeadheadsAtStartType.rawValue {
                    let formatString = "SUBQUERY(legs, $LEG, ($LEG.info.firstLegOfTrip == 1 && $LEG.trip.dropForFiltersSorts == 0 && $LEG.info.isDeadhead == 1 && $LEG.info.arriveCity == $\(BIFilterRuleCityVariablesKey))).@count > 0"
                    format = NSPredicate(format: formatString)
                }
                else if type == BIDeadheadsFilterRuleType.BIDeadheadsAtEndType.rawValue {
                    let formatString = "SUBQUERY(legs, $LEG, ($LEG.info.lastLegOfTrip == 1 && $LEG.trip.dropForFiltersSorts == 0 && $LEG.info.isDeadhead == 1 && $LEG.info.departCity == $\(BIFilterRuleCityVariablesKey))).@count > 0"
                    format = NSPredicate(format: formatString)
                }
                else {
                    let formatString = "SUBQUERY(legs, $LEG, ($LEG.trip.dropForFiltersSorts == 0 && (($LEG.info.firstLegOfTrip == 1 && $LEG.info.isDeadhead == 1 && $LEG.info.arriveCity == $\(BIFilterRuleCityVariablesKey)) || ($LEG.info.lastLegOfTrip == 1 && $LEG.info.isDeadhead == 1 && $LEG.info.departCity == $\(BIFilterRuleCityVariablesKey))))).@count > 0"
                    format = NSPredicate(format: formatString)
                }
            }
        }
        else if (category == BIFilterRuleCategory.BIPassesThruBaseFilterRuleCategory.rawValue && type == BIPassesThruBaseFilterRuleType.standard.rawValue) {
            let domicileCity = UserDefaults.standard.object(forKey: kCBCrewBaseDefaultKey) as! String
            let formatString = "SUBQUERY(legs, $LEG, $LEG.info.arriveCity == '\(domicileCity)' && $LEG.info.lastLegOfTrip == NO && $LEG.trip.dropForFiltersSorts == 0).@count > 0"
            format = NSPredicate(format: formatString)
        }
        else if (category == BIFilterRuleCategory.BIPassesThruBaseFilterRuleCategory.rawValue && type == BIPassesThruBaseFilterRuleType.midTrip.rawValue) {
            let formatString = "(info.containsMidTripPTB == 1 && dropForFiltersSorts == 0)"
            format = NSPredicate(format: formatString)
        }
        if format == nil {
            format = NSPredicate(value: true)
        }
        return format!.withSubstitutionVariables(self.variables as! [String: Any])
    }
    
    func selectedRegionalCities() -> NSArray {
        var cities: NSArray? = []
        let type = self.type?.intValue
        if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedEastCoastCities) as? NSArray)
        }
        else if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedWestCoastCities) as? NSArray)
        }
        else if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedNonConusCities) as? NSArray)
        }
        else if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedInternationalCities) as? NSArray)
        }
        else if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedAllCities) as? NSArray)
        }
        else if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedHawaiiCities) as? NSArray)
        }
        return cities ?? []
    }
}
