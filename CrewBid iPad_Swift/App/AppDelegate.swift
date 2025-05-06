//
//  AppDelegate.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/03/25.
//

import UIKit
import CoreData
import UserNotifications
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import Firebase
import IQKeyboardManagerSwift
private let TestFlightAppToken = "acc37fb4-d850-42d1-b030-bc968f5ac8a7"
private let kCBFreeMonthToken = "CrewBidFreeMonthToken"
private let kFreeMonthEncryptionKey = "acc37fb4-d850"
private let faqsObjectID = "G41RDHdiL9"
private let latestNewsObjectID = "NR58hbGSk3"


var dicCurrentBidDetails: [String: Any]?
var webData: Data?
var Domain: String?
var isNetWorkAvailable: Bool = false
var IPAddress: String?
var isMockData: Bool = false
var onLaunch: Bool = false
var isSenioritySecretOn: Bool = false
var isHistoricBid: Bool = false
var swaptimizerClicked: Bool = false
var isAvailableSouthWestNetwork: Bool = false
var objCBDocument: CBDocumentsCollectionViewController?
var dicSSIDDetails: [String: Any]?
var mockDataMonth: Int?
var mockDataYear: Int?
var createEmpNo: String?
var objReachability: Reachability?
var isNeedToDownloadSeniorityFromServer: Bool = false
var isFlightNetwork: Bool = false
var isPingSuccess: Bool = false

enum NetworkType: Int {
    case ground = 0
    case free
    case paid
}


@main
class AppDelegate: UIResponder, UIApplicationDelegate,SimplePingDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {


    var pinger:SimplePing?
    var sendTimer: Timer?
    var locationManager = CLLocationManager()
    var objNetworkType: NetworkType = .ground

    func checkUpdate(){
        if self.connectedToInternet(){
            self.checkForUpdate(false)
        }
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.checkUpdate()
        }
        let center = UNUserNotificationCenter.current()
        let array = ["BidNotificationKey"]
        center.removePendingNotificationRequests(withIdentifiers: array)
        isMockData = false
        isHistoricBid = false
        let dom = UserDefaults.standard.string(forKey: "Domain")
        if dom?.isEmpty ?? true {
            Domain = "http://www.wbidmax.com:8000/WBidDataDwonloadAuthService.svc/"
        }
        else{ Domain = dom}
        var isSouthWestWifi = UserDefaults.standard.string(forKey: "isSouthWestWifi")
        if isSouthWestWifi?.isEmpty ?? true {
            isSouthWestWifi = "NO"
            UserDefaults.standard.set("NO", forKey: "isSouthWestWifi")
        }
        var isQATest = UserDefaults.standard.string(forKey: "isQATest")
        if isQATest?.isEmpty ?? true{
            isQATest = "NO"
            UserDefaults.standard.set("NO", forKey: "isQATest")
            UserDefaults.standard.set("0", forKey: "QATestMonth")
            UserDefaults.standard.set("0", forKey: "QATestYear")
        }
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        onLaunch = true
        IQKeyboardManager.shared.isEnabled = true
//        FirebaseApp.configure()
//        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
//        Crashlytics.crashlytics().checkForUnsentReports { hasUnsentReports in
//            let hasConsent = true
//            if hasUnsentReports && hasConsent {
//                Crashlytics.crashlytics().sendUnsentReports()
//            }else{
//                Crashlytics.crashlytics().deleteUnsentReports()
//            }
//        }
        self.locationAccess()
        dicCurrentBidDetails?["bidEmployeeNum"] = ""
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppEnteringForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = UIColor.lightGray
        //MARK: need code
        objNetworkType = .ground
        self.notificationChecking()
        self.testInternetConnection()
        self.simplePingStarter()
        //MARK: need code
        // for transactions
        if UserDefaults.standard.object(forKey: "FirstRun") == nil{
            let keychainItem = KeychainItemWrapper(identifier: "SaveLoginDetails", accessGroup: nil)
            keychainItem?.resetKeychainItem()
            UserDefaults.standard.set("1strun", forKey: "FirstRun")
            UserDefaults.standard.synchronize()
        }
        IPAddress = self.getIPAddress()
        print("IP Address: \(String(describing: IPAddress))")
        self.iCloudAccessCheck()
//        NotificationCenter.default.addObserver(self, selector: #selector(ubiquitousKeyValueStoreDidChange), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
//        NotificationCenter.default.addObserver(self, selector: #selector(iCloudAccountAvailabilityChanged), name: .NSUbiquityIdentityDidChange, object: nil)
//        NSUbiquitousKeyValueStore.default.synchronize()
        
