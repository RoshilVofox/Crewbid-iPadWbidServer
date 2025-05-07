//
//  CBUserAccountDetail.swift
//  CrewBid iPad
//
//  Created by Basith on 08/02/22.
//

import Foundation
import FirebaseCrashlytics

final class CBUserAccountDetail {
    
    var Token = String ()
    var FirstName = String ()
    var LastName = String ()
    var EmpNum = String()
    var Position = Int ()
    var Email = String ()
    var CellPhone = String ()
    var CarrierNum = Int ()
    
    var Password = String ()
    var LoginuserId = String ()
    var AcceptEmail = Bool ()
    var UserAccountDateTime = String()
    var IsMonthlySubscribed = Bool()
    var WBExpirationDate = String()
    var isFree = false
    var topSubscriptionLine = String()
    var secondSubscriptionLine = String()
    var thirdSubscriptionLine = String()
    
    
    var isAutherized : Bool?
    
    // Can't init is singleton
    private init() { }
    
    // MARK: Shared Instance
    
    static let shared = CBUserAccountDetail()
    
    // MARK: Local Variable
    var stringvalue : String = "DATA"
    
    var emptyStringArray : [String] = []
    
    /// Saving user account data to the plist
    // Function to save user information to a plist file

    func saveUserinfo() {
        let DicUserDetails : NSMutableDictionary = NSMutableDictionary()
        DicUserDetails["CellPhone"] = CellPhone
        DicUserDetails["Email"] = Email
        DicUserDetails["EmpNum"] = EmpNum
        DicUserDetails["FirstName"] = FirstName
        DicUserDetails["LastName"] = LastName
        DicUserDetails["Position"] = Position
        DicUserDetails["CarrierNum"] = CarrierNum
        DicUserDetails["AcceptEmail"] = AcceptEmail
        DicUserDetails["UserAccountDateTime"] = UserAccountDateTime
        DicUserDetails["LoginuserId"] = LoginuserId
        DicUserDetails["WBExpirationDate"] = WBExpirationDate
        DicUserDetails["IsMonthlySubscribed"] = IsMonthlySubscribed
        DicUserDetails["topSubscriptionLine"] = topSubscriptionLine
        DicUserDetails["secondSubscriptionLine"] = secondSubscriptionLine
        DicUserDetails["thirdSubscriptionLine"] = thirdSubscriptionLine
        DicUserDetails["Token"] = Token
        // Save the dictionary to a plist file

        self.saveToPlist(dictionary: DicUserDetails)
    }
    // Function to save a dictionary to a plist file

    func saveToPlist(dictionary:NSMutableDictionary) -> Void {
        let plistFileName = "UserAccountDetails.plist"
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)
        let documentPath = paths[0] as NSString
        var plistPath = documentPath.appendingPathComponent(plistFileName)
        if !(FileManager.default.fileExists(atPath: plistPath)) {
            plistPath = documentPath.appendingPathComponent(plistFileName)
        }
        var data = NSMutableDictionary()
        if (FileManager.default.fileExists(atPath: plistPath)) {
            data = NSMutableDictionary(contentsOfFile: plistPath)!
        } else {
            data = NSMutableDictionary ()
        }
        if dictionary.count > 0 {
            data["UserDetails"] = dictionary
            // Write the data to the plist file

            data.write(toFile: plistPath, atomically: true)
            do {
                let url = URL(string: plistPath)!
                try data.write(to: url)
            } catch {
                print(error)
            }
        }
    }
    
    // Function to read user information from a plist file

    func readPlist() -> NSMutableDictionary {
        let plistFileName = "UserAccountDetails.plist"
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
    
    func isuserIfoAvaialble() -> Bool {
        var flag: Bool = false
        var dicUserData: NSMutableDictionary = NSMutableDictionary()
        dicUserData = readPlist()
        if ((dicUserData.count) > 0) {
            flag = true
            // Retrieve user details from the plist

            CellPhone = dicUserData["CellPhone"] as! String
            Email = dicUserData["Email"] as! String
            EmpNum = dicUserData["EmpNum"] as! String
            FirstName = dicUserData["FirstName"] as! String
            LastName = dicUserData["LastName"] as! String
            Position = dicUserData["Position"] as! Int
            let Carnum =  dicUserData["CarrierNum"] as! NSNumber
            CarrierNum = Int(truncating: Carnum)
            AcceptEmail = dicUserData["AcceptEmail"] as! Bool
            LoginuserId = dicUserData["LoginuserId"] as! String
            Token = dicUserData["Token"] as! String
            if dicUserData["IsMonthlySubscribed"] as? String == nil {
                IsMonthlySubscribed = dicUserData["IsMonthlySubscribed"] as! Bool
            } else {
                let IsMonthlySubscribedStr = dicUserData["IsMonthlySubscribed"] as! String
                if let IsMonthlySubscribedInt = Int(IsMonthlySubscribedStr) {
                    let IsMonthlySubscribedNum = NSNumber(value:IsMonthlySubscribedInt)
                    IsMonthlySubscribed = IsMonthlySubscribedNum.boolValue
                }
            }
            if (dicUserData["topSubscriptionLine"] as? String) != nil {
                topSubscriptionLine = dicUserData["topSubscriptionLine"] as! String
            }
            if (dicUserData["secondSubscriptionLine"] as? String) != nil {
                secondSubscriptionLine = dicUserData["secondSubscriptionLine"] as! String
            }
            if (dicUserData["thirdSubscriptionLine"] as? String) != nil {
                thirdSubscriptionLine = dicUserData["thirdSubscriptionLine"] as! String
            }
        }
        return flag
    }
    
    // Function to send crash details to Crashlytics

    func sentCrashDetails(){
//        var dicUserData: NSMutableDictionary = NSMutableDictionary()
//        dicUserData = readPlist()
//            if let bid = CBGlobalMethods.shared.selectedBidPeriod {
//                dicUserData.setValue(bid.base, forKey: "base")
//                dicUserData.setValue("\(String(describing: bid.getPosString()))", forKey: "type")
//                dicUserData.setValue("\(bid.round!)", forKey: "round")
//            }
//        
//        if ((dicUserData.count) > 0) {
//            Crashlytics.crashlytics().setCustomKeysAndValues(dicUserData as! [AnyHashable : Any])
//        }
    }
    
    

    // Function to delete user account details from the plist

    func deleteUserAccount() -> Void {
        let plistFileName = "UserAccountDetails.plist"
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentPath = paths[0] as NSString
        let plistPath = documentPath.appendingPathComponent(plistFileName)
        do {
            if FileManager.default.fileExists(atPath: plistPath) {
                try FileManager.default.removeItem(atPath: plistPath)
            }
        } catch {
            print(error)
        }
    }
    
}
