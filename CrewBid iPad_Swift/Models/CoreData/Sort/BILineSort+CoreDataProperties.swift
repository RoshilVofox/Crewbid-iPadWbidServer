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
    @NSManaged public var arrayVariables: NSArray? // first it was nsObject
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
    @NSManaged public var variables: NSDictionary?
    @NSManaged public var bidPeriod: BIBidPeriod?
    @NSManaged public var lineSortKeyMap: BILineSortKeyMap?

}

extension BILineSort : Identifiable, NSFetchedResultsControllerDelegate {
    class func lineSortCategories(for bidPeriod: BIBidPeriod) -> NSArray {
        var lineSortCategories: NSArray? = nil
        var lineSortsFileURL: URL? = nil
        // Determine the appropriate line sorts file URL based on bid period type.

        if bidPeriod.isFABid() == true {
            lineSortsFileURL = Bundle.main.url(forResource: "LineSortsFA", withExtension: "plist")
        } else if bidPeriod.isFirstRoundBid() {
            lineSortsFileURL = Bundle.main.url(forResource: "LineSorts", withExtension: "plist")
        } else {
            lineSortsFileURL = Bundle.main.url(forResource: "LineSortsRound2", withExtension: "plist")
        }
        // Load line sorting categories from the selected file.

        let path:String = lineSortsFileURL!.path
        let dictionary = NSDictionary(contentsOfFile: path)
        lineSortCategories = NSArray(array: dictionary![kLineSortsSortsKey] as! NSArray)
        // If the Swaptimizer is enabled, merge additional sorting categories.

