//
//  AwardsViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 14/08/25.
//

import Foundation

class AwardsViewModel {
    var bidPeriod:BIBidPeriod
    var EmpNum:String!
    init(bidPeriod: BIBidPeriod) {
        self.bidPeriod = bidPeriod
    }
    
    
    
    func retrieveAwardFile(completion : @escaping (Bool)->Void) {
        let bidDownload = BIBidFileDownload()
        let bidInfo = BIBidInfo()
        let filename = bidInfo.bidAwardTextFilename()
        bidDownload.downloadBidFiles(sessionKey: CBGlobalMethods.shared.secretKey!, filename: filename){ result in
            switch result{
            case .success(let fileURL):
                do{
                    let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
                    self.bidPeriod.awardString = fileContents
                    try self.bidPeriod.managedObjectContext?.save()
                    completion(true)
                }catch{
                    print("Failed to read award file: \(error.localizedDescription)")
                    completion(false)
                }
            case .failure(let error):
                print("Download error: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
//    func getAwardAlertFromServerCompleted(empNum: String, completion: @escaping (Bool)->Void){
//        var userPosition: String?
//        if bidPeriod.positionType!.intValue == 0 {
//            userPosition = "CP"
//        }
//        else if bidPeriod.positionType!.intValue == 1 {
//            userPosition = "FO"
//        }
//        else if bidPeriod.positionType!.intValue == 2 {
//            userPosition = "FA"
//        }
//        
//        var dicData : [String : Any] = [:]
//        dicData["Year"] = bidPeriod.year
//        dicData["Month"] = bidPeriod.month
//        dicData["Round"] = bidPeriod.round
//        dicData["Domicile"] = bidPeriod.base
//        dicData["Position"] = userPosition
//        let numberEmpNum = extractNumber(fromText: empNum)!
//        dicData["EmployeeNumber"] = numberEmpNum
//        if bidPeriod.crewIdentifier != nil && (CBGlobalMethods.shared.awardLertSecretEmpNum == nil) {
//            dicData["EmployeeNumber"] = bidPeriod.crewIdentifier?.stringValue
//        }
//        guard let url = URL(string: EndPoint.shared.getCurrentMonthAwardData) else { return }
//
//        var urlRequest = URLRequest(url: url)
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: dicData, options: [])
//            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
//            
//            urlRequest.httpBody = jsonString.data(using: .utf8)
//            urlRequest.httpMethod = "POST"
//            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//            
//            let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
//                DispatchQueue.main.async {
//                    if let data = data{
//                        if let httpResponse = response as? HTTPURLResponse {
//                            let isJSON = response?.mimeType?.range(of: "application/json") != nil
//                            var alertMessage = ""
//                            
//                            if httpResponse.statusCode == 200, isJSON {
//                                do {
//                                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
//                                    let awardedLine = (json["AwardedLine"] as? NSNumber)?.stringValue ?? ""
//                                    let isPaperBid = (json["IsPaperbid"] as? NSNumber)?.boolValue ?? false
//                                    var isBlankLine = false
//                                    if let blankLineValue = json["BlankLine"], !(blankLineValue is NSNull) {
//                                        isBlankLine = (blankLineValue as? NSNumber)?.boolValue ?? false
//                                    }
//                                    var isReserve = false
//                                    if let reserveValue = json["ReserveLine"], !(reserveValue is NSNull) {
//                                        isReserve = (reserveValue as? NSNumber)?.boolValue ?? false
//                                    }
//                                    var position = json["Position"] as? String
//                                    let buddyAwards = json["BuddyAwards"] as? [NSDictionary]
//                                    if position == nil {
//                                        position = ""
//                                    }
//                                    if awardedLine == "10000" {
//                                        return
//                                    }
//                                    if awardedLine != "0" {
//                                        if isPaperBid {
//                                            alertMessage = "You are a paper bid for the month and you were awarded line \(String(describing: awardedLine))"
//                                        }
//                                        else if isReserve {
//                                            alertMessage = "You were awarded line \(String(describing: awardedLine))\(position!) for \(self.shortMonthName(self.bidPeriod.month!.intValue)) \(self.bidPeriod.year!.intValue)."
//                                            alertMessage = "\(alertMessage)\n\nLine \(String(describing: awardedLine)) is a reserve line."
//                                            AlertService.showAlertForTopVC(title: "Award!", message: alertMessage, actions: [(title: "OK", style:.default, handler: {_ in
//                                                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
//                                            })])
//                                        }
//                                        else if isBlankLine {
//                                            alertMessage = "You were awarded line \(String(describing: awardedLine))\(position!) for \(self.shortMonthName(self.bidPeriod.month!.intValue)) \(self.bidPeriod.year!.intValue)."
//                                            alertMessage = "\(alertMessage)\n\nLine \(String(describing: awardedLine)) is a blank line."
//                                            AlertService.showAlertForTopVC(title: "Award!", message: alertMessage, actions: [(title: "OK", style:.default, handler: {_ in
//                                                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
//                                            })])
//                                        }
//                                        else if self.bidPeriod.positionType!.intValue == BICrewPositionType.Captain.rawValue {
//                                            alertMessage = "You were awarded line \(String(describing: awardedLine))\(position!) for \(self.shortMonthName(self.bidPeriod.month!.intValue)) \(self.bidPeriod.year!.intValue) .\n\n"
//                                         
//                                            if buddyAwards!.count > 0 {
//                                                alertMessage = "\(alertMessage)You will be flying with \(((buddyAwards![0] as! [AnyHashable : Any])["BuddyName"])!) (\(((buddyAwards![0] as! [AnyHashable : Any])["BuddyEmpNum"])!))"
//                                            }
//                                            AlertService.showAlertForTopVC(title: "Award!", message: alertMessage, actions: [(title: "OK", style:.default, handler: {_ in
//                                                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
//                                                print("We did not find an awarded line for you")
//                                            })])
//                                        }
//                                        else if self.bidPeriod.positionType!.intValue == BICrewPositionType.FirstOfficer.rawValue {
//                                            alertMessage = "You were awarded line \(String(describing: awardedLine))\(position!) for \(self.shortMonthName(self.bidPeriod.month!.intValue)) \(self.bidPeriod.year!.intValue) .\n\n"
//                                            
//                                            if buddyAwards!.count > 0 {
//                                                alertMessage = "\(alertMessage)You will be flying with \(((buddyAwards![0] as! [AnyHashable : Any])["BuddyName"])!) (\(((buddyAwards![0] as! [AnyHashable : Any])["BuddyEmpNum"])!))"
//                                            }
//                                            AlertService.showAlertForTopVC(title: "Award!", message: alertMessage, actions: [(title: "OK", style:.default, handler: {_ in
//                                                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
//                                                print("We did not find an awarded line for you")
//                                            })])
//                                        }
//                                        else if self.bidPeriod.positionType!.intValue == BICrewPositionType.FlightAttendant.rawValue {
//                                            alertMessage = "You were awarded line \(String(describing: awardedLine))\(position!) for \(self.shortMonthName(self.bidPeriod.month!.intValue)) \(self.bidPeriod.year!.intValue)."
//                                            if buddyAwards!.count > 0 {
//                                                alertMessage = "\(alertMessage)\n\nYou will be flying with"
//                                            }
//                                            for buddyDetails in buddyAwards! {
//                                                let buddyName = (buddyDetails["BuddyName"] as! String).trimmingCharacters(in: CharacterSet.whitespaces)
//                                                let buddyEmpNum = buddyDetails["BuddyEmpNum"] as? Int
//                                                var buddyPosition = (buddyDetails )["BuddyPosition"] as? String
//                                                if buddyPosition == nil {
//                                                    buddyPosition = ""
//                                                }
//                                                alertMessage = "\(alertMessage) \(buddyName) (\(buddyEmpNum!)) position \(buddyPosition!) and "
//                                            }
//                                            if alertMessage.length > 3 && (alertMessage as NSString).substring(with: NSRange(location: alertMessage.length - 4, length: 4)) == "and " {
//                                                alertMessage = (alertMessage as NSString).substring(with: NSRange(location: 0, length: alertMessage.length - 4))
//                                            }
//                                            AlertService.showAlertForTopVC(title: "Award!", message: alertMessage, actions: [(title: "OK", style:.default, handler: {_ in
//                                                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
//                                                print("We did not find an awarded line for you")
//                                            })])
//                                        }
//                                        completion(true)
//                                    }else{
//                                        if let AwardStatus = json["Status"] as? String{
//                                            if AwardStatus == "AwardImported"{
//                                                DispatchQueue.main.async(execute: { [self] in
//                                                    AlertService.showAlertForTopVC(title: "No awarded line found", message: "We did not find an awarded line for you \(numberEmpNum)", actions: [(title: "OK", style:.default, handler: {_ in
//                                                        NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
//                                                        print("We did not find an awarded line for you")
//                                                    })])
//                                                })
//                                            }
//                                            else{
//                                                DispatchQueue.main.async {
//                                                    AlertService.showAlertForTopVC(title: "CrewBid", message: "Award data is not yet downloaded into our database.  Please try again after a few hours.", actions: nil)
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            } catch {
//                                print("JSON parsing error: \(error)")
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            dataTask.resume()
//        } catch {
//            print("Error serializing JSON:", error)
//        }
//    }
    
    
    func getAwardAlertFromServerCompleted(empNum: String, completion: @escaping (Bool) -> Void) {
        guard let request = makeAwardRequest(empNum: empNum) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      response?.mimeType?.contains("application/json") == true,
                      let json = self.parseAwardResponse(data: data)
                else {
                    completion(false)
                    return
                }
                
                self.showAwardAlert(json: json, empNum: empNum)
                completion(true)
            }
        }.resume()
    }
    
    private func makeAwardRequest(empNum: String) -> URLRequest? {
        var userPosition: String?
        if bidPeriod.positionType?.intValue == 0 { userPosition = "CP" }
        else if bidPeriod.positionType?.intValue == 1 { userPosition = "FO" }
        else if bidPeriod.positionType?.intValue == 2 { userPosition = "FA" }
        
        var dicData: [String: Any] = [
            "Year": bidPeriod.year ?? 0,
            "Month": bidPeriod.month ?? 0,
            "Round": bidPeriod.round ?? 0,
            "Domicile": bidPeriod.base ?? "",
            "Position": userPosition ?? ""
        ]
        
        let numberEmpNum = extractNumber(fromText: empNum) ?? ""
        dicData["EmployeeNumber"] = bidPeriod.crewIdentifier?.stringValue ?? numberEmpNum
        EmpNum = numberEmpNum
        guard let url = URL(string: EndPoint.shared.getCurrentMonthAwardData) else { return nil }
        
        var request = URLRequest(url: url)
        if let jsonData = try? JSONSerialization.data(withJSONObject: dicData) {
            request.httpBody = jsonData
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            return request
        }
        return nil
    }
    
    private func parseAwardResponse(data: Data) -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
        } catch {
            print("JSON parsing error:", error)
            return nil
        }
    }
    
    private func showAwardAlert(json: [String: Any], empNum: String) {
        let awardedLine = (json["AwardedLine"] as? NSNumber)?.stringValue ?? ""
        let isPaperBid = (json["IsPaperbid"] as? NSNumber)?.boolValue ?? false
        var isBlankLine = false
        if let blankLineValue = json["BlankLine"], !(blankLineValue is NSNull) {
            isBlankLine = (blankLineValue as? NSNumber)?.boolValue ?? false
        }
        var isReserve = false
        if let reserveValue = json["ReserveLine"], !(reserveValue is NSNull) {
            isReserve = (reserveValue as? NSNumber)?.boolValue ?? false
        }
        var position = json["Position"] as? String
        let buddyAwards = json["BuddyAwards"] as? [NSDictionary]
        if position == nil {
            position = ""
        }
        if awardedLine == "10000" {
            return
        }
        var alertMessage = ""
        if awardedLine != "0" {
            if isPaperBid {
                alertMessage = "You are a paper bid for the month and you were awarded line \(String(describing: awardedLine))"
            }
            else if isReserve {
                alertMessage = "You were awarded line \(String(describing: awardedLine))\(position!) for \(self.shortMonthName(self.bidPeriod.month!.intValue)) \(self.bidPeriod.year!.intValue)."
                alertMessage = "\(alertMessage)\n\nLine \(String(describing: awardedLine)) is a reserve line."
                AlertService.showAlertForTopVC(title: "Award!", message: alertMessage, actions: [(title: "OK", style:.default, handler: {_ in
                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
                })])
            }
            else if isBlankLine {
                alertMessage = "You were awarded line \(String(describing: awardedLine))\(position!) for \(self.shortMonthName(self.bidPeriod.month!.intValue)) \(self.bidPeriod.year!.intValue)."
                alertMessage = "\(alertMessage)\n\nLine \(String(describing: awardedLine)) is a blank line."
                AlertService.showAlertForTopVC(title: "Award!", message: alertMessage, actions: [(title: "OK", style:.default, handler: {_ in
                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
                })])
            }
            else if self.bidPeriod.positionType!.intValue == BICrewPositionType.Captain.rawValue {
                alertMessage = "You were awarded line \(String(describing: awardedLine))\(position!) for \(self.shortMonthName(self.bidPeriod.month!.intValue)) \(self.bidPeriod.year!.intValue) .\n\n"
             
                if buddyAwards!.count > 0 {
                    alertMessage = "\(alertMessage)You will be flying with \(((buddyAwards![0] as! [AnyHashable : Any])["BuddyName"])!) (\(((buddyAwards![0] as! [AnyHashable : Any])["BuddyEmpNum"])!))"
                }
                AlertService.showAlertForTopVC(title: "Award!", message: alertMessage, actions: [(title: "OK", style:.default, handler: {_ in
                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
                })])
            }
            else if self.bidPeriod.positionType!.intValue == BICrewPositionType.FirstOfficer.rawValue {
                alertMessage = "You were awarded line \(String(describing: awardedLine))\(position!) for \(self.shortMonthName(self.bidPeriod.month!.intValue)) \(self.bidPeriod.year!.intValue) .\n\n"
                
                if buddyAwards!.count > 0 {
                    alertMessage = "\(alertMessage)You will be flying with \(((buddyAwards![0] as! [AnyHashable : Any])["BuddyName"])!) (\(((buddyAwards![0] as! [AnyHashable : Any])["BuddyEmpNum"])!))"
                }
                AlertService.showAlertForTopVC(title: "Award!", message: alertMessage, actions: [(title: "OK", style:.default, handler: {_ in
                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
                })])
            }
            else if self.bidPeriod.positionType!.intValue == BICrewPositionType.FlightAttendant.rawValue {
                alertMessage = "You were awarded line \(String(describing: awardedLine))\(position!) for \(self.shortMonthName(self.bidPeriod.month!.intValue)) \(self.bidPeriod.year!.intValue)."
                if buddyAwards!.count > 0 {
                    alertMessage = "\(alertMessage)\n\nYou will be flying with"
                }
                for buddyDetails in buddyAwards! {
                    let buddyName = (buddyDetails["BuddyName"] as! String).trimmingCharacters(in: CharacterSet.whitespaces)
                    let buddyEmpNum = buddyDetails["BuddyEmpNum"] as? Int
                    var buddyPosition = (buddyDetails )["BuddyPosition"] as? String
                    if buddyPosition == nil {
                        buddyPosition = ""
                    }
                    alertMessage = "\(alertMessage) \(buddyName) (\(buddyEmpNum!)) position \(buddyPosition!) and "
                }
                if alertMessage.length > 3 && (alertMessage as NSString).substring(with: NSRange(location: alertMessage.length - 4, length: 4)) == "and " {
                    alertMessage = (alertMessage as NSString).substring(with: NSRange(location: 0, length: alertMessage.length - 4))
                }
                AlertService.showAlertForTopVC(title: "Award!", message: alertMessage, actions: [(title: "OK", style:.default, handler: {_ in
                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
                    print("We did not find an awarded line for you")
                })])
            }
        }else{
            if let AwardStatus = json["Status"] as? String{
                if AwardStatus == "AwardImported"{
                    DispatchQueue.main.async(execute: { [self] in
                        AlertService.showAlertForTopVC(title: "No awarded line found", message: "We did not find an awarded line for you \(EmpNum!)", actions: [(title: "OK", style:.default, handler: {_ in
                            NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
                            print("We did not find an awarded line for you")
                        })])
                    })
                }
                else{
                    DispatchQueue.main.async {
                        AlertService.showAlertForTopVC(title: "CrewBid", message: "Award data is not yet downloaded into our database.  Please try again after a few hours.", actions: nil)
                    }
                }
            }
        }
    }
    
    func extractNumber(fromText text: String?) -> String? {
        let nonDigitCharacterSet = CharacterSet.decimalDigits.inverted
        return text?.components(separatedBy: nonDigitCharacterSet).joined(separator: "")
    }
    
    func shortMonthName(_ MonthNo: Int) -> String {
        var Month: String = ""
        switch MonthNo {
            case 1:
                Month = "Jan"
            case 2:
                Month = "Feb"
            case 3:
                Month = "Mar"
            case 4:
                Month = "APR"
            case 5:
                Month = "May"
            case 6:
                Month = "Jun"
            case 7:
                Month = "Jul"
            case 8:
                Month = "Aug"
            case 9:
                Month = "Sep"
            case 10:
                Month = "Oct"
            case 11:
                Month = "Nov"
            case 12:
                Month = "Dec"
            default:
                break
        }
        return Month
    }
}
