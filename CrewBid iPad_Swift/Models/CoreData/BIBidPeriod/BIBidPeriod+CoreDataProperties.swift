//
//  BIBidPeriod+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//
//

import Foundation
import CoreData


var BIBidPeriodEntityName = "BidPeriod"
var BICoverLetterTextFileName = "Cover Letter"
var BISeniorityListTextFileName = "Seniority List"
var BILinesTextFileName = "Lines Text"
var BITripsTextFileName = "Trips Text"
var BIAwardsTextFileName = "Bid Awards"
var BIFaMemoTextFileName = "FA Memo"


extension BIBidPeriod {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BIBidPeriod> {
        return NSFetchRequest<BIBidPeriod>(entityName: "BidPeriod")
    }
    
    @NSManaged public var appVersion: String?
    @NSManaged public var aWeekDays: String?
    @NSManaged public var base: String?
    @NSManaged public var baseLine: NSData?
    @NSManaged public var bidLineNumbers: NSArray?
    @NSManaged public var bidListLineCount: NSNumber?
    @NSManaged public var bidPackageErrorDisplayed: NSNumber?
    @NSManaged public var buddyBidder1: String?
    @NSManaged public var buddyBidder2: String?
    @NSManaged public var bWeekDays: String?
    @NSManaged public var cbFileIntent: String?
    @NSManaged public var cbFileIntentF: String?
    @NSManaged public var cbVacationFiles: NSObject?
    @NSManaged public var cbVacationFilesF: NSObject?
    @NSManaged public var containsCFV: NSNumber?
    @NSManaged public var containsEBG: NSNumber?
    @NSManaged public var containsFvVacay: NSNumber?
    @NSManaged public var containsMissingTripLines: NSNumber?
    @NSManaged public var containsVacay: NSNumber?
    @NSManaged public var coverLetterDisplayed: NSNumber?
    @NSManaged public var crewBidSecretVacation: NSObject?
    @NSManaged public var crewIdentifier: NSNumber?
    @NSManaged public var currentAmPmHerb: NSNumber?
    @NSManaged public var currentDateTime: Date?
    @NSManaged public var cWeekDays: String?
    @NSManaged public var dWeekDays: String?
    @NSManaged public var eomIsNo: String?
    @NSManaged public var eWeekDays: String?
    @NSManaged public var faEomSelectedDate: NSNumber?
    @NSManaged public var faFileIntent: String?
    @NSManaged public var faFileIntentEomOnly: String?
    @NSManaged public var faFileIntentF: String?
    @NSManaged public var faMrtLineExists: NSNumber?
    @NSManaged public var faReserveLineExists: NSNumber?
    @NSManaged public var faVacationFiles: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA1: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA2: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA3: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA4: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA5: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA6: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA7: NSObject?
    @NSManaged public var faVacationFilesFA1: NSObject?
    @NSManaged public var faVacationFilesFA2: NSObject?
    @NSManaged public var faVacationFilesFA3: NSObject?
    @NSManaged public var faVacationStatus: NSNumber?
    @NSManaged public var filteredLineNumbers: NSArray?
    @NSManaged public var firstLineNumber: NSNumber?
    @NSManaged public var fWeekDays: String?
    @NSManaged public var historicSecretUser: NSNumber?
    @NSManaged public var isAllLinesTrashed: NSNumber?
    @NSManaged public var isAwardSortOn: NSNumber?
    @NSManaged public var isBidListSortOn: NSNumber?
    @NSManaged public var isContainVacationLineValues: NSNumber?
    @NSManaged public var isEomFADeafaultDownload: NSNumber?
    @NSManaged public var isEomOn: NSNumber?
    @NSManaged public var isEtopsLinesContainsInBid: NSNumber?
    @NSManaged public var isFAVacationOn: NSNumber?
    @NSManaged public var isFirstRoundPaperBidder: NSNumber?
    @NSManaged public var isHistoric: NSNumber?
    @NSManaged public var isMaxSubScriptionOfEnteredUser: NSNumber?
    @NSManaged public var isMockData: NSNumber?
    @NSManaged public var isNetwrkNotAvailForSeniorityVacParsing: NSNumber?
    @NSManaged public var isOverNightBulkApplied: String?
    @NSManaged public var isQAdata: String?
    @NSManaged public var isReportReleaseFilterApplied: NSNumber?
    @NSManaged public var isSeniorityVacParsingFailed: NSNumber?
    @NSManaged public var isSortBySubmitOn: NSNumber?
    @NSManaged public var isStateFileModifiedToSync: NSNumber?
    @NSManaged public var isSwaptimizerOn: NSNumber?
    @NSManaged public var isVacationRemoved: NSNumber?
    @NSManaged public var isWbidMaxOn: NSNumber?
    @NSManaged public var lastBidDate: Date?
    @NSManaged public var lastTrashedArray: NSObject?
    @NSManaged public var lastTrashedDetails: NSArray?
    @NSManaged public var latestNewsDisplayed: NSNumber?
    @NSManaged public var loadedPresetIdentifier: String?
    @NSManaged public var month: NSNumber?
    @NSManaged public var mRTEnabledForASort: NSNumber?
    @NSManaged public var mRTLineIndexForASort: NSNumber?
    @NSManaged public var myCalEnabled: NSNumber?
    @NSManaged public var myCalEndDate: Date?
    @NSManaged public var myCalStartDate: Date?
    @NSManaged public var numVacations: NSNumber?
    @NSManaged public var onlyContainEOM: String?
    @NSManaged public var overNightBulk: NSObject?
    @NSManaged public var overNightCities: NSArray?
    @NSManaged public var paperBidCount: NSNumber?
    @NSManaged public var paperBidVacArray: NSArray?
    @NSManaged public var positionType: NSNumber?
    @NSManaged public var reservedLineIndexForASort: NSNumber?
    @NSManaged public var reserveEnabledForASort: NSNumber?
    @NSManaged public var round: NSNumber?
    @NSManaged public var secretSwitchOn: String?
    @NSManaged public var selectedSegmentVacType: String?
    @NSManaged public var seniorityNumber: NSNumber?
    @NSManaged public var seniorityVacayAvailable: NSNumber?
    @NSManaged public var stateFileVersion: NSNumber?
    @NSManaged public var stateSyncVersion: NSNumber?
    @NSManaged public var stateUpdatedTime: Date?
    @NSManaged public var submitSortOrder: NSNumber?
    @NSManaged public var submittedBid: String?
    @NSManaged public var swaptimizerIdentifier: NSNumber?
    @NSManaged public var swaptimizerStatus: NSNumber?
    @NSManaged public var userVacationWbidOrCrewBid: String?
    @NSManaged public var vacationDeffArray: NSObject?
    @NSManaged public var vacationName: String?
    @NSManaged public var vacationType: String?
    @NSManaged public var vacayAlertDisplayed: NSNumber?
    @NSManaged public var vactionWeekAlertDisplayed: NSNumber?
    @NSManaged public var wbFileIntent: String?
    @NSManaged public var wbFileIntentF: String?
    @NSManaged public var wbidSecretVacation: NSObject?
    @NSManaged public var wbVacationfile: NSObject?
    @NSManaged public var wbVacationfileF: NSObject?
    @NSManaged public var year: NSNumber?
    @NSManaged public var awardDetails: NSSet?
    @NSManaged public var bidReceipts: NSSet?
    @NSManaged public var commuteTime: NSSet?
    @NSManaged public var deadheadAtEndCities: NSSet?
    @NSManaged public var deadheadAtStartCities: NSSet?
    @NSManaged public var lines: NSSet?
    @NSManaged public var lineSortKeyMaps: NSSet?
    @NSManaged public var lineSorts: NSSet?
    @NSManaged public var textFiles: NSSet?
    @NSManaged public var vacationArrayFromServer: NSSet?
    @NSManaged public var vacations: NSSet?
    @NSManaged public var lineFilters: NSSet?
    @NSManaged public var insertionPoints: NSSet?
    @NSManaged public var awardString: String?
}