        if bidPeriod.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) {
//            if bidPeriod.isFABid() == true {
//                let swaptimizerFileURL: URL? = Bundle.main.url(forResource: "LineSortsFaVacation", withExtension: "plist")
//                let swaptimizerFileURLString:String = swaptimizerFileURL!.path
//                let swapSortsDictionary = NSDictionary(contentsOfFile: swaptimizerFileURLString)
//                let swapSortsArray: NSArray = swapSortsDictionary?["sorts"] as! NSArray
//                lineSortCategories = swapSortsArray.addingObjects(from: lineSortCategories as! [Any]) as NSArray
//            }else{
                let swaptimizerFileURL: URL? = Bundle.main.url(forResource: "LineSortsSwaptimizer", withExtension: "plist")
                let swaptimizerFileURLString:String = swaptimizerFileURL!.path
                let swapSortsDictionary = NSDictionary(contentsOfFile: swaptimizerFileURLString)
                let swapSortsArray: NSArray = swapSortsDictionary?["sorts"] as! NSArray
                lineSortCategories = swapSortsArray.addingObjects(from: lineSortCategories as! [Any]) as NSArray
//            }
        }
        if bidPeriod.faVacationStatus?.intValue ==  BIFaVacationStatus.enabled.rawValue {
            let swaptimizerFileURL: URL? = Bundle.main.url(forResource: "LineSortsFaVacation", withExtension: "plist")
            let swaptimizerFileURLString:String = swaptimizerFileURL!.path
            let swapSortsDictionary = NSDictionary(contentsOfFile: swaptimizerFileURLString)
            let swapSortsArray: NSArray = swapSortsDictionary?["sorts"] as! NSArray
            lineSortCategories = swapSortsArray.addingObjects(from: lineSortCategories as! [Any]) as NSArray
        }
        return lineSortCategories!
    }
    
    @objc func sortHighlightsTrips() -> Bool {
        if let catValue = self.category {
            let category = Int(truncating: catValue)
            let type = Int(truncating: self.type!)
            if category == BILineSortCategory.BICitiesLineSortCategory.rawValue {
                if BICityLineSortType.BICitiesLineSortTypeNonConusLegs.rawValue == type {
                    return false
                }
                else if BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue == type ||  BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue == type ||
                            BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue == type ||
                            BICityLineSortType.BICitiesLineSortTypeIntl.rawValue == type ||
                            BICityLineSortType.BICitiesLineSortTypeAll.rawValue == type ||
                            BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue == type {
                    return true
                }
                else {
                    if self.city == nil {
                        return false
                    }
                    else {
                        return true
                    }
                }
            }
            else if BILineSortCategory.BICommutingLineSortCategory.rawValue == category || BILineSortCategory.BIDeadheadsLineSortCategory.rawValue == category {
                return true
            }
            else if BILineSortCategory.BIPassesThruBaseLineSortCategory.rawValue == category {
                return true
            }
            else if BILineSortCategory.BICommutabilityLineSortCategory.rawValue == category {
                return false
            }
            else {
                return false
            }
        }
        return false
    }
    
    public var setCity: String? {
        set(newX){
            // Bid period must be set before setting city so that the bid period is
            // available to provide the line key path for sorting.
            //ZAssert(nil != self.bidPeriod, @"Bid period must be set before setting city.");
            // Update key path fom bid period. Raise an exception if this not a city
            // line sort.
            if let category = category {
                if BILineSortCategory.BICitiesLineSortCategory.rawValue != Int(truncating: category) && BILineSortCategory.BIDeadheadsLineSortCategory.rawValue != Int(truncating: category) {
                    print("City property can be set only for line sorts with category equal to BICitiesLineSortCategory or BIDeadheadsLineSortCategory")
                }
            }
            willChangeValue(forKey: "city")
            self.city = newX
            didChangeValue(forKey: "city")
            keyPath = bidPeriod?.lineSortKeyForCityLineSort(cityLineSort: self, city: newX!)
        }
        
        get {
            return temX
        }
    }
    
    func predicate() -> NSPredicate? {
        var format: NSPredicate?
        var category = self.category?.intValue
        var type = self.type?.intValue
        if (BILineSortCategory.BICitiesLineSortCategory.rawValue == category) {
            if (BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue == type || BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue == type || BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue == type || BICityLineSortType.BICitiesLineSortTypeIntl.rawValue == type || BICityLineSortType.BICitiesLineSortTypeAll.rawValue == type || BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue == type) {
                let formatString = """
                SUBQUERY(days, $DAY, (($DAY.info.city != %@ && $DAY.info.city IN $SET) && $DAY.trip.dropForFiltersSorts == 0)).@count > 0
                """
                format = NSPredicate(format: formatString, (self.bidPeriod?.base)!)
                var filterVars = self.variables?.mutableCopy() as? [String: Any] ?? [:]
                if filterVars["SET"] == nil {
                    let set = NSSet(array: self.selectedRegionalCities())
                    filterVars["SET"] = set
                    self.variables = filterVars as NSDictionary
                }
                format = format?.withSubstitutionVariables((self.variables as? [String : Any])!)
            }
            else {
                let city = self.city ?? ""
                if city.isEmpty {
                    return nil
                }
                // Overnight city predicate.
                if (BICityLineSortType.BIOvernightCityLineSortType.rawValue == type) {
                    if city == self.bidPeriod?.base {
                        return nil
                    }
                    let formatString = String(format:
                        "SUBQUERY(days, $DAY, $DAY.info.city == '%@' && $DAY.trip.dropForFiltersSorts == 0).@count > 0",
                        self.city ?? "")
                    format = NSPredicate(format: formatString)

                }
                // Leg city predicate.
                else {
                    format = NSPredicate(
                        format: "SUBQUERY(legs, $LEG, $LEG.info.arriveCity == %@ && $LEG.info.lastLegOfTrip == NO && $LEG.trip.dropForFiltersSorts == 0).@count > 0", self.city ?? "")
                }
            }
        }
        else if BILineSortCategory.BICommutingLineSortCategory.rawValue == category {
            format = NSPredicate(format: "info.isFullyCommutable == 1")
        }
        else if BILineSortCategory.BIDeadheadsLineSortCategory.rawValue == category && BIDeadheadLineSortType.BIDeadheadSortType.rawValue == type {
            format = NSPredicate(format: "SUBQUERY(legs, $LEG, $LEG.info.isDeadhead == YES && $LEG.trip.dropForFiltersSorts == 0).@count > 0")
        }
        else if ((BILineSortCategory.BIDeadheadsLineSortCategory.rawValue == category) &&  (BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue == type || BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue == type || BIDeadheadLineSortType.BIDeadheadAtBothSortType.rawValue == type)) {
            let city = self.city ?? ""
            if city.isEmpty {
                if BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue == type {
                    format = NSPredicate(format: "SUBQUERY(legs, $LEG, ($LEG.info.firstLegOfTrip == YES && $LEG.info.isDeadhead == YES && $LEG.trip.dropForFiltersSorts == 0)).@count > 0")
                }
                else if BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue == type {
                    format = NSPredicate(format: "SUBQUERY(legs, $LEG, ($LEG.info.lastLegOfTrip == YES && $LEG.info.isDeadhead == YES && $LEG.trip.dropForFiltersSorts == 0)).@count > 0")
                }
                else {
                    format = NSPredicate(format:
                        "SUBQUERY(legs, $LEG, ($LEG.trip.dropForFiltersSorts == 0 && (($LEG.info.firstLegOfTrip == 1 && $LEG.info.isDeadhead == 1) || ($LEG.info.lastLegOfTrip == 1 && $LEG.info.isDeadhead == 1)))).@count > 0"
                    )
                }
            }
            else if BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue == type {
                format = NSPredicate(format: "SUBQUERY(legs, $LEG, ($LEG.info.firstLegOfTrip == 1 && $LEG.trip.dropForFiltersSorts == 0 && $LEG.info.isDeadhead == 1 && $LEG.info.arriveCity == %@)).@count > 0", city)
            }
            else if BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue == type {
                format = NSPredicate(format: "SUBQUERY(legs, $LEG, ($LEG.info.lastLegOfTrip == 1 && $LEG.trip.dropForFiltersSorts == 0 && $LEG.info.isDeadhead == 1 && $LEG.info.departCity == %@)).@count > 0", city)
            }
            else {
                format = NSPredicate(format: "SUBQUERY(legs, $LEG, ($LEG.trip.dropForFiltersSorts == 0 && (($LEG.info.firstLegOfTrip == 1 && $LEG.info.isDeadhead == 1 && $LEG.info.arriveCity == %@) || ($LEG.info.lastLegOfTrip == 1 && $LEG.info.isDeadhead == 1 && $LEG.info.departCity == %@)))).@count > 0", city, city)
            }
        }
        else if BILineSortCategory.BIPassesThruBaseLineSortCategory.rawValue == category || BIPassesThruBaseLineSortType.BIPassesThruBaseLineSortTypeMidTrip.rawValue == type {
            format = NSPredicate(format: "info.containsMidTripPTB == 1 AND dropForFiltersSorts == 0")
        }
        return format
    }
    
    func selectedRegionalCities() -> [String] {
        var cities: [String]? = []
        let type = self.type?.intValue
        if (BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue == type) {
            cities = UserDefaults.standard.object(forKey: kCBSelectedEastCoastCities) as? [String]
        }
        else if (BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue == type) {
            cities = UserDefaults.standard.object(forKey: kCBSelectedWestCoastCities) as? [String]
        }
        else if (BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue == type) {
            cities = UserDefaults.standard.object(forKey: kCBSelectedNonConusCities) as? [String]
        }
        else if (BICityLineSortType.BICitiesLineSortTypeIntl.rawValue == type) {
            cities = UserDefaults.standard.object(forKey: kCBSelectedInternationalCities) as? [String]
        }
        else if (BICityLineSortType.BICitiesLineSortTypeAll.rawValue == type) {
            cities = UserDefaults.standard.object(forKey: kCBSelectedAllCities) as? [String]
        }
        else if (BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue == type) {
            cities = UserDefaults.standard.object(forKey: kCBSelectedHawaiiCities) as? [String]
        }
        return cities ?? []
    }
    
    func deHighlightTrips() {
        let fetchRequest: NSFetchRequest<BITrip> = BITrip.fetchRequest()
        if self.predicate() != nil {
            let highlightPredicate = NSPredicate(format: "highlightCount > 0")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [highlightPredicate, self.predicate()!])
        }
        else {
            return
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "info.number", ascending: true)]
        let tripFetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        tripFetchController.delegate = self
        do {
            try tripFetchController.performFetch()
        }
        catch {
            fatalError("Failed to perform fetch: \(error)")
        }
        for trip in tripFetchController.fetchedObjects ?? [] {
            trip.highlightCount = (Int(truncating: trip.highlightCount!) - 1 as NSNumber)
        }
    }
    
    func highlightTrips() {
    
        let fetchRequest: NSFetchRequest<BITrip> = BITrip.fetchRequest()
        if (self.predicate() != nil) {
            fetchRequest.predicate = self.predicate()
        }
        else {
            return
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "info.number", ascending: true)]
        let tripFetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        tripFetchController.delegate = self
        do {
            try tripFetchController.performFetch()
            for trip in tripFetchController.fetchedObjects ?? [] {
                trip.highlightCount = (Int(truncating: trip.highlightCount!) + 1 as NSNumber)
            }
        }
        catch {
            fatalError("Failed to perform fetch: \(error)")
        }
    }
    
    func saveSelectedCities(_ selectedCities: [Any]) {
        if BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue == Int(truncating: type!) {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedEastCoastCities)
        }
        else if BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue == Int(truncating: type!) {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedWestCoastCities)
        }
        else if BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue == Int(truncating: type!) {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedNonConusCities)
        }
        else if BICityLineSortType.BICitiesLineSortTypeIntl.rawValue == Int(truncating: type!) {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedInternationalCities)
        }
        else if BICityLineSortType.BICitiesLineSortTypeAll.rawValue == Int(truncating: type!) {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedAllCities)
        }
        else if BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue == Int(truncating: type!) {
            UserDefaults.standard.set(selectedCities, forKey: kCBSelectedHawaiiCities)
        }
        
    }
    
    func loadLineSort(pSort: CBPresetLineSort) {
        self.category = pSort.category
        self.type = pSort.type
        self.name = pSort.name
        self.keyPath = pSort.keyPath
        self.ascending = pSort.ascending
        self.isMutable = pSort.isMutable
        self.expression = pSort.expression
        self.order = pSort.order
        self.abbreviation = pSort.abbreviation
        if pSort.variables != nil {
            self.variables = pSort.variables as NSDictionary?
        }
    }
    
    func loadSyncSort(pSort: CBSyncSort) {
        self.category = pSort.category
        self.type = pSort.type
        self.name = pSort.name
        self.keyPath = pSort.keyPath
        self.ascending = pSort.ascending
        self.isMutable = pSort.isMutable
        self.expression = pSort.expression
        self.order = pSort.order
        self.abbreviation = pSort.abbreviation
        if pSort.variables != nil {
            self.variables = pSort.variables as NSDictionary?
        }
    }
    
    static func configureMonthDayFilter(_ indices: NSMutableArray) -> [String: Any] {
        var variables: [String: Any] = ["DAYS_OFF_MONTH_BITS": UInt64(0)]

        for case let index as NSNumber in indices {
            var monthBits = variables["DAYS_OFF_MONTH_BITS"] as? UInt64 ?? 0
            let mask: UInt64 = 1 << UInt64(index.intValue)
            monthBits |= mask
            variables["DAYS_OFF_MONTH_BITS"] = monthBits
        }

        return variables
    }


}

var temX: String = String()
