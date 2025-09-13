//
//  CBUserInfo.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/09/25.
//

import Foundation

let kCBUserInfoUserParseID = "UserInfoUserParseIDKey"
let kCBUserInfoParseObjectID = "UserInfoParseObjectIDKey"
let kCBUserInfoUserEmail = "UserInfoUserEmail"
let kCBUserInfoEncryptedExpirationDate = "UserInfoEncryptedExpirationDateKey"
let kCBUserInfoEncryptedWbidExpirationDate = "UserInfoEncryptedWbidExpirationDateKey"
let kCBUserInfoPurchaseTypesKey = "UserInfoPurchaseTypesKey"
let kCBUserInfoParseClassName = "UserInfo"
let kCBUserInfoPosition = "Position"
let kCBUserInfoDecryptedExpirationDate = "UserInfoDecryptedExpirationDateKey"
let kCBUserInfoDecryptedWbidExpirationDate = "UserInfoDecryptedWbidExpirationDateKey"
let kCBUserInfoMarchMadness = "UserInfoMarchMadnessKey"
let kCBUserInfoMostRecentPurchaseDate = "MostRecentPurchaseDate"
let kCBUserInfoParseUserSubscriptionExpirationDate = "SubscriptionExpirationDate"

class CBUserInfo: NSObject, NSCoding {
    // MARK: - Properties
    var userParseID: String?
    var parseObjectId: String?
    var userEmail: String?
    var encryptedExpirationDate: String?
    var purchaseTypes: [String] = []
    var marchMadness: Bool = false

    // MARK: - Designated initializer
    override init() {
        super.init()
    }

    // MARK: - Convenience initializer
    convenience init(bestAvailable: Bool) {
        self.init()

        guard bestAvailable else { return }

        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        if let encodedUserInfo = store.object(forKey: kCBUserInfoKey) as? Data,
           let decoded = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CBUserInfo.self, from: encodedUserInfo) {
            self.copyProperties(from: decoded)
        } else if let encodedUserInfo = UserDefaults.standard.object(forKey: kCBUserInfoKey) as? Data,
                  let decoded = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CBUserInfo.self, from: encodedUserInfo) {
            self.copyProperties(from: decoded)
        } else {
            self.purchaseTypes = []
        }
    }
    
    private func copyProperties(from other: CBUserInfo) {
        self.userParseID = other.userParseID
        self.parseObjectId = other.parseObjectId
        self.userEmail = other.userEmail
        self.encryptedExpirationDate = other.encryptedExpirationDate
        self.purchaseTypes = other.purchaseTypes
        self.marchMadness = other.marchMadness
    }

    required init?(coder decoder: NSCoder) {
        super.init()
        
        self.userParseID = decoder.decodeObject(forKey: "userParseID") as? String
        self.parseObjectId = decoder.decodeObject(forKey: "parseObjectId") as? String
        self.userEmail = decoder.decodeObject(forKey: "userEmail") as? String
        self.encryptedExpirationDate = decoder.decodeObject(forKey: "encryptedExpirationDate") as? String
        self.purchaseTypes = decoder.decodeObject(forKey: "purchaseTypes") as? [String] ?? []
        self.marchMadness = decoder.decodeObject(forKey: "marchMadness") as? Bool ?? false
    }

    func encode(with coder: NSCoder) {
        coder.encode(userParseID, forKey: "userParseID")
        coder.encode(parseObjectId, forKey: "parseObjectId")
        coder.encode(userEmail, forKey: "userEmail")
        coder.encode(encryptedExpirationDate, forKey: "encryptedExpirationDate")
        coder.encode(purchaseTypes, forKey: "purchaseTypes")
        coder.encode(marchMadness, forKey: "marchMadness")
    }

    // MARK: - Methods
    func getUserParseObjectId() -> String? {
        return self.userParseID
    }

    convenience init(bestAvailableUserInfo: [String: Any]) {
        self.init()
        userParseID = bestAvailableUserInfo["userParseID"] as? String
        parseObjectId = bestAvailableUserInfo["parseObjectId"] as? String
        userEmail = bestAvailableUserInfo["userEmail"] as? String
        encryptedExpirationDate = bestAvailableUserInfo["encryptedExpirationDate"] as? String
        purchaseTypes = bestAvailableUserInfo["purchaseTypes"] as? [String] ?? []
        marchMadness = bestAvailableUserInfo["marchMadness"] as? Bool ?? false
    }

    func archiveUserInfo() {
        do {
            // Archive the current object
            let encodedUserInfo = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
            
            // Save to iCloud
            let store = NSUbiquitousKeyValueStore.default
            store.set(encodedUserInfo, forKey: kCBUserInfoKey)
            store.synchronize()
            
            // Save to UserDefaults
            UserDefaults.standard.set(encodedUserInfo, forKey: kCBUserInfoKey)
            UserDefaults.standard.synchronize()
            
        } catch {
            print("Failed to archive CBUserInfo: \(error)")
        }
    }

    // MARK: - Class Methods
    class func bestAvailableUserInfoDictionary() -> [String: Any]? {
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()
        
        if let userInfo = store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any] {
            return userInfo
        } else if let userInfo = UserDefaults.standard.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any] {
            return userInfo
        }
        
        return nil
    }

    class func setUserInfoDictionary(_ userInfo: [String: Any]) {
        // Set iCloud userInfo
        let store = NSUbiquitousKeyValueStore.default
        store.set(userInfo, forKey: kCBUserInfoDictionaryKey)
        store.synchronize()
        
        // Set UserDefaults userInfo
        UserDefaults.standard.set(userInfo, forKey: kCBUserInfoDictionaryKey)
        UserDefaults.standard.synchronize()
    }

}