// MARK: Generated accessors for awardDetails
extension BIBidPeriod {
    
    @objc(addAwardDetailsObject:)
    @NSManaged public func addToAwardDetails(_ value: AwardDetails)
    
    @objc(removeAwardDetailsObject:)
    @NSManaged public func removeFromAwardDetails(_ value: AwardDetails)
    
    @objc(addAwardDetails:)
    @NSManaged public func addToAwardDetails(_ values: NSSet)
    
    @objc(removeAwardDetails:)
    @NSManaged public func removeFromAwardDetails(_ values: NSSet)
    
}

// MARK: Generated accessors for bidReceipts
extension BIBidPeriod {
    
    @objc(addBidReceiptsObject:)
    @NSManaged public func addToBidReceipts(_ value: BIBidReceipt)
    
    @objc(removeBidReceiptsObject:)
    @NSManaged public func removeFromBidReceipts(_ value: BIBidReceipt)
    
    @objc(addBidReceipts:)
    @NSManaged public func addToBidReceipts(_ values: NSSet)
    
    @objc(removeBidReceipts:)
    @NSManaged public func removeFromBidReceipts(_ values: NSSet)
    
}

// MARK: Generated accessors for commuteTime
extension BIBidPeriod {
    
    @objc(addCommuteTimeObject:)
    @NSManaged public func addToCommuteTime(_ value: CommuteTime)
    
    @objc(removeCommuteTimeObject:)
    @NSManaged public func removeFromCommuteTime(_ value: CommuteTime)
    
    @objc(addCommuteTime:)
    @NSManaged public func addToCommuteTime(_ values: NSSet)
    
    @objc(removeCommuteTime:)
    @NSManaged public func removeFromCommuteTime(_ values: NSSet)
    
}

// MARK: Generated accessors for deadheadAtEndCities
extension BIBidPeriod {
    
    @objc(addDeadheadAtEndCitiesObject:)
    @NSManaged public func addToDeadheadAtEndCities(_ value: BIDeadheadAtEndCity)
    
    @objc(removeDeadheadAtEndCitiesObject:)
    @NSManaged public func removeFromDeadheadAtEndCities(_ value: BIDeadheadAtEndCity)
    
    @objc(addDeadheadAtEndCities:)
    @NSManaged public func addToDeadheadAtEndCities(_ values: NSSet)
    
    @objc(removeDeadheadAtEndCities:)
    @NSManaged public func removeFromDeadheadAtEndCities(_ values: NSSet)
    
}

// MARK: Generated accessors for deadheadAtStartCities
extension BIBidPeriod {
    
    @objc(addDeadheadAtStartCitiesObject:)
    @NSManaged public func addToDeadheadAtStartCities(_ value: BIDeadheadAtStartCity)
    
    @objc(removeDeadheadAtStartCitiesObject:)
    @NSManaged public func removeFromDeadheadAtStartCities(_ value: BIDeadheadAtStartCity)
    
    @objc(addDeadheadAtStartCities:)
    @NSManaged public func addToDeadheadAtStartCities(_ values: NSSet)
    
    @objc(removeDeadheadAtStartCities:)
    @NSManaged public func removeFromDeadheadAtStartCities(_ values: NSSet)
    
}

// MARK: Generated accessors for lines
extension BIBidPeriod {
    
    @objc(addLinesObject:)
    @NSManaged public func addToLines(_ value: BILine)
    
    @objc(removeLinesObject:)
    @NSManaged public func removeFromLines(_ value: BILine)
    
    @objc(addLines:)
    @NSManaged public func addToLines(_ values: NSSet)
    
    @objc(removeLines:)
    @NSManaged public func removeFromLines(_ values: NSSet)
    
}

// MARK: Generated accessors for lineSortKeyMaps
extension BIBidPeriod {
    
    @objc(addLineSortKeyMapsObject:)
    @NSManaged public func addToLineSortKeyMaps(_ value: BILineSortKeyMap)
    
