//
//  CBBidSubmissionViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/08/25.
//

import Foundation

let kVendor = "CrewBidPad"


class CBBidSubmissionViewModel{
    
    var bidPeriod:BIBidPeriod?
    var userID = ""
    var password = ""
    var bidEmployeeNumber = "" // default Emp
    var optionalEmpNumbers = NSArray()
    var bidListNumbers = NSMutableArray()
    var app:AppDelegate!
    var isBiddingIDCertified:Bool = false
//    var bidFileDownload:BIBidFileDownload?
    let dataSource = GlobalBidInfo.shared
    var swaBidDataDownload:BISwaBidDataDownload?
    
    var jobShare1:String?
    var jobShare2:String?
    var isJobShareContingency:Bool = false
    init(bidPeriod: BIBidPeriod, userID: String,password: String, defaultEmpNum: String, optionalEmpNum: NSArray) {
        self.bidPeriod = bidPeriod
        self.optionalEmpNumbers = optionalEmpNum
        self.bidEmployeeNumber = defaultEmpNum
        self.userID = userID.lowercased()
        self.password = password
    }
    
    func setBidLineNumbers(completion: @escaping (Bool) -> Void){
        let lines = (CBGlobalMethods.shared.selectedBidPeriod!.lines!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "bidOrder", ascending: true)])
        let results: NSArray = ((lines as NSArray).filtered(using: NSPredicate(format: "bidOrder != 0"))) as NSArray
        if results.count == 0 {
            return
        }
        let bidLineNumbers = NSMutableArray()
        if bidPeriod!.isSecondRoundBid() || !bidPeriod!.isFABid() {
            let aKey = results.value(forKey: "number")
            bidLineNumbers.addObjects(from: aKey as! [Any])
            
        }else{
            for case let line as BILine in results{
                if line.faBidLineReserve != 0 {
                    bidLineNumbers.add("M")
                }else{
                    bidLineNumbers.add("\(line.number!)\(line.faPositionString)")
                }
            }
        }
        if self.bidPeriod!.isFABid(){
            if self.optionalEmpNumbers.count > 0 {
                let bidLineNumberWithoutDPosition = NSMutableArray()
                if let array = bidLineNumbers as? [Int] {
                    bidLineNumbers.removeAllObjects()
                    for item in array{
                        bidLineNumbers.add("\(item)")
                    }
                }
                for num in bidLineNumbers as! [String]{
                    if !num.contains("D"){
                        bidLineNumberWithoutDPosition.add(num)
                    }
                }
                if bidLineNumbers.count > bidLineNumberWithoutDPosition.count{
                    let removedLinesCount = bidLineNumbers.count - bidLineNumberWithoutDPosition.count
                    AlertService.showAlertForTopVC(title: "CrewBid", message: "\(removedLinesCount) lines were removed from the submission because they were D position lines. Buddy Bid Lines must have positions (A, B, etc.) for each bidder. Press or Cancel to return the position choices", actions: [(title: "OK", style: .default, handler: {_ in
                        //Bid line number for FA with buddy and D position lines removed for submission
                        self.bidListNumbers = bidLineNumberWithoutDPosition
                        completion(true)
                    })])
                }
                else{
                    //bid line number for FA with buddy and no D position lines in bidlist
                    self.bidListNumbers = bidLineNumbers
                    completion(true)
                }
            }else{
                //bid lines for FA without any buddy
                self.bidListNumbers = bidLineNumbers
                completion(true)
            }
        }else{
            //bid lines for the Pilot
            self.bidListNumbers = bidLineNumbers
            completion(true)
        }
        
    }
    
    
    func startBidSubmission(sessionKey: String, completion: @escaping (Result<String, Error>) -> Void){
        if bidPeriod!.isFABid(){
            //MARK: bid submission for FA
            // new API
//            self.handleBidSubmissionForFA()
            
        }else{
            //MARK: bid submission for Pilot
            //get the httpBody format for bid submission
            let httpBody = self.setupBidSubmissionFormat(sessionKey: sessionKey, bidEmployeeNumber: self.bidEmployeeNumber, packetID: self.getPacketID(), avoidanceEmpID: self.optionalEmpNumbers)
            print(httpBody)
            //logging raw data into server
//            self.handleRawDataSentToServer()
//            self.handleSubmissionRawDataToServer(year: self.dataSource.year, month: self.dataSource.month, round: self.dataSource.round, fromApp: "5", position: self.dataSource.position.shortName, rawData: httpBody, empNum: self.bidEmployeeNumber, domicile: self.dataSource.base)
            
//            submitBid(httpBody: httpBody) { result in
//                switch result {
//                case .success(let dataString):
//                    self.handleLogBidSubmissionProcess(event: "submitBid", SWAmessage: "")
//                    if CBGlobalMethods.shared.certified {
//                        self.handleLogBidSubmissionProcessCertify()
//                    }
//                    completion(.success(dataString))
//
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
        }
    }
    
    // MARK: - Submit bid process
    func submitBid(httpBody: String, completion: @escaping (Result<String, Errors>) -> Void) {
        guard let bodyData = httpBody.data(using: .utf8) else {
            completion(.failure(.invalidURL))
            return
        }

        APIService.shared.fetch(
            urlString: EndPoint.shared.thirdpartyURL,
            method: .POST,
            body: bodyData,
            parse: { data in
                guard let dataString = String(data: data, encoding: .utf8) else {
                    throw Errors.decodingError
                }
                return dataString
            },
            completion: completion
        )
    }
    
    
    
    
