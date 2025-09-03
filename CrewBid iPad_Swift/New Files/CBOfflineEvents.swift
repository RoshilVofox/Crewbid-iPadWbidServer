//
//  CBOfflineEvents.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 01/09/25.
//

import Foundation

class CBOfflineEvents{
    
    func addOfflineNewSKPaymentStatusEvent(_ objOfflineData: [String: Any]) {
        // Get documents directory
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else { return }
        
        let path = (documentsDirectory as NSString).appendingPathComponent("OfflineSKPaymentData.plist")
        let fileManager = FileManager.default
        
        // Ensure file exists
        if !fileManager.fileExists(atPath: path) {
            let _ = (documentsDirectory as NSString).appendingPathComponent("OfflineSKPaymentData.plist")
        }
        
        // Load existing array
        var arrListEvents = [[String: Any]]()
        if let savedArray = NSArray(contentsOfFile: path) as? [[String: Any]], savedArray.count > 0 {
            arrListEvents = savedArray
        }
        
        // Add new event
        arrListEvents.append(objOfflineData)
        
        // Write back to file
        (arrListEvents as NSArray).write(toFile: path, atomically: true)
    }


    func addOfflineEvent(_ objOfflineData: [String: Any]) {
        var updatedData = objOfflineData
        
        if let base = updatedData["Base"] as? String {
            if base == "(null)" || base.isEmpty {
                updatedData["Base"] = "BWI"
            }
        } else {
            updatedData["Base"] = "BWI"
        }
        
        if updatedData["Month"] == nil || updatedData["Month"] is NSNull {
            let date = Date()
            let calendar = Calendar.current
            let month = calendar.component(.month, from: date)
            updatedData["Month"] = CBUtils.shortMonthName(month: month, uc: true)
        }
        
        if let posObject = updatedData["Position"] {
            if let pos = posObject as? NSNumber {
                switch pos.intValue {
                case 0: updatedData["Position"] = "CP"
                case 1: updatedData["Position"] = "FO"
                default: updatedData["Position"] = "FA"
                }
            } else if let pos = posObject as? String {
                updatedData["Position"] = pos
            } else {
                updatedData["Position"] = "CP"
            }
        } else {
            updatedData["Position"] = "CP"
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else { return }
        let path = (documentsDirectory as NSString).appendingPathComponent("OfflineData.plist")
        
        var arrListEvents = [[String: Any]]()
        if let savedArray = NSArray(contentsOfFile: path) as? [[String: Any]], savedArray.count > 0 {
            arrListEvents = savedArray
        }
        
        let currentDate = Date()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 6 * 3600)
        let utc6DateString = isoFormatter.string(from: currentDate)
        
        var dicData = [String: Any]()
        dicData["date"] = utc6DateString
        dicData["LogDetails"] = updatedData
        
        arrListEvents.append(dicData)
        (arrListEvents as NSArray).write(toFile: path, atomically: true)
    }

    func addFromOfflineNewSKPaymentStatusLog() {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else { return }
        let path = (documentsDirectory as NSString).appendingPathComponent("OfflineSKPaymentData.plist")
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            // ensure path is created with correct file name
            _ = (documentsDirectory as NSString).appendingPathComponent("OfflineSKPaymentData.plist")
        }
        
        guard let savedValue = NSMutableArray(contentsOfFile: path), savedValue.count > 0 else {
            return
        }
        
        var dicMainData = [String: Any]()
        dicMainData["InAppStates"] = savedValue
        