        //needs code relsted to subscription reset
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        if (UserDefaults.standard.object(forKey: kCBIncludeDroppedTripsInProcessingKey) == nil){
            UserDefaults.standard.set(true, forKey: kCBIncludeDroppedTripsInProcessingKey)
        }
        if (UserDefaults.standard.object(forKey: kCBHideVacationKey) == nil){
            UserDefaults.standard.set(false, forKey: kCBHideVacationKey)
        }
        self.showDeviceUptimeAlert()
        
        return true
    }
    func showDeviceUptimeAlert(){
        let uptime = ProcessInfo.processInfo.systemUptime
        let uptimeDate = Date(timeIntervalSinceNow: -uptime)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day,.hour,.minute], from: uptimeDate, to: Date())
        print(components.day!, components.hour!, components.minute!)
        if components.day! > 7{
            let uptimeMessage = "Your device has been running for \(components.day!) days, \(components.hour!) hours, \(components.minute!) minutes. You should Restart your iPad."
            let alert = AlertService.showAlert(title: "Device Uptime", message: uptimeMessage, actions: nil)
            DispatchQueue.main.async {
                let topVC = self.getTopViewController()
                topVC?.present(alert, animated: true)
            }
        }
    }
    
    @objc func iCloudAccountAvailabilityChanged(){
    }
    
    @objc func ubiquitousKeyValueStoreDidChange(_ notification:Notification){
        let userInfo1 = notification.userInfo!
        guard let reasonForChange = userInfo1[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber else {
            print("No reason for change provided.")
            return
        }
        var reason = -1
        reason = reasonForChange.intValue
        if reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange{
            let changedKeys = userInfo1[NSUbiquitousKeyValueStoreChangeReasonKey] as! NSArray
            let ubiquitousKeyValueStore = NSUbiquitousKeyValueStore.default
            let userInfo = ubiquitousKeyValueStore.object(forKey: kCBUserInfoDictionaryKey) as? [String: Any]
            let encryptedString = userInfo![kCBUserInfoEncryptedExpirationDateKey] as! String
            var dateString = ""
            if !encryptedString.isEmpty{
                dateString = FBEncryptorAES.decryptBase64String(encryptedString, keyString: kFreeMonthEncryptionKey)
            }
            let dateFormateer = DateFormatter()
            dateFormateer.dateFormat = kCBExpirationDateFormat
            let iCloudDate = dateFormateer.date(from: dateString)
            
            //MARK: needs code
            //related to IAP
            
            
            
        }
        
    }

    
    func iCloudAccessCheck(){
        if let topVC = self.getTopViewController(){
        let firstLaunchWithiCloudAvailable = UserDefaults.standard.bool(forKey: "firstLaunchWithiCloudAvailable")
        let currentiCloudToken = FileManager.default.ubiquityIdentityToken
        if currentiCloudToken == nil && firstLaunchWithiCloudAvailable{
            let alert = AlertService.showAlert(title: "No iCloud Access!", message: "CrewBid requires iCloud access to sync your subscriptions across devices. To enable go to Settings > iCloud", actions: nil)
                topVC.present(alert, animated: true)
            }
            UserDefaults.standard.set(true, forKey: "firstLaunchWithiCloudAvailable")
        }
    }
    func getTopViewController() -> UIViewController? {
        guard let rootVC = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        return topVC
    }
    
    func locationAccess() {
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedWhenInUse {
            self.simplePingStarter()
        }else{
            locationManager.requestWhenInUseAuthorization()
        }
    }
    func getTransactions() -> [String]?{
        let store = NSUbiquitousKeyValueStore.default
        var transactionIdentifiers = store.object(forKey: "transaction") as? [String]
        if transactionIdentifiers == nil{
            transactionIdentifiers = []
        }
        return transactionIdentifiers
    }
    
    @objc func handleAppEnteringForeground(){
        
    }
  
    func testInternetConnection(){
        do{
            let reachability = try Reachability()
            if (reachability.isReachable){
                DispatchQueue.main.async {
                    print("There is Internet")
                    let app = UIApplication.shared.delegate as! AppDelegate
                    app.perform(#selector(self.handleAppEnteringForeground), with: nil, afterDelay: 8.0)
                    app.simplePingStarter()
                }
            }else{
                print("There is no Internet")
                let app = UIApplication.shared.delegate as! AppDelegate
                app.simplePingStarter()
            }
            try reachability.startNotifier()
        }catch{
            print("Failed to create Reachability object: \(error) ")
        }
    }
    func notificationChecking(){
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if error == nil{
                DispatchQueue.main.async{
                    UIApplication.shared.registerForRemoteNotifications()
                }
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    if !requests.isEmpty{
                        print("-----PendingNotificationRequests ",Int(requests.count))
                        if self.isUserInformationAvailable(){
                            if requests.count == 0{
                                //MARK: need code
                            }
                        }
                    }
                }
            }
        }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus != UNAuthorizationStatus.authorized{
                print("Notification not allowed")
            }else{
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    print("-----PendingNotificationRequests ",Int(requests.count))
    
                }
            }
        }
    }
    func isUserInformationAvailable() -> Bool{
        var isAvailable = false
        //MARK: need code
        return isAvailable
    }
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    func connectedToInternet() -> Bool {
        do {
            let reachability = try Reachability()
            let connection = reachability.connection
            switch connection{
            case .unavailable:
                print("There is no internet")
                return false
            case .wifi:
                print("Reachable via WiFi")
                return true
            case .cellular:
                print("Reachable via Cellular")
                return true
            default:
                print("Unknown connection")
                return false
            }
        } catch {
            print("Failed to create Reachability: \(error)")
            return false
        }
    }
    
    func checkForUpdate(_ isPingSuccess:Bool){
        if !isPingSuccess{
            self.simplePingStarter()
        }
    }
    
    func simplePingStarter(){
        dicSSIDDetails = fetchSSIDInfo()
        print("SSID Details: \(String(describing: dicSSIDDetails))")
        UserDefaults.standard.set(dicSSIDDetails?["SSID"], forKey: "SSID")
        self.runWithHostName("itunes.apple.com")
    }
    
    func runWithHostName(_ hostName: String){
        self.pinger?.timeout = 0.05
        self.pinger = SimplePing.simplePingWithHostName(hostName)
        assert(self.pinger != nil)
        self.pinger?.delegate = self
        self.pinger?.start()
    }
    
    func sendPing(){
        assert(self.pinger != nil)
        self.pinger?.sendPing(data: nil)
    }
    
    
    func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        if pinger == self.pinger{
            self.sendPing()
        }
        
    }
    
    func simplePing(_ pinger: SimplePing, didFailWithError error: NSError) {
        if pinger == self.pinger{
            print("Failed: \(String(describing: self.shortErrorfromError(error)))")
            self.sendTimer?.invalidate()
            self.sendTimer = nil
            self.simplePingStatus(false)
            self.pinger = nil
        }
    }
    
    
    func simplePing(_ pinger: SimplePing, didSendPacket packet: Data) {
        assert(pinger == self.pinger)
        if let icmpHeader = packet.withUnsafeBytes({ $0.bindMemory(to: ICMPHeader.self).baseAddress }) {
            let sequenceNumber = UInt16(bigEndian: icmpHeader.pointee.sequenceNumber)
            print("\(sequenceNumber) sent")
        }
    }
    
    func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, error: NSError) {
            assert(pinger == self.pinger)
            let sequenceNumber: UInt16 = packet.withUnsafeBytes {
                $0.bindMemory(to: ICMPHeader.self).baseAddress.map {
                    UInt16(bigEndian: $0.pointee.sequenceNumber)
                } ?? 0
            }
            let errorDescription = shortErrorfromError(error)
            NSLog("#\(sequenceNumber) send failed: \(String(describing: errorDescription))")
            self.simplePingStatus(false)
    }
    
    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data) {
            if let icmp = SimplePing.icmpInPacket(packet) {
                let sequenceNumber = UInt16(bigEndian: icmp.sequenceNumber)
                print("#\(sequenceNumber) received")
                self.simplePingStatus(true)
                self.checkForUpdate(true)
                self.pinger?.stop()
                self.sendTimer?.invalidate()
            }
    }
    
    func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        if let icmpPtr = SimplePing.icmpInPacket(packet) {
                let sequenceNumber = UInt16(bigEndian: icmpPtr.sequenceNumber)
                let type = icmpPtr.type
                let code = icmpPtr.code
                let identifier = UInt16(bigEndian: icmpPtr.identifier)
                print("#\(sequenceNumber) unexpected ICMP type=\(type), code=\(code), identifier=\(identifier)")
            } else {
                print("unexpected packet size=\(packet.count)")
            }
            self.simplePingStatus(false)
    }
    func simplePingDidTimeoutWaitingForResponsePacket(_ pinger: SimplePing) {
        print("TimeOut")
        self.simplePingStatus(false)
    }
    func simplePingStatus(_ isSuccess:Bool){
        isPingSuccess = isSuccess
        do{
            print("WiFi Status: ", isSuccess)
            let SSID = dicSSIDDetails?["SSID"] as! String
            if SSID.lowercased() == "southwestwifi" || SSID.lowercased() == "2wire"{
                isFlightNetwork = true
                if isSuccess{
                    objNetworkType = .paid
                    isNetWorkAvailable = true
                    isAvailableSouthWestNetwork = true
                }else{
                    objNetworkType = .free
                    isNetWorkAvailable = false
                }
            }else{
                isFlightNetwork = false
                objNetworkType = .ground
                if isSuccess{
                    isNetWorkAvailable = true
                    isAvailableSouthWestNetwork = false
                }else{
                    isNetWorkAvailable = false
                }
                if onLaunch{
                    onLaunch = false
                }
            }
            let isSouthWestWifi = UserDefaults.standard.string(forKey: "isSouthWestWifi")
            if isSouthWestWifi == "YES"{
                objNetworkType = .free
            }
            //MARK: needs code
        }catch{
            
        }
    }
    
    func fetchSSIDInfo() -> [String: Any]? {
        guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }
        print("Supported interfaces: \(interfaceNames)")
        for interfaceName in interfaceNames {
            if let ssidInfo = CNCopyCurrentNetworkInfo(interfaceName as CFString) as? [String: Any],
               !ssidInfo.isEmpty {
                print("\(interfaceName) => \(ssidInfo)")
                return ssidInfo
            }
        }
        return nil
    }
    func shortErrorfromError(_ error:NSError) ->String?{
        var result:String?
        if error.domain == kCFErrorDomainCFNetwork as String, error.code == CFNetworkErrors.cfHostErrorUnknown.rawValue{
            if let failureNum = error.userInfo[kCFGetAddrInfoFailureKey as String] as? NSNumber{
                let failure = failureNum.intValue
                if failure != 0, let failureStr = gai_strerror(Int32(failure)){
                    result = String(cString: failureStr)
                }
            }
            
        }
        return result
    }
    
    func getIPAddress() -> String {
        var address = "error"
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name: String = String(cString: (interface?.ifa_name)!)
                    if name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CrewBid_iPad_Swift")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

