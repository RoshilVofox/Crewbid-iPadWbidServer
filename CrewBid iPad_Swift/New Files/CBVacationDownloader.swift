//
//  CBVacationDownloader.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 22/05/25.
//

import Foundation
import CoreData
import UIKit

enum BIVacationOverlapTripOption: Int {
    case showAll = 0
    case dropFront
    case dropBack
    case dropAll
}

class CBVacationDownloader: NSObject, NSFetchedResultsControllerDelegate {
    
    let kSwaptimizerUrlTest = URL(string: "https://swaptimizer2.com/secure/cgi-bin/crewbid.f-week.cgi")!
    let kSwaptimizerUrl = URL(string: "https://secure.swaptimizer2.com/cgi-bin/crewbid.cgi")!
    let kswaptimizerAccessKey = "!evG7*5^7E"
    
    let app = UIApplication.shared.delegate as! AppDelegate
    var webData: NSMutableData?
    var bidPeriod: BIBidPeriod?
    var filesCount: Float = 0
    var urlData: NSMutableData?
    var urlRequest: URLRequest?
    let kURLConnectionTimeout: TimeInterval = 20.0
    let kURLConnectionTimeoutVD: TimeInterval = 90.0
    enum VacationDownloadType {
        case downloadWbidVacation
        case downloadFAVacation
    }
    var dataSource = GlobalBidInfo.shared
    var vactionDownloadType: VacationDownloadType?
    var isAutoDownload = false
    var EOMSelectedIndex = ""
    var calendarData: BICalendarData = BICalendarData()
    var round: NSNumber?
    var year: NSNumber?
    var month: NSNumber?
    var position: Int?
    static let shared = CBVacationDownloader()
    var employeeNumber: String?
    var base: String?
    
    let kVoLabel = "VO"
    let kVaLabel = "VA"
    let kFrontVoFull = "FrontVO-full"
    let kFrontVoPartial = "FrontVO-partial"
    let kBackVoFull = "BackVO-full"
    let kBackVoPartial = "BackVO-partial"
    let kPullTypeFront = "Front"
    let kPullTypeBack = "Back"
    let kPullTypeAll = "All"
    
    required init(bidPeriod : BIBidPeriod) {
//        self.controller = controller
        self.bidPeriod = bidPeriod
        calendarData = calendarData.initWithBidPeriod(bidPeriod: bidPeriod)!
    }

    override init() {
        super.init()
//        self.fetchAndPrintTripCount()
//        let ab = dataSource.position
//        let cb = dataSource.base
//        print("base\(cb) postion\(ab)")
//        let context = dataSource.managedObjectContext
//        let fetchRequest: NSFetchRequest<BIBidPeriod> = BIBidPeriod.fetchRequest()
//
//        let targetRound = dataSource.round as NSNumber
//        let targetMonth = dataSource.month as NSNumber
//        let targetPosition = NSNumber(value: dataSource.position.rawValue)
//        let targetBase = dataSource.base
//        let targetYear = dataSource.year as NSNumber
//        let targetEmployee = dataSource.employeeNumber
//
//        fetchRequest.predicate = NSPredicate(
//            format: "round == %@ AND month == %@ AND positionType == %@ AND base == %@ AND year == %@ AND crewIdentifier == %@",
//            targetRound, targetMonth, targetPosition, targetBase, targetYear, targetEmployee
//        )
//
//        do {
//            let results = try context.fetch(fetchRequest)
//            self.bidPeriod = results.first
//            if (self.bidPeriod != nil){
//                print("Found bidPeriod: ")
//            } else {
//                print("No matching bidPeriod found.")
//            }
//        } catch {
//            print("Fetch error: \(error)")
//        }

     
    }
//    func fetchAndPrintTripCount() {
//        let context = CoreDataManager.shared.persistentContainer.viewContext
//        let fetchRequest: NSFetchRequest<BITrip> = BITrip.fetchRequest()
//
//        do {
//            let trips = try context.fetch(fetchRequest)
//            print("Total BITrip count: \(trips.count)")
//        } catch {
//            print("Failed to fetch BITrip: \(error)")
//        }
//    }
    
//    MARK: vacation File type = "CREWBID" and download
    func downloadSwaptimizerVacationFilesWithHud(completion: @escaping (Bool) -> Void) {
        self.bidPeriod?.userVacationWbidOrCrewBid = "CREWBID"
        try? self.bidPeriod?.managedObjectContext?.save()
        if let cbFileIntent = self.bidPeriod?.cbFileIntent {
            if let dicVactionFile = self.readVacationFile(fileName: "CREWBID"),
               let configInfo = dicVactionFile["ConfigInfo"] as? [String: Any],
               let yearMonth = configInfo["YearMonth"] as? String {
                
                let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
                if vacayMonth != self.bidPeriod?.month?.intValue {
                    let moc = self.bidPeriod?.managedObjectContext
                    self.bidPeriod?.cbFileIntent = ""
                    do {
                        try moc?.save()
                        print("file name saved")
                    } catch {
                        print("file name not saved")
                    }

                    // Remove old vacation file here if needed
                    self.downloadCrewbidVacationFiles(crewbidType: "CREWBID") {
                        completion($0) // Pass the result of downloadCrewbid
                    }
                } else {
                    self.callToSetAutoDownloadOrValidateForSwaptimizer(jsonData: dicVactionFile) {
                        completion($0) // Assuming this method is updated to use completion
                    }
                }
            } else {
                // Parsing failed or file missing
                self.downloadCrewbidVacationFiles(crewbidType: "CREWBID") {
                    completion($0)
                }
            }
        } else {
            self.downloadCrewbidVacationFiles(crewbidType: "CREWBID") {
                completion($0)
            }
        }
    }

    
    //    MARK: vacation File type = "CREWBIDF" and download
    func downloadSwaptimizerEOMVacationFilesWithHud(completion: @escaping (Bool) -> Void) {
        self.bidPeriod?.userVacationWbidOrCrewBid = "CREWBIDF"
        try? self.bidPeriod?.managedObjectContext?.save()
        if let fileIntent = self.bidPeriod?.cbFileIntentF, !fileIntent.isEmpty {
            guard let dicVacationFile = self.readVacationFile(fileName: fileIntent) else {
                // File read failed, trigger download
                self.downloadCrewbidVacationFiles(crewbidType: "CREWBIDF", completion: completion)
                return
            }
            
            guard let configInfo = dicVacationFile["ConfigInfo"] as? [String: Any],
                  let yearMonth = configInfo["YearMonth"] as? String else {
                self.downloadCrewbidVacationFiles(crewbidType: "CREWBIDF", completion: completion)
                return
            }
            
            let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
            let currentMonth = self.bidPeriod?.month?.intValue ?? 0
            
            if vacayMonth != currentMonth {
                let moc = self.bidPeriod?.managedObjectContext
                self.bidPeriod?.cbFileIntentF = ""
                do {
                    try moc?.save()
                    print("cbFileIntentF cleared and context saved")
                } catch {
                    print("Failed to save context after clearing cbFileIntentF: \(error)")
                }

                // Optionally delete the old vacation file here
                // self.deleteVacationFile(fileName: fileIntent)

                self.downloadCrewbidVacationFiles(crewbidType: "CREWBIDF", completion: completion)
            } else {
                self.callToSetAutoDownloadOrValidateForSwaptimizer(jsonData: dicVacationFile) {
                    completion($0)
                }
            }
        } else {
            self.downloadCrewbidVacationFiles(crewbidType: "CREWBIDF", completion: completion)
        }
    }

    
    //    MARK: vacation File type = "WBID" and download
    func downloadWbidVacationFilesWithHud(completion: @escaping (Bool) -> Void) {
        self.bidPeriod?.userVacationWbidOrCrewBid = "WBID"
        try? self.bidPeriod?.managedObjectContext?.save()
        if let wbFileIntent = self.bidPeriod?.wbFileIntent {
            if let dicVactionFile = self.readVacationFile(fileName: "WBID") {
                if let configInfo = dicVactionFile["ConfigInfo"] as? [String: Any],
                   let yearMonth = configInfo["YearMonth"] as? String {
                    
                    let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
                    if vacayMonth != self.bidPeriod?.month?.intValue {
                        let moc = self.bidPeriod?.managedObjectContext
                        self.bidPeriod?.wbFileIntent = ""
                        do {
                            try moc?.save()
                            print("file name saved")
                        } catch {
                            print("file name not saved")
                        }

                        // Add function to remove vacation file from document directory
                        // self.removeVacationFile(fileName: "WBID")

                        self.downloadWbidVacation { success in
                            completion(success)
                        }
                    } else {
                        self.validateWBIDVacation(jsonData: dicVactionFile) { success in
                            completion(success)
                        }
                    }
                } else {
                    print("Invalid ConfigInfo or YearMonth")
                    completion(false)
                }
            } else {
                print("Vacation file not found or invalid")
                self.downloadWbidVacation { success in
                    completion(success)
                }
            }
        } else {
            self.downloadWbidVacation { success in
                completion(success)
            }
        }
    }

    
    //    MARK: vacation File type = "WBIDF" and download
    func downloadWbidEOMVacationFilesWithHud(completion: @escaping (Bool) -> Void) {
        self.bidPeriod?.userVacationWbidOrCrewBid = "WBIDF"
        try? self.bidPeriod?.managedObjectContext?.save()
        let downloadedEomDate = getTheDateOfDownloadedEOM(self.bidPeriod!.wbFileIntentF ?? "")
        if (downloadedEomDate == self.bidPeriod?.faEomSelectedDate) && (self.bidPeriod!.wbFileIntentF != nil) {
                guard let dicVactionFile = self.readVacationFile(fileName: "WBIDF"),
                      let configInfo = dicVactionFile["ConfigInfo"] as? [String: Any],
                      let yearMonth = configInfo["YearMonth"] as? String else {
                    self.downloadWbidVacation { success in
                        completion(success)
                    }
                    return
                }
                
                let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
                
                if vacayMonth != self.bidPeriod?.month?.intValue {
                    let moc = self.bidPeriod?.managedObjectContext
                    self.bidPeriod?.wbFileIntentF = ""
                    
                    do {
                        try moc?.save()
                        print("file name saved")
                    } catch {
                        print("file name not saved")
                    }
                    
                    // Optionally: remove the vacation file from disk here
                    
                    self.downloadWbidVacation { success in
                        completion(success)
                    }
                } else {
                    if self.bidPeriod?.isWBidmaxOverlapWithEom() == true {
                        AlertService.showAlertForTopVC(title: "Crewbid Error", message: "Your current vacation conflicts with the EOM dates, so we cannot display any EOM vacation. We will display your current vacation only.")
                        NotificationCenter.default.post(name: Notification.Name("HandleEOMConflict"), object: self)
                        completion(false)
                    } else {
                        self.validateWBIDVacation(jsonData: dicVactionFile) { success in
                            completion(success)
                        }
                    }
                }
        } else {
            self.downloadWbidVacation { success in
                completion(success)
            }
        }
    }

    //    MARK: vacation File type = "FAVACATION" and download
    func downloadFaVacationFilesWithHud(completion: @escaping (Bool) -> Void) {
        self.bidPeriod?.userVacationWbidOrCrewBid = "FAVacation"
        try? self.bidPeriod?.managedObjectContext?.save()
        UserDefaults.standard.set(false, forKey: kCBHideVacationKey)

        if let fileIntent = self.bidPeriod?.faFileIntent, !fileIntent.isEmpty {
            guard let dicVacationFile = self.readVacationFile(fileName: fileIntent) else {
                self.downloadFAVacation() { success in
                    completion(success)
                }
                return
            }

            guard let configInfo = dicVacationFile["ConfigInfo"] as? [String: Any],
                  let yearMonth = configInfo["YearMonth"] as? String else {
                self.downloadFAVacation() { success in
                    completion(success)
                }
                return
            }

            let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
            let currentMonth = self.bidPeriod?.month?.intValue ?? 0

            if vacayMonth != currentMonth {
                self.bidPeriod?.faFileIntent = ""
                let moc = self.bidPeriod?.managedObjectContext
                do {
                    try moc?.save()
                    print("faFileIntent cleared and context saved")
                } catch {
                    print("Failed to save context after clearing faFileIntent: \(error)")
                }

                // Optionally remove old file here
                // self.deleteVacationFile(fileName: fileIntent)

                self.downloadFAVacation() { success in
                    completion(success)
                }
            } else {
                self.validateFAVacation(jsonData: dicVacationFile) { isValid in
                    completion(isValid)
                }
            }
        } else {
            self.downloadFAVacation() { success in
                completion(success)
            }
        }
        print("compleeted222")
    }

    
    //    MARK: vacation File type = "FAVACATIONF" and download
    func downloadFaVacationEOMFilesWithHud(completion: @escaping (Bool) -> Void) {
        self.bidPeriod?.userVacationWbidOrCrewBid = "FAVacationF"
        try? self.bidPeriod?.managedObjectContext?.save()
        UserDefaults.standard.set(false, forKey: kCBHideVacationKey)
        
        let fileNameKey = self.bidPeriod?.faFileIntentF
        let dicVactionFile = self.readVacationFile(fileName: fileNameKey)
        let file = dicVactionFile?["File"] as? [String: Any]
        let topLevel = file?["SWAPtimizer_CrewBid_Data"] as? [String: Any]
        let header = topLevel?["Header"] as? [String: Any]
        let fileName = header?["FileIdent"] as? String
    
        let downloadedEomDate = getTheDateOfDownloadedEOM(self.bidPeriod!.faFileIntent ?? "")
        if (fileName == self.bidPeriod?.faFileIntentF) && (self.bidPeriod?.faFileIntentF != nil) && ("\(downloadedEomDate)" == EOMSelectedIndex) {
            if EOMSelectedIndex != "" {
                _ = self.readVacationFile(fileName: self.setFaFileIntentFWithSelectedIndex(selectedIndex: EOMSelectedIndex)!)
            } else {
                _ = self.readVacationFile(fileName: self.bidPeriod?.faFileIntentF ?? "")
            }
            
            guard let configInfo = dicVactionFile?["ConfigInfo"] as? [String: Any],
                  let yearMonth = configInfo["YearMonth"] as? String else {
                completion(false)
                return
            }
            
            let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
            if vacayMonth != self.bidPeriod?.month?.intValue {
                let moc = self.bidPeriod?.managedObjectContext
                self.bidPeriod?.faFileIntentF = ""
                do {
                    try moc?.save()
                    print("file name saved")
                } catch {
                    print("file name not saved")
                }
                self.downloadFAVacation { success in
                    completion(success)
                }
            } else {
                self.validateFAVacation(jsonData: dicVactionFile!) { isValid in
                    completion(isValid)
                }
            }
        } else {
            self.downloadFAVacation { success in
                completion(success)
            }
        }
    }
    
    func getTheDateOfDownloadedEOM(_ wbFileIntentF: String) -> NSNumber {
        var dateInteger: NSNumber = 0

        if !wbFileIntentF.isEmpty {
            let lastChar = wbFileIntentF.last!
            if lastChar.isWholeNumber, let lastDigit = Int(String(lastChar)) {
                dateInteger = NSNumber(value: lastDigit)
            }
        }

        return dateInteger
    }


    
    //    MARK: vacation File type = "FAVACATION_EOMOnly" and download
    func downloadFaVacationWithOnlyEOMFilesWithHud(completion: @escaping (Bool) -> Void) {
        self.bidPeriod?.userVacationWbidOrCrewBid = "FAVacationEomOnly"
        do {
            try? self.bidPeriod?.managedObjectContext?.save()
        }
        catch {
            print("error saving \(error.localizedDescription)")
        }
        UserDefaults.standard.set(false, forKey: kCBHideVacationKey)
        
        let fileNameKey = self.bidPeriod?.faFileIntentEomOnly
        let dicVactionFile = self.readVacationFile(fileName: fileNameKey)
        let file = dicVactionFile?["File"] as? [String: Any]
        let topLevel = file?["SWAPtimizer_CrewBid_Data"] as? [String: Any]
        let header = topLevel?["Header"] as? [String: Any]
        let fileIdent = header?["FileIdent"] as? String ?? ""
        
        
        if fileIdent == self.bidPeriod?.faFileIntentF {
            if EOMSelectedIndex != "" {
                _ = self.readVacationFile(fileName: self.setFaFileIntentEomOnlyWithSelectedIndex(selectedIndex: EOMSelectedIndex)!)
            } else if let intentEomOnly = self.bidPeriod?.faFileIntentEomOnly {
                _ = self.readVacationFile(fileName: intentEomOnly)
            }
            
            let configInfo = dicVactionFile?["ConfigInfo"] as? [String: Any]
            let yearMonth = configInfo?["YearMonth"] as? String
            
            let vacayMonth = Int((yearMonth?.dropFirst(4).prefix(2))!) ?? 0
            if vacayMonth != self.bidPeriod?.month?.intValue {
                let moc = self.bidPeriod?.managedObjectContext
                self.bidPeriod?.faFileIntentF = ""
                do {
                    try moc?.save()
                    print("file name saved")
                } catch {
                    print("file name not saved")
                }
                // Remove outdated vacation file and redownload
                self.downloadFAVacation { success in
                    completion(success)
                }
            } else {
                self.validateFAVacation(jsonData: dicVactionFile!) { isValid in
                    completion(isValid)
                }
            }
        } else {
            self.downloadFAVacation { success in
                completion(success)
            }
        }
    }

    
    func setFaFileIntentFWithSelectedIndex(selectedIndex: String) -> String? {
        guard let lastFaFileIntentF = self.bidPeriod!.faFileIntentF, !lastFaFileIntentF.isEmpty else {
            return nil
        }

        let index = lastFaFileIntentF.index(before: lastFaFileIntentF.endIndex)
        var newFaFileIntentF = lastFaFileIntentF
        newFaFileIntentF.replaceSubrange(index...index, with: selectedIndex)
        return newFaFileIntentF
    }
    
