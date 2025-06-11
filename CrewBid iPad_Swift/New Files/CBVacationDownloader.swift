//
//  CBVacationDownloader.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 22/05/25.
//

import Foundation
import CoreData

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
    var calendarData: BICalendarData = BICalendarData()
    var round: NSNumber?
    var year: NSNumber?
    var month: NSNumber?
    var position: Int?
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

    override init() {
        super.init()
        self.fetchAndPrintTripCount()
        let ab = dataSource.position
        let cb = dataSource.base
        print("base\(cb) postion\(ab)")
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<BIBidPeriod> = BIBidPeriod.fetchRequest()

        let targetRound = dataSource.round as NSNumber
        let targetMonth = dataSource.month as NSNumber
        let targetPosition = NSNumber(value: dataSource.position.rawValue)
        let targetBase = dataSource.base
        let targetYear = dataSource.year as NSNumber
        let targetEmployee = dataSource.employeeNumber

        fetchRequest.predicate = NSPredicate(
            format: "round == %@ AND month == %@ AND positionType == %@ AND base == %@ AND year == %@ AND crewIdentifier == %@",
            targetRound, targetMonth, targetPosition, targetBase, targetYear, targetEmployee
        )

        do {
            let results = try context.fetch(fetchRequest)
            self.bidPeriod = results.first
            if (self.bidPeriod != nil){
                print("Found bidPeriod: ")
            } else {
                print("No matching bidPeriod found.")
            }
        } catch {
            print("Fetch error: \(error)")
        }

     
    }
    func fetchAndPrintTripCount() {
        let context = CoreDataManager.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<BITrip> = BITrip.fetchRequest()

        do {
            let trips = try context.fetch(fetchRequest)
            print("Total BITrip count: \(trips.count)")
        } catch {
            print("Failed to fetch BITrip: \(error)")
        }
    }

    
    //MARK: download WBID VacationFiles
    func downloadWbidVacation() {
        let delayInSeconds = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            var vacationDetailDictionary: [String: Any] = [:]
            if(self.bidPeriod?.swaptimizerIdentifier == nil) {
                vacationDetailDictionary["EmpNum"] = self.bidPeriod?.crewIdentifier ?? 21541
            }
            else {
                vacationDetailDictionary["EmpNum"] = self.bidPeriod?.swaptimizerIdentifier ?? 21541
            }
            vacationDetailDictionary["Base"] = self.bidPeriod?.base ?? "ATL"
            if let rawValue = self.bidPeriod?.positionType?.intValue,
               let positionType = BICrewPositionType(rawValue: rawValue) {
                let shortName = CBUtils.shortName(for: positionType)
                vacationDetailDictionary["Position"] = shortName
            }
            vacationDetailDictionary["Position"] = "CP"
            vacationDetailDictionary["Year"] = self.bidPeriod?.year ?? 2025
            vacationDetailDictionary["Month"] = self.bidPeriod?.month ?? 7
            vacationDetailDictionary["FromApp"] = 5
            var round: String = ""
            if (self.bidPeriod?.round?.intValue == 1) {
                round = "M"
            }
            else if (self.bidPeriod?.round?.intValue == 2) {
                round = "S"
            }
            vacationDetailDictionary["Round"] = "M"
            
            let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "WBID"
            
            if vacationType == "WBID" {
                vacationDetailDictionary["isEOM"] = NSNumber(value: false)
            }
            else {
                vacationDetailDictionary["isEOM"] = NSNumber(value: true)
                vacationDetailDictionary["FAEOMStartDate"] = self.bidPeriod?.faEomSelectedDate
            }
            if (self.bidPeriod?.secretSwitchOn == "YES") {
                vacationDetailDictionary["EmpNum"] = self.bidPeriod?.crewIdentifier
            }
            //            MARK: Secret switch on in downloading wbid vacation file
            if self.bidPeriod?.secretSwitchOn == "YES" {
                if self.bidPeriod?.selectedSegmentVacType == "TestOtherWeeks" {
                    if let vacationName = self.bidPeriod?.vacationName, !(vacationName is NSNull) {
                        if vacationType == "WBID" {
                            var newString: String = ""
                            if ((self.bidPeriod?.vacationName?.hasSuffix("F")) != nil) {
                                if let name = self.bidPeriod?.vacationName {
                                    newString = String(name.dropLast())
                                }
                            }
                            else {
                                newString = (self.bidPeriod?.vacationName)!
                            }
                            vacationDetailDictionary["FileName"] = newString
                        }
                        
                    }
                    self.vactionDownloadType =  .downloadWbidVacation
                    //                    [self->Objdatabuilder DownloadWBidSecretVacationData: vacationDetailDictionary];
                }
                else {
                    self.vactionDownloadType = .downloadWbidVacation
                    //                    objDataBuilder.downloadWBidData(vacationDetailDictionary) { canDownloadVacation in
                    //                        if !canDownloadVacation {
                    //                            DispatchQueue.main.async {
                    //                                if self.bidPeriod.userVacationWbidOrCrewBid == "WBIDF" {
                    //                                    NotificationCenter.default.post(name: Notification.Name("EomDownloadFailedForNetWorkIssue"), object: self)
                    //                                }
                    //                            }
                    //                        }
                    //                    }
                }
                
            }
            else {
                self.vactionDownloadType = .downloadWbidVacation
                self.downloadWBidOrFAData(downloadWbidDetails: vacationDetailDictionary) { canDownload in
                    if(!canDownload) {
                        if self.bidPeriod?.userVacationWbidOrCrewBid == "WBIDF" {
                            print("network issue")
                        }
                    }
                }
                //                objDataBuilder.downloadWBidData(vacationDetailDictionary) { canDownloadVacation in
                //                    if !canDownloadVacation {
                //                        DispatchQueue.main.async {
                //                            if self.bidPeriod.userVacationWbidOrCrewBid == "WBIDF" {
                //                                NotificationCenter.default.post(name: Notification.Name("EomDownloadFailedForNetWorkIssue"), object: self)
                //                            }
                //                        }
                //                    }
                //                }
                
            }
            
        }
    }
    
    //    MARK: FA VAcationFile
    func downloadFAVacation() {
        let delayInSeconds = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            var vacationType = self.bidPeriod?.userVacationWbidOrCrewBid
            vacationType = "FAVacation"
            var vacationDetailDictionary: [String: Any] = [:]
            
            vacationDetailDictionary["EmpNum"] = self.bidPeriod?.crewIdentifier ?? 14313//31035
            vacationDetailDictionary["Base"] = self.bidPeriod?.base ?? "DEN"
            vacationDetailDictionary["Base"] = self.bidPeriod?.base ?? "DEN"
            if let rawValue = self.bidPeriod?.positionType?.intValue,
               let positionType = BICrewPositionType(rawValue: rawValue) {
                let shortName = CBUtils.shortName(for: positionType)
                vacationDetailDictionary["Position"] = shortName
            }
            vacationDetailDictionary["Position"] = "FA"
            vacationDetailDictionary["Year"] = self.bidPeriod?.year ?? 2025
            vacationDetailDictionary["Month"] = self.bidPeriod?.month ?? 7
            vacationDetailDictionary["FromApp"] = 5
            var round: String = ""
            if (self.bidPeriod?.round?.intValue == 1) {
                round = "M"
            }
            else if (self.bidPeriod?.round?.intValue == 2) {
                round = "S"
            }
            vacationDetailDictionary["Round"] = "M"
            if vacationType == "FAVacation" {
                vacationDetailDictionary["isEOM"] = NSNumber(value: false)
            }
            else {
                vacationDetailDictionary["isEOM"] = NSNumber(value: true)
                vacationDetailDictionary["FAEOMStartDate"] = self.bidPeriod?.faEomSelectedDate
            }
            self.vactionDownloadType = .downloadFAVacation
            self.downloadWBidOrFAData(downloadWbidDetails: vacationDetailDictionary) { canDownload in
                if(!canDownload) {
                    //                    if self.bidPeriod?.userVacationWbidOrCrewBid == "WBIDF" {
                    print("network issue")
                    //                    }
                }
                
            }
        }
    }
    
    //    MARK: downloadWBid OR FA Data
    func downloadWBidOrFAData(downloadWbidDetails: [String: Any], canDownloadVacation: @escaping (Bool) -> Void) {
        print("see me")
        var urlString = "GetCrewBidJsonVacFile"
        do {
            let data = try JSONSerialization.data(withJSONObject: downloadWbidDetails, options: [])
            guard let jsonString = String(data: data, encoding: .utf8) else {
                print("Failed to convert data to JSON string")
                canDownloadVacation(false)
                return
            }
            urlString = constructURLString(urlString: urlString)
            if !urlString.isEmpty {
                print("Internet is available")
                canDownloadVacation(true)
                self.postDataForVacationDownloading(urlName: urlString, jsonString: jsonString)
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
    
    func constructURLString(urlString: String) -> String {
        guard let domain = app.Domain else {
            print("Error: Domain is nil")
            return ""
        }
        let webData = app.webData
        let serviceURL = "\(domain)\(urlString)"
        let finalURLString = serviceURL.replacingOccurrences(of: " ", with: "%20")
        print(finalURLString)
        return finalURLString
    }
    
    func postDataForVacationDownloading(urlName: String, jsonString: String) {
        print("in post section")
        print(jsonString)
        
        guard let url = URL(string: urlName) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeoutVD)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("WBID OR FA DOWNLOAD FAILed")
                print("Request failed: \(error)")
                DispatchQueue.main.async {
                    // self.delegate?.connectionFailed()
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    // self.delegate?.connectionFailed()
                }
                return
            }
            // Debug print as string (optional)
            if let responseString = String(data: data as Data, encoding: .utf8) {
                print("Mutable Response String: \(responseString)")
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let fileName = json["FileName"], !(fileName is NSNull) {
                            print("Vacation FileName: \(fileName)")
                            let jsonData = json["JsonData"] as! [String: Any]
                            if self.vactionDownloadType == .downloadWbidVacation {
                                self.callToSetAutoDownloadOrValidateForWBID(jsonData: jsonData)
                            }
                            else if self.vactionDownloadType == .downloadFAVacation {
                                self.callToSetAutoDownloadOrValidateForFA(jsonData: jsonData)
                            }
                            
                        } else {
                            print("FileName is null or missing")
                            let message = json["Message"]
                            print("message: \(message!)")
                        }
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                }
            } else {
                print("Received binary mutable data of size: \(data) bytes")
            }
            
            // You can also store mutableData somewhere if needed
            // self.webData = mutableData (if applicable)
        }
        
        task.resume()
    }
    
    //    MARK: download crewbid Vacation file
    func downloadCrewbidVacationFiles(crewbidType: String) {
        self.bidPeriod?.userVacationWbidOrCrewBid = crewbidType
        let secretEnabled = self.bidPeriod?.secretSwitchOn ?? "NO"
        var pilot: NSNumber?
        
        var isEom = 1
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        if secretEnabled == "YES" {
            pilot = self.bidPeriod?.crewIdentifier
            pilot = 66226
            self.urlRequest = URLRequest(url: kSwaptimizerUrlTest, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeout)
        }
        else {
            pilot = self.bidPeriod?.swaptimizerIdentifier
            pilot = 44126//88463
            self.urlRequest = URLRequest(url: kSwaptimizerUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeout)
        }
        if((pilot == nil)) {
            print("not a valid pilot")
            return
        }
        let accessKey = kswaptimizerAccessKey
        let appVersion = CBUtils.AppVersion()
        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid
        if vacationType == "CREWBIDF" {
            isEom = 1
        }
        else {
            isEom = 0
        }
        let postDict: [String: Any] = ["Pilot": pilot ?? 88463, "CrewBidVersion": appVersion, "AccessKey": accessKey, "FWeek": isEom]
        self.urlRequest?.httpMethod = "POST"
        self.urlRequest?.setValue("text/plain", forHTTPHeaderField: "Accept")
        self.urlRequest?.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: postDict, options: [])
            self.urlRequest?.setValue("\(jsonData.count)", forHTTPHeaderField: "Content-Length")
            self.urlRequest?.httpBody = jsonData
            // Use jsonData here
        } catch {
            print("Error serializing JSON: \(error)")
        }
        let task = URLSession.shared.dataTask(with: self.urlRequest!) { (data, response, error) in
            if let error = error {
                print("WBID OR FA DOWNLOAD FAILed")
                print("Request failed: \(error)")
                DispatchQueue.main.async {
                    // self.delegate?.connectionFailed()
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    // self.delegate?.connectionFailed()
                }
                return
            }
            // Debug print as string (optional)
            if let responseString = String(data: data as Data, encoding: .utf8) {
                                print("Mutable Response String: \(responseString)")
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        let pilotInfo = json["PilotInfo"] as! [String: Any] //]["HasAccount"]
                        let hasAccount = (pilotInfo["HasAccount"] as? String == "1")
                        if hasAccount == false {
                            print("No swaptimizer account")
                        }
                        else {
                            print("Mutable Response String: \(responseString)")
                            self.callToSetAutoDownloadOrValidateForSwaptimizer(jsonData: json)
                        }
                    }
                }
                catch {
                    print("error finding has account while parsing")
                }
            }
        }
        task.resume()
    }
    
    //    MARK: callToSetAutoDownloadOrValidateForWBID()
    func callToSetAutoDownloadOrValidateForWBID(jsonData: [String: Any]) {
        if(isAutoDownload) {
            storeWBIDVacation(jsonData: jsonData)
        }
        else {
            validateWBIDVacation(jsonData: jsonData)
        }
    }
    
    //    MARK: callToSetAutoDownloadOrValidateFor FA vacation()
    func callToSetAutoDownloadOrValidateForFA(jsonData: [String: Any]) {
        if(isAutoDownload) {
            storeFAVacation(jsonData: jsonData)
        }
        else {
            validateFAVacation(jsonData: jsonData)
        }
    }
    
    //    MARK: callToSetAutoDownloadOrValidateFor swaptimizet()
    func callToSetAutoDownloadOrValidateForSwaptimizer(jsonData: [String: Any]) {
        if(isAutoDownload) {
           AutoValidateSWAPtimizerJSON(jsonData: jsonData)
        }
        else {
            validateSWAPtimizerJSON(jsonData: jsonData)
        }
    }
    
    //    MARK: storeWBIDVacation()
    func storeWBIDVacation(jsonData: [String: Any]) {
        let file = jsonData["File"] as! [String: Any]
        let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
        let header = topLevel["Header"] as! [String: Any]
        let moc = self.bidPeriod?.managedObjectContext
        self.bidPeriod?.faFileIntent = header["FileIdent"] as? String
        
        do {
            try moc?.save()
            print("filename saved")
        } catch {
            print("Error saving context: \(error)")
        }
        writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
        let isFlightAttendant = self.bidPeriod?.isFABid() ?? false
        if(!isFlightAttendant) {
            self.downloadCrewbidVacationFiles(crewbidType: "CREWBID")
        }
        
    }
    
    //    MARK: validateWBIDVacation
    func validateWBIDVacation(jsonData: [String: Any]) {
        let status = jsonData["Status"] as! [String: Any]
        let pilotInfo = jsonData["PilotInfo"] as! [String: Any]
        let configInfo = jsonData["ConfigInfo"] as! [String: Any]
        let statusCode = status["Code"] as! String
        let statusMsg = status["Msg"] as! String
        let hasAccount = (pilotInfo["HasAccount"] as? String == "1")
        let dataAvailable = (pilotInfo["DataAvailable"] as? NSNumber)?.boolValue ?? false
        let hasVacation = (pilotInfo["HasVacation"] as? NSNumber)?.boolValue ?? false
        //        let pilotIdentifier = pilotInfo["Pilot"] as? NSNumber)?.intValue ?? 0
        let pilotIdentifier = Int(pilotInfo["Pilot"] as? String ?? "") ?? 0
        
        let yearMonth = configInfo["YearMonth"] as! String
        let vacayYear = Int(yearMonth.prefix(4)) ?? 0
        let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
        let secretEnabled = self.bidPeriod?.secretSwitchOn
        
        if !(statusCode == "SUCCESS") {
            AlertService.showAlertForTopVC(title: "WBidmax Server Error", message: "\(statusMsg)\nWBidmax vacation usually releases data the evening of the 4th or morning of the 5th. If you are seeing this error before data release, please try again after data has been released.", actions: nil)
        }
        else if (pilotIdentifier != 21541 && !(secretEnabled == "YES")) {
//        else if (pilotIdentifier != self.bidPeriod?.swaptimizerIdentifier?.intValue && !(secretEnabled == "YES")) {
            //    The bid package for the wrong pilot got downloaded
            AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax user ID \(pilotIdentifier) does not match the pilot for whom the bid package was downloaded \(String(describing: self.bidPeriod?.swaptimizerIdentifier)).", actions: nil)
        }
//        else if (7 - vacayMonth == 1 || (7 == 1 && vacayMonth == 12)) {
        else if ((self.bidPeriod?.month?.intValue)! - vacayMonth == 1 || (self.bidPeriod?.month?.intValue == 1 && vacayMonth == 12)) {
            // New bid period but old month's data, so data is not yet available.
            // Alert view telling the user data is not yet available, check back later
            AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).", actions: nil)
        }
        else if !(hasVacation) {
            // Display StatusMsg to the user, there's an error
            var user = ""
            if (secretEnabled == "YES") {
                user = UserDefaults.standard.string(forKey: "SecretVDuserName") ?? ""
            }
            else {
                user = String(describing: self.bidPeriod?.swaptimizerIdentifier)
            }
            AlertService.showAlertForTopVC(title: "No Vacation", message: "No vacation next month for user \(user)", actions: nil)
        }
        else if (hasVacation && !hasAccount) {
            AlertService.showAlertForTopVC(title: "No MAX Subscription!", message: "We see that you have vacation this month, but you do not have a Max subscription.\nA Max subscription will give you access to the highly acclaimed WBidMax vacation predictions.\nTo get a Max subscription, go to www.crewbidmax.com and get a Max subscription.")
        }
        else if (hasVacation && hasAccount && !dataAvailable)
        {
            // Alert view telling the user data is not yet available, check back later
            AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
        }
        else if (hasVacation && hasAccount && dataAvailable)
        {
            // Check to make sure the data received is the proper file
            let seat = pilotInfo["Seat"] as! String
            let round = Int(configInfo["Round"] as? String ?? "") ?? 0
            let vacayBase = pilotInfo["Base"] as! String
            var rawValue = (self.bidPeriod?.positionType?.intValue)!
//            var rawValue = 0
            var positionType = BICrewPositionType(rawValue: rawValue)!
            let shortName = CBUtils.shortName(for: positionType) ?? "CM"
            
            if !(self.bidPeriod?.secretSwitchOn == "YES") {
//                if vacayMonth != 7 {
                if vacayMonth != self.bidPeriod?.month?.intValue ?? 0 {
                    AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax data month \(vacayMonth) is not the same as the bid period month \(String(describing: self.bidPeriod?.month))")
                }
//                else if (vacayYear != 2025) {
                else if (vacayYear != self.bidPeriod?.year?.intValue) {
                    AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax data year \(vacayYear) is not the same as the bid period year \(String(describing: self.bidPeriod?.year)).")
                }
//                else if !(vacayBase == "ATL") {
                    else if !(vacayBase == self.bidPeriod?.base) {
                    AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax data base \(vacayBase) is not the same as the bid period crew base \(String(describing: self.bidPeriod?.base)).")
                }
//                else if !("CA" == seat) {
                else if !(shortName == seat) {
                    AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The vacation data position \(seat) is not the same as the bid period position \(shortName).)")
                }
                else if (self.bidPeriod?.round?.intValue == 2 && round == 1)
                {
                    // It's round 2 but SWAPtimizer has not yet released round 1 data
                    // Alert view telling the user data is not yet available, check back later
                    AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
                }
//                else if (round != 7)
                else if (round != self.bidPeriod?.round?.intValue)
                {
                    AlertService.showAlertForTopVC(title: "WBidmax Error", message: "The vacation data round \(round) is not the same as the bid period round \(String(describing: self.bidPeriod?.round))")
                }
                else
                {
                    // Process the JSON file
                    let file = jsonData["File"] as! [String: Any]
                    let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
                    let header = topLevel["Header"] as! [String: Any]
                    let fileRound = header["Round"] as! Int
                    let fileYear = header["BidPeriodYear"] as! Int
                    let fileMonth = header["BidPeriodMonth"] as! Int
                    
                    if (fileRound != round) {
                        AlertService.showAlertForTopVC(title: "WBidmax File Mismatch", message: "The vacation round \(round) and WBidmax data file round \(fileRound) are mismatched. Perhaps you didn't bid a blank line?")
                    }
                    else if (fileYear != vacayYear) {
                        AlertService.showAlertForTopVC(title: "WBidmax File Mismatch", message: "The vacation year \(vacayYear) and WBidmax data file year \(fileYear) are mismatched. Perhaps you didn't bid a blank line?")
                    }
                    else if (fileMonth != vacayMonth) {
                        AlertService.showAlertForTopVC(title: "WBidmax File Mismatch", message: "The vacation month \(vacayMonth) and WBidmax data file month \(fileMonth) are mismatched. Perhaps you didn't bid a blank line?")
                    }
                    else {
                        let moc = self.bidPeriod?.managedObjectContext
                        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid;
                        if (vacationType == "WBID") {
                            self.bidPeriod?.wbFileIntent = header["FileIdent"] as? String
                        }
                        else {
                            self.bidPeriod?.wbFileIntentF = header["FileIdent"] as? String
                        }
                        do {
                            try moc?.save()
                            print("context in validat VWBID writevacationfile saved")
                        }
                        catch {
                            print("context in validat VWBID writevacationfile not saved: \(error)")
                        }
                        self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
                        if (isAutoDownload) {
                            self.downloadCrewbidVacationFiles(crewbidType: "CREWBID")
                        }
                        else {
                            let delayInSeconds = 0.1
                            DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                                self.processJsonFile(file: file)
                            }
                        }
                    }
                }
            }
            else {
                let file = jsonData["File"] as! [String: Any]
                let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
                let header = topLevel["Header"] as! [String: Any]
                
                let moc = self.bidPeriod?.managedObjectContext
                let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "WBID"
                if (vacationType == "WBID") {
                    self.bidPeriod?.wbFileIntent = header["FileIdent"] as? String
                }
                else {
                    self.bidPeriod?.wbFileIntentF = header["FileIdent"] as? String
                }
                self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
                self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.checked.rawValue as NSNumber
                
                let delayInSeconds = 0.1
                DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                    self.processJsonFile(file: file)
                }
                
                DispatchQueue.main.async {
                    do {
                        try moc?.save()
                        print("context in validat VWBID writevacationfile saved")
                    }
                    catch {
                        print("context in validat VWBID writevacationfile not saved: \(error)")
                    }
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
        do {
            try moc?.save()
            print("context writevacationfile saved")
        }
        catch {
            print("context writevacationfile not saved: \(error)")
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
        let notBlankPredicate = NSPredicate(format: "type != %d", BILineType.BlankLineType.rawValue)
        sortedLines = (sortedLines as NSArray).filtered(using: notBlankPredicate) as? [AnyObject] ?? []
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
        let notBlankPredicate = NSPredicate(format: "type != %d", BILineType.BlankLineType.rawValue)
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
                print("No match found for line \(lineNumber), JSON lines: \(vacayLines)")
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
        
        do {
            try moc?.save()
            print("filename saved")
        } catch {
            print("Error saving context: \(error)")
        }
        writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
    }
    
    func validateFAVacation(jsonData: [String: Any]) {
        let status = jsonData["Status"] as! [String: Any]
        let pilotInfo = jsonData["PilotInfo"] as! [String: Any]
        let configInfo = jsonData["ConfigInfo"] as! [String: Any]
        let statusCode = status["Code"] as! String
        //        let statusMsg = status["Msg"] as! String
        let hasAccount = (pilotInfo["HasAccount"] as? String == "1")
        let dataAvailable = (pilotInfo["DataAvailable"] as? NSNumber)?.boolValue ?? false
        let hasVacation = (pilotInfo["HasVacation"] as? NSNumber)?.boolValue ?? false
        //        let pilotIdentifier = (pilotInfo["Pilot"] as? NSNumber)?.intValue ?? 0
        let yearMonth = configInfo["YearMonth"] as! String
        let vacayYear = Int(yearMonth.prefix(4)) ?? 0
        let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
        let secretEnabled = self.bidPeriod?.secretSwitchOn
        
        if !(statusCode == "SUCCESS") {
            AlertService.showAlertForTopVC(title: "Crewbid Alert", message: "Vacation Files are NOT yet ready, check back in 2 more hours.", actions: nil)
        }
//        else if ((self.bidPeriod?.month?.intValue)! - vacayMonth == 1 || (self.bidPeriod?.month?.intValue == 1 && vacayMonth == 12)) {
//            // New bid period but old month's data, so data is not yet available.
//            // Alert view telling the user data is not yet available, check back later
//            AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "Vacation data is not yet available. Check back later.", actions: nil)
//        }
        else if !(hasVacation) {
            // Display StatusMsg to the user, there's an error
            var user = ""
            user = String(describing: self.bidPeriod?.swaptimizerIdentifier)
            AlertService.showAlertForTopVC(title: "No Vacation", message: "No vacation next month for user \(user)", actions: nil)
        }
        else if (hasVacation && hasAccount && !dataAvailable)
        {
            // Alert view telling the user data is not yet available, check back later
            AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
        }
        else if (hasVacation && hasAccount && dataAvailable)
        {
            // Check to make sure the data received is the proper file
            let seat = pilotInfo["Seat"] as! String
            let round = Int(configInfo["Round"] as? String ?? "") ?? 0
            let vacayBase = pilotInfo["Base"] as! String
            var rawValue = (self.bidPeriod?.positionType?.intValue)!
            var positionType = BICrewPositionType(rawValue: rawValue)!
            let shortName = CBUtils.shortName(for: positionType) ?? "CM"
            
            
            if vacayMonth != self.bidPeriod?.month?.intValue ?? 0 {
                AlertService.showAlertForTopVC(title: "Error", message: "The  data month \(vacayMonth) is not the same as the bid period month \(String(describing: self.bidPeriod?.month))")
            }
            else if (vacayYear != self.bidPeriod?.year?.intValue) {
                AlertService.showAlertForTopVC(title: " Error", message: "The  data year \(vacayYear) is not the same as the bid period year \(String(describing: self.bidPeriod?.year)).")
            }
            else if !(vacayBase == self.bidPeriod?.base) {
                AlertService.showAlertForTopVC(title: " Error", message: "The  data base \(vacayBase) is not the same as the bid period crew base \(String(describing: self.bidPeriod?.base)).")
            }
            else if !(shortName == seat) {
                AlertService.showAlertForTopVC(title: " Error", message: "The vacation data position \(seat) is not the same as the bid period position \(shortName).)")
            }
            else if (self.bidPeriod?.round?.intValue == 2 && round == 1)
            {
                // It's round 2 but SWAPtimizer has not yet released round 1 data
                // Alert view telling the user data is not yet available, check back later
                AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: " vacation data is not yet available. Check back later .")
            }
            else if (round != self.bidPeriod?.round?.intValue)
            {
                AlertService.showAlertForTopVC(title: " Error", message: "The vacation data round \(round) is not the same as the bid period round \(String(describing: self.bidPeriod?.round))")
            }
            else
            {
                // Process the JSON file
                let file = jsonData["File"] as! [String: Any]
                let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
                let header = topLevel["Header"] as! [String: Any]
                let fileRound = header["Round"] as! Int
                let fileYear = header["BidPeriodYear"] as! Int
                let fileMonth = header["BidPeriodMonth"] as! Int
                
                if (fileRound != round) {
                    AlertService.showAlertForTopVC(title: "File Mismatch", message: "The vacation round \(round) and  data file round \(fileRound) are mismatched. Perhaps you didn't bid a blank line?")
                }
                else if (fileYear != vacayYear) {
                    AlertService.showAlertForTopVC(title: "File Mismatch", message: "The vacation year \(vacayYear) and  data file year \(fileYear) are mismatched. Perhaps you didn't bid a blank line?")
                }
                else if (fileMonth != vacayMonth) {
                    AlertService.showAlertForTopVC(title: "File Mismatch", message: "The vacation month \(vacayMonth) and  data file month \(fileMonth) are mismatched. Perhaps you didn't bid a blank line?")
                }
                else {
                    let moc = self.bidPeriod?.managedObjectContext
                    let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "FAVacation"
                    if (vacationType == "FAVacation") {
                        self.bidPeriod?.faFileIntent = header["FileIdent"] as? String
                    }
                    else if (vacationType == "FAVacationF") {
                        self.bidPeriod?.faFileIntentF = header["FileIdent"] as? String
                    }
                    else if (vacationType == "FAVacationEomOnly") {
                        self.bidPeriod?.faFileIntentEomOnly = header["FileIdent"] as? String
                    }
                    do {
                        try moc?.save()
                        print("context in validat VWBID writevacationfile saved")
                    }
                    catch {
                        print("context in validat VWBID writevacationfile not saved: \(error)")
                    }
                    self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
                    
                    let delayInSeconds = 0.1
                    DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                        self.processFAVacationWithJsonFile(file: file)
                    }
                }
            }
        }
    }
    
    //    MARK: validateSWAPtimizerJSON
    func validateSWAPtimizerJSON(jsonData: [String: Any]) {
        let status = jsonData["Status"] as! [String: Any]
        let pilotInfo = jsonData["PilotInfo"] as! [String: Any]
        let configInfo = jsonData["ConfigInfo"] as! [String: Any]
        let statusCode = status["Code"] as! String
        let statusMsg = status["Msg"] as! String
        let hasAccount = (pilotInfo["HasAccount"] as? String == "1")
        let dataAvailable = (pilotInfo["DataAvailable"] as? NSNumber)?.boolValue ?? false
        let hasVacation = (pilotInfo["HasVacation"] as? NSNumber)?.boolValue ?? false
        //        let pilotIdentifier = pilotInfo["Pilot"] as? NSNumber)?.intValue ?? 0
        var pilotIdentifier = Int(pilotInfo["Pilot"] as? String ?? "") ?? 0
        
        let yearMonth = configInfo["YearMonth"] as! String
        let vacayYear = Int(yearMonth.prefix(4)) ?? 0
        let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
        let secretEnabled = self.bidPeriod?.secretSwitchOn
        
        if self.bidPeriod?.secretSwitchOn == "YES" {
            pilotIdentifier = self.bidPeriod?.swaptimizerIdentifier?.intValue ?? 0
        }
        
        if !(statusCode == "SUCCESS") {
            AlertService.showAlertForTopVC(title: "SWAPtimizer Server Error", message: "\(statusMsg)\n SWAPtimizer vacation usually releases data the evening of the 4th or morning of the 5th. If you are seeing this error before data release, please try again after data has been released.", actions: nil)
        }
        else if (pilotIdentifier != self.bidPeriod?.swaptimizerIdentifier?.intValue) {
            //    The bid package for the wrong pilot got downloaded
            AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The SWAPtimizer user ID \(pilotIdentifier) does not match the pilot for whom the bid package was downloaded \(String(describing: self.bidPeriod?.swaptimizerIdentifier)).", actions: nil)
        }
        else if ((self.bidPeriod?.month?.intValue)! - vacayMonth == 1 || (self.bidPeriod?.month?.intValue == 1 && vacayMonth == 12)) {
            // New bid period but old month's data, so data is not yet available.
            // Alert view telling the user data is not yet available, check back later
            AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later via the Bid Actions menu(top right).", actions: nil)
        }
        else if !(hasVacation) {
            // Display StatusMsg to the user, there's an error
            var user = String(describing: self.bidPeriod?.swaptimizerIdentifier)
            AlertService.showAlertForTopVC(title: "No Vacation", message: "No vacation next month for user \(user)", actions: nil)
        }
        else if (hasVacation && !hasAccount) {
            AlertService.showAlertForTopVC(title: "No SWAPtimizer Account!", message: "We see that you have vacation this month, but you do not have SWAPtimizer Account.\nSWAPtimizer is the gold standard of SWA vacation prediction and we highly recommend their product. Go to www.swaptimizer.com to sign up!")
        }
        else if (hasVacation && hasAccount && !dataAvailable)
        {
            // Alert view telling the user data is not yet available, check back later
            AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
        }
        else if (hasVacation && hasAccount && dataAvailable)
        {
            // Check to make sure the data received is the proper file
            let seat = pilotInfo["Seat"] as! String
            let round = Int(configInfo["Round"] as? String ?? "") ?? 0
            let vacayBase = pilotInfo["Base"] as! String
            var rawValue = (self.bidPeriod?.positionType?.intValue)!
            var positionType = BICrewPositionType(rawValue: rawValue)!
            let shortName = CBUtils.shortName(for: positionType) ?? "CM"
            
            if !(self.bidPeriod?.secretSwitchOn == "YES") {
                if vacayMonth != self.bidPeriod?.month?.intValue ?? 0 {
                    AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The SWAPtimizer data month \(vacayMonth) is not the same as the bid period month \(String(describing: self.bidPeriod?.month))")
                }
                else if (vacayYear != self.bidPeriod?.year?.intValue) {
                    AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The SWAPtimizer data year \(vacayYear) is not the same as the bid period year \(String(describing: self.bidPeriod?.year)).")
                }
                else if !(vacayBase == self.bidPeriod?.base) {
                    AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The SWAPtimizer data base \(vacayBase) is not the same as the bid period crew base \(String(describing: self.bidPeriod?.base)).")
                }
                else if !(shortName == seat) {
                    AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The vacation data position \(seat) is not the same as the bid period position \(shortName).)")
                }
                else if (self.bidPeriod?.round?.intValue == 2 && round == 1)
                {
                    // It's round 2 but SWAPtimizer has not yet released round 1 data
                    // Alert view telling the user data is not yet available, check back later
                    AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
                }
                else if (round != self.bidPeriod?.round?.intValue)
                {
                    AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The vacation data round \(round) is not the same as the bid period round \(String(describing: self.bidPeriod?.round))")
                }
                else
                {
                    // Process the JSON file
                    let file = jsonData["File"] as! [String: Any]
                    let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
                    let header = topLevel["Header"] as! [String: Any]
                    let fileRound = header["Round"] as! Int
                    let fileYear = header["BidPeriodYear"] as! Int
                    let fileMonth = header["BidPeriodMonth"] as! Int
                    
                    if (fileRound != round) {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer File Mismatch", message: "The vacation round \(round) and SWAPtimizer data file round \(fileRound) are mismatched. Perhaps you didn't bid a blank line?")
                    }
                    else if (fileYear != vacayYear) {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer File Mismatch", message: "The vacation year \(vacayYear) and SWAPtimizer data file year \(fileYear) are mismatched. Perhaps you didn't bid a blank line?")
                    }
                    else if (fileMonth != vacayMonth) {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer File Mismatch", message: "The vacation month \(vacayMonth) and SWAPtimizer data file month \(fileMonth) are mismatched. Perhaps you didn't bid a blank line?")
                    }
                    else {
                        let moc = self.bidPeriod?.managedObjectContext
                        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid;
                        if (vacationType == "CREWBID") {
                            self.bidPeriod?.cbFileIntent = header["FileIdent"] as? String
                        }
                        else if vacationType == "CREWBIDF" {
                            self.bidPeriod?.cbFileIntentF = header["FileIdent"] as? String
                        }
                        do {
                            try moc?.save()
                            print("context in validat SWAPtimizer writevacationfile saved")
                        }
                        catch {
                            print("context in validat SWAPtimizer writevacationfile not saved: \(error)")
                        }
                        
                        self.captureVacationDetails(jsonData: jsonData)
                        
                        self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
                        self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.checked.rawValue as NSNumber
                
                            let delayInSeconds = 0.1
                            DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                                if (self.isAutoDownload && ((self.bidPeriod?.wbFileIntent) != nil)) {
                                    self.bidPeriod?.userVacationWbidOrCrewBid = "WBID"
                                    let dicVactionFile = self.readVacationFile(fileName: self.bidPeriod?.wbFileIntent ?? "")
                                    self.validateWBIDVacation(jsonData: dicVactionFile ?? [:])
                                    return
                                }
                                let isFA = self.bidPeriod?.isFABid() ?? false
                                if(isFA) {
                                    self.processFAVacationWithJsonFile(file: file)
                                }
                                else {
                                    self.processJsonFile(file: file)
                                }
                            }
                    }
                }
            }
            else {
                // Process the JSON file Secret Vacation download
                let file = jsonData["File"] as! [String: Any]
                let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
                let header = topLevel["Header"] as! [String: Any]
                
                let moc = self.bidPeriod?.managedObjectContext
                let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "CREWBID"
                if (vacationType == "CREWBID") {
                    self.bidPeriod?.wbFileIntent = header["FileIdent"] as? String
                }
                else if (vacationType == "CREWBIDF") {
                    self.bidPeriod?.wbFileIntentF = header["FileIdent"] as? String
                }
                do {
                    try moc?.save()
                    print("context in validat VWBID writevacationfile saved")
                }
                catch {
                    print("context in validat VWBID writevacationfile not saved: \(error)")
                }
                self.captureVacationDetails(jsonData: jsonData)
                self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
                self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.checked.rawValue as NSNumber
                
                let delayInSeconds = 0.1
                DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                    if (self.isAutoDownload && ((self.bidPeriod?.wbFileIntent) != nil)) {
                        let dicVactionFile = self.readVacationFile(fileName: self.bidPeriod?.wbFileIntent ?? "")
                        self.validateWBIDVacation(jsonData: dicVactionFile ?? [:])
                        return
                    }
                    self.processJsonFile(file: file)
                }
                
            }
        }
    }
    
    //    MARK: Auto validateSWAPtimizerJSON
    func AutoValidateSWAPtimizerJSON(jsonData: [String: Any]) {
        let status = jsonData["Status"] as! [String: Any]
        let pilotInfo = jsonData["PilotInfo"] as! [String: Any]
        let configInfo = jsonData["ConfigInfo"] as! [String: Any]
        let statusCode = status["Code"] as! String
        let statusMsg = status["Msg"] as! String
        let hasAccount = (pilotInfo["HasAccount"] as? String == "1")
        let dataAvailable = (pilotInfo["DataAvailable"] as? NSNumber)?.boolValue ?? false
        let hasVacation = (pilotInfo["HasVacation"] as? NSNumber)?.boolValue ?? false
        //        let pilotIdentifier = pilotInfo["Pilot"] as? NSNumber)?.intValue ?? 0
        var pilotIdentifier = Int(pilotInfo["Pilot"] as? String ?? "") ?? 0
        
        let yearMonth = configInfo["YearMonth"] as! String
        let vacayYear = Int(yearMonth.prefix(4)) ?? 0
        let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
        let secretEnabled = self.bidPeriod?.secretSwitchOn
        
        if self.bidPeriod?.secretSwitchOn == "YES" {
            pilotIdentifier = self.bidPeriod?.swaptimizerIdentifier?.intValue ?? 0
        }
        
        if !(statusCode == "SUCCESS") {
            if (self.bidPeriod?.wbFileIntent == nil) {
                AlertService.showAlertForTopVC(title: "SWAPtimizer Server Error", message: "\(statusMsg)\n SWAPtimizer vacation usually releases data the evening of the 4th or morning of the 5th. If you are seeing this error before data release, please try again after data has been released.", actions: nil)
            }
        }
        else if (pilotIdentifier != self.bidPeriod?.swaptimizerIdentifier?.intValue) {
            //    The bid package for the wrong pilot got downloaded
            if (self.bidPeriod?.wbFileIntent != nil) {
                AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The SWAPtimizer user ID \(pilotIdentifier) does not match the pilot for whom the bid package was downloaded \(String(describing: self.bidPeriod?.swaptimizerIdentifier)).", actions: nil)
            }
        }
        else if ((self.bidPeriod?.month?.intValue)! - vacayMonth == 1 || (self.bidPeriod?.month?.intValue == 1 && vacayMonth == 12)) {
            // New bid period but old month's data, so data is not yet available.
            // Alert view telling the user data is not yet available, check back later
            if (self.bidPeriod?.wbFileIntent != nil) {
                AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later via the Bid Actions menu(top right).", actions: nil)
            }
        }
        else if !(hasVacation) {
            // Display StatusMsg to the user, there's an error
            let user = String(describing: self.bidPeriod?.swaptimizerIdentifier)
            if (self.bidPeriod?.wbFileIntent != nil) {
                AlertService.showAlertForTopVC(title: "No Vacation", message: "No vacation next month for user \(user)", actions: nil)
            }
        }
        else if (hasVacation && !hasAccount) {
            if (self.bidPeriod?.wbFileIntent != nil) {
                AlertService.showAlertForTopVC(title: "No SWAPtimizer Account!", message: "We see that you have vacation this month, but you do not have SWAPtimizer Account.\nSWAPtimizer is the gold standard of SWA vacation prediction and we highly recommend their product. Go to www.swaptimizer.com to sign up!")
            }
        }
        else if (hasVacation && hasAccount && !dataAvailable)
        {
            // Alert view telling the user data is not yet available, check back later
            if (self.bidPeriod?.wbFileIntent != nil) {
                AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
            }
        }
        else if (hasVacation && hasAccount && dataAvailable)
        {
            // Check to make sure the data received is the proper file
            let seat = pilotInfo["Seat"] as! String
            let round = Int(configInfo["Round"] as? String ?? "") ?? 0
            let vacayBase = pilotInfo["Base"] as! String
            let rawValue = (self.bidPeriod?.positionType?.intValue)!
            let positionType = BICrewPositionType(rawValue: rawValue)!
            let shortName = CBUtils.shortName(for: positionType) ?? "CM"
            
            if !(self.bidPeriod?.secretSwitchOn == "YES") {
                if vacayMonth != self.bidPeriod?.month?.intValue ?? 0 {
                    if (self.bidPeriod?.wbFileIntent != nil) {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The SWAPtimizer data month \(vacayMonth) is not the same as the bid period month \(String(describing: self.bidPeriod?.month))")
                    }
                }
                else if (vacayYear != self.bidPeriod?.year?.intValue) {
                    if (self.bidPeriod?.wbFileIntent != nil) {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The SWAPtimizer data year \(vacayYear) is not the same as the bid period year \(String(describing: self.bidPeriod?.year)).")
                    }
                }
                else if !(vacayBase == self.bidPeriod?.base) {
                    if (self.bidPeriod?.wbFileIntent != nil) {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The SWAPtimizer data base \(vacayBase) is not the same as the bid period crew base \(String(describing: self.bidPeriod?.base)).")
                    }
                }
                else if !(shortName == seat) {
                    if (self.bidPeriod?.wbFileIntent != nil) {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The vacation data position \(seat) is not the same as the bid period position \(shortName).)")
                    }
                }
                else if (self.bidPeriod?.round?.intValue == 2 && round == 1)
                {
                    // It's round 2 but SWAPtimizer has not yet released round 1 data
                    // Alert view telling the user data is not yet available, check back later
                    if (self.bidPeriod?.wbFileIntent != nil) {
                        AlertService.showAlertForTopVC(title: "Data Not Yet Available", message: "SWAPtimizer vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
                    }
                }
                else if (round != self.bidPeriod?.round?.intValue)
                {
                    if (self.bidPeriod?.wbFileIntent != nil) {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer Error", message: "The vacation data round \(round) is not the same as the bid period round \(String(describing: self.bidPeriod?.round))")
                    }
                }
                else
                {
                    // Process the JSON file
                    let file = jsonData["File"] as! [String: Any]
                    let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
                    let header = topLevel["Header"] as! [String: Any]
                    let fileRound = header["Round"] as! Int
                    let fileYear = header["BidPeriodYear"] as! Int
                    let fileMonth = header["BidPeriodMonth"] as! Int
                    
                    if (fileRound != round) {
                        if (self.bidPeriod?.wbFileIntent != nil) {
                            AlertService.showAlertForTopVC(title: "SWAPtimizer File Mismatch", message: "The vacation round \(round) and SWAPtimizer data file round \(fileRound) are mismatched. Perhaps you didn't bid a blank line?")
                        }
                    }
                    else if (fileYear != vacayYear) {
                        if (self.bidPeriod?.wbFileIntent != nil) {
                            AlertService.showAlertForTopVC(title: "SWAPtimizer File Mismatch", message: "The vacation year \(vacayYear) and SWAPtimizer data file year \(fileYear) are mismatched. Perhaps you didn't bid a blank line?")
                        }
                    }
                    else if (fileMonth != vacayMonth) {
                        if (self.bidPeriod?.wbFileIntent != nil) {
                            AlertService.showAlertForTopVC(title: "SWAPtimizer File Mismatch", message: "The vacation month \(vacayMonth) and SWAPtimizer data file month \(fileMonth) are mismatched. Perhaps you didn't bid a blank line?")
                        }
                    }
                    else {
                        let moc = self.bidPeriod?.managedObjectContext
                        self.bidPeriod?.cbFileIntent = header["FileIdent"] as? String
                        
                        do {
                            try moc?.save()
                            print("context in validat SWAPtimizer writevacationfile saved")
                        }
                        catch {
                            print("context in validat SWAPtimizer writevacationfile not saved: \(error)")
                        }
                        
                        self.captureVacationDetails(jsonData: jsonData)
                        
                        self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
                        self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.checked.rawValue as NSNumber
                
                            let delayInSeconds = 0.1
                            DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                                if (self.isAutoDownload && ((self.bidPeriod?.wbFileIntent) != nil)) {
                                    self.bidPeriod?.userVacationWbidOrCrewBid = "WBID"
                                    let dicVactionFile = self.readVacationFile(fileName: self.bidPeriod?.wbFileIntent ?? "")
                                    self.validateWBIDVacation(jsonData: dicVactionFile ?? [:])
                                    return
                                }
                                let isFA = self.bidPeriod?.isFABid() ?? false
                                if(isFA) {
                                    self.processFAVacationWithJsonFile(file: file)
                                }
                                else {
                                    self.processJsonFile(file: file)
                                }
                            }
                    }
                }
            }
            else {
                // Process the JSON file Secret Vacation download
                let file = jsonData["File"] as! [String: Any]
                let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
                let header = topLevel["Header"] as! [String: Any]
                
                let moc = self.bidPeriod?.managedObjectContext
                self.bidPeriod?.cbFileIntent = header["FileIdent"] as? String
                do {
                    try moc?.save()
                    print("context in validat VWBID writevacationfile saved")
                }
                catch {
                    print("context in validat VWBID writevacationfile not saved: \(error)")
                }
                self.captureVacationDetails(jsonData: jsonData)
                self.writeVacationFile(jsonData: jsonData, fileName: header["FileIdent"] as! String)
                self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.checked.rawValue as NSNumber
                
                let delayInSeconds = 0.1
                DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                    if (self.isAutoDownload && ((self.bidPeriod?.wbFileIntent) != nil)) {
                        let dicVactionFile = self.readVacationFile(fileName: self.bidPeriod?.wbFileIntent ?? "")
                        self.validateWBIDVacation(jsonData: dicVactionFile ?? [:])
                        return
                    }
                    self.processJsonFile(file: file)
                }
                
            }
        }
    
    }
    
    func captureVacationDetails(jsonData: [String: Any]) {
        let app = UIApplication.shared.delegate as! AppDelegate
        let file = jsonData["File"] as! [String: Any]
        let topLevel = file["SWAPtimizer_CrewBid_Data"] as! [String: Any]
        let header = topLevel["Header"] as! [String: Any]
        var dicVacationDetails: [String: Any] = [:]
        var sampleDic : [String: Any] = [:]
        sampleDic["Test"] = "Test"
        var pilotInfo = jsonData["PilotInfo"] as! [String: Any]
        dicVacationDetails["EmpNum"] = Int(pilotInfo["Pilot"] as? String ?? "") ?? 0
        dicVacationDetails["Base"] = header["Base"]
        dicVacationDetails["Month"] = Int(header["BidPeriodMonth"] as? String ?? "") ?? 0
        dicVacationDetails["Year"] = Int(header["BidPeriodYear"] as? String ?? "") ?? 0
        dicVacationDetails["Round"] = Int(header["Round"] as? String ?? "") ?? 0
        var position = pilotInfo["Seat"] as? String ?? ""
        
        if(position == "CA") {
            position = "CP"
        }
        dicVacationDetails["Position"] = position
        dicVacationDetails["SwapJsonFileName"] = header["FileIdent"]
        if app.connectedToInternet() {
            let url = URL(string: "\(app.Domain)SaveSwaptimizerFileToServer")
            self.urlRequest = URLRequest(url: url!)
            let jsonDataToSend = try! JSONSerialization.data(withJSONObject: dicVacationDetails, options: [])
            let jsonString = String(data: jsonDataToSend, encoding: .utf8)
            self.urlRequest?.httpBody = jsonString?.data(using: .utf8)
            self.urlRequest?.httpMethod = "POST"
            self.urlRequest?.setValue("852275", forHTTPHeaderField: "Content-Length")
            let dataTask = URLSession.shared.dataTask(with: urlRequest!) { data, response, error in
                // Handle request error
                if let error = error as NSError?, error.code == NSURLErrorTimedOut {
//                    MARK: need to add CBOffline events
//                    let objEvent = CBOfflineEvents()
                    if let monthValue = self.bidPeriod?.month {
//                        objEvent.sendOfflineDataForTimeOut(url.absoluteString, month: monthValue)
                    }
                }

                if let data = data {
                    DispatchQueue.main.async {
//                        self.hud?.hide(true)
                    }
                    // check status code and possibly MIME type (which shall start with "application/json"):
                    if let httpResponse = response as? HTTPURLResponse,
                       httpResponse.statusCode == 200,
                       let mimeType = response?.mimeType,
                       mimeType.contains("application/json") {
                        // Handle successful JSON response
                    }
                }
            }

            dataTask.resume()

        }
        
    }
    
    func readVacationFile(fileName: String) -> [String: Any]? {
        let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid
        var vacationData: Data = Data()
        if vacationType == "WBID" {
            vacationData = self.bidPeriod?.wbVacationfile as! Data
        }
        else if vacationType == "WBIDF" {
            vacationData = self.bidPeriod?.wbVacationfileF as! Data
        }
        else if vacationType == "CREWBID" {
            vacationData = self.bidPeriod?.cbVacationFiles as! Data
        }
        else if vacationType == "CREWBIDF" {
            vacationData = self.bidPeriod?.cbVacationFilesF as! Data
        }
        else if vacationType == "FAVacation" {
            vacationData = self.bidPeriod?.faVacationFiles as! Data
        }
        else if vacationType == "FAVacationF" {
            let eomIndexF = fileName.suffix(1)
            if eomIndexF == "1" {
                vacationData = self.bidPeriod?.faVacationFilesFA1 as! Data
            } else if eomIndexF == "2" {
                vacationData = self.bidPeriod?.faVacationFilesFA2 as! Data
            } else if eomIndexF == "3" {
                vacationData = self.bidPeriod?.faVacationFilesFA3 as! Data
            }
        }
        else if vacationType == "FAVacationEomOnly" {
            let eomIndexF = fileName.suffix(1)
            if eomIndexF == "1" {
                vacationData = self.bidPeriod?.faVacationFilesEomOnlyFA1 as! Data
            } else if eomIndexF == "2" {
                vacationData = self.bidPeriod?.faVacationFilesEomOnlyFA2 as! Data
            } else if eomIndexF == "3" {
                vacationData = self.bidPeriod?.faVacationFilesEomOnlyFA3 as! Data
            } else if eomIndexF == "4" {
                vacationData = self.bidPeriod?.faVacationFilesEomOnlyFA4 as! Data
            } else if eomIndexF == "5" {
                vacationData = self.bidPeriod?.faVacationFilesEomOnlyFA5 as! Data
            } else if eomIndexF == "6" {
                vacationData = self.bidPeriod?.faVacationFilesEomOnlyFA6 as! Data
            } else if eomIndexF == "7" {
                vacationData = self.bidPeriod?.faVacationFilesEomOnlyFA7 as! Data
            }
        }
        if vacationType == nil {
            return nil
        }
        let userDic = try! JSONSerialization.jsonObject(with: vacationData, options: []) as? [String: Any]
        return userDic
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
                    
                    for case let day as BIDay in trip.days ?? [] {
                        day.displayType = BIDayDisplayType.normal.rawValue as NSNumber
                        day.redEyeDayDisplayDayType = BIDayDisplayType.normal.rawValue as NSNumber
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
            let length = (self.calendarData.daysBetweenDate(startDate!, andDate: endDate!) ?? 0) + 1
            vacay.length = length as NSNumber
            
            self.bidPeriod?.containsVacay = true
        }

        UserDefaults.standard.set(false, forKey: kCBIncludeDroppedTripsInProcessingKey)

        let includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
        let lines = self.bidPeriod?.lines?.allObjects as? [AnyObject] ?? []
        var sortedLines = (lines as NSArray).sortedArray(using: [
            NSSortDescriptor(key: "number", ascending: true)
        ])
        let notBlankPredicate = NSPredicate(format: "type != %d", BILineType.BlankLineType.rawValue)
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
            do {
                try moc?.save()
                print("deadhead at start and end cities saved")
            } catch {
                print("Error saving context: \(error)")
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
                    line.clawBack = lineData[clawBack] as? NSNumber
                    
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
                        line.cfvVacDates = cfvDates as? NSObject
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
                        let length = (self.calendarData.daysBetweenDate(startDateFinal, andDate: endDateFinal)) + 1
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
                    
                    if ((self.bidPeriod?.containsVacay) != nil) {
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
                                   calendarData.isDate(normalizedDate, between: fvStartdate, and: fvEnddate) == true {
                                    for day in trip.orderedDays {
                                        day.displayType = BIDayDisplayType.fullPay.rawValue as NSNumber
                                        day.redEyeDayDisplayDayType = BIDayDisplayType.fullPay.rawValue as NSNumber
                                        trip.vacationOverlapType = BITripVacationOverlapType.none.rawValue as NSNumber
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
                            let missingDateIndex = CBUtils.findMissingIndexInRedEyeTrip(trip!)
                            let missingRedEyeDate = CBUtils.findMissingDate(forRedEyeTrip: trip!)
                        }
                        // Enumerate over the days and give them a value based on their status inside or
                        // outside the vacation and its overlap
                        
                        // Grab the vacation pieces
                        let vacationPieces = (vLine!["VacationPieces"] as? [[String: Any]])!
                        
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
                                    day?.redEyeDayDisplayDayType = displayDayType as NSNumber
                                }
                            }
                            //                        End vacationPieces loop
                            if (day?.displayType?.intValue == BIDayDisplayType.normal.rawValue) {
                                day?.displayType = BIDayDisplayType.noPay.rawValue as NSNumber
                            }
                        } // End day loop
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
            self.bidPeriod?.vacationType = vacationType
            do {
                try moc?.save()
                print("line core data saved from processJsonFile function in CBVacationDownloader")
            } catch {
                print("line core data not saved from processJsonFile function in CBVacationDownloader: \(error)")
            }
            // Get rid of any hidden vacation line values
            let lineValuesKey = CBLineValuesMenuController.lineValuesKeyForBidPeriod(bidPeriod: self.bidPeriod!)
            var lineValuesToDisplay = UserDefaults.standard.value(forKey: lineValuesKey) as? [Int]
            var valuesToRemove: [Int] = []
            for i in 0..<lineValuesToDisplay!.count {
                let valueType = lineValuesToDisplay![i]
                let lmvc = CBLineValuesMenuController()
                if (lmvc.lineValueTypeIsHiddenForPilotVacation(valueType)) {
                    valuesToRemove.append(valueType)
                }
            }
            let filtered = lineValuesToDisplay?.filter { !valuesToRemove.contains($0) }
            lineValuesToDisplay = filtered
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
        
    }
    
    //    MARK: getDisplayType
        func getDisplayType(date: Date, startDate: Date, endDate: Date, label: String, displayType: String) -> BIDayDisplayType.RawValue {
            var dayDisplayType = -1
            if (self.calendarData.isDate(date, between: startDate, and: endDate)) {
                if label == kVaLabel {
                    dayDisplayType = BIDayDisplayType.fullPay.rawValue
                }
                else if label == kVoLabel {
                    if displayType == kFrontVoFull {
                        dayDisplayType = BIDayDisplayType.fullPay.rawValue
                    }
                    else if label == kBackVoFull {
                        dayDisplayType = BIDayDisplayType.fullPay.rawValue
                    }
                    else if (self.calendarData.daysBetweenDate(startDate, andDate: endDate) > 0) {
                        if displayType == kFrontVoPartial {
                            let vaDc = self.calendarData.bidPeriodCalendar().dateComponents([.day], from: endDate)
                            let dayDc = self.calendarData.bidPeriodCalendar().dateComponents([.day], from: date)
                            
                            if (vaDc.day == dayDc.day) {
                                dayDisplayType = BIDayDisplayType.fullPay.rawValue
                            }
                            else {
                                dayDisplayType = BIDayDisplayType.partialPay.rawValue
                            }
                        }
                        else {
                            let vaDc = self.calendarData.bidPeriodCalendar().dateComponents([.day], from: startDate)
                            let dayDc = self.calendarData.bidPeriodCalendar().dateComponents([.day], from: date)
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
        var vacationType = self.bidPeriod?.userVacationWbidOrCrewBid ?? "FAVacation"
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
        var vacay: BIVacation?

        
        if vacationType == "FAVacation" || vacationType == "FAVacation" || vacationType == "FAVacationEomOnly" {
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
            let length = (self.calendarData.daysBetweenDate(startDate, andDate: endDate!) ?? 0) + 1
            vacay.length = length as NSNumber
            
            self.bidPeriod?.containsVacay = true
        }
        
        UserDefaults.standard.set(false, forKey: kCBIncludeDroppedTripsInProcessingKey)

        let includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
        let lines = self.bidPeriod?.lines?.allObjects as? [AnyObject] ?? []
        var sortedLines = (lines as NSArray).sortedArray(using: [
            NSSortDescriptor(key: "number", ascending: true)
        ])
        let notBlankPredicate = NSPredicate(format: "type != %d", BILineType.BlankLineType.rawValue)
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
        do {
            try moc?.save()
            print("deadhead at start and end cities saved")
        } catch {
            print("Error saving context: \(error)")
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
                line.clawBack = lineData[clawBack] as? NSNumber
                
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
                    
                    for d in 0..<(trip!.orderedDays.count) {
                        let day = trip?.orderedDays[d]
                        var currentDate = day?.date
                        for k in 0..<vacationPieces.count {
                            let currentDictionary = vacationPieces[k] as [String: Any]
                            let label = (currentDictionary["Label"] as? String)!
                            let displayType = (currentDictionary["DisplayType"] as? String)!
                            let startDateString = (currentDictionary["FirstDay"] as? String)!
                            let endDateString = (currentDictionary["LastDay"] as? String)!
                            
                            let startDate = (df.date(from: "0000" + startDateString))!
                            let endDate = (df.date(from: "2359" + endDateString))!
                            
                            if (trip!.isRedEyeTrip) {
                                currentDate = tripDaysDate[d]
                                if (d == 0 && trip!.startDate! < currentDate!) {
                                    currentDate = trip?.startDate
                                }
                            }
                            if (missingDateIndex != 0 && missingRedEyeDate != nil) {
                                let lastDay = trip?.orderedDays.last
                                if let missingDate = missingRedEyeDate, let lastDate = lastDay?.date, missingDate < lastDate {
                                    let displayDayType = self.getDisplayType(date: missingRedEyeDate!, startDate: startDate, endDate: endDate, label: label, displayType: displayType)
                                    
                                    if (displayDayType != -1) {
                                        day?.displayType = displayDayType as NSNumber
                                    }
                                }
                                else {
                                    let displayDayType = self.getDisplayType(date: currentDate!, startDate: startDate, endDate: endDate, label: label, displayType: displayType)
                                    if (displayDayType != -1) {
                                        day?.displayType = displayDayType as NSNumber
                                    }
                                }
                            }
                            else {
                                let displayDayType = self.getDisplayType(date: currentDate!, startDate: startDate, endDate: endDate, label: label, displayType: displayType)
                                if (displayDayType != -1) {
                                    day?.displayType = displayDayType as NSNumber
                                }
                            }
                        } // End vacationPieces loop
                        if (day?.displayType?.intValue == BIDayDisplayType.normal.rawValue) {
                            day?.displayType = BIDayDisplayType.noPay.rawValue as NSNumber
                        }
                    }// End day loop
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
        do {
            try moc?.save()
            print("line core data saved from processFAVacationWithJsonFile function in CBVacationDownloader")
        } catch {
            print("line core data not saved from processFAVacationWithJsonFile function in CBVacationDownloader: \(error)")
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
    }
    
    func getDayDatesFromTrip(trip: BITrip) -> [Date] {
        let missingDateIndex = CBUtils.findMissingIndexInRedEyeTrip(trip)
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
        for dayInfo in trip.info?.orderedDays as! [BIDayInfo] {
            for lengInfo in dayInfo.orderedLegs as! [BILegInfo] {
                dateComps.minute = lengInfo.departMinutes?.intValue
                let legStartDate = calendar.date(from: dateComps)!
                tripDates.append(df.string(from: legStartDate))
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
    
}