//    func handleRawDataSentToServer(){
//        var optionalParameters = ""
//        if self.optionalEmpNumbers.count > 0 {
//            //for CP, FO
//            var optionName = "PILOT"
//            if BICrewPositionType.FlightAttendant == self.dataSource.position{
//                //for FA
//                optionName = "BUDDY"
//            }
//            for i in 0..<self.optionalEmpNumbers.count {
//                let paramName = optionName + String(i+1)
//                let paramValue = self.optionalEmpNumbers[i]
//                optionalParameters.append(contentsOf: "&\(paramName)=\(paramValue)")
//            }
//        }
//        let packetID = self.getPacketID()
//
//        let httpBody = """
//         REQUEST=UPLOAD_BID
//         &CREDENTIALS=
//         &PACKETID=\(packetID)
//         &BIDDER=\(bidEmployeeNumber)\(optionalParameters)
//         &BASE=\(dataSource.base)
//         &SEAT=\(dataSource.position.shortName)
//         &BIDROUND=Round\(dataSource.round)
//         &VENDOR=\(kVendor)
//         &BID=\(self.bidListNumbers.componentsJoined(by: ","))
//         """
//        
//        let dict = NSMutableDictionary()
//        
//        dict["Year"] = self.bidPeriod?.year
//        dict["Month"] = self.bidPeriod?.month
//        dict["Round"] = self.bidPeriod?.round
//        dict["Domicile"] = self.bidPeriod?.base
//        dict["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: (self.bidPeriod?.positionType?.intValue)!)!)
//        dict["EmployeeNumber"] = self.bidEmployeeNumber
//        dict["RawData"] = httpBody
//        dict["FromApp"] = "5"
//        
//        bidFileDownload?.sendRawDataToServer(dict: dict)
//    }
    
    func handleRawDataSentToServer() {
        var optionalParameters = ""
        if self.optionalEmpNumbers.count > 0 {
            // For CP/FO = PILOT, for FA = BUDDY
            var optionName = "PILOT"
            if BICrewPositionType.FlightAttendant == self.dataSource.position {
                optionName = "BUDDY"
            }
            
            for (index, empNum) in self.optionalEmpNumbers.enumerated() {
                let paramName = optionName + String(index + 1)
                optionalParameters.append("&\(paramName)=\(empNum)")
            }
        }
        
        let packetID = self.getPacketID()
        
        let httpBody = """
        REQUEST=UPLOAD_BID
        &CREDENTIALS=
        &PACKETID=\(packetID)
        &BIDDER=\(bidEmployeeNumber)\(optionalParameters)
        &BASE=\(dataSource.base)
        &SEAT=\(dataSource.position.shortName)
        &BIDROUND=Round\(dataSource.round)
        &VENDOR=\(kVendor)
        &BID=\(self.bidListNumbers.componentsJoined(by: ","))
        """
        
        let dict: [String: Any] = [
            "Year": self.bidPeriod?.year ?? 0,
            "Month": self.bidPeriod?.month ?? 0,
            "Round": self.bidPeriod?.round ?? 0,
            "Domicile": self.bidPeriod?.base ?? "",
            "Position": CBUtils.shortName(for: BICrewPositionType(rawValue: self.bidPeriod?.positionType?.intValue ?? 0)!),
            "EmployeeNumber": self.bidEmployeeNumber,
            "RawData": httpBody,
            "FromApp": fromApp
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: dict) else {
            print("Failed to encode request body")
            return
        }
        
        let url = EndPoint.shared.addSubmittedRawDataToServer
        
        APIService.shared.fetch(
            urlString: url,
            method: .POST,
            body: body,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            parse: { data in
                // Just return JSON object
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw Errors.decodingError
                }
                return json
            },
            completion: { (result: Result<[String: Any], Errors>) in
                switch result {
                case .success(let response):
                    print("Raw data submitted, response: \(response)")
                case .failure(let error):
                    print("Raw data submission failed: \(error)")
                    // TODO: Handle offline queueing if needed
                }
            }
        )
    }
    
    func getPacketID() -> String {
        let dataSource = GlobalBidInfo.shared
        let round = dataSource.round
        //for pilot bid data
        // 4 for pilot first round bid, 5 for second round.
        let packetIDRound = 1 == round ? 4 : 5
        // Four-digit year, two-digit month.
        let packetID = "\(dataSource.base)\(dataSource.year)\(String(format: "%02d", dataSource.month))\(packetIDRound)"
        return packetID
    }
    
    func setupBidSubmissionFormat(sessionKey: String, bidEmployeeNumber: String, packetID: String, avoidanceEmpID: NSArray) -> String{
        let dataSource = GlobalBidInfo.shared
        var optionalParameters = ""
        if avoidanceEmpID.count > 0 {
            let optionName = "PILOT"
            for i in 0..<avoidanceEmpID.count {
                let paramName = optionName + "\(i + 1)"
                let paramValue = avoidanceEmpID[i] as! String
                optionalParameters.append(contentsOf: "&\(paramName)=\(paramValue)")
            }
        }

        let httpBody = """
         REQUEST=UPLOAD_BID
         &CREDENTIALS=\(sessionKey)
         &PACKETID=\(packetID)
         &BIDDER=\(bidEmployeeNumber)\(optionalParameters)
         &BASE=\(dataSource.base)
         &SEAT=\(dataSource.position.shortName)
         &BIDROUND=Round\(dataSource.round)
         &VENDOR=\(kVendor)
         &BID=\(self.bidListNumbers.componentsJoined(by: ","))
         """
        return httpBody
    }
    
    func stringByAddingPercentEscapes(to unescapedString: String) -> String {
        let allowedCharacterSet = CharacterSet(charactersIn: ";/?:@&=+$,").inverted
        return unescapedString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    }
    
    //MARK: Server Logging
    
