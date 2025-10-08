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
@objc enum CommutabilityThirdCell : Int {
    case Front = 1
    case Back
    case Overall
}

@objc enum ConstraintType : Int {
    case MoreThan = 1
    case LessThan
    case EqualTo
    case NotEqualTo
    case atAfter
    case atBefore
}

@objc enum BIOverlapDaysFilterRuleType: Int{
    case BIBIOverlapDaysFilterRuleTypeFront
    case BIOverlapDaysFilterRuleTypeBack
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

@objc enum BIDaysOfMonthFilterRuleType : Int {
    case BIDaysOfMonthOffType
    case BIDaysOfMonthIncludedType
    case BIDaysOfMonthFilterRuleTypeTripStartDates
    case BIDaysOfMonthFilterRuleTypeTripEndDates
    
    func name () -> Int {
        switch self
        {
        case .BIDaysOfMonthOffType: return 0
        case .BIDaysOfMonthIncludedType: return 1
        case .BIDaysOfMonthFilterRuleTypeTripStartDates: return 2
        case .BIDaysOfMonthFilterRuleTypeTripEndDates: return 3
        }
    }
}

enum BIPassesThruBaseFilterRuleType: Int {
    case midTrip
    case standard
}

extension BIFilterRule : Identifiable, NSFetchedResultsControllerDelegate {
    class func menuItemsForBidPeriod(_ bidPeriod: BIBidPeriod) -> NSArray {
        var menuItems: NSArray!
        // Check if it's the first round bid or flight attendant bid
        if bidPeriod.isFirstRoundBid() || bidPeriod.isFABid(){
            // Load FilterRules.plist for the menu items
            let ruleFileURL = Bundle.main.path(forResource: "FilterRules", ofType: "plist")
            let ruleDictionary = NSMutableDictionary(contentsOfFile: ruleFileURL!)!
            menuItems = (ruleDictionary["rules"]! as! NSArray)
        }else{
            // Load FilterRulesRound2.plist for the menu items
            let ruleFileURL = Bundle.main.path(forResource: "FilterRulesRound2", ofType: "plist")
            let ruleDictionary = NSMutableDictionary(contentsOfFile: ruleFileURL!)
            menuItems = (ruleDictionary?["rules"]! as! NSArray)
        }
        // Check if Swaptimizer is enabled for the bid period
        if (bidPeriod.swaptimizerStatus ?? 0).intValue == CBSwaptimizerStatus.enabled.rawValue {
//            if bidPeriod.isFABid(){
                // Load FilterRulesFaVacation.plist for flight attendant bids
                let swaptimizerFileURL = Bundle.main.path(forResource: "FilterRulesSwaptimizer", ofType: "plist")
                let swapRulesDictionary = NSMutableDictionary(contentsOfFile: swaptimizerFileURL!)!
                var swapRulesArray: NSArray!
                swapRulesArray = (swapRulesDictionary["rules"]! as! NSArray)
                // Combine the menu items with swap rules
                menuItems = swapRulesArray.addingObjects(from: menuItems as! [Any]) as NSArray
//            }
        }
        if bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue {
            let swaptimizerFileURL = Bundle.main.path(forResource: "FilterRulesFaVacation", ofType: "plist")
            let swapRulesDictionary = NSMutableDictionary(contentsOfFile: swaptimizerFileURL!)!
            var swapRulesArray: NSArray!
            swapRulesArray = (swapRulesDictionary["rules"]! as! NSArray)
            // Combine the menu items with swap rules
            menuItems = swapRulesArray.addingObjects(from: menuItems as! [Any]) as NSArray
        }
        
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
        if (tripsFetch.predicate == nil) {
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
    
    func deHighlightTrips() {
        // Fetch the trips fetch controller. Add the highlightCount to trips
        let tripsFetch: NSFetchRequest<BITrip> = BITrip.fetchRequest()
        if (self.category?.intValue == BIFilterRuleCategory.BIOvernightCitiesBulkRuleCategory.rawValue) {
            tripsFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: CBUtils.checkOvernightPredicate())
        }
        else {
            tripsFetch.predicate = self.predicateForTripHighlight()
        }
        if tripsFetch.predicate == nil {
            return
        }
        else {
            guard let basePredicate = tripsFetch.predicate else {
                    return
                }
            let highlightPredicate = NSPredicate(format: "highlightCount > 0")
            tripsFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, highlightPredicate])
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
                    trip.highlightCount = (Int(truncating: trip.highlightCount!) - 1 as NSNumber)
                    trip.bidListHighlighted = false
                }
            }
        }
        catch {
            print("error executing trips fetch: \(error.localizedDescription)")
        }
    }

    
    class func formatForCategory(category: BIFilterRuleCategory.RawValue, type: Int) -> NSPredicate {
        var format: NSPredicate? = nil
        switch category {
        case BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue:
            // Predicate for filtering by type.

            let formatString: String = "(type IN $SET)"
            format = NSPredicate(format: formatString)
        case BIFilterRuleCategory.BIEtopsFilterRuleCategory.rawValue:
            // Predicate for filtering by ETOPS.

            let formatString: String = "($ETOPS_ON == YES OR isETOPS == 0)"
            format = NSPredicate(format: formatString)
        case BIFilterRuleCategory.BIEtopsResFilterRuleCategory.rawValue:
            // Predicate for filtering by ETOPS Reservations.

            let formatString: String = "($ETOPSRES_ON == YES OR isETOPSRES == 0)"
            format = NSPredicate(format: formatString)
        case BIFilterRuleCategory.BIAmPmFilterRuleCategory.rawValue:
            // Predicate for filtering by AM/PM.

            format = NSPredicate(format: "amPM IN $SET")
        case BIFilterRuleCategory.BIDaysOfWeekFilterRuleCategory.rawValue:
            // Predicate for filtering by days of the week.

            format = NSPredicate(format: "bitwiseAnd:with:(weekdayBits, $WEEKDAY_BITS) == 0")
        case BIFilterRuleCategory.BITripLengthFilterRuleCategory.rawValue:
            // Predicate for filtering by trip length.

            format = NSPredicate(format: "($TURNS_ON == YES OR turnsCount == 0) AND " +
                                    "($TWO_DAYS_ON == YES OR twoDayTripsCount == 0) AND " +
                                    "($THREE_DAYS_ON == YES OR threeDayTripsCount == 0) AND " +
                                    "($FOUR_DAYS_ON == YES OR fourDayTripsCount == 0)")
        case BIFilterRuleCategory.BIDaysOfMonthFilterRuleCategory.rawValue:
            // Predicate for filtering by days of the month.
                // A set bit indicates a day of the month wanted off.
            format = NSPredicate(format: "bitwiseAnd:with:(monthBits, $MONTH_BITS) == 0")
            
        case BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue:
            // Predicate for filtering by position.

            format = NSPredicate(format: "faPosition IN $SET")
        case BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue:
            // Predicate for filtering by FA Reserve Line Type.

            format = NSPredicate(format: "faReserveLineType IN $SET")
        case BIFilterRuleCategory.BIUserFlagFilterRuleCategory.rawValue:
            // Predicate for filtering by User Flag Type.

            let formatString: String = "userFlagType IN $SET"
            format = NSPredicate(format: formatString)
        default:
            break
        }
        
        return format!
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
    
    func saveSelectedCities(_ selectedCities: [Any]) {
        if BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue == type?.intValue {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedEastCoastCities)
        }
        else if BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue == type?.intValue {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedWestCoastCities)
        }
        else if BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue == type?.intValue {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedNonConusCities)
        }
        else if BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue == type?.intValue {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedInternationalCities)
        }
        else if BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue == type?.intValue {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedAllCities)
        }
        else if BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue == type?.intValue {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedHawaiiCities)
        }
    }
    
    func selectedRegionalCities() -> [Any] {
        var cities: [Any]? = []
        let type = self.type?.intValue
        if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedEastCoastCities) as? [Any])
        }
        else if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedWestCoastCities) as? [Any])
        }
        else if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedNonConusCities) as? [Any])
        }
        else if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedInternationalCities) as? [Any])
        }
        else if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedAllCities) as? [Any])
        }
        else if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue) {
            cities = (UserDefaults.standard.object(forKey: kCBSelectedHawaiiCities) as? [Any])
        }
        if cities == nil {
            cities = [Any]()
        }
        return cities!
    }
    
    
    func predicateOperatorString() -> String {
        var predicateOperatorString: String? = nil
        switch (comparison ?? 0).intValue {
        case 1:
            predicateOperatorString = "<="
        case 2:
            predicateOperatorString = "=="
        case 3:
            predicateOperatorString = ">="
        default:
            predicateOperatorString = "<="
        }
        
        return predicateOperatorString!
    }
    
    var predicate : NSPredicate {
        var format:NSPredicate? = nil
        let category = Int(truncating: self.category!)
        let type = Int(truncating: self.type!)
        if category == BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue ||
            category == BIFilterRuleCategory.BIAmPmFilterRuleCategory.rawValue ||
            category == BIFilterRuleCategory.BIUserFlagFilterRuleCategory.rawValue ||
            category == BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue ||
            category == BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue ||
            category == BIFilterRuleCategory.BIEtopsFilterRuleCategory.rawValue ||
            category == BIFilterRuleCategory.BIEtopsResFilterRuleCategory.rawValue {
            
            format = BIFilterRule.formatForCategory(category: category, type: type)
            
        }else if category == BIFilterRuleCategory.BIDaysOfWeekFilterRuleCategory.rawValue {
            
            if BIWeekdaysFilterRuleType.BIWeekdaysCompoundType.rawValue == type {
                format = BIFilterRule.formatForCategory(category: category, type: type)
            }else{
                let formatString = String(format: "%@ %@ $%@",self.keyPath!,self.predicateOperatorString(),BIFilterRuleValueVariablesKey)
                
                format = NSPredicate(format: formatString)
            }
        }else if category == BIFilterRuleCategory.BITripLengthFilterRuleCategory.rawValue {
            if self.abbreviation == "Su" || self.abbreviation == "Mo" || self.abbreviation == "Tu" || self.abbreviation == "Wed" || self.abbreviation == "Th" || self.abbreviation == "Fr" || self.abbreviation == "Sa" || self.abbreviation == "Wknds" {
                if BIWeekdaysFilterRuleType.BIWeekdaysCompoundType.rawValue == type {
                    format = BIFilterRule.formatForCategory(category: category, type: type)
                }else{
                    let formatString = String(format: "%@ %@ $%@", self.keyPath!,self.predicateOperatorString(), BIFilterRuleValueVariablesKey)
                    format = NSPredicate(format: formatString)
                }
            }else{
                if BITripLengthFilterRuleType.BITripLengthCompoundType.rawValue == type {
                    format = BIFilterRule.formatForCategory(category: category, type: type)
                }else{
                    let formatString = String(format: "%@ %@ $%@", keyPath!, self.predicateOperatorString(), BIFilterRuleValueVariablesKey)
                    format = NSPredicate(format: formatString)
                }
            }
        }else if category == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue && type != BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConusLegs.rawValue {
            if type == BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue ||
                type == BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue ||
                type == BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue ||
                type == BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue ||
                type == BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue ||
                type == BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue{
                let formatString = String(format: "SUBQUERY(days, $DAY, ($DAY.info.city IN $SET) && $DAY.trip.dropForFiltersSorts == 0).@count %@ $%@", self.predicateOperatorString(), BIFilterRuleValueVariablesKey)
                format = NSPredicate(format: formatString)
                var filterVars = self.variables as! [String : Any]
                if filterVars["SET"] == nil {
                    let SET = self.selectedRegionalCities()
                    filterVars["SET"] = SET
                    self.variables = filterVars as NSDictionary
                }
            }else{
                let city = self.variables?[BIFilterRuleCityVariablesKey]
                if city == nil || city as! String == "" {
                    return NSPredicate(value: true)
                }
                // Overnight city predicate.
                if type == BICitiesFilterRuleType.BIOvernightCityType.rawValue {
                    let formatString = String(format: "SUBQUERY(days, $DAY, $DAY.info.city == $%@ && $DAY.trip.dropForFiltersSorts == 0).@count %@ $%@", BIFilterRuleCityVariablesKey, self.predicateOperatorString(),BIFilterRuleValueVariablesKey)
                    format = NSPredicate(format: formatString)
                }
                // Leg city predicate.
                else{
                    let formatString = String(format: "SUBQUERY(legs, $LEG, $LEG.info.arriveCity == $%@ && $LEG.trip.dropForFiltersSorts == 0 && $LEG.info.lastLegOfTrip == NO).@count %@ $%@", BIFilterRuleCityVariablesKey,self.predicateOperatorString(),BIFilterRuleValueVariablesKey)
                    format = NSPredicate(format: formatString)
                }
            }
        }else if category == BIFilterRuleCategory.BIOvernightCitiesBulkRuleCategory.rawValue{
            AppState.shared.currentBidPeriod?.isOverNightBulkApplied = "YES"
//            let formatString = "isTrashed == NO"
            let formatString: String = "isTrashed == NO AND  isOvernightFiltered == NO"
            format = NSPredicate(format: formatString)
            return format!
        }
        else if category == BIFilterRuleCategory.BIDaysOfMonthFilterRuleCategory.rawValue{
            if type == BIDaysOfMonthFilterRuleType.BIDaysOfMonthOffType.rawValue{
                format = NSPredicate(format: "bitwiseAnd:with:(monthBits, $MONTH_BITS) == 0")
            }else if type == BIDaysOfMonthFilterRuleType.BIDaysOfMonthIncludedType.rawValue{
                format = NSPredicate(format: "bitwiseAnd:with:(monthBits, $MONTH_BITS) == ((bitwiseAnd:with:($MONTH_BITS, $MONTH_BITS)))")
            }else if type == BIDaysOfMonthFilterRuleType.BIDaysOfMonthFilterRuleTypeTripStartDates.rawValue{
                format = NSPredicate(format: "bitwiseAnd:with:(tripStartMonthBits, $MONTH_BITS) == 0")
            }else if type == BIDaysOfMonthFilterRuleType.BIDaysOfMonthFilterRuleTypeTripEndDates.rawValue{
                format = NSPredicate(format: "bitwiseAnd:with:(tripEndMonthBits, $MONTH_BITS) == 0")
            }
        }else if category == BIFilterRuleCategory.BICommutingFilterRuleCategory.rawValue{
            let fetchRequest: NSFetchRequest<CommuteTime> = CommuteTime.fetchRequest()
            do {
                let fetchedObjects = try self.managedObjectContext!.fetch(fetchRequest)
                
                var formatString = ""
                if fetchedObjects.count > 0 {
                    formatString = "commutabilityOverall == 100"
                }
                if !(formatString.count > 1){
                    formatString = "commutabilityOverall == 0"
                }
                format = NSPredicate(format: String(format: "(%@)", formatString))
                if bidPeriod!.orderedLines().first!.totalCommutes!.intValue == 0 && bidPeriod!.orderedLines().first!.orderedTripObjects().count > 0{
                    format = NSPredicate(value: true)
                }
            } catch {
                print("Fetch error: \(error.localizedDescription)")
            }
            
            
        }else if category == BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue{
            let fetchRequest:NSFetchRequest<Commutability> = Commutability.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.filter.rawValue)
            do{
                let fetchedObjects = try self.managedObjectContext!.fetch(fetchRequest)
                
                var ObjCommutability:Commutability? = nil
                var formatString = ""
                if fetchedObjects.count > 0 {
                    ObjCommutability = fetchedObjects[0]
                    if ObjCommutability?.secondCellValue?.intValue == 1 {
                        if ObjCommutability?.thirdCellValue?.intValue == CommutabilityThirdCell.Back.rawValue {
                            if ObjCommutability?.type?.intValue == ConstraintType.LessThan.rawValue {
                                formatString = String(format: "(commutabilityBack > %d)|| (nightsInMid  > 0)", (ObjCommutability?.value!.intValue)!)
                            }else if ObjCommutability?.type?.intValue == ConstraintType.MoreThan.rawValue {
                                formatString = String(format: "(commutabilityBack < %d) || (nightsInMid  > 0)", (ObjCommutability?.value!.intValue)!)
                            }
                        }else if ObjCommutability?.thirdCellValue?.intValue == CommutabilityThirdCell.Front.rawValue {
                            if ObjCommutability?.type?.intValue == ConstraintType.LessThan.rawValue {
                                formatString = String(format: "(commutabilityFront > %d)|| (nightsInMid  > 0)", (ObjCommutability?.value!.intValue)!)
                            }else if ObjCommutability?.type?.intValue == ConstraintType.MoreThan.rawValue {
                                formatString = String(format: "(commutabilityFront < %d) || (nightsInMid  > 0)", (ObjCommutability?.value!.intValue)!)
                            }
                        }
                        if ObjCommutability?.thirdCellValue?.intValue == CommutabilityThirdCell.Overall.rawValue {
                            if ObjCommutability?.type?.intValue == ConstraintType.LessThan.rawValue {
                                formatString = String(format: "(commutabilityOverall > %d)|| (nightsInMid  > 0)", (ObjCommutability?.value!.intValue)!)
                            }else if ObjCommutability?.type?.intValue == ConstraintType.MoreThan.rawValue {
                                formatString = String(format: "(commutabilityOverall < %d) || (nightsInMid  > 0)", (ObjCommutability?.value!.intValue)!)
                            }
                        }
                    }else{
                        if ObjCommutability?.thirdCellValue?.intValue == CommutabilityThirdCell.Back.rawValue {
                            if ObjCommutability?.type?.intValue == ConstraintType.LessThan.rawValue {
                                formatString = String(format: "(commutabilityBack > %d)", (ObjCommutability?.value!.intValue)!)
                            }else if ObjCommutability?.type?.intValue == ConstraintType.MoreThan.rawValue {
                                formatString = String(format: "(commutabilityBack < %d)", (ObjCommutability?.value!.intValue)!)
                            }
                        }else if ObjCommutability?.thirdCellValue?.intValue == CommutabilityThirdCell.Front.rawValue {
                            if ObjCommutability?.type?.intValue == ConstraintType.LessThan.rawValue {
                                formatString = String(format: "(commutabilityFront > %d)", (ObjCommutability?.value!.intValue)!)
                            }else if ObjCommutability?.type?.intValue == ConstraintType.MoreThan.rawValue {
                                formatString = String(format: "(commutabilityFront < %d)", (ObjCommutability?.value!.intValue)!)
                            }
                        }
                        if ObjCommutability?.thirdCellValue?.intValue == CommutabilityThirdCell.Overall.rawValue {
                            if ObjCommutability?.type?.intValue == ConstraintType.LessThan.rawValue {
                                formatString = String(format: "(commutabilityOverall > %d)", (ObjCommutability?.value!.intValue)!)
                            }else if ObjCommutability?.type?.intValue == ConstraintType.MoreThan.rawValue {
                                formatString = String(format: "(commutabilityOverall < %d)", (ObjCommutability?.value!.intValue)!)
                            }
                        }
                    }
                    if !(formatString.length > 1) {
                        formatString = "commutabilityBack == commutabilityBack"
                    }
                    format = NSPredicate(format: String(format: "!(%@)", formatString))
                }
            }catch{
                print("Fetch error: \(error.localizedDescription)")
            }
            
        }else if category == BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue && (type == BIDeadheadsFilterRuleType.BIDeadheadsAtStartType.rawValue || type == BIDeadheadsFilterRuleType.BIDeadheadsAtEndType.rawValue || type == BIDeadheadsFilterRuleType.BIDeadheadsAtEitherType.rawValue){
            let city = self.variables![BIFilterRuleCityVariablesKey] as? String
            if city == nil || city == "" {
                let formatString = String(format: "%@ %@ $%@", self.keyPath!, self.predicateOperatorString(),BIFilterRuleCityVariablesKey)
                format = NSPredicate(format: formatString)
            }else if BIDeadheadsFilterRuleType.BIDeadheadsAtStartType.rawValue == type {
                let formatString = String(format: """
                SUBQUERY(legs, $LEG, ($LEG.info.firstLegOfTrip == 1 && $LEG.trip.dropForFiltersSorts == 0 && \
                $LEG.info.isDeadhead == 1 && $LEG.info.arriveCity == $%@)).@count %@ $%@
                """, BIFilterRuleCityVariablesKey,self.predicateOperatorString(),BIFilterRuleValueVariablesKey)
                format = NSPredicate(format: formatString)
            }
            else if BIDeadheadsFilterRuleType.BIDeadheadsAtEndType.rawValue == type {
                let formatString = String(format: """
                SUBQUERY(legs, $LEG, ($LEG.info.lastLegOfTrip == 1 && $LEG.trip.dropForFiltersSorts == 0 && \
                $LEG.info.isDeadhead == 1 && $LEG.info.departCity == $%@)).@count %@ $%@
                """, BIFilterRuleCityVariablesKey, self.predicateOperatorString(), BIFilterRuleValueVariablesKey)
                format = NSPredicate(format: formatString)
            }else{
                let formatString = String(format: """
                SUBQUERY(legs, $LEG, ($LEG.trip.dropForFiltersSorts == 0 &&(($LEG.info.firstLegOfTrip == 1 && $LEG.info.isDeadhead == 1 && $LEG.info.arriveCity == $%@)||($LEG.info.lastLegOfTrip == 1 && $LEG.info.isDeadhead == 1 && $LEG.info.departCity == $%@)))).@count %@ $%@
                """, BIFilterRuleCityVariablesKey, BIFilterRuleCityVariablesKey, self.predicateOperatorString(), BIFilterRuleValueVariablesKey)
                format = NSPredicate(format: formatString)
            }
        }else if BIFilterRuleCategory.BIOvernightLengthFilterRuleCategory.rawValue == category {
            var formatString = ""
            if BIOvernightLengthFilterRuleType.BIMinimumOvernightLengthType.rawValue == type {
                formatString = String(format: "minimumOvernightHours %@ $%@", self.predicateOperatorString(), BIFilterRuleValueVariablesKey)
            }else{
                formatString = String(format: "maximumOvernightHours %@ $%@", self.predicateOperatorString(), BIFilterRuleValueVariablesKey)
            }
            format = NSPredicate(format: formatString)
        }
        else if BIFilterRuleCategory.BIOvAvgFilterRuleCategory.rawValue == category {
            let val = self.variables![BIFilterRuleValueVariablesKey] as! NSNumber
            let a = val.intValue * 60
            let formatString = String(format: "ovAvg %@ %d", self.predicateOperatorString(),a)
            return NSPredicate(format: formatString)
        }else if BIFilterRuleCategory.BIOverlapFilterRuleCategory.rawValue == category && BIOverlapDaysFilterRuleType.BIBIOverlapDaysFilterRuleTypeFront.rawValue == type {
            if self.predicateOperatorString() == "<="{
                let formatString = String(format: """
                SUBQUERY(trips, $TRIP, $TRIP.startDay <= ($%@+1)).@count > 0
                """, BIFilterRuleValueVariablesKey)
                format = NSPredicate(format: formatString)
            }else if self.predicateOperatorString() == ">="{
                let formatString = String(format: """
                SUBQUERY(trips, $TRIP, $TRIP.startDay < ($%@+1)).@count == 0
                """, BIFilterRuleValueVariablesKey)
                format = NSPredicate(format: formatString)
            }else{
                let formatString = String(format: """
            (SUBQUERY(trips, $TRIP, $TRIP.startDay == ($%@+1)).@count > 0) && (SUBQUERY(trips, $TRIP, $TRIP.startDay < ($%@+1)).@count == 0)
            """, BIFilterRuleValueVariablesKey,BIFilterRuleValueVariablesKey)
                format = NSPredicate(format: formatString)
            }
        }
        else if BIFilterRuleCategory.BIReportReleaseFilterCategory.rawValue == category {
            let formatString = String(format: "(rptLessThanentered == NO AND rlsGreaterThanEntered == NO)")
            format = NSPredicate(format: formatString)
            return format!
        }else{
            let formatString = String(format: "%@ %@ $%@", self.keyPath!,self.predicateOperatorString(), BIFilterRuleValueVariablesKey)
            format = NSPredicate(format: formatString)
        }
        
        return format!.withSubstitutionVariables(self.variables as! [String : Any])
    }
    
    func loadFilterPreset(pRule: CBPresetFilterRule) {
        self.abbreviation = pRule.abbreviation
        self.category = pRule.category
        self.type = pRule.type
        self.name = pRule.name
        self.keyPath = pRule.keyPath
        self.comparison = pRule.comparison
        self.variables = pRule.variables as NSDictionary?
    }
    
}