        guard let url = URL(string: EndPoint.shared.logInAppStatus) else { return }
        var urlRequest = URLRequest(url: url)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicMainData, options: [])
            urlRequest.httpBody = jsonData
        } catch {
            print("JSON serialization error: \(error)")
            return
        }
        
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let httpResponse = response as? HTTPURLResponse,
               let mimeType = response?.mimeType,
               httpResponse.statusCode == 200,
               mimeType.contains("application/json") {
                
                if let str = String(data: data, encoding: .utf8),
                   let flag = Bool(str), flag {
                    do {
                        try fileManager.removeItem(atPath: path)
                    } catch {
                        print("Failed to remove file: \(error)")
                    }
                }
            }
        }
        task.resume()
    }

    func addOfflinePayment(_ objOfflineData: NSMutableDictionary) {
        
        let month = (objOfflineData["Month"] as? NSNumber)?.intValue ?? 0
        if month == 0 {
            return
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else { return }
        var path = (documentsDirectory as NSString).appendingPathComponent("OfflinePayment.plist")
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            path = (documentsDirectory as NSString).appendingPathComponent("OfflinePayment.plist")
        }
        
        objOfflineData.write(toFile: path, atomically: true)
    }
    
    
    func sendOfflineData() {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else { return }
        let path = (documentsDirectory as NSString).appendingPathComponent("OfflineData.plist")
        
        guard let arrEvents = NSMutableArray(contentsOfFile: path), arrEvents.count > 0 else {
            return
        }
        
        let dicMainData = NSMutableDictionary()
        dicMainData.setObject(arrEvents, forKey: "EventLogs" as NSCopying)
        
        guard let url = URL(string: EndPoint.shared.logOfflineEventsRest) else { return }
        
        var urlRequest = URLRequest(url: url)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicMainData, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            urlRequest.httpBody = jsonString.data(using: .utf8)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        } catch {
            print("JSON serialization error: \(error)")
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let data = data,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let mimeType = response?.mimeType,
               mimeType.contains("application/json") {
                
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Failed to remove file: \(error)")
                }
            }
        }
        dataTask.resume()
    }
    
    func updateOfflinePayment() {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else { return }
        let path = (documentsDirectory as NSString).appendingPathComponent("OfflinePayment.plist")
        
        guard let dicOffline = NSMutableDictionary(contentsOfFile: path), dicOffline.count > 0 else {
            return
        }
        
        guard let app = UIApplication.shared.delegate as? AppDelegate, app.connectedToInternet() else {
            return
        }
        
        guard let messageString = dicOffline["Message"] as? String else { return }
        let arrMessage = messageString.components(separatedBy: ",")
        
        let messageData = arrMessage.first ?? ""
        let type = arrMessage.count > 1 ? arrMessage[1] : "CrewBid"
        
        if type == "WBid" {
            
            dicOffline["AppNum"] = "5"
            dicOffline["Message"] = "SouthWestWifi \(messageData)"
            
            guard let url = URL(string: EndPoint.shared.updateWBidPaidUntilDate) else { return }
            var urlRequest = URLRequest(url: url)
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dicOffline, options: [])
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                print("----Data---\(jsonString)")
                
                urlRequest.httpBody = jsonString.data(using: .utf8)
                urlRequest.httpMethod = "POST"
                
            } catch {
                print("JSON serialization error: \(error)")
                return
            }
            
            let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                guard let data = data, let httpResponse = response as? HTTPURLResponse else { return }
                
                let mimeType = response?.mimeType ?? ""
                print("Status--\(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 && mimeType.contains("application/json") {
                    do {
                        if let res = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? NSMutableDictionary {
                            let flag = (res["Status"] as? Bool) ?? false
                            if flag {
                                if let wbExpirationDate = res["WBExpirationDate"] {
                                    app.ObjUserAccount!.dicLoginAuthDetails["WBExpirationDate"] = wbExpirationDate
                                    app.ObjUserAccount!.saveUserInfo()
                                    self.saveWbidExpirationDate("\(wbExpirationDate)")
                                    
                                    do {
                                        try FileManager.default.removeItem(atPath: path)
                                    } catch {
                                        print("Failed to delete plist: \(error)")
                                    }
                                    
                                    NotificationCenter.default.post(name: Notification.Name("UpdateSubscription"), object: nil)
                                }
                            }
                        }
                    } catch {
                        print("JSON parse error: \(error)")
                    }
                }
            }
            dataTask.resume()
            
        } else {
            let isRest = UserDefaults.standard.bool(forKey: kCBIsRest)
            if isRest {
                self.updateCrewBidPaidUntilDateRest(dicOffline, messageData: messageData)
            } else {
                self.updateCrewBidPaidUntilDateSoap(dicOffline, messageData: messageData)
            }
        }
    }
    
    
    func saveWbidExpirationDate(_ date: String) {
//        // Convert JSON date string to Date using your helper
//        guard let expiryDate = getDateFromJSON(date) else {
//            return
//        }
//
//        let formattedDate = "\(expiryDate)"
//        guard !formattedDate.isEmpty else {
//            return
//        }
//
//        // Compare with best available WBID expiration date
//        if let bestAvailableDate = CBIAPHelper.sharedInstance().getBestAvailableWbidExpirationDate() {
//            let maxWBDate = CBIAPHelper.sharedInstance().bestDate(from: expiryDate, date2: bestAvailableDate)
//
//            // Save encrypted expiration dates
//            CBIAPHelper.sharedInstance().setICloudEncryptedWbidExpirationDate(maxWBDate)
//            CBIAPHelper.sharedInstance().setLocalEncryptedWbidExpirationDate(maxWBDate)
//
//        }
    }
    
    func getDateFromJSON(_ string: String) -> Date? {
        // Regex pattern to match /Date(1268123281843+0530)/
        let pattern = #"^/date\((-?\d+)(?:([+-])(\d{2})(\d{2}))?\)/$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let match = regex.firstMatch(in: string, options: [], range: range) else {
            return nil
        }
        
        // Extract milliseconds
        if let millisRange = Range(match.range(at: 1), in: string) {
            let millisString = String(string[millisRange])
            if let millis = Double(millisString) {
                var seconds = millis / 1000.0
                
                // Handle timezone offset if present
                if match.range(at: 2).location != NSNotFound,
                   let signRange = Range(match.range(at: 2), in: string),
                   let hoursRange = Range(match.range(at: 3), in: string),
                   let minutesRange = Range(match.range(at: 4), in: string) {
                    
                    let sign = String(string[signRange]) // "+" or "-"
                    let hours = Double(sign + String(string[hoursRange])) ?? 0
                    let minutes = Double(sign + String(string[minutesRange])) ?? 0
                    
                    seconds += hours * 3600.0
                    seconds += minutes * 60.0
                }
                
                return Date(timeIntervalSince1970: seconds)
            }
        }
        
        return nil
    }
    
    
    func updateCrewBidPaidUntilDateRest(_ dicOffline: NSMutableDictionary, messageData: String) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        // File path for OfflinePayment.plist
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else { return }
        let path = (documentsDirectory as NSString).appendingPathComponent("OfflinePayment.plist")
        
        // Add formatted message to dictionary
        let message = "SouthWestWifi \(messageData)"
        dicOffline["Message"] = message
        
        // Prepare URL
        guard let url = URL(string: EndPoint.shared.updateWBidPaidUntilDate) else { return }
        var urlRequest = URLRequest(url: url)
        
        // Convert dictionary to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicOffline, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("----Data---\(jsonString)")
            }
            urlRequest.httpBody = jsonData
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        } catch {
            print("JSON Serialization error: \(error)")
            return
        }
        
        // Send request
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, error == nil else {
                print("Request failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let mimeType = response?.mimeType ?? ""
                print("Status--\(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200, mimeType.contains("application/json") {
                    do {
                        if let res = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any],
                           let flag = res["Status"] as? Bool, flag {
                            
                            // Update account info
                            app.ObjUserAccount?.topSubscriptionLine = res["TopSubscriptionLine"] as! String
                            app.ObjUserAccount?.secondSubscriptionLine = res["SecondSubscriptionLine"] as! String
                            app.ObjUserAccount?.thirdSubscriptionLine = res["ThirdSubscriptionLine"] as! String
                            app.ObjUserAccount?.LoginuserId = app.ObjUserAccount!.EmpNum
                            
                            app.ObjUserAccount?.dicLoginAuthDetails["TopSubscriptionLine"] = app.ObjUserAccount?.topSubscriptionLine
                            app.ObjUserAccount?.dicLoginAuthDetails["SecondSubscriptionLine"] = app.ObjUserAccount?.secondSubscriptionLine
                            app.ObjUserAccount?.dicLoginAuthDetails["ThirdSubscriptionLine"] = app.ObjUserAccount?.thirdSubscriptionLine
                            app.ObjUserAccount?.dicLoginAuthDetails["CBExpirationDate"] = res["CBExpirationDate"]
                            app.ObjUserAccount?.dicLoginAuthDetails["WBExpirationDate"] = res["WBExpirationDate"]
                            
                            app.ObjUserAccount?.saveUserInfo()
                            
                            if let cbDate = res["CBExpirationDate"] {
                                self.saveCBExpirationdate("\(cbDate)")
                            }
                            if let wbDate = res["WBExpirationDate"] {
                                self.saveWbidExpirationDate("\(wbDate)")
                            }
                            
                            // Remove offline payment file
                            do {
                                try FileManager.default.removeItem(atPath: path)
                            } catch {
                                print("Error removing file: \(error)")
                            }
                            
                            // Notify UI
                            NotificationCenter.default.post(name: Notification.Name("UpdateSubscription"), object: nil)
                        }
                    } catch {
                        print("JSON parsing error: \(error)")
                    }
                }
            }
        }
        task.resume()
    }
    
    
    func saveCBExpirationdate(_ date: String) {
        // Convert JSON date string to NSDate
        guard let expiryDate = getDateFromJSON(date) else { return }
        
        let formattedDate = "\(expiryDate)"
        if formattedDate.isEmpty {
            return
        }
        
        // Get max CB expiration date
        let maxCBDate = CBIAPHelper.shared.bestDate(from: expiryDate,
                                                              date2: CBIAPHelper.shared.getBestAvailableExpirationDate())
        
        // Save to iCloud and local storage
        CBIAPHelper.shared.setICloudEncryptedExpirationDate(maxCBDate)
        CBIAPHelper.shared.setLocalEncryptedExpirationDate(maxCBDate)

    }
    
    func updateCrewBidPaidUntilDateSoap(_ dicOffline: NSMutableDictionary, messageData: String) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        // Documents path
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else { return }
        let path = (documentsDirectory as NSString).appendingPathComponent("OfflinePayment.plist")
        
        // Add Message
        let message = "SouthWestWifi \(messageData)"
        dicOffline["Message"] = message
        
        let urlName = "UpdateCrewBidPaidUntilDateSoap"