//    func handleSubmissionRawDataToServer(year: Int, month: Int, round: Int, fromApp: String, position: String, rawData: String, empNum: String, domicile: String){
//        let dict = NSMutableDictionary()
//        dict["Year"] = year
//        dict["Month"] = month
//        dict["Round"] = round
//        dict["RawData"] = rawData
//        dict["EmployeeNumber"] = empNum
//        dict["FromApp"] = fromApp
//        dict["Position"] = position
//        dict["Domicile"] = domicile
//        bidFileDownload?.sendRawDataToServer(dict: dict)
//    }
    
    func handleSubmissionRawDataToServer(
        year: Int,
        month: Int,
        round: Int,
        fromApp: String,
        position: String,
        rawData: String,
        empNum: String,
        domicile: String
    ) {
        let dict: [String: Any] = [
            "Year": year,
            "Month": month,
            "Round": round,
            "RawData": rawData,
            "EmployeeNumber": empNum,
            "FromApp": fromApp,
            "Position": position,
            "Domicile": domicile
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: dict) else {
            print("Failed to encode request body")
            return
        }
        
        let url = EndPoint.shared.addSubmittedRawDataToServer
        
        APIService.shared.fetch(
            urlString: url,
            method: .POST,
            body: body,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            parse: { data in
                // Parse into dictionary
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw Errors.decodingError
                }
                return json
            },
            completion: { (result: Result<[String: Any], Errors>) in
                switch result {
                case .success(let response):
                    print("Submission response: \(response)")
                case .failure(let error):
                    print("Submission failed: \(error)")
                    // TODO: handle offline save if needed
                }
            }
        )
    }
    