    @objc(removeLineSortKeyMapsObject:)
    @NSManaged public func removeFromLineSortKeyMaps(_ value: BILineSortKeyMap)
    
    @objc(addLineSortKeyMaps:)
    @NSManaged public func addToLineSortKeyMaps(_ values: NSSet)
    
    @objc(removeLineSortKeyMaps:)
    @NSManaged public func removeFromLineSortKeyMaps(_ values: NSSet)
    
}

// MARK: Generated accessors for lineSorts
extension BIBidPeriod {
    
    @objc(addLineSortsObject:)
    @NSManaged public func addToLineSorts(_ value: BILineSort)
    
    @objc(removeLineSortsObject:)
    @NSManaged public func removeFromLineSorts(_ value: BILineSort)
    
    @objc(addLineSorts:)
    @NSManaged public func addToLineSorts(_ values: NSSet)
    
    @objc(removeLineSorts:)
    @NSManaged public func removeFromLineSorts(_ values: NSSet)
    
}

// MARK: Generated accessors for textFiles
extension BIBidPeriod {
    
    @objc(addTextFilesObject:)
    @NSManaged public func addToTextFiles(_ value: BITextFile)
    
    @objc(removeTextFilesObject:)
    @NSManaged public func removeFromTextFiles(_ value: BITextFile)
    
    @objc(addTextFiles:)
    @NSManaged public func addToTextFiles(_ values: NSSet)
    
    @objc(removeTextFiles:)
    @NSManaged public func removeFromTextFiles(_ values: NSSet)
    
}

// MARK: Generated accessors for vacations
extension BIBidPeriod {
    
    @objc(addVacationsObject:)
    @NSManaged public func addToVacations(_ value: BIVacation)
    
    @objc(removeVacationsObject:)
    @NSManaged public func removeFromVacations(_ value: BIVacation)
    
    @objc(addVacations:)
    @NSManaged public func addToVacations(_ values: NSSet)
    
    @objc(removeVacations:)
    @NSManaged public func removeFromVacations(_ values: NSSet)
    
}

// MARK: Generated accessors for lineFilters
extension BIBidPeriod {
    
    @objc(addLineFiltersObject:)
    @NSManaged public func addToLineFilters(_ value: BIFilterRule)
    
    @objc(removeLineFiltersObject:)
    @NSManaged public func removeFromLineFilters(_ value: BIFilterRule)
    
    @objc(addLineFilters:)
    @NSManaged public func addToLineFilters(_ values: NSSet)
    
    @objc(removeLineFilters:)
    @NSManaged public func removeFromLineFilters(_ values: NSSet)
    
}

extension BIBidPeriod : Identifiable {
    
    func isFABid() -> Bool {
        let dataSource = GlobalBidInfo.shared
        let isFABid = BICrewPositionType.FlightAttendant.rawValue == dataSource.position.rawValue
        return isFABid
    }
    func isFirstRoundBid() -> Bool {
        let dataSource = GlobalBidInfo.shared
        let isFirstRoundBid = dataSource.round == 1
        return isFirstRoundBid
    }
    
    func isSecondRoundBid() -> Bool {
        let dataSource = GlobalBidInfo.shared
        let isSecondRoundBid = dataSource.round == 2
        return isSecondRoundBid
    }
    func addTextFile(withText text: String, name: String) {
        let textFile = BITextFile(context: self.managedObjectContext!)
        textFile.text = text
        textFile.name = name
        addToTextFiles(textFile)
    }
    
