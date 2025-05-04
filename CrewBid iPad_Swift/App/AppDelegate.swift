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

var sendmail: String?
var dicCurrentBidDetails: [String: Any]?
var webData: Data?
var Domain: String?
var isNetWorkAvailable: Bool = false
var ipAddress: String?
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
var locationManager: CLLocationManager?



@main
class AppDelegate: UIResponder, UIApplicationDelegate,SimplePingDelegate {

    var pinger:SimplePing?

    

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
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        Crashlytics.crashlytics().checkForUnsentReports { hasUnsentReports in
            let hasConsent = true
            if hasUnsentReports && hasConsent {
                Crashlytics.crashlytics().sendUnsentReports()
            }else{
                Crashlytics.crashlytics().deleteUnsentReports()
            }
        }
        locationManager = CLLocationManager()
        locationManager?.startUpdatingHeading()
        
        self.simplePingStarter()
        
        
        dicCurrentBidDetails?["bidEmployeeNum"] = ""
//        NotificationCenter.default.addObserver(self, selector: #selector(handleAppEnteringForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        
        return true
    }
    
    @objc func handleAppEnteringForeground(){
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
                print("There is NO internet")
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
        //MARK: Add pinger
    }
    
    func sendPing(){
        assert(self.pinger != nil)
        self.pinger?.sendPing(data: nil)
    }
    
    
    //Simple ping delegate functions
    func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        
    }
    
    func simplePing(_ pinger: SimplePing, didFailWithError error: any Error) {
        
    }
    
    func simplePing(_ pinger: SimplePing, didSendPacket packet: Data) {
        
    }
    
    func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, error: any Error) {
        
    }
    
    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data) {
        
    }
    
    func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        
    }
    func simplePingDidTimeoutWaitingForResponsePacket(_ pinger: SimplePing) {
        
    }
    //-------------------
    
    
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

