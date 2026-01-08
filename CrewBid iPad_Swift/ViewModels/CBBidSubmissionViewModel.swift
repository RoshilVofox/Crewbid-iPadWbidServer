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
    init(bidPeriod: BIBidPeriod, userID: String,password: String, defaultEmpNum: String?, optionalEmpNum: NSArray, selectedObject:[String:Any]) {
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
    
    let bidReceipt = "7624\n1A\n1C\n1B\n2C\n2B\n2A\n3C\n3A\n3B\n4B\n4C\n4A\n5A\n5C\n5B\n6A\n6B\n6C\n7A\n7C\n7B\n8A\n8C\n8B\n9B\n9C\n9A\n10B\n10A\n10C\n11B\n11A\n11C\n13C\n13A\n13B\n14A\n14B\n14C\n15C\n15B\n15A\n16C\n16A\n16B\n17B\n17C\n17A\n18A\n18C\n18B\n22B\n22C\n22A\n23A\n23C\n23B\n24C\n24B\n24A\n26C\n26B\n26A\n27A\n27C\n27B\n28B\n28A\n28C\n29B\n29C\n29A\n30A\n30B\n30C\n33C\n33B\n33A\n34B\n34C\n34A\n35A\n35C\n35B\n36A\n36C\n36B\n37C\n37A\n37B\n38A\n38B\n38C\n39A\n39C\n39B\n40B\n40A\n40C\n41B\n41A\n41C\n42B\n42A\n42C\n43C\n43B\n43A\n44A\n44B\n44C\n45A\n45B\n45C\n46C\n46B\n46A\n47A\n47C\n47B\n59A\n59B\n59C\n60A\n60C\n60B\n61C\n61B\n61A\n62B\n62A\n62C\n63C\n63B\n63A\n64B\n64A\n64C\n65B\n65C\n65A\n66C\n66B\n66A\n67A\n67C\n67B\n68A\n68B\n68C\n69A\n69C\n69B\n70A\n70C\n70B\n71B\n71A\n71C\n72B\n72A\n72C\n73B\n73A\n73C\n74B\n74A\n74C\n85C\n85B\n85A\n86C\n86A\n86B\n87A\n87C\n87B\n88A\n88C\n88B\n89A\n89B\n89C\n90B\n90A\n90C\n91A\n91C\n91B\n92B\n92A\n92C\n93C\n93B\n93A\n94B\n94C\n94A\n95A\n95C\n95B\n96C\n96A\n96B\n97C\n97B\n97A\n98B\n98A\n98C\n99A\n99B\n99C\n100A\n100C\n100B\n101C\n101A\n101B\n113A\n113B\n113C\n114C\n114B\n114A\n115B\n115A\n115C\n116B\n116A\n116C\n117C\n117B\n117A\n118A\n118C\n118B\n119C\n119A\n119B\n120A\n120B\n120C\n121C\n121B\n121A\n122A\n122B\n122C\n123A\n123C\n123B\n124C\n124B\n124A\n125A\n125B\n125C\n126A\n126B\n126C\n139A\n139C\n139B\n140C\n140A\n140B\n141A\n141B\n141C\n142A\n142C\n142B\n143C\n143A\n143B\n144A\n144B\n144C\n145A\n145C\n145B\n146B\n146A\n146C\n147B\n147A\n147C\n148B\n148C\n148A\n149C\n149B\n149A\n150A\n150B\n150C\n151A\n151B\n151C\n152C\n152B\n152A\n167A\n167B\n167C\n168C\n168B\n168A\n169B\n169C\n169A\n170A\n170B\n170C\n171C\n171B\n171A\n172A\n172C\n172B\n173C\n173A\n173B\n174C\n174A\n174B\n175A\n175C\n175B\n176B\n176A\n176C\n177A\n177C\n177B\n178B\n178C\n178A\n179C\n179A\n179B\n180B\n180A\n180C\n181B\n181A\n181C\n182C\n182B\n182A\n196B\n196C\n196A\n197C\n197B\n197A\n198B\n198A\n198C\n199A\n199C\n199B\n200C\n200B\n200A\n201A\n201C\n201B\n202B\n202A\n202C\n203C\n203B\n203A\n204B\n204C\n204A\n205B\n205C\n205A\n206B\n206C\n206A\n207A\n207C\n207B\n208B\n208C\n208A\n209A\n209B\n209C\n222A\n222B\n222C\n223B\n223C\n223A\n224B\n224A\n224C\n225C\n225B\n225A\n226C\n226B\n226A\n227A\n227B\n227C\n228C\n228B\n228A\n229A\n229B\n229C\n230B\n230A\n230C\n231C\n231B\n231A\n232C\n232A\n232B\n233C\n233A\n233B\n234A\n234B\n234C\n235A\n235B\n235C\n236B\n236C\n236A\n237A\n237C\n237B\n238C\n238A\n238B\n239C\n239A\n239B\n240B\n240A\n240C\n253C\n253B\n253A\n254A\n254C\n254B\n255A\n255C\n255B\n256A\n256C\n256B\n257C\n257B\n257A\n258A\n258B\n258C\n259C\n259B\n259A\n260C\n260B\n260A\n261B\n261C\n261A\n262C\n262A\n262B\n263A\n263C\n263B\n264A\n264B\n264C\n265A\n265B\n265C\n266C\n266B\n266A\n267C\n267B\n267A\n268B\n268A\n268C\n269C\n269B\n269A\n270A\n270C\n270B\n286B\n286A\n286C\n287A\n287C\n287B\n288A\n288B\n288C\n289A\n289C\n289B\n290C\n290B\n290A\n291C\n291B\n291A\n292A\n292C\n292B\n293B\n293C\n293A\n294B\n294C\n294A\n295A\n295B\n295C\n296C\n296B\n296A\n297B\n297C\n297A\n298A\n298B\n298C\n299C\n299B\n299A\n300A\n300C\n300B\n301C\n301B\n301A\n302C\n302A\n302B\n303A\n303C\n303B\n304C\n304B\n304A\n305A\n305C\n305B\n306A\n306B\n306C\n307C\n307B\n307A\n308A\n308B\n308C\n309C\n309A\n309B\n327A\n327C\n327B\n328B\n328C\n328A\n329B\n329A\n329C\n330C\n330A\n330B\n331A\n331C\n331B\n332C\n332A\n332B\n333A\n333B\n333C\n334C\n334B\n334A\n335A\n335C\n335B\n336B\n336A\n336C\n337C\n337B\n337A\n338B\n338A\n338C\n339A\n339C\n339B\n340C\n340A\n340B\n341B\n341A\n341C\n342C\n342B\n342A\n352A\n352B\n352C\n353B\n353C\n353A\n354B\n354A\n354C\n355B\n355A\n355C\n356A\n356C\n356B\n357B\n357A\n357C\n358A\n358B\n358C\n359A\n359C\n359B\n360C\n360B\n360A\n361A\n361B\n361C\n362A\n362B\n362C\n363A\n363C\n363B\n364B\n364A\n364C\n365C\n365A\n365B\n366C\n366A\n366B\n367A\n367C\n367B\n368B\n368A\n368C\n369A\n369B\n369C\n370B\n370A\n370C\n371A\n371C\n371B\n372B\n372A\n372C\n373A\n373C\n373B\n387A\n387B\n387C\n388C\n388A\n388B\n389A\n389C\n389B\n390C\n390B\n390A\n391A\n391B\n391C\n392A\n392C\n392B\n393B\n393A\n393C\n394A\n394B\n394C\n395A\n395C\n395B\n396C\n396B\n396A\n397C\n397B\n397A\n398B\n398C\n398A\n399C\n399B\n399A\n400C\n400A\n400B\n401A\n401B\n401C\n402C\n402B\n402A\n403A\n403B\n403C\n414B\n414A\n414C\n415C\n415B\n415A\n416B\n416A\n416C\n417C\n417A\n417B\n418C\n418B\n418A\n419A\n419C\n419B\n420C\n420A\n420B\n421A\n421B\n421C\n422B\n422A\n422C\n423C\n423A\n423B\n424A\n424B\n424C\n425C\n425B\n425A\n426B\n426A\n426C\n427C\n427B\n427A\n428C\n428A\n428B\n429C\n429B\n429A\n430B\n430A\n430C\n431A\n431B\n431C\n432A\n432C\n432B\n433A\n433B\n433C\n434A\n434B\n434C\n435A\n435C\n435B\n436B\n436C\n436A\n437C\n437B\n437A\n452A\n452B\n452C\n453C\n453B\n453A\n454C\n454B\n454A\n455A\n455B\n455C\n456B\n456A\n456C\n457A\n457C\n457B\n458A\n458B\n458C\n459C\n459B\n459A\n460B\n460A\n460C\n461C\n461B\n461A\n462B\n462A\n462C\n463B\n463C\n463A\n464B\n464C\n464A\n465A\n465C\n465B\n466C\n466B\n466A\n467A\n467C\n467B\n468C\n468A\n468B\n469A\n469B\n469C\n470A\n470B\n470C\n471A\n471B\n471C\n472A\n472C\n472B\n473A\n473C\n473B\n474B\n474A\n474C\n475A\n475B\n475C\n476C\n476A\n476B\n477A\n477B\n477C\n497B\n497C\n497A\n498A\n498C\n498B\n499C\n499B\n499A\n500C\n500B\n500A\n501C\n501B\n501A\n502A\n502B\n502C\n503A\n503C\n503B\n504B\n504A\n504C\n505A\n505C\n505B\n506A\n506B\n506C\n507A\n507B\n507C\n508B\n508C\n508A\n509C\n509A\n509B\n510C\n510A\n510B\n511A\n511C\n511B\n512A\n512B\n512C\n513A\n513C\n513B\n514A\n514C\n514B\n515C\n515B\n515A\n516A\n516B\n516C\n517C\n517B\n517A\n518A\n518C\n518B\n519B\n519C\n519A\n520A\n520B\n520C\n521A\n521C\n521B\n522B\n522A\n522C\n523A\n523C\n523B\n524C\n524B\n524A\n525A\n525B\n525C\n526A\n526B\n526C\n527A\n527C\n527B\n528C\n528A\n528B\n529A\n529C\n529B\n530C\n530B\n530A\n531B\n531C\n531A\n532A\n532C\n532B\n533A\n533C\n533B\n534A\n534B\n534C\n535A\n535B\n535C\n536B\n536A\n536C\n537B\n537A\n537C\n538B\n538C\n538A\n539A\n539B\n539C\n540C\n540A\n540B\n541A\n541C\n541B\n542B\n542C\n542A\n543A\n543B\n543C\n544B\n544A\n544C\n545B\n545C\n545A\n546B\n546A\n546C\n547A\n547C\n547B\n548A\n548C\n548B\n549A\n549B\n549C\n550A\n550B\n550C\n551C\n551B\n552B\n552C\n553C\n553B\n554B\n554C\n555B\n555C\n595C\n595B\n595A\n596C\n596A\n596B\n597A\n597B\n597C\n598C\n598B\n598A\n599B\n599C\n599A\n600C\n600B\n600A\n*E\n8301\n*E\n SUBMITTED BY: [e7624]     7624    12/04/25 05:08:24\n"
    
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
        let bidChoices: [String] = (self.bidListNumbers) as? [String] ?? []
        
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
            "packetID": packet,
            "employeeId": self.bidEmployeeNumber ?? "",
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