    func setFaFileIntentEomOnlyWithSelectedIndex(selectedIndex: String) -> String? {
        guard let lastFaFileIntentEomOnly = self.bidPeriod?.faFileIntentEomOnly,
              !lastFaFileIntentEomOnly.isEmpty else {
            return nil
        }
        
        let index = lastFaFileIntentEomOnly.index(before: lastFaFileIntentEomOnly.endIndex)
        var newFaFileIntentEomOnly = lastFaFileIntentEomOnly
        newFaFileIntentEomOnly.replaceSubrange(index...index, with: selectedIndex)
        
        return newFaFileIntentEomOnly
    }


    
    //MARK: download WBID VacationFiles
    func downloadWbidVacation(completion: @escaping (Bool) -> Void) {
        let delayInSeconds = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            var vacationDetailDictionary: [String: Any] = [:]
            
            if self.bidPeriod?.swaptimizerIdentifier == nil {
                vacationDetailDictionary["EmpNum"] = self.bidPeriod?.crewIdentifier ?? 0
            } else {
                vacationDetailDictionary["EmpNum"] = self.bidPeriod?.swaptimizerIdentifier ?? 0
            }
            
            vacationDetailDictionary["Base"] = self.bidPeriod?.base ?? "ATL"
            
            if let rawValue = self.bidPeriod?.positionType?.intValue,
               let positionType = BICrewPositionType(rawValue: rawValue) {
                let shortName = CBUtils.shortName(for: positionType)
                vacationDetailDictionary["Position"] = shortName
            }

            // Override with hardcoded CP (matches original code logic)
            vacationDetailDictionary["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: (self.bidPeriod?.positionType?.intValue)!)!)
            
            vacationDetailDictionary["Year"] = self.bidPeriod?.year ?? 2025
            vacationDetailDictionary["Month"] = self.bidPeriod?.month ?? 7
            vacationDetailDictionary["FromApp"] = 5
            
            if self.bidPeriod?.round?.intValue == 1 {
                vacationDetailDictionary["Round"] = "M"
            } else {
                vacationDetailDictionary["Round"] = "S"
            }

            let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "WBID"
            
            if vacationType == "WBID" {
                vacationDetailDictionary["IsEOM"] = NSNumber(value: false)
            } else {
                vacationDetailDictionary["IsEOM"] = NSNumber(value: true)
                vacationDetailDictionary["FAEOMStartDate"] = self.bidPeriod?.faEomSelectedDate
            }
            
            if self.bidPeriod?.secretSwitchOn == "YES" {
                vacationDetailDictionary["EmpNum"] = self.bidPeriod?.crewIdentifier
                
                if self.bidPeriod?.selectedSegmentVacType == "TestOtherWeeks" {
                    if let vacationName = self.bidPeriod?.vacationName, !(vacationName is NSNull) {
                        if vacationType == "WBID" {
                            var newString: String = ""
                            if vacationName.hasSuffix("F") {
                                newString = String(vacationName.dropLast())
                            } else {
                                newString = vacationName
                            }
                            vacationDetailDictionary["FileName"] = newString
                        }
                    }
                    self.vactionDownloadType = .downloadWbidVacation
                    // Simulate success path for secret/TestOtherWeeks for now
                    completion(true)
                    return
                } else {
                    self.vactionDownloadType = .downloadWbidVacation
                    // Secret mode without TestOtherWeeks — Not calling completion currently (needs implementation)
                    self.downloadWBidOrFAData(downloadWbidDetails: vacationDetailDictionary) { canDownload in
                        if (canDownload) {
                            completion(true)
                            return
                        }
                        else {
                            completion(false)
                            return
                        }
                    }
                    
                }
            } else {
                self.vactionDownloadType = .downloadWbidVacation
                self.downloadWBidOrFAData(downloadWbidDetails: vacationDetailDictionary) { canDownload in
                    if !canDownload {
                        if self.bidPeriod?.userVacationWbidOrCrewBid == "WBIDF" {
                            print("Network issue in WBIDF download")
                        }
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }

    
    //    MARK: FA VAcationFile
    func downloadFAVacation(completion: @escaping (Bool) -> Void) {
        let delayInSeconds = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            var vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "FAVacation"
            var vacationDetailDictionary: [String: Any] = [:]

            vacationDetailDictionary["EmpNum"] = self.bidPeriod?.crewIdentifier ?? 0
            vacationDetailDictionary["Base"] = self.bidPeriod?.base ?? "DEN"
            if let rawValue = self.bidPeriod?.positionType?.intValue,
               let positionType = BICrewPositionType(rawValue: rawValue) {
                let shortName = CBUtils.shortName(for: positionType)
                vacationDetailDictionary["Position"] = shortName
            } else {
                vacationDetailDictionary["Position"] = "FA"
            }
            vacationDetailDictionary["Year"] = self.bidPeriod?.year ?? 2025
            vacationDetailDictionary["Month"] = self.bidPeriod?.month ?? 7
            vacationDetailDictionary["FromApp"] = 5

            var round: String = ""
            if self.bidPeriod?.round?.intValue == 1 {
                round = "M"
            } else if self.bidPeriod?.round?.intValue == 2 {
                round = "S"
            }
            vacationDetailDictionary["Round"] = round

            if vacationType == "FAVacation" {
                vacationDetailDictionary["IsEOM"] = NSNumber(value: false)
            } else {
                vacationDetailDictionary["IsEOM"] = NSNumber(value: true)
                vacationDetailDictionary["FAEOMStartDate"] = self.bidPeriod?.faEomSelectedDate
            }

            self.vactionDownloadType = .downloadFAVacation
            self.downloadWBidOrFAData(downloadWbidDetails: vacationDetailDictionary) { canDownload in
                if !canDownload {
                    print("network issue")
                }
                completion(canDownload)
            }
        }
    }

    
    //    MARK: downloadWBid OR FA Data
    func downloadWBidOrFAData(downloadWbidDetails: [String: Any], canDownloadVacation: @escaping (Bool) -> Void) {
        do {
            let data = try JSONSerialization.data(withJSONObject: downloadWbidDetails, options: [])
            guard let jsonString = String(data: data, encoding: .utf8) else {
                print("Failed to convert data to JSON string")
                canDownloadVacation(false)
                return
            }
            let urlString = EndPoint.shared.getCrewBidJsonVacFile
            if !urlString.isEmpty {
                print("Internet is available")
                
                self.postDataForVacationDownloading(urlName: urlString, jsonString: jsonString) { success in
                    if success {
                        print("Vacation data validated/downloaded successfully.")
                        canDownloadVacation(true)
                    } else {
                        print("Vacation data failed to validate/download.")
                        canDownloadVacation(false)
                    }
                }
            }
            else {
                print("Internet is not available")
                canDownloadVacation(false)
            }
        }
        catch {
            print("WBID JSON Serilisaton Error")
        }
    }
    
//    func constructURLString(urlString: String) -> String {
//        guard let domain = app.Domain else {
//            print("Error: Domain is nil")
//            return ""
//        }
//        let webData = app.webData
//        let serviceURL = "\(domain)\(urlString)"
//        let finalURLString = serviceURL.replacingOccurrences(of: " ", with: "%20")
//        print(finalURLString)
//        return finalURLString
//    }
    
//    func postDataForVacationDownloading(urlName: String, jsonString: String, completion: @escaping (Bool) -> Void) {
//        print("in post section")
//        print(jsonString)
//        
//        guard let url = URL(string: urlName) else {
//            print("Invalid URL")
//            completion(false)
//            return
//        }
//
//        
//        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeoutVD)
//        request.httpMethod = "POST"
//        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        request.httpBody = jsonString.data(using: .utf8)
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("WBID OR FA DOWNLOAD FAILED")
//                print("Request failed: \(error)")
//                DispatchQueue.main.async {
//                    completion(false)
//                }
//                return
//            }
//            
//            guard let data = data else {
//                print("No data received")
//                DispatchQueue.main.async {
//                    completion(false)
//                }
//                return
//            }
//            
//            if let responseString = String(data: data, encoding: .utf8) {
////                print("Mutable Response String: \(responseString)")
//                do {
//                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                        if let fileName = json["FileName"], !(fileName is NSNull),
//                           let jsonData = json["JsonData"] as? [String: Any] {
//                            
//                            if self.vactionDownloadType == .downloadWbidVacation {
//                                print("able to download wbid vacation from api")
//                                self.callToSetAutoDownloadOrValidateForWBID(jsonData: jsonData) { success in
//                                    DispatchQueue.main.async {
//                                        completion(success)
//                                    }
//                                }
//                            } else if self.vactionDownloadType == .downloadFAVacation {
//                                print("able to download fa vacation data from api")
//                                self.callToSetAutoDownloadOrValidateForFA(jsonData: jsonData) { success in
//                                    DispatchQueue.main.async {
//                                        completion(success)
//                                    }
//                                }
//                            } else {
//                                print("Unknown vacation download type")
//                                DispatchQueue.main.async {
//                                    completion(false)
//                                }
//                            }
//                            return
//                        } else {
//                            print("FileName is null or missing")
//                            if let message = json["Message"] as? String,
//                               message.lowercased().hasPrefix("it takes us about") {
//                                AlertService.showAlertForTopVC(title: "EOM Vacation", message: "You do not have Vacation this month.  If you have vacation starting in the 1st 3 days of \(self.eomMonth()), then touch the EOM button.")
//                            }
//                            DispatchQueue.main.async {
//                                completion(false)
//                            }
//                            return
//                        }
//                    }
//                } catch {
//                    print("JSON parsing error: \(error)")
//                    DispatchQueue.main.async {
//                        completion(false)
//                    }
//                    return
//                }
//            } else {
//                print("Received binary mutable data of size: \(data.count) bytes")
//                DispatchQueue.main.async {
//                    completion(false)
//                }
//            }
//        }
//        
//        task.resume()
//    }
    
    func postDataForVacationDownloading(urlName: String, jsonString: String, completion: @escaping (Bool) -> Void) {
//        print("in post section")
//        print(jsonString)
        
        guard let bodyData = jsonString.data(using: .utf8) else {
            print("Invalid JSON string encoding")
            completion(false)
            return
        }
        
        APIService.shared.fetch(
            urlString: urlName,
            method: .POST,
            body: bodyData,
            headers: [
                "Content-Type": "application/x-www-form-urlencoded"
            ],
            parse: { data in
                // Try parsing JSON
                try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
            },
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let json):
                        if let fileName = json["FileName"], !(fileName is NSNull),
                           let jsonData = json["JsonData"] as? [String: Any] {
                            
                            self.bidPeriod?.seniorityVacayAvailable = NSNumber(booleanLiteral: true)
                            if self.vactionDownloadType == .downloadWbidVacation {
                                print("able to download wbid vacation from api")
                                self.callToSetAutoDownloadOrValidateForWBID(jsonData: jsonData) { success in
                                    completion(success)
                                }
                            } else if self.vactionDownloadType == .downloadFAVacation {
                                print("able to download fa vacation data from api")
                                self.callToSetAutoDownloadOrValidateForFA(jsonData: jsonData) { success in
                                    completion(success)
                                }
                            } else {
                                print("Unknown vacation download type")
                                completion(false)
                            }
                            
                        } else {
                            //                            print("FileName is null or missing")
                            self.bidPeriod?.seniorityVacayAvailable = NSNumber(booleanLiteral: false)
                            let message = json["Message"] as? String ?? ""
                            var messageContent = message
                            if self.vactionDownloadType == .downloadWbidVacation {
                                if message.lowercased().hasPrefix("it takes us about") {
                                    if(self.bidPeriod!.containsVacay?.boolValue != true) {
                                        messageContent = "You do not have Vacation this month.  If you have vacation starting in the 1st 3 days of \(self.eomMonth()), then touch the EOM button"
                                    }
                                }
                                else {
                                    if self.bidPeriod?.isFABid() == true {
                                        messageContent = "It takes us about 4 hours to create the vacation files when the bid data is released.  If you have vacation,and the bid data was just release, come back later and touch the WBidMax or Swaptimizer button if a pilot."
                                        if self.bidPeriod?.containsVacay?.boolValue != true {
                                            messageContent = "You do not have Vacation this month.  If you have vacation starting in the 1st 3 days of \(self.eomMonth()), then touch the EOM button"
                                        }
                                    }
                                    else {
                                        messageContent = "It takes us about 12 hours to create the vacation files when the bid data is released.  If you have vacation,and the bid data was just release, come back later and touch the WBidMax or Swaptimizer button if a pilot."
                                        if self.bidPeriod?.containsVacay?.boolValue != true {
                                            messageContent = "You do not have Vacation this month.  If you have vacation starting in the 1st 3 days of \(self.eomMonth()), then touch the EOM button"
                                        }
                                    }
                                    
                                }
                                if !messageContent.lowercased().hasPrefix("it takes us about") || !messageContent.lowercased().hasPrefix("You do not have Vacation this month") {
                                    AlertService.showAlertForTopVC(title: "WBidMax Error", message: messageContent, actions: [(
                                        title: "OK",
                                        style: .default,
                                        handler: { _ in
                                            self.bidPeriod?.userVacationWbidOrCrewBid = ""
                                            self.bidPeriod?.vacationType = ""
                                            self.deleteAllVacation()
                                            //                                        NotificationCenter.default.post(name: NSNotification.Name("TapWBidMaxBtn"), object: self)
                                        }
                                    )])
                                }
                                else {
                                    AlertService.showAlertForTopVC(title: "WBidMax Error", message: messageContent, actions: [(
                                        title: "OK",
                                        style: .default,
                                        handler: { _ in
                                            self.bidPeriod?.userVacationWbidOrCrewBid = ""
                                            self.bidPeriod?.vacationType = ""
                                            self.deleteAllVacation()
                                        }
                                    )])
                                }
                                completion(false)
                            }
                            else if self.vactionDownloadType == .downloadFAVacation {
                                if message.lowercased().hasPrefix("it takes us about") && (self.bidPeriod!.containsVacay?.boolValue != true) {
                                    messageContent = "It takes us about 4 hours to create the vacation files when the bid data is released. If you have vacation,and the bid data was just released, come back later and touch the VAC button if a Flight Attendant."
                                }
                                if !messageContent.lowercased().hasPrefix("it takes us about") || !messageContent.lowercased().hasPrefix("You do not have Vacation this month") {
                                    AlertService.showAlertForTopVC(title: "Crewbid Alert", message: messageContent, actions: [(
                                        title: "OK",
                                        style: .default,
                                        handler: { _ in
                                            self.bidPeriod?.userVacationWbidOrCrewBid = ""
                                            self.bidPeriod?.vacationType = ""
                                            self.deleteAllVacation()
                                            //                                        NotificationCenter.default.post(name: NSNotification.Name("TapWBidMaxBtn"), object: self)
                                        }
                                    )])
                                }
                                else {
                                    AlertService.showAlertForTopVC(title: "Crewbid Alert", message: messageContent, actions: [(
                                        title: "OK",
                                        style: .default,
                                        handler: { _ in
                                            self.bidPeriod?.userVacationWbidOrCrewBid = ""
                                            self.bidPeriod?.vacationType = ""
                                            self.deleteAllVacation()
                                        }
                                    )])
                                }
                                completion(false)
                            }
                        }
                        
                    case .failure(let error):
                        print("WBID OR FA DOWNLOAD FAILED with error: \(error)")
                        completion(false)
                    }
                }
            }
        )
    }

    
    //    MARK: download crewbid Vacation file
