

import UIKit
import StoreKit


let kCCPromoCodeNameKey = "Name"
let kCCPromoCodeDateKey = "ExpirationDate"
let kCCPromoCodeUsedKey = "IsUsed"
let kCCPromoCodeParseClass = "PromoCode"
let kCCPromoCodeLengthKey = "Length"

let kLabelTag: Int = 10
let kImageViewTag: Int = 20
let kCellBorderWidth: CGFloat = 4.0


enum Webservice {
    case getSubscriptionDetails
    case updateSubscriptionDetails
    case updateMaxSubscription
}

class CBSubscriptionInfoController: BaseViewController, ServiceConnectionDelegate {
    
    func responseError(_ errMsg: String) {
        self.networkFailureMessage()
    }
    
    func networkFailureMessage() {
        if webType == .updateSubscriptionDetails || webType == .updateMaxSubscription {
            offlinePayment()
        }
        
        let alert = UIAlertController(
            title: "Something went wrong",
            message: "Please contact us. We would love to help.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
            self?.view.hideActivityIndicator()
        }
        
        alert.addAction(okAction)
        present(alert, animated: true)
        
        self.view.hideActivityIndicator()
    }
    
    func offlinePayment() {
        guard let demo = dicOfflinePaymentData["Month"] as? NSNumber else { return }
        let months = demo.intValue
        let transactionID = dicOfflinePaymentData["TransactionID"] as? String
        
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        objDataBuilder = ODataBuilder()
        
        var dicData: [String: Any] = [:]
        
        // Employee number
        let userDefaultsEmployeeNumber = "\(app.ObjUserAccount?.employeeNumber ?? "")"
        guard !userDefaultsEmployeeNumber.isEmpty else { return }
        
        dicData["EmpNum"] = app.ObjUserAccount?.employeeNumber
        dicData["Month"] = months
        if let transactionID = transactionID {
            dicData["TransactionNumber"] = transactionID
        }
        dicData["AppNum"] = 5
        
        // Message depending on months/purchase type
        if months == 1 {
            if purchaseType == "WBid" {
                dicData["Message"] = "PaymentReceived for Onetime Monthly,WBid"
            } else {
                dicData["Message"] = "PaymentReceived for Onetime Monthly,CrewBid"
            }
        } else if months == 6 {
            dicData["Message"] = "PaymentReceived for 6 months"
        }
        
        dicData["IpAddress"] = app.IPAddress
        if let transactionID = transactionID {
            dicData["TransactionID"] = transactionID
        }
        
        // Send mail if network type is PAID or GROUND
        if app.objNetworkType == .paid || app.objNetworkType == .ground {
            sendPaymentFailedMailToAdmin("\(dicData.description)")
        }
        
        // Save offline payment
        let objEvent = CBOfflineEvents()
        objEvent.addOfflinePayment(dicData as! NSMutableDictionary)
    }
    
    func sendPaymentFailedMailToAdmin(_ data: String) {
        let sendmail = CBSendMail()
        sendmail.sendPaymentFailedMail(data)
    }
    
    func getDay(from date: String) -> String {
        guard let expiryDate = getDateFromJSON(date) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        let formattedDate = formatter.string(from: expiryDate)
        
        return formattedDate.isEmpty ? "" : formattedDate
    }
    
