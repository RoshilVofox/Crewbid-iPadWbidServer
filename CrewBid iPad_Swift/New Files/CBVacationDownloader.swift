//
//  CBVacationDownloader.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 22/05/25.
//

import Foundation


class CBVacationDownloader: NSObject {
    
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
    var finishedBlock: BIFinishedBlock?
    
    
    
    //MARK: download WBID VacationFiles
    func downloadWbidVacation() {
        let delayInSeconds = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            var vacationDetailDictionary: [String: Any] = [:]
            if(self.bidPeriod?.swaptimizerIdentifier == nil) {
                vacationDetailDictionary["EmpNum"] = self.bidPeriod?.crewIdentifier ?? 12831
            }
            else {
                vacationDetailDictionary["EmpNum"] = self.bidPeriod?.swaptimizerIdentifier ?? 12831
            }
            vacationDetailDictionary["Base"] = self.bidPeriod?.base ?? "DEN"
            if let rawValue = self.bidPeriod?.positionType?.intValue,
               let positionType = BICrewPositionType(rawValue: rawValue) {
                let shortName = CBUtils.shortName(for: positionType)
                vacationDetailDictionary["Position"] = shortName
            }
            vacationDetailDictionary["Position"] = "CP"
            vacationDetailDictionary["Year"] = self.bidPeriod?.year ?? 2025
            vacationDetailDictionary["Month"] = self.bidPeriod?.month ?? 6
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
            
            vacationDetailDictionary["EmpNum"] = self.bidPeriod?.crewIdentifier ?? 22231//81566
            vacationDetailDictionary["Base"] = self.bidPeriod?.base ?? "DEN"
            vacationDetailDictionary["Base"] = self.bidPeriod?.base ?? "DEN"
            if let rawValue = self.bidPeriod?.positionType?.intValue,
               let positionType = BICrewPositionType(rawValue: rawValue) {
                let shortName = CBUtils.shortName(for: positionType)
                vacationDetailDictionary["Position"] = shortName
            }
            vacationDetailDictionary["Position"] = "FA"
            vacationDetailDictionary["Year"] = self.bidPeriod?.year ?? 2025
            vacationDetailDictionary["Month"] = self.bidPeriod?.month ?? 6
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
                //                print("Mutable Response String: \(responseString)")
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        let pilotInfo = json["PilotInfo"] as! [String: Any] //]["HasAccount"]
                        let hasAccount = pilotInfo["HasAccount"]
                        if hasAccount as! Int == 0 {
                            print("No swaptimizer account")
                        }
                        else if hasAccount as! Int == 1 {
                            print("Mutable Response String: \(responseString)")
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
    
//    MARK: storeWBIDVacation()
    func storeWBIDVacation(jsonData: [String: Any]) {
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
        let hasAccount = (pilotInfo["HasAccount"] as? NSNumber)?.boolValue ?? false
        let dataAvailable = (pilotInfo["DataAvailable"] as? NSNumber)?.boolValue ?? false
        let hasVacation = (pilotInfo["HasVacation"] as? NSNumber)?.boolValue ?? false
        let pilotIdentifier = (pilotInfo["Pilot"] as? NSNumber)?.intValue ?? 0
        let yearMonth = pilotInfo["YearMonth"] as! String
        let vacayYear = Int(yearMonth.prefix(4)) ?? 0
        let vacayMonth = Int(yearMonth.dropFirst(4).prefix(2)) ?? 0
        let secretEnabled = self.bidPeriod?.secretSwitchOn
        
        if !(statusCode == "SUCCESS") {
            AlertService().showAlertForTopVC(title: "WBidmax Server Error", message: "\(statusMsg)\nWBidmax vacation usually releases data the evening of the 4th or morning of the 5th. If you are seeing this error before data release, please try again after data has been released.", actions: nil)
            self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.statusError.rawValue as NSNumber)
        }
        else if (pilotIdentifier != self.bidPeriod?.swaptimizerIdentifier?.intValue && !(secretEnabled == "YES")) {
            //    The bid package for the wrong pilot got downloaded
            AlertService().showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax user ID \(pilotIdentifier) does not match the pilot for whom the bid package was downloaded \(String(describing: self.bidPeriod?.swaptimizerIdentifier)).", actions: nil)
            self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.dataNotAvailable.rawValue as NSNumber)
        }
        else if ((self.bidPeriod?.month?.intValue)! - vacayMonth == 1 || (self.bidPeriod?.month?.intValue == 1 && vacayMonth == 12)) {
            // New bid period but old month's data, so data is not yet available.
            // Alert view telling the user data is not yet available, check back later
            AlertService().showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).", actions: nil)
            self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.dataNotAvailable.rawValue as NSNumber)
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
            AlertService().showAlertForTopVC(title: "No Vacation", message: "No vacation next month for user \(user)", actions: nil)
            self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.notApplicable.rawValue as NSNumber )
        }
        else if (hasVacation && !hasAccount) {
            AlertService().showAlertForTopVC(title: "No MAX Subscription!", message: "We see that you have vacation this month, but you do not have a Max subscription.\nA Max subscription will give you access to the highly acclaimed WBidMax vacation predictions.\nTo get a Max subscription, go to www.crewbidmax.com and get a Max subscription.")
            self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.noAccount.rawValue as NSNumber )
        }
        else if (hasVacation && hasAccount && !dataAvailable)
        {
            // Alert view telling the user data is not yet available, check back later
            AlertService().showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
            self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.dataNotAvailable.rawValue as NSNumber)
        }
        else if (hasVacation && hasAccount && dataAvailable)
        {
            // Check to make sure the data received is the proper file
            let seat = pilotInfo["Seat"] as! String
            let round = pilotInfo["Round"] as! Int
            let vacayBase = pilotInfo["Base"] as! String
            var rawValue = (self.bidPeriod?.positionType?.intValue)!
            var positionType = BICrewPositionType(rawValue: rawValue)!
            let shortName = CBUtils.shortName(for: positionType) ?? "CM"
            
            if !(self.bidPeriod?.secretSwitchOn == "YES") {
                if vacayMonth != self.bidPeriod?.month?.intValue ?? 0 {
                    AlertService().showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax data month \(vacayMonth) is not the same as the bid period month \(String(describing: self.bidPeriod?.month))")
                    self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.statusError.rawValue as NSNumber)
                }
                else if (vacayYear != self.bidPeriod?.year?.intValue) {
                    AlertService().showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax data year \(vacayYear) is not the same as the bid period year \(String(describing: self.bidPeriod?.year)).")
                    self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.statusError.rawValue as NSNumber)
                }
                else if !(vacayBase == self.bidPeriod?.base) {
                    AlertService().showAlertForTopVC(title: "WBidmax Error", message: "The WBidmax data base \(vacayBase) is not the same as the bid period year \(String(describing: self.bidPeriod?.base)).")
                    self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.statusError.rawValue as NSNumber)
                }
                else if !(shortName == seat) {
                    AlertService().showAlertForTopVC(title: "WBidmax Error", message: "The vacation data position \(seat) is not the same as the bid period position \(shortName).)")
                    self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.statusError.rawValue as NSNumber)
                }
                else if (self.bidPeriod?.round?.intValue == 2 && round == 1)
                {
                    // It's round 2 but SWAPtimizer has not yet released round 1 data
                    // Alert view telling the user data is not yet available, check back later
                    AlertService().showAlertForTopVC(title: "Data Not Yet Available", message: "WBidMax vacation data is not yet available. Check back later via the Bid Actions menu(top right).")
                    self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.dataNotAvailable.rawValue as NSNumber)
                }
                else if (round != self.bidPeriod?.round?.intValue)
                {
                    AlertService().showAlertForTopVC(title: "WBidmax Error", message: "The vacation data round \(round) is not the same as the bid period round \(String(describing: self.bidPeriod?.round))")
                    self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.statusError.rawValue as NSNumber)
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
                        AlertService().showAlertForTopVC(title: "WBidmax File Mismatch", message: "The vacation round \(round) and WBidmax data file round \(fileRound) are mismatched. Perhaps you didn't bid a blank line?")
                        self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.statusError.rawValue as NSNumber)
                    }
                    else if (fileYear != vacayYear) {
                        AlertService().showAlertForTopVC(title: "WBidmax File Mismatch", message: "The vacation year \(vacayYear) and WBidmax data file year \(fileYear) are mismatched. Perhaps you didn't bid a blank line?")
                        self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.statusError.rawValue as NSNumber)
                    }
                    else if (fileMonth != vacayMonth) {
                        AlertService().showAlertForTopVC(title: "WBidmax File Mismatch", message: "The vacation month \(vacayMonth) and WBidmax data file month \(fileMonth) are mismatched. Perhaps you didn't bid a blank line?")
                        self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.statusError.rawValue as NSNumber)
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
                let vacationType = self.bidPeriod?.userVacationWbidOrCrewBid;
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
        else
        {
            self.finishBlock(withSwaptimizerStatus: CBSwaptimizerStatus.checked.rawValue as NSNumber)
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
        
    }
    func finishBlock(withSwaptimizerStatus swaptimizerStatus: NSNumber?) {
        if swaptimizerStatus != nil {
            self.bidPeriod?.swaptimizerStatus = NSNumber(value: CBSwaptimizerStatus.statusError.rawValue)
        }
        
        if let finishedBlock = self.finishedBlock {
            DispatchQueue.main.async {
                finishedBlock()
            }
        }
    }
    
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
       
    }
    
    func processJsonFile(file: [String: Any]) {
        
    }

}
