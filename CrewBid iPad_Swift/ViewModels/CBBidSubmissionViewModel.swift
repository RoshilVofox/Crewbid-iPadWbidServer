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
    var password:String?
    var bidEmployeeNumber :String? // default Emp
    var optionalEmpNumbers = NSArray()
    var bidListNumbers = NSMutableArray()
    var app:AppDelegate!
    var isBiddingIDCertified:Bool = false
    let dataSource = GlobalBidInfo.shared
    var swaBidDataDownload = BISwaBidDataDownload()
    
    var jobShare1:String?
    var jobShare2:String?
    var isJobShareContingency:Bool = false
    init(bidPeriod: BIBidPeriod, userID: String,password: String?, defaultEmpNum: String?, optionalEmpNum: NSArray, selectedObject:[String:Any]) {
        self.app = UIApplication.shared.delegate as? AppDelegate
        self.bidPeriod = bidPeriod
        self.optionalEmpNumbers = optionalEmpNum
        self.bidEmployeeNumber = defaultEmpNum
        self.userID = userID.lowercased()
        self.password = password
        if let js1 = selectedObject["jobShare1"] as? String, !js1.isEmpty {
            self.jobShare1 = js1
        }
        if let js2 = selectedObject["jobShare2"] as? String, !js2.isEmpty {
            self.jobShare2 = js2
        }
        self.isJobShareContingency = selectedObject["isJobShareContingency"] as? Bool ?? false
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

    
    func startBidSubmission(sessionKey: String? = nil, completion: @escaping (Result<Bool, Error>) -> Void){
        if bidPeriod!.isFABid() && (self.bidPeriod?.isSwaAPI?.boolValue == true){
            //MARK: bid submission for FA
            // new API
            self.handleBidSubmissionForFA(){result in
                switch result{
                case .success(let submitted):
                    completion(.success(submitted))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            CBGlobalMethods.shared.certified = false
        }else{
            //MARK: bid submission for Pilot
            //get the httpBody format for bid submission
            guard let sessionKey = sessionKey, !sessionKey.isEmpty else {
                let err = NSError(domain: "CBBidSubmission", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Missing session key for pilot submission."])
                completion(.failure(err))
                return
            }
            
            guard let bidEmployeeNumber = self.bidEmployeeNumber, !bidEmployeeNumber.isEmpty else {
                let err = NSError(domain: "CBBidSubmission", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Missing employee number for pilot submission."])
                completion(.failure(err))
                return
            }

            let httpBody = self.setupBidSubmissionFormat(sessionKey: sessionKey, bidEmployeeNumber: bidEmployeeNumber, packetID: self.getPacketID(), avoidanceEmpID: self.optionalEmpNumbers)
            print(httpBody)
            //logging raw data into server
//            self.handleRawDataSentToServer()
            self.handleSubmissionRawDataToServer(year: self.dataSource.year, month: self.dataSource.month, round: self.dataSource.round, fromApp: "5", position: self.dataSource.position.shortName, rawData: httpBody, empNum: bidEmployeeNumber, domicile: self.dataSource.base)
            
            self.submitBid(httpBody: httpBody) { result in
                switch result {
                case .success(let dataString):
                    self.bidPeriod?.addBidReceiptWithText(bidReceiptText: dataString)
                    self.handleLogBidSubmissionProcess(event: "submitBid", SWAmessage: "", message: "Bid Submit")
                    if CBGlobalMethods.shared.certified {
                        self.handleLogBidSubmissionProcessCertify()
                    }
                    completion(.success(true))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
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
        &BIDDER=\(bidEmployeeNumber ?? "")\(optionalParameters)
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
            "EmployeeNumber": self.bidEmployeeNumber ?? "",
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
                if data.isEmpty{
                    return [:]
                }
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

        let bidNumbers = self.bidListNumbers.compactMap { "\($0)" }

        let parts: [String] = [
            "REQUEST=UPLOAD_BID",
            "&CREDENTIALS=\(sessionKey)",
            "&PACKETID=\(packetID)",
            "&BIDDER=\(bidEmployeeNumber)\(optionalParameters)",
            "&BASE=\(dataSource.base)",
            "&SEAT=\(dataSource.position.shortName)",
            "&BIDROUND=Round \(dataSource.round)",
            "&VENDOR=\(kVendor)",
            "&BID=\(bidNumbers.joined(separator: ","))"
        ]

        return parts.joined()
    }
    
    func stringByAddingPercentEscapes(to unescapedString: String) -> String {
        let allowedCharacterSet = CharacterSet(charactersIn: ";/?:@&=+$,").inverted
        return unescapedString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    }
    
    //MARK: Server Logging
    
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
            "EmployeeNumber": Int(empNum) ?? 0,
            "FromApp": Int(fromApp) ?? 5,
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
                
                if data.isEmpty {
                    return [:]   // empty success
                }
                
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

    func handleLogBidSubmissionProcess(event: String, SWAmessage: String, message: String) {
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
        
//        var round = ""
//        if bidPeriod?.round?.intValue == 1 {
//            round = "M"
//        } else if bidPeriod?.round?.intValue == 2 {
//            round = "S"
//        }
        mailInfoDict["Round"] = self.bidPeriod?.round?.intValue ?? 0
        mailInfoDict["SWAMessage"] = SWAmessage
        mailInfoDict["Message"] = message
        mailInfoDict["OperatingSystemNum"] = "iPad OS"
        mailInfoDict["VersionNumber"] = appVersion
        mailInfoDict["PlatformNumber"] = "iPad"
        
        if let defaultEmp = self.bidEmployeeNumber?
            .replacingOccurrences(of: "e", with: "")
            .trimmingCharacters(in: .symbols){
            mailInfoDict["BidForEmpNum"] = Int(defaultEmp)
        }
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
            let offlineEvents = CBOfflineEvents()
            mailInfoDict["Message"] = "SouthWestWifi \(event)"
            offlineEvents.addOfflineEvent(mailInfoDict)
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
                    if data.isEmpty {
                        return [:]   // empty success
                    }
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
        let bid4EmpNum = self.bidEmployeeNumber ?? ""
        let message = String(format: "Certify with empnum %@ and %@ as the bid4EmpNum.", empNum, bid4EmpNum)
        logDict["Message"] = message
        logDict["BidForEmpNum"] = bid4EmpNum
        
        logDict["Event"] = "certify"
        
        logDict["EmployeeNumber"] = empNum

        
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
    
    func addSubmittedDataToServerForFA(completion: @escaping (Bool) -> Void){
//        let bidLineNumbers = self.bidListNumbers
        guard let bidReceipts = bidPeriod?.sortedBidReceipts() else {
            completion(false)
            return
        }
        let total = bidReceipts.count
        if total == 0 {
            completion(true)
            return
        }
        var processed = 0
        
        for bidReceipt in bidReceipts {
            self.handleAddSubmittedBid(empNumber: bidReceipt.submittedFor!) { success in
                
                processed += 1
                
                if !success {
                    completion(false)
                    return
                }
                
                // All submissions finished
                if processed == total {
                    completion(true)
                }
            }
        }
    }
    
    
    func handleAddSubmittedBid(empNumber: String, completion: @escaping (Bool) -> Void) {
        guard let bidReceipt = self.bidPeriod?.sortedBidReceipts().first else {
            completion(false)
            return
        }
//        self.bidPeriod?.submittedBid = bidReceipt.submittedLineNumbersString
        
        var mailInfoDict: [String: Any] = [:]
        mailInfoDict["Year"] = self.bidPeriod?.year
        mailInfoDict["Month"] = self.bidPeriod?.month
        mailInfoDict["Round"] = self.bidPeriod?.round
        mailInfoDict["Domicile"] = self.bidPeriod?.base
        mailInfoDict["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: (self.bidPeriod?.positionType?.intValue)!)!)
        mailInfoDict["EmpNum"] = Int(empNumber)
        
        guard let bidNumbersString = bidReceipt.submittedLineNumbersString,
              let submittedBy = bidReceipt.submittedBy?.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "") else {
                let mailObj = CBSendMail()
            mailObj.sendBidReceiptErrorMail(bidReceipt.text ?? "")
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
            let objEvent = CBOfflineEvents()
            objEvent.addOfflineEvent(mailInfoDict)
            completion(false)
            return
        }
        
        self.addSubmittedBid(dict: mailInfoDict) { success in
            guard success else {
                completion(false)
                return
            }
            
            self.bidPeriod?.submittedBid = bidNumbersString
            
            completion(true)
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
    func handleBidSubmissionForFA(completion: @escaping (Result<Bool,Error>) -> Void){
        let params = self.getFABidSubmissionParamString()
        
        self.handleRawDataSentToServer()
        self.swaBidDataDownload?.submitBid(params: params){ response in
            switch response{
            case .success(let result):
                
                guard
                    let embedded = result["_embedded"] as? [String: Any],
                    let bidReceipts = embedded["IFLineBaseAuctionBids"] as? [[String: Any]]
                else {
                    completion(.failure(Errors.other("Invalid JSON format" as! Error)))
                    return
                }
                
                self.bidPeriod?.addBidReceipt(withJSON: bidReceipts)
                
                let message = self.getConfirmationNum(bidReceipts)
                
                self.handleLogBidSubmissionProcess(event: "submitBid", SWAmessage: "", message: message)
                if CBGlobalMethods.shared.certified {
                    self.handleLogBidSubmissionProcessCertify()
                }
                completion(.success(true))
                
            case .failure(let error):
                
                completion(.failure(error))
            }
        }
    }
    
    
    func getFABidSubmissionParamString() -> [String: Any]{
        let bidChoices: [Int] = (self.bidListNumbers) as? [Int] ?? []
        
        let token = KeychainHelper.retrieveTokenFromKeyChain()!
        let userDetails = JWTDecoder.decode(jwtToken: token)!
        var submittedID = userDetails["cn"] as! String
        self.userID = submittedID
        submittedID = submittedID.lowercased()
        submittedID = submittedID.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "")
        
        //Buddy Bids
        var buddyBids: [String: Any] = [:]
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
        
        let packet: [String: Any] = [
            "base": self.bidPeriod!.base!,
            "year": self.bidPeriod!.year!,
            "schedulePeriod": CBUtils.shortMonthName(month: self.bidPeriod!.month!.intValue, uc: true),
            "roundType": self.bidPeriod!.round?.intValue == 1 ? "PRIMARY" : "SECONDARY"
        ]

        let bidDetails: [String: Any] = [
            "department": "IF",
            "packetId": packet,
            "employeeId": self.bidEmployeeNumber ?? NSNull(),
            "submittedBy": submittedID,
            "submittedAt": submittedAt,
            "buddyBids": buddyBids,
            "jobShare1": self.jobShare1 ?? NSNull(),
            "jobShare2": self.jobShare2 ?? NSNull(),
            "jobShareContingent": self.isJobShareContingency,
            "bidSource": "WEBBID",
            "mrtContingent": false,
            "bidChoices": bidChoices
        ]
        
        return bidDetails
    }
    
    func getConfirmationNum(_ bidReceipts: [[String: Any]]) -> String {
        var message = "Submit Bid"

        for dict in bidReceipts {
            guard
                let userID = dict["employeeId"] as? String,
                let confirmNum = dict["confirmationNumber"] as? String
            else { continue }

            if message == "Submit Bid" {
                message += " \(userID) - \(confirmNum)"
            } else {
                message += ", \(userID) - \(confirmNum)"
            }
        }

        return message
    }
}