    func serviceResponse(_ arrResponse: [Any]) {
//        print(arrResponse.description)

        if webType == .getSubscriptionDetails {
            self.view.hideActivityIndicator()

            guard let firstResponse = arrResponse.first as? [String: Any] else { return }

            let flag = (firstResponse["IsAuthorized"] as? Bool) ?? false
            let type = firstResponse["Type"] as? String ?? ""

            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let app = appDelegate

            if type != "TemporaryAuthenticate" {
                app.ObjUserAccount?.isFree = (firstResponse["IsFree"] as? Bool) ?? false
                app.ObjUserAccount?.isMonthlySubscribed = (firstResponse["IsMonthlySubscribed"] as? Bool) ?? false
                app.ObjUserAccount?.isYearlySubscribed = (firstResponse["IsYearlySubscribed"] as? Bool) ?? false
                app.ObjUserAccount?.isCBYearlySubscribed = (firstResponse["IsCBYearlySubscribed"] as? Bool) ?? false
                app.ObjUserAccount?.isCBMonthlySubscribed = (firstResponse["IsCBMonthlySubscribed"] as? Bool) ?? false

                app.ObjUserAccount?.topSubscriptionLine = firstResponse["TopSubscriptionLine"] as? String ?? ""
                app.ObjUserAccount?.secondSubscriptionLine = firstResponse["SecondSubscriptionLine"] as? String ?? ""
                app.ObjUserAccount?.thirdSubscriptionLine = firstResponse["ThirdSubscriptionLine"] as? String ?? ""

                // 0 = SOAP, 1 = REST
                self.isRest = (firstResponse["isCBRestPaymentService"] as? Bool) ?? false
                UserDefaults.standard.set(self.isRest, forKey: kCBIsRest)

                // Push Messages Handling
                if let pushDetailsArray = firstResponse["PushMessages"] as? [[String: Any]] {
                    for pushDetail in pushDetailsArray {
                        let crewBidKey = pushDetail["CrewbidKey"] as? String ?? ""
                        let position = pushDetail["Position"] as? String ?? ""
                        let pushMessage = pushDetail["PushMessage"] as? String ?? ""
                        let isActive = pushDetail["IsActive"] as? NSNumber ?? 0
                        let date = pushDetail["PushDate"] as? String ?? ""

                        let dayString = self.getDay(from: date)
                        print(dayString)

                        if position == "FA" {
                            switch crewBidKey {
                            case "round1LinesPostedDay":
                                app.ObjUserAccount?.faRound1LinesPostedDay = dayString
                                app.ObjUserAccount?.faRound1LinesPostedDayActive = isActive as! Bool
                                app.ObjUserAccount?.faRound1LinesPostedDayMessage = pushMessage

                            case "round1LinesDueDay":
                                app.ObjUserAccount?.faRound1LinesDueDay = dayString
                                app.ObjUserAccount?.faRound1LinesDueDayActive = isActive as! Bool
                                app.ObjUserAccount?.faRound1LinesDueDayMessage = pushMessage

                            case "round2LinesPostedDay":
                                app.ObjUserAccount?.faRound2LinesPostedDay = dayString
                                app.ObjUserAccount?.faRound2LinesPostedDayActive = isActive as! Bool
                                app.ObjUserAccount?.faRound2LinesPostedDayMessage = pushMessage

                            case "round2LinesDueDay":
                                app.ObjUserAccount?.faRound2LinesDueDay = dayString
                                app.ObjUserAccount?.faRound2LinesDueDayActive = isActive as! Bool
                                app.ObjUserAccount?.faRound2LinesDueDayMessage = pushMessage

                            default: break
                            }
                        } else {
                            switch crewBidKey {
                            case "round1LinesPostedDay":
                                app.ObjUserAccount?.nonFaRound1LinesPostedDay = dayString
                                app.ObjUserAccount?.nonFaRound1LinesPostedDayActive = isActive as! Bool
                                app.ObjUserAccount?.nonFaRound1LinesPostedDayMessage = pushMessage

                            case "round1LinesDueDay":
                                app.ObjUserAccount?.nonFaRound1LinesDueDay = dayString
                                app.ObjUserAccount?.nonFaRound1LinesDueDayActive = isActive as! Bool
                                app.ObjUserAccount?.nonFaRound1LinesDueDayMessage = pushMessage

                            case "round2LinesPostedDay":
                                app.ObjUserAccount?.nonFaRound2LinesPostedDay = dayString
                                app.ObjUserAccount?.nonFaRound2LinesPostedDayActive = isActive as! Bool
                                app.ObjUserAccount?.nonFaRound2LinesPostedDayMessage = pushMessage

                            case "round2LinesDueDay":
                                app.ObjUserAccount?.nonFaRound2LinesDueDay = dayString
                                app.ObjUserAccount?.nonFaRound2LinesDueDayActive = isActive as! Bool
                                app.ObjUserAccount?.nonFaRound2LinesDueDayMessage = pushMessage

                            default: break
                            }
                        }
                    }
                }

                app.ObjUserAccount?.LoginuserId = app.ObjUserAccount?.employeeNumber ?? ""
                app.ObjUserAccount?.dicLoginAuthDetails = NSMutableDictionary(dictionary: firstResponse, copyItems: true)

                app.ObjUserAccount?.saveUserInfo()
                self.saveCBExpirationDate("\(firstResponse["CBExpirationDate"] ?? "")")
                self.saveWbidExpirationDate("\(firstResponse["WBExpirationDate"] ?? "")")
                if checkIsFreeAfterServiceCall() {
                    print("User is free or subscribed")
                } else {
                    print("User is not free")
                }

                DispatchQueue.main.async {
                    CBUtils.setPushNotifications()
                }
            }

            subscriptionInfoTextLbl.isHidden = false
            subscriptionInfoTextLbl.text = """
            \(firstResponse["TopSubscriptionLine"] ?? "")
            \(firstResponse["SecondSubscriptionLine"] ?? "")
            \(firstResponse["ThirdSubscriptionLine"] ?? "")
            """
            subscriptionInfoTextLbl.font = UIFont.boldSystemFont(ofSize: 17.0)
            subscriptionInfoTextLbl.textAlignment = .center
        }
        else if webType == .updateMaxSubscription{
            if let firstResponse = arrResponse.first as? [String: Any] {
                let status = (firstResponse["Status"] as? Bool) ?? false
                if status {
                    // Remove OfflinePayment.plist
                    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileURL = documentsDirectory.appendingPathComponent("OfflinePayment.plist")
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                    
                    dicOfflinePaymentData = [:]
                    
                    if let wbExpirationDate = firstResponse["WBExpirationDate"] {
                        let wbDateString = String(describing: wbExpirationDate)
                        app.ObjUserAccount?.dicLoginAuthDetails["WBExpirationDate"] = wbDateString
                        app.ObjUserAccount?.saveUserInfo()
                        saveWbidExpirationDate(wbDateString)
                    }
                    
                    // Success alert
                    let alert = UIAlertController(
                        title: "Payment Successful",
                        message: "Your Max subscription payment was successful. Now you can use the WBidMax vacation",
                        preferredStyle: .alert
                    )
                    let okAction = UIAlertAction(title: "Ok", style: .default)
                    alert.addAction(okAction)
                    present(alert, animated: true)
                    
                    checkAuthentication()
                    
                } else {
                    offlinePayment()
                    let alert = UIAlertController(
                        title: "Something went wrong",
                        message: "Your subscription details not updated remotely. Please contact us. We would love to help.",
                        preferredStyle: .alert
                    )
                    let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                        self.view.hideActivityIndicator()
                    }
                    alert.addAction(okAction)
                    present(alert, animated: true)
                    self.view.hideActivityIndicator()
                }
            }
        }
        else if webType == .updateSubscriptionDetails {
            if self.isRest{
                if let firstResponse = arrResponse.first as? [String: Any],
                   let flag = firstResponse["Status"] as? Bool,
                   flag {
                    
                    // Remove OfflinePayment.plist
                    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let path = documentsDirectory.appendingPathComponent("OfflinePayment.plist")
                        try? FileManager.default.removeItem(at: path)
                    }
                    
                    // Clear offline payment data
                    dicOfflinePaymentData = [:]
                    
                    // Update subscription info
                    let topLine = firstResponse["TopSubscriptionLine"] as? String ?? ""
                    let secondLine = firstResponse["SecondSubscriptionLine"] as? String ?? ""
                    let thirdLine = firstResponse["ThirdSubscriptionLine"] as? String ?? ""
                    app.ObjUserAccount?.topSubscriptionLine = topLine
                    app.ObjUserAccount?.secondSubscriptionLine = secondLine
                    app.ObjUserAccount?.thirdSubscriptionLine = thirdLine
                    app.ObjUserAccount?.LoginuserId = app.ObjUserAccount?.employeeNumber ?? ""
                    
                    // Update login auth details dictionary
                    app.ObjUserAccount?.dicLoginAuthDetails["TopSubscriptionLine"] = topLine
                    app.ObjUserAccount?.dicLoginAuthDetails["SecondSubscriptionLine"] = secondLine
                    app.ObjUserAccount?.dicLoginAuthDetails["ThirdSubscriptionLine"] = thirdLine
                    app.ObjUserAccount?.dicLoginAuthDetails["CBExpirationDate"] = firstResponse["CBExpirationDate"]
                    app.ObjUserAccount?.dicLoginAuthDetails["WBExpirationDate"] = firstResponse["WBExpirationDate"]
                    app.ObjUserAccount?.saveUserInfo()
                    // Save expiration dates
                    if let cbDate = firstResponse["CBExpirationDate"] as? String {
                        saveCBExpirationDate(cbDate)
                    }
                    if let wbDate = firstResponse["WBExpirationDate"] as? String {
                        saveWbidExpirationDate(wbDate)
                    }
                    
                    self.view.hideActivityIndicator()
                    
                    // Update subscription info text view
                    subscriptionInfoTextLbl.isHidden = false
                    subscriptionInfoTextLbl.text = "\(topLine)\n\(secondLine)\n\(thirdLine)"
                    subscriptionInfoTextLbl.font = UIFont.boldSystemFont(ofSize: 17.0)
                    subscriptionInfoTextLbl.textAlignment = .center
                    
                } else {
                    offlinePayment()
                    let alert = UIAlertController(
                        title: "Something went wrong",
                        message: "Your subscription details not updated remotely. Please contact us. We would love to help.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                        self.view.hideActivityIndicator()
                    }))
                    present(alert, animated: true)
                    self.view.hideActivityIndicator()
                }
            }else{
                let flag: Bool = {
                    guard
                        let firstResponse = arrResponse.first as? [String: Any],
                        let body = firstResponse["Body"] as? [String: Any],
                        let response = body["UpdateCrewBidPaidUntilDateSoapResponse"] as? [String: Any],
                        let result = response["UpdateCrewBidPaidUntilDateSoapResult"] as? [String: Any],
                        let status = result["Status"] as? Bool
                    else {
                        return false
                    }
                    return status
                }()
                
                if flag{
                    // Remove OfflinePayment.plist
                    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let path = documentsDirectory.appendingPathComponent("OfflinePayment.plist")
                        try? FileManager.default.removeItem(at: path)
                    }
                    dicOfflinePaymentData = [String: Any]()
                    guard
                        let firstResponse = arrResponse.first as? [String: Any],
                        let body = firstResponse["Body"] as? [String: Any],
                        let response = body["UpdateCrewBidPaidUntilDateSoapResponse"] as? [String: Any],
                        let dicData = response["UpdateCrewBidPaidUntilDateSoapResult"] as? [String: Any]
                    else { return }
                    if let topLine = dicData["TopSubscriptionLine"] as? String {
                        app.ObjUserAccount?.topSubscriptionLine = topLine
                        app.ObjUserAccount?.dicLoginAuthDetails["TopSubscriptionLine"] = topLine
                    }
                    if let secondLine = dicData["SecondSubscriptionLine"] as? String {
                        app.ObjUserAccount?.secondSubscriptionLine = secondLine
                        app.ObjUserAccount?.dicLoginAuthDetails["SecondSubscriptionLine"] = secondLine
                    }
                    if let thirdLine = dicData["ThirdSubscriptionLine"] as? String {
                        app.ObjUserAccount?.thirdSubscriptionLine = thirdLine
                        app.ObjUserAccount?.dicLoginAuthDetails["ThirdSubscriptionLine"] = thirdLine
                    }
                    app.ObjUserAccount?.LoginuserId = app.ObjUserAccount?.employeeNumber ?? ""
                    var expiryDateCB: Date?
                    if let cbExpiration = dicData["CBExpirationDate"] as? String {
                        expiryDateCB = formatedSoapDate(cbExpiration)
                        if let date = expiryDateCB {
                            let formatted = "\(date)"
                            app.ObjUserAccount?.dicLoginAuthDetails["CBExpirationDate"] = formatted
                            saveSoapCBExpirationDate(cbExpiration)
                        }
                    }
                    var expiryDateWB: Date?
                    if let wbExpiration = dicData["WBExpirationDate"] as? String {
                        expiryDateWB = formatedSoapDate(wbExpiration)
                        if let date = expiryDateWB {
                            let formatted = "\(date)"
                            app.ObjUserAccount?.dicLoginAuthDetails["WBExpirationDate"] = formatted
                            saveSoapWbidExpirationDate(wbExpiration)
                        }
                    }
                    app.ObjUserAccount?.saveUserInfo()
                    // Store back in /Date(...) format
                    if let wbDate = expiryDateWB {
                        let startDate = wbDate.timeIntervalSince1970 * 1000
                        let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)
                        app.ObjUserAccount?.dicLoginAuthDetails["WBExpirationDate"] = dateStarted
                    }
                    if let cbDate = expiryDateCB {
                        let startDate1 = cbDate.timeIntervalSince1970 * 1000
                        let dateStarted1 = String(format: "/Date(%.0f+0800)/", startDate1)
                        app.ObjUserAccount?.dicLoginAuthDetails["CBExpirationDate"] = dateStarted1
                    }
                    app.ObjUserAccount?.saveUserInfo()
                    self.view.hideActivityIndicator()
                    subscriptionInfoTextLbl.isHidden = false
                    var stringInfo = ""
                    if let topLine = dicData["TopSubscriptionLine"] as? String {
                        stringInfo += "\(topLine)\n"
                    }
                    if let secondLine = dicData["SecondSubscriptionLine"] as? String {
                        stringInfo += "\(secondLine)\n"
                    }
                    if let thirdLine = dicData["ThirdSubscriptionLine"] as? String {
                        stringInfo += "\(thirdLine)\n"
                    }
                    subscriptionInfoTextLbl.text = stringInfo
                    subscriptionInfoTextLbl.font = .boldSystemFont(ofSize: 17)
                    subscriptionInfoTextLbl.textAlignment = .center
                }else{
                    guard
                        let firstResponse = arrResponse.first as? [String: Any],
                        let body = firstResponse["Body"] as? [String: Any],
                        let response = body["TempUpdatePaidDateResponse"] as? [String: Any],
                        let dicData = response["TempUpdatePaidDateResult"] as? [String: Any]
                    else { return }
                    let flagForPending = (dicData["Status"] as? Bool) ?? false
                    if flagForPending {
                        dicOfflinePaymentData = [String: Any]()
                        if let topLine = dicData["TopSubscriptionLine"] as? String {
                            app.ObjUserAccount?.topSubscriptionLine = topLine
                            app.ObjUserAccount?.dicLoginAuthDetails["TopSubscriptionLine"] = topLine
                        }
                        if let secondLine = dicData["SecondSubscriptionLine"] as? String {
                            app.ObjUserAccount?.secondSubscriptionLine = secondLine
                            app.ObjUserAccount?.dicLoginAuthDetails["SecondSubscriptionLine"] = secondLine
                        }
                        if let thirdLine = dicData["ThirdSubscriptionLine"] as? String {
                            app.ObjUserAccount?.thirdSubscriptionLine = thirdLine
                            app.ObjUserAccount?.dicLoginAuthDetails["ThirdSubscriptionLine"] = thirdLine
                        }
                        app.ObjUserAccount?.LoginuserId = app.ObjUserAccount?.employeeNumber ?? ""
                        var expiryDateCB: Date?
                        if let cbExpiration = dicData["CBExpirationDate"] as? String {
                            expiryDateCB = formatedSoapDate(cbExpiration)
                            if let date = expiryDateCB {
                                let formatted = "\(date)"
                                app.ObjUserAccount?.dicLoginAuthDetails["CBExpirationDate"] = formatted
                                saveSoapCBExpirationDate(cbExpiration)
                            }
                        }
                        var expiryDateWB: Date?
                        if let wbExpiration = dicData["WBExpirationDate"] as? String {
                            expiryDateWB = formatedSoapDate(wbExpiration)
                            if let date = expiryDateWB {
                                let formatted = "\(date)"
                                app.ObjUserAccount?.dicLoginAuthDetails["WBExpirationDate"] = formatted
                                saveSoapWbidExpirationDate(wbExpiration)
                            }
                        }
                        app.ObjUserAccount?.saveUserInfo()
                        // Store back in /Date(...) format
                        if let wbDate = expiryDateWB {
                            let startDate = wbDate.timeIntervalSince1970 * 1000
                            let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)
                            app.ObjUserAccount?.dicLoginAuthDetails["WBExpirationDate"] = dateStarted
                        }
                        if let cbDate = expiryDateCB {
                            let startDate1 = cbDate.timeIntervalSince1970 * 1000
                            let dateStarted1 = String(format: "/Date(%.0f+0800)/", startDate1)
                            app.ObjUserAccount?.dicLoginAuthDetails["CBExpirationDate"] = dateStarted1
                        }
                        app.ObjUserAccount?.saveUserInfo()
                        self.view.hideActivityIndicator()
                        subscriptionInfoTextLbl.isHidden = false
                        var stringInfo = ""
                        if let topLine = dicData["TopSubscriptionLine"] as? String {
                            stringInfo += "\(topLine)\n"
                        }
                        if let secondLine = dicData["SecondSubscriptionLine"] as? String {
                            stringInfo += "\(secondLine)\n"
                        }
                        if let thirdLine = dicData["ThirdSubscriptionLine"] as? String {
                            stringInfo += "\(thirdLine)\n"
                        }
                        subscriptionInfoTextLbl.text = stringInfo
                        subscriptionInfoTextLbl.font = .boldSystemFont(ofSize: 17)
                        subscriptionInfoTextLbl.textAlignment = .center
                    } else {
                        offlinePayment()
                        let alert = UIAlertController(
                            title: "Something went wrong",
                            message: "Your subscription details not updated remotely. Please contact us. We would love to help.",
                            preferredStyle: .alert
                        )
                        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                            self.view.hideActivityIndicator()
                        }
                        alert.addAction(okAction)
                        present(alert, animated: true)
                        self.view.hideActivityIndicator()
                    }
                }
            }
        }
    }
    
    func saveSoapWbidExpirationDate(_ date: String) {
        guard let expiryDate = formatedSoapDate(date) else {
            return
        }
        
        let maxWBDate = CBIAPHelper.shared.bestDate(from: expiryDate, date2: CBIAPHelper.shared.getBestAvailableWbidExpirationDate())
        
        CBIAPHelper.shared.setICloudEncryptedWbidExpirationDate(maxWBDate)
        CBIAPHelper.shared.setLocalEncryptedWbidExpirationDate(maxWBDate)
    }
    
    func saveSoapCBExpirationDate(_ date: String) {
        guard let expiryDate = formatedSoapDate(date) else { return }
        let formattedDate = "\(expiryDate)"
        if formattedDate.isEmpty { return }

        let maxCBDate = CBIAPHelper.shared.bestDate(from: expiryDate, date2: CBIAPHelper.shared.getBestAvailableExpirationDate())
        CBIAPHelper.shared.setICloudEncryptedExpirationDate(maxCBDate)
        CBIAPHelper.shared.setLocalEncryptedExpirationDate(maxCBDate)
    }
    
    func formatedSoapDate(_ date: String) -> Date? {
        let dateFormatter = DateFormatter()
        
        // Apply timezone fix if needed
        let formattedDateString = applyTimezoneFix(for: date)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = Locale.current
        
        if let expiryDate = dateFormatter.date(from: formattedDateString) {
            return expiryDate
        } else {
            // Fallback format
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            return fallbackFormatter.date(from: date)
        }
    }
    
    func applyTimezoneFix(for date: String) -> String {
        if let colonRange = date.range(of: ":", options: .backwards) {
            var fixedDate = date
            fixedDate.replaceSubrange(colonRange, with: "")
            return fixedDate
        }
        return date
    }
    
    func saveWbidExpirationDate(_ date: String) {
        guard let expiryDate = getDateFromJSON(date) else {
            return
        }
        
        let formattedDate = "\(expiryDate)"
        guard !formattedDate.isEmpty else {
            return
        }
        
        let maxWBDate = CBIAPHelper.shared.bestDate(
            from: expiryDate,
            date2: CBIAPHelper.shared.getBestAvailableWbidExpirationDate()
        )
        
        CBIAPHelper.shared.setICloudEncryptedWbidExpirationDate(maxWBDate)
        CBIAPHelper.shared.setLocalEncryptedWbidExpirationDate(maxWBDate)
        
        // Old Vofox code (commented in Obj-C)
        // CBIAPHelper.shared.setParseEncryptedWbidExpirationDate(maxWBDate, withProductID: "")
    }
    
    func saveCBExpirationDate(_ date: String) {
        guard let expiryDate = getDateFromJSON(date) else {
            return
        }
        
        let formattedDate = "\(expiryDate)"
        guard !formattedDate.isEmpty else {
            return
        }
        
        let maxCBDate = CBIAPHelper.shared.bestDate(from: expiryDate,
                                                              date2: CBIAPHelper.shared.getBestAvailableExpirationDate())
        
        CBIAPHelper.shared.setICloudEncryptedExpirationDate(maxCBDate)
        CBIAPHelper.shared.setLocalEncryptedExpirationDate(maxCBDate)

    }
    
    func getDateFromJSON(_ string: String) -> Date? {
        // Static regex (compiled once)
        struct RegexHolder {
            static let dateRegEx: NSRegularExpression = {
                let pattern = #"^\/date\((-?\d+)(?:([+-])(\d{2})(\d{2}))?\)\/$"#
                return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            }()
        }
        
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let match = RegexHolder.dateRegEx.firstMatch(in: string, options: [], range: range) else {
            return nil
        }
        
        // Milliseconds → seconds
        let millisecondsRange = Range(match.range(at: 1), in: string)!
        var seconds = (Double(String(string[millisecondsRange])) ?? 0.0) / 1000.0
        
        // Timezone offset
        if match.range(at: 2).location != NSNotFound {
            let signRange = Range(match.range(at: 2), in: string)!
            let sign = String(string[signRange])
            
            let hoursRange = Range(match.range(at: 3), in: string)!
            let minutesRange = Range(match.range(at: 4), in: string)!
            
            let hours = Double("\(sign)\(string[hoursRange])") ?? 0.0
            let minutes = Double("\(sign)\(string[minutesRange])") ?? 0.0
            
            seconds += hours * 3600.0
            seconds += minutes * 60.0
        }
        
        return Date(timeIntervalSince1970: seconds)
    }
    
    func checkIsFreeAfterServiceCall() -> Bool {
        var isFree = false
        collectionView.isHidden = false
        
        if app.ObjUserAccount!.isFree ||
            app.ObjUserAccount!.isMonthlySubscribed ||
            app.ObjUserAccount!.isYearlySubscribed ||
            app.ObjUserAccount!.isCBMonthlySubscribed ||
            app.ObjUserAccount!.isCBYearlySubscribed {
            
            isFree = true
            let daysLeft = CBIAPHelper.shared.daysRemainingOnSubscription()
            
            if daysLeft > 0 {
                collectionView.isHidden = true
            }
        } else {
            if !isFetching {
                loadCollectionViewAfterServiceCall()
            }
        }
        
        return isFree
    }
    
    
    func loadCollectionViewAfterServiceCall() {
        var newUrl = "\(UserDefaults.standard.value(forKey: "receiptValidationUrl") ?? "")"
        let currentURL = UserDefaults.standard.string(forKey: kCBReceiptValidationURLKey) ?? ""
        
        if !(newUrl.count > 0) {
            newUrl = currentURL
        }
        
        // Change the current URL if it is different
        if !currentURL.isEmpty && currentURL != newUrl {
            UserDefaults.standard.set(newUrl, forKey: kCBReceiptValidationURLKey)
        }
        
        if products?.count != 2 {
            DispatchQueue.main.async {
                CBIAPHelper.shared.requestProducts { success, products in
                    DispatchQueue.main.async {
                        if success, let products = products, products.count > 0 {
                            self.products = []
                            
                            var tempNumbers: [Int] = []
                            var tempInt = 1
                            
                            for tempProduct in products {
                                // changed by basith on 23-aug-2023 to fix issue where all products were visible if currency differed
                                if tempProduct.productIdentifier == kCBMonthlyMaxSubscriptionIdentifier {
                                    tempNumbers.append(tempInt)
                                    self.products?.append(tempProduct)
                                    tempInt += 1
                                }
                            }
                            
                            // Only show $5.99
                            self.cellItems = tempNumbers
                            self.collectionView.reloadData()
                            
                        } else {
                            self.view.hideActivityIndicator()
                            let alert = UIAlertController(
                                title: "iTunes Error",
                                message: """
                                iTunes failed to return a product list. Make sure you are connected to the internet or wait a few seconds and try again.

                                If the issue persists, first try logging in and out of iTunes in your iPad Settings. If that doesn't work, then try a hard reset by holding down the iPad's Home button and side button on the top right.
                                """,
                                preferredStyle: .alert
                            )
                            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.view.hideActivityIndicator()
            }
        }
    }
    
    func responseStatus(_ responseStatus: Int) {
        
    }
    
    func connectionFailed() {
        self.networkFailureMessage()
    }
    
    func requestFailed() {
        self.networkFailureMessage()
    }
    
    func connectionDataReceived(_ progress: Float) {
        
    }
    
    

    @IBOutlet weak var subscriptionInfoTextLbl: UILabel!
    @IBOutlet weak var internetWarningLbl: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    
    private var products:[SKProduct]?
    private var priceFormatter = NumberFormatter()
    private var observing: Bool = false
    private var objDataBuilder = ODataBuilder()
    private var dicOfflinePaymentData: [String: Any] = [:]
    private var isFetching: Bool = false
    private var purchaseType: String?
    var cellItems: [Int] = []
    
    var isRest: Bool = false
    var webType: Webservice = .getSubscriptionDetails
    
    let ITMS_PROD_VERIFY_RECEIPT_URL = "https://buy.itunes.apple.com/verifyReceipt"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        self.offlinePaymentDetails()
        app.simplePingStarter()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("UpdateSubscription"), object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateData),
                                               name: NSNotification.Name("UpdateSubscription"),
                                               object: nil)
        
        self.collectionView.isHidden = false
        UserDefaults.standard.set(ITMS_PROD_VERIFY_RECEIPT_URL, forKey: kCBReceiptValidationURLKey)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("InAppPurchaseUpdate"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("TempInAppPurchaseUpdate"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("InAppPurchaseUpdateAfterPending"), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateInAppPurchaseData(_:)),
                                               name: NSNotification.Name("InAppPurchaseUpdate"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(tempUpdatePendingPurchaseData(_:)),
                                               name: NSNotification.Name("TempInAppPurchaseUpdate"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateAfterPendingPurchaseData(_:)),
                                               name: NSNotification.Name("InAppPurchaseUpdateAfterPending"),
                                               object: nil)
        
        if app.objNetworkType == .free || !app.connectedToInternet(){
            subscriptionInfoTextLbl.isHidden = false
            subscriptionInfoTextLbl.text = String(format: "%@\n%@\n%@", app.ObjUserAccount!.topSubscriptionLine, app.ObjUserAccount!.secondSubscriptionLine, app.ObjUserAccount!.thirdSubscriptionLine)
            subscriptionInfoTextLbl.font = UIFont.systemFont(ofSize: 17)
            subscriptionInfoTextLbl.textAlignment = .center
        }else{
            subscriptionInfoTextLbl.isHidden = true
            let isFree = checkIsFree()
                loadCollectionView()

                if isFree {
                    loadDaysLeft()
                    NotificationCenter.default.addObserver(
                        self,
                        selector: #selector(loadDaysLeft),
                        name: NSNotification.Name(kCBNewSubscriptionPurchasedNotification),
                        object: nil
                    )
                    return
                }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(inAppPurchaseUpdated),
            name: NSNotification.Name("InAppPurchaseUpdated"),
            object: nil
        )
    }
    
    @objc func inAppPurchaseUpdated() {
        DispatchQueue.main.async { [weak self] in
            self?.view.hideActivityIndicator()
            self?.viewDidLoad()
        }
    }
    
    func loadCollectionView() {
        isFetching = true
        
        // First get the receipt validation URL
        var newUrl = UserDefaults.standard.string(forKey: "receiptValidationUrl") ?? ""
        let currentURL = UserDefaults.standard.string(forKey: kCBReceiptValidationURLKey) ?? ""
        
        if newUrl.isEmpty {
            newUrl = currentURL
        }
        
        // Change the current URL if it is different
        if !currentURL.isEmpty && currentURL != newUrl {
            UserDefaults.standard.set(newUrl, forKey: kCBReceiptValidationURLKey)
        }
        
        if products?.count != 2 {
            CBIAPHelper.shared.requestProducts { success, products  in
            }
            DispatchQueue.main.async {
                CBIAPHelper.shared.requestProducts { success, products in
                    DispatchQueue.main.async {
                        if success, products!.count > 0 {
                            self.products = []
                            var tempNumbers: [Int] = []
                            var tempInt = 1
                            
                            for tempProduct in products! {
                                if tempProduct.productIdentifier == kCBMonthlyMaxSubscriptionIdentifier {
                                    tempNumbers.append(tempInt)
                                    self.products?.append(tempProduct)
                                    tempInt += 1
                                }
                            }
                            
                            self.cellItems = tempNumbers
                            self.collectionView.reloadData()
                            
                        } else {
                            self.view.hideActivityIndicator()
                            DispatchQueue.main.async {
                                let alert = UIAlertController(
                                    title: "iTunes Error",
                                    message: """
                                    iTunes failed to return a product list. Make sure you are connected to the internet or wait a few seconds and try again.

                                    If the issue persists, first try logging in and out of iTunes in your iPad Settings. If that doesn't work, then try a hard reset by holding down the iPad's Home button and side button on the top right.
                                    """,
                                    preferredStyle: .alert
                                )
                                let okAction = UIAlertAction(title: "Ok", style: .default)
                                alert.addAction(okAction)
                                self.present(alert, animated: true)
                            }
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.view.hideActivityIndicator()
            }
        }
        
        loadDaysLeft()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadDaysLeft),
            name: NSNotification.Name(kCBNewSubscriptionPurchasedNotification),
            object: nil
        )
    }
    
    @objc func loadDaysLeft() {
        guard let userInfo = CBUserInfo.bestAvailableUserInfoDictionary() else { return }
        let productIDs = userInfo[kCBUserInfoPurchaseTypesKey] as? [String] ?? []

        if productIDs.isEmpty {
//            lastPurchaseTextView.isHidden = true
        }

        if app.objNetworkType == .free {
            collectionView.isHidden = true
//            imgMaxSubscriptionView.isHidden = true

            let daysOnFreeTrial = CBIAPHelper.shared.daysRemainingOnFreeTrial()
            let daysLeft = CBIAPHelper.shared.daysRemainingOnSubscription()

            if daysOnFreeTrial != 0 && daysOnFreeTrial >= daysLeft {
                // Still in free trial
                subscriptionInfoTextLbl.text = CBIAPHelper.shared.getFreeTrialExpirationDateString()
                subscriptionInfoTextLbl.font = UIFont.boldSystemFont(ofSize: 20.0)
                subscriptionInfoTextLbl.textAlignment = .center

                if daysOnFreeTrial > 0 {
                    subscriptionInfoTextLbl.textColor = CBColor.green
//                    lastPurchaseTextView.textColor = CBColor.green
                } else {
                    subscriptionInfoTextLbl.textColor = .red
//                    lastPurchaseTextView.textColor = .red
                }
            } else {
                // Might still be in free trial, but the user has purchased a subscription
                subscriptionInfoTextLbl.text = CBIAPHelper.shared.getExpirationDateString()
                subscriptionInfoTextLbl.font = UIFont.boldSystemFont(ofSize: 20.0)
                subscriptionInfoTextLbl.textAlignment = .center

                if daysLeft > 0 {
                    subscriptionInfoTextLbl.textColor = CBColor.green
//                    lastPurchaseTextView.textColor = CBColor.green
                } else {
                    subscriptionInfoTextLbl.textColor = .red
//                    lastPurchaseTextView.textColor = .red
                }
            }

            subscriptionInfoTextLbl.isHidden = false
        } else {
            updateSubscriptionDetails()
        }

        CBUserInfo.setUserInfoDictionary(userInfo)
    }
    
    
    func updateSubscriptionDetails() {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        if app.connectedToInternet() {
            self.view.showActivityIndicator()
            checkAuthentication()
            
        } else {
            let alert = UIAlertController(title: "Network not available!!",
                                          message: "Please check your internet connection",
                                          preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                self.view.hideActivityIndicator()
            }
            alert.addAction(okAction)
            present(alert, animated: true)
        }
    }
    
    func checkAuthentication() {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        var dicAuthenticationInfo: [String: Any] = [:]
        dicAuthenticationInfo["Platform"] = "iPad"
        dicAuthenticationInfo["OperatingSystem"] = "iPad OS"
        
        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            dicAuthenticationInfo["Version"] = appVersion
        }
        
        dicAuthenticationInfo["Base"] = ""
        dicAuthenticationInfo["BidRound"] = 0
        dicAuthenticationInfo["Postion"] = ""
        dicAuthenticationInfo["Month"] = "0"
        
        if let empNumber = Int(app.ObjUserAccount!.employeeNumber) {
            dicAuthenticationInfo["EmployeeNumber"] = empNumber
        } else {
            dicAuthenticationInfo["EmployeeNumber"] = 0
        }
        
        // Blocking setup of Bid data download from the server
        dicAuthenticationInfo["RequestType"] = 6
        
        // Optional: generate a GUID token if needed
        // dicAuthenticationInfo["GuidToken"] = CBUtils.generateUniqueIdentifier()
        
        app.sc?.delegate = self
        webType = .getSubscriptionDetails
        objDataBuilder.checkAuthentication(&dicAuthenticationInfo)
    }
    
    func checkIsFree() -> Bool {
        var isFree = false
        collectionView.isHidden = false

        if app.ObjUserAccount?.isFree == true ||
            app.ObjUserAccount?.isMonthlySubscribed == true ||
            app.ObjUserAccount?.isYearlySubscribed == true ||
            app.ObjUserAccount?.isCBMonthlySubscribed == true ||
            app.ObjUserAccount?.isCBYearlySubscribed == true {

            isFree = true
            let daysLeft = CBIAPHelper.shared.daysRemainingOnSubscription()

            if daysLeft > 0 {
                collectionView.isHidden = true
            }
        }

        return isFree
    }
    
    
    @objc func updateInAppPurchaseData(_ notification: Notification){
        self.view.showActivityIndicator(message: "Updating Purchase Details")
        guard let userInfo = notification.userInfo else { return }
        dicOfflinePaymentData = userInfo as? [String: Any] ?? [:]
        let months = (userInfo["Month"] as? NSNumber)?.intValue ?? 0
        objDataBuilder = ODataBuilder()
        var dicData: [String: Any] = [:]
            
            purchaseType = userInfo["Type"] as? String
            
            if purchaseType == "WBid" {
                guard let empNumber = app.ObjUserAccount?.employeeNumber, !empNumber.isEmpty else {
                    return
                }
                
                dicData["EmpNum"] = empNumber
                dicData["Month"] = months
                dicData["Message"] = "PaymentReceived for Onetime Monthly"
                dicData["TransactionNumber"] = dicOfflinePaymentData["TransactionID"]
                dicData["AppNum"] = 5
                
                app.sc?.delegate = self
                webType = .updateMaxSubscription
                
                objDataBuilder.updateMaxInAppPurchaseDetails(dicData)
            }else if purchaseType == "CrewBid" {
                guard let empNumber = app.ObjUserAccount?.employeeNumber, !empNumber.isEmpty else {
                    return
                }
                
                dicData["EmpNum"] = empNumber
                dicData["Month"] = months
                
                if months == 1 {
                    dicData["Message"] = "PaymentReceived for Onetime Monthly"
                } else if months == 6 {
                    dicData["Message"] = "PaymentReceived for 6 months"
                }
                
                dicData["IpAddress"] = app.IPAddress
                dicData["TransactionNumber"] = dicOfflinePaymentData["TransactionID"]
                dicData["AppNum"] = 5
                
                if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                    dicData["Version"] = appVersion
                }
                
                app.sc?.delegate = self
                webType = .updateSubscriptionDetails
                
                if isRest {
                    objDataBuilder.updateInAppPurchaseDetails(dicData)
                } else {
                    objDataBuilder.soapUpdateInAppPurchaseDetails(dicData)
                }
            }
    }
    
    @objc func tempUpdatePendingPurchaseData(_ notification: Notification) {
        self.view.showActivityIndicator(message: "Updating Purchase Details")

        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        dicOfflinePaymentData = userInfo

        let months = (userInfo["Month"] as? NSNumber)?.intValue ?? 0
        objDataBuilder = ODataBuilder()
        var dicData: [String: Any] = [:]

        purchaseType = userInfo["Type"] as? String

        if purchaseType == "WBid" {
            let userDefaultsEmployeeNumber = app.ObjUserAccount?.employeeNumber ?? ""
            if userDefaultsEmployeeNumber.isEmpty {
                return
            }

            dicData["EmpNum"] = userDefaultsEmployeeNumber
            dicData["Month"] = months
            dicData["Message"] = "Payment Pending"
            dicData["TransactionNumber"] = dicOfflinePaymentData["TransactionID"]
            dicData["AppNum"] = 5
            dicData["IpAddress"] = dicOfflinePaymentData["IpAddress"]
            dicData["IsWbid"] = true

            app.sc?.delegate = self
            webType = .updateMaxSubscription
            objDataBuilder.updateMaxInAppPurchaseDetails(dicData)
        }
    }
    
    @objc func updateAfterPendingPurchaseData(_ notification: Notification) {
        self.view.showActivityIndicator(message: "Updating Purchase Details")

        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        dicOfflinePaymentData = userInfo
        let months = (userInfo["Month"] as? NSNumber)?.intValue ?? 0

        objDataBuilder = ODataBuilder()
        var dicData: [String: Any] = [:]

        purchaseType = userInfo["Type"] as? String

        if purchaseType == "WBid" {
            let userDefaultsEmployeeNumber = app.ObjUserAccount?.employeeNumber ?? ""
            if userDefaultsEmployeeNumber.isEmpty {
                return
            }

            dicData["IpAddress"] = app.IPAddress
            dicData["TransactionNumber"] = dicOfflinePaymentData["TransactionID"]
            dicData["AppNum"] = 5
            dicData["OriginalTransactionDate"] = userInfo["original_purchase_date"]
            dicData["IsWbid"] = true

            app.sc?.delegate = self
            webType = .updateMaxSubscription   // assuming you mapped enum in Swift
            objDataBuilder.updateMaxInAppPurchaseDetailsAfterPending(dicData)
        }
    }
    
    
    func setupUI() {
        btnBack.setTitle("", for: .normal)
        btnDone.setTitle("", for: .normal)
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        
        let itemWidth: CGFloat = 184
//        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        let collectionViewWidth = collectionView.frame.width
        let horizontalInset = (collectionViewWidth - itemWidth) / 2
        
        layout.sectionInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
        collectionView.setCollectionViewLayout(layout, animated: true)
    }
    
    func offlinePaymentDetails() {
        // Get documents directory
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else { return }
        
        // File path for plist
        let path = (documentsDirectory as NSString).appendingPathComponent("OfflinePayment.plist")
        
        // Try to read dictionary from file
        if let dicOffline = NSMutableDictionary(contentsOfFile: path) {
            dicOfflinePaymentData = dicOffline.copy() as? [String: Any] ?? [:]
        } else {
            dicOfflinePaymentData = [:]
        }
    }
    
    @objc func updateData() {
        DispatchQueue.main.async {
            self.viewDidLoad()
        }
    }
    
    
    
    
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    func purchaseSubscription(with product: SKProduct) {
        if isEligibleForPurchase() {
            // Show activity indicator
            self.view.showActivityIndicator(message: "Processing purchase...")
            CBIAPHelper.shared.buyProduct(product)
        } else {
            let alert = UIAlertController(title: "Unable to purchase",
                                          message: "It seems that you have already tried an attempt, and now it is in pending status due to some technical issues.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func isEligibleForPurchase() -> Bool {
        let transactions = getTransactions()
        
        guard let lastTransaction = transactions.last,
              let dateFromIcloud = lastTransaction["transactionDate"] as? Date else {
            return true
        }
        
        let currentDate = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day], from: dateFromIcloud, to: currentDate)
        
        if let days = components.day, days < 10 {
            return false
        }
        
        return true
    }
    
    func getTransactions() -> [[String: Any]] {
        let store = NSUbiquitousKeyValueStore.default
        if let transactions = store.array(forKey: "transaction") as? [[String: Any]] {
            return transactions
        } else {
            return []
        }
    }
}