//    func downloadCrewbidVacationFiles(crewbidType: String, completion: @escaping (Bool) -> Void) {
//        self.bidPeriod?.userVacationWbidOrCrewBid = crewbidType
//        let secretEnabled = self.bidPeriod?.secretSwitchOn ?? "NO"
//        var pilot: NSNumber?
//        var isEom = 1
//
//        if secretEnabled == "YES" {
//            pilot = self.bidPeriod?.crewIdentifier ?? 0
//            self.urlRequest = URLRequest(url: kSwaptimizerUrlTest, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeout)
//        } else {
//            pilot = self.bidPeriod?.swaptimizerIdentifier ?? 0
//            self.urlRequest = URLRequest(url: kSwaptimizerUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeout)
//        }
//
//        guard let pilotNumber = pilot else {
//            print("not a valid pilot")
//            completion(false)
//            return
//        }
//
//        let accessKey = kswaptimizerAccessKey
//        let appVersion = CBUtils.AppVersion()
//        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid
//        isEom = (vacationType == "CREWBIDF") ? 1 : 0
//
//        let postDict: [String: Any] = ["Pilot": pilotNumber, "CrewBidVersion": appVersion, "AccessKey": accessKey, "FWeek": isEom]
//
//        self.urlRequest?.httpMethod = "POST"
//        self.urlRequest?.setValue("text/plain", forHTTPHeaderField: "Accept")
//        self.urlRequest?.setValue("text/plain", forHTTPHeaderField: "Content-Type")
//
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: postDict, options: [])
//            self.urlRequest?.setValue("\(jsonData.count)", forHTTPHeaderField: "Content-Length")
//            self.urlRequest?.httpBody = jsonData
//        } catch {
//            print("Error serializing JSON: \(error)")
//            completion(false)
//            return
//        }
//
//        let task = URLSession.shared.dataTask(with: self.urlRequest!) { data, response, error in
//            if let error = error {
//                print("WBID OR FA DOWNLOAD FAILED")
//                print("Request failed: \(error)")
//                DispatchQueue.main.async {
//                    completion(false)
//                }
//                return
//            }
//
//            guard let data = data else {
//                print("No data received")
//                DispatchQueue.main.async {
//                    completion(false)
//                }
//                return
//            }
//
//            if let responseString = String(data: data, encoding: .utf8) {
////                print("Mutable Response String: \(responseString)")
//            }
//
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                   let pilotInfo = json["PilotInfo"] as? [String: Any],
//                   pilotInfo["HasAccount"] as? Int == 1 {
//                    
//                    print("Able to download crewbid vacation from API")
//                    self.callToSetAutoDownloadOrValidateForSwaptimizer(jsonData: json) { success in
//                        DispatchQueue.main.async {
//                            completion(success)
//                        }
//                    }
//                } else {
//                    print("No swaptimizer account")
//                    DispatchQueue.main.async {
//                        completion(false)
//                    }
//                }
//            } catch {
//                print("Error finding has account while parsing")
//                DispatchQueue.main.async {
//                    completion(false)
//                }
//            }
//        }
//        task.resume()
//    }
    
    func downloadCrewbidVacationFiles(crewbidType: String, completion: @escaping (Bool) -> Void) {
        self.bidPeriod?.userVacationWbidOrCrewBid = crewbidType
        let secretEnabled = self.bidPeriod?.secretSwitchOn ?? "NO"
        var pilot: NSNumber?
        var isEom = 1
        
        // Select pilot number and base URL
        if secretEnabled == "YES" {
            pilot = self.bidPeriod?.crewIdentifier ?? 0
        } else {
            pilot = self.bidPeriod?.swaptimizerIdentifier ?? 0
        }
        
        guard let pilotNumber = pilot else {
            print("not a valid pilot")
            completion(false)
            return
        }
        
        let baseUrl = (secretEnabled == "YES") ? kSwaptimizerUrlTest : kSwaptimizerUrl
        let accessKey = kswaptimizerAccessKey
        let appVersion = CBUtils.AppVersion()
        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid
        isEom = (vacationType == "CREWBIDF") ? 1 : 0
        
        let postDict: [String: Any] = [
            "Pilot": pilotNumber,
            "CrewBidVersion": appVersion,
            "AccessKey": accessKey,
            "FWeek": isEom
        ]
        
        // Serialize JSON body
        guard let jsonData = try? JSONSerialization.data(withJSONObject: postDict, options: []) else {
            print("Error serializing JSON")
            completion(false)
            return
        }
        
        // Use APIService.shared.fetch
        APIService.shared.fetch(
            urlString: baseUrl.absoluteString,
            method: .POST,
            body: jsonData,
            headers: [
                "Accept": "text/plain",
                "Content-Type": "text/plain",
                "Content-Length": "\(jsonData.count)"
            ],
            parse: { data in
                // Parse into JSON dictionary
                try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
            },
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let json):
                        //MARK: need to handle the alerts if there is no account
                        if let pilotInfo = json["PilotInfo"] as? [String: Any],
                           pilotInfo["HasAccount"] as? Int == 1 {
                            print("Able to download crewbid vacation from API")
                            self.callToSetAutoDownloadOrValidateForSwaptimizer(jsonData: json) { success in
                                completion(success)
                            }
                        } else {
                            print("No swaptimizer account")
                            completion(false)
                        }
                        
                    case .failure(let error):
                        print("WBID OR FA DOWNLOAD FAILED with error: \(error)")
                        completion(false)
                    }
                }
            }
        )
    }

    
    //    MARK: callToSetAutoDownloadOrValidateForWBID()
    func callToSetAutoDownloadOrValidateForWBID(jsonData: [String: Any], completion: @escaping (Bool) -> Void) {
        if isAutoDownload {
            storeWBIDVacation(jsonData: jsonData)
            completion(true) // Assume success after storing
        } else {
            validateWBIDVacation(jsonData: jsonData) { _ in
                completion(true)
            }
        }
    }

    
    //    MARK: callToSetAutoDownloadOrValidateFor FA vacation()
    func callToSetAutoDownloadOrValidateForFA(jsonData: [String: Any], completion: @escaping (Bool) -> Void) {
        if isAutoDownload {
            storeFAVacation(jsonData: jsonData)
            completion(true)
        } else {
            validateFAVacation(jsonData: jsonData) { success in
                completion(success)
            }
        }
    }

    
    //    MARK: callToSetAutoDownloadOrValidateFor swaptimizet()
    func callToSetAutoDownloadOrValidateForSwaptimizer(jsonData: [String: Any], completion: @escaping (Bool) -> Void) {
        if isAutoDownload {
            AutoValidateSWAPtimizerJSON(jsonData: jsonData) { success in
                completion(success)
            }
        } else {
            validateSWAPtimizerJSON(jsonData: jsonData) { success in
                completion(success)
            }
        }
    }

    
    //    MARK: storeWBIDVacation()
    func storeWBIDVacation(jsonData: [String: Any]) {
        let file = jsonData["File"] as! [String: Any]
        let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
        let header = topLevel["Header"] as! [String: Any]
        let moc = self.bidPeriod?.managedObjectContext
        self.bidPeriod?.faFileIntent = header["FileIdent"] as? String
        if moc!.hasChanges {
            do {
                try moc?.save()
                print("filename saved")
            } catch {
                print("Error saving context: \(error)")
            }
        }
        
        writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
        let isFlightAttendant = self.bidPeriod?.isFABid() ?? false
        if(!isFlightAttendant) {
            self.downloadCrewbidVacationFiles(crewbidType: "CREWBID", completion: { _ in })
        }
        
    }
    
    //    MARK: validateWBIDVacation
    func validateWBIDVacation(jsonData: [String: Any], completion: @escaping (Bool) -> Void) {
        guard
            let status = jsonData["Status"] as? [String: Any],
            let pilotInfo = jsonData["PilotInfo"] as? [String: Any],
            let configInfo = jsonData["ConfigInfo"] as? [String: Any],
            let statusCode = status["Code"] as? String,
            let statusMsg = status["Msg"] as? String
        else {
            completion(false)
            return
        }

        let hasAccount = (pilotInfo["HasAccount"] as? String == "1")
        let dataAvailable = (pilotInfo["DataAvailable"] as? NSNumber)?.boolValue ?? false
        let hasVacation = (pilotInfo["HasVacation"] as? NSNumber)?.boolValue ?? false
        let pilotIdentifier = Int(pilotInfo["Pilot"] as? String ?? "") ?? 0

        let yearMonth = configInfo["YearMonth"] as? String ?? ""
        let vacayYear = Int(yearMonth.prefix(4)) ?? 0
        let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
        let secretEnabled = self.bidPeriod?.secretSwitchOn

        guard self.bidPeriod?.month != nil, self.bidPeriod?.year != nil else {
            completion(false)
            return
        }

        if statusCode != "SUCCESS" {
            AlertService.showAlertForTopVC(title: "WBidmax Server Error", message: "\(statusMsg)\nWBidmax vacation usually releases data the evening of the 4th or morning of the 5th. If you are seeing this error before data release, please try again after data has been released.", actions: nil)
            completion(false)
        } else if pilotIdentifier != Int(truncating: self.bidPeriod?.crewIdentifier ?? 0) && secretEnabled != "YES" {
            AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax user ID \(pilotIdentifier) does not match the pilot for whom the bid package was downloaded \(String(describing: self.bidPeriod?.swaptimizerIdentifier)).", actions: nil)
            completion(false)
        } else if (self.bidPeriod?.month?.intValue ?? 0) - vacayMonth == 1 || (self.bidPeriod?.month?.intValue == 1 && vacayMonth == 12) {
            AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).", actions: nil)
            completion(false)
        } else if !hasVacation {
            let user = secretEnabled == "YES"
                ? UserDefaults.standard.string(forKey: "SecretVDuserName") ?? ""
                : String(describing: self.bidPeriod?.swaptimizerIdentifier)
            AlertService.showAlertForTopVC(title: "No Vacation", message: "No vacation next month for user \(user)", actions: nil)
            completion(false)
        } else if hasVacation && !hasAccount {
            AlertService.showAlertForTopVC(title: "No MAX Subscription!", message: "We see that you have vacation this month, but you do not have a Max subscription.\nA Max subscription will give you access to the highly acclaimed WBidMax vacation predictions.\nTo get a Max subscription, go to www.crewbidmax.com and get a Max subscription.")
            completion(false)
        } else if hasVacation && hasAccount && !dataAvailable {
            AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
            completion(false)
        } else if hasVacation && hasAccount && dataAvailable {
            let seat = pilotInfo["Seat"] as? String ?? ""
            let round = Int(configInfo["Round"] as? String ?? "") ?? 0
            let vacayBase = pilotInfo["Base"] as? String ?? ""
            let rawValue = self.bidPeriod?.positionType?.intValue ?? 0
            let positionType = BICrewPositionType(rawValue: rawValue)!
            let shortName = CBUtils.shortName(for: positionType) ?? "CM"

            if secretEnabled != "YES" {
                if vacayMonth != self.bidPeriod?.month?.intValue {
                    AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax data month \(vacayMonth) is not the same as the bid period month \(String(describing: self.bidPeriod?.month))")
                    completion(false)
                    return
                }
                if vacayYear != self.bidPeriod?.year?.intValue {
                    AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax data year \(vacayYear) is not the same as the bid period year \(String(describing: self.bidPeriod?.year))")
                    completion(false)
                    return
                }
                if vacayBase != self.bidPeriod?.base {
                    AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax data base \(vacayBase) is not the same as the bid period crew base \(String(describing: self.bidPeriod?.base))")
                    completion(false)
                    return
                }
                if shortName != seat {
                    AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The vacation data position \(seat) is not the same as the bid period position \(shortName).")
                    completion(false)
                    return
                }
                if self.bidPeriod?.round?.intValue == 2 && round == 1 {
                    AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
                    completion(false)
                    return
                }
                if round != self.bidPeriod?.round?.intValue {
                    AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The vacation data round \(round) is not the same as the bid period round \(String(describing: self.bidPeriod?.round))")
                    completion(false)
                    return
                }

                // ✅ Process valid file
                if let file = jsonData["File"] as? [String: Any],
                   let topLevel = file["SWAPtimizer_CrewBid_Data"] as? [String: Any],
                   let header = topLevel["Header"] as? [String: Any],
                   let fileRound = header["Round"] as? Int,
                   let fileYear = header["BidPeriodYear"] as? Int,
                   let fileMonth = header["BidPeriodMonth"] as? Int {

                    if fileRound != round || fileYear != vacayYear || fileMonth != vacayMonth {
                        AlertService.showAlertForTopVC(title: "WBidmax File Mismatch", message: "The vacation round/year/month and WBidmax data file do not match. Perhaps you didn't bid a blank line?")
                        completion(false)
                        return
                    }

                    let moc = self.bidPeriod?.managedObjectContext
                    let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "WBID"
                    if vacationType == "WBID" {
                        self.bidPeriod?.wbFileIntent = header["FileIdent"] as? String
                    } else {
                        self.bidPeriod?.wbFileIntentF = header["FileIdent"] as? String
                    }

                    if moc?.hasChanges == true {
                        do {
                            try moc?.save()
                            print("context saved during validate wbid")
                        } catch {
                            print("context not saved: \(error)")
                        }
                    }

                    self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)

                    if self.isAutoDownload {
                        self.downloadCrewbidVacationFiles(crewbidType: "CREWBID") {_ in 
                            completion(true)
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.processJsonFile(file: file)
                            completion(true)
                        }
                    }

                } else {
                    completion(false)
                }
            } else {
                // ✅ Secret vacation path
                if let file = jsonData["File"] as? [String: Any],
                   let topLevel = file["SWAPtimizer_CrewBid_Data"] as? [String: Any],
                   let header = topLevel["Header"] as? [String: Any] {

                    let moc = self.bidPeriod?.managedObjectContext
                    let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "WBID"
                    if vacationType == "WBID" {
                        self.bidPeriod?.wbFileIntent = header["FileIdent"] as? String
                    } else {
                        self.bidPeriod?.wbFileIntentF = header["FileIdent"] as? String
                    }
                    if moc?.hasChanges == true {
                        do {
                            try moc?.save()
                            print(" saved from validate wbid")
                        } catch {
                            print("secret context save error: \(error)")
                        }
                    }

                    self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
                    self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.checked.rawValue as NSNumber

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.processJsonFile(file: file)
                        completion(true)
                    }

//                    if moc?.hasChanges == false {
//                        do {
//                            try moc?.save()
//                            print("secret context saved")
//                        } catch {
//                            print("secret context save error: \(error)")
//                        }
//                    }
                } else {
                    completion(false)
                }
            }
        }
    }

    
    func writeVacationFile(jsonData: [String: Any], fileName: String) {
        let moc = self.bidPeriod?.managedObjectContext
        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "WBID"
        if vacationType == "WBID" {
            self.bidPeriod?.wbVacationfile = jsonData as NSDictionary
        }
        else if vacationType == "WBIDF" {
            self.bidPeriod?.wbVacationfileF = jsonData as NSDictionary
        }
        else if vacationType == "CREWBIDF" {
            self.bidPeriod?.cbVacationFilesF = jsonData as NSDictionary
        }
        else if vacationType == "FAVacation" {
            self.bidPeriod?.faVacationFiles = jsonData as NSDictionary
        }
        else if vacationType == "FAVacationF" {
            let eomIndexF = fileName.suffix(1)
            if eomIndexF == "1" {
                self.bidPeriod?.faVacationFilesFA1 = jsonData as NSDictionary
            } else if eomIndexF == "2" {
                self.bidPeriod?.faVacationFilesFA2 = jsonData as NSDictionary
            } else if eomIndexF == "3" {
                self.bidPeriod?.faVacationFilesFA3 = jsonData as NSDictionary
            }
        }
        else if vacationType == "FAVacationEomOnly" {
            let eomIndexF = fileName.suffix(1)
            if eomIndexF == "1" {
                self.bidPeriod?.faVacationFilesEomOnlyFA1 = jsonData as NSDictionary
            } else if eomIndexF == "2" {
                self.bidPeriod?.faVacationFilesEomOnlyFA2 = jsonData as NSDictionary
            } else if eomIndexF == "3" {
                self.bidPeriod?.faVacationFilesEomOnlyFA3 = jsonData as NSDictionary
            } else if eomIndexF == "4" {
                self.bidPeriod?.faVacationFilesEomOnlyFA4 = jsonData as NSDictionary
            } else if eomIndexF == "5" {
                self.bidPeriod?.faVacationFilesEomOnlyFA5 = jsonData as NSDictionary
            } else if eomIndexF == "6" {
                self.bidPeriod?.faVacationFilesEomOnlyFA6 = jsonData as NSDictionary
            } else if eomIndexF == "7" {
                self.bidPeriod?.faVacationFilesEomOnlyFA7 = jsonData as NSDictionary
            }
        }
        else {
            self.bidPeriod?.cbVacationFiles = jsonData as NSDictionary
        }
        if moc!.hasChanges {
            do {
                try moc?.save()
                print("context writevacationfile saved")
            }
            catch {
                print("context writevacationfile not saved: \(error)")
            }
        }
        let isFlightAttendant = self.bidPeriod?.isFABid() ?? false
        if(!isFlightAttendant) {
            vacationPayDiffrence(jsonData: jsonData)
        } else {
            vacationPayDiffrenceFA(jsonData: jsonData)
        }
    }
    
    //    MARK: vaccation pay diffrence
    func vacationPayDiffrence(jsonData: [String: Any]) {
        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "WBID"
        var totalVacationPay = ""
        var lineName = ""
        
        if vacationType == "WBID" || vacationType == "WBIDF" || vacationType == "FAVacation" || vacationType == "FAVacationF" {
            totalVacationPay = "TotalVacationPay"
            lineName = "Line1"
        } else {
            totalVacationPay = "Total Vacation Pay"
            lineName = "Line#"
        }
        
        let lines = self.bidPeriod?.lines?.allObjects as? [AnyObject] ?? []
        var sortedLines = (lines as NSArray).sortedArray(using: [
            NSSortDescriptor(key: "number", ascending: true)
        ])
        let notBlankPredicate = NSPredicate(format: "type != %d", BILineType.BlankLine.rawValue)
        sortedLines = (sortedLines as NSArray).filtered(using: notBlankPredicate)
        let file = jsonData["File"] as! [String: Any]
        let toplevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
        let vacayLines = toplevel["Lines"] as! [[String: Any]]
        
        if(sortedLines.count == vacayLines.count) {
            var vEnumerator = vacayLines.makeIterator()
            for line in sortedLines as! [BILine] {
                let vLine = vEnumerator.next()
                let vLineNumber = (vLine?[lineName] as? Int) ?? (vLine?[lineName] as? NSNumber)?.intValue ?? 0
                if(vLineNumber == line.number?.intValue) {
                    let lineData = vLine?["LineData"] as! [String: Any]
                    if vacationType == "WBID" {
                        line.vWBVacPay =  NSNumber(value: (lineData[totalVacationPay] as? NSNumber)?.floatValue ?? 0.0)
                    }
                    else {
                        line.vCBVacPay = lineData[totalVacationPay] as? NSNumber
                    }
                }
            }
            DispatchQueue.main.async {
                if let context = self.bidPeriod?.managedObjectContext {
                    do {
                        try context.save()
                        print("saved from vacation pay diffrence")
                    } catch {
                        print("Failed to save context: \(error)")
                    }
                }
            }
        }
    }
    
    func vacationPayDiffrenceFA(jsonData: [String: Any]) {
        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "FAVacation"
        var totalVacationPay = ""
        var lineName = ""
        
        if vacationType == "FAVacation" || vacationType == "FAVacationF" || vacationType == "FAVacationEomOnly" {
            totalVacationPay = "TotalVacationPay"
            lineName = "Line1"
        }
        
        let lines = self.bidPeriod?.lines?.allObjects as? [AnyObject] ?? []
        var sortedLines = (lines as NSArray).sortedArray(using: [
            NSSortDescriptor(key: "number", ascending: true)
        ])
        let notBlankPredicate = NSPredicate(format: "type != %d", BILineType.BlankLine.rawValue)
        sortedLines = (sortedLines as NSArray).filtered(using: notBlankPredicate) as? [AnyObject] ?? []
        let file = jsonData["File"] as! [String: Any]
        let toplevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
        let vacayLines = toplevel["Lines"] as! [[String: Any]]
        
        //        if(sortedLines.count == vacayLines.count) {
        var vEnumerator = vacayLines.makeIterator()
        for line in sortedLines as! [BILine] {
            let vLine = vEnumerator.next()
            guard let lineNumber = line.number?.intValue else { continue }
  
            let resultArray = vacayLines.filter { ($0[lineName] as? Int ?? 0) == lineNumber }
            if resultArray.isEmpty {
//                print("No match found for line \(lineNumber), JSON lines: \(vacayLines)")
            }
            else {
                let vLineNumber = (vLine?[lineName] as? Int) ?? (vLine?[lineName] as? NSNumber)?.intValue ?? 0
                if(vLineNumber == line.number?.intValue) {
                    let lineData = vLine?["LineData"] as! [String: Any]
                    if vacationType == "FAVacation" {
                        line.vWBVacPay =  NSNumber(value: (lineData[totalVacationPay] as? NSNumber)?.floatValue ?? 0.0)
                    }
                }
            }
        }
        DispatchQueue.main.async {
            if let context = self.bidPeriod?.managedObjectContext {
                do {
                    try context.save()
                } catch {
                    print("Failed to save context: \(error)")
                }
            }
        }
        //        }
        
    }
