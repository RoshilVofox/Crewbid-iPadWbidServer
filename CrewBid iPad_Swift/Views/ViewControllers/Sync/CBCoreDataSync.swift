//
//  CBCoreDataSync.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 14/10/25.
//

import UIKit
import CoreData

class CBCoreDataSync: NSObject {
    
    var managedObjectContext: NSManagedObjectContext?
    var bidPeriod: BIBidPeriod?
    
    static func syncFilename(withBidPeriod: BIBidPeriod) -> String? {
        let presetsFileName = "CBState.plist"
        return presetsFileName
    }
    
    static func syncDocumentDirectory() -> URL? {
        // Presets URL
        let presetsURL = BIBidInfo().documentsDirectory().appendingPathComponent("StateContent")
        
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: presetsURL, withIntermediateDirectories: true, attributes: nil)
            return presetsURL
        } catch {
            return nil
        }
    }
    
    func fetchStatePlistForSync(completion: @escaping (Bool) -> Void) {
        let pListArray = CBCoreDataSync.openSyncedFromFile(bidPeriod: self.bidPeriod!)
        self.importSyncFiles(arrSync: (pListArray![0] as? NSMutableArray)!)
        let arrLines = pListArray?.value(forKey: "lines") as? NSMutableArray
        self.importLines(arrLines: arrLines!)
        let dictInsertionPoint = pListArray?.value(forKey: "insertionPoint") as? NSMutableArray
        self.importInsertionPoints(details: dictInsertionPoint!)
        let dictOvernightBulkDetails = pListArray?.value(forKey: "OvernightBulkCities") as? NSMutableArray
        self.importOvernightBulkDetails(details: dictOvernightBulkDetails!)
        let dictVacationDetails = pListArray?.value(forKey: "VacationDetails") as? NSDictionary
        let isWbidMaxOn = (dictVacationDetails?["IsWbidMaxOn"] as? [NSNumber])?[0]
        let isSwaptimizerOn = (dictVacationDetails?["IsSwaptimizerOn"] as? [NSNumber])?[0]
        let isEomOn = (dictVacationDetails?["IsEomOn"] as? [NSNumber])?[0]
        let isFAVacationOn = (dictVacationDetails?["isFAVacationOn"] as? [NSNumber])?[0]
        if isWbidMaxOn?.intValue == 1 || isSwaptimizerOn?.intValue == 1 || isEomOn?.intValue == 1 || isFAVacationOn?.intValue == 1 {
            completion(true)
        }
        else {
            if (self.bidPeriod!.isWbidMaxOn?.intValue == 1 || self.bidPeriod!.isSwaptimizerOn?.intValue == 1 || self.bidPeriod!.isEomOn?.intValue == 1 || self.bidPeriod!.isFAVacationOn?.intValue == 1) {
                self.removeVacationsIfExists()
            }
            else {
                completion(true)
            }
        }
    }
    
    static func openSyncedFromFile(bidPeriod: BIBidPeriod) -> NSMutableArray? {
        // Get the file path for the given bid period
        let path = self.syncDocumentFilePath(bidPeriod: bidPeriod)
        // Read data from the file
        guard let result = FileManager.default.contents(atPath: path) else {
            return nil
        }
        // Safely unarchive using the modern API
        do {
            if let presets = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSMutableArray.self, from: result) {
                return presets
            }
        } catch {
            print("❌ Failed to unarchive presets: \(error)")
        }
        return nil
    }

    
    static func syncDocumentFilePath(bidPeriod: BIBidPeriod) -> String {
        let syncDirectoryURL = self.syncDocumentDirectory()
        let syncFileName = self.syncFilename(withBidPeriod: bidPeriod)
        let presetsDocument = syncDirectoryURL?.appendingPathComponent(syncFileName!).path
        return presetsDocument ?? ""
    }
    
    func importSyncFiles(arrSync: NSMutableArray) {
//        MARK: 362 need to check becuase there is some diffrence
        let sync = arrSync.firstObject as? CBSync
        var tempRule: CBSyncFilter?
        let valuesArray = NSMutableArray()
        // Reset the trip highlight count
        BITrip.resetTripHighlightCount(in: self.managedObjectContext!)
        // Delete all old filters and sorts
        // FILTERS FETCH
        let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true), NSSortDescriptor(key: "type", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
        let result = try? self.managedObjectContext!.fetch(fetchRequest)
        for data in result ?? [] {
            self.managedObjectContext!.delete(data)
        }
        
        // SORT FETCH
        let sortFetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        sortFetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        sortFetchRequest.predicate = NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
        let sortResult = try? self.managedObjectContext!.fetch(sortFetchRequest)
        for data in sortResult ?? [] {
            self.managedObjectContext!.delete(data)
        }
        
        //Delete the datas from Commutability entity
        let commutabilityFetch: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        let commuteResult = try? self.managedObjectContext!.fetch(commutabilityFetch)
        for data in commuteResult ?? [] {
            self.managedObjectContext!.delete(data)
        }
        
        //Delete the datas from commute Time
        let commuteTimeFetch: NSFetchRequest<CommuteTime> = CommuteTime.fetchRequest()
        let commuteTimeResult = try? self.managedObjectContext!.fetch(commuteTimeFetch)
        for data in commuteTimeResult ?? [] {
            self.managedObjectContext!.delete(data)
        }
        
        //Setting commutability properties to zero while deleting the sort.
        let lineFetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        let lineResult = try? self.managedObjectContext!.fetch(lineFetchRequest)
        for line in lineResult ?? [] {
            line.totalCommutes = 0
            line.commutableBacks = 0
            line.commutableFronts = 0
            line.commutabilityFront = 0
            line.commutabilityBack = 0
            line.commutabilityOverall = 0
        }
        try? self.managedObjectContext!.save()
        
        // Add filters from preset
        var isCommutabilityFilter = false
        var isCommutabilitySort = false
        
        for case let pRule as CBSyncFilter in sync?.filterRules ?? [] {
            let rule = BIFilterRule(context: self.managedObjectContext!)
            rule.loadFilterSync(pRule: pRule)
            if pRule.category?.intValue == BIFilterRuleCategory.BIDaysOfMonthFilterRuleCategory.rawValue {
                
            }
            
            else if (pRule.category?.intValue == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue && (pRule.type?.intValue == BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue || pRule.type?.intValue == BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue || pRule.type?.intValue ==  BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue || pRule.type?.intValue ==  BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue || pRule.type?.intValue ==  BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue || pRule.type?.intValue ==  BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue)) {
                let filterVars = pRule.variables
                let selectedCities = filterVars!["SET"] as? [Any]
                rule.saveSelectedCities(selectedCities!)
            }
            
            else if pRule.category?.intValue == BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue {
                var filterVars = pRule.variables as? [String: Any]
                if filterVars!["SET"] == nil {
                    let tempSet = NSSet()
                    filterVars!["SET"] = tempSet
                    rule.variables = filterVars as? NSDictionary
                }
            }
            
            else if pRule.category?.intValue == BIFilterRuleCategory.BICommutingFilterRuleCategory.rawValue {
                // Load the default presets
                let defaultCommuteTimes = UserDefaults.standard.array(forKey: kCBDefaultCommutingTimesKey)
                if (defaultCommuteTimes != nil) {
                    let monThursDept = defaultCommuteTimes![0] as! Int
                    let monThursRet = defaultCommuteTimes![1] as! Int
                    let friDept = defaultCommuteTimes![2] as! Int
                    let friRet = defaultCommuteTimes![3] as! Int
                    let satDept = defaultCommuteTimes![4] as! Int
                    let satRet = defaultCommuteTimes![5] as! Int
                    let sunDept = defaultCommuteTimes![6] as! Int
                    let sunRet = defaultCommuteTimes![7] as! Int
                    var variables = pRule.variables as? [String: Any]
                    
                    if monThursDept > -1 {
                        variables![BIFilterRuleMonThursDepartTimeVariablesKey] = monThursDept
                    }
                    else {
                        variables![BIFilterRuleMonThursDepartTimeVariablesKey] = -1
                    }
                    if friDept > -1 {
                        variables![BIFilterRuleFriDepartTimeVariablesKey] = friDept
                    }
                    else {
                        variables![BIFilterRuleFriDepartTimeVariablesKey] = -1
                    }
                    if satDept > -1 {
                        variables![BIFilterRuleSatDepartTimeVariablesKey] = satDept
                    }
                    else {
                        variables![BIFilterRuleSatDepartTimeVariablesKey] = -1
                    }
                    if sunDept > -1 {
                        variables![BIFilterRuleSunDepartTimeVariablesKey] = sunDept
                    }
                    else {
                        variables![BIFilterRuleSunDepartTimeVariablesKey] = -1
                    }
                    if monThursRet < 3000 {
                        variables![BIFilterRuleMonThursReturnTimeVariablesKey] = monThursRet
                    }
                    else {
                        variables![BIFilterRuleMonThursReturnTimeVariablesKey] = 3000
                    }
                    if friRet < 3000 {
                        variables![BIFilterRuleFriReturnTimeVariablesKey] = friRet
                    }
                    else {
                        variables![BIFilterRuleFriReturnTimeVariablesKey] = 3000
                    }
                    if satRet < 3000 {
                        variables![BIFilterRuleSatReturnTimeVariablesKey] = satRet
                    }
                    else {
                        variables![BIFilterRuleSatReturnTimeVariablesKey] = 3000
                    }
                    if sunRet < 3000 {
                        variables![BIFilterRuleSunReturnTimeVariablesKey] = sunRet
                    }
                    else {
                        variables![BIFilterRuleSunReturnTimeVariablesKey] = 3000
                    }
                    pRule.variables = variables as? NSDictionary
                }
            }
            
            else if pRule.category?.intValue == BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue {
                isCommutabilityFilter = true
                var filterVars = pRule.variables as? [String: Any]
                if filterVars!["SET"] == nil {
                    let tempSet = NSSet()
                    filterVars!["SET"] = tempSet
                    rule.variables = filterVars as? NSDictionary
                }
                let objcommutability = Commutability(context: self.managedObjectContext!)
                objcommutability.thirdCellValue = sync?.commutabilityFilterDetails["thirdCellValue"] as? NSNumber
                objcommutability.secondCellValue = sync?.commutabilityFilterDetails["secondCellValue"] as? NSNumber
                objcommutability.commutableType = CommutabilityType.filter.rawValue as NSNumber
                objcommutability.city = sync?.commutabilityFilterDetails["city"] as? String
                objcommutability.checkInTime = sync?.commutabilityFilterDetails["checkInTime"] as? NSNumber
                objcommutability.connectTime = sync?.commutabilityFilterDetails["connectTime"] as? NSNumber
                objcommutability.baseTime = sync?.commutabilityFilterDetails["baseTime"] as? NSNumber
                objcommutability.type = sync?.commutabilityFilterDetails["type"] as? NSNumber
                objcommutability.value = sync?.commutabilityFilterDetails["value"] as? NSNumber
                objcommutability.weight = sync?.commutabilityFilterDetails["weight"] as? NSNumber
                //Import commute time details
                for i in 0 ..< (sync?.commuteTimeDetails.count ?? 0) {
                    autoreleasepool {
                        let objCommuteTimeImportFilter = CommuteTime(context: self.managedObjectContext!)
                        let details = sync?.commuteTimeDetails[i] as? [String: Any]
                        objCommuteTimeImportFilter.bidDay = details?["bidDay"] as? Date
                        objCommuteTimeImportFilter.bidDayStringValue = details?["bidDayStringValue"] as? String
                        objCommuteTimeImportFilter.earliestArrivel = details?["earliestArrivel"] as? Date
                        objCommuteTimeImportFilter.latestDeparture = details?["latestDeparture"] as? Date
                        objCommuteTimeImportFilter.type = details?["type"] as? NSNumber
                    }
                }
                try? self.managedObjectContext!.save()
            }
            if rule.ruleHighlightsTrips() {
                rule.highlightTrips()
            }
        }
        // Add sorts from preset
        for case let pSort as CBSyncSort in sync?.lineSorts ?? [] {
            let sort = BILineSort(context: self.managedObjectContext!)
            sort.loadSyncSort(pSort: pSort)
            sort.bidPeriod = self.bidPeriod!
            if (sort.category?.intValue == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue && (sort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue || sort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue || sort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtBothSortType.rawValue )) {
                var deadheadCitiesSet = NSMutableSet()
                var alertMsg = ""
                if sort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue {
                    deadheadCitiesSet = (self.bidPeriod?.deadheadAtStartCities?.value(forKey: "city") as? NSMutableSet)!
                    alertMsg = "at start to"
                }
                else if sort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue {
                    deadheadCitiesSet = (self.bidPeriod?.deadheadAtEndCities?.value(forKey: "city") as? NSMutableSet)!
                    alertMsg = "at end from"
                }
                else {
                    if let startCities = self.bidPeriod!.deadheadAtStartCities?.value(forKey: "city") as? NSSet,
                       let endCities = self.bidPeriod!.deadheadAtEndCities?.value(forKey: "city") as? NSSet {
                        
                        deadheadCitiesSet = startCities.mutableCopy() as! NSMutableSet
                        deadheadCitiesSet.union(endCities as! Set<AnyHashable>)
                    }
                    alertMsg = "at either from/to"
                }
                if deadheadCitiesSet.contains(pSort.city) {
                    sort.city = pSort.city
                }
                else {
                    AlertService.showAlertForTopVC(title: "Deadhead City Not Found", message: "This month's lines do not contain deadheads \(alertMsg) \(String(describing: pSort.city))")
                }
            }
            else if sort.category?.intValue == BILineSortCategory.BICitiesLineSortCategory.rawValue {
                if (BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue == sort.type?.intValue || BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue == sort.type?.intValue || BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue == sort.type?.intValue || BICityLineSortType.BICitiesLineSortTypeAll.rawValue == sort.type?.intValue || BICityLineSortType.BICitiesLineSortTypeIntl.rawValue == sort.type?.intValue || BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue == sort.type?.intValue) {
                    let filterVars = sort.variables
                    let selectedCities = filterVars?["SET"] as? [Any]
                    sort.saveSelectedCities(selectedCities!)
                }
                else if pSort.city != nil && pSort.city != "" {
                    sort.city = pSort.city
                }
            }
            else if sort.category?.intValue == BILineSortCategory.BICommutingLineSortCategory.rawValue {
                sort.keyPath = sort.bidPeriod?.lineSortKey(forCommute: sort)
            }
            else if sort.category?.intValue == BILineSortCategory.BIDaysOffLineSortCategory.rawValue {
                sort.keyPath = sort.bidPeriod?.lineSortKeyForDaysOff(lineSort: sort)
            }
            else if sort.category?.intValue == BILineSortCategory.BIDaysWorkLineSortCategory.rawValue {
                sort.keyPath = sort.bidPeriod?.lineSortKeyForDaysWork(lineSort: sort)
            }
            else if sort.category?.intValue == BILineSortCategory.BIDaysTripStartSortCategory.rawValue {
                sort.keyPath = sort.bidPeriod?.lineSortKeyForTripStartDays(lineSort: sort)
            }
            else if sort.category?.intValue == BILineSortCategory.BICommutabilityLineSortCategory.rawValue {
                var isCommutabilitySort = true
                let objcommutability = Commutability(context: self.managedObjectContext!)
                objcommutability.thirdCellValue = sync?.commutabilitySortDetails["thirdCellValue"] as? NSNumber
                objcommutability.secondCellValue = sync?.commutabilitySortDetails["secondCellValue"] as? NSNumber
                objcommutability.commutableType = CommutabilityType.sort.rawValue as NSNumber
                objcommutability.city = sync?.commutabilitySortDetails["city"] as? String
                objcommutability.checkInTime = sync?.commutabilitySortDetails["checkInTime"] as? NSNumber
                objcommutability.connectTime = sync?.commutabilitySortDetails["connectTime"] as? NSNumber
                objcommutability.baseTime = sync?.commutabilitySortDetails["baseTime"] as? NSNumber
                objcommutability.type = sync?.commutabilitySortDetails["type"] as? NSNumber
                objcommutability.value = sync?.commutabilitySortDetails["value"] as? NSNumber
                objcommutability.weight = sync?.commutabilitySortDetails["weight"] as? NSNumber
                //Import commute time details
                for i in 0 ..< (sync?.commuteTimeDetails.count ?? 0) {
                    autoreleasepool {
                        let objCommuteTimeImportFilter = CommuteTime(context: self.managedObjectContext!)
                        let details = sync?.commuteTimeDetails[i] as? [String: Any]
                        objCommuteTimeImportFilter.bidDay = details?["bidDay"] as? Date
                        objCommuteTimeImportFilter.bidDayStringValue = details?["bidDayStringValue"] as? String
                        objCommuteTimeImportFilter.earliestArrivel = details?["earliestArrivel"] as? Date
                        objCommuteTimeImportFilter.latestDeparture = details?["latestDeparture"] as? Date
                        objCommuteTimeImportFilter.type = details?["type"] as? NSNumber
                    }
                }
                try? self.managedObjectContext!.save()
            }
            if sort.sortHighlightsTrips() {
                sort.highlightTrips()
            }
        }
        if isCommutabilityFilter || isCommutabilitySort {
            NotificationCenter.default.post(name: NSNotification.Name("refreshWorkBlock"), object: self)
        }
        
        if self.managedObjectContext!.hasChanges {
            try? self.managedObjectContext?.save()
        }
    }
    
    func importLines(arrLines: NSMutableArray) {
        let linesFetch: NSFetchRequest<BILine> = BILine.fetchRequest()
        linesFetch.predicate = NSPredicate(format: "bidOrder > 0")
        linesFetch.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
        let results = try? self.managedObjectContext!.fetch(linesFetch)
        
        for line in results ?? [] {
            if (self.bidPeriod!.isFABid() && (line.faBidLineMrt?.boolValue == true || line.faBidLineReserve?.boolValue == true)) {
                if line.faBidLineMrt?.boolValue == true {
                    self.bidPeriod?.faReserveLineExists = false
                }
                else {
                    self.bidPeriod?.faMrtLineExists = false
                }
                self.bidPeriod?.managedObjectContext?.delete(line)
            }
            else {
                if line.isFrozen?.boolValue == true {
                    line.isFrozen = false
                }
                line.removeFromBidLines()
            }
            line.userFlagType = CBUserFlagType.none.rawValue as NSNumber
        }
        
        // Reset all user flags
        linesFetch.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        linesFetch.predicate = NSPredicate(format: "userFlagType > 0")
        let flaggedLines = try? self.managedObjectContext!.fetch(linesFetch)
        for line in flaggedLines ?? [] {
            line.userFlagType = CBUserFlagType.none.rawValue as NSNumber
        }
        
        // set state file values to line.
        if self.bidPeriod!.isFABid() {
            var dicBidDetails = [String: Any]()
            for case let line as BILine in arrLines {
                var dicDetails = [String: Any]()
                dicDetails["bidOrder"] = "\(String(describing: line.bidOrder))"
                dicDetails["faPosition"] = "\(String(describing: line.faPosition))"
                if line.markerTitle != nil {
                    dicDetails["markerTitle"] = line.markerTitle
                }
                dicDetails["isFrozen"] = "\(String(describing: line.isFrozen))"
                dicDetails["faBidLineReserve"] = "\(String(describing: line.faBidLineReserve))"
                dicDetails["faBidLineMrt"] = "\(String(describing: line.faBidLineMrt))"
                dicDetails["isTrashed"] = "\(String(describing: line.isTrashed))"
                dicBidDetails["\(String(describing: line.number)),\(String(describing: line.faPosition))"] = dicDetails
                
                if line.faBidLineReserve?.intValue == 1 {
                    self.bidPeriod?.faReserveLineExists = true
                    let reserveLine = BILine(context: self.managedObjectContext!)
                    reserveLine.faBidLineReserve = true
                    reserveLine.number = 1000
                    reserveLine.bidOrder = line.bidOrder
                    reserveLine.markerTitle = line.markerTitle
                    reserveLine.isFrozen = line.isFrozen
                    reserveLine.userFlagType = line.userFlagType
                }
                
                if line.faBidLineMrt?.intValue == 1 {
                    let reserveLine = BILine(context: self.managedObjectContext!)
                    reserveLine.faBidLineReserve = true
                    reserveLine.number = 1000
                    reserveLine.bidOrder = line.bidOrder
                    reserveLine.markerTitle = line.markerTitle
                    reserveLine.isFrozen = line.isFrozen
                    reserveLine.userFlagType = line.userFlagType
                }
            }
            
            for case let line as BILine in self.bidPeriod!.lines! {
                if dicBidDetails["\(String(describing: line.number)),\(String(describing: line.faPosition))"] != nil {
                    let dicDetails = dicBidDetails["\(String(describing: line.number)),\(String(describing: line.faPosition))"] as? [String: Any]
                    if let bidOrder = dicDetails?["bidOrder"] as? Int {
                        line.bidOrder = NSNumber(value: bidOrder)
                    }
                    if let faPosition = dicDetails?["faPosition"] as? Int {
                        line.faPosition = NSNumber(value: faPosition)
                    }
                    if let isFrozen = dicDetails?["isFrozen"] as? Int {
                        line.isFrozen = NSNumber(value: isFrozen)
                    }
                    if let faBidLineReserve = dicDetails?["faBidLineReserve"] as? Bool {
                        line.faBidLineReserve = NSNumber(value: faBidLineReserve)
                    }
                    if let faBidLineMrt = dicDetails?["faBidLineMrt"] as? Bool {
                        line.faBidLineMrt = NSNumber(value: faBidLineMrt)
                    }
                    if let isTrashed = dicDetails?["isTrashed"] as? Bool {
                        line.isTrashed = NSNumber(value: isTrashed)
                    }
                    if let userFlagType = dicDetails?["userFlagType"] as? Int {
                        line.userFlagType = NSNumber(value: userFlagType)
                    }
                    if dicDetails?["markerTitle"] != nil {
                        line.markerTitle = dicDetails!["markerTitle"] as? String
                    }
                }
                if line.isTrashed?.intValue == 1 {
                    var objDeleteArray = self.bidPeriod?.lastTrashedArray?.mutableCopy() as? NSMutableArray
                    objDeleteArray?.add("\(String(describing: line.number))")
                    // Remove duplicates while preserving order
                    let uniqueArray = Array(NSOrderedSet(array: objDeleteArray as! [Any])) as NSArray
                    self.bidPeriod!.lastTrashedDetails = uniqueArray.mutableCopy() as? NSMutableArray
                }
            }
            try? self.managedObjectContext!.save()
        }
        else {
//            Pilot
            let bidLineFetch: NSFetchRequest<BILine> = BILine.fetchRequest()
            let results = try? self.managedObjectContext!.fetch(bidLineFetch)
            for i in 0 ..< arrLines.count {
                let dicFilter = arrLines[i] as? [String: Any]
                let lineNumber = NSNumber(value: (dicFilter!["number"] as? Int)!)
                for line in results ?? [] {
                    if line.number?.intValue == lineNumber.intValue {
                        if let bidOrder = dicFilter?["bidOrder"] as? Int {
                            line.bidOrder = NSNumber(value: bidOrder)
                        }
                        if let isFrozen = dicFilter?["isFrozen"] as? Int {
                            line.isFrozen = NSNumber(value: isFrozen)
                        }
                        if let isTrashed = dicFilter?["isTrashed"] as? Int {
                            line.isTrashed = NSNumber(value: isTrashed)
                        }
                        if let userFlagType = dicFilter?["userFlagType"] as? Int {
                            line.userFlagType = NSNumber(value: userFlagType)
                        }
                        
                        if line.isTrashed?.intValue == 1 {
                            var objDeleteArray = self.bidPeriod?.lastTrashedArray?.mutableCopy() as? NSMutableArray
                            objDeleteArray?.add("\(String(describing: line.number))")
                            // Remove duplicates while preserving order
                            let uniqueArray = Array(NSOrderedSet(array: objDeleteArray as! [Any])) as NSArray
                            self.bidPeriod!.lastTrashedDetails = uniqueArray.mutableCopy() as? NSMutableArray
                        }
                        if dicFilter?["markerTitle"] != nil {
                            line.markerTitle = dicFilter!["markerTitle"] as? String
                        }
                    }
                }
            }
            try? self.managedObjectContext!.save()
        }
    }
    
    func importInsertionPoints(details: NSMutableArray) {
        //Delete Insertion entity details
        let fetchRequest: NSFetchRequest<BIInsertionPoint> = BIInsertionPoint.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
        let results = try? self.managedObjectContext!.fetch(fetchRequest)
        for point in results ?? [] {
            self.managedObjectContext!.delete(point)
        }
        
        // Save the imported details to entity
        let first = details[0] as? [String: Any]
        if first?.count ?? 0 > 0 {
            let objinsertion = BIInsertionPoint(context: self.managedObjectContext!)
            objinsertion.bidPeriod = self.bidPeriod
            objinsertion.above = first!["above"] as? NSNumber
            objinsertion.index = first!["index"] as? NSNumber
        }
        else {
            let objinsertion = BIInsertionPoint(context: self.managedObjectContext!)
        }
        try? self.managedObjectContext!.save()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func importOvernightBulkDetails(details: NSMutableArray) {
        //Delete OvernightBulk entity details
        let fetchRequest: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
        let reult = try? self.managedObjectContext!.fetch(fetchRequest)
        for bulk in reult ?? [] {
            self.managedObjectContext?.delete(bulk)
        }
        // Save the imported details to entity
        let objOvernight = OvernightBulk(context: self.managedObjectContext!)
        objOvernight.citystatus = details[0] as? NSObject
        try? self.managedObjectContext!.save()
        
        if !(details[0] is NSNull) {
            self.bidPeriod?.isOverNightBulkApplied = "YES"
            let dictAllValues = details[0] as? [String: Any]
            let noArray = (dictAllValues!.filter { $0.value as? String == "1" }.map { $0.key } as? NSArray)!
            let yesArray = (dictAllValues!.filter { $0.value as? String == "2" }.map { $0.key } as? NSArray)!
            CBUtils.overnightBulkRedApply(noArray: noArray)
            CBUtils.overnightBulkGreenApply(yesArray: yesArray)
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    func removeVacationsIfExists() {
        NotificationCenter.default.post(name: NSNotification.Name("RemoveVacationsForSync"), object: self)
    }
}