extension CBSubscriptionInfoController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SubscriptionCollectionViewCell
//        cell.label.text = "Subscribe for \n₹699.00"
//        cell.imageView.image = UIImage(named: "oneMonth")
        configureCell(cell, at: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UICollectionViewCell, at indexPath: IndexPath) {
        // Corner radius and border
        cell.layer.cornerRadius = 6.0
        cell.layer.borderWidth = 3.0
        cell.layer.borderColor = CBColor.cbPurpleColor?.cgColor
        
        // Get product
        let product = products?[indexPath.row]
        
        // Format price
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product?.priceLocale
        let formattedPrice = numberFormatter.string(from: product?.price ?? 0)
        
        // Set label
        if let label = labelForCell(cell) {
            label.text = formattedPrice
        }
    }
    
    func labelForCell(_ cell: UICollectionViewCell) -> UILabel? {
        return cell.viewWithTag(kLabelTag) as? UILabel
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 184, height: 168)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var daysLeft: Int = 0
        
        switch indexPath.row {
        case 0, 2:
            daysLeft = CBIAPHelper.shared.daysRemainingOnSubscription()
        case 1:
            daysLeft = CBIAPHelper.shared.daysRemainingOnWBidSubscription()
        default:
            break
        }
        
        // Check for pending offline payment
        offlinePaymentDetails()
        if !dicOfflinePaymentData.isEmpty {
            let alert = UIAlertController(title: "Unable to purchase",
                                          message: "It seems that you already purchased the subscription, but it is not updated to database.\nIf you have any question with the subscription then please contact Admin.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Check if daysLeft > 30
        if daysLeft > 30 {
            let alert = UIAlertController(title: "Unable to purchase",
                                          message: "There must be 30 or fewer days remaining on your subscription before renewals can be processed.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alert, animated: true)
        } else {
            // Purchase the product
            self.view.showActivityIndicator(message: "Processing purchase...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                let product = self.products?[indexPath.row]
                self.purchaseSubscription(with: product!)
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let totalCellWidth = 150 * CGFloat(products?.count ?? 0)
        let totalSpacingWidth = 10 * CGFloat(max((products?.count ?? 0) - 1, 0))
        let leftInset = (self.collectionView.bounds.width - (totalCellWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset
        
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
    }
    
}