//    func finishBlock(withSwaptimizerStatus swaptimizerStatus: NSNumber?) {
//        if swaptimizerStatus != nil {
//            self.bidPeriod?.swaptimizerStatus = NSNumber(value: CBSwaptimizerStatus.statusError.rawValue)
//        }
//        
////        if let finishedBlock = self.finishedBlock {
////            DispatchQueue.main.async {
////                finishedBlock()
////            }
////        }
//    }
    
    func storeFAVacation(jsonData: [String: Any]) {
        let file = jsonData["File"] as! [String: Any]
        let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
        let header = topLevel["Header"] as! [String: Any]
        var moc = self.bidPeriod?.managedObjectContext
        self.bidPeriod?.faFileIntent = header["FileIdent"] as? String
        if moc!.hasChanges {
            do {
                try moc?.save()
                print("filename saved")
            } catch {
                print("Error saving context: \(error)")
            }
        }
        writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
    }
    
    func validateFAVacation(jsonData: [String: Any], completion: @escaping (Bool) -> Void) {
        guard
            let status = jsonData["Status"] as? [String: Any],
            let pilotInfo = jsonData["PilotInfo"] as? [String: Any],
            let configInfo = jsonData["ConfigInfo"] as? [String: Any],
            let statusCode = status["Code"] as? String,
            let yearMonth = configInfo["YearMonth"] as? String
        else {
            completion(false)
            return
        }

        let hasAccount = (pilotInfo["HasAccount"] as? String == "1")
        let dataAvailable = (pilotInfo["DataAvailable"] as? NSNumber)?.boolValue ?? false
        let hasVacation = (pilotInfo["HasVacation"] as? NSNumber)?.boolValue ?? false

        let vacayYear = Int(yearMonth.prefix(4)) ?? 0
        let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
        let bidMonth = self.bidPeriod?.month?.intValue ?? 0
        let bidYear = self.bidPeriod?.year?.intValue ?? 0
        let bidBase = self.bidPeriod?.base ?? ""
        let bidRound = self.bidPeriod?.round?.intValue ?? 0

        guard statusCode == "SUCCESS" else {
            AlertService.showAlertForTopVC(title: "Crewbid Alert", message: "Vacation Files are NOT yet ready, check back in 2 more hours.", actions: nil)
            completion(false)
            return
        }

        guard hasVacation else {
            let user = String(describing: self.bidPeriod?.swaptimizerIdentifier)
            AlertService.showAlertForTopVC(title: "No Vacation", message: "No vacation next month for user \(user)", actions: nil)
            completion(false)
            return
        }

        guard hasAccount && dataAvailable else {
            AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
            completion(false)
            return
        }

        guard
            let seat = pilotInfo["Seat"] as? String,
            let configRound = Int(configInfo["Round"] as? String ?? "0"),
            let vacayBase = pilotInfo["Base"] as? String,
            let positionType = self.bidPeriod?.positionType.flatMap({ BICrewPositionType(rawValue: $0.intValue) })
        else {
            completion(false)
            return
        }
        let shortName = CBUtils.shortName(for: positionType)
        if vacayMonth != bidMonth {
            AlertService.showAlertForTopVC(title: "Error", message: "The data month \(vacayMonth) is not the same as the bid period month \(bidMonth)")
            completion(false)
            return
        }

        if vacayYear != bidYear {
            AlertService.showAlertForTopVC(title: "Error", message: "The data year \(vacayYear) is not the same as the bid period year \(bidYear).")
            completion(false)
            return
        }

        if vacayBase != bidBase {
            AlertService.showAlertForTopVC(title: "Error", message: "The data base \(vacayBase) is not the same as the bid period base \(bidBase).")
            completion(false)
            return
        }

        if shortName != seat {
            AlertService.showAlertForTopVC(title: "Error", message: "The vacation data position \(seat) is not the same as the bid period position \(shortName).")
            completion(false)
            return
        }

        if bidRound == 2 && configRound == 1 {
            AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "Vacation data is not yet available. Check back later.")
            completion(false)
            return
        }

        if configRound != bidRound {
            AlertService.showAlertForTopVC(title: "Error", message: "The vacation data round \(configRound) is not the same as the bid period round \(bidRound).")
            completion(false)
            return
        }

        // Final SWAPtimizer JSON verification
        guard
            let file = jsonData["File"] as? [String: Any],
            let topLevel = file["SWAPtimizer_CrewBid_Data"] as? [String: Any],
            let header = topLevel["Header"] as? [String: Any],
            let fileRound = header["Round"] as? Int,
            let fileYear = header["BidPeriodYear"] as? Int,
            let fileMonth = header["BidPeriodMonth"] as? Int
        else {
            completion(false)
            return
        }

        if fileRound != configRound {
            AlertService.showAlertForTopVC(title: "File Mismatch", message: "Vacation round \(configRound) and data file round \(fileRound) mismatch.")
            completion(false)
            return
        }

        if fileYear != vacayYear {
            AlertService.showAlertForTopVC(title: "File Mismatch", message: "Vacation year \(vacayYear) and file year \(fileYear) mismatch.")
            completion(false)
            return
        }

        if fileMonth != vacayMonth {
            AlertService.showAlertForTopVC(title: "File Mismatch", message: "Vacation month \(vacayMonth) and file month \(fileMonth) mismatch.")
            completion(false)
            return
        }

        // ✅ All validations passed → Write file & process
        let moc = self.bidPeriod?.managedObjectContext
        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "FAVacation"
        if vacationType == "FAVacation" {
            self.bidPeriod?.faFileIntent = header["FileIdent"] as? String
        } else if vacationType == "FAVacationF" {
            self.bidPeriod?.faFileIntentF = header["FileIdent"] as? String
        } else if vacationType == "FAVacationEomOnly" {
            self.bidPeriod?.faFileIntentEomOnly = header["FileIdent"] as? String
        }

        if moc?.hasChanges == true {
            do {
                try moc?.save()
                print("Context saved during FA validation")
            } catch {
                print("Failed to save context: \(error)")
            }
        }

        self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)

        // Delay processing slightly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.processFAVacationWithJsonFile(file: file)
            completion(true)
        }
    }

    
    //    MARK: validateSWAPtimizerJSON
    func validateSWAPtimizerJSON(jsonData: [String: Any], completion: @escaping (Bool) -> Void) {
        let status = jsonData["Status"] as! [String: Any]
        let pilotInfo = jsonData["PilotInfo"] as! [String: Any]
        let configInfo = jsonData["ConfigInfo"] as! [String: Any]
        let statusCode = status["Code"] as! String
        let statusMsg = status["Msg"] as! String
        let hasAccount = (pilotInfo["HasAccount"] as? Int == 1)
        let dataAvailable = (pilotInfo["DataAvailable"] as? NSNumber)?.boolValue ?? false
        let hasVacation = (pilotInfo["HasVacation"] as? NSNumber)?.boolValue ?? false
        var pilotIdentifier = Int(pilotInfo["Pilot"] as? String ?? "") ?? 0
        let yearMonth = configInfo["YearMonth"] as! String
        let vacayYear = Int(yearMonth.prefix(4)) ?? 0
        let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
        
        if self.bidPeriod?.secretSwitchOn == "YES" {
            pilotIdentifier = self.bidPeriod?.swaptimizerIdentifier?.intValue ?? 0
        }

        func showError(title: String, message: String) {
            AlertService.showAlertForTopVC(title: title, message: message)
            completion(false)
        }

        guard statusCode == "SUCCESS" else {
            showError(title: "SWAPtimizer Server Error", message: "\(statusMsg)\nSWAPtimizer vacation usually releases data the evening of the 4th or morning of the 5th. If you are seeing this error before data release, please try again after data has been released.")
            return
        }

        guard pilotIdentifier == self.bidPeriod?.swaptimizerIdentifier?.intValue else {
            showError(title: "SWAPtimizer Error", message: "The SWAPtimizer user ID \(pilotIdentifier) does not match the pilot for whom the bid package was downloaded \(String(describing: self.bidPeriod?.swaptimizerIdentifier)).")
            return
        }

        if ((self.bidPeriod?.month?.intValue)! - vacayMonth == 1 || (self.bidPeriod?.month?.intValue == 1 && vacayMonth == 12)) {
            showError(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
            return
        }

        guard hasVacation else {
            showError(title: "No Vacation", message: "No vacation next month for user \(String(describing: self.bidPeriod?.swaptimizerIdentifier))")
            return
        }

        if hasVacation && !hasAccount {
            showError(title: "No SWAPtimizer Account!", message: "We see that you have vacation this month, but you do not have SWAPtimizer Account.\nSWAPtimizer is the gold standard of SWA vacation prediction and we highly recommend their product. Go to www.swaptimizer.com to sign up!")
            return
        }

        if hasVacation && hasAccount && !dataAvailable {
            showError(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
            return
        }

        // ✅ VALID CASE
        let seat = pilotInfo["Seat"] as! String
        let round = Int(configInfo["Round"] as? String ?? "") ?? 0
        let vacayBase = pilotInfo["Base"] as! String
        let rawValue = (self.bidPeriod?.positionType?.intValue)!
        let positionType = BICrewPositionType(rawValue: rawValue)!
        let shortName = CBUtils.shortName(for: positionType)

        if self.bidPeriod?.secretSwitchOn != "YES" {
            if vacayMonth != self.bidPeriod?.month?.intValue {
                showError(title: "SWAPtimizer Error", message: "The SWAPtimizer data month \(vacayMonth) is not the same as the bid period month \(String(describing: self.bidPeriod?.month))")
                return
            }
            if vacayYear != self.bidPeriod?.year?.intValue {
                showError(title: "SWAPtimizer Error", message: "The SWAPtimizer data year \(vacayYear) is not the same as the bid period year \(String(describing: self.bidPeriod?.year)).")
                return
            }
            if vacayBase != self.bidPeriod?.base {
                showError(title: "SWAPtimizer Error", message: "The SWAPtimizer data base \(vacayBase) is not the same as the bid period crew base \(String(describing: self.bidPeriod?.base)).")
                return
            }
            if shortName != seat {
                showError(title: "SWAPtimizer Error", message: "The vacation data position \(seat) is not the same as the bid period position \(shortName).")
                return
            }
            if self.bidPeriod?.round?.intValue == 2 && round == 1 {
                showError(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
                return
            }
            if round != self.bidPeriod?.round?.intValue {
                showError(title: "SWAPtimizer Error", message: "The vacation data round \(round) is not the same as the bid period round \(String(describing: self.bidPeriod?.round))")
                return
            }
        }

        let file = jsonData["File"] as! [String: Any]
        let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
        let header = topLevel["Header"] as! [String: Any]
        let fileRound = header["Round"] as! Int
        let fileYear = header["BidPeriodYear"] as! Int
        let fileMonth = header["BidPeriodMonth"] as! Int

        if self.bidPeriod?.secretSwitchOn != "YES" {
            if fileRound != round {
                showError(title: "SWAPtimizer File Mismatch", message: "The vacation round \(round) and SWAPtimizer data file round \(fileRound) are mismatched. Perhaps you didn't bid a blank line?")
                return
            }
            if fileYear != vacayYear {
                showError(title: "SWAPtimizer File Mismatch", message: "The vacation year \(vacayYear) and SWAPtimizer data file year \(fileYear) are mismatched. Perhaps you didn't bid a blank line?")
                return
            }
            if fileMonth != vacayMonth {
                showError(title: "SWAPtimizer File Mismatch", message: "The vacation month \(vacayMonth) and SWAPtimizer data file month \(fileMonth) are mismatched. Perhaps you didn't bid a blank line?")
                return
            }
        }

        // ✅ Save context, write file, and continue processing
        let moc = self.bidPeriod?.managedObjectContext
        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "CREWBID"

        if vacationType == "CREWBID" {
            self.bidPeriod?.cbFileIntent = header["FileIdent"] as? String
        } else if vacationType == "CREWBIDF" {
            self.bidPeriod?.cbFileIntentF = header["FileIdent"] as? String
        }

        if moc?.hasChanges == true {
            do {
                try moc?.save()
                print("context in validate SWAPtimizer writeVacationFile saved")
            } catch {
                print("context in validate SWAPtimizer writeVacationFile not saved: \(error)")
            }
        }

        self.captureVacationDetails(jsonData: jsonData)
        self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
        self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.checked.rawValue as NSNumber

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.isAutoDownload, let wbFile = self.bidPeriod?.wbFileIntent {
                self.bidPeriod?.userVacationWbidOrCrewBid = "WBID"
                let dicVacationFile = self.readVacationFile(fileName: wbFile)
                self.validateWBIDVacation(jsonData: dicVacationFile ?? [:]) { _ in
                    completion(true)
                }
                return
            }

            let isFA = self.bidPeriod?.isFABid() ?? false
            if isFA {
                self.processFAVacationWithJsonFile(file: file)
            } else {
                self.processJsonFile(file: file)
            }
            completion(true)
        }
    }

    
    //    MARK: Auto validateSWAPtimizerJSON
    func AutoValidateSWAPtimizerJSON(jsonData: [String: Any], completion: @escaping (Bool) -> Void) {
        guard
            let status = jsonData["Status"] as? [String: Any],
            let pilotInfo = jsonData["PilotInfo"] as? [String: Any],
            let configInfo = jsonData["ConfigInfo"] as? [String: Any]
        else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }

        let statusCode = status["Code"] as? String ?? ""
        let statusMsg = status["Msg"] as? String ?? ""
        let hasAccount = (pilotInfo["HasAccount"] as? String == "1")
        let dataAvailable = (pilotInfo["DataAvailable"] as? NSNumber)?.boolValue ?? false
        let hasVacation = (pilotInfo["HasVacation"] as? NSNumber)?.boolValue ?? false
        var pilotIdentifier = Int(pilotInfo["Pilot"] as? String ?? "") ?? 0
        let yearMonth = configInfo["YearMonth"] as? String ?? ""
        let vacayYear = Int(yearMonth.prefix(4)) ?? 0
        let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0

        if self.bidPeriod?.secretSwitchOn == "YES" {
            pilotIdentifier = self.bidPeriod?.swaptimizerIdentifier?.intValue ?? 0
        }

        func failWithAlert(title: String, message: String) {
            if self.bidPeriod?.wbFileIntent != nil {
                AlertService.showAlertForTopVC(title: title, message: message, actions: nil)
            }
            DispatchQueue.main.async {
                completion(false)
            }
        }

        guard statusCode == "SUCCESS" else {
            failWithAlert(title: "SWAPtimizer Server Error", message: "\(statusMsg)\nSWAPtimizer vacation usually releases data the evening of the 4th or morning of the 5th.")
            return
        }

        guard pilotIdentifier == self.bidPeriod?.swaptimizerIdentifier?.intValue else {
            failWithAlert(title: "SWAPtimizer Error", message: "The SWAPtimizer user ID \(pilotIdentifier) does not match the pilot for whom the bid package was downloaded.")
            return
        }

        let bidMonth = self.bidPeriod?.month?.intValue ?? 0
        if bidMonth - vacayMonth == 1 || (bidMonth == 1 && vacayMonth == 12) {
            failWithAlert(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later.")
            return
        }

        guard hasVacation else {
            failWithAlert(title: "No Vacation", message: "No vacation next month for user \(String(describing: self.bidPeriod?.swaptimizerIdentifier))")
            return
        }

        guard hasAccount else {
            failWithAlert(title: "No SWAPtimizer Account!", message: "You have vacation this month, but do not have a SWAPtimizer account.\nVisit www.swaptimizer.com to sign up!")
            return
        }

        guard dataAvailable else {
            failWithAlert(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later.")
            return
        }

        // Now: validate file matches
        guard
            let file = jsonData["File"] as? [String: Any],
            let topLevel = file["SWAPtimizer_CrewBid_Data"] as? [String: Any],
            let header = topLevel["Header"] as? [String: Any]
        else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }

        let fileRound = header["Round"] as? Int ?? 0
        let fileYear = header["BidPeriodYear"] as? Int ?? 0
        let fileMonth = header["BidPeriodMonth"] as? Int ?? 0

        let round = self.bidPeriod?.round?.intValue ?? 0
        let positionRaw = self.bidPeriod?.positionType?.intValue ?? 0
        let positionType = BICrewPositionType(rawValue: positionRaw)!
        let shortName = CBUtils.shortName(for: positionType)
        let seat = pilotInfo["Seat"] as? String ?? ""
        let vacayBase = pilotInfo["Base"] as? String ?? ""

        if self.bidPeriod?.secretSwitchOn != "YES" {
            if vacayMonth != bidMonth {
                failWithAlert(title: "SWAPtimizer Error", message: "SWAPtimizer data month \(vacayMonth) doesn't match bid period month \(bidMonth)")
                return
            }
            if vacayYear != self.bidPeriod?.year?.intValue {
                failWithAlert(title: "SWAPtimizer Error", message: "SWAPtimizer data year \(vacayYear) doesn't match bid period year")
                return
            }
            if vacayBase != self.bidPeriod?.base {
                failWithAlert(title: "SWAPtimizer Error", message: "SWAPtimizer base \(vacayBase) doesn't match crew base")
                return
            }
            if shortName != seat {
                failWithAlert(title: "SWAPtimizer Error", message: "Vacation data position \(seat) doesn't match bid period position \(shortName)")
                return
            }
            if round == 2 && fileRound == 1 {
                failWithAlert(title: "Data Not Yet Available", message: "Round 2 active, but SWAPtimizer only has Round 1 data.")
                return
            }
            if round != fileRound {
                failWithAlert(title: "SWAPtimizer File Mismatch", message: "Vacation round \(fileRound) doesn't match bid period round \(round)")
                return
            }
            if fileYear != vacayYear {
                failWithAlert(title: "SWAPtimizer Error", message: "The vacation year \(vacayYear)and SWAPTimizer data file year \(fileYear) are mismatched. Please contact the support staff to report the mismatch.")
                return
            }
            if fileMonth != vacayMonth {
                failWithAlert(title: "SWAPtimizer Error", message: "The vacation month \(vacayMonth)and SWAPTimizer data file month \(fileMonth) are mismatched. Please contact the support staff to report the mismatch.")
                return
            }
        }

        // ✅ Passed validation
        let moc = self.bidPeriod?.managedObjectContext
        self.bidPeriod?.cbFileIntent = header["FileIdent"] as? String
        if moc?.hasChanges == true {
            do {
                try moc?.save()
                print("context saved")
            } catch {
                print("context save failed: \(error)")
            }
        }

        self.captureVacationDetails(jsonData: jsonData)
        self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
        self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.checked.rawValue as NSNumber

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.isAutoDownload, let wbFileIntent = self.bidPeriod?.wbFileIntent {
                self.bidPeriod?.userVacationWbidOrCrewBid = "WBID"
                let dicVacationFile = self.readVacationFile(fileName: wbFileIntent)
                self.validateWBIDVacation(jsonData: dicVacationFile ?? [:]) { _ in
                    completion(true) // Still considered a success
                }
                
            } else {
                let isFA = self.bidPeriod?.isFABid() ?? false
                if isFA {
                    self.processFAVacationWithJsonFile(file: file)
                } else {
                    self.processJsonFile(file: file)
                }
                completion(true)
            }
        }
    }

    
//    func captureVacationDetails(jsonData: [String: Any]) {
//        let app = UIApplication.shared.delegate as! AppDelegate
//        let file = jsonData["File"] as! [String: Any]
//        let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
//        let header = topLevel["Header"] as! [String: Any]
//        var dicVacationDetails: [String: Any] = [:]
//        var sampleDic : [String: Any] = [:]
//        sampleDic["Test"] = "Test"
//        var pilotInfo = jsonData["PilotInfo"] as! [String: Any]
//        dicVacationDetails["EmpNum"] = Int(pilotInfo["Pilot"] as? String ?? "") ?? 0
//        dicVacationDetails["Base"] = header["Base"]
//        dicVacationDetails["Month"] = Int(header["BidPeriodMonth"] as? String ?? "") ?? 0
//        dicVacationDetails["Year"] = Int(header["BidPeriodYear"] as? String ?? "") ?? 0
//        dicVacationDetails["Round"] = Int(header["Round"] as? String ?? "") ?? 0
//        var position = pilotInfo["Seat"] as? String ?? ""
//        
//        if(position == "CA") {
//            position = "CP"
//        }
//        dicVacationDetails["Position"] = position
//        dicVacationDetails["SwapJsonFileName"] = header["FileIdent"]
//        var url2 = URL(string: "")
//        if app.connectedToInternet() {
//            if let baseURL = URL(string: app.Domain!) {
//                let url = baseURL.appendingPathComponent("SaveSwaptimizerFileToServer")
//                print(url) // http://www.wbidmax.com:8000/WBidDataDwonloadAuthService.svc/SaveSwaptimizerFileToServer
//                url2 = url
//            }
//            self.urlRequest = URLRequest(url: url2!)
//            let jsonDataToSend = try! JSONSerialization.data(withJSONObject: dicVacationDetails, options: [])
//            let jsonString = String(data: jsonDataToSend, encoding: .utf8)
//            self.urlRequest?.httpBody = jsonString?.data(using: .utf8)
//            self.urlRequest?.httpMethod = "POST"
//            self.urlRequest?.setValue("852275", forHTTPHeaderField: "Content-Length")
//            let dataTask = URLSession.shared.dataTask(with: urlRequest!) { data, response, error in
//                // Handle request error
//                if let error = error as NSError?, error.code == NSURLErrorTimedOut {
////                    MARK: need to add CBOffline events
////                    let objEvent = CBOfflineEvents()
//                    if let monthValue = self.bidPeriod?.month {
////                        objEvent.sendOfflineDataForTimeOut(url.absoluteString, month: monthValue)
//                    }
//                }
//
//                if let data = data {
//                    DispatchQueue.main.async {
////                        self.hud?.hide(true)
//                    }
//                    // check status code and possibly MIME type (which shall start with "application/json"):
//                    if let httpResponse = response as? HTTPURLResponse,
//                       httpResponse.statusCode == 200,
//                       let mimeType = response?.mimeType,
//                       mimeType.contains("application/json") {
//                        // Handle successful JSON response
//                    }
//                }
//            }
//
//            dataTask.resume()
//
//        }
//        
//    }
    func captureVacationDetails(jsonData: [String: Any]) {
        guard
            let file = jsonData["File"] as? [String: Any],
            let topLevel = file["SWAPtimizer_CrewBid_Data"] as? [String: Any],
            let header = topLevel["Header"] as? [String: Any],
            let pilotInfo = jsonData["PilotInfo"] as? [String: Any]
        else {
            print("Invalid JSON structure in captureVacationDetails")
            return
        }
        
        // Build vacation details dictionary
        var dicVacationDetails: [String: Any] = [:]
        dicVacationDetails["EmpNum"] = Int(pilotInfo["Pilot"] as? String ?? "") ?? 0
        dicVacationDetails["Base"] = header["Base"]
        dicVacationDetails["Month"] = Int(header["BidPeriodMonth"] as? String ?? "") ?? 0
        dicVacationDetails["Year"] = Int(header["BidPeriodYear"] as? String ?? "") ?? 0
        dicVacationDetails["Round"] = Int(header["Round"] as? String ?? "") ?? 0
        
        var position = pilotInfo["Seat"] as? String ?? ""
        if position == "CA" { position = "CP" }
        dicVacationDetails["Position"] = position
        dicVacationDetails["SwapJsonFileName"] = header["FileIdent"]
        
        // Ensure we have a base URL
        let app = UIApplication.shared.delegate as! AppDelegate
        guard app.connectedToInternet() else {
            print("No internet")
            return
        }
        let url = EndPoint.shared.saveSwaptimizerFileToServer
        print("Upload URL:", url)
        
        // Encode vacation details JSON
        guard let bodyData = try? JSONSerialization.data(withJSONObject: dicVacationDetails, options: []) else {
            print("Failed to serialize vacation details")
            return
        }
        
        // Use APIService.shared.fetch
        APIService.shared.fetch(
            urlString: url,
            method: .POST,
            body: bodyData,
            headers: [
                "Content-Type": "application/json",
                "Content-Length": "\(bodyData.count)"
            ],
            parse: { data in
                // Return parsed JSON response (if any)
                try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
            },
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let responseJSON):
                        print("Vacation details successfully sent. Response:", responseJSON)
                        // TODO: handle success logic here
                    case .failure(let error):
                        print("Failed to send vacation details with error:", error)
                        if let nsError = error as NSError?, nsError.code == NSURLErrorTimedOut {
                            let offlineEvent = CBOfflineEvents()
                            if let monthValue = self.bidPeriod?.month {
                                offlineEvent.sendOfflineDataForTimeOut(url: url, month: monthValue)
                            } else {
                                offlineEvent.sendOfflineDataForTimeOut(url: url, month: nil)
                            }
                        }
                    }
                }
            }
        )
    }
    
    func readVacationFile(fileName: String?) -> [String: Any]? {
        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid
        var vacationData: NSObject = NSObject()
        if vacationType == "WBID" {
            vacationData = (self.bidPeriod?.wbVacationfile)!
        }
        else if vacationType == "WBIDF" {
            vacationData = (self.bidPeriod?.wbVacationfileF)!
        }
        else if vacationType == "CREWBID" {
            vacationData = (self.bidPeriod?.cbVacationFiles)!
        }
        else if vacationType == "CREWBIDF" {
            vacationData = (self.bidPeriod?.cbVacationFilesF)!
        }
        else if vacationType == "FAVacation" {
            vacationData = (self.bidPeriod?.faVacationFiles)!
        }
        else if vacationType == "FAVacationF" {
            let eomIndexF = fileName?.suffix(1)
            if eomIndexF == "1" {
                vacationData = (self.bidPeriod?.faVacationFilesFA1)!
            } else if eomIndexF == "2" {
                vacationData = (self.bidPeriod?.faVacationFilesFA2)!
            } else if eomIndexF == "3" {
                vacationData = (self.bidPeriod?.faVacationFilesFA3)!
            }
        }
        else if vacationType == "FAVacationEomOnly" {
            let eomIndexF = fileName?.suffix(1)
            if eomIndexF == "1" {
                vacationData = (self.bidPeriod?.faVacationFilesEomOnlyFA1)!
            } else if eomIndexF == "2" {
                vacationData = (self.bidPeriod?.faVacationFilesEomOnlyFA2)!
            } else if eomIndexF == "3" {
                vacationData = (self.bidPeriod?.faVacationFilesEomOnlyFA3)!
            } else if eomIndexF == "4" {
                vacationData = (self.bidPeriod?.faVacationFilesEomOnlyFA4)!
            } else if eomIndexF == "5" {
                vacationData = (self.bidPeriod?.faVacationFilesEomOnlyFA5)!
            } else if eomIndexF == "6" {
                vacationData = (self.bidPeriod?.faVacationFilesEomOnlyFA6)!
            } else if eomIndexF == "7" {
                vacationData = (self.bidPeriod?.faVacationFilesEomOnlyFA7)!
            }
        }
        if vacationType == nil {
            return nil
        }
        if let jsonObject = vacationData as? NSObject,
           JSONSerialization.isValidJSONObject(jsonObject) {
            do {
                let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
                let userDic = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                return userDic
            } catch {
                print("Serialization error: \(error)")
                return nil
            }
        } else {
            return nil
        }
    }
    