    func textFile(withName name: String) -> BITextFile? {
        let predicate = NSPredicate(format: "name == %@", name)
        let filtered = textFiles!.filtered(using: predicate)
        return filtered.first as? BITextFile
    }
    func isWBidmaxOverlapWithEom() -> Bool {
        var isNextMonth = false
        var savedVacationObject: NSManagedObject? = nil
        if (self.month != nil) {
            let currentMonth = self.month as? Int
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "VacationArrayFromServer")
            
            do {
                let fetchedObjects = try self.managedObjectContext!.fetch(fetchRequest)
                if (fetchedObjects.count > 0) {
                    for vacationArrayFromServer in fetchedObjects {
                        if let endDate = vacationArrayFromServer.value(forKey: "endDate") as? Date {
                            print("endDate: \(endDate)")
                            
                            let calendar = Calendar.current
                            let components = calendar.dateComponents([.month], from: endDate)
                            if let monthFromDate = components.month {
                                 isNextMonth = (monthFromDate != currentMonth)
                                if isNextMonth {
                                    savedVacationObject = vacationArrayFromServer
                                    break
                                }
                            }
                        }
                    }
                    
                }
            } catch {
                print("Fetch failed: \(error.localizedDescription)")
                return false
            }
        }
        var isConflict = false
        if isNextMonth == true {
            if (self.faEomSelectedDate != nil) {
                let selectedDate = self.faEomSelectedDate?.intValue
                let savedEndDate = savedVacationObject!.value(forKey: "endDate") as? Date
                if let savedEndDate = savedEndDate, !isConflict {
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.day], from: savedEndDate)
                    if let vacEndDateInt = components.day {
                        isConflict = (vacEndDateInt >= selectedDate!)
                    }
                }
                
            }
        }
        return isConflict
    }
    
    func newSortKey() -> String {
        // Find the linesortkeymaps that have a nil lineSort
        var sortKey: String? = nil
        let unusedPredicate = NSPredicate(format: "lineSort = nil")
        let unusedKeyMaps:NSArray = lineSortKeyMaps!.filter { unusedPredicate.evaluate(with: $0) } as NSArray
        let unusedLineValues: Set<AnyHashable> = unusedKeyMaps.value(forKey: "lineKey") as! Set<AnyHashable>
        if ((unusedLineValues.count) > 0) {
            // Just grab the first object
            sortKey = unusedLineValues.first as? String
            // Clear out the unused key maps
            for keyMap in unusedKeyMaps {
                let temp = keyMap as! BILineSortKeyMap
                managedObjectContext?.delete(temp)
            }
        }
        return sortKey!
    }
    
    func lineSortKeyForCityLineSort(cityLineSort: BILineSort, city: String) -> String? {
        // This function generates a line sort key for a given city and city line sort
        var lineSortKey: String? = nil
        var sortKey: String? = nil
        // Check the category of city line sort
        if cityLineSort.category?.intValue == BILineSortCategory.BICitiesLineSortCategory.rawValue {
            switch Int(truncating: cityLineSort.type!) {
            case BICityLineSortType.BIOvernightCityLineSortType.rawValue:
                sortKey = "overnightCity\(city)"
            case BICityLineSortType.BILegCityLineSortType.rawValue:
                sortKey = "legCity\(city)"
            case BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue:
                sortKey = "EastCoast"
            case BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue:
                sortKey = "WestCoast"
            case BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue:
                sortKey = "NonConus"
            case BICityLineSortType.BICitiesLineSortTypeIntl.rawValue:
                sortKey = "International"
            case BICityLineSortType.BICitiesLineSortTypeAll.rawValue:
                sortKey = "AllCities"
            case BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue:
                sortKey = "Hawaii"
            default:
                print("Unknown type for BICitiesLineSortCategory line sort.")
            }
        }
        else if Int(truncating: cityLineSort.category!) == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue {
            // Determine the sort key based on the type of deadhead line sort

            switch Int(truncating: cityLineSort.type!) {
            case BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue:
                sortKey = "dhAtStartCity\(city)"
            case BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue:
                sortKey = "dhAtEndCity\(city)"
            case BIDeadheadLineSortType.BIDeadheadAtBothSortType.rawValue:
                sortKey = "dhAtBothCity\(city)"
            default:
                print("Unknown type for BIDeadheadsLineSortCategory line sort.")
            }
        }
        // If there is already a line sort map for this sort key, then use the
        // line key that corresponds to that sort key. Otherwise, create a new line
        // sort map for the sort key and get the line key for that map. Before
        // returning the line key, set the line key value for all lines.
        let sortKeyPredicate = NSPredicate(format: "sortKey == %@", sortKey!)
        let filteredLineSortMaps: [Any] = lineSortKeyMaps!.filter { sortKeyPredicate.evaluate(with: $0) }
        // There should be only 1 (or 0) line sort key maps for the sort key.
        //ZAssert(filteredLineSortMaps.count < 2, @"There must not be more than one sort key map for a sort key");
        let type = Int(truncating: cityLineSort.type!)
        if 0 == filteredLineSortMaps.count || (Int(truncating: cityLineSort.category!) == BILineSortCategory.BICitiesLineSortCategory.rawValue && (BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue == type || BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue == type || BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue == type || BICityLineSortType.BICitiesLineSortTypeIntl.rawValue == type || BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue == type)) {
            var lineSortKeyMap: BILineSortKeyMap? = nil
            if filteredLineSortMaps.count == 0 {
                lineSortKeyMap = BILineSortKeyMap(context: managedObjectContext!)
                lineSortKeyMap!.lineSort = cityLineSort
                cityLineSort.lineSortKeyMap = lineSortKeyMap
                lineSortKeyMap!.bidPeriod = self
                lineSortKeyMap!.sortKey = sortKey
                // Get the next available line dynamic sort value name.
                let lineEntity = BILine.entity()
                var lineAttributeNames =  [String]()
                
                for attributeName in (lineEntity.attributesByName.keys)  {
                    // attributeName has the type String
                    // ...
                    lineAttributeNames.append(attributeName)
                }
                let dynamicValuePredicate = NSPredicate(format: "SELF BEGINSWITH %@", "dynamicSortValue")
                let dynamicValueNames: [Any]? = lineAttributeNames.filter { dynamicValuePredicate.evaluate(with: $0) }
                // Find the first dynamic value name that is not in the line sort key
                // maps names.
                let usedLineValues: Set<AnyHashable>? = (lineSortKeyMaps?.value(forKey: "lineKey") as? Set<AnyHashable>)
                var foundDynamicVariable: Bool = false
                (dynamicValueNames! as NSArray).enumerateObjects({(_ obj: Any, _ idx: Int, _ stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                    if !usedLineValues!.contains(obj as! AnyHashable) {
                        lineSortKey = obj as? String
                        foundDynamicVariable = true
                        //                stop = true
                    }
                })
                // Check to see if all the dynamic variable slots are used up, if so, use the least-recently-used
                // one, which will always be the first one
                if !foundDynamicVariable {
                    lineSortKey = newSortKey()
                    if !(sortKey != nil) {
                        managedObjectContext?.delete(lineSortKeyMap!)
                        managedObjectContext?.delete(cityLineSort)
                        return nil
                    }
                    if !(lineSortKey != nil) {
                        managedObjectContext?.delete(lineSortKeyMap!)
                        managedObjectContext?.delete(cityLineSort)
                    }
                }
            }
            else {
                lineSortKeyMap = filteredLineSortMaps.first as? BILineSortKeyMap
                cityLineSort.lineSortKeyMap = lineSortKeyMap
                lineSortKey = lineSortKeyMap?.lineKey
            }
            lineSortKeyMap?.lineKey = lineSortKey
            //TODO: Make predicate for fetch depend on type of sort (overnight city or leg city). No need for value expression since it is far too slow.
            var fetch: NSFetchRequest<NSFetchRequestResult>? = nil
            var predicate: NSPredicate? = nil

            if BILineSortCategory.BICitiesLineSortCategory.rawValue == cityLineSort.category?.intValue {
                let type = cityLineSort.type?.intValue
                if (BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue == type || BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue == type || BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue == type || BICityLineSortType.BICitiesLineSortTypeIntl.rawValue == type || BICityLineSortType.BICitiesLineSortTypeAll.rawValue == type) {
                    fetch = NSFetchRequest(entityName: "Day")
                    let formatString = "line == $LINE && (info.city IN $SET) && trip.dropForFiltersSorts == 0"
                    predicate = NSPredicate(format: formatString)
                    
                    var filterVars = (cityLineSort.variables as? [String: Any]) ?? [:]
                    
                    if filterVars["SET"] == nil {
                        let selectedCities = cityLineSort.selectedRegionalCities()
                        filterVars["SET"] = Set(selectedCities)
                        cityLineSort.variables = filterVars as NSDictionary
                    }
                    predicate = predicate?.withSubstitutionVariables(cityLineSort.variables as! [String : Any])
                }
                else {
                    if BICityLineSortType.BIOvernightCityLineSortType.rawValue == cityLineSort.type?.intValue {
                        fetch = NSFetchRequest(entityName: "Day")
                        predicate = NSPredicate(format: "line == $LINE && info.city == %@ && trip.dropForFiltersSorts == NO", city)
                    }
                    else {
                        fetch = NSFetchRequest(entityName: "Leg")
                        predicate = NSPredicate(format: "line == $LINE && info.arriveCity == %@ && trip.dropForFiltersSorts == 0 && info.lastLegOfTrip == NO", city)
                    }
                }
            }
            else if BILineSortCategory.BIDeadheadsLineSortCategory.rawValue == cityLineSort.category?.intValue {
                fetch = NSFetchRequest(entityName: "Leg")
                if (BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue == type) {
                    predicate = NSPredicate(format: "line == $LINE && info.firstLegOfTrip == 1 && info.isDeadhead == 1 && info.arriveCity == %@ && trip.dropForFiltersSorts == 0", city)
                }
                else if (BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue == type) {
                    predicate = NSPredicate(format: "line == $LINE && info.lastLegOfTrip == 1 && trip.dropForFiltersSorts == 0 && info.isDeadhead == 1 && info.departCity == %@", city)
                }
                else {
                    predicate = NSPredicate(format: "line == $LINE && (trip.dropForFiltersSorts == 0 && ((info.lastLegOfTrip == 1 && info.isDeadhead == 1 && info.departCity == %@) || (info.firstLegOfTrip == 1 && info.isDeadhead == 1 && info.arriveCity == %@)))", city, city)
                }
            }
            let moc = self.managedObjectContext!
            self.lines!.forEach { line in
                fetch!.predicate = predicate!.withSubstitutionVariables(["LINE": line])
                fetch!.propertiesToFetch = nil

                do {
                    let count = try moc.count(for: fetch!)
                    (line as AnyObject).setValue(count, forKey: lineSortKey!)
                } catch {
                    print("Error counting fetch for line \(line): \(error)")
                }
            }

            
        }
        else {
            let lineSortKeyMap: BILineSortKeyMap = filteredLineSortMaps.first as! BILineSortKeyMap
            cityLineSort.lineSortKeyMap = lineSortKeyMap
            lineSortKey = lineSortKeyMap.lineKey
        }
        do {
            try self.managedObjectContext?.save()
        }
        catch {
            print("Error saving managed object context: \(error.localizedDescription)")
        }
        return lineSortKey
    }
    
    func lineSortKeyForPosition( posLineSort: BILineSort) -> String? {
        var lineSortKey:String = String()
        // Create line sort key, depending on type of line sort and city.
        var sortKey: String? = nil
        var posString: String? = nil
        // Determine sort key and position string based on the line sort type
        
        switch Int(truncating: posLineSort.type!) {
        case BIPositionsLineSortType.BIPositionASortType.rawValue:
            sortKey = "faPositionA"
            posString = "A"
        case BIPositionsLineSortType.BIPositionBSortType.rawValue:
            sortKey = "faPositionB"
            posString = "B"
        case BIPositionsLineSortType.BIPositionASortType.rawValue:
            sortKey = "faPositionC"
            posString = "C"
        case BIPositionsLineSortType.BIPositionASortType.rawValue:
            sortKey = "faPositionD"
            posString = "D"
        default:
            print("Unknown type for BIPositionsLineSortCategory line sort.")
        }
        // If there is already a line sort map for this sort key, then use the
        // line key that corresponds to that sort key. Otherwise, create a new line
        // sort map for the sort key and get the line key for that map. Before
        // returning the line key, set the line key value for all lines.
        let sortKeyPredicate = NSPredicate(format: "sortKey == %@", sortKey!)
        let filteredLineSortMaps: [Any] = lineSortKeyMaps!.filter { sortKeyPredicate.evaluate(with: $0)} as [Any]
        // There should be only 1 (or 0) line sort key maps for the sort key.
        //ZAssert(filteredLineSortMaps.count < 2, @"There must not be more than one sort key map for a sort key");
        if 0 == filteredLineSortMaps.count {
            // There is no line sort key map for the sort key, so create one and
            // set line values.
           let lineSortKeyMap = BILineSortKeyMap(context: managedObjectContext!)
            lineSortKeyMap.lineSort = posLineSort
            posLineSort.lineSortKeyMap = lineSortKeyMap
            lineSortKeyMap.bidPeriod = self
            lineSortKeyMap.sortKey = sortKey
            // Get the next available line dynamic sort value name.
            let lineEntity = NSEntityDescription.entity(forEntityName: "Line", in: managedObjectContext!)
            var lineAttributeNames = [String]()
            for attributeName in (lineEntity?.attributesByName.keys)! {
                lineAttributeNames.append(attributeName)
            }
            
            let dynamicValuePredicate = NSPredicate(format:"SELF BEGINSWITH %@", "dynamicSortValue")
            let dynamicValueNames: [Any]? = lineAttributeNames.filter { dynamicValuePredicate.evaluate(with: $0)}
            // Find the first dynamic value name that is not in the line sort key
            // maps names.
            let usedLineValues: Set<AnyHashable>? = (lineSortKeyMaps?.value(forKey: "lineKey") as? Set<AnyHashable>)
            var foundDynamicVariable: Bool = false
            (dynamicValueNames! as NSArray).enumerateObjects({( _ obj: Any, _ idx: Int, _ stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if !(usedLineValues?.contains(obj as! AnyHashable))! {
                    lineSortKey = obj as! String
                    foundDynamicVariable = true
                }
            })
            // Check to see if all the dynamic variable slots are used up, if so, use the least-recently-used
            // one, which will always be the first one
            if !foundDynamicVariable {
                lineSortKey = newSortKey()
                if !(sortKey != nil) {
                    managedObjectContext?.delete(lineSortKeyMap)
                    managedObjectContext?.delete(posLineSort)
                    return nil
                }
            }
            lineSortKeyMap.lineKey = lineSortKey
            let array = Array(lines!)
            for (index, value) in array.enumerated() {
                print(index)
                let line: BILine = value as! BILine
                if line.faPositionString == posString {
                    line.setValue(1, forKey: lineSortKey)
                }
                else {
                    line.setValue(2, forKey: lineSortKey)
                }
            }
        }
        else {
            let lineSortKeyMap: BILineSortKeyMap? = filteredLineSortMaps.first as? BILineSortKeyMap
            lineSortKey = (lineSortKeyMap?.lineKey)!
        }
        return lineSortKey
    }
    
    // Create a line sort key for days off sorting and set values for lines accordingly.
    
    func lineSortKeyForDaysOff( lineSort: BILineSort) -> String? {
        var lineSortKey: String = String()
        // Create line sort key, depending on type of line sort and city.
        let sortKey: String = "daysOffSort"
        // If there is already a line sort map for this sort key, then use the
        // line key that corresponds to that sort key. Otherwise, create a new line
        // sort map for the sort key and get the line key for that map. Before
        // returning the line key, set the line key value for all lines.
        // Check if a line sort map already exists for this sort key, and if not, create one

        let sortKeyPredicate = NSPredicate(format: "sortKey == %@", sortKey)
        let filteredLineSortMaps: [Any] = lineSortKeyMaps!.filter { sortKeyPredicate.evaluate(with: $0) }
        // There should be only 1 (or 0) line sort key maps for the sort key.
        if 0 == filteredLineSortMaps.count {
            // Create a new line sort key map for the sort key

            // There is no line sort key map for the sort key, so create one and
            // set line values.
            
            let lineSortKeyMap = BILineSortKeyMap(context: managedObjectContext!)
            lineSortKeyMap.lineSort = lineSort
            lineSort.lineSortKeyMap = lineSortKeyMap
            lineSortKeyMap.bidPeriod = self
            lineSortKeyMap.sortKey = sortKey
            // Determine the line key based on dynamic value names

            let lineEntity = NSEntityDescription.entity(forEntityName: BILineEntityName, in: managedObjectContext!)
            var lineAttributeNames =  [String]()
            for attributeName in (lineEntity?.attributesByName.keys)!  {
                // attributeName has the type String
                // ...
                lineAttributeNames.append(attributeName)
            }
            
            let dynamicValuePredicate = NSPredicate(format: "SELF BEGINSWITH %@", "dynamicSortValue")
            let dynamicValueNames: [Any]? = lineAttributeNames.filter { dynamicValuePredicate.evaluate(with: $0) }
            // Find the first dynamic value name that is not in the line sort key
            // maps names.
            
            let usedLineValues: Set<AnyHashable>? = (lineSortKeyMaps?.value(forKey: "lineKey") as? Set<AnyHashable>)
            var foundDynamicVariable: Bool = false
            
            (dynamicValueNames! as NSArray).enumerateObjects({(_ obj: Any, _ idx: Int, _ stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if !(usedLineValues?.contains(obj as! AnyHashable))! {
                    lineSortKey = obj as! String
                    foundDynamicVariable = true
                }
            })
            // Check to see if all the dynamic variable slots are used up, if so, use the least-recently-used
            // one, which will always be the first one
            if !foundDynamicVariable {
                lineSortKey = newSortKey()
                if sortKey.length > 0  {
                    managedObjectContext?.delete(lineSortKeyMap)
                    managedObjectContext?.delete(lineSort)
                    return nil
                }
            }
            // Set the line key for the map

            lineSortKeyMap.lineKey = lineSortKey
        } else {
            let lineSortKeyMap: BILineSortKeyMap? = (filteredLineSortMaps.first as! BILineSortKeyMap)
            lineSortKey = (lineSortKeyMap?.lineKey)!
        }
        // Set values for lines based on their days off

        if lineSort.variables != nil && lineSort.variables!["DAYS_OFF_MONTH_BITS"] != nil{
            let daysOffBits: UInt64 = lineSort.variables!["DAYS_OFF_MONTH_BITS"] as! UInt64
            let array = Array(lines!)
            for (index, value) in array.enumerated() {
                print(index)
                let line:BILine = value as! BILine
                let flippedMonthBits: UInt64 = UInt64(Int(truncating: line.monthBits!))
                let daysOffForLineBits: UInt64 = flippedMonthBits & daysOffBits
                let numDaysOffForLine: Int = CBUtils.popcount_few_ones(daysOffForLineBits)
                line.setValue(numDaysOffForLine, forKey: lineSortKey)
            }
        }
  
        return lineSortKey
    }
    
    // Create a line sort key for sorting lines based on days of work and set values for lines accordingly.

    func lineSortKeyForDaysWork( lineSort: BILineSort) -> String? {
        var lineSortKey: String = String()
        // Create line sort key, depending on type of line sort and city.
        let sortKey: String = "daysWorkSort"
        // If there is already a line sort map for this sort key, then use the
        // line key that corresponds to that sort key. Otherwise, create a new line
        // sort map for the sort key and get the line key for that map. Before
        // returning the line key, set the line key value for all lines.
        let sortKeyPredicate = NSPredicate(format: "sortKey == %@", sortKey)
        let filteredLineSortMaps: [Any] = lineSortKeyMaps!.filter { sortKeyPredicate.evaluate(with: $0) }
        // There should be only 1 (or 0) line sort key maps for the sort key.
        if 0 == filteredLineSortMaps.count {
            // There is no line sort key map for the sort key, so create one and
            // set line values.
           
            let lineSortKeyMap = BILineSortKeyMap(context: managedObjectContext!)
            lineSortKeyMap.lineSort = lineSort
            lineSort.lineSortKeyMap = lineSortKeyMap
            lineSortKeyMap.bidPeriod = self
            lineSortKeyMap.sortKey = sortKey
            let lineEntity = NSEntityDescription.entity(forEntityName: BILineEntityName, in: managedObjectContext!)
            var lineAttributeNames =  [String]()
            for attributeName in (lineEntity?.attributesByName.keys)!  {
                // attributeName has the type String
                // ...
                lineAttributeNames.append(attributeName)
            }
            
            let dynamicValuePredicate = NSPredicate(format: "SELF BEGINSWITH %@", "dynamicSortValue")
            let dynamicValueNames: [Any]? = lineAttributeNames.filter { dynamicValuePredicate.evaluate(with: $0) }
            // Find the first dynamic value name that is not in the line sort key
            // maps names.
            let usedLineValues: Set<AnyHashable>? = (lineSortKeyMaps?.value(forKey: "lineKey") as? Set<AnyHashable>)
            var foundDynamicVariable: Bool = false
            
            (dynamicValueNames! as NSArray).enumerateObjects({(_ obj: Any, _ idx: Int, _ stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if !(usedLineValues?.contains(obj as! AnyHashable))! {
                    lineSortKey = obj as! String
                    foundDynamicVariable = true
                }
            })
            // Check to see if all the dynamic variable slots are used up, if so, use the least-recently-used
            // one, which will always be the first one
            if !foundDynamicVariable {
                lineSortKey = newSortKey()
                if sortKey.length > 0  {
                    managedObjectContext?.delete(lineSortKeyMap)
                    managedObjectContext?.delete(lineSort)
                    return nil
                }
            }
            // Set the line key for the map

            lineSortKeyMap.lineKey = lineSortKey
        } else {
            let lineSortKeyMap: BILineSortKeyMap? = (filteredLineSortMaps.first as! BILineSortKeyMap)
            lineSortKey = (lineSortKeyMap?.lineKey)!
        }
        // Set values for lines based on their days of work

        let daysOffBits: UInt64 = lineSort.variables!["DAYS_OFF_MONTH_BITS"] as! UInt64
        let array = Array(lines!)
        for (index, value) in array.enumerated() {
            print(index)
            let line:BILine = value as! BILine
            let flippedMonthBits: UInt64 = UInt64(Int(truncating: line.monthBits!))
            let daysOffForLineBits: UInt64 = flippedMonthBits & daysOffBits
            let numDaysOffForLine: Int = CBUtils.popcount_few_ones(daysOffForLineBits)
            line.setValue(numDaysOffForLine, forKey: lineSortKey)
        }
        return lineSortKey
    }
    
    // Create a line sort key for sorting lines based on trip start days and set values for lines accordingly.

    func lineSortKeyForTripStartDays( lineSort: BILineSort) -> String? {
        var lineSortKey: String = String()
        // Create line sort key, depending on type of line sort and city.
        let sortKey: String = "daysTripStartSort"
        // If there is already a line sort map for this sort key, then use the
        // line key that corresponds to that sort key. Otherwise, create a new line
        // sort map for the sort key and get the line key for that map. Before
        // returning the line key, set the line key value for all lines.
        let sortKeyPredicate = NSPredicate(format: "sortKey == %@", sortKey)
        let filteredLineSortMaps: [Any] = lineSortKeyMaps!.filter { sortKeyPredicate.evaluate(with: $0) }
        // There should be only 1 (or 0) line sort key maps for the sort key.
        if 0 == filteredLineSortMaps.count {
            // There is no line sort key map for the sort key, so create one and
            // set line values.
            let lineSortKeyMap = BILineSortKeyMap(context: managedObjectContext!)
            lineSortKeyMap.lineSort = lineSort
            lineSort.lineSortKeyMap = lineSortKeyMap
            lineSortKeyMap.bidPeriod = self
            lineSortKeyMap.sortKey = sortKey
            let lineEntity = NSEntityDescription.entity(forEntityName: BILineEntityName, in: managedObjectContext!)
            var lineAttributeNames =  [String]()
            for attributeName in (lineEntity?.attributesByName.keys)!  {
                // attributeName has the type String
                // ...
                lineAttributeNames.append(attributeName)
            }
            
            let dynamicValuePredicate = NSPredicate(format: "SELF BEGINSWITH %@", "dynamicSortValue")
            let dynamicValueNames: [Any]? = lineAttributeNames.filter { dynamicValuePredicate.evaluate(with: $0) }
            // Find the first dynamic value name that is not in the line sort key
            // maps names.
            let usedLineValues: Set<AnyHashable>? = (lineSortKeyMaps?.value(forKey: "lineKey") as? Set<AnyHashable>)
            var foundDynamicVariable: Bool = false
            
            (dynamicValueNames! as NSArray).enumerateObjects({(_ obj: Any, _ idx: Int, _ stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if !(usedLineValues?.contains(obj as! AnyHashable))! {
                    lineSortKey = obj as! String
                    foundDynamicVariable = true
                }
            })
            // Check to see if all the dynamic variable slots are used up, if so, use the least-recently-used
            // one, which will always be the first one
            if !foundDynamicVariable {
                lineSortKey = newSortKey()
                if sortKey.length > 0  {
                    managedObjectContext?.delete(lineSortKeyMap)
                    managedObjectContext?.delete(lineSort)
                    return nil
                }
            }
            // Set the line key for the map

            lineSortKeyMap.lineKey = lineSortKey
        } else {
            let lineSortKeyMap: BILineSortKeyMap? = (filteredLineSortMaps.first as! BILineSortKeyMap)
            lineSortKey = (lineSortKeyMap?.lineKey)!
        }
        // Set values for lines based on their trip start days

        let daysOffBits: UInt64 = lineSort.variables!["DAYS_OFF_MONTH_BITS"] as! UInt64
        let array = Array(lines!)
        for (index, value) in array.enumerated() {
            print(index)
            let line:BILine = value as! BILine
            let flippedMonthBits: UInt64 = UInt64(Int(truncating: line.tripStartMonthBits!))
            let daysOffForLineBits: UInt64 = flippedMonthBits & daysOffBits
            let numDaysOffForLine: Int = CBUtils.popcount_few_ones(daysOffForLineBits)
            line.setValue(numDaysOffForLine, forKey: lineSortKey)
        }
        return lineSortKey
    }
    
    func isNeedToShowMyCal() -> Bool {
        return myCalEndDate != nil && myCalStartDate != nil
    }
 
    func getFrozenBidListLines() -> [BILine] {
        let lines = (self.lines!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "isFrozen", ascending: false)]) as! [BILine]
        // Create predicates to filter lines by bidOrder and isFrozen status

        var array : [NSPredicate] = []
        array.append(NSPredicate(format: "bidOrder > 0"))
        array.append(NSPredicate(format: "isFrozen == \(NSNumber(value: true))"))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        // Filter the lines using the predicate and return the result

        let predicateValue = (lines as NSArray).filtered(using: predicate) as! [BILine]
        return predicateValue
    }
    func getOrderedBidListSorts() -> [BILineSort]{
        let predicate = NSPredicate(format: "isBidListSort == \(NSNumber(value: true))")
        guard let linesSort = ((self.lineSorts!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as NSArray).filtered(using: predicate) as? [BILineSort] else { return [] }
        return linesSort
    }
    
    func getOrderedSortsForPosition() -> [BILineSort]{
        var positionFlag2 = 0
        var sortedBILine = [BILineSort]()
        for case let sort as BILineSort in (self.lineSorts?.allObjects ?? []) {
            if sort.category?.intValue == 3{
                positionFlag2 = 1
            }
        }
        if positionFlag2 == 1{
            let predicate = NSPredicate(format: "isBidListSort != \(NSNumber(value: true))")
            guard let linesSort = ((self.lineSorts!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as NSArray).filtered(using: predicate) as? [BILineSort] else { return [] }
            positionFlag2 = 0
            sortedBILine = linesSort
            
        }
        return sortedBILine
    }
    
    func orderedLines() -> [BILine] {
        let lines = (self.lines!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "number", ascending: true)]) as! [BILine]
        return lines
    }
    
    // This function deletes all bid list sorts
    func deleteAllBidListSorts(){
        // Retrieve and sort bid list sorts
        let sortArray = ((getOrderedBidListSorts()) as NSArray).sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as NSArray
        // Iterate through the sorted bid list sorts
        var isNeededTripHighlightReset = false
        for sort in sortArray.filtered(using: NSPredicate(format: "isBidListSort == \(NSNumber(value: true))")) {
            // Check if the sort is of type BILineSort
            isNeededTripHighlightReset = true
            guard let sort = sort as? BILineSort else {
                continue
            }
            // Delete associated line sort key map, if it exists
            if (sort.lineSortKeyMap != nil) {
                self.managedObjectContext?.delete(sort.lineSortKeyMap!)
            }
            // Delete the bid list sort

            self.managedObjectContext?.delete(sort)
        }
        // Reset trip highlight count if a bid period is selected
        if CBGlobalMethods.shared.selectedBidPeriod != nil && isNeededTripHighlightReset{
            BITrip.resetTripHighlightCount(in: CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!)
        }
       
    }
    func getTrashedLines() -> [BILine] {
        let lines = (self.lines!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "number", ascending: true)]) as! [BILine]
        var array : [NSPredicate] = []
        // Create a predicate to filter lines by isTrashed status

        array.append(NSPredicate(format: "isTrashed == %@", NSNumber(booleanLiteral: true)))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        // Filter the lines using the predicate and return the result

        let predicateValue = (lines as NSArray).filtered(using: predicate) as! [BILine]
        return predicateValue
    }

    
    func getBidListLines() -> [BILine] {
        let lines = (self.lines!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "bidOrder", ascending: true)]) as! [BILine]
        var array : [NSPredicate] = []
        array.append(NSPredicate(format: "bidOrder > 0"))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        let predicateValue = (lines as NSArray).filtered(using: predicate) as! [BILine]
        return predicateValue
    }
    
    //MARK: Bid Receipts
    
    func addBidReceiptWithText(bidReceiptText: String){
        let receipt = BIBidReceipt(context: self.managedObjectContext!)
        receipt.setPropertiesWithReceiptText(receiptText: bidReceiptText)
        receipt.bidPeriod = self
        self.addToBidReceipts(receipt)
        self.lastBidDate = receipt.timeStamp
    }
    
    func sortedBidReceipts() -> [BIBidReceipt] {
        let timeStampSort = NSSortDescriptor(key: "timeStamp", ascending: false)
        let sortedBidReceipts = (bidReceipts!.allObjects as NSArray).sortedArray(using: [timeStampSort])
        return sortedBidReceipts as! [BIBidReceipt]
    }
    
    func mostRecentBidReceipt() -> BIBidReceipt? {
        return self.sortedBidReceipts().first
    }
    
    func sortedBidReceiptByCreatedAt() -> [BIBidReceipt]{
        let createdAtSort = NSSortDescriptor(key: "createdAt", ascending: false)
        let sortedBidReceiptByCreatedAt = (self.bidReceipts!.allObjects as NSArray).sortedArray(using: [createdAtSort])
        return sortedBidReceiptByCreatedAt as! [BIBidReceipt]
    }
    
    func mostRecentBidReceiptByCreatedAt() -> BIBidReceipt? {
        return self.sortedBidReceiptByCreatedAt().first
    }
    
}
