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
            
            vacationDetailDictionary["EmpNum"] = self.bidPeriod?.crewIdentifier ?? 81566
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
                                print("FileName: \(fileName)")
                            } else {
                                print("FileName is null or missing")
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
        var postDict: [String: Any] = ["Pilot": pilot ?? 88463, "CrewBidVersion": appVersion, "AccessKey": accessKey, "FWeek": isEom]
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
                        print(hasAccount)
                    }
                }
                catch {
                    print("error finding has account while parsing")
                }
            }
        }
        task.resume()
    }
    
    
}