//    MARK: processJsonFile
    func processJsonFile(file: [String: Any]) {
        let thanksGivingDay = CBUtils.thanksgivingDay(for: self.bidPeriod?.year?.intValue ?? 0)
        var vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "WBID"
        var frontVO = ""
        var frontVO1 = ""
        var frontVO2 = ""
        var backVO = ""
        var backVO1 = ""
        var backVO2 = ""
        var carryoutVacationPay = ""
        var effectiveVacationLength = ""
        var longestBlockofDaysOff = ""
        var carryoutVOPay = ""
        var totalPay = ""
        var flyPay = ""
        var totalVacationPay = ""
        var carryOutPay_Flying = ""
        var totalDaysOff = ""
        var daysWorked_inmonth = ""
        var daysWorked = ""
        var lineName = ""
        var blockName = ""
        var vacPayBothBp = ""
        var vacPayNeBp = ""
        var clawBack = ""
        
        var vAbo = ""
        var vAbp = ""
        var vAne = ""
        var vAPbo = ""
        var vAPbp = ""
        var vAPne = ""
        
        var vOFront = ""
        var vOFNe = ""
        var vOBack = ""
        var vOBNe = ""
        
        if vacationType == "WBID" || vacationType == "WBIDF" {
            lineName = "Line1";
            frontVO = "FrontVO";
            frontVO1 = "FrontVO1";
            frontVO2 = "FrontVO2";
            blockName = "Block";
            backVO = "BackVO";
            backVO1 = "BackVO1";
            backVO2 = "BackVO2";
            
            carryoutVacationPay = "CarryOutVacationPay";
            effectiveVacationLength = "EffectiveVacationLength";
            longestBlockofDaysOff = "LongestBlockofDaysOff";
            vacPayBothBp = "VacPayBothBp";
            vacPayNeBp = "VacPayNeBp";
            carryoutVOPay = "CarryoutVOPay";
            totalPay = "TotalPay";
            flyPay = "FlyPay";
            totalVacationPay = "TotalVacationPay";
            carryOutPay_Flying = "CarryOutPay";
            totalDaysOff = "TotalDaysOff";
            
            daysWorked_inmonth = "DaysWorkedinMonth";
            daysWorked = "DaysWorked";
            
            clawBack = "ClawBack";
            
            vAbo = "VAbo";
            vAbp = "VAbp";
            vAne = "VAne";
            vAPbo = "VAPbo";
            vAPbp = "VAPbp";
            vAPne = "VAPne";
            
            vOFront = "VOFront";
            vOFNe = "VOFNe";
            vOBack = "VOBack";
            vOBNe = "VOBNe";
            
        } else {
            
            lineName = "Line#";
            frontVO = "Front VO";
            frontVO1 = "Front VO1";
            frontVO2 = "Front VO 2";
            blockName = "*Block";
            backVO = "Back VO";
            backVO1 = "Back VO1";
            backVO2 = "Back VO 2";
            
            carryoutVacationPay = "Carry-out Vacation Pay";
            effectiveVacationLength = "Effective Vacation Length";
            longestBlockofDaysOff = "Longest Block of Days Off";
            carryoutVOPay = "Carry-out VO Pay";
            vacPayBothBp = "VacPayBothBp";
            vacPayNeBp = "VacPayNeBp";
            totalPay = "Total Pay";
            flyPay = "Fly Pay";
            totalVacationPay = "Total Vacation Pay";
            carryOutPay_Flying = "Carry Out Pay (Flying)";
            
            totalDaysOff = "Total Days Off";
            daysWorked_inmonth = "Days Worked (in month)";
            daysWorked = "Days Worked";
            
            vAbo = "VAbo";
            vAbp = "VAbp";
            vAne = "VAne";
            vAPbo = "VAPbo";
            vAPbp = "VAPbp";
            vAPne = "VAPne";
        }
        let secretEnabled = self.bidPeriod?.secretSwitchOn
        let moc = self.bidPeriod?.managedObjectContext
        let fetchRequest: NSFetchRequest<BITrip> = BITrip.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]

        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: moc!,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        do {
            try controller.performFetch()
            
            if let trips = controller.fetchedObjects as? [BITrip] {
                for trip in trips {
                    trip.vacationOverlapType = 0
                    trip.dropForFiltersSorts = false
                    trip.redEyeDayDisplayDayType = BIDayDisplayType.normal.rawValue as NSNumber
                    
                    for case let day as BIDay in trip.days ?? [] {
                        day.displayType = BIDayDisplayType.normal.rawValue as NSNumber
                    }
                }
            }
            
        } catch {
            print("Failed to perform fetch: \(error)")
        }
        let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
        let header = topLevel["Header"] as! [String: Any]
        let numVacayWeeks = header["NumberVacationWeeks"] as? Int ?? 0
        self.bidPeriod?.numVacations = numVacayWeeks as NSNumber
        var vacayDates = header["VacationDates"] as! [[String: String]]
        
        // Figure out if we're going to hide some of the values based on the LineDataFields
        var lineDataFields: [String] = []
        lineDataFields = (header["LineDataFields"] as? [String])!
        var hiddenValues: [String: Any] = [:]
        
//        carry out pay
        if lineDataFields.contains(carryOutPay_Flying) {
            hiddenValues[kCBSwaptmizerCarryOutPayHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerCarryOutPayHidden] = true
        }
//        Front VO
        if lineDataFields.contains(frontVO) || lineDataFields.contains(frontVO1) || lineDataFields.contains(frontVO2) {
            hiddenValues[kCBSwaptmizerFrontVoHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerFrontVoHidden] = true
        }
//        Back VO
        if lineDataFields.contains(backVO) || lineDataFields.contains(backVO1) || lineDataFields.contains(backVO2) {
            hiddenValues[kCBSwaptmizerBackVoHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerBackVoHidden] = true
        }
//        Vaccay Carry Out Pay
        if lineDataFields.contains(carryoutVacationPay) {
            hiddenValues[kCBSwaptmizerVacayCarryOutPayHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerVacayCarryOutPayHidden] = true
        }
        //  Effective vacay length
        if lineDataFields.contains(effectiveVacationLength) {
            hiddenValues[kCBSwaptmizerEffVacayLengthHidden] = false
        }
        else {
            if vacationType == "WBID" || vacationType == "WBIDF" {
                hiddenValues[kCBSwaptmizerEffVacayLengthHidden] = false
            }
            else {
                hiddenValues[kCBSwaptmizerEffVacayLengthHidden] = true
            }
        }
        // Vacation Pay Next BP
        if lineDataFields.contains(vacPayNeBp) {
            hiddenValues[kCBSwaptmizerVacPayNextBPHidden] = false
        }
        else {
            if vacationType == "WBID" || vacationType == "WBIDF" {
                hiddenValues[kCBSwaptmizerVacPayNextBPHidden] = false
            }
            else {
                hiddenValues[kCBSwaptmizerVacPayNextBPHidden] = true
            }
        }
        // Vacation Pay Both BP
        if lineDataFields.contains(vacPayBothBp) {
            hiddenValues[kCBSwaptmizerVacPayBothBPHidden] = false
        }
        else {
            if vacationType == "WBID" || vacationType == "WBIDF" {
                hiddenValues[kCBSwaptmizerVacPayBothBPHidden] = false
            }
            else {
                hiddenValues[kCBSwaptmizerVacPayBothBPHidden] = true
            }
        }
//        ClawBack
        if vacationType == "WBID" || vacationType == "WBIDF" {
         hiddenValues[kCBSwaptmizerClawBackHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerClawBackHidden] = true
        }
        //Longest Block of Days Off
        if lineDataFields.contains(longestBlockofDaysOff) {
            hiddenValues[kCBSwaptmizerLongestBlockofDaysOffHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerLongestBlockofDaysOffHidden] = true
        }
        // Carry Out Vo Pay
        if lineDataFields.contains(carryoutVOPay) {
            hiddenValues[kCBSwaptmizerCarryOutVoHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerCarryOutVoHidden] = true
        }
        UserDefaults.standard.set(hiddenValues, forKey: kCBSwaptimizerHiddenDict)
        