//    func handleLogBidSubmissionProcess(event: String, SWAmessage: String){
//        let mailInfoDict = NSMutableDictionary()
//        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
//        let employeeNumReal = self.userID.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .symbols)
//        
//        mailInfoDict["EmployeeNumber"] = Int(employeeNumReal)
//        mailInfoDict["Event"] = event
//        mailInfoDict["Base"] = self.bidPeriod?.base
//        mailInfoDict["Month"] = CBUtils.shortMonthName(month: self.bidPeriod!.month as! Int, uc: false)
//        mailInfoDict["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: (self.bidPeriod?.positionType?.intValue)!)!)
//        
//        var round = ""
//        if bidPeriod?.round?.intValue == 1 {
//            round = "M"
//        } else if bidPeriod?.round?.intValue == 2 {
//            round = "S"
//        }
//        
//        mailInfoDict["Round"] = round
//        mailInfoDict["SWAMessage"] = SWAmessage
//        mailInfoDict["Message"] = event
//        mailInfoDict["OperatingSystemNum"] = "iPad OS"
//        mailInfoDict["VersionNumber"] = appVersion
//        mailInfoDict["PlatformNumber"] = "iPad"
//        
//        let defaultEmp = self.bidEmployeeNumber.replacingOccurrences(of: "e", with: "").trimmingCharacters(in: .symbols)
//        
//        mailInfoDict["BidForEmpNum"] = Int(defaultEmp)
//        
//        var optionalBuddy1 = ""
//        var optionalBuddy2 = ""
//        var optionalBuddy3 = ""
//        
//        if self.optionalEmpNumbers.count > 0 {
//            if self.optionalEmpNumbers.count > 0{
//                optionalBuddy1 = "\(self.optionalEmpNumbers[0])"
//            }
//            if self.optionalEmpNumbers.count > 1{
//                optionalBuddy2 = "\(self.optionalEmpNumbers[1])"
//            }
//            if self.optionalEmpNumbers.count == 3{
//                optionalBuddy3 = "\(self.optionalEmpNumbers[2])"
//            }
//            print("Optional emplyee count: \(self.optionalEmpNumbers.count)")
//        }
//        
//        if !(optionalBuddy1.length > 0) {
//            optionalBuddy1 = "0"
//        }
//        if !(optionalBuddy2.length > 0) {
//            optionalBuddy2 = "0"
//        }
//        if !(optionalBuddy3.length > 0) {
//            optionalBuddy3 = "0"
//        }
//        mailInfoDict["BuddyBid1"] = Int(optionalBuddy1.replacingOccurrences(of: "e", with: "").trimmingCharacters(in: .symbols)) ?? 0
//        mailInfoDict["BuddyBid2"] = Int(optionalBuddy2.replacingOccurrences(of: "e", with: "").trimmingCharacters(in: .symbols)) ?? 0
//        mailInfoDict["BuddyBid3"] = Int(optionalBuddy3.replacingOccurrences(of: "e", with: "").trimmingCharacters(in: .symbols)) ?? 0
//        
//        let now = Date()
//        let startDate = CFTimeInterval(now.timeIntervalSince1970 * 1000)
//        let dateStarted = String(format: "/Date(%.0f+0800)", startDate)
//        mailInfoDict["Date"] = dateStarted
//        mailInfoDict["IpAddress"] = CBGlobalMethods.getIPAddress()
//        
//        if app.objNetworkType == .free {
//            //Needs code for cboffline events
//            return
//        }
//        bidFileDownload?.logBidSubmission(dict: mailInfoDict)
//    }
    
    func handleLogBidSubmissionProcess(event: String, SWAmessage: String) {
        var mailInfoDict: [String: Any] = [:]
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let employeeNumReal = self.userID
            .replacingOccurrences(of: "e", with: "")
            .replacingOccurrences(of: "x", with: "")
            .trimmingCharacters(in: .symbols)
        
        mailInfoDict["EmployeeNumber"] = Int(employeeNumReal)
        mailInfoDict["Event"] = event
        mailInfoDict["Base"] = self.bidPeriod?.base
        mailInfoDict["Month"] = CBUtils.shortMonthName(month: self.bidPeriod!.month as! Int, uc: false)
        mailInfoDict["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: (self.bidPeriod?.positionType?.intValue)!)!)
        
        var round = ""
        if bidPeriod?.round?.intValue == 1 {
            round = "M"
        } else if bidPeriod?.round?.intValue == 2 {
            round = "S"
        }
        mailInfoDict["Round"] = round
        mailInfoDict["SWAMessage"] = SWAmessage
        mailInfoDict["Message"] = event
        mailInfoDict["OperatingSystemNum"] = "iPad OS"
        mailInfoDict["VersionNumber"] = appVersion
        mailInfoDict["PlatformNumber"] = "iPad"
        
        let defaultEmp = self.bidEmployeeNumber
            .replacingOccurrences(of: "e", with: "")
            .trimmingCharacters(in: .symbols)
        mailInfoDict["BidForEmpNum"] = Int(defaultEmp)
        
        // Optional buddies
        var buddies = self.optionalEmpNumbers.map { "\($0)" }
        while buddies.count < 3 { buddies.append("0") }
        
        mailInfoDict["BuddyBid1"] = Int(buddies[0].replacingOccurrences(of: "e", with: "").trimmingCharacters(in: .symbols)) ?? 0
        mailInfoDict["BuddyBid2"] = Int(buddies[1].replacingOccurrences(of: "e", with: "").trimmingCharacters(in: .symbols)) ?? 0
        mailInfoDict["BuddyBid3"] = Int(buddies[2].replacingOccurrences(of: "e", with: "").trimmingCharacters(in: .symbols)) ?? 0
        
        let now = Date()
        let startDate = CFTimeInterval(now.timeIntervalSince1970 * 1000)
        let dateStarted = String(format: "/Date(%.0f+0800)", startDate)
        mailInfoDict["Date"] = dateStarted
        mailInfoDict["IpAddress"] = CBGlobalMethods.getIPAddress()
        
        if app.objNetworkType == .free {
            // Needs code for offline events
            return
        }
        
        logBidSubmission(dict: mailInfoDict) { result in
            switch result {
            case .success(let response):
                print("Log submission success: \(response)")
            case .failure(let error):
                print("Log submission failed: \(error)")
            }
        }
    }
    
    func logBidSubmission(dict: [String: Any], completion: @escaping (Result<[String: Any], Errors>) -> Void) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            
            APIService.shared.fetch(
                urlString: EndPoint.shared.logCrewBidSubmitBidDetails,
                method: .POST,
                body: jsonData,
                parse: { data in
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let dictionary = json as? [String: Any] else {
                        throw Errors.decodingError
                    }
                    return dictionary
                },
                completion: completion
            )
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    
    
    
    func handleLogBidSubmissionProcessCertify(){
        
        let logDict = NSMutableDictionary()
        
        let empNum = self.userID.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "")
        let bid4EmpNum = self.bidEmployeeNumber
        let message = String(format: "Certify with empnum %@ and %@ as the bid4EmpNum.", empNum, bid4EmpNum)
        
        logDict["Event"] = "certify"
        logDict["BidForEmpNum"] = bid4EmpNum
        logDict["EmployeeNumber"] = empNum
        logDict["Message"] = message
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        logDict["VersionNumber"] = appVersion
        logDict["Base"] = self.bidPeriod?.base
        logDict["Month"] = CBUtils.shortMonthName(month: (self.bidPeriod?.month?.intValue)!, uc: false)
        logDict["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: (self.bidPeriod?.positionType?.intValue)!)!)
        logDict["Round"] = self.bidPeriod?.round
        logDict["OperatingSystem"] = "iPadOS"
        logDict["PlatformNumber"] = "iPad"
        logDict["FromApp"] = "5"
        logDict["BuddyBid1"] = NSNumber(integerLiteral: 0)
        logDict["BuddyBid2"] = NSNumber(integerLiteral: 0)
        logDict["BuddyBid3"] = NSNumber(integerLiteral: 0)
        
        if bid4EmpNum != empNum{
            //cboffline events
            //send offline data with logdict
        }
    }
    
//    func handleAddSubmittedBid(empNumber: String, completion: @escaping (Bool) -> Void){
//        let bidReceipt = self.bidPeriod?.sortedBidReceipts()[0]
//        self.bidPeriod?.submittedBid = bidReceipt?.submittedLineNumbersString
//        
//        let mailInfoDict = NSMutableDictionary()
//        mailInfoDict["Year"] = self.bidPeriod?.year
//        mailInfoDict["Month"] = self.bidPeriod?.month
//        mailInfoDict["Round"] = self.bidPeriod?.round
//        mailInfoDict["Domicile"] = self.bidPeriod?.base
//        mailInfoDict["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: (self.bidPeriod?.positionType?.intValue)!)!)
//        mailInfoDict["EmpNum"] = Int(empNumber)
//        let bidNumbersString = bidReceipt?.submittedLineNumbersString
//        if bidNumbersString == nil || bidReceipt?.submittedBy == nil {
//            // send mail
//            // log missing emp number function
//            AlertService.showAlertForTopVC(title: "Oops!", message: "Your bid receipt has been returned with NO employee number.  This can occur when you are on a leave of absence.  Please contact us if you are not on a leave of absence.", actions: [(title: "OK", style: .default, handler: {_ in
//                completion(false)
//            })])
//            return
//        }
//        mailInfoDict["SubmittedResult"] = bidNumbersString
//        mailInfoDict["SubmitBy"] = bidReceipt?.submittedBy
//        mailInfoDict["SubmitFor"] = bidReceipt?.submittedFor
//        mailInfoDict["SubmitDTG"] = bidReceipt?.submittedDateString
//        mailInfoDict["FromApp"] = "5"
//        
//        if app.objNetworkType == .free{
//            //cboffline events
//            //add offline event
//            return
//        }
//        bidFileDownload?.addSubmittedBid(dict: mailInfoDict){ result in
//            if result == true {
//                self.bidPeriod?.submittedBid = bidNumbersString
//            }
//        }
//    }
    
    func handleAddSubmittedBid(empNumber: String, completion: @escaping (Bool) -> Void) {
        guard let bidReceipt = self.bidPeriod?.sortedBidReceipts().first else {
            completion(false)
            return
        }
        self.bidPeriod?.submittedBid = bidReceipt.submittedLineNumbersString
        
        var mailInfoDict: [String: Any] = [:]
        mailInfoDict["Year"] = self.bidPeriod?.year
        mailInfoDict["Month"] = self.bidPeriod?.month
        mailInfoDict["Round"] = self.bidPeriod?.round
        mailInfoDict["Domicile"] = self.bidPeriod?.base
        mailInfoDict["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: (self.bidPeriod?.positionType?.intValue)!)!)
        mailInfoDict["EmpNum"] = Int(empNumber)
        
        guard let bidNumbersString = bidReceipt.submittedLineNumbersString,
              let submittedBy = bidReceipt.submittedBy else {
            // send mail
            AlertService.showAlertForTopVC(
                title: "Oops!",
                message: "Your bid receipt has been returned with NO employee number. This can occur when you are on a leave of absence. Please contact us if you are not on a leave of absence.",
                actions: [(title: "OK", style: .default, handler: { _ in
                    completion(false)
                })]
            )
            return
        }
        
        mailInfoDict["SubmittedResult"] = bidNumbersString
        mailInfoDict["SubmitBy"] = submittedBy
        mailInfoDict["SubmitFor"] = bidReceipt.submittedFor ?? ""
        mailInfoDict["SubmitDTG"] = bidReceipt.submittedDateString ?? ""
        mailInfoDict["FromApp"] = "5"
        
        if app.objNetworkType == .free {
            // Handle offline case here
            return
        }
        
        addSubmittedBid(dict: mailInfoDict) { success in
            if success {
                self.bidPeriod?.submittedBid = bidNumbersString
            }
            completion(success)
        }
    }
    
    func addSubmittedBid(dict: [String: Any], completion: @escaping (Bool) -> Void) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            
            APIService.shared.fetch(
                urlString: EndPoint.shared.SaveBidSubmittedData,
                method: .POST,
                body: jsonData,
                parse: { data in
                    guard
                        let httpResponse = try? JSONSerialization.jsonObject(with: data, options: []),
                        let _ = httpResponse as? [String: Any] // expecting a JSON object
                    else {
                        throw Errors.decodingError
                    }
                    return true
                },
                completion: { result in
                    switch result {
                    case .success:
                        completion(true)
                    case .failure:
                        completion(false)
                    }
                }
            )
        } catch {
            completion(false)
        }
    }
    
    
    
    //for FA new API
    func handleBidSubmissionForFA(){
        let params = self.getFABidSubmissionParamString()
        self.swaBidDataDownload = BISwaBidDataDownload()
        //logging raw data into server
        self.handleRawDataSentToServer()
        //code for FA bid submission
        
    }
    
    func getFABidSubmissionParamString() -> NSDictionary{
        let bidChoices: [String] = (self.bidListNumbers) as? [String] ?? []
        
        let token = KeychainHelper.retrieveTokenFromKeyChain()
        let userDetails = JWTDecoder.decode(jwtToken: token!)!
        var submittedID = userDetails["cn"] as! String
        self.userID = submittedID
        submittedID = submittedID.lowercased()
        submittedID = submittedID.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "")
        
        //Buddy Bids
        let buddyBids = NSMutableDictionary()
        if self.optionalEmpNumbers.count > 0 {
            for employee in self.optionalEmpNumbers {
                if let emp = employee as? String {
                    buddyBids[emp] = bidChoices
                }
            }
        }
        
        //Submitting date
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        let submittedAt = dateFormatter.string(from: currentDate)
        
        //Constructing the bid details dictionary
        
        let bidDetails: NSDictionary = [
            "department": "IF",
            "packetID": ["base": self.bidPeriod!.base!,
                         "year": self.bidPeriod!.year!,
                         "schedulePeriod":CBUtils.shortMonthName(month: (self.bidPeriod?.month!.intValue)!, uc: true),
                         "roundType":self.bidPeriod?.round?.intValue == 1 ? "PRIMARY": "SECONDARY"],
            "employeeId": self.bidEmployeeNumber,
            "submittedBy": submittedID,
            "submittedAt": submittedAt,
            "buddyBids": buddyBids,
            "jobShare1": self.jobShare1 ?? "",
            "jobShare2": self.jobShare2 ?? "",
            "jobShareContingent": self.isJobShareContingency,
            "bidSource": "WEBBID",
            "mrtContingent": false,
            "bidChoices": bidChoices
        ]
        return bidDetails
    }
}
