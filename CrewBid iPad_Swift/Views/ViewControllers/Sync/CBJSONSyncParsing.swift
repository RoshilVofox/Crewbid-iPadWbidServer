//
//  CBJSONSyncParsing.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 14/10/25.
//

import UIKit
import CoreData

//MARK: when new filter is added add data in filterTitleDict, filterNameAbbreviation function

class CBJSONSyncParsing: NSObject {

    var calendarData: BICalendarData?
    var bidPeriod: BIBidPeriod?
    var syncType: UserSyncType?
    var lineManger: BILinesManager?
    var arrayDictRecived: [[String: Any]]?
    var syncPreset: PresetSync?
    let app = UIApplication.shared.delegate as! AppDelegate
    let context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!
    let objdatabuilder = ODataBuilder()
    var syncContainsVacation = false
    
    func initcalendarData() {
        calendarData = calendarData?.initWithBidPeriod(bidPeriod: bidPeriod!)
    }
    
//    MARK: presetKeepLocal
    func presetKeepLocal() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM/dd/yyyy hh:mm: a"
        let now = Date()
        let startDate = now.timeIntervalSince1970 * 70
        let dateStartedString = String(format: "/Date(%.0f+0800)/", startDate)
        var dictDetails = [String: Any]()
        var presetVersionNumber = 0
        if self.syncPreset != nil {
            presetVersionNumber = (self.syncPreset?.presetSyncVersion!.intValue)!
        }
        dictDetails["EmployeeNumber"] = app.ObjUserAccount?.employeeNumber
        dictDetails["StateFileName"] = NSNull()
        dictDetails["PreSetFileName"] = app.ObjUserAccount?.employeeNumber
        dictDetails["Year"] = self.bidPeriod!.year!
        dictDetails["VersionNumber"] = 0
        dictDetails["StateContent"] = NSNull()
        dictDetails["LastUpdatedTime"] = dateStartedString
        dictDetails["PreSetVersionNumber"] = NSNumber(value: presetVersionNumber)
        dictDetails["PreSetStateContent"] = self.getJsonForPresetSync()
        dictDetails["PreSetLastUpdatedTime"] = dateStartedString
        objdatabuilder.saveCrewBidStateAndPresetToServer(dictDetails: dictDetails) { response in
            CBGlobalMethods.shared.hideCustomActivityIndicator()
            if let response = response {
                let responseDict = response[0]
                if responseDict["IsPresetSuccess"] != nil {
                    let isPresetSynced = responseDict["IsPresetSuccess"] as? NSNumber
                    if isPresetSynced?.boolValue == true {
                        self.bidPeriod?.currentDateTime = Date()
                        try? self.context.save()
                        AlertService.showAlertForTopVC(title: "Synched!", message: "You have successfully synched your Presets to server.")
                    }
                    else {
                        AlertService.showAlertForTopVC(title: "", message:"Preset synch was not success!")
                    }
                }
                else {
                    AlertService.showAlertForTopVC(title: "Error!", message: "Something went wrong!")
                }
//                print("✅ Server response:", response)
            } else {
                AlertService.showAlertForTopVC(title: "Error!", message: "Something went wrong!")
                print("❌ Failed to save preset/state")
            }
        }
    }
    
    func getJsonForPresetSync() -> String {
        let fileManager = FileManager()
        let presetTableVC = CBPresetsTVC()
        var presetsArray: [Any] = []
        var presetsParsed = NSMutableArray()
        if fileManager.fileExists(atPath: presetTableVC.presetsDocumentFilePathWithBidPeriod(bidPeriod: self.bidPeriod!)) {
            let array = presetTableVC.openPresetsFromFileWithBidPeriod(bidPeriod: self.bidPeriod!)
            for preset in array {
                if let dict = preset as? [String: Any] {
                    var linesSorts: [CBPresetLineSort] = []
                    var filterRules: [CBPresetFilterRule] = []
                    if let dictFilterRule = dict["filterRules"] as? [[String: Any]] {
                        for filter in dictFilterRule {
                            let filt = CBPresetFilterRule()
                            filt.category = filter["category"] as? NSNumber
                            filt.type = filter["type"] as? NSNumber
                            filt.name = filter["name"] as? String
                            filt.keyPath = filter["keyPath"] as? String
                            filt.abbreviation = filter["abbreviation"] as? String
                            filt.comparison = filter["comparison"] as? NSNumber
                            filt.variables = filter["variables"] as? [String: Any]
                            filterRules.append(filt)
                        }
                    }
                    if let dictSortRules = dict["lineSorts"] as? [[String: Any]] {
                        for sort in dictSortRules {
                            let sortObj = CBPresetLineSort()
                            sortObj.category = sort["category"] as? NSNumber
                            sortObj.type = sort["type"] as? NSNumber
                            sortObj.name = sort["name"] as? String
                            sortObj.keyPath = sort["keyPath"] as? String
                            sortObj.abbreviation = sort["abbreviation"] as? String
                            sortObj.ascending = sort["ascending"] as? NSNumber
                            sortObj.isMutable = sort["isMutable"] as? NSNumber
                            sortObj.city = sort["city"] as? String
                            sortObj.expression = sort["expression"] as? String
                            sortObj.order = sort["order"] as? NSNumber
                            sortObj.lineSortKeyMap = sort["lineSortKeyMap"] as? [String: Any]
                            sortObj.variables = sort["variables"] as? [String: Any]
                            sortObj.arrayVariables = sort["arrayVariables"] as? NSMutableArray
                            linesSorts.append(sortObj)
                        }
                    }
                    let pr = CBPreset()
                    pr.name = dict["name"] as? String
                    pr.month = dict["month"] as? NSNumber
                    pr.year = dict["year"] as? NSNumber
                    pr.position = dict["position"] as? NSNumber
                    pr.appVersion = dict["appVersion"] as? String
                    pr.lineValues = dict["lineValues"] as? [Any] ?? []
                    pr.selected = dict["selected"] as? NSNumber
                    pr.presetIdentifier = dict["presetIdentifier"] as? String
                    pr.overnight = dict["overnight"] as? NSMutableArray
                    pr.commuteTimeDetails = dict["commuteTimeDetails"] as? NSMutableArray
                    pr.commutabilityFilterDetails = dict["commutabilityFilterDetails"] as? NSMutableDictionary
                    pr.commutabilitySortDetails = dict["commutabilitySortDetails"] as? NSMutableDictionary
                    pr.filterRules = filterRules
                    pr.lineSorts = linesSorts
                    presetsArray.append(pr)
                }
                else if let presetObj = preset as? CBPreset {
                    presetsArray.append(presetObj)
                }
            }
            
            let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "isBidListSort != %@", NSNumber(value: true))
            let resultsSort = try! self.context.fetch(fetchRequest)
            for case let preset as CBPreset in presetsArray {
                let menuFilters = self.getMenuFilterListDictFromLocalForSync(from: nil, isState: false, resultsPresetFilter: preset)
                let quickFilters = self.getQuickFilterListDictFromLocal(from: nil, isState: false, resultsFilterPreset: preset.filterRules)
                let menuLineSorts = self.getMenuSortListDictFromLocalForSync(resultsSort: resultsSort, isState: false, resultsPresetSort: preset, isConversion: false)
                let filterAndSorts = self.mergeDictionaries([menuFilters, quickFilters, menuLineSorts])
                var presetDict = [String: Any]()
                presetDict["filterSortState"] = filterAndSorts
                presetDict["month"] = preset.month
                let position = BICrewPositionType(rawValue: preset.position!.intValue)!
                presetDict["position"] = CBUtils.shortName(for: position)
                presetDict["year"] = preset.year
                presetDict["presetIdentifier"] = preset.presetIdentifier
                if preset.presetIdentifier == self.bidPeriod?.loadedPresetIdentifier {
                    presetDict["selected"] = 1
                }
                else {
                    presetDict["selected"] = 0
                }
                presetsParsed.add(presetDict)
            }
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: presetsParsed, options: [])
            let jsonString = String(data: data, encoding: .utf8)
            return jsonString ?? ""
        } catch {
            print("JSON serialization error: \(error)")
            return ""
        }

        
    }
    
    func getMenuFilterListDictFromLocalForSync(from resultsFilter: [Any]?, isState: Bool, resultsPresetFilter preset: CBPreset?) -> [String: Any] {
        let resultsPresetFilter = preset?.filterRules
        var currentTitle = ""
        var filerList = NSMutableArray()
        var tempDict = [String: Any]()
        var listFilterArray = NSMutableArray()
        var listFilterDict = [String: Any]()
        if isState {
            var i = -1
            for case let filter as BIFilterRule in resultsFilter ?? [] {
                i = i + 1
                if filter.name == "Overnight City" {
                    filter.abbreviation = "OC"
                }
                if filter.abbreviation != nil {
                    // resetting all the old abbriveation to new
                    let filterName = filter.name!
                    let requiredAbbreviation = filterNameAbbreviation()[filterName]
                    if requiredAbbreviation != filter.abbreviation {
                        if "v\(requiredAbbreviation ?? "")" == filter.abbreviation {
                            print("Emp completed Abbreviation converted from (Filter0: \(filterName)) \(String(describing: filter.abbreviation)) to v\(requiredAbbreviation ?? "")")
                            filter.abbreviation = "v\(requiredAbbreviation ?? "")"
                        } else {
                            print("Emp completed Abbreviation converted from (Filter1: \(filterName)) \(String(describing: filter.abbreviation)) to \(requiredAbbreviation ?? "")")
                            filter.abbreviation = requiredAbbreviation
                        }
                    }
                    
                    currentTitle = self.filterTitleDict()[filter.abbreviation!] ?? ""
                    var dict = [String: Any]()
                    
                    if filter.comparison!.intValue == NSComparisonPredicate.Operator.lessThanOrEqualTo.rawValue ||
                        filter.comparison!.intValue == NSComparisonPredicate.Operator.lessThan.rawValue {
                        filter.comparison = NSNumber(value: ComparisonType.atMost.rawValue)
                    }

                    if filter.comparison!.intValue == NSComparisonPredicate.Operator.equalTo.rawValue {
                        filter.comparison = NSNumber(value: ComparisonType.exactly.rawValue)
                    }

                    if filter.comparison!.intValue == NSComparisonPredicate.Operator.greaterThanOrEqualTo.rawValue {
                        filter.comparison = NSNumber(value: ComparisonType.atLeast.rawValue)
                    }
                    dict["Abbreviation"] = filter.abbreviation
                    dict["category"] = filter.category
                    dict["Type"] = filter.category?.stringValue
                    dict["Name"] = filter.name
                    dict["KeyPath"] = filter.keyPath
                    dict["Comparison"] = filter.comparison
                    var variables = filter.variables as? [String: Any]
                    if filter.abbreviation == "Flags" {
                        if let tempSet = variables?["SET"] as? Set<AnyHashable> {
                            let variables = Array(tempSet)
                            dict["Variable"] = variables
                        }
                    }
                    else if filter.abbreviation == "Report-Release" {
                        dict["Abbreviation"] = "Report-Release"
                        variables = [String: Any]()
                        let varb = (filter.variables as? [String: Any])!
                        var dict2 = [String: Any]()
                        dict2 = varb
                        
                        var selectedIndices: [Int] = []

                        if let monthBitsValue = filter.variables?["MONTH_BITS"] as? UInt64 {
                            for index in 0..<calendarData!.calendarDays.count {
                                let one: UInt64 = 1
                                let mask = one << UInt64(index)
                                if (monthBitsValue & mask) != 0 {
                                    selectedIndices.append(index)
                                }
                            }
                        }
                        variables!["selectedIndex"] = selectedIndices
                        variables!["selectedOption"] = 1
                        if dict2["isFirst"] != nil {
                            let tmp = NSNumber(value: (dict2["isFirst"] as? Int)!)
                            variables!["isFirst"] = tmp
                        }
                        if dict2["isLast"] != nil {
                            let tmp = NSNumber(value: (dict2["isLast"] as? Int)!)
                            variables!["isLast"] = tmp
                        }
                        if dict2["isNoMid"] != nil {
                            let tmp = NSNumber(value: (dict2["isNoMid"] as? Int)!)
                            variables!["isNoMid"] = tmp
                        }
                        if dict2["isCalendar"] != nil {
                            let tmp = NSNumber(value: (dict2["isCalendar"] as? Int)!)
                            variables!["selectedOption"] = tmp
                        }
                        if dict2["isAllDays"] != nil {
                            let tmp = NSNumber(value: (dict2["isAllDays"] as? Int)!)
                            variables!["selectedOption"] = tmp
                        }
                        if dict2["releaseValue"] != nil {
                            let tmp = dict2["releaseValue"]
                            variables!["releaseValue"] = tmp
                        }
                        if dict2["reportValue"] != nil {
                            let tmp = dict2["reportValue"]
                            variables!["reportValue"] = tmp
                        }
                        
                        dict["Variable"] = variables
                    }
                    else if filter.abbreviation == "CmAuto" {
                        var dict2 = [String: Any]()
                        dict2 = variables!
                        variables = [
                            "commuteCity": "ABQ",
                            "selectedConnectTime": "00:30",
                            "nonStop": 0,
                            "selectedTakeOffPadTimeValues": "01:00",
                            "selectedBackToBasePadTimeValues": "00:10",
                            "nMid": 1,
                            "cmtFrBaOv": 3,
                            "cmtGreaterOrLesser": 1,
                            "cmtPercentage": 100
                        ]
                        
                        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "commutableType == 0")
                        let fetchedObjects = try? self.lineManger?.managedObjectContext.fetch(fetchRequest)
                        var objCommutability: Commutability?
                        if fetchedObjects?.count ?? 0 > 0 {
                            objCommutability = fetchedObjects![0]
                            if objCommutability!.isNonStop == nil {
                                objCommutability?.isNonStop = 0
                            }
                            var isNonStop = 0
                            if objCommutability!.isNonStop!.boolValue == true {
                                isNonStop = 1
                            }
                            variables = [
                                "commuteCity": objCommutability?.city as Any,
                                "selectedConnectTime": self.getHours(from: objCommutability!.connectTime!),
                                "nonStop": isNonStop,
                                "selectedTakeOffPadTimeValues": self.getHours(from: objCommutability!.checkInTime!),
                                "selectedBackToBasePadTimeValues": self.getHours(from: objCommutability!.baseTime!),
                                "nMid" : objCommutability!.secondCellValue?.stringValue,
                                "cmtFrBaOv" : objCommutability!.thirdCellValue?.stringValue,
                                "cmtGreaterOrLesser" : objCommutability!.type?.stringValue,
                                "cmtPercentage" : objCommutability!.value?.stringValue
                            ]
                        }
                        dict["Variable"] = variables
                    }
                    else if filter.abbreviation == "CRqd" {
                        var dict2 = [String: Any]()
                        dict2 = variables!
                        let noMidCheckState = (dict2["NoMidCheckState"] as? NSNumber)?.boolValue ?? false
                        var rangeEnd = 0
                        var rangeStart = 0
                        var value = 0
                        if dict2["RANGEEND"] != nil {
                            rangeEnd = 10
                        }
                        if dict2["RANGESTART"] != nil {
                            rangeEnd = 10
                        }
                        if dict2["VALUE"] != nil {
                            rangeEnd = 10
                        }
                        
                        var monThuesDept = dict2["MON_THURS_DEPART"] as? String
                        var monThuesRet = dict2["MON_THURS_RETURN"] as? String
                        var friDept = dict2["FRI_DEPART"] as? String
                        var friRet = dict2["FRI_RETURN"] as? String
                        var satDept = dict2["SAT_DEPART"] as? String
                        var satRet = dict2["SAT_RETURN"] as? String
                        var sunDept = dict2["SUN_DEPART"] as? String
                        var sunRet = dict2["SUN_RETURN"] as? String
                        
                        if monThuesDept == "-1" {
                            monThuesDept = ""
                        }
                        if friDept == "-1" {
                            friDept = ""
                        }
                        if satDept == "-1" {
                            satDept = ""
                        }
                        if sunDept == "-1" {
                            sunDept = ""
                        }
                        
                        if monThuesRet == "3000" {
                            monThuesRet = ""
                        }
                        if friRet == "3000" {
                            friRet = ""
                        }
                        if satRet == "3000" {
                            satRet = ""
                        }
                        if sunRet == "3000" {
                            sunRet = ""
                        }
                        
                        variables = [
                            "RANGEEND": "\(rangeEnd)",
                            "RANGESTART": "\(rangeStart)",
                            "MON_THURS_DEPART": monThuesDept!,
                            "MON_THURS_RETURN": monThuesRet!,
                            "FRI_DEPART": friDept!,
                            "FRI_RETURN": friRet!,
                            "SAT_DEPART": satDept!,
                            "SAT_RETURN": satRet!,
                            "SUN_DEPART": sunDept!,
                            "SUN_RETURN": sunRet!,
                            "VALUE": "\(value)",
                            "NoMidCheckState": NSNumber(value: noMidCheckState)
                        ]
                        dict["Variable"] = variables
                    }
                    else if filter.abbreviation == "OCB" {
                        var noArray = [Any]()
                        var yesArray = [Any]()
                        let overnightYesCitiesArray = NSMutableArray()
                        let fetchRequest: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
                        let fetchedObjects = try? context.fetch(fetchRequest)
                        var dictAllValues = [String: Any]()
                        var array = NSMutableArray()
                        if fetchedObjects?.count ?? 0 > 0 {
                            let first = fetchedObjects![0]
                            if let cityStatusValueArray = first.value(forKey: "citystatus") as? NSMutableArray, cityStatusValueArray.count > 0 {
                                array = cityStatusValueArray
                                dictAllValues = (cityStatusValueArray[0] as? [String: Any])!
                            }
                            else if let citystatusValue = first.value(forKey: "citystatus"), !(citystatusValue is NSNull) {
                                dictAllValues = (citystatusValue as? [String: Any])!
                            }
                        }
                        noArray = dictAllValues.keys.filter { dictAllValues[$0] as? String == "1" }
                        yesArray = dictAllValues.keys.filter { dictAllValues[$0] as? String == "2" }
                        variables = [
                            "OverNightYes": yesArray,
                            "OverNightNo": noArray
                        ]
                        dict["Variable"] = variables
                    }
                    else if (filter.abbreviation == "WantDays" || filter.abbreviation == "MonthDays" || filter.abbreviation == "TripStarts" || filter.abbreviation == "TripEnds") {
                        var variablesArray: [Int] = []

                        if let monthBits = (filter.variables?["MONTH_BITS"] as? NSNumber)?.uint64Value {
                            for index in 0..<calendarData!.calendarDays.count {
                                let one: UInt64 = 1
                                let mask = one << UInt64(index)
                                if (monthBits & mask) != 0 {
                                    variablesArray.append(index)
                                }
                            }
                        }
                        dict["Variable"] = variablesArray
                    }
                    else if currentTitle == "Regional Overnight Cities" {
                        let dict2 = variables!
                        if let tempSet = variables?["SET"] as? Set<AnyHashable> {
                            let variablesDict: [String: Any] = [
                                "CITY": Array(tempSet),
                                "RANGEEND": dict2["RANGEEND"] as Any,
                                "RANGESTART": dict2["RANGESTART"] as Any,
                                "VALUE": dict2["VALUE"] as Any
                            ]
                            dict["Variable"] = variablesDict
                        }
                    }
                    else {
                        dict["Variable"] = variables
                    }
                    listFilterArray.add(dict)
                
                    var flag = false
                    for i in 0 ..< filerList.count {
                        let filterListArray = filerList
                        let dict: [String: Any] = filterListArray[i] as! [String: Any]
                        var muteDict = dict
                        if muteDict["title"] as! String == currentTitle {
                            flag = true
                            let array = muteDict["Listfilter"] as? [Any]
                            var mutArray = array
                            mutArray?.append(listFilterArray[0])
                            muteDict["Listfilter"] = mutArray
                            filterListArray.replaceObject(at: i, with: dict)
                            filerList = filterListArray.mutableCopy() as! NSMutableArray
                        }
                    }
                    
                    if !flag {
                        listFilterDict["title"] = self.filterTitleDict()[filter.abbreviation!]
                        listFilterDict["Listfilter"] = listFilterArray.mutableCopy()
                        filerList.add(listFilterDict)
                    }
                    listFilterArray.removeAllObjects()
                }
            }
        }
        else {
            var i = -1
            for case let filter as CBPresetFilterRule in resultsFilter ?? [] {
                i = i + 1

                if filter.abbreviation != nil {
                    // resetting all the old abbriveation to new
                    let filterName = filter.name!
                    let requiredAbbreviation = filterNameAbbreviation()[filterName]
                    if requiredAbbreviation != filter.abbreviation {
                        if "v\(requiredAbbreviation ?? "")" == filter.abbreviation {
                            print("Emp completed Abbreviation converted from (Filter0: \(filterName)) \(String(describing: filter.abbreviation)) to v\(requiredAbbreviation ?? "")")
                            filter.abbreviation = "v\(requiredAbbreviation ?? "")"
                        } else {
                            print("Emp completed Abbreviation converted from (Filter1: \(filterName)) \(String(describing: filter.abbreviation)) to \(requiredAbbreviation ?? "")")
                            filter.abbreviation = requiredAbbreviation
                        }
                    }
                    
                    currentTitle = self.filterTitleDict()[filter.abbreviation!] ?? ""
                    var dict = [String: Any]()
                    
                    if filter.comparison!.intValue == NSComparisonPredicate.Operator.lessThanOrEqualTo.rawValue ||
                        filter.comparison!.intValue == NSComparisonPredicate.Operator.lessThan.rawValue {
                        filter.comparison = NSNumber(value: ComparisonType.atMost.rawValue)
                    }

                    if filter.comparison!.intValue == NSComparisonPredicate.Operator.equalTo.rawValue {
                        filter.comparison = NSNumber(value: ComparisonType.exactly.rawValue)
                    }

                    if filter.comparison!.intValue == NSComparisonPredicate.Operator.greaterThanOrEqualTo.rawValue {
                        filter.comparison = NSNumber(value: ComparisonType.atLeast.rawValue)
                    }
                    dict["Abbreviation"] = filter.abbreviation
                    dict["category"] = filter.category
                    dict["Type"] = filter.category?.stringValue
                    dict["Name"] = filter.name
                    dict["KeyPath"] = filter.keyPath
                    dict["Comparison"] = filter.comparison
                    var variables = filter.variables as? [String: Any]
                    if filter.abbreviation == "Flags" {
                        if let tempSet = variables?["SET"] as? Set<AnyHashable> {
                            let variables = Array(tempSet)
                            dict["Variable"] = variables
                        }
                    }
                    else if filter.abbreviation == "Report-Release" {
                        dict["Abbreviation"] = "Report-Release"
                        variables = [String: Any]()
                        let varb = (filter.variables as? [String: Any])!
                        var dict2 = [String: Any]()
                        dict2 = varb
                        
                        var selectedIndices: [Int] = []

                        if let monthBitsValue = filter.variables?["MONTH_BITS"] as? UInt64 {
                            for index in 0..<calendarData!.calendarDays.count {
                                let one: UInt64 = 1
                                let mask = one << UInt64(index)
                                if (monthBitsValue & mask) != 0 {
                                    selectedIndices.append(index)
                                }
                            }
                        }
                        variables!["selectedIndex"] = selectedIndices
                        variables!["selectedOption"] = 1
                        if dict2["isFirst"] != nil {
                            let tmp = NSNumber(value: (dict2["isFirst"] as? Int)!)
                            variables!["isFirst"] = tmp
                        }
                        if dict2["isLast"] != nil {
                            let tmp = NSNumber(value: (dict2["isLast"] as? Int)!)
                            variables!["isLast"] = tmp
                        }
                        if dict2["isNoMid"] != nil {
                            let tmp = NSNumber(value: (dict2["isNoMid"] as? Int)!)
                            variables!["isNoMid"] = tmp
                        }
                        if dict2["isCalendar"] != nil {
                            let tmp = NSNumber(value: (dict2["isCalendar"] as? Int)!)
                            variables!["selectedOption"] = tmp
                        }
                        if dict2["isAllDays"] != nil {
                            let tmp = NSNumber(value: (dict2["isAllDays"] as? Int)!)
                            variables!["selectedOption"] = tmp
                        }
                        if dict2["releaseValue"] != nil {
                            let tmp = dict2["releaseValue"]
                            variables!["releaseValue"] = tmp
                        }
                        if dict2["reportValue"] != nil {
                            let tmp = dict2["reportValue"]
                            variables!["reportValue"] = tmp
                        }
                        
                        dict["Variable"] = variables
                    }
                    else if filter.abbreviation == "CmAuto" {
                        var dict2 = [String: Any]()
                        dict2 = variables!
                        variables = [
                            "commuteCity": "ABQ",
                            "selectedConnectTime": "00:30",
                            "nonStop": 0,
                            "selectedTakeOffPadTimeValues": "01:00",
                            "selectedBackToBasePadTimeValues": "00:10",
                            "nMid": 1,
                            "cmtFrBaOv": 3,
                            "cmtGreaterOrLesser": 1,
                            "cmtPercentage": 100
                        ]
                        
                        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "commutableType == 0")
                        let fetchedObjects = try? self.lineManger?.managedObjectContext.fetch(fetchRequest)
                        var objCommutability: Commutability?
                        if fetchedObjects?.count ?? 0 > 0 {
                            objCommutability = fetchedObjects![0]
                            if objCommutability!.isNonStop == nil {
                                objCommutability?.isNonStop = 0
                            }
                            var isNonStop = 0
                            if objCommutability!.isNonStop!.boolValue == true {
                                isNonStop = 1
                            }
                            variables = [
                                "commuteCity": objCommutability?.city as Any,
                                "selectedConnectTime": self.getHours(from: objCommutability!.connectTime!),
                                "nonStop": isNonStop,
                                "selectedTakeOffPadTimeValues": self.getHours(from: objCommutability!.checkInTime!),
                                "selectedBackToBasePadTimeValues": self.getHours(from: objCommutability!.baseTime!),
                                "nMid" : objCommutability!.secondCellValue?.stringValue,
                                "cmtFrBaOv" : objCommutability!.thirdCellValue?.stringValue,
                                "cmtGreaterOrLesser" : objCommutability!.type?.stringValue,
                                "cmtPercentage" : objCommutability!.value?.stringValue
                            ]
                        }
                        dict["Variable"] = variables
                    }
                    else if filter.abbreviation == "CRqd" {
                        var dict2 = [String: Any]()
                        dict2 = variables!
                        let noMidCheckState = (dict2["NoMidCheckState"] as? NSNumber)?.boolValue ?? false
                        var rangeEnd = 0
                        var rangeStart = 0
                        var value = 0
                        if dict2["RANGEEND"] != nil {
                            rangeEnd = 10
                        }
                        if dict2["RANGESTART"] != nil {
                            rangeEnd = 10
                        }
                        if dict2["VALUE"] != nil {
                            rangeEnd = 10
                        }
                        
                        var monThuesDept = dict2["MON_THURS_DEPART"] as? String
                        var monThuesRet = dict2["MON_THURS_RETURN"] as? String
                        var friDept = dict2["FRI_DEPART"] as? String
                        var friRet = dict2["FRI_RETURN"] as? String
                        var satDept = dict2["SAT_DEPART"] as? String
                        var satRet = dict2["SAT_RETURN"] as? String
                        var sunDept = dict2["SUN_DEPART"] as? String
                        var sunRet = dict2["SUN_RETURN"] as? String
                        
                        if monThuesDept == "-1" {
                            monThuesDept = ""
                        }
                        if friDept == "-1" {
                            friDept = ""
                        }
                        if satDept == "-1" {
                            satDept = ""
                        }
                        if sunDept == "-1" {
                            sunDept = ""
                        }
                        
                        if monThuesRet == "3000" {
                            monThuesRet = ""
                        }
                        if friRet == "3000" {
                            friRet = ""
                        }
                        if satRet == "3000" {
                            satRet = ""
                        }
                        if sunRet == "3000" {
                            sunRet = ""
                        }
                        
                        variables = [
                            "RANGEEND": "\(rangeEnd)",
                            "RANGESTART": "\(rangeStart)",
                            "MON_THURS_DEPART": monThuesDept!,
                            "MON_THURS_RETURN": monThuesRet!,
                            "FRI_DEPART": friDept!,
                            "FRI_RETURN": friRet!,
                            "SAT_DEPART": satDept!,
                            "SAT_RETURN": satRet!,
                            "SUN_DEPART": sunDept!,
                            "SUN_RETURN": sunRet!,
                            "VALUE": "\(value)",
                            "NoMidCheckState": NSNumber(value: noMidCheckState)
                        ]
                        dict["Variable"] = variables
                    }
                    else if filter.abbreviation == "OCB" {
                        var noArray = [Any]()
                        var yesArray = [Any]()
                        let overnightYesCitiesArray = NSMutableArray()
                        let fetchRequest: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
                        let fetchedObjects = try? context.fetch(fetchRequest)
                        var dictAllValues = [String: Any]()
                        var array = NSMutableArray()
                        if fetchedObjects?.count ?? 0 > 0 {
                            let first = fetchedObjects![0]
                            if let cityStatusValueArray = first.value(forKey: "citystatus") as? NSMutableArray, cityStatusValueArray.count > 0 {
                                array = cityStatusValueArray
                                dictAllValues = (cityStatusValueArray[0] as? [String: Any])!
                            }
                            else if let citystatusValue = first.value(forKey: "citystatus"), !(citystatusValue is NSNull) {
                                dictAllValues = (citystatusValue as? [String: Any])!
                            }
                        }
                        noArray = dictAllValues.keys.filter { dictAllValues[$0] as? String == "1" }
                        yesArray = dictAllValues.keys.filter { dictAllValues[$0] as? String == "2" }
                        variables = [
                            "OverNightYes": yesArray,
                            "OverNightNo": noArray
                        ]
                        dict["Variable"] = variables
                    }
                    else if (filter.abbreviation == "WantDays" || filter.abbreviation == "MonthDays" || filter.abbreviation == "TripStarts" || filter.abbreviation == "TripEnds") {
                        var variablesArray: [Int] = []

                        if let monthBits = (filter.variables?["MONTH_BITS"] as? NSNumber)?.uint64Value {
                            for index in 0..<calendarData!.calendarDays.count {
                                let one: UInt64 = 1
                                let mask = one << UInt64(index)
                                if (monthBits & mask) != 0 {
                                    variablesArray.append(index)
                                }
                            }
                        }
                        dict["Variable"] = variablesArray
                    }
                    else if currentTitle == "Regional Overnight Cities" {
                        let dict2 = variables!
                        if let tempSet = variables?["SET"] as? Set<AnyHashable> {
                            let variablesDict: [String: Any] = [
                                "CITY": Array(tempSet),
                                "RANGEEND": dict2["RANGEEND"] as Any,
                                "RANGESTART": dict2["RANGESTART"] as Any,
                                "VALUE": dict2["VALUE"] as Any
                            ]
                            dict["Variable"] = variablesDict
                        }
                    }
                    else {
                        dict["Variable"] = variables
                    }
                    listFilterArray.add(dict)
                
                    var flag = false
                    for i in 0 ..< filerList.count {
                        let filterListArray = filerList
                        let dict: [String: Any] = filterListArray[i] as! [String: Any]
                        var muteDict = dict
                        if muteDict["title"] as! String == currentTitle {
                            flag = true
                            let array = muteDict["Listfilter"] as? [Any]
                            var mutArray = array
                            mutArray?.append(listFilterArray[0])
                            muteDict["Listfilter"] = mutArray
                            filterListArray.replaceObject(at: i, with: dict)
                            filerList = filterListArray.mutableCopy() as! NSMutableArray
                        }
                    }
                    
                    if !flag {
                        listFilterDict["title"] = self.filterTitleDict()[filter.abbreviation!]
                        listFilterDict["Listfilter"] = listFilterArray.mutableCopy()
                        filerList.add(listFilterDict)
                    }
                    listFilterArray.removeAllObjects()
                }
            }
        }
        var lstDict = [String: Any]()
        lstDict["lstFilters"] = filerList
        return lstDict
    }
    
    func getQuickFilterListDictFromLocal(from resultsFilters: [Any]?, isState: Bool, resultsFilterPreset resultsPresetFilters: [Any]?) -> [String: Any] {
        var dict = self.getQuickFilterDefaultDict()
        if isState {
            for case let filter as BIFilterRule in resultsFilters! {
                if filter.abbreviation == nil {
                    let category = filter.category?.intValue
                    let type = filter.type?.intValue
                    if category == BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue {
                        if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                            let valArray = Array(set)
                            if self.bidPeriod!.isEtopsLinesContainsInBid?.boolValue == true {
                                //ETOPS
                                if self.bidPeriod!.isSecondRoundBid() {
                                    if valArray.contains(BILineType.NonEtopsConUS.rawValue) {
                                        dict["conUs"] = false
                                    }
                                    else {
                                        dict["conUs"] = true
                                    }
                                    if valArray.contains(BILineType.NonEtopsNonConUS.rawValue) {
                                        dict["nonConUs"] = false
                                    }
                                    else {
                                        dict["nonConUs"] = true
                                    }
                                    if valArray.contains(BILineType.NonEtopsHard.rawValue) {
                                        dict["hard"] = false
                                    }
                                    else {
                                        dict["hard"] = true
                                    }
                                    if valArray.contains(BILineType.NonEtopsMixed.rawValue) {
                                        dict["mixed"] = false
                                    }
                                    else {
                                        dict["mixed"] = true
                                    }
                                    dict["blank"] = false
                                }
                                else {
                                    if valArray.contains(BILineType.NonEtopsConUS.rawValue) {
                                        dict["conUs"] = false
                                    }
                                    else {
                                        dict["conUs"] = true
                                    }
                                    if valArray.contains(BILineType.NonEtopsNonConUS.rawValue) {
                                        dict["nonConUs"] = false
                                    }
                                    else {
                                        dict["nonConUs"] = true
                                    }
                                    if valArray.contains(BILineType.BlankLine.rawValue) {
                                        dict["blank"] = false
                                    }
                                    else {
                                        dict["blank"] = true
                                    }
                                }
                                if valArray.contains(BILineType.NonEtopsReserve.rawValue) {
                                    dict["reserve"] = false
                                }
                                else {
                                    dict["reserve"] = true
                                }
                            }
                        }
                        else {
                            //Non ETOPS
                            if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                                let valArray = Array(set)
                                if self.bidPeriod!.isSecondRoundBid() {
                                    if self.bidPeriod!.isFABid() {
                                        // FA 2nd
                                        if valArray.contains(BILineType.HardConUS.rawValue) {
                                            dict["conUs"] = false
                                        }
                                        else {
                                            dict["conUs"] = true
                                        }
                                        if valArray.contains(BILineType.HardNonConUS.rawValue) {
                                            dict["nonConUs"] = false
                                        }
                                        else {
                                            dict["nonConUs"] = true
                                        }
                                    }
                                    else {
                                        // CP 2nd
                                        dict["conUs"] = false
                                        dict["nonConUs"] = false
                                        dict["blank"] = false
                                        if valArray.contains(BILineType.HardLine.rawValue) {
                                            dict["hard"] = false
                                        }
                                        else {
                                            dict["hard"] = true
                                        }
                                        if valArray.contains(BILineType.MixedLine.rawValue) {
                                            dict["mixed"] = false
                                        }
                                        else {
                                            dict["mixed"] = true
                                        }
                                    }
                                }
                                else {
                                    //                                    first round both
                                    if valArray.contains(BILineType.HardConUS.rawValue) {
                                        dict["conUs"] = false
                                    }
                                    else {
                                        dict["conUs"] = true
                                    }
                                    if valArray.contains(BILineType.HardNonConUS.rawValue) {
                                        dict["nonConUs"] = false
                                    }
                                    else {
                                        dict["nonConUs"] = true
                                    }
                                    if valArray.contains(BILineType.BlankLine.rawValue) {
                                        dict["blank"] = false
                                    }
                                    else {
                                        dict["blank"] = true
                                    }
                                }
                                //                                Both
                                if valArray.contains(BILineType.ReserveLine.rawValue) {
                                    dict["reserve"] = false
                                }
                                else {
                                    dict["reserve"] = true
                                }
                            }
                        }
                        if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                            let valArray = Array(set)
                            if valArray.contains(BILineType.BILineTypeLoDo.rawValue) {
                                dict["LODO"] = false
                            }
                            else {
                                dict["LODO"] = true
                            }
                        }
                    }
                    else if category == BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue {
                        if self.bidPeriod!.isFABid() && self.bidPeriod!.isSecondRoundBid() {
                            if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                                let valArray = Array(set)
                                if bidPeriod!.isFABid() {
                                    if valArray.contains(BIFaReserveLineType.SnrAMres.rawValue) {
                                        dict["SnrAMres"] = false
                                    }
                                    else {
                                        dict["SnrAMres"] = true
                                    }
                                    if valArray.contains(BIFaReserveLineType.SnrPMres.rawValue) {
                                        dict["SnrPMres"] = false
                                    }
                                    else {
                                        dict["SnrPMres"] = true
                                    }
                                    if valArray.contains(BIFaReserveLineType.JnrAMres.rawValue) {
                                        dict["JnrAMres"] = false
                                    }
                                    else {
                                        dict["JnrAMres"] = true
                                    }
                                    if valArray.contains(BIFaReserveLineType.JnrPMres.rawValue) {
                                        dict["JnrPMres"] = false
                                    }
                                    else {
                                        dict["JnrPMres"] = true
                                    }
                                    if valArray.contains(BIFaReserveLineType.JnrLateRes.rawValue) {
                                        dict["JnrLateRes"] = false
                                    }
                                    else {
                                        dict["JnrLateRes"] = true
                                    }
                                    if valArray.contains(BIFaReserveLineType.NoType.rawValue) {
                                        dict["noReserve"] = false
                                    }
                                    else {
                                        dict["noReserve"] = true
                                    }
                                }
                            }
                        }
                    }
                    else if category == BIFilterRuleCategory.BIEtopsFilterRuleCategory.rawValue {
                        let val = filter.variables!["ETOPS_ON"] as? NSNumber
                        if val?.boolValue == true {
                            dict["etops"] = false
                        }
                        else {
                            dict["etops"] = true
                        }
                    }
                    else if category == BIFilterRuleCategory.BIEtopsResFilterRuleCategory.rawValue {
                        let val = filter.variables!["ETOPSRES_ON"] as? NSNumber
                        if val?.boolValue == true {
                            dict["etopsRes"] = false
                        }
                        else {
                            dict["etopsRes"] = true
                        }
                    }
                    else if category == BIFilterRuleCategory.BIAmPmFilterRuleCategory.rawValue {
                        if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                            let valArray = Array(set)
                            if valArray.contains(BILineAMPM.AMLine.rawValue) {
                                dict["amLines"] = false
                            }
                            else {
                                dict["amLines"] = true
                            }
                            if valArray.contains(BILineAMPM.PMLine.rawValue) {
                                dict["pmLines"] = false
                            }
                            else {
                                dict["pmLines"] = true
                            }
                            if valArray.contains(BILineAMPM.MixedAMPMLine.rawValue) {
                                dict["mixedLines"] = false
                            }
                            else {
                                dict["mixedLines"] = true
                            }
                            if valArray.contains(BILineAMPM.RedEyeAMPMLine.rawValue) {
                                dict["redEyeAmPmLines"] = false
                            }
                            else {
                                dict["redEyeAmPmLines"] = true
                            }
                        }
                    }
                    else if category == BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue {
                        if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                            let valArray = Array(set)
                            if valArray.contains(BIFaPosition.FaPositionA.rawValue) {
                                dict["posA"] = false
                            }
                            else {
                                dict["posA"] = true
                            }
                            if valArray.contains(BIFaPosition.FaPositionB.rawValue) {
                                dict["posB"] = false
                            }
                            else {
                                dict["posB"] = true
                            }
                            if valArray.contains(BIFaPosition.FaPositionC.rawValue) {
                                dict["posC"] = false
                            }
                            else {
                                dict["posC"] = true
                            }
                            if valArray.contains(BIFaPosition.FaPositionD.rawValue) {
                                dict["posD"] = false
                            }
                            else {
                                dict["posD"] = true
                            }
                            if valArray.contains(BIFaPosition.FaPositionMultiple.rawValue) {
                                dict["posMultiple"] = false
                            }
                            else {
                                dict["posMultiple"] = true
                            }
                            if valArray.contains(BIFaPosition.FaPositionNA.rawValue) {
                                dict["posNA"] = false
                            }
                            else {
                                dict["posNA"] = true
                            }
                        }
                    }
                    else if category == BIFilterRuleCategory.BIDaysOfWeekFilterRuleCategory.rawValue {
                        if let weekdayBits = (filter.variables?["WEEKDAY_BITS"] as? NSNumber)?.uintValue {
                            for wkday in 0..<7 {
                                let bitSet = weekdayBits & (1 << wkday)
                                let select = (bitSet == 0)
                                
                                switch wkday {
                                case 0:
                                    dict["sun"] = !select
                                case 1:
                                    dict["mon"] = !select
                                case 2:
                                    dict["tue"] = !select
                                case 3:
                                    dict["wed"] = !select
                                case 4:
                                    dict["thu"] = !select
                                case 5:
                                    dict["fri"] = !select
                                case 6:
                                    dict["sat"] = !select
                                default:
                                    break
                                }
                            }
                        }
                    }
                    else if category == BIFilterRuleCategory.BITripLengthFilterRuleCategory.rawValue {
                        let turns_On = filter.variables!["TURNS_ON"] as? NSNumber
                        if !(turns_On?.boolValue ?? true) == true {
                            dict["turns"] = true
                        }
                        let two_Days_On = filter.variables!["TWO_DAYS_ON"] as? NSNumber
                        if !(two_Days_On?.boolValue ?? true) == true {
                            dict["twoDays"] = true
                        }
                        let three_Days_On = filter.variables!["THREE_DAYS_ON"] as? NSNumber
                        if !(three_Days_On?.boolValue ?? true) == true {
                            dict["threeDays"] = true
                        }
                        let four_Days_On = filter.variables!["FOUR_DAYS_ON"] as? NSNumber
                        if !(four_Days_On?.boolValue ?? true) == true {
                            dict["fourDays"] = true
                        }
                    }
                }
            }
        }
        else {
            for case let filter as CBPresetFilterRule in resultsFilters ?? [] {
                if filter.abbreviation == nil {
                    let category = filter.category?.intValue
                    let type = filter.type?.intValue
                    if category == BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue {
                        if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                            let valArray = Array(set)
                            if self.bidPeriod!.isEtopsLinesContainsInBid?.boolValue == true {
                                //ETOPS
                                if self.bidPeriod!.isSecondRoundBid() {
                                    if valArray.contains(BILineType.NonEtopsConUS.rawValue) {
                                        dict["conUs"] = false
                                    }
                                    else {
                                        dict["conUs"] = true
                                    }
                                    if valArray.contains(BILineType.NonEtopsNonConUS.rawValue) {
                                        dict["nonConUs"] = false
                                    }
                                    else {
                                        dict["nonConUs"] = true
                                    }
                                    if valArray.contains(BILineType.NonEtopsHard.rawValue) {
                                        dict["hard"] = false
                                    }
                                    else {
                                        dict["hard"] = true
                                    }
                                    if valArray.contains(BILineType.NonEtopsMixed.rawValue) {
                                        dict["mixed"] = false
                                    }
                                    else {
                                        dict["mixed"] = true
                                    }
                                    dict["blank"] = false
                                }
                                else {
                                    if valArray.contains(BILineType.NonEtopsConUS.rawValue) {
                                        dict["conUs"] = false
                                    }
                                    else {
                                        dict["conUs"] = true
                                    }
                                    if valArray.contains(BILineType.NonEtopsNonConUS.rawValue) {
                                        dict["nonConUs"] = false
                                    }
                                    else {
                                        dict["nonConUs"] = true
                                    }
                                    if valArray.contains(BILineType.BlankLine.rawValue) {
                                        dict["blank"] = false
                                    }
                                    else {
                                        dict["blank"] = true
                                    }
                                }
                                if valArray.contains(BILineType.NonEtopsReserve.rawValue) {
                                    dict["reserve"] = false
                                }
                                else {
                                    dict["reserve"] = true
                                }
                            }
                        }
                        else {
                            //Non ETOPS
                            if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                                let valArray = Array(set)
                                if self.bidPeriod!.isSecondRoundBid() {
                                    if self.bidPeriod!.isFABid() {
                                        // FA 2nd
                                        if valArray.contains(BILineType.HardConUS.rawValue) {
                                            dict["conUs"] = false
                                        }
                                        else {
                                            dict["conUs"] = true
                                        }
                                        if valArray.contains(BILineType.HardNonConUS.rawValue) {
                                            dict["nonConUs"] = false
                                        }
                                        else {
                                            dict["nonConUs"] = true
                                        }
                                    }
                                    else {
                                        // CP 2nd
                                        dict["conUs"] = false
                                        dict["nonConUs"] = false
                                        dict["blank"] = false
                                        if valArray.contains(BILineType.HardLine.rawValue) {
                                            dict["hard"] = false
                                        }
                                        else {
                                            dict["hard"] = true
                                        }
                                        if valArray.contains(BILineType.MixedLine.rawValue) {
                                            dict["mixed"] = false
                                        }
                                        else {
                                            dict["mixed"] = true
                                        }
                                    }
                                }
                                else {
                                    //                                    first round both
                                    if valArray.contains(BILineType.HardConUS.rawValue) {
                                        dict["conUs"] = false
                                    }
                                    else {
                                        dict["conUs"] = true
                                    }
                                    if valArray.contains(BILineType.HardNonConUS.rawValue) {
                                        dict["nonConUs"] = false
                                    }
                                    else {
                                        dict["nonConUs"] = true
                                    }
                                    if valArray.contains(BILineType.BlankLine.rawValue) {
                                        dict["blank"] = false
                                    }
                                    else {
                                        dict["blank"] = true
                                    }
                                }
                                //                                Both
                                if valArray.contains(BILineType.ReserveLine.rawValue) {
                                    dict["reserve"] = false
                                }
                                else {
                                    dict["reserve"] = true
                                }
                            }
                        }
                        if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                            let valArray = Array(set)
                            if valArray.contains(BILineType.BILineTypeLoDo.rawValue) {
                                dict["LODO"] = false
                            }
                            else {
                                dict["LODO"] = true
                            }
                        }
                    }
                    else if category == BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue {
                        if self.bidPeriod!.isFABid() && self.bidPeriod!.isSecondRoundBid() {
                            if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                                let valArray = Array(set)
                                if bidPeriod!.isFABid() {
                                    if valArray.contains(BIFaReserveLineType.SnrAMres.rawValue) {
                                        dict["SnrAMres"] = false
                                    }
                                    else {
                                        dict["SnrAMres"] = true
                                    }
                                    if valArray.contains(BIFaReserveLineType.SnrPMres.rawValue) {
                                        dict["SnrPMres"] = false
                                    }
                                    else {
                                        dict["SnrPMres"] = true
                                    }
                                    if valArray.contains(BIFaReserveLineType.JnrAMres.rawValue) {
                                        dict["JnrAMres"] = false
                                    }
                                    else {
                                        dict["JnrAMres"] = true
                                    }
                                    if valArray.contains(BIFaReserveLineType.JnrPMres.rawValue) {
                                        dict["JnrPMres"] = false
                                    }
                                    else {
                                        dict["JnrPMres"] = true
                                    }
                                    if valArray.contains(BIFaReserveLineType.JnrLateRes.rawValue) {
                                        dict["JnrLateRes"] = false
                                    }
                                    else {
                                        dict["JnrLateRes"] = true
                                    }
                                    if valArray.contains(BIFaReserveLineType.NoType.rawValue) {
                                        dict["noReserve"] = false
                                    }
                                    else {
                                        dict["noReserve"] = true
                                    }
                                }
                            }
                        }
                    }
                    else if category == BIFilterRuleCategory.BIEtopsFilterRuleCategory.rawValue {
                        let val = filter.variables!["ETOPS_ON"] as? NSNumber
                        if val?.boolValue == true {
                            dict["etops"] = false
                        }
                        else {
                            dict["etops"] = true
                        }
                    }
                    else if category == BIFilterRuleCategory.BIEtopsResFilterRuleCategory.rawValue {
                        let val = filter.variables!["ETOPSRES_ON"] as? NSNumber
                        if val?.boolValue == true {
                            dict["etopsRes"] = false
                        }
                        else {
                            dict["etopsRes"] = true
                        }
                    }
                    else if category == BIFilterRuleCategory.BIAmPmFilterRuleCategory.rawValue {
                        if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                            let valArray = Array(set)
                            if valArray.contains(BILineAMPM.AMLine.rawValue) {
                                dict["amLines"] = false
                            }
                            else {
                                dict["amLines"] = true
                            }
                            if valArray.contains(BILineAMPM.PMLine.rawValue) {
                                dict["pmLines"] = false
                            }
                            else {
                                dict["pmLines"] = true
                            }
                            if valArray.contains(BILineAMPM.MixedAMPMLine.rawValue) {
                                dict["mixedLines"] = false
                            }
                            else {
                                dict["mixedLines"] = true
                            }
                            if valArray.contains(BILineAMPM.RedEyeAMPMLine.rawValue) {
                                dict["redEyeAmPmLines"] = false
                            }
                            else {
                                dict["redEyeAmPmLines"] = true
                            }
                        }
                    }
                    else if category == BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue {
                        if let set = filter.variables?["SET"] as? Set<AnyHashable> {
                            let valArray = Array(set)
                            if valArray.contains(BIFaPosition.FaPositionA.rawValue) {
                                dict["posA"] = false
                            }
                            else {
                                dict["posA"] = true
                            }
                            if valArray.contains(BIFaPosition.FaPositionB.rawValue) {
                                dict["posB"] = false
                            }
                            else {
                                dict["posB"] = true
                            }
                            if valArray.contains(BIFaPosition.FaPositionC.rawValue) {
                                dict["posC"] = false
                            }
                            else {
                                dict["posC"] = true
                            }
                            if valArray.contains(BIFaPosition.FaPositionD.rawValue) {
                                dict["posD"] = false
                            }
                            else {
                                dict["posD"] = true
                            }
                            if valArray.contains(BIFaPosition.FaPositionMultiple.rawValue) {
                                dict["posMultiple"] = false
                            }
                            else {
                                dict["posMultiple"] = true
                            }
                            if valArray.contains(BIFaPosition.FaPositionNA.rawValue) {
                                dict["posNA"] = false
                            }
                            else {
                                dict["posNA"] = true
                            }
                        }
                    }
                    else if category == BIFilterRuleCategory.BIDaysOfWeekFilterRuleCategory.rawValue {
                        if let weekdayBits = (filter.variables?["WEEKDAY_BITS"] as? NSNumber)?.uintValue {
                            for wkday in 0..<7 {
                                let bitSet = weekdayBits & (1 << wkday)
                                let select = (bitSet == 0)
                                
                                switch wkday {
                                case 0:
                                    dict["sun"] = !select
                                case 1:
                                    dict["mon"] = !select
                                case 2:
                                    dict["tue"] = !select
                                case 3:
                                    dict["wed"] = !select
                                case 4:
                                    dict["thu"] = !select
                                case 5:
                                    dict["fri"] = !select
                                case 6:
                                    dict["sat"] = !select
                                default:
                                    break
                                }
                            }
                        }
                    }
                    else if category == BIFilterRuleCategory.BITripLengthFilterRuleCategory.rawValue {
                        let turns_On = filter.variables!["TURNS_ON"] as? NSNumber
                        if !(turns_On?.boolValue ?? true) == true {
                            dict["turns"] = true
                        }
                        let two_Days_On = filter.variables!["TWO_DAYS_ON"] as? NSNumber
                        if !(two_Days_On?.boolValue ?? true) == true {
                            dict["twoDays"] = true
                        }
                        let three_Days_On = filter.variables!["THREE_DAYS_ON"] as? NSNumber
                        if !(three_Days_On?.boolValue ?? true) == true {
                            dict["threeDays"] = true
                        }
                        let four_Days_On = filter.variables!["FOUR_DAYS_ON"] as? NSNumber
                        if !(four_Days_On?.boolValue ?? true) == true {
                            dict["fourDays"] = true
                        }
                    }
                }
            }
        }
        let dictArray = [dict]
        let lstQuickFiletDict = ["lstQuickFilters": dictArray]
        return lstQuickFiletDict
    }
    
    func getMenuSortListDictFromLocalForSync(resultsSort: [Any], isState: Bool, resultsPresetSort preset: CBPreset?, isConversion: Bool) -> [String: Any] {
        let resultsPresetSort = preset?.lineSorts
        var currentTitle = ""
        var listSortArray = NSMutableArray()
        var sortsList = NSMutableArray()
        var listSortDict = [String: Any]()
        if isState{
            var i = -1
            for case let sort as BILineSort in resultsSort {
                i += 1
                if sort.abbreviation == nil {
                    if(sort.name == "Overnight City") {
                        sort.abbreviation = "OvernightCity"
                    }
                    if(sort.name == "Legs Thru") {
                        sort.abbreviation = "LegsThru"
                    }
                    if(sort.name == "Days Off") {
                        sort.abbreviation = "Off"
                    }
                    if(sort.name == "Days of the Month Off") {
                        sort.abbreviation = "OffSort"
                    }
                    if(sort.name == "Days I want to Work") {
                        sort.abbreviation = "WorkSort"
                    }
                    if(sort.name == "Days I Don't Want Trips to Start") {
                        sort.abbreviation = "TripStartSort"
                    }
                }
                
                // resetting all the old abbriveation to new
                let sortName = sort.name!
                var requiredAbbreviation = self.sortNameAbbreviation()[sortName]
                if requiredAbbreviation != sort.abbreviation {
                    if "v\(String(describing: requiredAbbreviation))" == sort.abbreviation {
                        print("Emp completed Abbreviation converted from (Sort0: \(sortName)) \(sort.abbreviation ?? "") to v\(String(describing: requiredAbbreviation))")
                        sort.abbreviation = "v\(String(describing: requiredAbbreviation))"
                    } else {
                        if sort.abbreviation == "vBlk" {
                            requiredAbbreviation = "vBlk"
                        }
                        if sort.abbreviation == "v$/day" {
                            requiredAbbreviation = "v$/day"
                        }
                        print("Emp completed Abbreviation converted from (Sort1: \(sortName)) \(sort.abbreviation ?? "") to \(String(describing: requiredAbbreviation))")
                        sort.abbreviation = requiredAbbreviation
                    }
                }

                currentTitle = self.sortTitleDict()[sort.abbreviation!]!
                var dict = [String: Any]()
                dict["Category"] = sort.category
                dict["Abbreviation"] = sort.abbreviation
                dict["isSortScratchpad"] = NSNumber(booleanLiteral: true)
                if sort.isBidListSort == true {
                    dict["isSortScratchpad"] = NSNumber(booleanLiteral: false)
                }
                if sort.type != nil {
                    dict["type"] = sort.type
                }
                if sort.arrayVariables != nil {
                    dict["ArrayVariables"] = sort.arrayVariables
                }
                var sortOrder = sort.order?.intValue
                if isConversion {
                    sortOrder! += 1
                }
                else {
                    sortOrder! += 1
                }
                dict["Order"] = sortOrder
                dict["Name"] = sort.name
                dict["KeyPath"] = sort.keyPath
                let temp = sort.ascending
                dict["Ascending"] = temp?.boolValue
                var variables = sort.variables as? [String: Any]
                if (sort.abbreviation == "OffSort" || sort.abbreviation == "WorkSort" || sort.abbreviation == "TripStartSort") {
                    var variablesArray: [Int] = []
                    if let monthBits = sort.variables?["DAYS_OFF_MONTH_BITS"] as? UInt64 {
                        for index in 0..<calendarData!.calendarDays.count {
                            let mask: UInt64 = 1 << index
                            if (monthBits & mask) != 0 {
                                variablesArray.append(index)
                            }
                        }
                    }
                    dict["ArrayVariables"] = variablesArray
                    
                    if sort.abbreviation == "WorkSort" {
                        dict["Ascending"] = false
                    } else if sort.abbreviation == "OffSort" {
                        dict["Ascending"] = true
                    } else {
                        dict["Ascending"] = true
                    }
                }
                else if sort.abbreviation == "CmAuto" {
                    let dict2 = [String: Any]()
                    let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "commutableType == 1")
                    let fetchedObjects = try? self.lineManger?.managedObjectContext.fetch(fetchRequest)
                    var objCommutability: Commutability?
                    if fetchedObjects?.count ?? 0 > 0 {
                        objCommutability = fetchedObjects![0]
                        var nonStop = 0 as NSNumber
                        if objCommutability?.isNonStop != nil {
                            nonStop = (objCommutability?.isNonStop)!
                        }
                        variables = [
                            "commuteCity": objCommutability!.city!,
                            "selectedConnectTime": self.getHours(from: objCommutability!.connectTime!),
                            "nonStop": nonStop,
                            "selectedTakeOffPadTimeValues": self.getHours(from: objCommutability!.checkInTime!),
                            "selectedBackToBasePadTimeValues": self.getHours(from: objCommutability!.baseTime!),
                            "nMid": objCommutability!.secondCellValue!.stringValue,
                            "cmtFrBaOv": objCommutability!.thirdCellValue!.stringValue,
                            "cmtGreaterOrLesser": objCommutability!.type!.stringValue,
                            "cmtPercentage": objCommutability!.value!.stringValue
                        ]
                    }
                    dict["Variable"] = variables
                }
                else if sort.abbreviation == "Commute" {
                    variables = sort.variables as? [String: Any]
                    var dict2 = variables!
                    let noMidCheckState = (dict2["NoMidCheckState"] as? NSNumber)?.boolValue ?? false
                    
                    var monThuesDept = dict2["MON_THURS_DEPART"] as? String
                    var monThuesRet = dict2["MON_THURS_RETURN"] as? String
                    var friDept = dict2["FRI_DEPART"] as? String
                    var friRet = dict2["FRI_RETURN"] as? String
                    var satDept = dict2["SAT_DEPART"] as? String
                    var satRet = dict2["SAT_RETURN"] as? String
                    var sunDept = dict2["SUN_DEPART"] as? String
                    var sunRet = dict2["SUN_RETURN"] as? String
                    
                    if monThuesDept == "-1" {
                        monThuesDept = ""
                    }
                    if friDept == "-1" {
                        friDept = ""
                    }
                    if satDept == "-1" {
                        satDept = ""
                    }
                    if sunDept == "-1" {
                        sunDept = ""
                    }
                    
                    if monThuesRet == "3000" {
                        monThuesRet = ""
                    }
                    if friRet == "3000" {
                        friRet = ""
                    }
                    if satRet == "3000" {
                        satRet = ""
                    }
                    if sunRet == "3000" {
                        sunRet = ""
                    }
                    
                    variables = [
                        "MON_THURS_DEPART": monThuesDept!,
                        "MON_THURS_RETURN": monThuesRet!,
                        "FRI_DEPART": friDept!,
                        "FRI_RETURN": friRet!,
                        "SAT_DEPART": satDept!,
                        "SAT_RETURN": satRet!,
                        "SUN_DEPART": sunDept!,
                        "SUN_RETURN": sunRet!,
                        "NoMidCheckState": NSNumber(value: noMidCheckState)
                    ]
                    dict["Variable"] = variables
                }
                else if currentTitle == "Regional Overnight Cities" {
                    if let tempSet = variables!["SET"] as? Set<AnyHashable> {
                        let newVariables: [String: Any] = ["CITY": Array(tempSet)]
                        dict["Variable"] = newVariables
                    }
                }
                else {
                    dict["Variable"] = sort.variables
                }
                dict["isMutable"] = sort.isMutable
                if sort.city != nil {
                    dict["City"] = sort.city
                }
                listSortArray.add(dict)
                var flag = false
                for i in 0 ..< sortsList.count {
                    let sortsListArray = sortsList
                    let dict: [String: Any] = sortsListArray[i] as! [String: Any]
                    var muteDict = dict
                    if muteDict["title"] as! String == currentTitle {
                        flag = true
                        let array = muteDict["Listfilter"] as? [Any]
                        var mutArray = array
                        mutArray?.append(listSortArray[0])
                        muteDict["ListSort"] = mutArray
                        sortsListArray.replaceObject(at: i, with: dict)
                        sortsList = sortsListArray.mutableCopy() as! NSMutableArray
                    }
                }
                
                if !flag {
                    listSortDict["title"] = self.sortTitleDict()[sort.abbreviation!]
                    listSortDict["Listfilter"] = listSortArray.mutableCopy()
                    sortsList.add(listSortDict)
                }
                listSortArray.removeAllObjects()
            }
        }
        //        MARK: Not isState
        else {
            var i = -1
            for case let sort as CBPresetLineSort in resultsSort {
                i += 1
                if sort.abbreviation == nil {
                    if(sort.name == "Overnight City") {
                        sort.abbreviation = "OvernightCity"
                    }
                    if(sort.name == "Legs Thru") {
                        sort.abbreviation = "LegsThru"
                    }
                    if(sort.name == "Days Off") {
                        sort.abbreviation = "Off"
                    }
                    if(sort.name == "Days of the Month Off") {
                        sort.abbreviation = "OffSort"
                    }
                    if(sort.name == "Days I want to Work") {
                        sort.abbreviation = "WorkSort"
                    }
                    if(sort.name == "Days I Don't Want Trips to Start") {
                        sort.abbreviation = "TripStartSort"
                    }
                }
                
                // resetting all the old abbriveation to new
                let sortName = sort.name!
                var requiredAbbreviation = self.sortNameAbbreviation()[sortName]
                if requiredAbbreviation != sort.abbreviation {
                    if "v\(String(describing: requiredAbbreviation))" == sort.abbreviation {
                        print("Emp completed Abbreviation converted from (Sort0: \(sortName)) \(sort.abbreviation ?? "") to v\(String(describing: requiredAbbreviation))")
                        sort.abbreviation = "v\(String(describing: requiredAbbreviation))"
                    } else {
                        if sort.abbreviation == "vBlk" {
                            requiredAbbreviation = "vBlk"
                        }
                        if sort.abbreviation == "v$/day" {
                            requiredAbbreviation = "v$/day"
                        }
                        print("Emp completed Abbreviation converted from (Sort1: \(sortName)) \(sort.abbreviation ?? "") to \(String(describing: requiredAbbreviation))")
                        sort.abbreviation = requiredAbbreviation
                    }
                }

                currentTitle = self.sortTitleDict()[sort.abbreviation!]!
                var dict = [String: Any]()
                dict["Category"] = sort.category
                dict["Abbreviation"] = sort.abbreviation
                dict["isSortScratchpad"] = NSNumber(booleanLiteral: true)
                if sort.isBidListSort == true {
                    dict["isSortScratchpad"] = NSNumber(booleanLiteral: false)
                }
                if sort.type != nil {
                    dict["type"] = sort.type
                }
                if sort.arrayVariables != nil {
                    dict["ArrayVariables"] = sort.arrayVariables
                }
                var sortOrder = sort.order?.intValue
                if isConversion {
                    sortOrder! += 1
                }
                else {
                    sortOrder! += 1
                }
                dict["Order"] = sortOrder
                dict["Name"] = sort.name
                dict["KeyPath"] = sort.keyPath
                let temp = sort.ascending
                dict["Ascending"] = temp?.boolValue
                var variables = sort.variables as? [String: Any]
                if (sort.abbreviation == "OffSort" || sort.abbreviation == "WorkSort" || sort.abbreviation == "TripStartSort") {
                    var variablesArray: [Int] = []
                    if let monthBits = sort.variables?["DAYS_OFF_MONTH_BITS"] as? UInt64 {
                        for index in 0..<calendarData!.calendarDays.count {
                            let mask: UInt64 = 1 << index
                            if (monthBits & mask) != 0 {
                                variablesArray.append(index)
                            }
                        }
                    }
                    dict["ArrayVariables"] = variablesArray
                    
                    if sort.abbreviation == "WorkSort" {
                        dict["Ascending"] = false
                    } else if sort.abbreviation == "OffSort" {
                        dict["Ascending"] = true
                    } else {
                        dict["Ascending"] = true
                    }
                }
                else if sort.abbreviation == "CmAuto" {
                    var isNonStop = 0 as NSNumber
                    if ((preset?.commutabilitySortDetails?["isNonStop"]) != nil) {
                        isNonStop = (preset!.commutabilitySortDetails!["isNonStop"] as? NSNumber)!
                    }
                    if preset?.commutabilitySortDetails == nil {
                        variables = [
                            "commuteCity": "ABQ",
                            "selectedConnectTime": "00:30",
                            "nonStop": 0,
                            "selectedTakeOffPadTimeValues": "01:00",
                            "selectedBackToBasePadTimeValues": "00:10",
                            "nMid": 1,
                            "cmtFrBaOv": 3,
                            "cmtGreaterOrLesser": 1,
                            "cmtPercentage": 100
                        ]
                    }
                    else
                    {
                        if preset?.commutabilitySortDetails?["city"] == nil {
                            preset?.commutabilitySortDetails?["city"] = "ABQ"
                        }

                        if preset?.commutabilitySortDetails?["connectTime"] == nil {
                            preset?.commutabilitySortDetails?["connectTime"] = 30
                        }

                        if preset?.commutabilitySortDetails?["checkInTime"] == nil {
                            preset?.commutabilitySortDetails?["checkInTime"] = 120
                        }

                        if preset?.commutabilitySortDetails?["baseTime"] == nil {
                            preset?.commutabilitySortDetails?["baseTime"] = 0
                        }

                        if preset?.commutabilitySortDetails?["secondCellValue"] == nil {
                            preset?.commutabilitySortDetails?["secondCellValue"] = 1
                        }

                        if preset?.commutabilitySortDetails?["thirdCellValue"] == nil {
                            preset?.commutabilitySortDetails?["thirdCellValue"] = 3
                        }

                        if preset?.commutabilitySortDetails?["type"] == nil {
                            preset?.commutabilitySortDetails?["type"] = 1
                        }

                        if preset?.commutabilitySortDetails?["value"] == nil {
                            preset?.commutabilitySortDetails?["value"] = 100
                        }

                        variables = [
                            "commuteCity": preset!.commutabilitySortDetails!["city"],
                            "selectedConnectTime": self.getHours(from: preset!.commutabilitySortDetails!["connectTime"] as! NSNumber),
                            "nonStop": isNonStop,
                            "selectedTakeOffPadTimeValues": self.getHours(from: preset!.commutabilitySortDetails!["checkInTime"] as! NSNumber),
                            "selectedBackToBasePadTimeValues": self.getHours(from: preset!.commutabilitySortDetails!["baseTime"] as! NSNumber),
                            "nMid": preset!.commutabilitySortDetails!["secondCellValue"],
                            "cmtFrBaOv": preset!.commutabilitySortDetails!["thirdCellValue"],
                            "cmtGreaterOrLesser": preset!.commutabilitySortDetails!["type"],
                            "cmtPercentage": preset!.commutabilitySortDetails!["value"],
                        ]
                    }
                    dict["Variable"] = variables
                }
                else if sort.abbreviation == "Commute" {
                    variables = sort.variables as? [String: Any]
                    var dict2 = variables!
                    let noMidCheckState = (dict2["NoMidCheckState"] as? NSNumber)?.boolValue ?? false
                    
                    var monThuesDept = dict2["MON_THURS_DEPART"] as? String
                    var monThuesRet = dict2["MON_THURS_RETURN"] as? String
                    var friDept = dict2["FRI_DEPART"] as? String
                    var friRet = dict2["FRI_RETURN"] as? String
                    var satDept = dict2["SAT_DEPART"] as? String
                    var satRet = dict2["SAT_RETURN"] as? String
                    var sunDept = dict2["SUN_DEPART"] as? String
                    var sunRet = dict2["SUN_RETURN"] as? String
                    
                    if monThuesDept == "-1" {
                        monThuesDept = ""
                    }
                    if friDept == "-1" {
                        friDept = ""
                    }
                    if satDept == "-1" {
                        satDept = ""
                    }
                    if sunDept == "-1" {
                        sunDept = ""
                    }
                    
                    if monThuesRet == "3000" {
                        monThuesRet = ""
                    }
                    if friRet == "3000" {
                        friRet = ""
                    }
                    if satRet == "3000" {
                        satRet = ""
                    }
                    if sunRet == "3000" {
                        sunRet = ""
                    }
                    
                    variables = [
                        "MON_THURS_DEPART": monThuesDept!,
                        "MON_THURS_RETURN": monThuesRet!,
                        "FRI_DEPART": friDept!,
                        "FRI_RETURN": friRet!,
                        "SAT_DEPART": satDept!,
                        "SAT_RETURN": satRet!,
                        "SUN_DEPART": sunDept!,
                        "SUN_RETURN": sunRet!,
                        "NoMidCheckState": NSNumber(value: noMidCheckState)
                    ]
                    dict["Variable"] = variables
                }
                else if currentTitle == "Regional Overnight Cities" {
                    if let tempSet = variables!["SET"] as? Set<AnyHashable> {
                        let newVariables: [String: Any] = ["CITY": Array(tempSet)]
                        dict["Variable"] = newVariables
                    }
                }
                else {
                    dict["Variable"] = sort.variables
                }
                dict["isMutable"] = sort.isMutable
                if sort.city != nil {
                    dict["City"] = sort.city
                }
                listSortArray.add(dict)
                var flag = false
                for i in 0 ..< sortsList.count {
                    let sortsListArray = sortsList
                    let dict: [String: Any] = sortsListArray[i] as! [String: Any]
                    var muteDict = dict
                    if muteDict["title"] as! String == currentTitle {
                        flag = true
                        let array = muteDict["Listfilter"] as? [Any]
                        var mutArray = array
                        mutArray?.append(listSortArray[0])
                        muteDict["ListSort"] = mutArray
                        sortsListArray.replaceObject(at: i, with: dict)
                        sortsList = sortsListArray.mutableCopy() as! NSMutableArray
                    }
                }
                
                if !flag {
                    listSortDict["title"] = self.sortTitleDict()[sort.abbreviation!]
                    listSortDict["Listfilter"] = listSortArray.mutableCopy()
                    sortsList.add(listSortDict)
                }
                listSortArray.removeAllObjects()
            }
        }
        
        var defaultCommuteTimes = UserDefaults.standard.array(forKey: kCBDefaultCommutingTimesKey)
        var defaultCommutingValues = [String: Any]()
           if defaultCommuteTimes != nil {

               let monThursDept = "\(defaultCommuteTimes![0])"
               let monThursRet  = "\(defaultCommuteTimes![1])"
               let friDept      = "\(defaultCommuteTimes![2])"
               let friRet       = "\(defaultCommuteTimes![3])"
               let satDept      = "\(defaultCommuteTimes![4])"
               let satRet       = "\(defaultCommuteTimes![5])"
               let sunDept      = "\(defaultCommuteTimes![6])"
               let sunRet       = "\(defaultCommuteTimes![7])"

            defaultCommutingValues = [
                "MON_THURS_DEPART": monThursDept,
                "MON_THURS_RETURN": monThursRet,
                "FRI_DEPART": friDept,
                "FRI_RETURN": friRet,
                "SAT_DEPART": satDept,
                "SAT_RETURN": satRet,
                "SUN_DEPART": sunDept,
                "SUN_RETURN": sunRet,
                "NoMidCheckState": false
            ]
        }
        var lstSortDict = [String: Any]()
        lstSortDict = ["lstSorts": sortsList]
        if defaultCommutingValues.count > 0 {
            lstSortDict = [
                "lstSorts": sortsList,
                "DefaultCommutingValues": defaultCommutingValues
            ]
        }
        return lstSortDict
    }
    
    
    func filterNameAbbreviation() -> [String: String] {
        let filterNameAbbreviation: [String: String] = [
            "Aircraft Changes": "Chngs",
            "Days of Reserve": "reserveDays",
            "Aircraft Type 700": "700s",
            "Aircraft Type 800": "800s",
            "Aircraft Type 8MAX": "8Max",
            "Aircraft Type 7MAX": "7Max",
            "Aircraft Type 8Max": "8Max",
            "Aircraft Type 7Max": "7Max",
            "Block of Days Off": "BlkOff",
            "Block Hours": "BlkHrs",
            "Overnight City": "OC",
            "Leg City": "LegCty",
            "Overnight Cities-Bulk": "OCB",
            "NonConUS Legs": "NonConLegs",
            "East Coast": "EC",
            "West Coast": "WC",
            "NonConUS": "NonConUS",
            "All Cities": "AllC",
            "Hawaii": "Hawaii",
            "Days Off": "Off",
            "Weekends": "Wknds",
            "Sundays": "Su",
            "Mondays": "Mo",
            "Tuesdays": "Tu",
            "Wednesdays": "Wed",
            "Thursdays": "Th",
            "Fridays": "Fr",
            "Saturdays": "Sa",
            "Legs": "Legs",
            "Max Legs in a Day": "MLegs",
            "Overnights in Base": "OIBs",
            "Passes Through Base": "PTBs",
            "Passes through Base": "PTBs",
            "Mid-Trip PTBs": "MidPTBs",
            "TAFB Hours": "TAFB",
            "Number of Trips": "Trips",
            "Turns": "Turns",
            "Two Day Trips": "2Days",
            "Three Day Trips": "3Days",
            "Four Day Trips": "4Days",
            "Workdays": "Work",
            "Flags": "Flags",
            "Days I Want Off": "MonthDays",
            "Days I Want To Work": "WantDays",
            "Days I Don't Want Trips To Start": "TripStarts",
            "Days I Don't Want Trips To End": "TripEnds",
            "Duty Hours": "DtyHrs",
            "Duty Hours Per Day": "Dty/Day",
            "Pay": "Pay",
            "Pay Per Block Hour": "$/Blk",
            "Pay Per Day": "$/Day",
            "Pay Per Duty Hour": "$/Duty",
            "Pay Per Leg": "$/Leg",
            "Pay Per TAFB": "$/Tafb",
            "Carry Out Pay": "CoPay",
            "Line Rig": "Line Rig",
            "Commutability": "CmAuto",
            "Commuting - Manual": "CRqd",
            "Commuting - Auto": "CmAuto",
            "Month Start Overlap": "StartOLap",
            "Month End Overlap": "EndOLap",
            "Overnight Length": "OLength",
            "Deadheads": "DHs",
            "DH At Start To": "DH Start",
            "DH At End From": "DH End",
            "DH At Either": "DH Either",
            "Total Pay": "vTotalPay",
            "Fly Pay": "vFlyPay",
            "Vacation Pay": "vVacPay",
            "Pay Per Block": "v$/blk",
            "Pay Per Day": "v$/day",
            "Block Time": "vBlk",
            "Days Off": "vOff",
            "Eff. Vac. Length": "vVacayLength",
            "Carry Out VA Pay": "vVOutPay",
            "Report-Release": "Report-Release",
            "WorkBlocks": "workBlock",
            "VA Pay": "vVacPay",
            "Carry Out Fly Pay": "vCarryPay",
            "Carry Out VO Pay": "vCOutVOPay",
            "Longest Blk Off": "vLongest",
            "Front VO Pay": "vFrontVO",
            "Back VO Pay": "vBackVO",
            "WorkBlocks Count": "wrkBlkCount",
            "Ground Time Max": "Ground Time Max",
            "Ground Time Average": "Ground Time Average",
            "Overnight Average": "OvAvg",
            "1 or 2 day off": "1 or 2 day off",
            "Red Eye Trips": "RedEyeTrips"
        ]
        return filterNameAbbreviation
    }
    
    func filterTitleDict() -> [String: String] {
        let filterDict: [String: String] = [
            "Chngs": "Aircraft Changes",
            "reserveDays": "Days of Reserve",
            "700s": "Aircraft Types",
            "800s": "Aircraft Types",
            "8Max": "Aircraft Types",
            "7Max": "Aircraft Types",
            "BlkOff": "Block of Days Off",
            "BlkHrs": "Block Hours",
            "OC": "Cities",
            "OCB": "Cities",
            "NonConLegs": "Cities",
            "LegCty": "Cities",
            "EC": "Regional Overnight Cities",
            "WC": "Regional Overnight Cities",
            "NonConUS": "Regional Overnight Cities",
            "AllC": "Regional Overnight Cities",
            "Hawaii": "Regional Overnight Cities",
            "CRqd": "Commuting",
            "CmAuto": "Commuting",
            "MonthDays": "Days of the Month",
            "WantDays": "Days of the Month",
            "TripStarts": "Days of the Month",
            "TripEnds": "Days of the Month",
            "Off": "Days Off",
            "Wknds": "Days of Week",
            "Su": "Days of Week",
            "Mo": "Days of Week",
            "Tu": "Days of Week",
            "Wed": "Days of Week",
            "Th": "Days of Week",
            "Fr": "Days of Week",
            "Sa": "Days of Week",
            "DHs": "Deadheads",
            "DH Start": "Deadheads",
            "DH End": "Deadheads",
            "DH Either": "Deadheads",
            "DtyHrs": "Duty Time",
            "Dty/Day": "Duty Time",
            "Flags": "Flags",
            "Legs": "Legs",
            "MLegs": "Max Legs in a Day",
            "StartOLap": "Overlap Days",
            "EndOLap": "Overlap Days",
            "OLength": "Overnight Length",
            "OIBs": "Overnights in Base",
            "PTBs": "Passes Through Base",
            "MidPTBs": "Passes Through Base",
            "Pay": "Pay",
            "Pay/Blk": "Pay",
            "Pay/Day": "Pay",
            "Pay/Duty": "Pay",
            "Pay/Leg": "Pay",
            "Pay/Tafb": "Pay",
            "Pay/Dty": "Pay",
            "$/Blk": "Pay",
            "$/Day": "Pay",
            "$/Duty": "Pay",
            "$/Leg": "Pay",
            "$/Tafb": "Pay",
            "CoPay": "Pay",
            "Line Rig": "Pay",
            "TAFB": "TAFB Hours",
            "Trips": "Number of Trips",
            "Turns": "Trip Length",
            "2Days": "Trip Length",
            "3Days": "Trip Length",
            "4Days": "Trip Length",
            "Work": "Workdays",
            "wrkBlkCount": "WorkBlocks Count",
            "vTotalPay": "Vacation",
            "vFlyPay": "Vacation",
            "vVacPay": "Vacation",
            "v$/blk": "Vacation",
            "v$/day": "Vacation",
            "vCarryPay": "Vacation",
            "vCOutVOPay": "Vacation",
            "vBlk": "Vacation",
            "vOff": "Vacation",
            "vVacayLength": "Vacation",
            "vLongest": "Vacation",
            "vVOutPay": "Vacation",
            "vFrontVO": "Vacation",
            "vBackVO": "Vacation",
            "workBlock": "WorkBlocks",
            "Report-Release": "Report-Release",
            "RptRls": "Report-Release",
            "Ground Time Max": "Ground Time",
            "Ground Time Average": "Ground Time",
            "OvAvg": "Overnight Average",
            "1 or 2 day off": "1 or 2 day off",
            "RedEyeTrips": "Red Eye Trips"
        ]
        return filterDict
    }

    func getHours(from minutes: NSNumber) -> String {
        let totalMinutes = minutes.intValue
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }
    
    func getQuickFilterDefaultDict() -> [String: Bool] {
        var dict: [String: Bool]

        if bidPeriod?.isFABid() == true {
            dict = [
                "mixed": false,
                "conUs": false,
                "nonConUs": false,
                "reserve": false,
                "lodo": false,
                "blank": false,
                "etops": false,
                "etopsRes": false,
                "amLines": false,
                "pmLines": false,
                "mixedLines": false,
                "redEyeAmPmLines": false,
                "posA": false,
                "posB": false,
                "posC": false,
                "posD": false,
                "posMultiple": false,
                "posNA": false,
                "sun": false,
                "mon": false,
                "tue": false,
                "wed": false,
                "thu": false,
                "fri": false,
                "sat": false,
                "turns": false,
                "twoDays": false,
                "threeDays": false,
                "fourDays": false
            ]

            if bidPeriod!.isSecondRoundBid() {
                dict["SnrAMres"] = false
                dict["SnrPMres"] = false
                dict["JnrAMres"] = false
                dict["JnrPMres"] = false
                dict["JnrLateRes"] = false
            }

        } else {
            dict = [
                "mixed": false,
                "hard": false,
                "conUs": false,
                "nonConUs": false,
                "reserve": false,
                "blank": false,
                "etops": false,
                "etopsRes": false,
                "amLines": false,
                "pmLines": false,
                "redEyeAmPmLines": false,
                "mixedLines": false,
                "sun": false,
                "mon": false,
                "tue": false,
                "wed": false,
                "thu": false,
                "fri": false,
                "sat": false,
                "turns": false,
                "twoDays": false,
                "threeDays": false,
                "fourDays": false
            ]
        }

        return dict
    }
    
    func sortNameAbbreviation() -> [String: String] {
        let sortNameAbbreviation: [String: String] = [
            "rigADG": "rigADG",
            "rigDHR": "rigDHR",
            "rigDPM": "rigDPM",
            "rigTHR": "rigTHR",
            "TripTfp": "TripTfp",
            "HoliRig": "HoliRig",
            "vaNE": "vaNE",
            "vpCu+vaNe": "vpCuPlusVaNe",
            "Days Off": "Off",
            "Days of Reserve": "reserveDays",
            "Aircraft Changes": "Chngs",
            "Legs": "Legs",
            "Aircraft Type 700": "700s",
            "Aircraft Type 800": "800s",
            "Aircraft Type 8Max": "8Max",
            "Aircraft Type 7Max": "7Max",
            "Aircraft Type 8MAX": "8Max",
            "Aircraft Type 7MAX": "7Max",
            "Aircraft Type MAX": "8Max",
            "Days I Don't Want Trips to Start": "TripStartSort",
            "Days I want to Work": "WorkSort",
            "AM then PM": "AM",
            "PM then AM": "PM",
            "Block of Days Off": "BlkOff",
            "Block Time": "BlkHrs",
            "Weekends": "Wknds",
            "Sundays": "Su",
            "Mondays": "Mo",
            "Tuesdays": "Tu",
            "Wednesdays": "Wed",
            "Thursdays": "Th",
            "Fridays": "Fr",
            "Saturdays": "Sa",
            "Turns": "Turns",
            "Two Day Trips": "2Days",
            "Three Day Trips": "3Days",
            "Four Day Trips": "4Days",
            "Trips": "Trips",
            "Work Days": "Work",
            "Earliest Departure": "EDep",
            "Latest Arrival": "LArr",
            "Max Legs in a Day": "MLegs",
            "TAFB": "TAFB",
            "Flags": "flag",
            "Overnight City": "OvernightCity",
            "Legs Thru": "Legs Thru",
            "NonConUS Legs": "NonConLegs",
            "East Coast": "EC",
            "West Coast": "WC",
            "NonConUS": "NonConUS",
            "All Cities": "AllC",
            "Hawaii": "Hawaii",
            "Days of the Month Off": "OffSort",
            "Duty Hours": "Dty",
            "Duty Hours Per Day": "Dty/Day",
            "Pay": "Pay",
            "Pay per Block Hour": "$/Blk",
            "Pay per Day": "$/Day",
            "Pay per Duty Hour": "$/Duty",
            "Pay per Leg": "$/Leg",
            "Pay per TAFB": "$/TAFB",
            "Carry Out Pay": "CoPay",
            "Line Rig": "linerig",
            "Overnights in Base": "OIBs",
            "Passes Through Base": "PTBs",
            "Passes through Base": "PTBs",
            "Mid-Trip PTBs": "MidPTBs",
            "Min O-Nite Length": "minNite",
            "Max O-Nite Length": "maxNite",
            "ETOPS": "eTops",
            "LODO": "lodo",
            "ETOPS Trips": "eTrips",
            "Overlap Days": "OLap",
            "Vac+LG": "TpL",
            "Deadheads": "DHs",
            "Deadheads*": "DHs",
            "DH At Start": "DH Start",
            "DH At End": "DH End",
            "DH At Either": "DH At Both",
            "Total Pay": "vTotalPay",
            "Fly Pay": "vFlyPay",
            "Vac Pay in BP": "vVacationPay",
            "Vacation Pay": "vVacationPay",
            "Vac Pay next BP": "vVacPayNext",
            "Vac Pay both BP": "vVacPayBoth",
            "Pay Per Block": "v$/blk",
            "Pay Per Day": "v$/day",
            "Block Time": "vBlk",
            "Days Off": "vOff",
            "Eff. Vac. Length": "vVacayLength",
            "CarryOut VA Pay": "vVOutPay",
            "Commutability": "CmAuto",
            "Commuting-Manual": "Commute",
            "Commuting - Auto": "CmAuto",
            "Quick Add Positions A-B-C": "positionABC",
            "Position A": "A",
            "Position B": "B",
            "Position C": "C",
            "CarryOut Fly Pay": "vCOutPay",
            "CarryOut VO Pay": "vCOutVOPay",
            "Longest Blk Off": "vLongest",
            "Front VO Pay": "vFrontVO",
            "Back VO Pay": "vBackVO",
            "WorkBlocks Count": "wrkBlkCount",
            "Ground Time Max": "Ground Time Max",
            "Ground Time Average": "Ground Time Average",
            "Overnight Average": "OvAvg",
            "Red Eye Trips": "RedEyeTrips"
        ]
        return sortNameAbbreviation
    }
    
    func sortTitleDict() -> [String: String] {
        let sortDict: [String: String] = [
            "rigADG": "rigADG",
            "rigDHR": "rigDHR",
            "rigDPM": "rigDPM",
            "rigTHR": "rigTHR",
            "TripTfp": "TripTfp",
            "HoliRig": "HoliRig",
            "eTrips": "ETOPS Trips",
            "reserveDays": "Days of Reserve",
            "Chngs": "Aircraft Changes",
            "700s": "Aircraft Types",
            "TripStartSort": "Days of the Month Off",
            "WorkSort": "Days of the Month Off",
            "800s": "Aircraft Types",
            "8Max": "Aircraft Types",
            "7Max": "Aircraft Types",
            "AM": "AM/PM",
            "PM": "AM/PM",
            "BlkOff": "Block of Days Off",
            "BlkHrs": "Block Hours",
            "Overnight City": "Cities",
            "OvernightCity": "Cities",
            "OCB": "Cities",
            "Legs Thru": "Cities",
            "NonConLegs": "Cities",
            "EC": "Regional Overnight Cities",
            "WC": "Regional Overnight Cities",
            "NonConUS": "Regional Overnight Cities",
            "AllC": "Regional Overnight Cities",
            "Hawaii": "Regional Overnight Cities",
            "Wknds": "Days of Week",
            "Su": "Days of Week",
            "Mo": "Days of Week",
            "Tu": "Days of Week",
            "Wed": "Days of Week",
            "Th": "Days of Week",
            "Fr": "Days of Week",
            "Sa": "Days of Week",
            "Off": "Days Off",
            "OffSort": "Days of the Month Off",
            "DHs": "Deadheads",
            "DH Start": "Deadheads",
            "DH End": "Deadheads",
            "DH Either": "Deadheads",
            "DH At Both": "Deadheads",
            "Dty": "Duty Time",
            "Dty/Day": "Duty Time",
            "EDep": "Earliest Departure",
            "eTops": "ETOPS",
            "lodo": "LODO",
            "flag": "Flags",
            "LArr": "Latest Arrival",
            "Legs": "Legs",
            "MLegs": "Max Legs in a Day",
            "OLap": "Overlap Days",
            "OIBs": "Overnights in Base",
            "minNite": "Overnight Length",
            "maxNite": "Overnight Length",
            "PTBs": "Passes through Base",
            "MidPTBs": "Passes through Base",
            "Pay": "Pay",
            "Pay/Blk": "Pay",
            "Pay/Leg": "Pay",
            "Pay/Day": "Pay",
            "Pay/Duty": "Pay",
            "Pay/Dty": "Pay",
            "Pay/Tafb": "Pay",
            "Pay/TAFB": "Pay",
            "$/Blk": "Pay",
            "$/Day": "Pay",
            "$/Duty": "Pay",
            "$/Leg": "Pay",
            "$/Tafb": "Pay",
            "CoPay": "Pay",
            "linerig": "Pay",
            "TAFB": "TAFB",
            "Turns": "Trip Length",
            "2Days": "Trip Length",
            "3Days": "Trip Length",
            "4Days": "Trip Length",
            "Trips": "Trips",
            "TpL": "Vac+LG",
            "Work": "Work Days",
            "wrkBlkCount": "WorkBlocks Count",
            "vTotalPay": "Vacation",
            "vFlyPay": "Vacation",
            "vVacationPay": "Vacation",
            "v$/blk": "Vacation",
            "v$/day": "Vacation",
            "vCarryPay": "Vacation",
            "vCOutVOPay": "Vacation",
            "vVacPayBoth": "Vacation",
            "vVacPayNext": "Vacation",
            "vBlk": "Vacation",
            "vOff": "Vacation",
            "vVacayLength": "Vacation",
            "vLongest": "Vacation",
            "vVOutPay": "Vacation",
            "vFrontVO": "Vacation",
            "vBackVO": "Vacation",
            "vaNE": "Vacation",
            "vpCuPlusVaNe": "Vacation",
            "Commute": "Commuting",
            "CmAuto": "Commuting",
            "A": "Position",
            "B": "Position",
            "C": "Position",
            "positionABC": "Position",
            "Ground Time Max": "Ground Time",
            "Ground Time Average": "Ground Time",
            "OvAvg": "Overnight Average",
            "RedEyeTrips": "Red Eye Trips"
        ]
        
        return sortDict
    }

    func mergeDictionaries(_ dictionaryArray: [[String: Any]]) -> [String: Any] {
        var result: [String: Any] = [:]
        
        for dictionary in dictionaryArray {
            for (key, value) in dictionary {
                if let keyString = key as? String {
                    result[keyString] = value
                }
            }
        }
        
        return result
    }

    func presetTakeServer(completion: @escaping ([[String: Any]]?) -> Void) {
        var dictDetails: [String: Any] = [:]
        dictDetails["Employeeumber"] = app.ObjUserAccount?.employeeNumber
            dictDetails["StateName"] = NSNull()
        dictDetails["PresetFileName"] = app.ObjUserAccount?.employeeNumber
        dictDetails["Year"] = bidPeriod!.year
            dictDetails["FileType"] = 1

        objdatabuilder.getCrewBidStateAndPresetFromServer(dictDetails: dictDetails) { result in
            if let result = result {
                let responseDict = result[0]
                let isOldPreset = responseDict["IsOldPreset"] as? NSNumber
                if isOldPreset?.boolValue == true {
                    completion(result)
                    return
                }
                if responseDict["PreSetStateContent"] != nil {
                    let contentString = responseDict["PreSetStateContent"] as? String
                    let contentDictArray = self.convertStringToDictionary(contentString!)
                    DispatchQueue.main.async {
                        self.setPresetToLocalDB(details: contentDictArray!)
                    }
                    DispatchQueue.main.async {
                        AlertService.showAlertForTopVC(title: "Synced!", message: "Preset sync was successful!")
                    }
                }
                else {
                    AlertService.showAlertForTopVC(title: "Error!", message: "Preset from server is NULL")
                }
            }
            else {
                AlertService.showAlertForTopVC(title: "Error!", message: "Something went wrong")
            }
        }
    }
    
    func convertStringToDictionary(_ string: String) -> [[String: Any]]? {
        guard let data = string.data(using: .utf8) else { return nil }
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                return jsonArray
            } else {
                print("⚠️ JSON is not an array of dictionaries")
                return nil
            }
        } catch {
            print("❌ JSON parsing error: \(error.localizedDescription)")
            return nil
        }
    }

    func setPresetToLocalDB(details: [[String: Any]]) {
        let presetsArray = NSMutableArray()
        for presetDict in details {
            if presetDict["filterSortState"] == nil {
                return
            }
            var synchedPreset = CBPreset()
            var filterSorts = presetDict["filterSortState"] as? [String: Any]
            let presetSorts = self.getPresetSortObjects(details: filterSorts!, syncPreset: synchedPreset)
            var presetQuickFilters = self.getPresetQuickFilterObjects(from: filterSorts!)
            let presetMenuFilters = self.getPresetFilterObjects(from: filterSorts!)
            presetQuickFilters.addObjects(from: presetMenuFilters as! [Any])
            let lineValuesKey = CBLineValuesMenuController.lineValuesKeyForBidPeriod(bidPeriod: self.bidPeriod!)
            let lineValues = UserDefaults.standard.array(forKey: lineValuesKey)
            synchedPreset.lineValues = lineValues ?? []
            synchedPreset.lineSorts = presetSorts as! [CBPresetLineSort]
            synchedPreset.filterRules = presetQuickFilters as! [CBPresetFilterRule]
            synchedPreset.name = presetDict["presetName"] as? String
            synchedPreset.month = bidPeriod!.month
            synchedPreset.year = self.bidPeriod!.year
            synchedPreset.position = self.bidPeriod!.positionType
            synchedPreset.appVersion = self.bidPeriod!.appVersion
            synchedPreset.presetIdentifier = presetDict["presetIdentifier"] as? String
            synchedPreset.selected = 0
            if synchedPreset.selected?.boolValue == true {
                DispatchQueue.main.async {
                    self.setQuickFilterToLocalDB(details: filterSorts!)
                    self.setFilterToLocalDB(details: filterSorts!)
                    self.setSortToLocalDB(details: filterSorts!)
                    self.bidPeriod?.loadedPresetIdentifier = synchedPreset.presetIdentifier
                }
            }
            presetsArray.add(synchedPreset)
        }
        self.savePresets(presetArray: presetsArray)
    }
    
    func getPresetSortObjects(details: [String: Any], syncPreset: CBPreset) -> NSMutableArray {
        let lineSorts = NSMutableArray()
        let lstSorts = details["lstSorts"] as? NSMutableArray
        for case let sortDict as [String: Any] in lstSorts ?? [] {
            let subSorts = sortDict["ListSort"] as? NSMutableArray
            
            // saveing each filters from the json to coredata.
            for case let subSort as [String: Any] in subSorts ?? [] {
                let lineSort = CBPresetLineSort()
                lineSort.abbreviation = subSort["Abbreviation"] as? String
                lineSort.category = NSNumber(value: (subSort["Category"] as? Int)!)
                if subSort["Type"] != nil {
                    lineSort.type = NSNumber(value: (subSort["Type"] as? Int)!)
                }
                else {
                    lineSort.type = 0
                }
                
                if subSort["ArrayVariables"] != nil {
                    let dct = subSort["ArrayVariables"] as? NSMutableArray
                    lineSort.arrayVariables = dct
                    if (lineSort.abbreviation == "OffSort" || lineSort.abbreviation == "WorkSort" || lineSort.abbreviation == "TripStartSort") {
                        lineSort.variables = BILineSort.configureMonthDayFilter(lineSort.arrayVariables!)
                    }
                }
                
                if lineSort.abbreviation == "CmAuto" {
                    var commutabilitySortDetails = [String: Any]()
                    let variable  = subSort["Variable"] as? [String: Any]
                    commutabilitySortDetails["city"] = variable?["commuteCity"]
                    
                    if variable!["selectedTakeOffPadTimeValues"] as? String != nil {
                        let checkInTime = (variable!["selectedTakeOffPadTimeValues"] as? String)!
                        commutabilitySortDetails["checkInTime"] = self.getMinutes(from: checkInTime)
                    }
                    else {
                        let checkInTime = variable!["selectedTakeOffPadTimeValues"] as? NSNumber
                        commutabilitySortDetails["checkInTime"] = self.getMinutes(from: checkInTime!.stringValue)
                    }
                    
                    if variable!["cmtFrBaOv"] as? String != nil {
                        commutabilitySortDetails["cmtFrBaOv"] = variable?["thirdCellValue"]
                    }
                    else {
                        let thirdCellValue = variable!["cmtFrBaOv"] as? NSNumber
                        commutabilitySortDetails["cmtFrBaOv"] = thirdCellValue?.stringValue
                    }
                    if variable!["selectedBackToBasePadTimeValues"] as? String != nil {
                        let baseTime = (variable!["selectedBackToBasePadTimeValues"] as? String)!
                        commutabilitySortDetails["baseTime"] = self.getMinutes(from: baseTime)
                    }
                    else {
                        let baseTime = variable!["selectedBackToBasePadTimeValues"] as? NSNumber
                        commutabilitySortDetails["baseTime"] = self.getMinutes(from: baseTime!.stringValue)
                    }
                    if variable!["cmtGreaterOrLesser"] as? String != nil {
                        commutabilitySortDetails["type"] = variable?["cmtGreaterOrLesser"]
                    }
                    else {
                        var type = variable?["cmtGreaterOrLesser"] as? NSNumber
                        if type == nil {
                            type = 1
                        }
                        commutabilitySortDetails["type"] = type
                    }
                    if variable!["selectedConnectTime"] as? String != nil {
                        let connectTime = (variable!["selectedConnectTime"] as? String)!
                        commutabilitySortDetails["connectTime"] = self.getMinutes(from: connectTime)
                    }
                    else {
                        let connectTime = variable!["selectedConnectTime"] as? NSNumber
                        commutabilitySortDetails["connectTime"] = self.getMinutes(from: connectTime!.stringValue)
                    }
                    if variable!["cmtPercentage"] as? String != nil {
                        commutabilitySortDetails["value"] = variable?["cmtPercentage"]
                    }
                    else {
                        var value = variable?["cmtPercentage"] as? NSNumber
                        if value == nil {
                            value = 100
                        }
                        commutabilitySortDetails["value"] = value
                    }
                    if variable!["nMid"] as? String != nil {
                        commutabilitySortDetails["secondCellValue"] = variable?["nMid"]
                    }
                    else {
                        var secondCellValue = variable?["nMid"] as? NSNumber
                        if secondCellValue == nil {
                            secondCellValue = 1
                        }
                        commutabilitySortDetails["secondCellValue"] = secondCellValue
                    }
                    commutabilitySortDetails["weight"] = 0
                    if variable?["nonStop"] != nil {
                        commutabilitySortDetails["isNonStop"] = variable?["nonStop"]
                    }
                    else {
                        commutabilitySortDetails["isNonStop"] = 0
                    }
                    
                    syncPreset.commutabilitySortDetails = NSMutableDictionary(dictionary: commutabilitySortDetails)
                }
                if lineSort.abbreviation == "flag" {
                    var variable = [String: Any]()
                    if lineSort.variables == nil {
                        lineSort.variables = variable
                    }
                    for val in lineSort.arrayVariables! {
                        guard let val = val as? NSNumber else { continue }
                        
                        switch val {
                        case 0:
                            variable["NO_COLOR_FLAG"] = val
                        case 1:
                            variable["BLUE_COLOR_FLAG"] = val
                        case 2:
                            variable["GREEN_COLOR_FLAG"] = val
                        case 3:
                            variable["RED_COLOR_FLAG"] = val
                        case 4:
                            variable["YELLOW_COLOR_FLAG"] = val
                        case 5:
                            variable["ORANGE_COLOR_FLAG"] = val
                        case 6:
                            variable["BROWN_COLOR_FLAG"] = val
                        case 7:
                            variable["PINK_COLOR_FLAG"] = val
                        default:
                            break
                        }
                    }
                    if variable.count > 0 {
                        lineSort.variables = variable
                    }
                    else {
                        continue
                    }
                }
                lineSort.order = NSNumber(value: (subSort["Order"] as? Int)!)
                lineSort.name = subSort["name"] as? String
                lineSort.keyPath = subSort["KeyPath"] as? String
                let ascending = subSort["Ascending"] as? Bool ?? false
                lineSort.ascending = NSNumber(booleanLiteral: ascending)
                lineSort.isMutable = NSNumber(value: (subSort["isMutable"] as? Int)!)
                if subSort["City"] != nil {
                    lineSort.city = subSort["City"] as? String
                }
                if subSort["Variable"] != nil {
                    lineSort.variables = subSort["Variable"] as? [String: Any]
                }
                lineSorts.add(lineSort)
            }
        }
        return lineSorts
    }
    
    func getMinutes(from hours: String) -> NSNumber {
        let components = hours.split(separator: ":")
        let hour = Int(components.first ?? "0") ?? 0
        let mins = Int(components.last ?? "0") ?? 0
        let totalMinutes = (hour * 60) + mins
        return NSNumber(value: totalMinutes)
    }
    
    func getPresetQuickFilterObjects(from details: [String: Any]) -> NSMutableArray {
        let presetFilterRules = NSMutableArray()
        let lstQuickFiltersArray = details["lstQuickFilters"] as? NSMutableArray
        var lstQuickFilters = [String: Any]()
        if lstQuickFilters.count == 0 {
            lstQuickFilters = self.getQuickFilterDefaultDict()
        }
        else {
            lstQuickFilters = lstQuickFiltersArray![0] as? [String: Any] ?? [:]
        }
        var set = Set<Int>()
        var filterRule = CBPresetFilterRule()
        filterRule.category = 0
        filterRule.type = 0
        if self.bidPeriod!.isEtopsLinesContainsInBid?.boolValue == true {
            //            ETOPS
            if bidPeriod!.isSecondRoundBid() {
                set.insert(4)
                if let nonConUs = lstQuickFilters["nonConUs"] as? NSNumber, !nonConUs.boolValue {
                    set.insert(7)
                }
                if let conUs = lstQuickFilters["conUs"] as? NSNumber, !conUs.boolValue {
                    set.insert(8)
                }
                if let etops = lstQuickFilters["etops"] as? NSNumber, !etops.boolValue {
                    set.insert(9)
                }
                if let hard = lstQuickFilters["hard"] as? NSNumber, !hard.boolValue {
                    set.insert(10)
                }
                if let mixed = lstQuickFilters["mixed"] as? NSNumber, !mixed.boolValue {
                    set.insert(11)
                }
                if let reserve = lstQuickFilters["reserve"] as? NSNumber, !reserve.boolValue {
                    set.insert(3)
                }
                //                ETOPS FA Second Round
                if bidPeriod!.isFABid() {
                    set.insert(9)
                    if let nonConUs = lstQuickFilters["nonConUs"] as? NSNumber, !nonConUs.boolValue {
                        set.insert(2)
                    }
                    if let conUs = lstQuickFilters["conUs"] as? NSNumber, !conUs.boolValue {
                        set.insert(1)
                    }
                    if let reserve = lstQuickFilters["reserve"] as? NSNumber, !reserve.boolValue {
                        set.insert(3)
                    }
                }
            }
            else {
                //                ETOPS First Round
                //                for Pilot
                if self.bidPeriod!.isFABid() == false {
                    set.insert(1)
                    set.insert(2)
                    set.insert(3)
                    set.insert(5)
                    set.insert(9)
                    set.insert(12)
                }
                else {
                    set.insert(1)
                    set.insert(2)
                    set.insert(13)
                }
                if let nonConUs = lstQuickFilters["nonConUs"] as? NSNumber, !nonConUs.boolValue {
                    set.insert(7)
                }
                if let conUs = lstQuickFilters["conUs"] as? NSNumber, !conUs.boolValue {
                    set.insert(8)
                }
                if let blank = lstQuickFilters["blank"] as? NSNumber, !blank.boolValue {
                    set.insert(4)
                }
            }
            if let reserve = lstQuickFilters["reserve"] as? NSNumber, !reserve.boolValue {
                set.insert(6)
            }
        }
        else {
            //            NON ETOPS
            //            Second Round
            if bidPeriod!.isSecondRoundBid() {
                set.insert(1)
                set.insert(2)
                set.insert(4)
                //                for pilot
                if bidPeriod!.isFABid() == false {
                    if let hard = lstQuickFilters["hard"] as? NSNumber, !hard.boolValue {
                        set.insert(0)
                    }
                    if let mixed = lstQuickFilters["mixed"] as? NSNumber, !mixed.boolValue {
                        set.insert(5)
                    }
                }
            }
            else {
                //             NON ETOPS First Round
                if let nonConUs = lstQuickFilters["nonConUs"] as? NSNumber, !nonConUs.boolValue {
                    set.insert(2)
                }
                if let conUs = lstQuickFilters["conUs"] as? NSNumber, !conUs.boolValue {
                    set.insert(1)
                }
                if let blank = lstQuickFilters["blank"] as? NSNumber, !blank.boolValue {
                    set.insert(4)
                }
                if let mixed = lstQuickFilters["mixed"] as? NSNumber, !mixed.boolValue {
                    set.insert(5)
                }
            }
            if let reserve = lstQuickFilters["reserve"] as? NSNumber, !reserve.boolValue {
                set.insert(3)
            }
        }
        var dict = [String: Any]()
        dict = ["SET": set]
        filterRule.variables = dict
        presetFilterRules.add(filterRule)
        
//        for FA
        if self.bidPeriod!.isFABid() {
            if lstQuickFilters["posA"] != nil {
                set.removeAll()
                filterRule = CBPresetFilterRule()
                filterRule.category = 3
                filterRule.type = 0
                
                if let posA = lstQuickFilters["posA"] as? NSNumber, !posA.boolValue {
                    set.insert(BIFaPosition.FaPositionA.rawValue)
                }
                if let posB = lstQuickFilters["posB"] as? NSNumber, !posB.boolValue {
                    set.insert(BIFaPosition.FaPositionB.rawValue)
                }
                if let posC = lstQuickFilters["posC"] as? NSNumber, !posC.boolValue {
                    set.insert(BIFaPosition.FaPositionC.rawValue)
                }
                if let posD = lstQuickFilters["posD"] as? NSNumber, !posD.boolValue {
                    set.insert(BIFaPosition.FaPositionD.rawValue)
                }
                if let posMultiple = lstQuickFilters["posMultiple"] as? NSNumber, !posMultiple.boolValue {
                    set.insert(BIFaPosition.FaPositionMultiple.rawValue)
                }
                
                if lstQuickFilters["posNA"] != nil {
                    if let posNA = lstQuickFilters["posNA"] as? NSNumber, !posNA.boolValue {
                        set.insert(BIFaPosition.FaPositionNA.rawValue)
                    }
                }
                var dict = ["SET": set]
                filterRule.variables = dict
                presetFilterRules.add(filterRule)
            }
        }
        if self.bidPeriod!.isFABid() && self.bidPeriod!.isSecondRoundBid() {
            if lstQuickFilters["SnrAMres"] != nil {
                set.removeAll()
                filterRule.category = 2
                filterRule.type = 0
                
                if let SnrAMres = lstQuickFilters["SnrAMres"] as? NSNumber, !SnrAMres.boolValue {
                    set.insert(BIFaReserveLineType.SnrAMres.rawValue)
                }
                if let SnrPMres = lstQuickFilters["SnrPMres"] as? NSNumber, !SnrPMres.boolValue {
                    set.insert(BIFaReserveLineType.SnrPMres.rawValue)
                }
                if let JnrAMres = lstQuickFilters["JnrAMres"] as? NSNumber, !JnrAMres.boolValue {
                    set.insert(BIFaReserveLineType.JnrAMres.rawValue)
                }
                if let JnrPMres = lstQuickFilters["JnrPMres"] as? NSNumber, !JnrPMres.boolValue {
                    set.insert(BIFaReserveLineType.JnrPMres.rawValue)
                }
                if let JnrLateRes = lstQuickFilters["JnrLateRes"] as? NSNumber, !JnrLateRes.boolValue {
                    set.insert(BIFaReserveLineType.JnrLateRes.rawValue)
                }
                if let noReserve = lstQuickFilters["noReserve"] as? NSNumber, !noReserve.boolValue {
                    set.insert(BIFaReserveLineType.NoType.rawValue)
                }
                var dict = ["SET": set]
                filterRule.variables = dict
                presetFilterRules.add(filterRule)
            }
        }
        
        filterRule = CBPresetFilterRule()
        set.removeAll()
        filterRule.category = 35
        filterRule.type = 0
        
        if let etops = lstQuickFilters["etops"] as? NSNumber, !etops.boolValue {
            dict = ["ETOPS_ON" : 1]
            filterRule.variables = dict
        }
        else {
            dict = ["ETOPS_ON" : 0]
            filterRule.variables = dict
        }
        presetFilterRules.add(filterRule)
        
        filterRule = CBPresetFilterRule()
        set.removeAll()
        filterRule.category = 1
        filterRule.type = 0
        
        if let amLines = lstQuickFilters["amLines"] as? NSNumber, !amLines.boolValue {
            set.insert(0)
        }
        if let mixedLines = lstQuickFilters["mixedLines"] as? NSNumber, !mixedLines.boolValue {
            set.insert(1)
        }
        if let pmLines = lstQuickFilters["pmLines"] as? NSNumber, !pmLines.boolValue {
            set.insert(2)
        }
        if let redEyeAmPmLines = lstQuickFilters["redEyeAmPmLines"] as? NSNumber, !redEyeAmPmLines.boolValue {
            set.insert(3)
        }
        set.insert(4)
        dict = ["SET": set]
        filterRule.variables = dict
        presetFilterRules.add(filterRule)
        
        filterRule = CBPresetFilterRule()
        filterRule.category = 4
        filterRule.type = 0
        var mask: UInt = 0
        var weekdayBits: UInt = 0
        let dayKeys = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]

        for (index, key) in dayKeys.enumerated() {
            if let value = lstQuickFilters[key] as? NSNumber, value.boolValue {
                mask = 1 << index
                weekdayBits |= mask
            }
        }

        dict = ["WEEKDAY_BITS": NSNumber(value: weekdayBits)]
        filterRule.variables = dict
        presetFilterRules.add(filterRule)
        
        filterRule = CBPresetFilterRule()
        var dictMutable = [String: Any]()
        if let turns = lstQuickFilters["turns"] as? NSNumber, !turns.boolValue {
            dictMutable["TURNS_ON"] = 1
            filterRule.variables = dictMutable
        }
        else {
            dictMutable["TURNS_ON"] = 0
            filterRule.variables = dictMutable
        }
        if let twoDays = lstQuickFilters["twoDays"] as? NSNumber, !twoDays.boolValue {
            dictMutable["TWO_DAYS_ON"] = 1
            filterRule.variables = dictMutable
        }
        else {
            dictMutable["TWO_DAYS_ON"] = 0
            filterRule.variables = dictMutable
        }
        if let threeDays = lstQuickFilters["threeDays"] as? NSNumber, !threeDays.boolValue {
            dictMutable["THREE_DAYS_ON"] = 1
            filterRule.variables = dictMutable
        }
        else {
            dictMutable["THREE_DAYS_ON"] = 0
            filterRule.variables = dictMutable
        }
        if let fourDays = lstQuickFilters["fourDays"] as? NSNumber, !fourDays.boolValue {
            dictMutable["FOUR_DAYS_ON"] = 1
            filterRule.variables = dictMutable
        }
        else {
            dictMutable["FOUR_DAYS_ON"] = 0
            filterRule.variables = dictMutable
        }
        
        presetFilterRules.add(filterRule)
        return presetFilterRules
    }
    
    func getPresetFilterObjects(from details: [String: Any]) -> NSMutableArray {
        var presetFilterRules = NSMutableArray()
        let lstFilters = details["lstFilters"] as? NSMutableArray
        for case let filterDict as [String: Any] in lstFilters ?? [] {
            let subFilters = filterDict["Listfilter"] as? NSMutableArray
            // saving each filters from the json to coredata
            for case let subFilter as [String: Any] in subFilters ?? [] {
                var filterRule = CBPresetFilterRule()
                filterRule.abbreviation = subFilter["Abbreviation"] as? String
                filterRule.category = NSNumber(value: (subFilter["Category"] as? Int)!)
                filterRule.type = NSNumber(value: (subFilter["Type"] as? Int)!)
                filterRule.keyPath = subFilter["KeyPath"] as? String
                let currentTile = self.filterTitleDict()[filterRule.abbreviation!]
                let varb = subFilter["Variable"] as? [String: Any]
                
                if (subFilter["Abbreviation"] as? String == "WantDays" || subFilter["Abbreviation"] as? String == "MonthDays" || subFilter["Abbreviation"] as? String == "TripStarts" || subFilter["Abbreviation"] as? String == "TripEnds") {
                    let variab = (subFilter["Variable"] as? NSMutableArray)!
                    filterRule.variables = BIFilterRule.configureMonthDayFilter(variab)
                }
                else if currentTile == "Regional Overnight Cities" {
                    let variable = subFilter["Variable"] as? [String: Any]
                    let setArray = (variable!["CITY"] as? [Any])!
                    let set = NSSet(array: setArray)
                    let variables = [
                        "SET": set,
                        "RANGEEND": variable?["RANGEEND"],
                        "RANGESTART": variable?["RANGESTART"],
                        "VALUE": variable?["VALUE"]
                    ]
                    filterRule.variables = variables as [String : Any]
                }
                else if subFilter["Abbreviation"] as? String == "Flags" {
                    let set = NSSet(array: (subFilter["Variable"] as? [Any])!)
                    filterRule.variables = ["SET": set]
                }
                else {
                    var dict2 = varb
                    if dict2!["VALUE"] != nil {
                        dict2!["VALUE"] = (dict2!["VALUE"] as? NSNumber)?.intValue
                    }
                    filterRule.variables = dict2
                }
                filterRule.comparison = NSNumber(value: (subFilter["Comparison"] as? Int)!)
                presetFilterRules.add(filterRule)
            }
        }
       return presetFilterRules
    }

    func setQuickFilterToLocalDB(details: [String: Any]) {
        let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        let result  = try? self.context.fetch(fetchRequest)
        if details["buddyBidder1"] != nil {
            let buddyBidder1 = (details["buddyBidder1"] as? NSNumber)?.stringValue
            self.bidPeriod!.buddyBidder1 = buddyBidder1
        }
        if details["buddyBidder2"] != nil {
            let buddyBidder2 = (details["buddyBidder2"] as? NSNumber)?.stringValue
            self.bidPeriod!.buddyBidder2 = buddyBidder2
        }
//        to recalculate am pm time after sync on 12-01-2022
        if details["AMPMtime"] != nil {
            let myString = (details["AMPMtime"] as? NSNumber)?.stringValue
            if myString != nil {
                UserDefaults.standard.set(myString, forKey: KCBCustomizedHerbValue)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("calculateAMPMFromSync"), object: nil)
                }
            }
        }
        if result?.count ?? 0 > 0 {
            for case let filterRule as BIFilterRule in result! {
                if filterRule.abbreviation == nil {
                    self.context.delete(filterRule)
                }
            }
        }
        if details["lstQuickFilters"] == nil {
            return
        }
        let lstQuickFiltersArray = details["lstQuickFiltersArray"] as? NSMutableArray
        if lstQuickFiltersArray?.count == 0 {
            let biReader = BIBidInfoReader()
            biReader.bidPeriod = self.bidPeriod
            biReader.addDefaultFilterRules(context: self.context)
            return
        }
        let lstQuickFilters = lstQuickFiltersArray![0] as? [String: Any]
        var set = Set<Int>()
        var filterRule = BIFilterRule(context: context)
        filterRule.bidPeriod = self.bidPeriod
        filterRule.category = 0
        if self.bidPeriod?.isEtopsLinesContainsInBid?.boolValue == true {
//            ETOPS
            if self.bidPeriod!.isSecondRoundBid() {
                set.insert(4)
                if let etops = lstQuickFilters?["etops"] as? Bool, etops == false  {
                    set.insert(BILineType.NonReserveEtops.rawValue)
                }
                if let nonConUs = lstQuickFilters?["nonConUs"] as? Bool, nonConUs == false  {
                    set.insert(7)
                }
                if let conUs = lstQuickFilters?["conUs"] as? Bool, conUs == false  {
                    set.insert(BILineType.NonEtopsConUS.rawValue)
                }
                if self.bidPeriod!.isFABid() {
                    if let hard = lstQuickFilters?["hard"] as? Bool, hard == false  {
                        set.insert(BILineType.NonEtopsHard.rawValue)
                    }
                    if let mixed = lstQuickFilters?["mixed"] as? Bool, mixed == false  {
                        set.insert(BILineType.NonEtopsMixed.rawValue)
                    }
                }
            }
            
            else {
//                first round ETOPS
//                pilot
                if self.bidPeriod!.isFABid() == false {
                    set.insert(1)
                    set.insert(2)
                    set.insert(3)
                    set.insert(5)
                    set.insert(9)
                    set.insert(12)
                }
                else {
//                    FA
                    set.insert(1)
                    set.insert(2)
                    set.insert(13)
                }
                if let nonConUs = lstQuickFilters?["nonConUs"] as? Bool, nonConUs == false  {
                    set.insert(7)
                }
                if let conUs = lstQuickFilters?["conUs"] as? Bool, conUs == false  {
                    set.insert(8)
                }
                if let blank = lstQuickFilters?["blank"] as? Bool, blank == false  {
                    set.insert(4)
                }
                if let etops = lstQuickFilters?["etops"] as? Bool, etops == false  {
                    set.insert(BILineType.NonReserveEtops.rawValue)
                }
            }
            if let reserve = lstQuickFilters?["reserve"] as? Bool, reserve == false  {
                set.insert(6)
            }
        }
        else {
//            non etops
            if self.bidPeriod?.isSecondRoundBid() == true {
                if let conUs = lstQuickFilters?["conUs"] as? Bool, conUs == false  {
                    set.insert(1)
                }
                if let nonConUs = lstQuickFilters?["nonConUs"] as? Bool, nonConUs == false  {
                    set.insert(2)
                }
                if let blank = lstQuickFilters?["blank"] as? Bool, blank == false  {
                    set.insert(4)
                }
                if !self.bidPeriod!.isFABid() {
                    if let blank = lstQuickFilters?["blank"] as? Bool, blank == false  {
                        set.insert(0)
                    }
                    if let mixed = lstQuickFilters?["mixed"] as? Bool, mixed == false  {
                        set.insert(5)
                    }
                }
                if let mixed = lstQuickFilters?["mixed"] as? Bool, mixed == false  {
                    set.insert(5)
                }
            }
            else {
                if let conUs = lstQuickFilters?["conUs"] as? Bool, conUs == false  {
                    set.insert(1)
                }
                if let nonConUs = lstQuickFilters?["nonConUs"] as? Bool, nonConUs == false  {
                    set.insert(2)
                }
                if let blank = lstQuickFilters?["blank"] as? Bool, blank == false  {
                    set.insert(4)
                }
                if let mixed = lstQuickFilters?["mixed"] as? Bool, mixed == false  {
                    set.insert(5)
                }
            }
            if let reserve = lstQuickFilters?["reserve"] as? Bool, reserve == false  {
                set.insert(3)
            }
            if let conUs = lstQuickFilters?["conUs"] as? Bool, conUs == false  {
                set.insert(BILineType.NonEtopsConUS.rawValue)
            }
            if let nonConUs = lstQuickFilters?["nonConUs"] as? Bool, nonConUs == false  {
                set.insert(7)
            }
            if let etops = lstQuickFilters?["etops"] as? Bool, etops == false  {
                set.insert(BILineType.NonEtopsReserve.rawValue)
            }
        }
        var dict = [String: Any]()
        dict = ["SET": set]
        filterRule.variables = dict as NSDictionary
        