//        Delete all vacay
        let fetchRequestForVacation: NSFetchRequest<BIVacation> = BIVacation.fetchRequest()
        fetchRequestForVacation.includesPropertyValues = false
        do {
            let vacays = try self.bidPeriod?.managedObjectContext?.fetch(fetchRequestForVacation)
            for vacay in vacays! {
                moc?.delete(vacay)
            }
        } catch {
            print("vacation fetch failed: \(error)")
        }
        
        let vacayLines = topLevel["Lines"] as! [[String: Any]]
        let totalLinesToProcess = vacayLines.count * vacayDates.count
        var counter = 0
        
        for i in 0..<vacayDates.count {
            let df = DateFormatter()
            df.dateFormat = "HHmmyyyyMMdd"
            df.timeZone = self.calendarData.bidPeriodTimezone()
            let vacayDict = vacayDates[i]
            let startDateString = vacayDict["FirstDay"]!
            let endDateString = vacayDict["LastDay"]!
            let startDate = df.date(from: "1200" + startDateString)
            let endDtStr = "2359" + endDateString
            let endDate = df.date(from: endDtStr)
            
//           not using nsEntityDescription for now, in case of error look obj-c
            let vacay = BIVacation(context: self.bidPeriod!.managedObjectContext!)
            if secretEnabled == "YES" {
                let secretVacay = BIVacation(context: (self.bidPeriod?.managedObjectContext)!)
            }
            vacay.bidPeriod = self.bidPeriod
            vacay.startDate = startDate
            vacay.endDate = endDate
//            vacationType = (self.bidPeriod?.userVacationWbidOrCrewBid)!
            vacay.vacationType = vacationType
            let length = (self.calendarData.daysBetweenDate(fromDateTime: startDate!, toDateTime: endDate!)) + 1
//            let length = (self.calendarData.daysBetweenDate(startDate!, andDate: endDate!) ?? 0) + 1
            vacay.length = length as NSNumber
            
            self.bidPeriod?.containsVacay = true
        }

        UserDefaults.standard.set(false, forKey: kCBIncludeDroppedTripsInProcessingKey)

        let includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
        let lines = self.bidPeriod?.lines?.allObjects as? [AnyObject] ?? []
        var sortedLines = (lines as NSArray).sortedArray(using: [
            NSSortDescriptor(key: "number", ascending: true)
        ])
        let notBlankPredicate = NSPredicate(format: "type != %d", BILineType.BlankLine.rawValue)
        sortedLines = (sortedLines as NSArray).filtered(using: notBlankPredicate) as? [AnyObject] ?? []
        
        if (sortedLines.count == vacayLines.count) {
            self.round = self.bidPeriod?.round
            self.year = self.bidPeriod?.year
            self.month = self.bidPeriod?.month
            self.position = self.bidPeriod?.positionType?.intValue
            self.base = self.bidPeriod?.base
            self.employeeNumber = self.bidPeriod?.swaptimizerIdentifier?.stringValue
            var globalBidInfo = GlobalBidInfo.shared
            let bidInfoReader = BIBidInfoReader()
            //            bidInfoReader.dataSource = self
            //            add global bid info if needed
            //            globalBidInfo.round = self.bidPeriod?.round as? Int ?? 0
            //            globalBidInfo.year = self.bidPeriod?.year as? Int ?? 2025
            //            globalBidInfo.month = self.bidPeriod?.month as? Int ?? 1
            //            globalBidInfo.position = self.bidPeriod?.positionType?.intValue ?? 0
            bidInfoReader.bidPeriod = self.bidPeriod
            bidInfoReader.calendarData = self.calendarData
            bidInfoReader.includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
            bidInfoReader.intlCities = (UserDefaults.standard.object(forKey: kCBInternationalCitiesDict) as? [String: Any])!
            
            // Reset the deadhead at start and end cities
            let fetchRequestForDeadHeadAtStart: NSFetchRequest<BIDeadheadAtStartCity> = BIDeadheadAtStartCity.fetchRequest()
            fetchRequestForDeadHeadAtStart.includesPropertyValues = false
            do {
                let cities = try self.bidPeriod?.managedObjectContext?.fetch(fetchRequestForDeadHeadAtStart)
                for city in cities! {
                    moc?.delete(city)
                }
            } catch {
                print("deadhead at start city fetch failed: \(error)")
            }
            let fetchRequestForDeadHeadAtEnd: NSFetchRequest<BIDeadheadAtEndCity> = BIDeadheadAtEndCity.fetchRequest()
            fetchRequestForDeadHeadAtEnd.includesPropertyValues = false
            do {
                let cities = try self.bidPeriod?.managedObjectContext?.fetch(fetchRequestForDeadHeadAtEnd)
                for city in cities! {
                    moc?.delete(city)
                }
            } catch {
                print("deadhead at end city fetch failed: \(error)")
            }
            if moc!.hasChanges {
                do {
                    try moc?.save()
                    print("deadhead at start and end cities saved")
                } catch {
                    print("Error saving context: \(error)")
                }
            }
            // Iterate over all the lines and fill in the stuff we need to know
            var vEnumerator = vacayLines.makeIterator()
            self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.enabled.rawValue as NSNumber
            for line in sortedLines as! [BILine] {
                
//                MARK: we can add progress if needed here
                let vLine = vEnumerator.next()
                let vLineNumber = (vLine?[lineName] as? Int) ?? (vLine?[lineName] as? NSNumber)?.intValue ?? 0
                
                if (vLineNumber == line.number?.intValue) {
                    let lineData = vLine?["LineData"] as! [String: Any]
                    line.vTotalPay = lineData[totalPay] as? NSNumber
                    line.pay = line.vTotalPay
                    line.coHoli = 0
                    line.vFlyPay = lineData[flyPay] as? NSNumber
                    line.tripTfp = line.vFlyPay
                    line.vVacationPay = lineData[totalVacationPay] as? NSNumber
                    if let rig = line.lineRig?.floatValue, let vvp = line.vVacationPay?.floatValue {
                        line.vTpLPay = NSNumber(value: rig + vvp)
                    }
                    line.vCarryOutPay = lineData[carryOutPay_Flying] as? NSNumber
                    if let vcop = line.vCarryOutPay?.floatValue, let lp = line.pay?.floatValue {
                        line.payPlusCo = NSNumber(value: vcop + lp)
                    }
                    line.vVacayCarryOutPay = lineData[carryoutVacationPay] as? NSNumber
                    line.vVacayPayBothBP = lineData[vacPayBothBp] as? NSNumber
                    line.vVacayPayNextBP = lineData[vacPayNeBp] as? NSNumber
                    line.vCarryOutVOPay = lineData[carryoutVOPay] as? NSNumber
                    line.blockMinutes = lineData[blockName] as? NSNumber
                    line.blockHours = line.blockMinutes!.floatValue / 60 as NSNumber
                    line.vBlockTime = line.blockMinutes!.floatValue / 60 as NSNumber
                    line.vDaysOff = lineData[totalDaysOff] as? NSNumber
                    line.vEffectiveVacayLength = lineData[effectiveVacationLength] as? NSNumber
                    line.vLongestBlockofDaysOff = lineData[longestBlockofDaysOff] as? NSNumber
                    line.vAbp = lineData[vAbp] as? NSNumber
                    line.vAne = lineData[vAne] as? NSNumber
                    line.vAbo = lineData[vAbo] as? NSNumber
                    line.vAPbp = lineData[vAPbp] as? NSNumber
                    line.vAPne = lineData[vAPne] as? NSNumber
                    line.vAPbo = lineData[vAPbo] as? NSNumber
                    
                    line.vOBcu = lineData[vOBack] as? NSNumber
                    line.vOBne = lineData[vOBNe] as? NSNumber
                    line.vOFcu = lineData[vOFront] as? NSNumber
                    line.vOFne = lineData[vOFNe] as? NSNumber
                    
                    line.clawBack = lineData[clawBack] as? NSNumber
                    let ane = line.vAne?.floatValue ?? 0
                    let vacationPay = line.vVacationPay?.floatValue ?? 0
                    line.vpCuPlusVaNe = NSNumber(value: ane + vacationPay)
                    
                    if (line.vTotalPay!.floatValue > 0 && line.vBlockTime!.intValue > 0) {
                        line.vPayPerBlock = (line.vTotalPay!.floatValue) / (line.vBlockTime?.floatValue)! as NSNumber
                    }
                    else {
                        line.vPayPerBlock = 0.0
                        line.payPerBlockHour = 0.0
                    }
                    var fvVacayDates: [[String: Any]] = []
                    if let data = vLine?["FVvacationData"] {
                        if let array = data as? [[String: Any]] {
                            fvVacayDates = array
                        }
                    }
                    if let cfvDates = vLine?["CFVDates"] {
                        line.cfvVacDates = cfvDates as? NSArray
                        self.bidPeriod?.containsVacay = true
                        self.bidPeriod?.seniorityVacayAvailable = true
                        self.bidPeriod?.containsCFV = true
                    }
                    var modifiedFVVacayDates: [[String: Any]]  = []
                    var selectedFVVacayDates: [[String: Any]]  = []
                    
                    let areDateRangesOverLapping = self.anyDateRangesOverlapping(vacations: fvVacayDates)
                    if (areDateRangesOverLapping) {
                        modifiedFVVacayDates = self.mergeDateRanges(vacationDates: fvVacayDates)
                    }
                    if (areDateRangesOverLapping && modifiedFVVacayDates.count > 0) {
                        selectedFVVacayDates = fvVacayDates
                    }
                    for i in 0..<selectedFVVacayDates.count {
                        let vacayDict = selectedFVVacayDates[i]
                        var startDate = Date()
                        var endDate = Date()
                        if (areDateRangesOverLapping) {
                            startDate = vacayDict["FVStartDate"] as! Date
                            endDate = vacayDict["FVEndDate"] as! Date
                        }
                        else {
                            startDate = self.getDateFromJSON(vacayDict["FVStartDate"] as? String)!
                            endDate = self.getDateFromJSON(vacayDict["FVEndDate"] as? String)!
                        }
                        
                        let dff = DateFormatter()
                        dff.dateFormat = "yyyy-MM-dd'T'HH:mm"
                        dff.timeZone = TimeZone(abbreviation: "GMT")
                        let resultStart = dff.string(from: startDate)
                        let startDateFinal = dff.date(from: resultStart)!
                        let resultEnd = dff.string(from: endDate)
                        let endDateFinal = dff.date(from: resultEnd)!
                        
                        let vacay = BIVacation(context: self.bidPeriod!.managedObjectContext!)
                        if secretEnabled == "YES" {
                            let secretVacay = BIVacation(context: (self.bidPeriod?.managedObjectContext)!)
                        }
                        vacay.line = line
                        vacay.fvStartdate = startDateFinal
                        vacay.fvEnddate = endDateFinal
                        let length = (self.calendarData.daysBetweenDate(fromDateTime: startDateFinal, toDateTime: endDateFinal)) + 1
                        vacay.fvLength = length as NSNumber
                        self.bidPeriod?.containsVacay = true
                        self.bidPeriod?.containsFvVacay = true
                    }
                    // Calculate the line's total Front VO pay and Back VO
                    if (numVacayWeeks > 1) {
                        var frontVoPay: Float = 0.0
                        var backVoPay: Float = 0.0
                        
                        for i in 0..<numVacayWeeks {
                            let frontVoKey = String(format: "Front VO%@%d", (i == 0 ? "" : " "), i + 1)
                            let backVoKey = String(format: "Back VO%@%d", (i == 0 ? "" : " "), i + 1)
                            
                            let frontVoPayString = lineData[frontVoKey] as? String
                            if (frontVoPayString != nil) {
                                frontVoPay += frontVoPayString!.floatValue
                            }
                            let backVoPayString = lineData[backVoKey] as? String
                            if (backVoPayString != nil) {
                                backVoPay += backVoPayString!.floatValue
                            }
                            
                        }
                        line.vFrontVoPay = frontVoPay as NSNumber
                        line.vBackVoPay = backVoPay as NSNumber
                    }
                    else {
                        line.vFrontVoPay = lineData[frontVO] as? NSNumber
                        line.vBackVoPay = lineData[backVO] as? NSNumber
                    }
                    if (vacationType == "WBID" || vacationType == "WBIDF") {
                        line.vFrontVoPay = lineData["VOFront"] as? NSNumber
                        line.vBackVoPay = lineData["VOBack"] as? NSNumber
                    }
                    var workDays = (lineData[daysWorked_inmonth] as? NSNumber)?.intValue ?? 0
                    if (((lineData[daysWorked_inmonth] as? NSNumber)?.intValue) == nil) {
                        workDays = (lineData[daysWorked] as? NSNumber)?.intValue ?? 0
                    }
                    if (line.vTotalPay!.floatValue > 0 && workDays > 0) {
                        line.vPayPerDay = (line.vTotalPay!.floatValue) / Float(workDays) as? NSNumber
                    }
                    else if (workDays == 0) {
                        line.vPayPerDay = 0.0
                    }
                    
                    // Set up the droppped trips for Fv Vacation.
                    // Below the trip.vacationOverlapType is defined as default value
                    
                    if ((self.bidPeriod?.containsFvVacay) != nil) {
                        let trips = line.trips as? Set<BITrip> ?? []
                        let vacations = line.fvvacations as? Set<BIVacation> ?? []
                        
                        for vacay in vacations {
                            let fvStartdate = vacay.fvStartdate!
                            let fvEnddate = vacay.fvEnddate!
                            for trip in trips {
                                let dff = DateFormatter()
                                dff.dateFormat = "yyyy-MM-dd"
                                dff.timeZone = TimeZone(abbreviation: "GMT")
                                
                                
                                if let tripDate = trip.startDate,
                                   let normalizedDate = dff.date(from: dff.string(from: tripDate)),
                                   calendarData.date(date: normalizedDate, beginDate: fvStartdate, endDate: fvEnddate) == true {
                                    for day in trip.orderedDays {
                                        day.displayType = BIDayDisplayType.fullPay.rawValue as NSNumber
                                        trip.redEyeDayDisplayDayType = BIDayDisplayType.fullPay.rawValue as NSNumber
                                        trip.vacationOverlapType = BITripVacationOverlapType.full.rawValue as NSNumber
                                    }
                                }
                            }
                        }
                    }
                    
                    // Set up the trips if dropped
                    let rawPairingsPulled = vLine!["PairingsPulled"]
                    if rawPairingsPulled is String {
                        continue
                    }
                    let pairingsPulled = rawPairingsPulled as? [[String: Any]]
                    let trips = Array(line.trips as? Set<BITrip> ?? [])
                    for j in 0..<pairingsPulled!.count {
                        let df = DateFormatter()
                        df.dateFormat = "HHmmyyyyMMdd"
                        df.timeZone = self.calendarData.bidPeriodTimezone()
                        let pulledPairing = pairingsPulled![j]
                        let pairingNumber = pulledPairing["ID"] as? String
                        let tripNumberPredicate = NSPredicate(format: "info.number == %@", (pairingNumber)!)
                        let tripDateString = pulledPairing["PrDate"] as! String
                        let pullType = pulledPairing["PullType"] as? String
                        let tripDate = df.date(from: "1200\(tripDateString)")
                        let tripDatePredicate = NSPredicate(format: "startDate == %@", tripDate! as CVarArg)
                        
                        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [tripDatePredicate, tripNumberPredicate])
                        let filteredTrips = trips.filter { compoundPredicate.evaluate(with: $0) }
                        let trip = filteredTrips.first
                        
                        if (pullType == kPullTypeAll) {
                            trip?.vacationOverlapType = BITripVacationOverlapType.full.rawValue as NSNumber
                            trip?.dropForFiltersSorts = !includeDroppedTrips as NSNumber
                        }
                        else if (pullType == kPullTypeFront) {
                            trip?.vacationOverlapType = BITripVacationOverlapType.front.rawValue as NSNumber
                            trip?.dropForFiltersSorts = !includeDroppedTrips as NSNumber
                        }
                        else if (pullType == kPullTypeBack) {
                            trip?.vacationOverlapType = BITripVacationOverlapType.back.rawValue as NSNumber
                            trip?.dropForFiltersSorts = !includeDroppedTrips as NSNumber
                        }
                        // Get missingDate for RedEye Trips
                        var missingDateIndex = -1
                        var missingRedEyeDate: Date? = nil
                        if (trip != nil && trip!.isRedEyeTrip) {
                            missingDateIndex = CBUtils.findMissingIndex(inRedEyeTrip: trip!)
                            missingRedEyeDate = CBUtils.findMissingDate(forRedEyeTrip: trip!)
                        }
                        // Enumerate over the days and give them a value based on their status inside or
                        // outside the vacation and its overlap
                        
                        // Grab the vacation pieces
                        let vacationPieces = (vLine!["VacationPieces"] as? [[String: Any]])!
                        var displayTypes: [Int] = []
                        
                        for d in 0..<(trip?.orderedDays.count)! {
                            let day = trip?.orderedDays[d]
                            for k in 0..<vacationPieces.count {
                                let currentDictionary = vacationPieces[k] as [String: Any]
                                let label = (currentDictionary["Label"] as? String)!
                                let displayType = (currentDictionary["DisplayType"] as? String)!
                                let startDateString = (currentDictionary["FirstDay"] as? String)!
                                let endDateString = (currentDictionary["LastDay"] as? String)!
                                
                                let startDate = (df.date(from: "0000" + startDateString))!
                                let endDate = (df.date(from: "2359" + endDateString))!
                                
                                let displayDayType = self.getDisplayType(date: day!.date!, startDate: startDate, endDate: endDate, label: label, displayType: displayType)
                                if displayDayType != -1 {
                                    day?.displayType = displayDayType as NSNumber
//                                    day?.redEyeDayDisplayDayType = displayDayType as NSNumber
                                    displayTypes.append(displayDayType)
                                }
                                
                                if trip?.isRedEyeTrip == true{
                                    var calendar = Calendar(identifier: .gregorian)
                                    calendar.timeZone = TimeZone(secondsFromGMT: 0)! // UTC

                                    
                                    if missingDateIndex != -1 && missingRedEyeDate != nil && missingDateIndex == d{
                                        let displayDayType = self.getDisplayType(date: missingRedEyeDate!, startDate: startDate, endDate: endDate, label: label, displayType: displayType)
                                        if displayDayType != -1 {
                                            trip?.redEyeDayDisplayDayType = displayDayType as NSNumber
                                        }
                                    }
                                    if (d == trip?.orderedDays.count ?? 0 - 1 && day?.displayType?.intValue == BIDayDisplayType.normal.rawValue && label == kVaLabel) {
                                        if day?.date?.compare(endDate) == .orderedDescending {
                                            let calendar = Calendar.current
                                            // Normalize to 00:00:00
                                            let endDate = df.date(from: "0000\(endDateString)")
                                            let normalizedEndDate = calendar.startOfDay(for: endDate!)
                                            let normalizedDayDate = calendar.startOfDay(for: day!.date!)
                                            
                                            let afterDayDate =
                                                calendar.compare(normalizedDayDate, to: normalizedEndDate, toGranularity: .day) == .orderedDescending

                                            let diffWithDate = calendar.dateComponents([.day], from: normalizedEndDate, to: normalizedDayDate)
                                            if afterDayDate && diffWithDate.day == 1 {
                                                day?.displayType = BIDayDisplayType.fullPay.rawValue as NSNumber
                                                if missingDateIndex == d {
                                                    trip?.redEyeDayDisplayDayType = BIDayDisplayType.fullPay.rawValue as NSNumber
                                                }
                                            }
                                            else {
                                                day?.displayType = BIDayDisplayType.noPay.rawValue as NSNumber
                                                trip?.redEyeDayDisplayDayType = BIDayDisplayType.noPay.rawValue as NSNumber
                                            }
                                        }
                                    }
                                }
                            }
                            //                        End vacationPieces loop
                            
                            // If the day made it through all the vacation pieces without receiving
                            // a displayType then it must be a noPay day
                            if (day?.displayType?.intValue == BIDayDisplayType.normal.rawValue) {
                                day?.displayType = BIDayDisplayType.noPay.rawValue as NSNumber
                                displayTypes.append(BIDayDisplayType.noPay.rawValue)
                            }
                        } // End day loop
                        
                        // If the trip made it through all the vacation pieces without receiving
                        // a RedEye displayType then check previous and next day.
                        if trip?.redEyeDayDisplayDayType?.intValue == BIDayDisplayType.normal.rawValue  {
                            trip?.redEyeDayDisplayDayType = BIDayDisplayType.noPay.rawValue as NSNumber
                            
                            for d in 0..<(trip?.orderedDays.count ?? 0) {
                                if d <= displayTypes.count - 1 {
                                    if missingDateIndex != -1 && missingRedEyeDate != nil && missingDateIndex == d {
                                        let prevType = displayTypes[d - 1]
                                        let currentType = displayTypes[d - 1]
                                        let redEyeType = self.redEyeDisplayTypeFromPrev(prev: prevType, next: currentType)
                                        trip?.redEyeDayDisplayDayType = redEyeType as NSNumber
                                    }
                                }
                            }
                        }
                        
                    } // End pulled pairings loop
                }
                else {
                    break //display error to user and break
                }
                // Re-init the derived properties of the line, ignoring the dropped trips
                // RE-INIT the derived line properties, but ONLY IF the user doesn't want them in the default filters/sorts
                var globalBidInfo = GlobalBidInfo.shared
                let bidInfoReader = BIBidInfoReader()
                //            bidInfoReader.dataSource = self
                //            add global bid info if needed
                //            globalBidInfo.round = self.bidPeriod?.round as? Int ?? 0
                //            globalBidInfo.year = self.bidPeriod?.year as? Int ?? 2025
                //            globalBidInfo.month = self.bidPeriod?.month as? Int ?? 1
                //            globalBidInfo.position = self.bidPeriod?.positionType?.intValue ?? 0
                bidInfoReader.bidPeriod = self.bidPeriod
                bidInfoReader.calendarData = self.calendarData
                bidInfoReader.includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
                bidInfoReader.intlCities = (UserDefaults.standard.object(forKey: kCBInternationalCitiesDict) as? [String: Any])!
                
                if !UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey) {
                    bidInfoReader.initDerivedPropertiesForLine(line: line, isReprocessing: true)
                }
            } // End line loop
            
            if secretEnabled == "YES" {
                self.bidPeriod?.secretSwitchOn = "YES"
            }
            self.bidPeriod!.vacationType = vacationType
            self.bidPeriod!.vacationType = self.bidPeriod?.userVacationWbidOrCrewBid
            if moc!.hasChanges {
                do {
                    try moc!.save()
                    print("line core data saved from processJsonFile function in CBVacationDownloader")
                } catch {
                    print("line core data not saved from processJsonFile function in CBVacationDownloader: \(error)")
                }
            }
            // Get rid of any hidden vacation line values
            
