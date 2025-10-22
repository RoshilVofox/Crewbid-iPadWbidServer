//
//  CBSendMail.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 01/09/25.
//

import Foundation

class CBSendMail{
    func sendCrashMail(_ bidData: String) {
        var dicMailInfo: [String: Any] = [:]
        
        let userDefaultsEmployeeNumber = UserDefaults.standard.string(forKey: kCBEmployeeNumberDefaultKey)
        
        dicMailInfo["ToAddress"] = "crash@crewbidmax.com"
        dicMailInfo["FromAddress"] = "admin@wbidmax.com"
        dicMailInfo["MessageBody"] = bidData.replacingOccurrences(of: "\r\n", with: "<br/>")
        
        // Employee number
        let empNo: String
        if let empNum = userDefaultsEmployeeNumber, !empNum.isEmpty {
            empNo = empNum
        } else {
            empNo = ""
        }
        
        dicMailInfo["Alias"] = "\(empNo) CrewBid-iPad"
        dicMailInfo["EmployeeNumber"] = userDefaultsEmployeeNumber ?? ""
        
        // Application Version
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        dicMailInfo["Subject"] = "CrewBid Error Log ( \(version) )"
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            dicMailInfo["UserAppEmail"] = appDelegate.ObjUserAccount?.email ?? ""
        }
        // Call the mail sending function
        sendMail(dicMailInfo)
    }

    func sendBidPackageErrorMail(_ bidData: String) {
        var dicMailInfo: [String: Any] = [:]
        
        let userDefaultsEmployeeNumber = UserDefaults.standard.string(forKey: kCBEmployeeNumberDefaultKey) ?? ""
        let empNo = userDefaultsEmployeeNumber.isEmpty ? "" : userDefaultsEmployeeNumber
        
        dicMailInfo["ToAddress"] = "admin@crewbidmax.com"
        dicMailInfo["FromAddress"] = "admin@wbidmax.com"
        dicMailInfo["MessageBody"] = bidData.replacingOccurrences(of: "\r\n", with: "<br/>")
        dicMailInfo["Alias"] = "\(empNo) Bid Package Error"
        dicMailInfo["EmployeeNumber"] = userDefaultsEmployeeNumber
        dicMailInfo["Subject"] = "Bid Package Error - CrewBid iPad"
        
        if let app = UIApplication.shared.delegate as? AppDelegate {
            dicMailInfo["UserAppEmail"] = app.ObjUserAccount?.email ?? ""
        }
        
        sendMail(dicMailInfo)
    }

    func sendIOS16PresetConversionEmail(_ bidData: String) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        var dicMailInfo: [String: Any] = [:]
        let userDefaultsEmployeeNumber = UserDefaults.standard.string(forKey: kCBEmployeeNumberDefaultKey) ?? ""
        let empNo = userDefaultsEmployeeNumber.isEmpty ? "" : userDefaultsEmployeeNumber
        
        let mailBody = "This user has an un-converted iOS16 preset file. User - \(empNo)"
        
        dicMailInfo["ToAddress"] = "crash@crewbidmax.com"
        dicMailInfo["FromAddress"] = "admin@wbidmax.com"
        dicMailInfo["MessageBody"] = mailBody.replacingOccurrences(of: "\r\n", with: "<br/>")
        dicMailInfo["Alias"] = "\(empNo) iOS16 Preset Conversion"
        dicMailInfo["EmployeeNumber"] = userDefaultsEmployeeNumber
        dicMailInfo["Subject"] = "\(empNo) iOS16 Preset Conversion"
        dicMailInfo["UserAppEmail"] = app.ObjUserAccount?.email ?? ""
        
        sendMail(dicMailInfo)
    }

    func sendBidReceiptErrorMail(_ bidData: String) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        var dicMailInfo: [String: Any] = [:]
        let userDefaultsEmployeeNumber = UserDefaults.standard.string(forKey: kCBEmployeeNumberDefaultKey) ?? ""
        let empNo = userDefaultsEmployeeNumber.isEmpty ? "" : userDefaultsEmployeeNumber
        
        let messageBody = "The bid receipt of the employee \(empNo) \r\n \(bidData)"
            .replacingOccurrences(of: "\r\n", with: "<br/>")
        
        dicMailInfo["ToAddress"] = "admin@crewbidmax.com"
        dicMailInfo["FromAddress"] = "admin@wbidmax.com"
        dicMailInfo["MessageBody"] = messageBody
        dicMailInfo["Alias"] = "\(empNo) CrewBid-iPad Bid receipt error"
        dicMailInfo["EmployeeNumber"] = userDefaultsEmployeeNumber
        dicMailInfo["Subject"] = "Bid receipt with incomplete data"
        dicMailInfo["UserAppEmail"] = app.ObjUserAccount?.email ?? ""
        
        sendMail(dicMailInfo)
    }

    func userAccountCreationFailedMail(_ mailId: String) {
        var dicMailInfo: [String: Any] = [:]
        
        dicMailInfo["ToAddress"] = mailId
        dicMailInfo["FromAddress"] = "admin@wbidmax.com"
        dicMailInfo["MessageBody"] = "Please click on the link to create the user account in CrewBid - https://www.crewbidmax.com/Home/LoginCWA"
        dicMailInfo["Subject"] = "Crewbid User Account creation"
        
        sendMail(dicMailInfo)
    }

    func userAccountCreationFailedMailToAdmin(_ userInfo: [String: Any]) {
        var dicMailInfo: [String: Any] = [:]
        
        let empNum = userInfo["EmpNum"] as? String ?? ""
        let firstName = userInfo["FirstName"] as? String ?? ""
        let lastName = userInfo["LastName"] as? String ?? ""
        let email = userInfo["Email"] as? String ?? ""
        let cellPhone = userInfo["CellPhone"] as? String ?? ""
        
        dicMailInfo["ToAddress"] = "admin@wbidmax.com"
        dicMailInfo["FromAddress"] = "admin@wbidmax.com"
        
        dicMailInfo["MessageBody"] =
            """
            Failed User Informations
            Employee Number: \(empNum)
            First Name: \(firstName)
            Last Name: \(lastName)
            Email: \(email)
            Cell Phone: \(cellPhone)
            """.replacingOccurrences(of: "\n", with: "<br/>")
        
        // Employee Number
        let alias = empNum.isEmpty ? "" : "\(empNum) CrewBid-iPad"
        dicMailInfo["Alias"] = alias
        dicMailInfo["EmployeeNumber"] = empNum
        
        // Application Version
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            dicMailInfo["Subject"] = "CrewBid User account creation Failed Log ( \(version) )"
        } else {
            dicMailInfo["Subject"] = "CrewBid User account creation Failed Log"
        }
        
        // User email (App user email, but in Obj-C you were taking from DicUserinfo["Email"])
        dicMailInfo["UserAppEmail"] = email
        
        sendMail(dicMailInfo)
    }

    func sendPaymentFailedMail(_ bidData: String) {
        var dicMailInfo: [String: Any] = [:]
        
        let userDefaultsEmployeeNumber = UserDefaults.standard.string(forKey: kCBEmployeeNumberDefaultKey) ?? ""
        
        dicMailInfo["ToAddress"] = "admin@wbidmax.com"
        dicMailInfo["FromAddress"] = "admin@wbidmax.com"
        
        dicMailInfo["MessageBody"] = bidData.replacingOccurrences(of: "\r\n", with: "<br/>")
        
        // Employee number
        let empNo = userDefaultsEmployeeNumber.isEmpty ? "" : userDefaultsEmployeeNumber
        dicMailInfo["Alias"] = "\(empNo) CrewBid-iPad"
        dicMailInfo["EmployeeNumber"] = userDefaultsEmployeeNumber
        
        // Application Version
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            dicMailInfo["Subject"] = "CrewBid Payment Failed Log ( \(version) )"
        } else {
            dicMailInfo["Subject"] = "CrewBid Payment Failed Log"
        }
        
        // AppDelegate instance
        if let app = UIApplication.shared.delegate as? AppDelegate {
            dicMailInfo["UserAppEmail"] = app.ObjUserAccount?.email ?? ""
        }
        
        sendMail(dicMailInfo)
    }


    func sendMail(_ dicData: [String: Any]) {
        guard let url = URL(string: EndPoint.shared.sendMail) else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicData, options: [])
            urlRequest.httpBody = jsonData
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            // handle request error
            if let error = error as NSError?, error.code == NSURLErrorTimedOut {
                let objEvent = CBOfflineEvents()
                objEvent.sendOfflineDataForTimeOut(url: url.absoluteString, month: nil)
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse else { return }
            
            print("Status code -- \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200,
               let mimeType = response?.mimeType,
               mimeType.contains("application/json") {
                
                do {
                    _ = try JSONSerialization.jsonObject(with: data, options: [])
                    
                    UserDefaults.standard.set("  ", forKey: "ErrorText")
                    
                    if let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileAtPath = filePath.appendingPathComponent("ErrorLog.txt")
                        
                        if FileManager.default.fileExists(atPath: fileAtPath.path) {
                            do {
                                try FileManager.default.removeItem(at: fileAtPath)
                            } catch {
                                print("Could not delete file: \(error.localizedDescription)")
                            }
                        }
                    }
                } catch {
                    print("Failed to parse JSON: \(error.localizedDescription)")
                }
            }
        }
        dataTask.resume()
    }
}
