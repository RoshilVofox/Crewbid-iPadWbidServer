//
//  IAPHelper.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 02/09/25.
//
/*
import Foundation
import StoreKit

class CBIAPHelper: IAPHelper{
    
    static let shared: CBIAPHelper = {
        let productIdentifiers: Set<String> = [
            kCBMonthlyMaxSubscriptionIdentifier
        ]
        return CBIAPHelper(productIdentifiers: productIdentifiers)
    }()
    
    private override init(productIdentifiers: Set<String>) {
        super.init(productIdentifiers: productIdentifiers)
    }
    
}

let IAPHelperProductPurchasedNotification = "IAPHelperProductPurchasedNotification"
let kCBNewSubscriptionPurchasedNotification = "CBNewSubscriptionPurchasedNotification"
let kSubscriptionExpirationDateKey = "ExpirationDate"
let kCBSubscriptionToken = "CBSubscriptionToken"
private let kFreeMonthEncryptionKey = "acc37fb4-d850"
let kCBExpirationDateFormat1 = "MM/dd/yyyy HH:mm:ss"

typealias RequestProductsCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

let kCBMonthlyMaxSubscriptionIdentifier = "com.brainbagsoftware.crewbid.monthlyMaxcrewbid_6_99"



class IAPHelper: NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {

    // MARK: - Instance properties
    var app: AppDelegate?
    var objDataBuilder: ODataBuilder?
    var dicCWAMasterDetails: [AnyHashable: Any] = [:]
    var productId: String?
    private var productsRequest: SKProductsRequest?
    private var completionHandler: RequestProductsCompletionHandler?
    private var productIdentifiers: Set<String>
    private var purchasedProductIdentifiers = Set<String>()
    var purchaseInProgress = false
    var refreshCounter = 0
    weak var transaction: SKPaymentTransaction?
    
    // MARK: - Initializer
    init(productIdentifiers: Set<String>) {
         self.productIdentifiers = productIdentifiers
         super.init()

         // Check previously purchased products
         for productIdentifier in productIdentifiers {
             let productPurchased = UserDefaults.standard.bool(forKey: productIdentifier)
             if productPurchased {
                 purchasedProductIdentifiers.insert(productIdentifier)
                 // print("Previously purchased: \(productIdentifier)")
             } else {
                 // print("Not purchased: \(productIdentifier)")
             }
         }

         // Add self as transaction observer
         SKPaymentQueue.default().add(self)
     }
    
    func requestProducts(completionHandler: @escaping RequestProductsCompletionHandler) {
        self.completionHandler = completionHandler
        self.productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        self.productsRequest?.delegate = self
        self.productsRequest?.start()
    }
    
    
    func productPurchased(_ productIdentifier: String) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    func buyProduct(_ product: SKProduct) {
        // Store the product identifier
        productId = product.productIdentifier
        // Create payment and add to the queue
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func validateReceipt(for transaction: SKPaymentTransaction) {
        if let transactionId = transaction.transactionIdentifier {
            print("Transaction id---\(transactionId)")
        }

        // Finish the transaction
        SKPaymentQueue.default().finishTransaction(transaction)

        // Provide content for the product
        provideContent(for: transaction)

        // Mark purchase as completed
        purchaseInProgress = false
    }
    
    func checkReceiptWithICloud() {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            return
        }
        
        // Prepare JSON request body
        let requestDictionary: [String: Any] = [
            "receipt-data": receiptData.base64EncodedString()
        ]
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestDictionary,
                                                           options: .prettyPrinted) else {
            return
        }
        
        // Apple sandbox verification URL (change to production if needed)
        guard let storeURL = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt") else { return }
        
        var storeRequest = URLRequest(url: storeURL)
        storeRequest.httpMethod = "POST"
        storeRequest.httpBody = requestData
        
        // Perform async request
        let task = URLSession.shared.dataTask(with: storeRequest) { data, response, error in
            if let error = error {
                print("Receipt validation connection error: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let receipt = jsonResponse["receipt"] as? [String: Any],
                   let inApp = receipt["in_app"] as? [[String: Any]] {
                    
                    let pendingArray = self.getTransactions()
                    
                    for dicPending in pendingArray {
                        if let pendingTransactionID = dicPending["transactionID"] as? String {
                            for dicInApp in inApp {
                                if let inAppTransactionID = dicInApp["transaction_id"] as? String,
                                   pendingTransactionID == inAppTransactionID {
                                    // Match found -> remove from iCloud
                                    self.removeTransactionIcloud(withTransactionIdentifier: pendingTransactionID)
                                }
                            }
                        }
                    }
                }
            } catch {
                print("JSON parse error: \(error)")
            }
        }
        task.resume()
    }
    
    
    func removeTransactionIcloud(withTransactionIdentifier transactionIdentifier: String) {
        let store = NSUbiquitousKeyValueStore.default
        guard let transactions = store.array(forKey: "transaction") as? [[String: Any]],
              !transactions.isEmpty else {
            return
        }
        
        // Filter out the matching transaction ID
        let updatedTransactions = getNewTransactions(from: transactions, withKey: transactionIdentifier)
        
        store.set(updatedTransactions, forKey: "transaction")
        store.synchronize()
        
        offlineLogging(productID: "InAppPendingRemoved", transactionID: transactionIdentifier)
    }
    
    func getNewTransactions(from transactions: [[String: Any]], withKey key: String) -> [[String: Any]] {
        var transactionMutableArray = transactions
        for (index, dict) in transactions.enumerated() {
            if let transactionID = dict["transactionID"] as? String, transactionID == key {
                transactionMutableArray.remove(at: index)
                break // stop after removing the first match
            }
        }
        return transactionMutableArray
    }
    
    func offlineLogging(productID: String, transactionID: String) {
        // Show alert
        let alert = UIAlertController(
            title: "Something went wrong",
            message: "Purchased date not updated to remote user account. Please contact us. We would love to help.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        if let currentTopVC = currentTopViewController() {
            currentTopVC.present(alert, animated: true, completion: nil)
        }
        
        
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        var offlineData: [String: Any] = [:]
        
        if let employeeNumber = app.ObjUserAccount?.employeeNumber {
            let cleanedNumber = "\(employeeNumber)"
                .replacingOccurrences(of: "e", with: "")
                .trimmingCharacters(in: CharacterSet.symbols)
            
            if let intValue = Int(cleanedNumber) {
                offlineData["EmployeeNumber"] = intValue
                offlineData["BidForEmpNum"] = intValue
            }
        }
        
        offlineData["Event"] = "PaymentReceived"
        offlineData["Base"] = "BWI"
        offlineData["Month"] = ""
        
        if let position = app.ObjUserAccount?.position {
            offlineData["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: position)!)
        }
        
        offlineData["Round"] = 0
        offlineData["Message"] = "In app purchase success But No network - Purchase Id- \(productID), transaction id- \(transactionID)"
        offlineData["VersionNumber"] = CBUtils.AppVersion()
        offlineData["PlatformNumber"] = "iPad"
        offlineData["OperatingSystemNum"] = "iPad OS"
        
        // Submit three bids
        offlineData["BuddyBid1"] = 0
        offlineData["BuddyBid2"] = 0
        offlineData["BuddyBid3"] = 0
        
        let now = Date()
        let startDate = now.timeIntervalSince1970 * 1000
        let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)
        offlineData["date"] = dateStarted
        
        if let ipAddress = app.IPAddress {
            offlineData["IpAddress"] = ipAddress
        }
        
        let objEvent = CBOfflineEvents()
        objEvent.addOfflineEvent(offlineData)
    }
    
    func provideContent(for transaction: SKPaymentTransaction) {
        let productIdentifier = transaction.payment.productIdentifier
        
        switch productIdentifier {
        case kCBMonthlyMaxSubscriptionIdentifier:
            switch transaction.transactionState {
            case .deferred:
                purchaseMaxSubscriptionWithMonthsPending(
                    months: 1,
                    productID: productIdentifier,
                    transactionID: transaction.transactionIdentifier ?? "",
                    transactionState: "\(transaction.transactionState.rawValue)"
                )
            case .purchased:
                purchaseMaxSubscription(
                    months: 1,
                    productID: productIdentifier,
                    transactionID: transaction.transactionIdentifier ?? "",
                    transactionState: "\(transaction.transactionState.rawValue)"
                )
            default:
                break
            }
            
        default:
            switch transaction.transactionState {
            case .deferred:
                // purchaseSubscriptionWithMonthsForPending(6, productID: productIdentifier, ...)
                break
            case .purchased:
                // purchaseSubscriptionWithMonths(6, productID: productIdentifier, ...)
                break
            default:
                break
            }
        }
        
        NotificationCenter.default.post(
            name: Notification.Name(IAPHelperProductPurchasedNotification),
            object: productIdentifier,
            userInfo: nil
        )
    }
    
    func purchaseMaxSubscriptionWithMonthsPending(
        months: Int,
        productID: String,
        transactionID: String,
        transactionState state: String
    ) {
        let iCloudDate = getICloudDecryptedWbidExpirationDate()
        let localDate = getLocalDecryptedWbidExpirationDate()
        
        if let iCloudDate = iCloudDate, let localDate = localDate, iCloudDate > localDate  {
            setLocalEncryptedWbidExpirationDate(iCloudDate)
        }
        
        let expirationDate = getMaxExpirationDate(forMonths: months)
        setICloudEncryptedWbidExpirationDate(expirationDate!)
        setLocalEncryptedWbidExpirationDate(expirationDate!)
        
        let date = Date()
        setICloudTransactionState(state, transationIdentifier: productID, transactionID: transactionID, transactionDate: date)
        
        if app!.connectedToInternet() {
            let userInfo: [String: Any] = [
                "Month": months,
                "TransactionID": transactionID,
                "Type": "WBid"
            ]
            NotificationCenter.default.post(
                name: Notification.Name("TempInAppPurchaseUpdate"),
                object: self,
                userInfo: userInfo
            )
        } else {
            OfflineLogging(productID: productID, transactionID: transactionID)
            OfflinePayment(productID: productID, transactionID: transactionID, months: months, purchaseType: "WBid")
        }
    }
    
    
    func purchaseMaxSubscription(
        months: Int,
        productID: String,
        transactionID: String,
        transactionState: String
    ) {
        // Compare iCloud and local expiration dates
        let iCloudDate = getICloudDecryptedWbidExpirationDate()
        let localDate = getLocalDecryptedWbidExpirationDate()
        
        if let iCloudDate = iCloudDate, let localDate = localDate, iCloudDate > localDate {
            setLocalEncryptedWbidExpirationDate(iCloudDate)
        }
        
        // Compute new expiration date
        guard let expirationDate = getMaxExpirationDate(forMonths: months) else { return }
        setICloudEncryptedWbidExpirationDate(expirationDate)
        setLocalEncryptedWbidExpirationDate(expirationDate)
        
        // Check if transaction was pending
        let transactions = getTransactions()
        var wasPending = false
        for dic in transactions {
            if let dicTransactionID = dic["transactionID"] as? String, dicTransactionID == transactionID {
                wasPending = true
                break
            }
        }
        
        if wasPending {
            let userInfo: [String: Any] = ["Month": months, "TransactionID": transactionID, "Type": "WBid"]
            validateDirectly(userInfo)
        } else {
            if isVPSConnected() {
                OfflinePayment(productID: productID, transactionID: transactionID, months: months, purchaseType: "WBid")
                let userInfo: [String: Any] = ["Month": months, "TransactionID": transactionID, "Type": "WBid"]
                NotificationCenter.default.post(name: Notification.Name("InAppPurchaseUpdate"), object: self, userInfo: userInfo)
            } else {
                OfflineLogging(productID: productID, transactionID: transactionID)
                OfflinePayment(productID: productID, transactionID: transactionID, months: months, purchaseType: "WBid")
            }
        }
    }
    
    func isVPSConnected() -> Bool {
        guard let url = URL(string: EndPoint.shared.VPSPing),
              let data = try? Data(contentsOf: url) else {
            return false
        }
        
        if let lookup = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let status = lookup["Status"] as? String,
           status == "Success" {
            return true
        }
        
        return false
    }
    
    func validateDirectly(_ userInfo: [String: Any]) {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            // Handle missing receipt
            return
        }
        
        // Prepare JSON payload
        let base64Receipt = receiptData.base64EncodedString()
        let requestContents: [String: Any] = ["receipt-data": base64Receipt]
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestContents, options: .prettyPrinted) else {
            // Handle JSON serialization error
            return
        }
        
        // Create POST request to the sandbox Apple endpoint
        guard let storeURL = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt") else { return }
        var storeRequest = URLRequest(url: storeURL)
        storeRequest.httpMethod = "POST"
        storeRequest.httpBody = requestData
        
        // Send request on a background queue
        let queue = OperationQueue()
        URLSession.shared.dataTask(with: storeRequest) { data, response, error in
            if let error = error {
                print("Connection error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data,
                  let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let receipt = jsonResponse["receipt"] as? [String: Any],
                  let inApp = receipt["in_app"] as? [[String: Any]],
                  let firstPurchase = inApp.first,
                  let originalTransactionDate = firstPurchase["original_purchase_date"] as? String else {
                return
            }
            
            // Post notification with updated userInfo
            var updatedUserInfo = userInfo
            updatedUserInfo["original_purchase_date"] = originalTransactionDate
            NotificationCenter.default.post(
                name: Notification.Name("InAppPurchaseUpdateAfterPending"),
                object: self,
                userInfo: updatedUserInfo
            )
        }.resume()
    }
    
    
    func getTransactions() -> [[String: Any]] {
        let store = NSUbiquitousKeyValueStore.default
        let transactions = store.object(forKey: "transaction") as? [[String: Any]] ?? []
        return transactions
    }
    
    
    func OfflinePayment(productID: String, transactionID: String, months: Int, purchaseType: String) {
        guard let app = UIApplication.shared.delegate as? AppDelegate,
              let employeeNumber = app.ObjUserAccount?.employeeNumber,
              !employeeNumber.isEmpty else {
            return
        }
        
        var dicData: [String: Any] = [:]
        dicData["EmpNum"] = employeeNumber
        dicData["Month"] = months
        
        // Set message based on months and purchase type
        if months == 1 {
            if purchaseType == "WBid" {
                dicData["Message"] = "PaymentReceived for Onetime Monthly,WBid"
            } else {
                dicData["Message"] = "PaymentReceived for Onetime Monthly,CrewBid"
            }
        } else if months == 6 {
            dicData["Message"] = "PaymentReceived for 6 months"
        }
        
        dicData["IpAddress"] = app.IPAddress ?? ""
        dicData["TransactionNumber"] = transactionID
        dicData["AppNum"] = 5
        
        let objEvent = CBOfflineEvents()
        objEvent.addOfflinePayment(dicData as! NSMutableDictionary)
    }
    
    func addOfflinePayment(_ objOfflineData: NSMutableDictionary) {
        guard let month = objOfflineData["Month"] as? Int, month != 0 else {
            return
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else { return }
        
        var path = (documentsDirectory as NSString).appendingPathComponent("OfflinePayment.plist")
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            path = (documentsDirectory as NSString).appendingPathComponent("OfflinePayment.plist")
        }
        
        // Save dictionary directly to file (similar to Obj-C)
        objOfflineData.write(toFile: path, atomically: true)
    }
    
    
    func OfflineLogging(productID: String, transactionID: String) {
        // Show alert
        let alert = UIAlertController(
            title: "Something went wrong",
            message: "Purchased date not updated to remote user account. Please contact us. We would love to help.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        
        if let currentTopVC = currentTopViewController() {
            currentTopVC.present(alert, animated: true)
        }
        
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        var offlineData: [String: Any] = [:]
        
        if let employeeNumber = app.ObjUserAccount?.employeeNumber {
            let cleanedEmpNum = employeeNumber
                .replacingOccurrences(of: "e", with: "")
                .trimmingCharacters(in: .symbols)
            offlineData["EmployeeNumber"] = Int(cleanedEmpNum) ?? 0
        }
        
        offlineData["Event"] = "PaymentReceived"
        offlineData["Base"] = "BWI"
        offlineData["Month"] = ""
        
        if let position = app.ObjUserAccount?.position {
            offlineData["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: position)!)
        }
        
        offlineData["Round"] = 0
        offlineData["Message"] = "In app purchase success But No network - Purchase Id- \(productID), transaction id- \(transactionID)"
        offlineData["VersionNumber"] = CBUtils.AppVersion()
        offlineData["PlatformNumber"] = "iPad"
        offlineData["OperatingSystemNum"] = "iPad OS"
        
        if let employeeNumber = app.ObjUserAccount?.employeeNumber {
            let cleanedEmpNum = employeeNumber
                .replacingOccurrences(of: "e", with: "")
                .trimmingCharacters(in: .symbols)
            offlineData["BidForEmpNum"] = Int(cleanedEmpNum) ?? 0
        }
        
        // Submit three bids
        offlineData["BuddyBid1"] = 0
        offlineData["BuddyBid2"] = 0
        offlineData["BuddyBid3"] = 0
        
        let now = Date()
        let startDate = now.timeIntervalSince1970 * 1000
        let dateStarted = "/Date(\(Int(startDate))+0800)/"
        offlineData["date"] = dateStarted
        
        if let ipAddress = app.IPAddress {
            offlineData["IpAddress"] = ipAddress
        }
        
        let objEvent = CBOfflineEvents()
        objEvent.addOfflineEvent(offlineData)
    }
    
    
    func currentTopViewController() -> UIViewController? {
        guard let rootVC = UIApplication.shared.delegate?.window??.rootViewController else {
            return nil
        }
        
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        
        return topVC
    }
    
    func setICloudTransactionState(
        _ state: String,
        transationIdentifier: String,
        transactionID: String,
        transactionDate: Date
    ) {
        // Get existing transactions
        var transactions = getTransactions()
        
        // Create new transaction dictionary
        var dict: [String: Any] = [:]
        dict["transactionIdentifier"] = transationIdentifier
        dict["transactionID"] = transactionID
        dict["transactionDate"] = transactionDate
        dict["transactionState"] = state
        dict["position"] = app!.ObjUserAccount?.position
        dict["userId"] = app!.ObjUserAccount?.employeeNumber
        
        // Add new transaction
        transactions.append(dict)
        
        // Save to iCloud key-value store
        let store = NSUbiquitousKeyValueStore.default
        store.set(transactions, forKey: "transaction")
        store.synchronize()
    }
    
    
    func setICloudEncryptedWbidExpirationDate(_ expiryDate: Date?) {
        guard let expiryDate = expiryDate else { return }
        let encryptedString = encryptedDateString(expiryDate)
        let store = NSUbiquitousKeyValueStore.default
        
        var userInfo = store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any] ?? [:]
        userInfo[kCBUserInfoEncryptedWbidExpirationDateKey] = encryptedString
        
        store.set(userInfo, forKey: kCBUserInfoDictionaryKey)
        store.synchronize()
    }
    
    func getMaxExpirationDate(forMonths months: Int) -> Date? {
        let originDate: Date
        if daysRemainingOnWBidSubscription() > 0 {
            originDate = getBestAvailableWbidExpirationDate()!
        } else {
            originDate = Date()
        }
        
        var dateComponents = DateComponents()
        dateComponents.month = months
        dateComponents.day = 1 // add an extra day to subscription because we love our users
        
        return Calendar.current.date(byAdding: dateComponents, to: originDate)
    }
    
    func setICloudEncryptedExpirationDate(_ expiryDate: Date?) {
        guard let expiryDate = expiryDate else { return }
        
        let encryptedString = encryptedDateString(expiryDate)
        let store = NSUbiquitousKeyValueStore.default
        var userInfo = store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any] ?? [:]
        
        userInfo[kCBUserInfoEncryptedExpirationDateKey] = encryptedString
        store.set(userInfo, forKey: kCBUserInfoDictionaryKey)
        store.synchronize()
    }
    
    func setLocalEncryptedExpirationDate(_ expiryDate: Date?) {
        guard let expiryDate = expiryDate else { return }
        
        // Decrypt existing local date (kept from Obj-C, though not used here)
        let _ = getLocalDecryptedExpirationDate()
        
        let encryptedString = encryptedDateString(expiryDate)
        
        // Save into UserDefaults
        let defaults = UserDefaults.standard
        var userInfo = defaults.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any] ?? [:]
        userInfo[kCBUserInfoEncryptedExpirationDateKey] = encryptedString
        defaults.set(userInfo, forKey: kCBUserInfoDictionaryKey)
        defaults.synchronize()
        
        // Save into Keychain
        let account = "CrewBidExpirationDate"
        let service = "com.yourapp.expiration" // you can namespace it to avoid conflicts
    
        let success = KeychainHelper.save(account: account, service: service, value: encryptedString)
        if !success {
            print("Failed to save encrypted expiration date in Keychain")
        }
    }
    
    func setLocalEncryptedWbidExpirationDate(_ expiryDate: Date?) {
        guard let expiryDate = expiryDate else { return }
        // Encrypt the date
        let encryptedString = encryptedDateString(expiryDate)
        
        // Update UserDefaults
        let store = UserDefaults.standard
        var userInfo = store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any] ?? [:]
        userInfo[kCBUserInfoEncryptedWbidExpirationDateKey] = encryptedString
        store.set(userInfo, forKey: kCBUserInfoDictionaryKey)
        store.synchronize()
        
        // Update Keychain
        let account = "CrewBidWbidExpirationDate"
        let service = "com.yourapp.wbidExpiration"
        
        let success = KeychainHelper.save(account: account, service: service,value: encryptedString)
        if !success {
            print("Failed to save WBID expiration date in Keychain")
        }
    }
    
    func getLocalDecryptedWbidExpirationDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = kCBExpirationDateFormat
        
        var expirationDate: Date?
        
        // Grab the userInfo expiration date from UserDefaults
        let store = UserDefaults.standard
        var userInfoExpirationDate: Date?
        
        if var userInfo = store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any],
           let encryptedString = userInfo[kCBUserInfoEncryptedWbidExpirationDateKey] as? String
        {
            if let decryptedString = FBEncryptorAES.decryptBase64String(encryptedString, keyString: kFreeMonthEncryptionKey) {
                userInfoExpirationDate = dateFormatter.date(from: decryptedString)
            }
        }
        
        // Grab the expiration date from Keychain
        let account = "CrewBidWbidExpirationDate"
        let service = "com.yourapp.wbidExpiration"
        var keychainExpirationDate: Date?
        var keychainEncryptedString: String?
        
        if let encryptedString = KeychainHelper.retrieve(account: account, service: service) {
            keychainEncryptedString = encryptedString
            if let decryptedString = FBEncryptorAES.decryptBase64String(encryptedString, keyString: kFreeMonthEncryptionKey) {
                keychainExpirationDate = dateFormatter.date(from: decryptedString)
            }
        }
        
        // Determine the latest expiration date
        if let keyDate = keychainExpirationDate, let userDate = userInfoExpirationDate {
            if keyDate > userDate {
                expirationDate = keyDate
                // Update userInfo with Keychain value
                if var userInfo = store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any] {
                    userInfo[kCBUserInfoEncryptedWbidExpirationDateKey] = keychainEncryptedString
                    store.set(userInfo, forKey: kCBUserInfoDictionaryKey)
                }
            } else {
                expirationDate = userDate
            }
        } else if let keyDate = keychainExpirationDate {
            expirationDate = keyDate
            // Update userInfo with Keychain value
            if var userInfo = store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any] {
                userInfo[kCBUserInfoEncryptedWbidExpirationDateKey] = keychainEncryptedString
                store.set(userInfo, forKey: kCBUserInfoDictionaryKey)
            }
        } else {
            expirationDate = userInfoExpirationDate
        }
        
        return expirationDate
    }
    
    
    func getICloudDecryptedWbidExpirationDate() -> Date? {
        let store = NSUbiquitousKeyValueStore.default
        guard
            let userInfo = store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any],
            let encryptedString = userInfo[kCBUserInfoEncryptedWbidExpirationDateKey] as? String
        else {
            return nil
        }
        
        // Decrypt the string
        let dateString = FBEncryptorAES.decryptBase64String(encryptedString, keyString: kFreeMonthEncryptionKey)
        
        // Parse the date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = kCBExpirationDateFormat
        return dateFormatter.date(from: dateString!)
    }
    
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("didReceive called")
        productsRequest = nil
        completionHandler?(true, response.products)
        completionHandler = nil
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("request failed:", error.localizedDescription)
        productsRequest = nil
        completionHandler?(false, nil)
        completionHandler = nil
    }
    
    func daysRemainingOnSubscription() -> Int {
        // 1. Get expiration date
        guard let expirationDate = getBestAvailableExpirationDate() else {
            return 0
        }
        
        // 2. Get current UTC date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let formattedDate = dateFormatter.string(from: Date())
        guard let utcCurrentDate = dateFormatter.date(from: formattedDate) else {
            return 0
        }
        
        // 3. Calculate difference in days
        let timeInterval = expirationDate.timeIntervalSince(utcCurrentDate)
        let days = timeInterval / 60.0 / 60.0 / 24.0
        let day = Int(ceil(days))
        
        // 4. Return with conditions
        if days <= 0 {
            if checkIsAutoRenewUser() {
                return daysRemainingForExpiryForAutoRenewUser(expirationDate: expirationDate)
            }
            return 0
        } else if days < 1 {
            return 1
        } else {
            return day
        }
    }
    
    func daysRemainingForExpiryForAutoRenewUser(expirationDate: Date) -> Int {
        // 1. Extend expiration date by 10 days
        var dateComponents = DateComponents()
        dateComponents.day = 10
        guard let extendedDate = Calendar.current.date(byAdding: dateComponents, to: expirationDate) else {
            return 0
        }
        
        // 2. Get current UTC time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let formattedDate = dateFormatter.string(from: Date())
        guard let utcExpirationDate = dateFormatter.date(from: formattedDate) else {
            return 0
        }
        
        // 3. Calculate difference in days
        let timeInterval = extendedDate.timeIntervalSince(utcExpirationDate)
        let days = ceil(timeInterval / 60.0 / 60.0 / 24.0)
        
        // 4. Return rounded days
        if days <= 0 {
            return 0
        } else if days < 1 {
            return 1
        } else {
            return Int(days)
        }
    }
    
    func checkIsAutoRenewUser() -> Bool {
        guard let app = UIApplication.shared.delegate as? AppDelegate else {
            return false
        }
        
        var isFree = false
        var enteredEmpNo = app.ObjUserAccount?.employeeNumber ?? ""
        
        // Defaults from ObjUserAccount
        var isMonthlySubscribed = app.ObjUserAccount?.isMonthlySubscribed
        var isYearlySubscribed = app.ObjUserAccount?.isYearlySubscribed
        var isCBMonthlySubscribed = app.ObjUserAccount?.isCBMonthlySubscribed
        var isCBYearlySubscribed = app.ObjUserAccount?.isCBYearlySubscribed
        
        var dicAutoRenewUser: [String: Any] = [:]
        
        if let loginUserId = app.ObjUserAccount?.LoginuserId, !loginUserId.isEmpty {
            enteredEmpNo = loginUserId
            
            if app.ObjUserAccount?.employeeNumber == enteredEmpNo {
                dicAutoRenewUser = (app.ObjUserAccount?.dicLoginAuthDetails ?? [:]) as! [String : Any]
            } else {
                dicAutoRenewUser = (app.ObjUserAccount?.dicLogInAuthExternalUser ?? [:]) as! [String : Any]
            }
            
            if let val = dicAutoRenewUser["IsFree"] as? Bool {
                isFree = val
            }
            if let val = dicAutoRenewUser["IsMonthlySubscribed"] as? Bool {
                isMonthlySubscribed = val
            }
            if let val = dicAutoRenewUser["IsYearlySubscribed"] as? Bool {
                isYearlySubscribed = val
            }
            if let val = dicAutoRenewUser["IsCBMonthlySubscribed"] as? Bool {
                isCBMonthlySubscribed = val
            }
            if let val = dicAutoRenewUser["IsCBYearlySubscribed"] as? Bool {
                isCBYearlySubscribed = val
            }
        }
        
        // If any subscription flag is true → treat as "auto renew user"
        if isMonthlySubscribed == true || isYearlySubscribed == true || isCBMonthlySubscribed == true || isCBYearlySubscribed == true {
            isFree = true
        }
        
        return isFree
    }
    
    func getBestAvailableCBExpirationDateFromiCloudAndKeyChain() -> Date? {
        // First check to see if the iCloud date is available, if not,
        // get the local date
        let iCloudExpirationDate = getICloudDecryptedExpirationDate()
        let localExpirationDate = getLocalDecryptedExpirationDate()
        // let parseDate = getParseExpirationDate()
        // let cwaMasterExpirationDate = getCWAMasterExpirationDate()
        
        var expirationDate: Date?
        
        if let iCloudDate = iCloudExpirationDate, let localDate = localExpirationDate {
            if iCloudDate == localDate {
                expirationDate = iCloudDate
            } else if iCloudDate > localDate {
                expirationDate = iCloudDate
                setLocalEncryptedExpirationDate(iCloudDate)
            } else {
                expirationDate = localDate
                setICloudEncryptedExpirationDate(localDate)
            }
        } else if let iCloudDate = iCloudExpirationDate {
            expirationDate = iCloudDate
            setLocalEncryptedExpirationDate(iCloudDate)
        } else if let localDate = localExpirationDate {
            expirationDate = localDate
            setICloudEncryptedExpirationDate(localDate)
        } else {
            expirationDate = getFreeTrialDecryptedExpirationDate()
        }
        
        return expirationDate
    }
    
    
    
    func getBestAvailableExpirationDate() -> Date? {
        guard let app = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }

        var bestAvailableSubscriptionDate: Date? = nil
        var enteredEmpNo = app.ObjUserAccount?.employeeNumber ?? ""
        var dicCWAMasterDetails: [String: Any] = [:]

        let isLocalUserAccAvailable = CBUtils.isLocalUserInformationAvailable()

        if let loginUserId = app.ObjUserAccount?.LoginuserId, !loginUserId.isEmpty {
            enteredEmpNo = loginUserId

            if app.ObjUserAccount?.employeeNumber == enteredEmpNo {
                dicCWAMasterDetails = (app.ObjUserAccount?.dicLoginAuthDetails ?? [:]) as! [String : Any]
            } else {
                dicCWAMasterDetails = (app.ObjUserAccount?.dicLogInAuthExternalUser ?? [:]) as! [String : Any]
            }
        }

        let subscriptionDateKeychain = getSubscriptionDate("keychain", user: enteredEmpNo, authorizationDetails: app.ObjUserAccount?.dicLoginAuthDetails as! [String : Any])
        let subscriptionDateICloud = getSubscriptionDate("icloud", user: enteredEmpNo, authorizationDetails: app.ObjUserAccount?.dicLoginAuthDetails as! [String : Any])
        let subscriptionDateCWAMaster = getSubscriptionDate("cwamaster", user: enteredEmpNo, authorizationDetails: app.ObjUserAccount?.dicLoginAuthDetails as! [String : Any])

        if isLocalUserAccAvailable {
            if app.ObjUserAccount?.employeeNumber == enteredEmpNo {
                // Local user matches entered employee number
                if let subscriptionDateCWAMaster = subscriptionDateCWAMaster {
                    print("Entered into save section")

                    // Extract CB and WB expiration dates
                    let cbDate = getDateFromJSON("\(dicCWAMasterDetails["CBExpirationDate"] ?? "")")
                    let wbDate = getDateFromJSON("\(dicCWAMasterDetails["WBExpirationDate"] ?? "")")

                    // Save to helpers
                    CBIAPHelper.shared.setICloudEncryptedExpirationDate(cbDate)
                    CBIAPHelper.shared.setLocalEncryptedExpirationDate(cbDate)

                    CBIAPHelper.shared.setICloudEncryptedWbidExpirationDate(wbDate!)
                    CBIAPHelper.shared.setLocalEncryptedWbidExpirationDate(wbDate!)

                    let cwaMaxDate = getDateFromJSON("\(dicCWAMasterDetails["ExpirationDate"] ?? "")")
                    let maxDate = bestDate(from: subscriptionDateCWAMaster, date2: cwaMaxDate)

                    bestAvailableSubscriptionDate = maxDate
                    return bestAvailableSubscriptionDate
                } else {
                    // CWAMaster value is nil → fallback
                    bestAvailableSubscriptionDate = bestDate(from: subscriptionDateKeychain, date2: subscriptionDateICloud)
                    return bestAvailableSubscriptionDate
                }
            } else {
                // External user → pull directly from external user dictionary
                dicCWAMasterDetails = (app.ObjUserAccount?.dicLogInAuthExternalUser ?? [:]) as! [String : Any]
                bestAvailableSubscriptionDate = getDateFromJSON("\(dicCWAMasterDetails["ExpirationDate"] ?? "")")
                return bestAvailableSubscriptionDate
            }
        }

        return bestAvailableSubscriptionDate
    }
    
    func getSubscriptionDate(_ whichDate: String,
                             user empNo: String,
                             authorizationDetails dicAuthUserDetails: [String: Any]) -> Date? {
        
        var subscriptionDate: Date?
        
        if whichDate == "keychain" {
            let cbDate = getLocalDecryptedExpirationDate()
            let wbDate = getLocalDecryptedWbidExpirationDate()
            subscriptionDate = bestDate(from: cbDate, date2: wbDate)
            
        } else if whichDate == "icloud" {
            if "\(app?.ObjUserAccount?.employeeNumber ?? "")" != empNo {
                if !empNo.isEmpty {
                    let cbDate = getDateFromJSON("\(dicCWAMasterDetails["CBExpirationDate"] ?? "")")
                    let wbDate = getDateFromJSON("\(dicCWAMasterDetails["WBExpirationDate"] ?? "")")
                    subscriptionDate = bestDate(from: cbDate, date2: wbDate)
                }
            } else {
                let cbDate = getICloudDecryptedExpirationDate()
                let wbDate = getICloudDecryptedWbidExpirationDate()
                subscriptionDate = bestDate(from: cbDate, date2: wbDate)
            }
            
        } else { // "cwamaster"
            if !empNo.isEmpty {
                let cbDate = getDateFromJSON("\(dicCWAMasterDetails["CBExpirationDate"] ?? "")")
                let wbDate = getDateFromJSON("\(dicCWAMasterDetails["WBExpirationDate"] ?? "")")
                subscriptionDate = bestDate(from: cbDate, date2: wbDate)
            }
        }
        
        return subscriptionDate
    }
    
    func getICloudDecryptedExpirationDate() -> Date? {
        let store = NSUbiquitousKeyValueStore.default
        guard let userInfo = store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any] else {
            return nil
        }
        
        let encryptedString = userInfo[kCBUserInfoEncryptedExpirationDateKey] as? String
        var dateString: String?
        
        if let encrypted = encryptedString {
            dateString = FBEncryptorAES.decryptBase64String(encrypted, keyString: kFreeMonthEncryptionKey)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = kCBExpirationDateFormat
        
        if let dateStr = dateString {
            return dateFormatter.date(from: dateStr)
        }
        
        return nil
    }
    
    
    func bestDate(from date1: Date?, date2: Date?) -> Date? {
        var expirationDate: Date?

        if let d1 = date1, let d2 = date2 {
            if d1.compare(d2) == .orderedSame {
                expirationDate = d1
            } else if d1.compare(d2) == .orderedDescending {
                expirationDate = d1
                // setLocalEncryptedExpirationDate(d1)
            } else {
                expirationDate = d2
                // setICloudEncryptedExpirationDate(d2)
            }
        } else if let d1 = date1 {
            expirationDate = d1
            // setLocalEncryptedExpirationDate(d1)
        } else if let d2 = date2 {
            expirationDate = d2
            // setICloudEncryptedExpirationDate(d2)
        } else {
            // expirationDate = getFreeTrialDecryptedExpirationDate()
        }

        return expirationDate
    }
    
    func getLocalDecryptedExpirationDate() -> Date? {
        var expirationDate: Date?
        var userInfoDateString: String?
        var keychainDateString: String?
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = kCBExpirationDateFormat
        
        var keychainExpirationDate: Date?
        var userInfoExpirationDate: Date?
        
        // Grab the userInfo expirationDate from UserDefaults
        let store = UserDefaults.standard
        if var userInfo = store.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any] {
            if let userInfoEncryptedString = userInfo[kCBUserInfoEncryptedExpirationDateKey] as? String {
                userInfoDateString = FBEncryptorAES.decryptBase64String(userInfoEncryptedString, keyString: kFreeMonthEncryptionKey)
                if let decryptedString = userInfoDateString {
                    userInfoExpirationDate = dateFormatter.date(from: decryptedString)
                }
            }
            
            // Grab the expiration date from the Keychain
            let account = "CrewBidExpirationDate"
            let service = "com.yourapp.expiration"
            
            if let keychainEncryptedString = KeychainHelper.retrieve(account: account, service: service) {
                keychainDateString = FBEncryptorAES.decryptBase64String(keychainEncryptedString, keyString: kFreeMonthEncryptionKey)
                if let decryptedString = keychainDateString {
                    keychainExpirationDate = dateFormatter.date(from: decryptedString)
                }
                
                // Compare Keychain & UserDefaults dates
                if let kcDate = keychainExpirationDate, let uiDate = userInfoExpirationDate {
                    if kcDate.compare(uiDate) == .orderedDescending {
                        expirationDate = kcDate
                        userInfo[kCBUserInfoEncryptedExpirationDateKey] = keychainEncryptedString
                        store.set(userInfo, forKey: kCBUserInfoDictionaryKey)
                    } else {
                        expirationDate = uiDate
                    }
                } else if let kcDate = keychainExpirationDate {
                    expirationDate = kcDate
                    userInfo[kCBUserInfoEncryptedExpirationDateKey] = keychainEncryptedString
                    store.set(userInfo, forKey: kCBUserInfoDictionaryKey)
                } else {
                    expirationDate = userInfoExpirationDate
                }
            } else {
                expirationDate = userInfoExpirationDate
            }
        }
        
        // expirationDate could be nil if both keychain & userInfo are nil
        return expirationDate
    }
    
    
    
    func daysRemainingOnWBidSubscription() -> Int {
        // 1. Get expiration date
        guard let expirationDate = getBestAvailableWbidExpirationDate() else {
            return 0
        }

        // 2. Get current UTC date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let formattedDate = dateFormatter.string(from: Date())
        guard let utcExpirationDate = dateFormatter.date(from: formattedDate) else {
            return 0
        }

        // 3. Calculate difference in days
        let timeInterval = expirationDate.timeIntervalSince(utcExpirationDate)
        let days = timeInterval / 60.0 / 60.0 / 24.0
        let day = Int(ceil(days))

        // 4. Apply rules
        if days <= 0 {
            return 0
        } else if days < 1 {
            return 1
        } else {
            return day
        }
    }
    
    func getBestAvailableWbidExpirationDate() -> Date? {
        guard let app = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }

        var enteredEmpNo = "\(app.ObjUserAccount?.employeeNumber ?? "")"
        var expirationDate: Date?

        if let loginUserId = app.ObjUserAccount?.LoginuserId, !loginUserId.isEmpty {
            enteredEmpNo = loginUserId
        }

        if "\(app.ObjUserAccount?.employeeNumber ?? "")" != enteredEmpNo {
            // External user check
            if let dicExternalUser = app.ObjUserAccount!.dicLogInAuthExternalUser as? [String: Any] {
                dicCWAMasterDetails = NSMutableDictionary(dictionary: dicExternalUser, copyItems: true) as! [AnyHashable : Any]
                if let wbExpiration = dicExternalUser["WBExpirationDate"] as? String {
                    return getDateFromJSON(wbExpiration)
                }
            }
        } else {
            let iCloudExpirationDate = getICloudDecryptedWbidExpirationDate()
            let localExpirationDate = getLocalDecryptedWbidExpirationDate()

            if let iCloudDate = iCloudExpirationDate, let localDate = localExpirationDate {
                if iCloudDate == localDate {
                    expirationDate = iCloudDate
                } else if iCloudDate.compare(localDate) == .orderedDescending {
                    expirationDate = iCloudDate
                    setLocalEncryptedWbidExpirationDate(iCloudDate)
                } else {
                    expirationDate = localDate
                    setICloudEncryptedWbidExpirationDate(localDate)
                }
            } else if let iCloudDate = iCloudExpirationDate {
                expirationDate = iCloudDate
                setLocalEncryptedWbidExpirationDate(iCloudDate)
            } else if let localDate = localExpirationDate {
                expirationDate = localDate
                setICloudEncryptedWbidExpirationDate(localDate)
            } else {
                // TODO: handle free trial fallback
                // expirationDate = getFreeTrialDecryptedExpirationDate()
            }
        }

        return expirationDate
    }
    
    func daysRemainingOnFreeTrial() -> Int {
        guard let expirationDate = getFreeTrialDecryptedExpirationDate() else {
            return 0
        }
        
        let timeInterval = expirationDate.timeIntervalSince(Date())
        let days = timeInterval / 60.0 / 60.0 / 24.0
        
        if days < 0 {
            return 0
        } else if days < 1 {
            return 1
        } else {
            return Int(round(days))
        }
    }
    
    func getFreeTrialDecryptedExpirationDate() -> Date? {
        // Retrieve the encrypted string from the Keychain
        guard let encryptedString = KeychainHelper.retrieve(account: "CrewBidFreeMonthToken", service: "CrewBidFreeMonthToken") else {
            return nil
        }
        
        // Decrypt the string
        guard let dateString = FBEncryptorAES.decryptBase64String(encryptedString, keyString: kFreeMonthEncryptionKey) else {
            return nil
        }
        
        // Convert to Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = kCBExpirationDateFormat
        return dateFormatter.date(from: dateString)
    }
    
    func getFreeTrialExpirationDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        
        guard let expirationDate = getFreeTrialDecryptedExpirationDate() else {
            return "Not Subscribed"
        }
        
        let daysRemaining = daysRemainingOnFreeTrial()
        
        if daysRemaining > 0 {
            return "Subscription Active!\nFree Trial Expires: \(dateFormatter.string(from: expirationDate)) (\(daysRemaining) Days)"
        } else {
            return "Subscription Expired!\nFree Trial Expired on: \(dateFormatter.string(from: expirationDate))"
        }
    }
    
    func latestPurchaseType() -> Int {
        var productType = 0
        guard let userInfo = CBUserInfo.bestAvailableUserInfoDictionary() else {
            return productType
        }
        
        if let productIDs = userInfo[kCBUserInfoPurchaseTypesKey] as? [String], !productIDs.isEmpty {
            if let lastProductID = productIDs.last {
                if lastProductID == "NewHirePromo" {
                    productType = 3
                }
            }
        }
        
        return productType
    }
    
    
    func getExpirationDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        
        guard let expiryDate = getBestAvailableExpirationDate() else {
            return "Not Subscribed"
        }
        
        let formattedDate = dateFormatter.string(from: expiryDate)
        print("ExpiryDateFormat---\(formattedDate)")
        
        guard let app = UIApplication.shared.delegate as? AppDelegate else {
            return "Not Subscribed"
        }
        
        // Check account subscription type
        if app.ObjUserAccount!.isFree {
            return "Account is Free"
        } else if app.ObjUserAccount!.isMonthlySubscribed {
            return "Monthly Auto Renew"
        } else if app.ObjUserAccount!.isYearlySubscribed {
            return "Yearly Auto Renew"
        }
        
        let daysRemaining = daysRemainingOnSubscription()
        
        if daysRemaining > 0 {
            return "Subscription Active!\nExpires: \(formattedDate) (\(daysRemaining) Days)"
        } else {
            return "Subscription Expired!\nExpired on: \(formattedDate)"
        }
    }
    
    func getDateFromJSON(_ string: String) -> Date? {
        // Regex for /Date(123456789+0800)/
        let pattern = #"^\\/date\\((-?\\d+)(?:([+-])(\\d{2})(\\d{2}))?\\)\\/$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let match = regex.firstMatch(in: string, options: [], range: range) else {
            return nil
        }
        
        // Milliseconds since epoch
        if let millisRange = Range(match.range(at: 1), in: string),
           let millis = Double(string[millisRange]) {
            
            var seconds = millis / 1000.0
            
            // Timezone offset
            if match.range(at: 2).location != NSNotFound,
               let signRange = Range(match.range(at: 2), in: string),
               let hoursRange = Range(match.range(at: 3), in: string),
               let minsRange = Range(match.range(at: 4), in: string) {
                
                let sign = string[signRange]
                let hours = Double("\(sign)\(string[hoursRange])") ?? 0
                let mins  = Double("\(sign)\(string[minsRange])") ?? 0
                
                seconds += (hours * 3600.0) + (mins * 60.0)
            }
            
            return Date(timeIntervalSince1970: seconds)
        }
        
        return nil
    }
    
    func encryptedDateString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = kCBExpirationDateFormat
        
        let dateString = dateFormatter.string(from: date)
        let encryptedString = FBEncryptorAES.encryptBase64String(
            dateString,
            keyString: kFreeMonthEncryptionKey,
            separateLines: false
        )
        return encryptedString!
    }
    
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
                case .purchased:
                    completeTransaction(transaction)
                case .failed:
                    failedTransaction(transaction)
                case .restored:
                    restoreTransaction(transaction)
                case .deferred:
                    deferredTransaction(transaction) // keep method name consistent
                case .purchasing:
                    purchasingTransaction(transaction) // keep method name consistent
                @unknown default:
                    break
            }
        }
    }
    
    func completeTransaction(_ transaction: SKPaymentTransaction) {
        print("completeTransaction...")
        
        offlineLoggingRareCase(productId: productId!, messageType: "PaymentReceived")
        
        validateReceipt(for: transaction)
        
        let dict = getSKPaymentStatusData(statusCase: 1)
        offlineNewSKPaymentStatusLog(with: dict)
        newSKPaymentStatusLog(dict)
        
    }
    
    func newSKPaymentStatusLog(_ dict: [String: Any]) {
        // Documents directory path
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let path = (documentsDirectory as NSString).appendingPathComponent("OfflineSKPaymentData.plist")

        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }

        // Prepare request body
        var arrEvents: [[String: Any]] = []
        arrEvents.append(dict)

        var dicMainData: [String: Any] = [:]
        dicMainData["InAppStates"] = arrEvents

        guard let url = URL(string: "\(app.Domain!)LogInAppStatus") else { return }
        var urlRequest = URLRequest(url: url)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicMainData, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                urlRequest.httpBody = jsonString.data(using: .utf8)
            }
        } catch {
            print("JSON serialization error: \(error)")
            return
        }

        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Send request
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, error == nil else {
                print("Request error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               let mimeType = response?.mimeType,
               httpResponse.statusCode == 200,
               mimeType.contains("application/json") {

                if let str = String(data: data, encoding: .utf8), let flag = Bool(str), flag {
                    do {
                        try FileManager.default.removeItem(atPath: path)
                    } catch {
                        print("File removal error: \(error)")
                    }
                }
            }
        }
        dataTask.resume()
    }
    
    func getSKPaymentStatusData(statusCase: Int) -> [String: Any] {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return [:] }
        
        var valEvents: [String: Any] = [:]
        
        let startDate = Date().timeIntervalSince1970 * 1000
        let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)
        
        if let empId = app.ObjUserAccount?.LoginuserId {
            valEvents["EmpNum"] = empId
        }
        
        valEvents["Dtg"] = dateStarted
        valEvents["SKPaymentTransactionState"] = statusCase
        valEvents["IpAddress"] = app.getIPAddress()
        
        return valEvents
    }
    
    func offlineNewSKPaymentStatusLog(with dict: [String: Any]) {
        let objEvent = CBOfflineEvents()
        objEvent.addOfflineNewSKPaymentStatusEvent(dict)
    }
    
    func offlineLoggingRareCase(productId: String, messageType: String) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        var offlineData: [String: Any] = [:]
        
        if let empNum = app.ObjUserAccount?.employeeNumber {
            let cleanedEmpNum = empNum
                .replacingOccurrences(of: "e", with: "")
                .trimmingCharacters(in: CharacterSet.symbols)
            if let intVal = Int(cleanedEmpNum) {
                offlineData["EmployeeNumber"] = intVal
            }
        }
        
        offlineData["Event"] = messageType
        offlineData["Base"] = ""
        offlineData["Month"] = ""
        
        if let position = app.ObjUserAccount?.position {
            offlineData["Position"] = CBUtils.shortName(for: BICrewPositionType(rawValue: position)!)
        }
        
        offlineData["Round"] = 0
        let type = "MaxSubscription"
        
        offlineData["Message"] = "Offline-In app purchase Type- \(type), Status- \(messageType), Date : \(Date())"
        offlineData["VersionNumber"] = CBUtils.AppVersion()
        offlineData["PlatformNumber"] = "iPad"
        offlineData["OperatingSystemNum"] = "iPad OS"
        
        if let empNum = app.ObjUserAccount?.employeeNumber {
            let cleanedEmpNum = empNum
                .replacingOccurrences(of: "e", with: "")
                .trimmingCharacters(in: CharacterSet.symbols)
            if let intVal = Int(cleanedEmpNum) {
                offlineData["BidForEmpNum"] = intVal
            }
        }
        
        // Submit three bids
        offlineData["BuddyBid1"] = 0
        offlineData["BuddyBid2"] = 0
        offlineData["BuddyBid3"] = 0
        
        let now = Date()
        let startDate = now.timeIntervalSince1970 * 1000
        let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)
        offlineData["date"] = dateStarted
        
        if let ip = app.IPAddress {
            offlineData["IpAddress"] = ip
        }
        
        let objEvent = CBOfflineEvents()
        objEvent.addOfflineEvent(offlineData)
    }
    
    
    func failedTransaction(_ transaction: SKPaymentTransaction) {
        // 1. Log payment status
        let dict = getSKPaymentStatusDataWithStatusCase(2)
        offlineNewSKPaymentStatusLog(with: dict as! [String : Any])
        newSKPaymentStatusLog(dict as! [String : Any])
        print("failedTransaction...")
        
        // 2. Handle only non-cancelled errors
        if let error = transaction.error, (error as NSError).code != SKError.paymentCancelled.rawValue {
            
            // Check pending transactions
            let transactions = getTransactions()
            var wasPending = "0"
            if !transactions.isEmpty {
                for dic in transactions {
                    if let transactionID = dic["transactionID"] as? String,
                       transaction.transactionIdentifier == transactionID {
                        wasPending = "1"
                        break
                    }
                }
            }
            
            // Log offline rare case
            offlineLoggingRareCase(productId: productId!, messageType: "inAppPmntFail")
            
            // Prepare alert message
            let alertMessage: String
            if wasPending == "1" {
                alertMessage = "\(error.localizedDescription)\n\nWe were notified that your Subscription attempt on 2 Dec was put in PENDING status by Apple. They have subsequently failed the PENDING transaction. You can contact Apple, or you can attempt another subscription."
            } else {
                alertMessage = "\(error.localizedDescription)\n\nIf the issue persists, first try logging in and out of iTunes in your iPad Settings. If that doesn't work, then try a hard reset by holding down the iPad's Home button and side button on the top right."
            }
            
            // Show alert
            let alert = UIAlertController(title: "iTunes Store Error",
                                          message: alertMessage,
                                          preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(okAction)
            
            if let currentTopVC = currentTopViewController() {
                DispatchQueue.main.async {
                    currentTopVC.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        // 3. Finish transaction
        SKPaymentQueue.default().finishTransaction(transaction)
        purchaseInProgress = false
    }
    
    func getSKPaymentStatusDataWithStatusCase(_ statusCase: Int) -> NSMutableDictionary {
        let app = UIApplication.shared.delegate as! AppDelegate
        let valEvents = NSMutableDictionary()

        // Current timestamp in milliseconds
        let startDate = Date().timeIntervalSince1970 * 1000
        let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)

        // Populate dictionary
        if let empNum = app.ObjUserAccount?.LoginuserId {
            valEvents.setObject(empNum, forKey: "EmpNum" as NSString)
        }
        valEvents.setObject(dateStarted, forKey: "Dtg" as NSString)
        valEvents.setObject(statusCase, forKey: "SKPaymentTransactionState" as NSString)
        if let ip = app.getIPAddress() {
            valEvents.setObject(ip, forKey: "IpAddress" as NSString)
        }

        return valEvents
    }
    
    
    func restoreTransaction(_ transaction: SKPaymentTransaction) {
        print("restoreTransaction...")
        
        // Used for first time, changed by Gregory
        // OfflineLoggingRareCase(productId, messageType: "PaymentRestore")
        offlineLoggingRareCase(productId: productId!, messageType: "InAppRestore")
        
        validateReceipt(for: transaction)
        
        let dict = getSKPaymentStatusDataWithStatusCase(3)
        offlineNewSKPaymentStatusLog(with: dict as! [String : Any])
        newSKPaymentStatusLog(dict as! [String : Any])
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    func deferredTransaction(_ transaction: SKPaymentTransaction) {
        offlineLoggingRareCase(productId: productId!, messageType: "InAppPending")
        
        validateReceipt(for: transaction)
        
        let dict = getSKPaymentStatusDataWithStatusCase(4)
        offlineNewSKPaymentStatusLog(with: dict as! [String : Any])
        newSKPaymentStatusLog(dict as! [String : Any])
    }
    func purchasingTransaction(_ transaction: SKPaymentTransaction) {
        print("Purchasing ongoing")
        
        let dict = getSKPaymentStatusDataWithStatusCase(5)
        offlineNewSKPaymentStatusLog(with: dict as! [String : Any])
        newSKPaymentStatusLog(dict as! [String : Any])
    }
 }*/