//            let lineValuesKey = CBLineValuesMenuController.lineValuesKeyForBidPeriod(bidPeriod: self.bidPeriod!)
//            var lineValuesToDisplay = UserDefaults.standard.value(forKey: lineValuesKey) as? [Int]
//            var valuesToRemove: [Int] = []
//            for i in 0..<lineValuesToDisplay!.count {
//                let valueType = lineValuesToDisplay![i]
//                let lmvc = CBLineValuesMenuController()
//                if (lmvc.lineValueTypeIsHiddenForPilotVacation(valueType)) {
//                    valuesToRemove.append(valueType)
//                }
//            }
//            let filtered = lineValuesToDisplay?.filter { !valuesToRemove.contains($0) }
//            lineValuesToDisplay = filtered
        }
        else {
            if vacationType == "WBID" || vacationType == "WBIDF" {
                AlertService.showAlertForTopVC(title: "WBidMax Error", message: "The number of lines in the vacation file does not match the number of lines in the bid package. Please contact the support staff.")
            }
            else {
                AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The number of lines in the vacation file does not match the number of lines in the bid package. Please contact the support staff.")
//                21541
            }
        }
        print("done processing vacation json file")
    }
    
    //    MARK: getDisplayType
        func getDisplayType(date: Date, startDate: Date, endDate: Date, label: String, displayType: String) -> BIDayDisplayType.RawValue {
            var dayDisplayType = -1
            if (self.calendarData.date(date: date, beginDate: startDate, endDate: endDate) == true) {
                if label == kVaLabel {
                    dayDisplayType = BIDayDisplayType.fullPay.rawValue
                }
                else if label == kVoLabel {
                    if displayType == kFrontVoFull {
                        dayDisplayType = BIDayDisplayType.fullPay.rawValue
                    }
                    else if displayType == kBackVoFull {
                        dayDisplayType = BIDayDisplayType.fullPay.rawValue
                    }
                    else if (self.calendarData.daysBetweenDate(fromDateTime: startDate, toDateTime: startDate) > 0) {
                        if displayType == kFrontVoPartial {
                            let vaDc = self.calendarData.bidPeriodCalendar()!.dateComponents([.day], from: endDate)
                            let dayDc = self.calendarData.bidPeriodCalendar()!.dateComponents([.day], from: date)
                            
                            if (vaDc.day == dayDc.day) {
                                dayDisplayType = BIDayDisplayType.fullPay.rawValue
                            }
                            else {
                                dayDisplayType = BIDayDisplayType.partialPay.rawValue
                            }
                        }
                        else {
                            let vaDc = self.calendarData.bidPeriodCalendar()!.dateComponents([.day], from: startDate)
                            let dayDc = self.calendarData.bidPeriodCalendar()!.dateComponents([.day], from: date)
                            if (vaDc.day == dayDc.day) {
                                dayDisplayType = BIDayDisplayType.fullPay.rawValue
                            }
                            else {
                                dayDisplayType = BIDayDisplayType.partialPay.rawValue
                            }
                        }
                    }
                    else {
                        dayDisplayType = BIDayDisplayType.partialPay.rawValue
                    }
                }
            }
            return dayDisplayType
        }
    
    // Function to check if any date ranges overlap in an array of ranges
    func anyDateRangesOverlapping(vacations: [[String: Any]]) -> Bool {
        for i in 0..<vacations.count {
            for j in (i + 1)..<vacations.count {
                if areDateRangesOverlapping(range1: vacations[i], range2: vacations[j]) {
                    return true
                }
            }
        }
        return false
    }

    
    func areDateRangesOverlapping(range1: [String: Any],range2: [String: Any]) -> Bool {
        guard
            let start1 = getDateFromJSON(range1["FVStartDate"] as? String),
            let end1 = getDateFromJSON(range1["FVEndDate"] as? String),
            let start2 = getDateFromJSON(range2["FVStartDate"] as? String),
            let end2 = getDateFromJSON(range2["FVEndDate"] as? String)
        else {
            return false
        }

        return start1 <= end2 && start2 <= end1
    }

    
    func getDateFromJSON(_ string: String?) -> Date? {
        guard let string = string, string.count > 1 else {
            return nil
        }

        // Regular expression for matching /Date(1625140800000+0530)/ format
        let pattern = #"^\/date\((-?\d+)(?:([+-])(\d{2})(\d{2}))?\)\/$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(location: 0, length: string.utf16.count)
        guard let match = regex.firstMatch(in: string, options: [], range: range) else {
            return nil
        }

        // Extract milliseconds since epoch
        guard let millisRange = Range(match.range(at: 1), in: string),
              let milliseconds = Double(string[millisRange]) else {
            return nil
        }

        var seconds = milliseconds / 1000.0

        // If there's a timezone offset
        if match.range(at: 2).location != NSNotFound,
           let signRange = Range(match.range(at: 2), in: string),
           let hourRange = Range(match.range(at: 3), in: string),
           let minRange = Range(match.range(at: 4), in: string) {

            let sign = string[signRange]
            let hours = Double(string[hourRange]) ?? 0
            let minutes = Double(string[minRange]) ?? 0
            let offset = (hours * 3600.0) + (minutes * 60.0)

            seconds += (sign == "+" ? offset : -offset)
        }

        return Date(timeIntervalSince1970: seconds)
    }
    
    func mergeDateRanges(vacationDates: [[String: Any]]) -> [[String: Any]] {
        // Step 1: Convert dictionary dates to NSDate
        var datesArray: [[String: Any]] = []
        for dict in vacationDates {
            let startDate = self.getDateFromJSON(dict["FVStartDate"] as? String)
            let endDate = self.getDateFromJSON(dict["FVEndDate"] as? String)
            datesArray.append(["startDate": startDate, "endDate": endDate])
        }
            
            // Step 2: Sort the dates by start date
            let sortDescriptor = NSSortDescriptor(key: "startDate", ascending: true)
            let sortedDates = (datesArray as NSArray).sortedArray(using: [sortDescriptor])
            
            // Step 3: Merge overlapping or contiguous ranges
            var mergedDates: [[String: Any]] = []
            var currentRange = sortedDates.first as! [String: Any]
            for range in sortedDates {
                if let range = range as? [String: Any],
                    let currentStartDate = currentRange["startDate"] as? Date,
                    let currentEndDate = currentRange["endDate"] as? Date,
                    let nextStartDate = range["startDate"] as? Date,
                    let nextEndDate = range["endDate"] as? Date {
                    
                    if nextStartDate <= currentEndDate {
                        // Ranges overlap or are contiguous
                        currentRange = [
                            "startDate": currentStartDate,
                            "endDate": (nextEndDate > currentEndDate) ? nextEndDate : currentEndDate
                        ]
                    }
                    else {
                        // No overlap, add current range to merged list and update current range
                        mergedDates.append(currentRange)
                        currentRange = range
                    }
                }
            }
        mergedDates.append(currentRange) // Add the last range
        
        // Step 4: Convert merged date ranges back to dictionary format
        var results: [[String: Any]] = []
        for range in mergedDates {
            results.append(["FVStartDate": range["startDate"],"FVEndDate": range["endDate"]])
        }
        
        return results
    }
    
//    MARK: processFAVacationWithJsonFile
    func processFAVacationWithJsonFile(file: [String: Any]) {
        let thanksGivingDay = CBUtils.thanksgivingDay(for: self.bidPeriod?.year?.intValue ?? 0)
        var vacationType = self.bidPeriod!.userVacationWbidOrCrewBid ?? "FAVacation"
        var frontVO = ""
        var frontVO1 = ""
        var frontVO2 = ""
        var backVO = ""
        var backVO1 = ""
        var backVO2 = ""
        var carryoutVacationPay = ""
        var effectiveVacationLength = ""
        var longestBlockofDaysOff = ""
        var carryoutVOPay = ""
        var totalPay = ""
        var flyPay = ""
        var totalVacationPay = ""
        var carryOutPay_Flying = ""
        var totalDaysOff = ""
        var daysWorked_inmonth = ""
        var daysWorked = ""
        var lineName = ""
        var blockName = ""
        var vacPayBothBp = ""
//        var vacPayNeBp = ""
        var clawBack = ""
        
        var vAbo = ""
        var vAbp = ""
        var vAne = ""
        var vAPbo = ""
        var vAPbp = ""
        var vAPne = ""
        
        var vOFront = ""
        var vOFNe = ""
        var vOBack = ""
        var vOBNe = ""
        var vacay: BIVacation?

        
        if vacationType == "FAVacation" || vacationType == "FAVacationF" || vacationType == "FAVacationEomOnly" {
            lineName = "Line1";
            frontVO = "FrontVO";
            frontVO1 = "FrontVO1";
            frontVO2 = "FrontVO2";
            blockName = "Block";
            backVO = "BackVO";
            backVO1 = "BackVO1";
            backVO2 = "BackVO2";
            
            carryoutVacationPay = "CarryOutVacationPay";
            effectiveVacationLength = "EffectiveVacationLength";
            longestBlockofDaysOff = "LongestBlockofDaysOff";
            vacPayBothBp = "VacPayBothBp";
//            vacPayNeBp = "VacPayNeBp";
            carryoutVOPay = "CarryoutVOPay";
            totalPay = "TotalPay";
            flyPay = "FlyPay";
            totalVacationPay = "TotalVacationPay";
            carryOutPay_Flying = "CarryOutPay";
            totalDaysOff = "TotalDaysOff";
            
            daysWorked_inmonth = "DaysWorkedinMonth";
            daysWorked = "DaysWorked";
            
            clawBack = "ClawBack";
            
            vAbo = "VAbo";
            vAbp = "VAbp";
            vAne = "VAne";
            vAPbo = "VAPbo";
            vAPbp = "VAPbp";
            vAPne = "VAPne";
            
            vOFront = "VOFront";
            vOFNe = "VOFNe";
            vOBack = "VOBack";
            vOBNe = "VOBNe";
            
        }
        let moc = self.bidPeriod?.managedObjectContext
        let fetchRequest: NSFetchRequest<BITrip> = BITrip.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]

        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: moc!,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        do {
            try controller.performFetch()
            
            if let trips = controller.fetchedObjects as? [BITrip] {
                for trip in trips {
                    trip.vacationOverlapType = 0
                    trip.dropForFiltersSorts = false
                    
                    for case let day as BIDay in trip.days ?? [] {
                        day.displayType = BIDayDisplayType.normal.rawValue as NSNumber
                    }
                }
            }
            
        } catch {
            print("Failed to perform trip fetch: \(error)")
        }
        let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
        let header = topLevel["Header"] as! [String: Any]
        let numVacayWeeks = header["NumberVacationWeeks"] as? Int ?? 0
        self.bidPeriod?.numVacations = numVacayWeeks as NSNumber
        var vacayDates = header["VacationDates"] as! [[String: String]]
        
        // Figure out if we're going to hide some of the values based on the LineDataFields
        var lineDataFields: [String] = []
        lineDataFields = (header["LineDataFields"] as? [String])!
        var hiddenValues: [String: Any] = [:]
        
        //        carry out pay
        if lineDataFields.contains(carryOutPay_Flying) {
            hiddenValues[kCBSwaptmizerCarryOutPayHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerCarryOutPayHidden] = true
        }
        //        Front VO
        if lineDataFields.contains(frontVO) || lineDataFields.contains(frontVO1) || lineDataFields.contains(frontVO2) {
            hiddenValues[kCBSwaptmizerFrontVoHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerFrontVoHidden] = true
        }
        //        Back VO
        if lineDataFields.contains(backVO) || lineDataFields.contains(backVO1) || lineDataFields.contains(backVO2) {
            hiddenValues[kCBSwaptmizerBackVoHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerBackVoHidden] = true
        }
        //        Vaccay Carry Out Pay
        if lineDataFields.contains(carryoutVacationPay) {
            hiddenValues[kCBSwaptmizerVacayCarryOutPayHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerVacayCarryOutPayHidden] = true
        }
        //  Effective vacay length
        if lineDataFields.contains(effectiveVacationLength) {
            hiddenValues[kCBSwaptmizerEffVacayLengthHidden] = false
        }
        else {
            if vacationType == "WBID" || vacationType == "WBIDF" {
                hiddenValues[kCBSwaptmizerEffVacayLengthHidden] = false
            }
            else {
                hiddenValues[kCBSwaptmizerEffVacayLengthHidden] = true
            }
        }
//        // Vacation Pay Both BP
//        if lineDataFields.contains(vacPayBothBp) {
//            hiddenValues[kCBSwaptmizerVacPayBothBPHidden] = false
//        }
//        else {
//            if vacationType == "WBID" || vacationType == "WBIDF" {
//                hiddenValues[kCBSwaptmizerVacPayBothBPHidden] = false
//            }
//            else {
//                hiddenValues[kCBSwaptmizerVacPayBothBPHidden] = true
//            }
//        }
        //        ClawBack
        if vacationType == "WBID" || vacationType == "WBIDF" {
            hiddenValues[kCBSwaptmizerClawBackHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerClawBackHidden] = true
        }
        //Longest Block of Days Off
        if lineDataFields.contains(longestBlockofDaysOff) {
            hiddenValues[kCBSwaptmizerLongestBlockofDaysOffHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerLongestBlockofDaysOffHidden] = true
        }
        // Carry Out Vo Pay
        if lineDataFields.contains(carryoutVOPay) {
            hiddenValues[kCBSwaptmizerCarryOutVoHidden] = false
        }
        else {
            hiddenValues[kCBSwaptmizerCarryOutVoHidden] = true
        }
        UserDefaults.standard.set(hiddenValues, forKey: kCBSwaptimizerHiddenDict)
        
//       Delete all vacay
        let fetchRequestForVacation: NSFetchRequest<BIVacation> = BIVacation.fetchRequest()
        fetchRequestForVacation.includesPropertyValues = false
        do {
            let vacays = try self.bidPeriod?.managedObjectContext?.fetch(fetchRequestForVacation)
            for vacay in vacays! {
                moc?.delete(vacay)
            }
        } catch {
            print("vacation fetch failed: \(error)")
        }
        
        let vacayLines = topLevel["Lines"] as! [[String: Any]]
        let totalLinesToProcess = vacayLines.count * vacayDates.count
        var counter = 0
        var vacationTypeChanged = false
        
        for i in 0..<vacayDates.count {
            let df = DateFormatter()
            df.dateFormat = "HHmmyyyyMMdd"
            df.timeZone = self.calendarData.bidPeriodTimezone()
            let vacayDict = vacayDates[i]
            let startDateString = vacayDict["FirstDay"]!
            let endDateString = vacayDict["LastDay"]!
            let startDate = df.date(from: "1200" + startDateString)!
            let endDtStr = "2359" + endDateString
            let endDate = df.date(from: endDtStr)
            
            if vacationType == "FAVacationEomOnly" {
                if vacationTypeChanged == false {
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.year, .month, .day], from: startDate)
                    if (components.month == self.bidPeriod?.month?.intValue) {
                        vacationTypeChanged = true
                        self.bidPeriod?.userVacationWbidOrCrewBid = "FAVacationF"
                        self.bidPeriod?.vacationType = "FAVacationF"
                    }
                    
                }
            }
            //           not using nsEntityDescription for now, in case of error look obj-c
            let vacay = BIVacation(context: self.bidPeriod!.managedObjectContext!)
            vacay.bidPeriod = self.bidPeriod
            vacay.startDate = startDate
            vacay.endDate = endDate
            
