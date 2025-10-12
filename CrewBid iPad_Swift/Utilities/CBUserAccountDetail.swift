//
//  CBUserAccountDetail.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 08/07/25.
//

import Foundation
import FirebaseCrashlytics

 class CBUserAccountDetail {
    
    var token = String ()
    var firstName = String ()
    var lastName = String ()
    var employeeNumber = String()
    var position = Int ()
    var email = String ()
    var cellPhone = String ()
    var CarrierNum = Int ()
    
    var Password = String ()
    var LoginuserId = String ()
    var AcceptEmail = Bool ()
    var UserAccountDateTime = String()
    var isYearlySubscribed: Bool = false
    var isMonthlySubscribed: Bool = false
    var isCBMonthlySubscribed: Bool = false
    var isCBYearlySubscribed: Bool = false
    var WBExpirationDate = String()
    var isFree = false
    var topSubscriptionLine = String()
    var secondSubscriptionLine = String()
    var thirdSubscriptionLine = String()
    var dicLoginAuthDetails: NSMutableDictionary = NSMutableDictionary()
    var dicLogInAuthExternalUser: NSMutableDictionary = NSMutableDictionary()
    var dataSource: BIBidInfoReaderDataSource?
    var isAuthorized : Bool?
    var maxSubscriptionDate = String()
    var userType: String?
    var isAcceptMail = false
    var isAcceptUserTerms = false
    var userEncryptedExpirationDate: String?
    var vacationFilename: String?
    var arrVacationList = [Any]()
    var isFAVactionDisplayOn = false

    // FA Days
    var faRound1LinesPostedDay: String?
    var faRound1LinesDueDay: String?
    var faRound2LinesPostedDay: String?
     var faRound2LinesDueDay: String = ""
    // Non-FA Days
    var nonFaRound1LinesPostedDay: String?
    var nonFaRound1LinesDueDay: String?
    var nonFaRound2LinesPostedDay: String?
     var nonFaRound2LinesDueDay: String = ""
    // FA Active Flags
    var faRound1LinesPostedDayActive: Bool = false
    var faRound1LinesDueDayActive: Bool = false
    var faRound2LinesPostedDayActive: Bool = false
    var faRound2LinesDueDayActive: Bool = false
    // Non-FA Active Flags
    var nonFaRound1LinesPostedDayActive: Bool = false
    var nonFaRound1LinesDueDayActive: Bool = false
    var nonFaRound2LinesPostedDayActive: Bool = false
    var nonFaRound2LinesDueDayActive: Bool = false
    // FA Messages
    var faRound1LinesPostedDayMessage: String?
    var faRound1LinesDueDayMessage: String?
    var faRound2LinesPostedDayMessage: String?
     var faRound2LinesDueDayMessage: String = ""
    // Non-FA Messages
    var nonFaRound1LinesPostedDayMessage: String?
    var nonFaRound1LinesDueDayMessage: String?
    var nonFaRound2LinesPostedDayMessage: String?
    var nonFaRound2LinesDueDayMessage: String?
     
     let mailChimpApiKey1 = "d92d00c71c4c417dd6b6ccd69270eaa0-us3"
     let mailChimpListID1 = "101e8c801f"
     
     
    static let shared = CBUserAccountDetail()

    var stringvalue : String = "DATA"
    
    var emptyStringArray : [String] = []
    

     func saveUserInfo() {
         let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
         var dicUserDetails: [String: Any] = [:]
         
         dicUserDetails["CellPhone"] = cellPhone
         dicUserDetails["firstName"] = firstName
         dicUserDetails["lastname"] = lastName
         dicUserDetails["employeeNumber"] = employeeNumber
         dicUserDetails["email"] = email
         UserDefaults.standard.set(maxSubscriptionDate, forKey: "MaxSubscriptionDate")
         dicUserDetails["LoginuserId"] = LoginuserId
         if UserAccountDateTime.length > 0 {
             dicUserDetails["UserAccountDateTime"] = UserAccountDateTime
         }
         
         
         // Round Days
         UserDefaults.standard.set(faRound1LinesPostedDay, forKey: "FAround1LinesPostedDay")
         UserDefaults.standard.set(faRound1LinesDueDay, forKey: "FAround1LinesDueDay")
         UserDefaults.standard.set(faRound2LinesPostedDay, forKey: "FAround2LinesPostedDay")
         UserDefaults.standard.set(faRound2LinesDueDay, forKey: "FAround2LinesDueDay")
         UserDefaults.standard.set(nonFaRound1LinesPostedDay, forKey: "NonFAround1LinesPostedDay")
         UserDefaults.standard.set(nonFaRound1LinesDueDay, forKey: "NonFAround1LinesDueDay")
         UserDefaults.standard.set(nonFaRound2LinesPostedDay, forKey: "NonFAround2LinesPostedDay")
         UserDefaults.standard.set(nonFaRound2LinesDueDay, forKey: "NonFAround2LinesDueDay")
         
         // Round Active flags
         UserDefaults.standard.set(faRound1LinesPostedDayActive.intValue, forKey: "FAround1LinesPostedDayActive")
         UserDefaults.standard.set(faRound1LinesDueDayActive.intValue, forKey: "FAround1LinesDueDayActive")
         UserDefaults.standard.set(faRound2LinesPostedDayActive.intValue, forKey: "FAround2LinesPostedDayActive")
         UserDefaults.standard.set(faRound2LinesDueDayActive.intValue, forKey: "FAround2LinesDueDayActive")
         UserDefaults.standard.set(nonFaRound1LinesPostedDayActive.intValue, forKey: "NonFAround1LinesPostedDayActive")
         UserDefaults.standard.set(nonFaRound1LinesDueDayActive.intValue, forKey: "NonFAround1LinesDueDayActive")
         UserDefaults.standard.set(nonFaRound2LinesPostedDayActive.intValue, forKey: "NonFAround2LinesPostedDayActive")
         UserDefaults.standard.set(nonFaRound2LinesDueDayActive.intValue, forKey: "NonFAround2LinesDueDayActive")
         
         // Round Messages
         UserDefaults.standard.set(faRound1LinesPostedDayMessage, forKey: "FAround1LinesPostedDayMessage")
         UserDefaults.standard.set(faRound1LinesDueDayMessage, forKey: "FAround1LinesDueDayMessage")
         UserDefaults.standard.set(faRound2LinesPostedDayMessage, forKey: "FAround2LinesPostedDayMessage")
         UserDefaults.standard.set(faRound2LinesDueDayMessage, forKey: "FAround2LinesDueDayMessage")
         UserDefaults.standard.set(nonFaRound1LinesPostedDayMessage, forKey: "NonFAround1LinesPostedDayMessage")
         UserDefaults.standard.set(nonFaRound1LinesDueDayMessage, forKey: "NonFAround1LinesDueDayMessage")
         UserDefaults.standard.set(nonFaRound2LinesPostedDayMessage, forKey: "NonFAround2LinesPostedDayMessage")
         UserDefaults.standard.set(nonFaRound2LinesDueDayMessage, forKey: "NonFAround2LinesDueDayMessage")
         
         dicUserDetails["Password"] = Password
         dicUserDetails["Position"] = "\(position)"
         dicUserDetails["CarrierNum"] = "\(CarrierNum)"
         
         dicUserDetails["isAcceptUserTerms"] = isAcceptUserTerms ? "YES" : "NO"
         dicUserDetails["isAcceptMail"] = isAcceptMail ? "YES" : "NO"
         dicUserDetails["isFAVactionDisplayOn"] = isFAVactionDisplayOn ? "YES" : "NO"
         
         dicUserDetails["isFree"] = isFree ? "YES" : "NO"
         dicUserDetails["IsMonthlySubscribed"] = isMonthlySubscribed ? "YES" : "NO"
         dicUserDetails["IsYearlySubscribed"] = isYearlySubscribed ? "YES" : "NO"
         dicUserDetails["IsCBMonthlySubscribed"] = isCBMonthlySubscribed ? "YES" : "NO"
         dicUserDetails["IsCBYearlySubscribed"] = isCBYearlySubscribed ? "YES" : "NO"
         
         if dicLoginAuthDetails.count > 0 {
             dicUserDetails["DicLoginAuthDetails"] = dicLoginAuthDetails
         }
         if dicLogInAuthExternalUser.count > 0 {
             dicUserDetails["DicLogInAuthExternalUser"] = dicLogInAuthExternalUser
         }
         
         dicUserDetails["TopSubscriptionLine"] = topSubscriptionLine
         dicUserDetails["SecondSubscriptionLine"] = secondSubscriptionLine
         dicUserDetails["ThirdSubscriptionLine"] = thirdSubscriptionLine
         
         // Save to Keychain and Plist
         saveToKeyChain(userdata: dicUserDetails)
         saveToPlist(userdata: dicUserDetails)
     }
     
     func saveToKeyChain(userdata: [String: Any]) {
         do {
             // Archive dictionary into Data (not requiring secure coding for backward compatibility)
             let data = try NSKeyedArchiver.archivedData(withRootObject: userdata, requiringSecureCoding: false)

             // Save into keychain
             let success = KeychainHelper.save(account: "CWAUserAccountDetails",
                                               service: "UserAccountService",
                                               value: data.base64EncodedString())
             if !success {
                 print("Failed to save user data to keychain")
             }
         } catch {
             print("Error archiving user data: \(error)")
         }
     }
     
    // Function to save a dictionary to a plist file

     func saveToPlist(userdata: [String: Any]) {
         // Get Documents directory
         guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
             print("Could not find documents directory")
             return
         }
         
         let path = documentsDirectory.appendingPathComponent("LocalUserDetails.plist")
         
         var data: [String: Any] = [:]
         
         if FileManager.default.fileExists(atPath: path.path) {
             // Load existing data
             if let existingData = NSDictionary(contentsOf: path) as? [String: Any] {
                 data = existingData
             }
         }
         
         // Insert/overwrite UserDetails key
         if !userdata.isEmpty {
             data["UserDetails"] = userdata
             let success = (data as NSDictionary).write(to: path, atomically: true)
             if success {
                 print("Saved UserDetails to plist at \(path)")
             } else {
                 print("Failed to save plist")
             }
         }
     }
    
    // Function to read user information from a plist file

    func readPlist() -> NSMutableDictionary {
        let plistFileName = "LocalUserDetails.plist"
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)
        let documentPath = paths[0] as NSString
        let plistPath = documentPath.appendingPathComponent(plistFileName)
        var savedValue: NSMutableDictionary!
        savedValue = NSMutableDictionary()
        savedValue = NSMutableDictionary(contentsOfFile: plistPath)
        var value = NSMutableDictionary()
        if savedValue != nil {
            value = savedValue["UserDetails"] as! NSMutableDictionary
        }
        if !((value.count) > 0) {
            value=NSMutableDictionary ()
        }
        return value
    }
    
    // Function to check if user information is available in the plist file
    
     func isUserInfoAvailable() -> Bool {
         var flag = false
         guard let dicUserData = readPlist() as? [String: Any] else {
             return false
         }

         if dicUserData.count > 0 {
             flag = true

             // Strings
             self.cellPhone = dicUserData["CellPhone"] as? String ?? ""
             self.firstName = dicUserData["firstName"] as? String ?? ""
             self.lastName = dicUserData["lastname"] as? String ?? ""
             self.employeeNumber = dicUserData["employeeNumber"] as? String ?? ""
             self.email = dicUserData["email"] as? String ?? ""
             self.Password = dicUserData["Password"] as? String ?? ""
             self.LoginuserId = dicUserData["LoginuserId"] as? String ?? ""
             self.UserAccountDateTime = dicUserData["UserAccountDateTime"] as? String ?? ""

             // Ints
             if let pos = dicUserData["Position"] as? Int {
                 self.position = pos
             }
             if let carrierNum = dicUserData["CarrierNum"] as? String {
                 self.CarrierNum = Int(carrierNum) ?? 0
             }

             // Booleans from "YES"/"NO"
             func boolFromYesNo(_ value: Any?) -> Bool {
                 guard let str = value as? String else { return false }
                 return str.uppercased() == "YES"
             }

             self.isFAVactionDisplayOn = boolFromYesNo(dicUserData["isFAVactionDisplayOn"])
             self.isAcceptMail = boolFromYesNo(dicUserData["isAcceptMail"])
             self.isFree = boolFromYesNo(dicUserData["isFree"])
             self.isMonthlySubscribed = boolFromYesNo(dicUserData["IsMonthlySubscribed"])
             self.isYearlySubscribed = boolFromYesNo(dicUserData["IsYearlySubscribed"])
             self.isCBYearlySubscribed = boolFromYesNo(dicUserData["IsCBYearlySubscribed"])
             self.isCBMonthlySubscribed = boolFromYesNo(dicUserData["IsCBMonthlySubscribed"])

             // Dictionaries
             if let loginAuth = dicUserData["DicLoginAuthDetails"]  as? NSMutableDictionary {
                 self.dicLoginAuthDetails = loginAuth
             }
             if let externalUser = dicUserData["DicLogInAuthExternalUser"] as? NSMutableDictionary {
                 self.dicLogInAuthExternalUser = externalUser
             }

             // Subscription lines
             self.topSubscriptionLine = dicUserData["TopSubscriptionLine"] as! String
             self.secondSubscriptionLine = dicUserData["SecondSubscriptionLine"] as! String
             self.thirdSubscriptionLine = dicUserData["ThirdSubscriptionLine"] as! String

             // Dates
             if let maxDate = dicUserData["MaxSubscriptionDate"] as? String {
                 self.maxSubscriptionDate = maxDate
             }
         }

         // Crashlytics logging
         if let empId = dicUserData["LoginuserId"] {
//             Crashlytics.crashlytics().log("Employee ID: \(empId)")
//             Crashlytics.crashlytics().setCustomValue(empId, forKey: "EmployeeNumber")
         }

         // Save to Keychain
         saveToKeyChain(userdata: dicUserData)

         return flag
     }
    
    
     func deleteUserAccount() {
         // Get documents directory path
         guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
             print("Could not find documents directory.")
             return
         }
         
         let fileURL = documentsDirectory.appendingPathComponent("LocalUserDetails.plist")
         
         if FileManager.default.fileExists(atPath: fileURL.path) {
             do {
                 try FileManager.default.removeItem(at: fileURL)
                 print("User account plist deleted successfully.")
             } catch {
                 print("Failed to delete user account plist: \(error.localizedDescription)")
             }
         } else {
             print("No user account plist found to delete.")
         }
     }
    
     func captureUserEmail(_ emailAddress: String?) {
         guard let userEmail = emailAddress, !userEmail.isEmpty else {
             print("Invalid email address.")
             return
         }
         
         // Update in AppDelegate dictionary
         if let app = UIApplication.shared.delegate as? AppDelegate {
             app.dicCurrentBidDetails?["Usermail"] = userEmail
         }
         
         // Save in iCloud key-value store
         let store = NSUbiquitousKeyValueStore.default
         var userInfo = (store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any]) ?? [:]
         userInfo[kCBUserInfoUserEmailKey] = userEmail
         CBUserInfo.setUserInfoDictionary(userInfo)
         
         // Upload to MailChimp
         let ck = ChimpKit(delegate: self, andApiKey: mailChimpApiKey1)
         var params: [String: Any] = [
             "id": mailChimpListID1,
             "email_address": userEmail,
             "double_optin": "true",
             "update_existing": "false"
         ]
         
         let mergeVars: [String: Any] = [
             "FNAME": "First",
             "LNAME": "Last"
         ]
         params["merge_vars"] = mergeVars
         
         ck?.callApiMethod("listSubscribe", withParams: params)
     }
     
}