//        app.SC?.constructUrl(urlName)   // assuming constructUrl exists
        
        // Build SOAP message
        let soapMessage = """
        <x:Envelope xmlns:x="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wbi="http://WbidAuthService/" xmlns:wbi1="http://schemas.datacontract.org/2004/07/WBidDataDownloadAuthorizationService.Model">
            <x:Header/>
            <x:Body>
                <wbi:UpdateCrewBidPaidUntilDateSoap>
                    <wbi:paymentdetails>
                        <wbi1:AppNum>5</wbi1:AppNum>
                        <wbi1:EmpNum>\(dicOffline["EmpNum"] ?? "")</wbi1:EmpNum>
                        <wbi1:IpAddress>\(dicOffline["IpAddress"] ?? "")</wbi1:IpAddress>
                        <wbi1:Message>\(dicOffline["Message"] ?? "")</wbi1:Message>
                        <wbi1:Month>\(dicOffline["Month"] ?? "")</wbi1:Month>
                        <wbi1:TransactionNumber>\(dicOffline["TransactionNumber"] ?? "")</wbi1:TransactionNumber>
                    </wbi:paymentdetails>
                </wbi:UpdateCrewBidPaidUntilDateSoap>
            </x:Body>
        </x:Envelope>
        """
        
        // Service URL
        var serviceURL = "\(app.Domain ?? "")soap"
        serviceURL = serviceURL.replacingOccurrences(of: " ", with: "%20")
        guard let url = URL(string: serviceURL) else { return }
        
        // Build Request
        var request = URLRequest(url: url)
        let msgLength = "\(soapMessage.count)"
        request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let soapAction = "http://WbidAuthService/IWBidDataDwonloadAuthService/\(urlName)"
        request.addValue(soapAction, forHTTPHeaderField: "SOAPAction")
        request.addValue(msgLength, forHTTPHeaderField: "Content-Length")
        request.timeoutInterval = 60
        request.httpMethod = "POST"
        request.httpBody = soapMessage.data(using: .utf8)
        
        // Execute request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let xmlString = String(data: data, encoding: .utf8) {
                // You had a dependency on "dictionaryWithXMLString" (probably XMLDictionary library).
                // In Swift, you can use XMLParser or a third-party parser.
                // Placeholder for dictionary parsing:
                if let xmlDict = NSDictionary(contentsOfFile: xmlString) as? [String: Any] {
                    // Extract deeply nested keys safely
                    if
                        let body = xmlDict["Body"] as? [String: Any],
                        let response = body["UpdateCrewBidPaidUntilDateSoapResponse"] as? [String: Any],
                        let result = response["UpdateCrewBidPaidUntilDateSoapResult"] as? [String: Any],
                        let flag = (result["Status"] as? NSString)?.boolValue, flag == true
                    {
                        // Update UserAccount
                        if let topLine = result["TopSubscriptionLine"] as? String {
                            app.ObjUserAccount?.topSubscriptionLine = topLine
                            app.ObjUserAccount?.dicLoginAuthDetails["TopSubscriptionLine"] = topLine
                        }
                        if let secondLine = result["SecondSubscriptionLine"] as? String {
                            app.ObjUserAccount?.secondSubscriptionLine = secondLine
                            app.ObjUserAccount?.dicLoginAuthDetails["SecondSubscriptionLine"] = secondLine
                        }
                        if let thirdLine = result["ThirdSubscriptionLine"] as? String {
                            app.ObjUserAccount?.thirdSubscriptionLine = thirdLine
                            app.ObjUserAccount?.dicLoginAuthDetails["ThirdSubscriptionLine"] = thirdLine
                        }
                        app.ObjUserAccount?.LoginuserId = app.ObjUserAccount!.EmpNum
                        
                        // Handle expiration dates
                        if let cbExpirationDate = result["CBExpirationDate"] as? String,
                           let expiryDate = self.formatedSoapDate(cbExpirationDate) {
                            let formatted = "\(expiryDate)"
                            app.ObjUserAccount?.dicLoginAuthDetails["CBExpirationDate"] = formatted
                            self.saveSoapCBExpirationDate(cbExpirationDate)
                            
                            let ms = expiryDate.timeIntervalSince1970 * 1000
                            let dateStarted = "/Date(\(Int(ms))+0800)/"
                            app.ObjUserAccount?.dicLoginAuthDetails["CBExpirationDate"] = dateStarted
                        }
                        
                        if let wbExpirationDate = result["WBExpirationDate"] as? String,
                           let expiryDate = self.formatedSoapDate(wbExpirationDate) {
                            let formatted = "\(expiryDate)"
                            app.ObjUserAccount?.dicLoginAuthDetails["WBExpirationDate"] = formatted
                            self.saveSoapWbidExpirationDate(wbExpirationDate)
                            
                            let ms = expiryDate.timeIntervalSince1970 * 1000
                            let dateStarted = "/Date(\(Int(ms))+0800)/"
                            app.ObjUserAccount?.dicLoginAuthDetails["WBExpirationDate"] = dateStarted
                        }
                        
                        app.ObjUserAccount?.saveUserInfo()
                        
                        // Remove offline payment file
                        try? FileManager.default.removeItem(atPath: path)
                        
                        // Notify
                        NotificationCenter.default.post(name: Notification.Name("UpdateSubscription"), object: nil)
                    }
                }
            }
        }
        task.resume()
    }
    
    func saveSoapCBExpirationDate(_ date: String) {
        guard let expiryDate = formatedSoapDate(date) else {
            return
        }
        
        let formattedDate = "\(expiryDate)"
        if formattedDate.isEmpty {
            return
        }
        
        let maxCBDate = CBIAPHelper.shared.bestDate(
            from: expiryDate,
            date2: CBIAPHelper.shared.getBestAvailableExpirationDate()
        )
        
        CBIAPHelper.shared.setICloudEncryptedExpirationDate(maxCBDate)
        CBIAPHelper.shared.setLocalEncryptedExpirationDate(maxCBDate)
    }
    
    func saveSoapWbidExpirationDate(_ date: String) {
        guard let expiryDate = formatedSoapDate(date) else {
            return
        }
        
        let formattedDate = "\(expiryDate)"
        if formattedDate.isEmpty {
            return
        }
        
        let maxWBDate = CBIAPHelper.shared.bestDate(
            from: expiryDate,
            date2: CBIAPHelper.shared.getBestAvailableWbidExpirationDate()
        )
        
        CBIAPHelper.shared.setICloudEncryptedWbidExpirationDate(maxWBDate!)
        CBIAPHelper.shared.setLocalEncryptedWbidExpirationDate(maxWBDate!)
    }
    
    func formatedSoapDate(_ date: String) -> Date? {
        let dateFormatter = DateFormatter()
        let formattedDateString = applyTimezoneFixForDate(date)
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = Locale.current
        
        var expiryDate = dateFormatter.date(from: formattedDateString)
        
        if expiryDate == nil {
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            fallbackFormatter.locale = Locale.current
            expiryDate = fallbackFormatter.date(from: date)
        }
        
        return expiryDate
    }
    
    func applyTimezoneFixForDate(_ date: String) -> String {
        if let colonRange = date.range(of: ":", options: .backwards) {
            var fixedDate = date
            fixedDate.replaceSubrange(colonRange, with: "")
            return fixedDate
        }
        return date
    }
    
    func sendOfflineDataForTimeOut(url: String, month: NSNumber?) {
        DispatchQueue.main.async {
            var dicMailInfo: [String: Any] = [:]
            let base = "BWI"
            
            let objUserAccount = CBUserAccountDetail()
            let empNum: String
            let position: NSNumber
            
            if objUserAccount.isUserInfoAvailable() {
                empNum = objUserAccount.EmpNum
                position = NSNumber(value: objUserAccount.Position)
            } else {
                empNum = ""
                position = 1
            }
            
            dicMailInfo["EmployeeNumber"] = empNum
            dicMailInfo["Event"] = "AWSServiceTimeOut"
            dicMailInfo["EventName"] = "AWSServiceTimeOut"
            dicMailInfo["Message"] = url
            dicMailInfo["Base"] = base
            dicMailInfo["Position"] = position
            dicMailInfo["Round"] = 1
            dicMailInfo["OperatingSystemNum"] = "iPad OS"
            dicMailInfo["VersionNumber"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            dicMailInfo["PlatformNumber"] = "iPad"
            dicMailInfo["BidForEmpNum"] = 0
            dicMailInfo["BuddyBid1"] = 0
            dicMailInfo["BuddyBid2"] = 0
            dicMailInfo["BuddyBid3"] = 0
            dicMailInfo["FromApp"] = "5"
            dicMailInfo["FromAppNum"] = "5"
            
            if let month = month {
                let myInt = month.intValue
                dicMailInfo["Month"] = CBUtils.shortMonthName(month: myInt, uc: true)
            }
            
            let startDate = CFAbsoluteTimeGetCurrent() * 1000
            let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)
            dicMailInfo["Date"] = dateStarted
            
            print("DicmailInfo \(dicMailInfo)")
            
            self.addOfflineEvent(dicMailInfo)
            self.sendOfflineData()
        }
    }
    
}