//            vacationType = (self.bidPeriod?.userVacationWbidOrCrewBid)!
            vacay.vacationType = vacationType
            let length = (self.calendarData.daysBetweenDate(fromDateTime: startDate, toDateTime: endDate!)) + 1
            vacay.length = length as NSNumber
            
            self.bidPeriod?.containsVacay = true
        }
        
        UserDefaults.standard.set(false, forKey: kCBIncludeDroppedTripsInProcessingKey)

        let includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
        let lines = self.bidPeriod?.lines?.allObjects as? [AnyObject] ?? []
        var sortedLines = (lines as NSArray).sortedArray(using: [
            NSSortDescriptor(key: "number", ascending: true)
        ])
        let notBlankPredicate = NSPredicate(format: "type != %d", BILineType.BlankLine.rawValue)
        sortedLines = (sortedLines as NSArray).filtered(using: notBlankPredicate) as? [AnyObject] ?? []
        
        self.round = self.bidPeriod?.round
        self.year = self.bidPeriod?.year
        self.month = self.bidPeriod?.month
        self.position = self.bidPeriod?.positionType?.intValue
        self.base = self.bidPeriod?.base
        self.employeeNumber = self.bidPeriod?.swaptimizerIdentifier?.stringValue
        var globalBidInfo = GlobalBidInfo.shared
        let bidInfoReader = BIBidInfoReader()
        //            bidInfoReader.dataSource = self
        //            add global bid info if needed
        //            globalBidInfo.round = self.bidPeriod?.round as? Int ?? 0
        //            globalBidInfo.year = self.bidPeriod?.year as? Int ?? 2025
        //            globalBidInfo.month = self.bidPeriod?.month as? Int ?? 1
        //            globalBidInfo.position = self.bidPeriod?.positionType?.intValue ?? 0
        bidInfoReader.bidPeriod = self.bidPeriod
        bidInfoReader.calendarData = self.calendarData
        bidInfoReader.includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
        bidInfoReader.intlCities = (UserDefaults.standard.object(forKey: kCBInternationalCitiesDict) as? [String: Any])!
        
        // Reset the deadhead at start and end cities
        let fetchRequestForDeadHeadAtStart: NSFetchRequest<BIDeadheadAtStartCity> = BIDeadheadAtStartCity.fetchRequest()
        fetchRequestForDeadHeadAtStart.includesPropertyValues = false
        do {
            let cities = try self.bidPeriod?.managedObjectContext?.fetch(fetchRequestForDeadHeadAtStart)
            for city in cities! {
                moc?.delete(city)
            }
        } catch {
            print("deadhead at start city fetch failed: \(error)")
        }
        let fetchRequestForDeadHeadAtEnd: NSFetchRequest<BIDeadheadAtEndCity> = BIDeadheadAtEndCity.fetchRequest()
        fetchRequestForDeadHeadAtEnd.includesPropertyValues = false
        do {
            let cities = try self.bidPeriod?.managedObjectContext?.fetch(fetchRequestForDeadHeadAtEnd)
            for city in cities! {
                moc?.delete(city)
            }
        } catch {
            print("deadhead at end city fetch failed: \(error)")
        }
        if moc!.hasChanges {
            do {
                try moc?.save()
                print("deadhead at start and end cities saved")
            } catch {
                print("Error saving context: \(error)")
            }
        }
        // Iterate over all the lines and fill in the stuff we need to know
        var vEnumerator = vacayLines.makeIterator()
        for line in sortedLines as! [BILine] {
//          MARK: we can add progress if needed here
            var vLine = vEnumerator.next()
            let targetLine = line.number?.intValue ?? 0
            let resultArray = vacayLines.filter {
                ($0["Line1"] as? Int) == targetLine
            }
            if (resultArray.count == 0) {
                continue
            }
            vLine = resultArray[0]
            let vLineNumber = (vLine?[lineName] as? Int) ?? (vLine?[lineName] as? NSNumber)?.intValue ?? 0
            
            if (vLineNumber == line.number?.intValue) {
                let lineData = vLine?["LineData"] as! [String: Any]
                line.vTotalPay = lineData[totalPay] as? NSNumber
                line.pay = line.vTotalPay
                line.coHoli = 0
                line.vFlyPay = lineData[flyPay] as? NSNumber
                line.tripTfp = line.vFlyPay
                line.vVacationPay = lineData[totalVacationPay] as? NSNumber
                if let rig = line.lineRig?.floatValue, let vvp = line.vVacationPay?.floatValue {
                    line.vTpLPay = NSNumber(value: rig + vvp)
                }
                line.vCarryOutPay = lineData[carryOutPay_Flying] as? NSNumber
                if let vcop = line.vCarryOutPay?.floatValue, let lp = line.pay?.floatValue {
                    line.payPlusCo = NSNumber(value: vcop + lp)
                }
                if let cph = line.coHoli?.floatValue,
                   let cop = line.carryOutPay?.floatValue {
                    line.coPlusHoli = NSNumber(value: cph + cop)
                }
                line.vVacayCarryOutPay = lineData[carryoutVacationPay] as? NSNumber
                line.vVacayPayBothBP = lineData[vacPayBothBp] as? NSNumber
                line.vCarryOutVOPay = lineData[carryoutVOPay] as? NSNumber
                line.blockMinutes = lineData[blockName] as? NSNumber
                line.blockHours = line.blockMinutes!.floatValue / 60 as NSNumber
                line.vBlockTime = line.blockMinutes!.floatValue / 60 as NSNumber
                line.vDaysOff = lineData[totalDaysOff] as? NSNumber
                line.vEffectiveVacayLength = lineData[effectiveVacationLength] as? NSNumber
                line.vLongestBlockofDaysOff = lineData[longestBlockofDaysOff] as? NSNumber
                
                line.vAbp = lineData[vAbp] as? NSNumber
                line.vAne = lineData[vAne] as? NSNumber
                line.vAbo = lineData[vAbo] as? NSNumber
                line.vAPbp = lineData[vAPbp] as? NSNumber
                line.vAPne = lineData[vAPne] as? NSNumber
                line.vAPbo = lineData[vAPbo] as? NSNumber
                
                line.vOBcu = lineData[vOBack] as? NSNumber
                line.vOBne = lineData[vOBNe] as? NSNumber
                line.vOFcu = lineData[vOFront] as? NSNumber
                line.vOFne = lineData[vOFNe] as? NSNumber
                
                line.clawBack = lineData[clawBack] as? NSNumber
                let ane = line.vAne?.floatValue ?? 0
                let vacationPay = line.vVacationPay?.floatValue ?? 0
                line.vpCuPlusVaNe = NSNumber(value: ane + vacationPay)
                
                if (line.vTotalPay!.floatValue > 0 && line.vBlockTime!.intValue > 0) {
                    line.vPayPerBlock = (line.vTotalPay!.floatValue) / (line.vBlockTime?.floatValue)! as NSNumber
                }
                else {
                    line.vPayPerBlock = 0.0
                    line.payPerBlockHour = 0.0
                }
                
                // Calculate the line's total Front VO pay and Back VO
                if (numVacayWeeks > 1) {
                    var frontVoPay: Float = 0.0
                    var backVoPay: Float = 0.0
                    
                    for i in 0..<numVacayWeeks {
                        let frontVoKey = String(format: "Front VO%@%d", (i == 0 ? "" : " "), i + 1)
                        let backVoKey = String(format: "Back VO%@%d", (i == 0 ? "" : " "), i + 1)
                        
                        let frontVoPayString = lineData[frontVoKey] as? String
                        if (frontVoPayString != nil) {
                            frontVoPay += frontVoPayString!.floatValue
                        }
                        let backVoPayString = lineData[backVoKey] as? String
                        if (backVoPayString != nil) {
                            backVoPay += backVoPayString!.floatValue
                        }
                        
                    }
                    line.vFrontVoPay = frontVoPay as NSNumber
                    line.vBackVoPay = backVoPay as NSNumber
                }
                else {
                    line.vFrontVoPay = lineData[frontVO] as? NSNumber
                    line.vBackVoPay = lineData[backVO] as? NSNumber
                }
                if (vacationType == "FAVacation" || vacationType == "FAVacationF") {
                    line.vFrontVoPay = lineData["VOFront"] as? NSNumber
                    line.vBackVoPay = lineData["VOBack"] as? NSNumber
                }
                
                var workDays = (lineData[daysWorked_inmonth] as? NSNumber)?.intValue ?? 0
                if (((lineData[daysWorked_inmonth] as? NSNumber)?.intValue) == nil) {
                    workDays = (lineData[daysWorked] as? NSNumber)?.intValue ?? 0
                }
                if (line.vTotalPay!.floatValue > 0 && workDays > 0) {
                    line.vPayPerDay = (line.vTotalPay!.floatValue) / Float(workDays) as? NSNumber
                }
                else if (workDays == 0) {
                    line.vPayPerDay = 0.0
                }
                
                // Set up the trips if dropped
                let rawPairingsPulled = vLine!["PairingsPulled"]
                if rawPairingsPulled is String {
                    continue
                }
                let pairingsPulled = rawPairingsPulled as? [[String: Any]]
                let trips = Array(line.trips as? Set<BITrip> ?? [])
                for j in 0..<pairingsPulled!.count {
                    let df = DateFormatter()
                    df.dateFormat = "HHmmyyyyMMdd"
                    df.timeZone = self.calendarData.bidPeriodTimezone()
                    let pulledPairing = pairingsPulled![j]
                    let pairingNumber = pulledPairing["ID"] as? String
                    let tripNumberPredicate = NSPredicate(format: "info.number == %@", (pairingNumber)!)
                    let tripDateString = pulledPairing["PrDate"] as! String
                    let pullType = pulledPairing["PullType"] as? String
                    let tripDate = df.date(from: "1200\(tripDateString)")
                    let tripDatePredicate = NSPredicate(format: "startDate == %@", tripDate! as CVarArg)
                    
                    let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [tripDatePredicate, tripNumberPredicate])
                    let filteredTrips = trips.filter { compoundPredicate.evaluate(with: $0) }
                    let trip = filteredTrips.first
                   
                    if (pullType == kPullTypeAll) {
                        trip?.vacationOverlapType = BITripVacationOverlapType.full.rawValue as NSNumber
                        trip?.dropForFiltersSorts = !includeDroppedTrips as NSNumber
                    }
                    else if (pullType == kPullTypeFront) {
                        trip?.vacationOverlapType = BITripVacationOverlapType.front.rawValue as NSNumber
                        trip?.dropForFiltersSorts = !includeDroppedTrips as NSNumber
                    }
                    else if (pullType == kPullTypeBack) {
                        trip?.vacationOverlapType = BITripVacationOverlapType.back.rawValue as NSNumber
                        trip?.dropForFiltersSorts = !includeDroppedTrips as NSNumber
                    }
                    // Get missingDate for RedEye Trips
                    var missingDateIndex = -1
                    var missingRedEyeDate: Date? = nil
                    var tripDaysDate: [Date] = []
                    if (trip != nil && trip!.isRedEyeTrip == true) {
                        let missingDateIndex = CBUtils.findMissingDateAndIndex(forRedEyeTrip: trip!)
                        let missingRedEyeDate = CBUtils.findMissingDate(forRedEyeTrip: trip!)
                        tripDaysDate = self.getDayDatesFromTrip(trip: trip!)
                    }
                    // Enumerate over the days and give them a value based on their status inside or
                    // outside the vacation and its overlap
                    
                    // Grab the vacation pieces
                    let vacationPieces = (vLine!["VacationPieces"] as? [[String: Any]])!
                    if let trip = trip {
                        for d in 0..<(trip.orderedDays.count) {
                            let day = trip.orderedDays[d]
                            var currentDate = day.date
                            for k in 0..<vacationPieces.count {
                                let currentDictionary = vacationPieces[k] as [String: Any]
                                let label = (currentDictionary["Label"] as? String)!
                                let displayType = (currentDictionary["DisplayType"] as? String)!
                                let startDateString = (currentDictionary["FirstDay"] as? String)!
                                let endDateString = (currentDictionary["LastDay"] as? String)!
                                
                                let startDate = (df.date(from: "0000" + startDateString))!
                                let endDate = (df.date(from: "2359" + endDateString))!
                                
                                if (trip.isRedEyeTrip) {
                                    currentDate = tripDaysDate.indices.contains(d) ? tripDaysDate[d] : currentDate
                                    if (d == 0 && trip.startDate! < currentDate!) {
                                        currentDate = trip.startDate
                                    }
                                }
                                if (missingDateIndex != 0 && missingRedEyeDate != nil) {
                                    let lastDay = trip.orderedDays.last
                                    if let missingDate = missingRedEyeDate, let lastDate = lastDay?.date, missingDate < lastDate {
                                        let displayDayType = self.getDisplayType(date: missingRedEyeDate!, startDate: startDate, endDate: endDate, label: label, displayType: displayType)
                                        
                                        if (displayDayType != -1) {
                                            day.displayType = displayDayType as NSNumber
                                        }
                                    }
                                    else {
                                        let displayDayType = self.getDisplayType(date: currentDate!, startDate: startDate, endDate: endDate, label: label, displayType: displayType)
                                        if (displayDayType != -1) {
                                            day.displayType = displayDayType as NSNumber
                                        }
                                    }
                                }
                                else {
                                    let displayDayType = self.getDisplayType(date: currentDate!, startDate: startDate, endDate: endDate, label: label, displayType: displayType)
                                    if (displayDayType != -1) {
                                        day.displayType = displayDayType as NSNumber
                                    }
                                }
                            } // End vacationPieces loop
                            if (day.displayType?.intValue == BIDayDisplayType.normal.rawValue) {
                                day.displayType = BIDayDisplayType.noPay.rawValue as NSNumber
                            }
                        }// End day loop
                    }
                }// End pulled pairings loop
            }
            else {
                break
            }
            // Re-init the derived properties of the line, ignoring the dropped trips
            // RE-INIT the derived line properties, but ONLY IF the user doesn't want them in the default filters/sorts
            if !UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey) {
                bidInfoReader.initDerivedPropertiesForLine(line: line, isReprocessing: true)
            }
        }// End line loop
        
        self.bidPeriod?.vacationType = vacationType
        self.bidPeriod?.vacationType = self.bidPeriod?.userVacationWbidOrCrewBid
        if moc!.hasChanges {
            do {
                try moc?.save()
                print("line core data saved from processFAVacationWithJsonFile function in CBVacationDownloader")
            } catch {
                print("line core data not saved from processFAVacationWithJsonFile function in CBVacationDownloader: \(error)")
            }
        }
        // Get rid of any hidden vacation line values
        
//        let lineValuesKey = CBLineValuesMenuController.lineValuesKeyForBidPeriod(bidPeriod: self.bidPeriod!)
//        var lineValuesToDisplay = UserDefaults.standard.value(forKey: lineValuesKey) as? [Int]
//        var valuesToRemove: [Int] = []
//        for i in 0..<lineValuesToDisplay!.count {
//            let valueType = lineValuesToDisplay![i]
//            let lmvc = CBLineValuesMenuController()
//            if (lmvc.lineValueTypeIsHiddenForPilotVacation(valueType)) {
//                valuesToRemove.append(valueType)
//            }
//        }
//        let filtered = lineValuesToDisplay?.filter { !valuesToRemove.contains($0) }
//        lineValuesToDisplay = filtered
        self.bidPeriod?.faVacationStatus = BIFaVacationStatus.enabled.rawValue as NSNumber
        print("done processing fa vaction json file")
    }
    
    func getDayDatesFromTrip(trip: BITrip) -> [Date] {
        let missingDateIndex = CBUtils.findMissingIndex(inRedEyeTrip: trip)
        let missingRedEyeDate = CBUtils.findMissingDate(forRedEyeTrip: trip)
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = TimeZone(identifier: "US/Central")!
        var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate!)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "US/Central")
        
        var tripDates: [String] = []
        tripDates.reserveCapacity(4)
        var legIndex = 0
        
        for dayInfo in trip.info!.orderedDays() {
            for lengInfo in dayInfo.orderedLegs {
                dateComps.minute = lengInfo.departMinutes?.intValue
                let legStartDate = calendar.date(from: dateComps)!
                
                let legDateOnly = df.string(from: legStartDate)
                let startDateOnly = df.string(from: trip.startDate!)
                
                if legIndex == 0 {
                    if legDateOnly != startDateOnly {
                        tripDates.append(startDateOnly)
                    }
                    else {
                        tripDates.append(legDateOnly)
                    }
                }
                else {
                    tripDates.append(legDateOnly)
                }
                legIndex += 1
            }
        }
        let uniqueDatesSet = NSOrderedSet(array: tripDates)
        let uniqueDatesArray = uniqueDatesSet.array as? [String] ?? []
        
        var dateArray: [Date] = []
        // Parse back to date from "yyyy-MM-dd" string
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.timeZone = TimeZone(identifier: "US/Central")

        for dateStr in uniqueDatesArray {
            if let parsedDate = inputFormatter.date(from: dateStr) {
                var dateComps = calendar.dateComponents([.year, .month, .day], from: parsedDate)
                dateComps.hour = 0
                dateComps.minute = 0
                dateComps.second = 0

                if let finalDate = calendar.date(from: dateComps) {
                    dateArray.append(finalDate)
                }
            }
        }
        let lastDayDate = dateArray.last!
        
        if missingDateIndex != -1 && missingRedEyeDate! < lastDayDate {
            dateArray.insert(missingRedEyeDate!, at: missingDateIndex)
        }
        return dateArray
    }
    
    func deleteAllVacation() {
        DispatchQueue.main.async {
            guard let moc = self.bidPeriod?.managedObjectContext else { return }
            
            let fetchRequest: NSFetchRequest<BIVacation> = BIVacation.fetchRequest()
            fetchRequest.includesPropertyValues = false
            
            do {
                let results = try moc.fetch(fetchRequest)
                
                for vacation in results {
                    moc.delete(vacation)
                }
                
                if self.bidPeriod?.isFABid() == true {
                    self.bidPeriod?.faVacationStatus = NSNumber(value: BIFaVacationStatus.noVacation.rawValue)
                    UserDefaults.standard.set(true, forKey: kCBHideVacationKey)
                }
                
                self.bidPeriod?.swaptimizerStatus = NSNumber(value: CBSwaptimizerStatus.notApplicable.rawValue)
                self.bidPeriod?.vacationType = ""
                self.bidPeriod?.userVacationWbidOrCrewBid = ""
                
                try moc.save()
                
            } catch {
                print("Vacation fetch or save failed: \(error.localizedDescription)")
            }
        }
    }
    
    func eomMonth() -> String {
        let startDate = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        var components = calendar.dateComponents([.year, .month, .day], from: startDate)
        components.day = 1
        components.month = self.bidPeriod?.month?.intValue
        components.year = self.bidPeriod?.year?.intValue
        let originalDate = calendar.date(from: components)!
        var dateComponents = DateComponents()
        dateComponents.month = 1
        let newDate = calendar.date(byAdding: dateComponents, to: originalDate)
        let Updatedcomponents = calendar.dateComponents([.year, .month, .day], from: newDate!)
        return CBUtils.shortMonthName(month: Updatedcomponents.month!, uc: false)
    }
    
    func redEyeDisplayTypeFromPrev(prev: Int, next: Int) -> Int {
        // Full + Full → Full
        if prev == BIDayDisplayType.fullPay.rawValue && next == BIDayDisplayType.fullPay.rawValue {
            return BIDayDisplayType.fullPay.rawValue
        }
        // Half + Full → Full
        if prev == BIDayDisplayType.partialPay.rawValue && next == BIDayDisplayType.fullPay.rawValue {
            return BIDayDisplayType.fullPay.rawValue
        }
        // Full + Half → Full
        if prev == BIDayDisplayType.fullPay.rawValue && next == BIDayDisplayType.partialPay.rawValue {
            return BIDayDisplayType.fullPay.rawValue
        }
        // Full + NoPay → Half
        if prev == BIDayDisplayType.fullPay.rawValue && next == BIDayDisplayType.noPay.rawValue {
            return BIDayDisplayType.partialPay.rawValue
        }
        // NoPay + Full → Half
        if prev == BIDayDisplayType.noPay.rawValue && next == BIDayDisplayType.fullPay.rawValue {
            return BIDayDisplayType.partialPay.rawValue
        }
        // NoPay + Half → NoPay
        if prev == BIDayDisplayType.noPay.rawValue && next == BIDayDisplayType.partialPay.rawValue {
            return BIDayDisplayType.noPay.rawValue
        }
        // Half + NoPay → NoPay
        if prev == BIDayDisplayType.partialPay.rawValue && next == BIDayDisplayType.noPay.rawValue {
            return BIDayDisplayType.noPay.rawValue
        }
        // Default fallback
        return BIDayDisplayType.noPay.rawValue
    }
}