//        for Fa
        if lstQuickFilters!["posA"] != nil && self.bidPeriod!.isFABid(){
            set.removeAll()
            filterRule = BIFilterRule(context: self.context)
            filterRule.bidPeriod = self.bidPeriod!
            filterRule.category = 3
            
            if let posA = lstQuickFilters?["posA"] as? NSNumber, !posA.boolValue {
                set.insert(BIFaPosition.FaPositionA.rawValue)
            }
            if let posB = lstQuickFilters?["posB"] as? NSNumber, !posB.boolValue {
                set.insert(BIFaPosition.FaPositionB.rawValue)
            }
            if let posC = lstQuickFilters?["posC"] as? NSNumber, !posC.boolValue {
                set.insert(BIFaPosition.FaPositionC.rawValue)
            }
            if let posD = lstQuickFilters?["posD"] as? NSNumber, !posD.boolValue {
                set.insert(BIFaPosition.FaPositionD.rawValue)
            }
            if let posMultiple = lstQuickFilters?["posMultiple"] as? NSNumber, !posMultiple.boolValue {
                set.insert(BIFaPosition.FaPositionMultiple.rawValue)
            }
            if lstQuickFilters!["posNA"] != nil {
                if let posNA = lstQuickFilters?["posNA"] as? NSNumber, !posNA.boolValue {
                    set.insert(BIFaPosition.FaPositionNA.rawValue)
                }
            }
            filterRule.variables = ["SET": set]
        }
        try? self.context.save()
        filterRule = BIFilterRule(context: self.context)
        set.removeAll()
        filterRule.category = 35
        filterRule.bidPeriod = bidPeriod
        if let etops = lstQuickFilters?["etops"] as? NSNumber, !etops.boolValue {
            filterRule.variables = ["ETOPS_ON": 1]
        }
        else {
            filterRule.variables = ["ETOPS_ON": 0]
        }
        filterRule = BIFilterRule(context: self.context)
        filterRule.category = 38
        filterRule.bidPeriod = bidPeriod
        if let etops = lstQuickFilters?["etopsRes"] as? NSNumber, !etops.boolValue {
            filterRule.variables = ["ETOPSRES_ON": 1]
        }
        else {
            filterRule.variables = ["ETOPSRES_ON": 0]
        }
        try? self.context.save()
        
        if self.bidPeriod!.isFABid() && self.bidPeriod!.isSecondRoundBid() {
            filterRule = BIFilterRule(context: self.context)
            filterRule.category = 2
            filterRule.bidPeriod = bidPeriod
            
            if let SnrAMres = lstQuickFilters?["SnrAMres"] as? NSNumber, !SnrAMres.boolValue {
                set.insert(BIFaReserveLineType.SnrAMres.rawValue)
            }
            if let SnrPMres = lstQuickFilters?["SnrPMres"] as? NSNumber, !SnrPMres.boolValue {
                set.insert(BIFaReserveLineType.SnrPMres.rawValue)
            }
            if let JnrAMres = lstQuickFilters?["JnrAMres"] as? NSNumber, !JnrAMres.boolValue {
                set.insert(BIFaReserveLineType.JnrAMres.rawValue)
            }
            if let JnrPMres = lstQuickFilters?["JnrPMres"] as? NSNumber, !JnrPMres.boolValue {
                set.insert(BIFaReserveLineType.JnrPMres.rawValue)
            }
            if let JnrLateRes = lstQuickFilters?["JnrLateRes"] as? NSNumber, !JnrLateRes.boolValue {
                set.insert(BIFaReserveLineType.JnrLateRes.rawValue)
            }
            if let noReserve = lstQuickFilters?["noReserve"] as? NSNumber, !noReserve.boolValue {
                set.insert(BIFaReserveLineType.NoType.rawValue)
            }
            var dict = ["SET": set]
            filterRule.variables = dict as NSDictionary
        }
        try? self.context.save()
        filterRule = BIFilterRule(context: self.context)
        filterRule.category = 1
        filterRule.bidPeriod = bidPeriod
        
        if let amLines = lstQuickFilters?["amLines"] as? NSNumber, !amLines.boolValue {
            set.insert(0)
        }
        if let mixedLines = lstQuickFilters?["mixedLines"] as? NSNumber, !mixedLines.boolValue {
            set.insert(1)
        }
        if let pmLines = lstQuickFilters?["pmLines"] as? NSNumber, !pmLines.boolValue {
            set.insert(2)
        }
        if let redEyeAmPmLines = lstQuickFilters?["redEyeAmPmLines"] as? NSNumber, !redEyeAmPmLines.boolValue {
            set.insert(3)
        }
        set.insert(4)
        dict = ["SET": set]
        filterRule.variables = dict as NSDictionary
        try? self.context.save()
        
        try? self.context.save()
        filterRule = BIFilterRule(context: self.context)
        filterRule.category = 4
        filterRule.bidPeriod = bidPeriod
        
        var mask: UInt = 0
        var weekdayBits: UInt = 0
        let dayKeys = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]

        for (index, key) in dayKeys.enumerated() {
            if let value = lstQuickFilters?[key] as? NSNumber, value.boolValue {
                mask = 1 << index
                weekdayBits |= mask
            }
        }

        dict = ["WEEKDAY_BITS": NSNumber(value: weekdayBits)]
        filterRule.variables = dict as NSDictionary
        try? self.context.save()
        filterRule = BIFilterRule(context: self.context)
        filterRule.category = 5
        filterRule.bidPeriod = bidPeriod
        
        var dictMutable = [String: Any]()
        if let turns = lstQuickFilters?["turns"] as? NSNumber, !turns.boolValue {
            dictMutable["TURNS_ON"] = 1
            filterRule.variables = dictMutable as NSDictionary
        }
        else {
            dictMutable["TURNS_ON"] = 0
            filterRule.variables = dictMutable as NSDictionary
        }
        if let twoDays = lstQuickFilters?["twoDays"] as? NSNumber, !twoDays.boolValue {
            dictMutable["TWO_DAYS_ON"] = 1
            filterRule.variables = dictMutable as NSDictionary
        }
        else {
            dictMutable["TWO_DAYS_ON"] = 0
            filterRule.variables = dictMutable as NSDictionary
        }
        if let threeDays = lstQuickFilters?["threeDays"] as? NSNumber, !threeDays.boolValue {
            dictMutable["THREE_DAYS_ON"] = 1
            filterRule.variables = dictMutable as NSDictionary
        }
        else {
            dictMutable["THREE_DAYS_ON"] = 0
            filterRule.variables = dictMutable as NSDictionary
        }
        if let fourDays = lstQuickFilters?["fourDays"] as? NSNumber, !fourDays.boolValue {
            dictMutable["FOUR_DAYS_ON"] = 1
            filterRule.variables = dictMutable as NSDictionary
        }
        else {
            dictMutable["FOUR_DAYS_ON"] = 0
            filterRule.variables = dictMutable as NSDictionary
        }
        try? self.context.save()
    }

    func setFilterToLocalDB(details: [String: Any]) {
        let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        let result  = try? self.context.fetch(fetchRequest)
        
        if result?.count ?? 0 > 0 {
            for filterRule in result! {
                if filterRule.abbreviation != nil {
                    self.context.delete(filterRule)
                }
            }
        }
        let commuteFetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        commuteFetchRequest.predicate = NSPredicate(format:"commutableType == 0")
        let commuteResult = try? self.context.fetch(commuteFetchRequest)
        if commuteResult?.count ?? 0 > 0 {
            for commute in commuteResult! {
                self.context.delete(commute)
            }
        }
        
        if details["lstFilters"] == nil {
            return
        }
        let lstFilters =  details["lstFilters"] as? NSMutableArray
        for case let filterDict as [String: Any] in lstFilters! {
            let subfilters = details["Listfilter"] as? NSMutableArray
            // saveing each filters from the json to coredata.
            
            var commuteValueDict = [String: Any]()
            var reportReleaseValueDict = [String: Any]()
            
            for case let subfilter as [String: Any] in subfilters ?? [] {
                if subfilter["Abbreviation"] as? String == "CmAuto" {
                    commuteValueDict = subfilter
                }
                else if subfilter["Abbreviation"] as? String == "Report-Release" {
                    reportReleaseValueDict = subfilter
                }
                else {
                    let filterRule = BIFilterRule(context: self.context)
                    filterRule.bidPeriod = bidPeriod
                    filterRule.abbreviation = subfilter["Abbreviation"] as? String
                    filterRule.name = subfilter["Name"] as? String
                    filterRule.keyPath = subfilter["KeyPath"] as? String
                    filterRule.category = NSNumber(value: (subfilter["Category"] as? Int)!)
                    filterRule.type = NSNumber(value: (subfilter["Type"] as? Int)!)
                    
                    let currentTitle = self.filterTitleDict()[filterRule.abbreviation!]
                    //                    Flags
                    if filterRule.abbreviation == "Flags" {
                        let set = NSSet(array: (subfilter["Variable"] as? [Any])!)
                        filterRule.variables = ["SET": set]
                    }
//                    commute manual
                    else if filterRule.abbreviation == "CRqd" {
                        let varb = subfilter["Variable"] as? [String: Any]
                        var dictTemp = [String: Any]()
                        for (key, value) in varb ?? [:] {
                            if let numberValue = value as? NSNumber {
                                dictTemp[key] = numberValue.stringValue
                            } else {
                                dictTemp[key] = value
                            }
                        }
//                        end od add
                        var dict2 = dictTemp
                        if let value = dict2["VALUE"] {
                            dict2["VALUE"] = Double("\(value)") ?? 0.0
                        }
                        
                        if let rangeEnd = dict2["RANGEEND"] {
                            dict2["RANGEEND"] = Double("\(rangeEnd)") ?? 0.0
                        }
                        
                        if let rangeStart = dict2["RANGESTART"] {
                            dict2["RANGESTART"] = Double("\(rangeStart)") ?? 0.0
                        }
                        if let friReturn = dict2["FRI_RETURN"] as? String {
                            if !friReturn.isEmpty && friReturn != "0" {
                                dict2["FRI_RETURN"] = Double(friReturn) ?? 0.0
                            } else {
                                dict2["FRI_RETURN"] = 3000.0
                            }
                        }
                        if let monThursReturn = dict2["MON_THURS_RETURN"] as? String {
                            if !monThursReturn.isEmpty && monThursReturn != "0" {
                                dict2["MON_THURS_RETURN"] = Double(monThursReturn) ?? 0.0
                            } else {
                                dict2["MON_THURS_RETURN"] = 3000.0
                            }
                        }
                        if let satReturn = dict2["SAT_RETURN"] as? String {
                            if !satReturn.isEmpty && satReturn != "0" {
                                dict2["SAT_RETURN"] = Double(satReturn) ?? 0.0
                            } else {
                                dict2["SAT_RETURN"] = 3000.0
                            }
                        }
                        if let sunReturn = dict2["SUN_RETURN"] as? String {
                            if !sunReturn.isEmpty && sunReturn != "0" {
                                dict2["SUN_RETURN"] = Double(sunReturn) ?? 0.0
                            } else {
                                dict2["SUN_RETURN"] = 3000.0
                            }
                        }
                        if let friDepart = dict2["FRI_DEPART"] as? String {
                            if !friDepart.isEmpty && friDepart != "0" {
                                dict2["FRI_DEPART"] = Double(friDepart) ?? -1.0
                            } else {
                                dict2["FRI_DEPART"] = -1.0
                            }
                        }
                        if let MonThursDepart = dict2["MON_THURS_DEPART"] as? String {
                            if !MonThursDepart.isEmpty && MonThursDepart != "0" {
                                dict2["MON_THURS_DEPART"] = Double(MonThursDepart) ?? -1.0
                            } else {
                                dict2["MON_THURS_DEPART"] = -1.0
                            }
                        }
                        if let satDepart = dict2["SAT_DEPART"] as? String {
                            if !satDepart.isEmpty && satDepart != "0" {
                                dict2["SAT_DEPART"] = Double(satDepart) ?? -1.0
                            } else {
                                dict2["SAT_DEPART"] = -1.0
                            }
                        }
                        if let sunDepart = dict2["SUN_DEPART"] as? String {
                            if !sunDepart.isEmpty && sunDepart != "0" {
                                dict2["SUN_DEPART"] = Double(sunDepart) ?? -1.0
                            } else {
                                dict2["SUN_DEPART"] = -1.0
                            }
                        }
                        
                        filterRule.variables = dict2 as NSDictionary
                        let cell = CBPresetsTVC()
                        cell.bidPeriod = self.bidPeriod
                        cell.calculateCommuteMannualfilter(variables: dict2)
                    }
//                    overnightBulk
                    else if filterRule.abbreviation == "OCB" {
                        var variables = [String: Any]()
                        var variable = subfilter["Variable"] as? [String: Any]
                        let overNightYesCities = variable?["OverNightYes"] as? NSMutableArray
                        let overNightNoCities = variable?["OverNightNo"] as? NSMutableArray
                        
                        for case let overNightYesCity as String in overNightYesCities ?? [] {
                            variables[overNightYesCity] = 2
                        }
                        for case let overNightNoCity as String in overNightNoCities ?? [] {
                            variables[overNightNoCity] = 1
                        }
                        
                        let fetchRequest: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
                        let fetchedObjects = try? self.context.fetch(fetchRequest)
                        if fetchedObjects?.count ?? 0 > 0 {
                            let objOvernight = fetchedObjects![0] 
                            objOvernight.citystatus = variable as NSObject?
                            try? self.context.save()
                        }
                        else {
                            let objOvernight = OvernightBulk(context: self.context)
                            objOvernight.citystatus = variable as NSObject?
                            try? self.context.save()
                        }
                        filterRule.variables = variables as NSDictionary
                        CBUtils.overnightBulkRedApply(noArray: overNightNoCities ?? [])
                    }
//                    days of month
                    else if (filterRule.abbreviation == "WantDays" || filterRule.abbreviation == "MonthDays" || filterRule.abbreviation == "TripStarts" || filterRule.abbreviation == "TripEnds") {
                        filterRule.variables = BIFilterRule.configureMonthDayFilter((subfilter["Variable"] as? NSMutableArray)!) as NSDictionary
                    }
//                    Regional overnightCities
                    else if currentTitle == "Regional Overnight Cities" {
                        var variables = [String: Any]()
                        let variable = subfilter["Variable"] as? [String: Any]
                        let set = NSSet(array: [variable?["CITY"] as? [Any]] ?? [])
                        variables = [
                            "SET": set,
                            "RANGEEND": variable?["RANGEEND"],
                            "RANGEEND": variable?["RANGEEND"],
                            "VALUE": NSNumber(value: (variable?["VALUE"] as? Int)!)
                        ]
                        filterRule.variables = variables as NSDictionary
                    }
                    else {
                        let varb = subfilter["Variable"] as? [String: Any]
                        var dict2 = varb
                        let keys = ["VALUE", "RANGEEND", "RANGESTART", "DECIMAL", "STEP", "NUMPLACES"]
                        for key in keys {
                            if let value = dict2?[key] {
                                dict2?[key] = Double("\(value)") ?? 0.0
                            }
                        }
                        filterRule.variables = dict2 as? NSDictionary
                    }
                    
//                    cities
                    if filterRule.category?.intValue == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue {
                        let type = filterRule.type?.intValue
                        if (type == BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue || type == BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue || type == BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue || type == BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue || type == BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue) {
                            let selectedCitites = self.selectedFCities(with: filterRule)
                            filterRule.saveSelectedCities(selectedCitites)
                            let set = NSSet(array: selectedCitites)
                            var filterVars = [String: Any]()
                            if filterRule.variables != nil {
                                filterVars = filterRule.variables?.mutableCopy() as! [String : Any]
                                filterVars["SET"] = set
                            }
                            filterRule.variables = filterVars as NSDictionary
                        }
                    }
                    
                    filterRule.comparison = NSNumber(value: (subfilter["Comparison"] as? Double) ?? 0.0)
                    if filterRule.ruleHighlightsTrips() {
                        filterRule.highlightTrips()
                    }
                }
            }
//            commute auto filter
            if commuteValueDict.count != 0 {
                let commuteDict = commuteValueDict
                let varb = commuteDict["Variable"] as? [String: Any]
                let dict2 = varb
                var commuteCity = ""
                var isNonStop = false
                if dict2?["commuteCity"] != nil {
                    commuteCity = (dict2?["commuteCity"] as? String)!
                }
                if dict2?["nonStop"] != nil {
                    let nonStopNumber =  dict2?["nonStop"] as? NSNumber
                    isNonStop = nonStopNumber!.boolValue && nonStopNumber?.intValue != 0
                }
                var connectTime = dict2?["selectedConnectTime"] as? NSNumber
                if connectTime == nil {
                    connectTime = 0
                }
                let commuteVC = CommuteCityViewController()
                //                        CBGlobalMethods.shared.showCustomActivityIndicator(message: "Calculating commute values..", bgcolor: .purple, height: 100)
                let (success, commuteCityReturn) = commuteVC.commutabilityCalculationWithForSync(city: commuteCity, isNonStop: isNonStop, connectTimeFromPreset: connectTime as! Int)
                //                        CBGlobalMethods.shared.hideCustomActivityIndicator()
                let commutInfoVC = CBCommuteInfoViewController()
                commutInfoVC.backToBaseFromSync = (dict2?["selectedBackToBasePadTimeValues"] as? String)!
                let connectTimeStr = dict2?["selectedConnectTime"] as? String
                if connectTimeStr == "--:--" {
                    commutInfoVC.connectTimeFromSync = "0:0"
                }
                else {
                    commutInfoVC.connectTimeFromSync = connectTimeStr!
                }
                commutInfoVC.checkInFromSync = (dict2?["selectedTakeOffPadTimeValues"] as? String)!
                commutInfoVC.bidPeriod = self.bidPeriod
                commutInfoVC.commutabilityType = CommutabilityType.filter
                commutInfoVC.isNonStop = isNonStop
                commutInfoVC.commuteCityFromSync = commuteCity
                commutInfoVC.value = NSNumber(value: (dict2?["cmtPercentage"] as? Int)!)
                commutInfoVC.secondCellValue = NSNumber(value: (dict2?["nMid"] as? Int)!)
                commutInfoVC.thirdCellValue = NSNumber(value: (dict2?["cmtFrBaOv"] as? Int)!)
                commutInfoVC.type = NSNumber(value: (dict2?["cmtGreaterOrLesser"] as? Int)!)
                commutInfoVC.calculateCommuteLineProperties()
            }
//            reportRelease
            if reportReleaseValueDict.count != 0 {
                let varb = reportReleaseValueDict["Variable"] as? [String: Any]
                let dict2 = varb
                var reportValue = ""
                var releaseValue = ""
                var isLast: NSNumber = 0
                var isNoMid: NSNumber = 0
                var isCalendar: NSNumber = 0
                var isSelectedAll: NSNumber = 0
                var isFirst: NSNumber = 0
                var isAllDays: NSNumber = 0
                var selectedDates = NSMutableArray()
                var selectedIndices = NSMutableArray()
                selectedIndices = dict2?["selectedIndex"] as? NSMutableArray ?? []
                if dict2?["reportValue"] != nil {
                    reportValue = (dict2?["reportValue"] as? String)!
                }
                if dict2?["releaseValue"] != nil {
                    releaseValue = (dict2?["releaseValue"] as? String)!
                }
                if dict2?["isFirst"] != nil {
                    if (dict2?["isFirst"] as? NSNumber)?.boolValue == true {
                        isFirst = 1
                    }
                    else {
                        isFirst = 0
                    }
                }
                if dict2?["isNoMid"] != nil {
                    if (dict2?["isNoMid"] as? NSNumber)?.boolValue == true {
                        isNoMid = 1
                    }
                    else {
                        isNoMid = 0
                    }
                }
                if dict2?["isLast"] != nil {
                    if (dict2?["isLast"] as? NSNumber)?.boolValue == true {
                        isLast = 1
                    }
                    else {
                        isLast = 0
                    }
                }
                if dict2?["selectedOption"] != nil {
                    let tmp = (dict2?["selectedOption"] as? NSNumber)?.intValue
                    if tmp == 0 {
                        isSelectedAll = 1
                    }
                    else if tmp == 2 {
                        isCalendar = 1
                    }
                }
                
                var tempDict: [String: Any] = [:]
                // tempDict["SELECTED_DATES"] = SELECTED_DATES
                tempDict["isAllDays"] = isAllDays
                tempDict["isCalendar"] = isCalendar
                tempDict["isFirst"] = isFirst
                tempDict["isLast"] = isLast
                tempDict["isNoMid"] = isNoMid
                tempDict["isSelectedAll"] = isSelectedAll
                tempDict["releaseValue"] = releaseValue
                tempDict["reportValue"] = reportValue

                let filterRule = BIFilterRule(context: self.context)
                filterRule.bidPeriod = bidPeriod
                filterRule.abbreviation = "RptRls"
                filterRule.category = NSNumber(value: (reportReleaseValueDict["Category"] as? Int)!)
                filterRule.type = NSNumber(value: (reportReleaseValueDict["Type"] as? Int)!)
                filterRule.comparison = NSNumber(value: (reportReleaseValueDict["Comparison"] as? Int)!)
                filterRule.name = reportReleaseValueDict["Name"] as? String
                filterRule.keyPath = reportReleaseValueDict["KeyPath"] as? String
                
                var MONTH_BITS: NSNumber = 0

                for index in 0..<selectedIndices.count {
                    var strDay: [Any] = []
                    let indexValue = (selectedIndices[index] as? Int) ?? 0
                    let nsi = Int(indexValue)
                    
                    var mask: UInt64 = 0
                    var monthBits: UInt64 = 0
                    let one: UInt64 = 1
                    
                    if MONTH_BITS != 0 {
                        monthBits = MONTH_BITS.uint64Value
                    }
                    
                    mask = one << UInt64(nsi)
                    monthBits |= mask
                    
                    MONTH_BITS = NSNumber(value: monthBits)
                    
                    let day = calendarData?.calendarDays[indexValue] as? BICalendarDay
                    if (!day!.isCurrentMonth) {
                        if bidPeriod?.month?.intValue == 12 {
                            let month: NSNumber = 1
                            let year: NSNumber = (bidPeriod?.year?.intValue ?? 0) + 1 as NSNumber
                            strDay.append((index as? NSNumber)?.stringValue)
                            strDay.append(month)
                            strDay.append(year)
                        }
                        else {
                            strDay.append(day!.text)
                            strDay.append(String(self.bidPeriod!.month!.intValue + 1))
                            strDay.append(String(self.bidPeriod!.year!.intValue))
                        }
                    }
                    else {
                        strDay.append(day!.text)
                        strDay.append(String(self.bidPeriod!.month!.intValue))
                        strDay.append(String(self.bidPeriod!.year!.intValue))
                    }
                    selectedDates.add((strDay as? [String] ?? []).joined(separator: "-"))
                }
                tempDict["SELECTED_DATES"] = selectedDates
                tempDict["MONTH_BITS"] = MONTH_BITS
                filterRule.variables = tempDict as NSDictionary
                try? self.context.save()
                
                let reportReleaseVC = CBReportReleaseRuleCellTableViewCell()
                reportReleaseVC.bidPeriod = bidPeriod
                reportReleaseVC.filterRule = filterRule
                reportReleaseVC.calendarData = calendarData
                reportReleaseVC.calculationFromSync(reportValue: reportValue, releaseValue: releaseValue, isLast: isLast, isNoMid: isNoMid, isCalendar: isCalendar, isSelectedAll: isSelectedAll, isFirst: isFirst, selectedDates: selectedDates) { success in
                    if !success {
                        AlertService.showAlertForTopVC(title: "Alert", message: "Report release calculation failed")
                    }
                }
            }
        }
        try? self.context.save()
    }
    
    func selectedFCities(with filterRule: BIFilterRule) -> [Any] {
        var cities: [Any] = []
        
        if let tmp = filterRule.variables?["SET"] {
            if let set = tmp as? Set<AnyHashable> {
                cities = Array(set)
            } else if let mutableSet = tmp as? NSMutableSet {
                cities = mutableSet.allObjects
            } else if let array = tmp as? [Any] {
                cities = array
            } else if let mutableArray = tmp as? NSMutableArray {
                cities = mutableArray as? [Any] ?? []
            }
        }
        
        return cities
    }

    func setSortToLocalDB(details: [String: Any]) {
        let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        let result = try? self.context.fetch(fetchRequest)
        if result?.count ?? 0 > 0 {
            for object in result ?? [] {
                self.context.delete(object)
            }
        }
        
        let commuteFetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        commuteFetchRequest.predicate = NSPredicate(format: "commutableType == 1")
        let commuteResult = try? self.context.fetch(commuteFetchRequest)
        if commuteResult?.count ?? 0 > 0 {
            for commute in commuteResult! {
                self.context.delete(commute)
            }
        }
        
        if details["lstSorts"] == nil {
            return
        }
        
        if details["DefaultCommutingValues"] != nil {
            let defaultCommutingValues = details["DefaultCommutingValues"] as? [String: Any]
            let monThursDepart = defaultCommutingValues?["MON_THURS_DEPART"] as? String
            let satDepart = defaultCommutingValues?["SAT_DEPART"] as? String
            let sunDepart = defaultCommutingValues?["SUN_DEPART"] as? String
            let friDepart = defaultCommutingValues?["FRI_DEPART"] as? String
            let friReurn = defaultCommutingValues?["FRI_RETURN"] as? String
            let monThursReurn = defaultCommutingValues?["MON_THURS_RETURN"] as? String
            let satReurn = defaultCommutingValues?["SAT_RETURN"] as? String
            let sunReurn = defaultCommutingValues?["SUN_RETURN"] as? String
            let noMidCheckState = defaultCommutingValues?["NoMidCheckState"] as? String
            if (monThursDepart != nil && friDepart != nil && satDepart != nil && sunDepart != nil && monThursReurn != nil && friReurn != nil && satReurn != nil && satReurn != nil) {
                var defaultTimes = NSMutableArray()
                if monThursDepart?.length ?? 0 > 0 {
                    let timeDepartureMonThurs = Int(monThursDepart!)!
                    if timeDepartureMonThurs > -1 {
                        defaultTimes.add(timeDepartureMonThurs)
                    }
                    else {
                        defaultTimes.add(-1)
                    }
                }
                if monThursReurn?.length ?? 0 > 0 {
                    let timereturnMonThurs = Int(monThursReurn!)!
                    if timereturnMonThurs < 3000 {
                        defaultTimes.add(timereturnMonThurs)
                    }
                    else {
                        defaultTimes.add(3000)
                    }
                }
                if friDepart?.length ?? 0 > 0 {
                    let timedepartureFri = Int(friDepart!)!
                    if timedepartureFri > -1 {
                        defaultTimes.add(timedepartureFri)
                    }
                    else {
                        defaultTimes.add(-1)
                    }
                }
                if friReurn?.length ?? 0 > 0 {
                    let timereturnFri = Int(friReurn!)!
                    if timereturnFri < 3000 {
                        defaultTimes.add(timereturnFri)
                    }
                    else {
                        defaultTimes.add(3000)
                    }
                }
                if satDepart?.length ?? 0 > 0 {
                    let timedepartureSat = Int(satDepart!)!
                    if timedepartureSat > -1 {
                        defaultTimes.add(timedepartureSat)
                    }
                    else {
                        defaultTimes.add(-1)
                    }
                }
                if satReurn?.length ?? 0 > 0 {
                    let timereturnSat = Int(satReurn!)!
                    if timereturnSat < 3000 {
                        defaultTimes.add(timereturnSat)
                    }
                    else {
                        defaultTimes.add(3000)
                    }
                }
                if sunDepart?.length ?? 0 > 0 {
                    let timedepartureSun = Int(sunDepart!)!
                    if timedepartureSun > -1 {
                        defaultTimes.add(timedepartureSun)
                    }
                    else {
                        defaultTimes.add(-1)
                    }
                }
                if sunReurn?.length ?? 0 > 0 {
                    let timereturnSun = Int(sunReurn!)!
                    if timereturnSun < 3000 {
                        defaultTimes.add(timereturnSun)
                    }
                    else {
                        defaultTimes.add(3000)
                    }
                }
                UserDefaults.standard.set(defaultTimes, forKey: kCBDefaultCommutingTimesKey)
                UserDefaults.standard.set(noMidCheckState, forKey: kCBDefaultsCommutingNoMidKey)
            }
        }
        let lstSorts = details["lstSorts"] as? NSMutableArray
        for case let sortDict as [String: Any] in lstSorts ?? [] {
            if sortDict["ListSort"] == nil {
                return
            }
            let subsorts = sortDict["ListSort"] as? NSMutableArray
            // saveing each sorts from the json to coredata.
            var lineSortAutoComute = [String: Any]()
            for case let subsort as [String: Any] in subsorts ?? [] {
                if subsort["Abbreviation"] as? String == "CmAuto" {
                    lineSortAutoComute = subsort
                }
                else {
                    let lineSort = BILineSort(context: self.context)
                    lineSort.bidPeriod = bidPeriod
                    lineSort.abbreviation = subsort["Abbreviation"] as? String
                    lineSort.isBidListSort = NSNumber(booleanLiteral: false)
                    let currentTitle = self.sortTitleDict()[lineSort.abbreviation!]
                    lineSort.category = NSNumber(value: (subsort["Category"] as? Int)!)
                    if subsort["Type"] != nil {
                        lineSort.type = NSNumber(value: (subsort["Type"] as? Int)!)
                    }
                    if subsort["ArrayVariables"] != nil {
                        let tmp = subsort["ArrayVariables"] as? NSMutableArray
                        lineSort.arrayVariables = tmp
                    }
                    lineSort.order = NSNumber(value: (subsort["Order"] as? Int)!)
                    lineSort.name = subsort["Name"] as? String
                    if currentTitle == "Position" {
                        lineSort.keyPath = self.bidPeriod?.lineSortKeyForPosition(posLineSort: lineSort)
                    }
                    else {
                        lineSort.keyPath = subsort["KeyPath"] as? String
                        if lineSort.abbreviation == "OffSort" {
                            lineSort.keyPath = bidPeriod?.lineSortKeyForDaysOff(lineSort: lineSort)
                            lineSort.ascending = 0
                        }
                        if lineSort.abbreviation == "WorkSort" {
                            lineSort.keyPath = bidPeriod?.lineSortKeyForDaysWork(lineSort: lineSort)
                            lineSort.ascending = 1
                        }
                        if lineSort.abbreviation == "TripStartSort" {
                            lineSort.keyPath = bidPeriod?.lineSortKeyForTripStartDays(lineSort: lineSort)
                            lineSort.ascending = 0
                        }
                    }
                    
                    let ascending = subsort["Ascending"] as? Bool
                    lineSort.ascending = NSNumber(booleanLiteral: ascending!)
                    lineSort.isMutable = NSNumber(value: (subsort["IsMutable"] as? Int)!)
                    
                    if subsort["City"] != nil {
                        lineSort.city = subsort["City"] as? String
                        lineSort.setCity = subsort["City"] as? String
                    }
                    else if lineSort.abbreviation == "flag" {
                        var variable = [String: Any]()
                        let arrayVariables = lineSort.arrayVariables as? NSMutableArray
                        for i in 0..<arrayVariables!.count {
                            let val = arrayVariables![i] as? NSNumber
                            if val == 0 {
                                variable["NO_COLOR_FLAG"] = val
                            }
                            else if val == 1 {
                                variable["BLUE_COLOR_FLAG"] = val
                            }
                            else if val == 2 {
                                variable["GREEN_COLOR_FLAG"] = val
                            }
                            else if val == 3 {
                                variable["RED_COLOR_FLAG"] = val
                            }
                            else if val == 4 {
                                variable["YELLOW_COLOR_FLAG"] = val
                            }
                            else if val == 5 {
                                variable["ORANGE_COLOR_FLAG"] = val
                            }
                            else if val == 6 {
                                variable["BROWN_COLOR_FLAG"] = val
                            }
                            else if val == 7 {
                                variable["PINK_COLOR_FLAG"] = val
                            }
                        }
                        lineSort.variables = variable as NSDictionary
                        var userFlags = NSMutableArray(capacity: arrayVariables!.count)
                        for value in arrayVariables! {
                            guard let intValue = (value as? NSNumber)?.intValue else { continue }

                            switch intValue {
                            case 0:
                                userFlags.add(CBUserFlagType.none.rawValue)

                            case 1:
                                userFlags.add(CBUserFlagType.blue.rawValue)
                            case 2:
                                userFlags.add(CBUserFlagType.green.rawValue)
                            case 3:
                                userFlags.add(CBUserFlagType.red.rawValue)
                            case 4:
                                userFlags.add(CBUserFlagType.yellow.rawValue)
                            case 5:
                                userFlags.add(CBUserFlagType.orange.rawValue)

                            case 6:
                                userFlags.add(CBUserFlagType.brown.rawValue)
                            case 7:
                                userFlags.add(CBUserFlagType.pink.rawValue)
                            default:
                                break
                            }
                        }
                        lineSort.arrayVariables = userFlags
                        let lineFetch: NSFetchRequest<BILine> = BILine.fetchRequest()
                        lineFetch.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
                        let lineresult = try? self.context.fetch(lineFetch)
                        for line in lineresult ?? [] {
                            line.flagOrder = 8
                        }
                        for i in 0..<userFlags.count {
                            let arrIndexValue = userFlags[i] as? Int
                            lineFetch.predicate = NSPredicate(format: "userFlagType == %d",arrIndexValue!)
                            let sortedLine = try? self.context.fetch(lineFetch)
                            for line in sortedLine ?? [] {
                                line.flagOrder = NSNumber(value: i)
                            }
                        }
                        try? self.context.save()
                    }
                    else if (lineSort.abbreviation == "OffSort" || lineSort.abbreviation == "WorkSort" || lineSort.abbreviation == "TripStartSort") {
                        lineSort.variables = BILineSort.configureMonthDayFilter((subsort["ArrayVariables"] as? NSMutableArray)!) as NSDictionary
                    }
                    else if lineSort.abbreviation == "Commute" {
                        let varb = subsort["Variable"] as? [String: Any]
                        var dict2 = varb!
                        if let value = dict2["FRI_RETURN"] {
                            if let stringValue = value as? String {
                                if stringValue.isEmpty {
                                    dict2["FRI_RETURN"] = 3000
                                } else if let doubleValue = Double(stringValue) {
                                    dict2["FRI_RETURN"] = Int(doubleValue)
                                }
                            }
                        }
                        if let value = dict2["MON_THURS_DEPART"] {
                            if let stringValue = value as? String {
                                if stringValue.isEmpty {
                                    dict2["MON_THURS_DEPART"] = 3000
                                } else if let doubleValue = Double(stringValue) {
                                    dict2["MON_THURS_DEPART"] = Int(doubleValue)
                                }
                            }
                        }
                        if let value = dict2["SAT_RETURN"] {
                            if let stringValue = value as? String {
                                if stringValue.isEmpty {
                                    dict2["SAT_RETURN"] = 3000
                                } else if let doubleValue = Double(stringValue) {
                                    dict2["SAT_RETURN"] = Int(doubleValue)
                                }
                            }
                        }
                        if let value = dict2["SUN_RETURN"] {
                            if let stringValue = value as? String {
                                if stringValue.isEmpty {
                                    dict2["SUN_RETURN"] = 3000
                                } else if let doubleValue = Double(stringValue) {
                                    dict2["SUN_RETURN"] = Int(doubleValue)
                                }
                            }
                        }
                        if let value = dict2["FRI_DEPART"] {
                            if let stringValue = value as? String {
                                if stringValue.isEmpty {
                                    dict2["FRI_DEPART"] = -1
                                } else if let doubleValue = Double(stringValue) {
                                    dict2["FRI_DEPART"] = Int(doubleValue)
                                }
                            }
                        }
                        if let value = dict2["MON_THURS_DEPART"] {
                            if let stringValue = value as? String {
                                if stringValue.isEmpty {
                                    dict2["MON_THURS_DEPART"] = -1
                                } else if let doubleValue = Double(stringValue) {
                                    dict2["MON_THURS_DEPART"] = Int(doubleValue)
                                }
                            }
                        }
                        if let value = dict2["SAT_DEPART"] {
                            if let stringValue = value as? String {
                                if stringValue.isEmpty {
                                    dict2["SAT_DEPART"] = -1
                                } else if let doubleValue = Double(stringValue) {
                                    dict2["SAT_DEPART"] = Int(doubleValue)
                                }
                            }
                        }
                        if let value = dict2["SUN_DEPART"] {
                            if let stringValue = value as? String {
                                if stringValue.isEmpty {
                                    dict2["SUN_DEPART"] = -1
                                } else if let doubleValue = Double(stringValue) {
                                    dict2["SUN_DEPART"] = Int(doubleValue)
                                }
                            }
                        }
                        if dict2["NoMidCheckState"] != nil {
                            dict2["NoMidCheckState"] = (dict2["NoMidCheckState"] as? NSNumber)?.boolValue
                        }
                        let cell = CBPresetsTVC()
                        cell.bidPeriod = self.bidPeriod
                        cell.calculateCommuteMannualSort(pRule: dict2)
                    }
                    else if currentTitle == "Regional Overnight Cities" {
                        let variable = subsort["Variable"] as? [String: Any]
                        let setArray = variable!["City"] as? [Any]
                        let set = NSSet(array: setArray!)
                        lineSort.variables = ["SET": set]
                    }
                    else {
                        if subsort["Variable"] != nil {
                            lineSort.variables = subsort["Variable"] as? NSDictionary
                        }
                    }
                    
                    if lineSort.category?.intValue == BILineSortCategory.BICitiesLineSortCategory.rawValue {
                        lineSort.bidPeriod = bidPeriod
                        let type = lineSort.type?.intValue ?? 8
                        if (type == BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue || type == BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue || type == BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue || type == BICityLineSortType.BICitiesLineSortTypeAll.rawValue || type == BICityLineSortType.BICitiesLineSortTypeIntl.rawValue || type == BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue) {
                            let selectedCities = self.selectedCitiesWithLinesort(linesort: lineSort)
                            lineSort.saveSelectedCities(selectedCities)
                            
                            var filerVars = [String: Any]()
                            let set = NSSet(array: selectedCities)
                            if lineSort.variables != nil {
                                filerVars = (lineSort.variables as? [String: Any])!
                                filerVars["SET"] = set
                            }
                            lineSort.variables = filerVars as NSDictionary
                            lineSort.keyPath = lineSort.bidPeriod?.lineSortKeyForCityLineSort(cityLineSort: lineSort, city: "")
                            if lineSort.sortHighlightsTrips() {
                                lineSort.highlightTrips()
                            }
                        }
                    }
                    if lineSort.sortHighlightsTrips() {
                        lineSort.highlightTrips()
                    }
                    try? self.context.save()
                }
            }
            if lineSortAutoComute.count != 0 {
                let commuteDict = lineSortAutoComute
                let varb = commuteDict["variable"] as? [String: Any]
                let dict2 = varb!
                var isNonStop = false
                var commuteCity = ""
                if dict2["commuteCity"] != nil {
                    commuteCity = (dict2["commuteCity"] as? String)!
                }
                if dict2["nonStop"] != nil {
                    let nonStopNumber = (dict2["nonStop"] as? NSNumber)!
                    isNonStop = nonStopNumber.boolValue && nonStopNumber.intValue != 0
                }
                var connectTime = dict2["selectedConnectTime"] as? NSNumber
                if connectTime == nil {
                    connectTime = 0
                }
                let commuteVC = CommuteCityViewController()
                //                        CBGlobalMethods.shared.showCustomActivityIndicator(message: "Calculating commute values..", bgcolor: .purple, height: 100)
                let (success, commuteCityReturn) = commuteVC.commutabilityCalculationWithForSync(city: commuteCity, isNonStop: isNonStop, connectTimeFromPreset: connectTime as! Int)
                //                        CBGlobalMethods.shared.hideCustomActivityIndicator()
                let commutInfoVC = CBCommuteInfoViewController()
                commutInfoVC.backToBaseFromSync = (dict2["selectedBackToBasePadTimeValues"] as? String)!
                let connectTimeStr = dict2["selectedConnectTime"] as? String
                if connectTimeStr == "--:--" {
                    commutInfoVC.connectTimeFromSync = "0:0"
                }
                else {
                    commutInfoVC.connectTimeFromSync = connectTimeStr!
                }
                commutInfoVC.checkInFromSync = (dict2["selectedTakeOffPadTimeValues"] as? String)!
                commutInfoVC.bidPeriod = self.bidPeriod
                commutInfoVC.commutabilityType = CommutabilityType.sort
                commutInfoVC.isNonStop = isNonStop
                commutInfoVC.commuteCityFromSync = commuteCity
                commutInfoVC.value = NSNumber(value: (dict2["cmtPercentage"] as? Int)!)
                commutInfoVC.secondCellValue = NSNumber(value: (dict2["nMid"] as? Int)!)
                commutInfoVC.thirdCellValue = NSNumber(value: (dict2["cmtFrBaOv"] as? Int)!)
                commutInfoVC.type = NSNumber(value: (dict2["cmtGreaterOrLesser"] as? Int)!)
                commutInfoVC.calculateCommuteLineProperties()
            }
        }
        
        let bidLstSorts = details["bidLstSorts"] as? NSMutableArray
        for case let sortDict as [String: Any] in bidLstSorts ?? [] {
            if sortDict["ListSort"] == nil {
                return
            }
            let subSorts = sortDict["ListSort"] as? NSMutableArray
            // saveing each sorts from the json to coredata.
            var linesortAutoCommute = [String: Any]()
            for case let subSort as [String: Any] in subSorts! {
                if subSort["Abbreviation"] as? String == "CmAuto" {
                    linesortAutoCommute = subSort
                }
                else {
                    let lineSort = BILineSort(context: self.context)
                    lineSort.abbreviation = subSort["Abbreviation"] as? String
                    let currentTile = self.sortTitleDict()[lineSort.abbreviation!]
                    lineSort.category = NSNumber(value: (subSort["Category"] as? Int)!)
                    lineSort.isBidListSort = NSNumber(booleanLiteral: true)
                    if subSort["Type"] != nil {
                        lineSort.type = NSNumber(value: (subSort["Type"] as? Int)!)
                    }
                    if subSort["ArrayVariables"] != nil {
                        let tmp = subSort["ArrayVariables"] as? NSMutableArray
                        lineSort.arrayVariables = tmp
                    }
                    lineSort.order = NSNumber(value: (subSort["Order"] as? Int)!)
                    lineSort.name = subSort["Name"] as? String
                    let ascending = subSort["Ascending"] as? Bool
                    lineSort.ascending = NSNumber(booleanLiteral: ascending!)
                    lineSort.isMutable = NSNumber(value: (subSort["IsMutable"] as? Int)!)
                    
                    if subSort["City"] != nil {
                        lineSort.city = subSort["City"] as? String
                        lineSort.setCity = subSort["City"] as? String
                    }
                    else if lineSort.abbreviation == "flag" {
                        var variable = [String: Any]()
                        let arrayVariables = lineSort.arrayVariables as? NSMutableArray
                        for i in 0..<arrayVariables!.count {
                            let val = arrayVariables![i] as? NSNumber
                            if val == 0 {
                                variable["NO_COLOR_FLAG"] = val
                            }
                            else if val == 1 {
                                variable["BLUE_COLOR_FLAG"] = val
                            }
                            else if val == 2 {
                                variable["GREEN_COLOR_FLAG"] = val
                            }
                            else if val == 3 {
                                variable["RED_COLOR_FLAG"] = val
                            }
                            else if val == 4 {
                                variable["YELLOW_COLOR_FLAG"] = val
                            }
                            else if val == 5 {
                                variable["ORANGE_COLOR_FLAG"] = val
                            }
                            else if val == 6 {
                                variable["BROWN_COLOR_FLAG"] = val
                            }
                            else if val == 7 {
                                variable["PINK_COLOR_FLAG"] = val
                            }
                        }
                        lineSort.variables = variable as NSDictionary
                    }
                    else if (lineSort.abbreviation == "OffSort" || lineSort.abbreviation == "WorkSort" || lineSort.abbreviation == "TripStartSort") {
                        lineSort.variables = BILineSort.configureMonthDayFilter((subSort["ArrayVariables"] as? NSMutableArray)!) as NSDictionary
                    }
                    else if lineSort.abbreviation == "Commute" {
                        let varb = subSort["Variable"] as? [String: Any]
                        var dict2 = varb!
                        let doubleKeys = [
                            "FRI_RETURN",
                            "FRI_DEPART",
                            "MON_THURS_DEPART",
                            "MON_THURS_RETURN",
                            "SAT_DEPART",
                            "SAT_RETURN",
                            "SUN_RETURN",
                            "SUN_DEPART"
                        ]

                        for key in doubleKeys {
                            if let value = dict2[key] {
                                if let number = value as? NSNumber {
                                    dict2[key] = number.doubleValue
                                } else if let string = value as? String, let doubleValue = Double(string) {
                                    dict2[key] = doubleValue
                                }
                            }
                        }

                        if let value = dict2["NoMidCheckState"] {
                            if let number = value as? NSNumber {
                                dict2["NoMidCheckState"] = number.boolValue
                            } else if let string = value as? String {
                                dict2["NoMidCheckState"] = (string as NSString).boolValue
                            }
                        }
                        lineSort.variables = dict2 as NSDictionary
                    }
                    else if currentTile == "Regional Overnight Cities" {
                        let variable = subSort["Variable"] as? [String: Any]
                        let setArray = variable!["City"] as? [Any]
                        let set = NSSet(array: setArray!)
                        lineSort.variables = ["SET": set]
                    }
                    else {
                        if subSort["Variable"] != nil {
                            lineSort.variables = subSort["Variable"] as? NSDictionary
                        }
                    }
                    if currentTile == "Position" {
                        lineSort.keyPath = self.bidPeriod?.lineSortKeyForPosition(posLineSort: lineSort)
                    }
                    else {
                        lineSort.keyPath = subSort["KeyPath"] as? String
                        if lineSort.abbreviation == "OffSort" {
                            lineSort.keyPath = bidPeriod?.lineSortKeyForDaysOff(lineSort: lineSort)
                            lineSort.ascending = 0
                        }
                        if lineSort.abbreviation == "WorkSort" {
                            lineSort.keyPath = bidPeriod?.lineSortKeyForDaysWork(lineSort: lineSort)
                            lineSort.ascending = 1
                        }
                        if lineSort.abbreviation == "TripStartSort" {
                            lineSort.keyPath = bidPeriod?.lineSortKeyForTripStartDays(lineSort: lineSort)
                            lineSort.ascending = 0
                        }
                    }
                    
                    if lineSort.sortHighlightsTrips() {
                        lineSort.highlightTrips()
                    }
                    try? self.context.save()
                }
            }
            if linesortAutoCommute.count != 0 {
                let commuteDict = linesortAutoCommute
                let varb = commuteDict["variable"] as? [String: Any]
                let dict2 = varb!
                var isNonStop = false
                var commuteCity = ""
                if dict2["commuteCity"] != nil {
                    commuteCity = (dict2["commuteCity"] as? String)!
                }
                if dict2["nonStop"] != nil {
                    let nonStopNumber = (dict2["nonStop"] as? NSNumber)!
                    isNonStop = nonStopNumber.boolValue && nonStopNumber.intValue != 0
                }
                var connectTime = dict2["selectedConnectTime"] as? NSNumber
                if connectTime == nil {
                    connectTime = 0
                }
                let commuteVC = CommuteCityViewController()
                //                        CBGlobalMethods.shared.showCustomActivityIndicator(message: "Calculating commute values..", bgcolor: .purple, height: 100)
                let (success, commuteCityReturn) = commuteVC.commutabilityCalculationWithForSync(city: commuteCity, isNonStop: isNonStop, connectTimeFromPreset: connectTime as! Int)
                //                        CBGlobalMethods.shared.hideCustomActivityIndicator()
                let commutInfoVC = CBCommuteInfoViewController()
                commutInfoVC.backToBaseFromSync = (dict2["selectedBackToBasePadTimeValues"] as? String)!
                let connectTimeStr = dict2["selectedConnectTime"] as? String
                if connectTimeStr == "--:--" {
                    commutInfoVC.connectTimeFromSync = "0:0"
                }
                else {
                    commutInfoVC.connectTimeFromSync = connectTimeStr!
                }
                commutInfoVC.checkInFromSync = (dict2["selectedTakeOffPadTimeValues"] as? String)!
                commutInfoVC.bidPeriod = self.bidPeriod
                commutInfoVC.commutabilityType = CommutabilityType.sort
                commutInfoVC.isNonStop = isNonStop
                commutInfoVC.commuteCityFromSync = commuteCity
                commutInfoVC.value = NSNumber(value: (dict2["cmtPercentage"] as? Int)!)
                commutInfoVC.secondCellValue = NSNumber(value: (dict2["nMid"] as? Int)!)
                commutInfoVC.thirdCellValue = NSNumber(value: (dict2["cmtFrBaOv"] as? Int)!)
                commutInfoVC.type = NSNumber(value: (dict2["cmtGreaterOrLesser"] as? Int)!)
                commutInfoVC.calculateCommuteLineProperties()
            }
        }
        try? self.context.save()
    }
    
    func selectedCitiesWithLinesort(linesort: BILineSort) -> [Any] {
        var cities: [Any] = []
        
        if let tmp = linesort.variables?["SET"] {
            if let set = tmp as? Set<AnyHashable> {
                cities = Array(set)
            } else if let array = tmp as? [Any] {
                cities = array
            }
        }
        
        return cities
    }
    
    func savePresets(presetArray: NSMutableArray) {
        var jsonArray: [Any] = []
        var plistData: Data? = nil
        let order = UIDevice.current.systemVersion.compare("16.0.0", options: .numeric)
        
        if order == .orderedSame || order == .orderedDescending {
            for case let preset as CBPreset in presetArray{
                var jsonDict = [String: Any]()
                var lineSorts: NSMutableArray = []
                var filterRules: NSMutableArray = []
                
                for filter in preset.filterRules {
                    var filtDict = [String: Any]()
                    filtDict["category"] = filter.category
                    filtDict["type"] = filter.category
                    filtDict["keyPath"] = filter.category
                    filtDict["abbreviation"] = filter.category
                    filtDict["comparison"] = filter.category
                    filtDict["variables"] = filter.category
                    filterRules.add(filtDict)
                }
                
                for sort in preset.lineSorts {
                    var sortDict: [String: Any] = [:]
                    sortDict["category"] = sort.category
                    sortDict["type"] = sort.type
                    sortDict["keyPath"] = sort.keyPath
                    sortDict["abbreviation"] = sort.abbreviation
                    sortDict["ascending"] = sort.ascending
                    sortDict["isMutable"] = sort.isMutable
                    sortDict["city"] = sort.city
                    sortDict["expression"] = sort.expression
                    sortDict["order"] = sort.order
                    sortDict["lineSortKeyMap"] = sort.lineSortKeyMap
                    sortDict["variables"] = sort.variables
                    sortDict["name"] = sort.name
                    sortDict["arrayVariables"] = sort.arrayVariables
                    sortDict["isBidListSort"] = sort.isBidListSort
                    lineSorts.add(sortDict)
                }
                jsonDict["lineSorts"] = lineSorts
                jsonDict["filterRules"] = filterRules
                jsonDict["name"] = preset.name
                jsonDict["month"] = self.bidPeriod!.month!.intValue
                jsonDict["year"] = self.bidPeriod!.year!.intValue
                jsonDict["position"] = self.bidPeriod!.positionType
                jsonDict["appVersion"] = self.bidPeriod!.appVersion
                jsonDict["lineValues"] = preset.lineValues
                jsonDict["selected"] = preset.selected
                jsonDict["presetIdentifier"] = preset.presetIdentifier
                jsonDict["overnight"] = preset.overnight
                jsonDict["commutabilityFilterDetails"] = preset.commutabilityFilterDetails
                jsonDict["commutabilitySortDetails"] = preset.commutabilitySortDetails
                jsonArray.append(jsonDict)
            }
            do {
                plistData = try NSKeyedArchiver.archivedData(withRootObject: jsonArray,
                                                             requiringSecureCoding: false)
            } catch {
                print("Archiving error: \(error)")
            }
        }
        else {
           do {
               plistData = try NSKeyedArchiver.archivedData(withRootObject: presetArray,
                                                            requiringSecureCoding: false)
           } catch {
               print("Archiving error: \(error)")
           }
       }
        if let plistData = plistData {
            let filePath = CBPresetsTVC().presetsDocumentFilePathWithBidPeriod(bidPeriod: self.bidPeriod!)
            let fileURL = URL(fileURLWithPath: filePath)
            
            do {
                try plistData.write(to: fileURL, options: .atomic)
                print("Presets saved at: \(fileURL.path)")
            } catch {
                print("Failed to save presets: \(error)")
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("presetSynched"), object: nil)
        
    }
    
    func stateKeepLocal() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM/dd/yyyy hh:mm: a"
        let now = Date()
        let startDate = now.timeIntervalSince1970 * 1000
        let dateStartedString = String(format: "/Date(%.0f+0800)/", startDate)
        var dictDetails = [String: Any]()
        var presetVersionNumber = 0
        dictDetails["EmployeeNumber"] = app.ObjUserAccount?.employeeNumber
        dictDetails["StateFileName"] = self.bidFilenameForState()
        dictDetails["PreSetFileName"] = NSNull()
        dictDetails["Year"] = self.bidPeriod!.year!
        dictDetails["StateVersionNumber"] = self.bidPeriod?.stateSyncVersion?.intValue
        dictDetails["StateContent"] = self.getJsonDictForStateSync()
        dictDetails["StateLastUpdatedTime"] = dateStartedString
        dictDetails["PresetVersionNumber"] = 0
        dictDetails["PresetContent"] = NSNull()
        dictDetails["PreSetLastUpdatedTime"] = dateStartedString
        objdatabuilder.saveCrewBidStateAndPresetToServer(dictDetails: dictDetails) { response in
            if let response = response {
                self.bidPeriod?.isStateFileModifiedToSync = false
                let responseDict = response[0]
                if responseDict["IsStateSuccess"] != nil {
                    let isPresetSynced = responseDict["IsStateSuccess"] as? NSNumber
                    if isPresetSynced?.boolValue == true {
                        self.bidPeriod?.currentDateTime = Date()
                        try? self.context.save()
                        AlertService.showAlertForTopVC(title: "Synched!", message: "You have successfully synched your CrewBid State to server.")
                    }
                    else {
                        AlertService.showAlertForTopVC(title: "", message:"CrewBid State synch was not success!")
                    }
                }
                else {
                    AlertService.showAlertForTopVC(title: "Error!", message: "Something went wrong!")
                }
//                print("✅ Server response:", response)
            } else {
                AlertService.showAlertForTopVC(title: "Error!", message: "Something went wrong!")
                print("❌ Failed to save preset/state")
            }
        }
    }
    
    
    func bidFilenameForState() -> String {
        var bidRoundChar = "M"
        if self.bidPeriod!.isSecondRoundBid() {
            bidRoundChar = "W"
        }
        var dateString = "\(bidPeriod!.year!)"
        let twoDigitDate = String(dateString.suffix(2))
        let positionInt = self.bidPeriod!.positionType!.intValue
        let position = BICrewPositionType(rawValue: positionInt)
        let positionShortString = CBUtils.shortName(for: position!)
        let bidDataFilename = String(format: "CB%@%@%02ld%@%c", self.bidPeriod!.base!, positionShortString, self.bidPeriod!.month!.intValue, twoDigitDate, bidRoundChar)
        return bidDataFilename
    }
    
    func getJsonDictForStateSync() -> String {
        let jsonString = [String: Any]()
        let quickFilterDict = self.getQuickFilterDictFromLocalDB()
        let filterDict = self.getMenuFilterDictFromLocalDB()
        let sortDict = self.getMenuSortsDictFromLocalDB()
        let trashedLinesDict = self.getTrashedLinesDictFromLocalDB()
        let flaggedLinesDict = self.getFlaggedLinesDictFromLocalDB()
        let bidlistDetails = self.getBidListLinesDictFromLocalDB()
        let aSortDetails = self.getASortDetailsFromLocalDB()
        let platformDetails = self.getPlatForm()
        let vacationButtons = self.getMenubarButtons()
        let vacationDetails = self.getVactionDetails()
        let faEOMDatesDetails = self.getFaEOMDates()
        let insertLineBetween = self.getInsertLineBetween()
        let bidListSortDict = self.getBidListSortsDictFromLocalDB()
        let myCalDetails = self.getMyCalDetails()
        let ampmTime: [String: Any] = ["AMPMtime": NSNumber(value: Int(UserDefaults.standard.string(forKey: KCBCustomizedHerbValue) ?? "") ?? 0)]
        let buddyBidders = [
            "buddyBidder1": self.getbuddyBidder1(),
            "buddyBidder2": self.getbuddyBidder2()
        ]
        let mergedDict = self.mergeDictionaries([quickFilterDict, filterDict, sortDict, trashedLinesDict, flaggedLinesDict, bidlistDetails, aSortDetails, vacationButtons, vacationDetails, faEOMDatesDetails, platformDetails, ampmTime, insertLineBetween, bidListSortDict, buddyBidders, myCalDetails])
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: mergedDict, options: .fragmentsAllowed)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString ?? ""
        } catch {
            print("Error serializing JSON: \(error)")
            return ""
        }

    }
    
    func getQuickFilterDictFromLocalDB() -> [String: Any] {
        var LstQuickFiletDict = [String: Any]()
        let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true), NSSortDescriptor(key: "type", ascending: true)]
        let resulFilter = try! self.context.fetch(fetchRequest)
        LstQuickFiletDict = self.getQuickFilterListDictFromLocal(from: resulFilter, isState: true, resultsFilterPreset: nil)
        return LstQuickFiletDict
    }
    
    func getMenuFilterDictFromLocalDB() -> [String: Any] {
        var LstFiltDict = [String: Any]()
        let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true), NSSortDescriptor(key: "type", ascending: true)]
        let resulFilter = try! self.context.fetch(fetchRequest)
        LstFiltDict = self.getMenuFilterListDictFromLocalForSync(from: resulFilter, isState: true, resultsPresetFilter: nil)
        return LstFiltDict
    }
    
    func getMenuSortsDictFromLocalDB() -> [String: Any] {
        var lstSortDict = [String: Any]()
        let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "isBidListSort != %@", NSNumber(value: true))

        let resulSort = try! self.context.fetch(fetchRequest)
        lstSortDict = self.getMenuSortListDictFromLocalForSync(resultsSort: resulSort, isState: true, resultsPresetSort: nil, isConversion: false)
        return lstSortDict
    }
    
    func getTrashedLinesDictFromLocalDB() -> [String: Any] {
        let trashedLinesArray = self.bidPeriod!.lastTrashedDetails
        let trashDictionary: [String: Any] = ["trashedLines": trashedLinesArray?.mutableCopy() ?? []]
        return trashDictionary
    }
    
    func getFlaggedLinesDictFromLocalDB() -> [String: Any] {
        var flaggedDetails = [String: Any]()
        let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        do {
            let results = try self.context.fetch(fetchRequest)
            let flasgDictArray = NSMutableArray()
            for line in results {
                var flaggedDict = [String: Any]()
                flaggedDict = [
                    "LineNum" : line.number!,
                    "FlagColor" : line.userFlagType,
                    "FAPosition" : line.faPositionString
                ]
                flasgDictArray.add(flaggedDict)
            }
            flaggedDetails["flagDetails"] = flasgDictArray
        }
        catch {
            print("\(error.localizedDescription)")
        }
        return flaggedDetails
    }
    
    func getBidListLinesDictFromLocalDB() -> [String: Any] {
        var bidListDict = [String: Any]()
        let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bidOrder > 0")
        do {
            let results = try self.context.fetch(fetchRequest)
            var dictArray = NSMutableArray()
            for bidLine in results {
                var bidLineDict = [String: Any]()
                bidLineDict["LineNum"] = bidLine.number!
                if self.bidPeriod!.isFABid() {
                    if self.bidPeriod!.isFirstRoundBid() {
                        if bidLine.faBidLineReserve?.boolValue == true {
                            bidLineDict["FAPosition"] = "R"
                            bidLineDict["LineNum"] = 0
                        }
                        else if bidLine.faBidLineMrt?.boolValue == true {
                            bidLineDict["FAPosition"] = "M"
                            bidLineDict["LineNum"] = 0
                        }
                        else {
                            bidLineDict["FAPosition"] = bidLine.faPositionString
                        }
                    }
                    else {
                        bidLineDict["FAPosition"] = bidLine.faPositionString
                    }
                }
                else {
                    bidLineDict["FAPosition"] = ""
                }
                bidLineDict["BidOrder"] = bidLine.bidOrder
                bidLineDict["PreviousBidOrder"] = bidLine.previousBidOrder
                bidLineDict["IsFreeze"] = bidLine.isFrozen
                if bidLine.markerTitle != nil {
                    bidLineDict["MarkerText"] = bidLine.markerTitle
                }
                dictArray.add(bidLineDict)
            }
            bidListDict["BidListDetails"] = dictArray
        }
        catch {
            print("\(error.localizedDescription)")
        }
        return bidListDict
    }
    
    func getASortDetailsFromLocalDB() -> [String: Any] {
        var aSortsConditions: [String: Any] = [:]
        aSortsConditions["IsSortBySubmit"] = bidPeriod?.isSortBySubmitOn?.boolValue
        aSortsConditions["IsSortByAward"] = bidPeriod?.isAwardSortOn?.boolValue
            return aSortsConditions
    }
    
    func getMenubarButtons() -> [String: Any] {
        var btnDetails: [String: Any] = [:]
        
        btnDetails["vacationButton"] = bidPeriod?.isWbidMaxOn?.intValue
        btnDetails["eomButton"] = bidPeriod?.isEomOn?.intValue
        btnDetails["swaptimizerButton"] = bidPeriod?.isSwaptimizerOn?.intValue

        if bidPeriod?.isFABid() == true {
            btnDetails["vacationButton"] = bidPeriod?.isFAVacationOn?.intValue
        }

        return ["MenubarButtons": btnDetails]
    }
    
    func getVactionDetails() -> [String: Any] {
        var vacDetails: [[String: Any]] = []

        if let vacations = bidPeriod?.vacations {
            for case let vacay as BIVacation in vacations {
                var obj: [String: Any] = [:]
                obj["startDate"] = self.getDateString(vacay.startDate)
                obj["endDate"] = self.getDateString(vacay.endDate)
                obj["type"] = vacay.vacationType
                vacDetails.append(obj)
            }
        }

        return ["Vacation": vacDetails]
    }

    func getDateString(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: date)
        
        // Convert back to Date (same as Objective-C logic)
        guard let parsedDate = formatter.date(from: dateString) else { return "" }
        
        formatter.dateFormat = "MM/dd/yyyy"
        let finalString = formatter.string(from: parsedDate)
        
        return finalString
    }
    
    func getFaEOMDates() -> [String: Any] {
        var eOMSelectedDateDict = [String: Any]()
        if self.bidPeriod!.vacations != nil {
            for case let vacay as BIVacation in self.bidPeriod!.vacations! {
                eOMSelectedDateDict["EOMSelectedDate"] = self.bidPeriod!.faEomSelectedDate
                return eOMSelectedDateDict
            }
        }
        return eOMSelectedDateDict
    }
    
    func getPlatForm() -> [String: Any] {
        var platFormDict = [String: Any]()
        platFormDict["Platform"] = "iPad"
        return platFormDict
    }
    
    func getInsertLineBetween() -> [String: Any] {
        var insertIndex: NSNumber = 0
        var isInsertLineAbove: NSNumber = 0
        var insertionPoint: BIInsertionPoint? = nil
        let fetchRequest: NSFetchRequest<BIInsertionPoint> = BIInsertionPoint.fetchRequest()
        fetchRequest.fetchLimit = 1
        let results = try? self.context.fetch(fetchRequest)
        if results?.count ?? 0 > 0 {
            insertionPoint = results![0]
            insertIndex = insertionPoint!.index ?? 0
            isInsertLineAbove = insertionPoint!.above ?? 0
        }
        var dict1 = [String: Any]()
        dict1["insertIndex"] = insertIndex
        if isInsertLineAbove.boolValue {
            dict1["isInsertLineAbove"] = true
        }
        else {
            dict1["isInsertLineAbove"] = false
        }
        let dict: [String: Any] = ["InsertLineBetween": dict1]
        return dict
    }
    
    func getBidListSortsDictFromLocalDB() -> [String: Any] {
        var lstSortDict = [String: Any]()
        let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "isBidListSort == %@", NSNumber(value: true))

        let resulSort = try! self.context.fetch(fetchRequest)
        lstSortDict = self.getMenuSortListDictFromLocalForSync(resultsSort: resulSort, isState: true, resultsPresetSort: nil, isConversion: false)
        let biDlistSortDict: [String: Any] = ["lstSorts" :lstSortDict]
        let bidLstSorts: [String: Any] = ["bidLstSorts": biDlistSortDict]
        return bidLstSorts
    }
    
    func getMyCalDetails() -> [String: Any] {
        var myCalDetails: [String: Any] = [:]
        myCalDetails["myCalEnabled"] = Int(self.bidPeriod!.myCalEnabled!.intValue)
        myCalDetails["myCalStartDate"] = getDateStringGMT(self.bidPeriod!.myCalStartDate!)
        myCalDetails["myCalEndDate"] = getDateStringGMT(self.bidPeriod!.myCalEndDate!)
        
        return ["myCalDetails": myCalDetails]
    }

    func getDateStringGMT(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let myString = formatter.string(from: date)
        let yourDate = formatter.date(from: myString)
        
        formatter.dateFormat = "MM/dd/yyyy"
        let myStringAfd = formatter.string(from: yourDate ?? date)
        
        return myStringAfd
    }
    
    func getbuddyBidder1() -> String {
        if self.bidPeriod!.buddyBidder1 == nil {
            return ""
        }
        return self.bidPeriod!.buddyBidder1!
    }
    
    func getbuddyBidder2() -> String {
        if self.bidPeriod!.buddyBidder2 == nil {
            return ""
        }
        return self.bidPeriod!.buddyBidder2!
    }

    func stateTakeServerWithCompletion(completion: @escaping ([[String: Any]]?) -> Void) {
        var dictDetails: [String: Any] = [:]
        dictDetails["Employeeumber"] = app.ObjUserAccount?.employeeNumber
        dictDetails["StateName"] = self.bidFilenameForState()
        dictDetails["PresetFileName"] = NSNull()
        dictDetails["Year"] = bidPeriod!.year
        dictDetails["FileType"] = 0
        ODataBuilder().getCrewBidStateAndPresetFromServer(dictDetails: dictDetails) { result in
            if let result = result {
                let responseDict = result[0]
                let IsOldState = responseDict["IsOldState"] as? NSNumber
                if IsOldState?.boolValue == true {
                    completion(result)
                    return
                }
                if responseDict["StateContent"] != nil {
                    let contentString = responseDict["StateContent"] as? String
                    let contentDict = self.convertStringToDictionary(contentString!)
                    DispatchQueue.main.async {
                        let contentDictFirst = contentDict![0]
                        self.setMyCalToLocalDB(details: contentDictFirst)
                        self.setTrashLineAndDetailsToLocalDB(details: contentDictFirst)
                        self.setQuickFilterToLocalDB(details: contentDictFirst)
                        self.setFlaggedLineAndDetailsToLocalDB(details: contentDictFirst)
                        self.setFilterToLocalDB(details: contentDictFirst)
                        self.setSortToLocalDB(details: contentDictFirst)
                        self.setBidListDetailsToLocalDB(details: contentDictFirst)
                        self.setInsertionIndexToLocalDB(details: contentDictFirst)
                        self.setASortConditions(details: contentDictFirst)
                        self.setFaEOMDates(details: contentDictFirst)
                        self.setVacationButtonsLocalDB(details: contentDictFirst)
                        self.bidPeriod!.isStateFileModifiedToSync = NSNumber(booleanLiteral: false)
                        self.bidPeriod!.stateSyncVersion = NSNumber(value: ((self.arrayDictRecived?.first?["StateVersionNumber"] as? Int) ?? 0))
                        
                    }
                    DispatchQueue.main.async {
                        if !self.syncContainsVacation {
                            AlertService.showAlertForTopVC(title: "Synced!", message: "State sync was successful!")
                        }
                    }
                }
                else {
                    AlertService.showAlertForTopVC(title: "Error!", message: "Content from server is NULL")
                }
            }
            else {
                AlertService.showAlertForTopVC(title: "Error!", message: "Something went wrong")
            }
        }
    }
    
    func setMyCalToLocalDB(details: [String: Any]) {
        let myCalDetails = details["myCalDetails"] as? [String: Any]
        let myCalEnabled = myCalDetails?["myCalEnabled"] as? NSNumber
        let myCalStartDate = myCalDetails?["myCalStartDate"] as? String
        let myCalEndDate = myCalDetails?["myCalEndDate"] as? String
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        
        let date1 = dateFormatter.date(from: myCalStartDate!)
        let date2 = dateFormatter.date(from: myCalEndDate!)
        
        bidPeriod!.myCalEnabled = myCalEnabled
        bidPeriod!.myCalStartDate = date1
        bidPeriod!.myCalEndDate = date2
    }
    
    func setTrashLineAndDetailsToLocalDB(details: [String: Any]) {
        if details["trashedLines"] != nil {
            if self.bidPeriod!.isFABid() {
                let trashedLinesArray = details["trashedLines"] as? NSMutableArray
                self.bidPeriod!.lastTrashedDetails = trashedLinesArray
                let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
                let allLines = try? self.lineManger?.managedObjectContext.fetch(fetchRequest)
                for line in allLines ?? [] {
                    line.isTrashed = NSNumber(booleanLiteral: false)
                    let faLineNumber = "\(String(describing: line.number?.stringValue))\(line.faPositionString)"
                    for trashedLineNum in trashedLinesArray ?? [] {
                        let trashedArray = (trashedLineNum as? String)?.components(separatedBy: ",")
                        if trashedArray!.contains(faLineNumber) {
                            line.isTrashed = NSNumber(booleanLiteral: true)
                        }
                    }
                }
            }
            else {
                let trashedLinesArray = details["trashedLines"] as? NSMutableArray
                self.bidPeriod!.lastTrashedDetails = trashedLinesArray
                let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
                let allLines = try? self.lineManger?.managedObjectContext.fetch(fetchRequest)
                for line in allLines ?? [] {
                    if trashedLinesArray!.contains(line.number!.stringValue) {
                        line.isTrashed = NSNumber(booleanLiteral: true)
                    }
                    else {
                        line.isTrashed = NSNumber(booleanLiteral: false)
                    }
                }
            }
            try? lineManger?.managedObjectContext.save()
        }
        else {
            return
        }
    }
    
    func setFlaggedLineAndDetailsToLocalDB(details: [String: Any]) {
        for case let line as BILine in self.bidPeriod!.lines ?? [] {
            line.userFlagType = 0
        }
        if details["flagDetails"] != nil {
            let flaggedLinesArray = details["flagDetails"] as? NSMutableArray
            var flaggedLineNumbers = NSMutableArray()
            for case let dict as [String: Any] in flaggedLinesArray! {
                if dict["LineNum"] != nil {
                    flaggedLineNumbers.add(dict["LineNum"]!)
                }
            }
            let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "number IN %@", flaggedLineNumbers)
            let linesForFlag = try? self.lineManger?.managedObjectContext.fetch(fetchRequest)
            for case let flaggedLine as [String: Any] in flaggedLinesArray! {
                for line in linesForFlag ?? [] {
                    if self.bidPeriod?.isFABid() == false {
                        let lineNum = (flaggedLine["LineNum"] as? NSNumber)?.intValue
                        if line.number?.intValue == lineNum {
                            line.userFlagType = flaggedLine["FlagColor"] as? NSNumber
                        }
                    }
                    else {
//                        for FA
                        let lineNum = (flaggedLine["LineNum"] as? NSNumber)?.intValue
                        let pos = flaggedLine["FAPosition"] as? String
                        var faPos = 0
                        if pos == "A" {
                            faPos = 1
                        }
                        else if pos == "B" {
                            faPos = 2
                        }
                        else if pos == "C" {
                            faPos = 3
                        }
                        else if pos == "D" {
                            faPos = 4
                        }
                        else if pos == "M" {
                            faPos = 5
                        }
                        else {
                            faPos = 6
                        }
                        
                        if (line.number?.intValue == lineNum && line.faPosition?.intValue == faPos) {
                            line.userFlagType = flaggedLine["FlagColor"] as? NSNumber
                        }
                    }
                }
            }
            try? self.lineManger?.managedObjectContext.save()
        }
        else {
            return
        }
    }
    
    func setBidListDetailsToLocalDB(details: [String: Any]) {
        if details["BidListDetails"] == nil {
            return
        }
        let bidListDetails = details["BidListDetails"] as? NSMutableArray
        let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        let allLines = try? self.lineManger?.managedObjectContext.fetch(fetchRequest)
        if allLines?.count ?? 0 > 0 {
            var reserveDetails = [String: Any]()
            var mrtDetails = [String: Any]()
            for line in allLines! {
                line.isFrozen = 0
                line.frozenOrder = NSNumber(booleanLiteral: false)
                line.previousBidOrder = 0
                line.markerTitle = nil
                if line.faBidLineMrt?.boolValue == true {
                    self.lineManger?.managedObjectContext.delete(line)
                    self.bidPeriod?.faMrtLineExists = false
                    try? self.lineManger?.managedObjectContext.save()
                    continue
                }
                if line.faBidLineReserve?.boolValue == true {
                    self.lineManger?.managedObjectContext.delete(line)
                    self.bidPeriod?.faReserveLineExists = false
                    try? self.lineManger?.managedObjectContext.save()
                    continue
                }
                for case let bidListDetail as [String: Any] in bidListDetails! {
                    if self.bidPeriod!.isFABid() {
                        if self.bidPeriod!.isFirstRoundBid() && bidListDetail["FAPosition"] as? String == "M" {
                            mrtDetails = bidListDetail
                            continue
                        }
                        else if self.bidPeriod!.isFirstRoundBid() && bidListDetail["FAPosition"] as? String == "R" {
                            reserveDetails = bidListDetail
                            continue
                        }
                        if line.number?.intValue == (bidListDetail["LineNum"] as? NSNumber)?.intValue {
                            if line.faPositionString == (bidListDetail["FAPosition"] as? NSNumber)?.stringValue {
                                if bidListDetail["IsFreeze"] != nil {
                                    line.isFrozen = NSNumber(value: (bidListDetail["IsFreeze"] as? Bool ?? false))
                                }
                                if bidListDetail["MarkerText"] != nil {
                                    line.markerTitle = (bidListDetail["MarkerText"] as? NSNumber)?.stringValue
                                }
                                line.bidOrder = NSNumber(value: (bidListDetail["BidOrder"] as? Int ?? 0))
                                line.previousBidOrder = NSNumber(value: (bidListDetail["PreviousBidOrder"] as? Int ?? 0))
                            }
                        }
                    }
                    else {
                        if line.number?.intValue == (bidListDetail["LineNum"] as? NSNumber)?.intValue {
                            if bidListDetail["IsFreeze"] != nil {
                                line.isFrozen = NSNumber(value: (bidListDetail["IsFreeze"] as? Bool ?? false))
                            }
                            if bidListDetail["MarkerText"] != nil {
                                line.markerTitle = (bidListDetail["MarkerText"] as? NSNumber)?.stringValue
                            }
                            line.bidOrder = NSNumber(value: (bidListDetail["BidOrder"] as? Int ?? 0))
                            line.previousBidOrder = NSNumber(value: (bidListDetail["PreviousBidOrder"] as? Int ?? 0))
                        }
                    }
                }
            }
            // Insert reserve or MRT lines in bidlist
            if self.bidPeriod!.isFABid() && self.bidPeriod!.isFirstRoundBid() {
                if mrtDetails.count > 0 {
                    let mRTLine = BILine(context: self.lineManger!.managedObjectContext)
                    mRTLine.faBidLineMrt = NSNumber(booleanLiteral: true)
                    mRTLine.number = 10000
                    mRTLine.faNumber = "10000NA"
                    mRTLine.bidPeriod = self.bidPeriod
                    self.bidPeriod?.faMrtLineExists = NSNumber(booleanLiteral: true)
                    mRTLine.bidOrder = NSNumber(value: (mrtDetails["BidOrder"] as? Int ?? 0))
                    mRTLine.previousBidOrder = NSNumber(value: (mrtDetails["PreviousBidOrder"] as? Int ?? 0))
                    try? self.lineManger?.managedObjectContext.save()
                }
                if reserveDetails.count > 0 {
                    let reserveLine = BILine(context: self.lineManger!.managedObjectContext)
                    reserveLine.faBidLineMrt = NSNumber(booleanLiteral: true)
                    reserveLine.number = 10001
                    reserveLine.faNumber = "10001NA"
                    reserveLine.bidPeriod = self.bidPeriod
                    self.bidPeriod?.faMrtLineExists = NSNumber(booleanLiteral: true)
                    reserveLine.bidOrder = NSNumber(value: (reserveDetails["BidOrder"] as? Int ?? 0))
                    reserveLine.previousBidOrder = NSNumber(value: (reserveDetails["PreviousBidOrder"] as? Int ?? 0))
                    try? self.lineManger?.managedObjectContext.save()
                }
            }
        }
        try? self.lineManger?.managedObjectContext.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    func setInsertionIndexToLocalDB(details: [String: Any]) {
        let bidListDetails = details["BidListDetails"] as? NSMutableArray
        let insertLineBetween = details["InsertLineBetween"] as? [String: Any]
        if insertLineBetween != nil && bidListDetails != nil {
            let insertIndex = NSNumber(value: (insertLineBetween!["insertIndex"] as? Int)!)
            let isInsertLineAbove = NSNumber(value: (insertLineBetween!["isInsertLineAbove"] as? Bool ?? false))

            if bidListDetails!.count > insertIndex.intValue {
                let fetchRequest: NSFetchRequest<BIInsertionPoint> = BIInsertionPoint.fetchRequest()
                let results = try? self.context.fetch(fetchRequest)
                for point in results ?? [] {
                    self.context.delete(point)
                }
                let objinsertion = BIInsertionPoint(context: self.context)
                objinsertion.above = isInsertLineAbove
                objinsertion.index = insertIndex
                try? self.context.save()
                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            }
        }
    }
    
    func setASortConditions(details: [String: Any]) {
        if details["IsSortByAward"] != nil && details["IsSortBySubmit"] != nil {
            let userInfo = [
                "AwardSortisOn": NSNumber(value: details["IsSortByAward"] as? Bool ?? false),
                "SubmitSortisOn": NSNumber(value: details["IsSortBySubmit"] as? Bool ?? false)
            ]
        }
        else {
            return
        }
    }

    func setFaEOMDates(details: [String: Any]) {
        if details["EOMSelectedDate"] != nil {
            self.bidPeriod!.faEomSelectedDate = details["EOMSelectedDate"] as? NSNumber
            self.bidPeriod?.vacationType = "FAVacationEomOnly"
        }
        else {
            return
        }
    }
    
    func setVacationButtonsLocalDB(details: [String: Any]) {
        if details["MenubarButtons"] != nil {
            self.bidPeriod?.isSwaptimizerOn = NSNumber(booleanLiteral: false)
            self.bidPeriod?.isEomOn = NSNumber(booleanLiteral: false)
            self.bidPeriod?.isWbidMaxOn = NSNumber(booleanLiteral: false)
            self.bidPeriod?.isFAVacationOn = NSNumber(booleanLiteral: false)
            let menubarButton = details["MenubarButtons"] as? [String: Any]
            
            if menubarButton?["swaptimizerButton"] != nil {
                syncContainsVacation = true
                self.bidPeriod!.isSwaptimizerOn = menubarButton?["swaptimizerButton"] as? NSNumber
            }
            if menubarButton?["eomButton"] != nil {
                syncContainsVacation = true
                self.bidPeriod!.isEomOn = menubarButton?["eomButton"] as? NSNumber
            }
            if menubarButton?["vacationButton"] != nil {
                syncContainsVacation = true
                self.bidPeriod!.isWbidMaxOn = menubarButton?["vacationButton"] as? NSNumber
                if bidPeriod!.isFABid() {
                    self.bidPeriod!.isFAVacationOn = menubarButton?["vacationButton"] as? NSNumber
                }
            }
            let vacations = details["Vacation"] as? NSMutableArray
            if vacations?.count ?? 0 > 0 {
                let vacation = vacations?[0] as? [String: Any]
                self.bidPeriod!.vacationType = vacation!["type"] as? String
            }
            try? self.lineManger?.managedObjectContext.save()
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
        else {
            return
        }
    }
}
