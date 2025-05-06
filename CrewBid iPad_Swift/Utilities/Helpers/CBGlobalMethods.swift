//
//  CBGlobalMethods.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import Foundation
import UIKit
import CloudKit

public final class CBGlobalMethods: NSObject {
    var activityView: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    // Can't init is singleton
    private override init() { }
    
    // MARK: Shared Instance
    @objc static let shared = CBGlobalMethods()
    
    // MARK: Local Variable
    var stringvalue : String = "DATA"
    var emptyStringArray : [String] = []
    var SelectedYear: NSNumber?
    var SelectedMonth: NSNumber?
    var SelectedRound: NSNumber?
    var SelectedBase: String?
    var SelectedPosition: String?
    var employeeNumber: String?
    var swaptimizerId: String?
    var userid: String?
    var password: String?
    var secretKey: String?
    var isBulkDownload: Bool = false
    var activityIndicatorView = UIActivityIndicatorView()
    var isNewsFirstTimeDisply: Bool = false
    
    var selectedBidPeriod: BIBidPeriod?
    var openedBidDocumentControllerClass: CBBidActionsVC!
    var isSortAvailable = false
    var awardLertSecretEmpNum: String?
    var accessKey = "!evG7*5^7E"
    var buddyArray = [BIBidReceipt]()
    var frameWidth:CGFloat = 0
    var bidCalendarViewFrameWidth:CGFloat = 0
    var falistDict = [String:Any]()
    var domicileIsDifferent = false
    var certified = false
    var certifiedFirstName = ""
    var certifiedLastName = ""
    var bid4empnum = ""
    var bidder = ""
    var isMoveAllAction = false
    var isDeviceUptimeAlertDisplayed = false

    // Save the WBID expiration date to the Keychain

//    func SaveWbidExpirationdate(date: String) {
//        let expiryDate =  self.getDateFromJSON(string: String(date.prefix(19)))
//        let formattedDate = String(format: "%@", expiryDate! as CVarArg)
//        if formattedDate.count == 0 {
//            return
//        }
//        if expiryDate == nil {
//            return
//        }
//        self.saveExpairyToKeychain(date: expiryDate!)
//    }
    
    // Parse a date from a JSON-formatted string

    func getDateFromJSON(string: String, frmat : String = "yyyy-MM-dd'T'HH:mm:ss") -> Date? {
        let format = frmat
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(identifier: "US/Central")!
        let date = dateFormatter.date(from: string)
        return date
    }
    
    // Save the expiration date to iCloud Key-Value Store

//    func saveExpiryToiCloud(date: Date) {
//        guard FileManager.default.ubiquityIdentityToken != nil else {
//            // is not available
//            return
//        }
//        let keyValueStore = NSUbiquitousKeyValueStore.default
//        keyValueStore.set(encryptedDateString(date: date), forKey: "CrewBidWbidExpirationDate")
//        keyValueStore.synchronize()
//    }
    // Retrieve the expiration date from iCloud Key-Value Store

//    func getExpiryDateFromiCloud() -> Date? {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = kCBExpirationDateFormat
//
//        guard FileManager.default.ubiquityIdentityToken != nil else {
//            return nil
//        }
//        
//        let keyValueStore = NSUbiquitousKeyValueStore.default
//        keyValueStore.synchronize()
//        
//        if let encValue = keyValueStore.string(forKey: "CrewBidWbidExpirationDate") {
//            // Successfully retrieved account value
//            let keychainDateString = FBEncryptorAES.decryptBase64String(encValue, keyString: kFreeMonthEncryptionKey) ?? ""
//            
//            if let keychainExpirationDate = dateFormatter.date(from: keychainDateString) {
//                return keychainExpirationDate
//            }
//        } else {
//            //  value not found
//            print("i_Cloud value not found")
//        }
//        return nil
//    }
    
    // Return the model identifier of the device

    final func modelIdentifier() -> String {
         if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
         var sysinfo = utsname()
         uname(&sysinfo) // ignore return value
         return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
     }
    
    // Returns the short abbreviation for a crew position type

    class func shortNameOf(type: BICrewPositionType) -> String {
        var shortName = ""
        switch type {
        case .Captain:
            shortName = "CP"
            break
            
        case .FirstOfficer:
            shortName = "FO"
            break
            
        case .FlightAttendant:
            shortName = "FA"
            break
        }
        return shortName
    }
    
    // Returns the long name for a crew position type

    class func longNameOf(type: BICrewPositionType) -> String {
        var shortName = ""
        switch type {
        case .Captain:
            shortName = "Captain"
            break
            
        case .FirstOfficer:
            shortName = "First Officer"
            break
            
        case .FlightAttendant:
            shortName = "Flight Attendant"
            break
        }
        return shortName
    }
    
    // Returns the short abbreviation for a month based on its integer representation

    class func shortMonthNameOf(monthInt: Int) -> String {
        var month = ""
        switch monthInt {
        case 1:
            month = "Jan"
            break
            
        case 2:
            month = "Feb"
            break
            
        case 3:
            month = "Mar"
            break
            
        case 4:
            month = "Apr"
            break
            
        case 5:
            month = "May"
            break
            
        case 6:
            month = "Jun"
            break
            
        case 7:
            month = "Jul"
            break
            
        case 8:
            month = "Aug"
            break
            
        case 9:
            month = "Sep"
            break
            
        case 10:
            month = "Oct"
            break
            
        case 11:
            month = "Nov"
            break
            
        case 12:
            month = "Dec"
            break
            
        default:
            break
        }
        return month
    }
    
    // Returns the full name for a month based on its integer representation

    class func fullMonthNameOf(monthInt: Int) -> String {
        var month = ""
        switch monthInt {
            case 1:
                month = "January"
                break
                
            case 2:
                month = "February"
                break
                
            case 3:
                month = "March"
                break
                
            case 4:
                month = "April"
                break
                
            case 5:
                month = "May"
                break
                
            case 6:
                month = "June"
                break
                
            case 7:
                month = "July"
                break
                
            case 8:
                month = "August"
                break
                
            case 9:
                month = "September"
                break
                
            case 10:
                month = "October"
                break
                
            case 11:
                month = "November"
                break
                
            case 12:
                month = "December"
                break
                
            default:
                break
        }
        return month
    }
    // Retrieves the IP address of the "en0" network interface

    
    class func getIPAddress() -> String {
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
    
    
    /// Show alert
    // Displays a simple alert with an OK button.

    @objc func ShowAlert(TitleString : String, MessageString : String, buttonTitle: String = "OK") {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            let alert = UIAlertController(title: TitleString, message: MessageString, preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default) {
                UIAlertAction in
                NSLog("OK Pressed")
            }
            alert.addAction(okAction)
            UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
        })
    }
    
    // Displays an alert with an OK button and a custom action.
//    @objc func ShowAlertWithOnlyOKAction(TitleString : String, MessageString : String, buttonTitle: String = "OK", OKAction: ((UIAlertAction) -> Void)?) {
//        let alert = UIAlertController(title: TitleString, message: MessageString, preferredStyle: UIAlertController.Style.alert)
//        let okAction = UIAlertAction(title: buttonTitle, style: .default, handler: OKAction)
//        alert.addAction(okAction)
//        DispatchQueue.main.async {
//            UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
//        }
//    }
    
    //  Displays an alert with OK and Cancel buttons.

//    @objc func ShowAlertWithOKAction(TitleString : String, MessageString : String, buttonTitle: String = "OK", cancelTitle: String = "Cancel", isCancelButtonFirst: Bool = true, OKAction: ((UIAlertAction) -> Void)?) {
//        let alert = UIAlertController(title: TitleString, message: MessageString, preferredStyle: UIAlertController.Style.alert)
//        let okAction = UIAlertAction(title: buttonTitle, style: .default, handler: OKAction)
//        let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertAction.Style.cancel) {
//            UIAlertAction in
//            NSLog("OK Pressed")
//        }
//        if isCancelButtonFirst {
//            alert.addAction(cancelAction)
//            alert.addAction(okAction)
//        } else {
//            alert.addAction(okAction)
//            alert.addAction(cancelAction)
//        }
//        DispatchQueue.main.async {
//            UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
//        }
//    }
    
    //  Displays an alert with an OK button and a custom action.
    
//    @objc func ShowAlertWithOKAndCancelAction(TitleString : String, MessageString : String, OKAction: ((UIAlertAction) -> Void)?) {
//        let alert = UIAlertController(title: TitleString, message: MessageString, preferredStyle: UIAlertController.Style.alert)
//        let okAction = UIAlertAction(title: "OK", style: .default, handler: OKAction)
//        alert.addAction(okAction)
//        DispatchQueue.main.async {
//            UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
//        }
//    }
    
    //    Sets up and schedules a push notification.

    func setPushNotifications(title:String,body:String,userInfo:[String:Any]){
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        let fireDate = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: Date().addingTimeInterval(5))
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate, repeats: false)
        let request = UNNotificationRequest(identifier: "reminder", content: content, trigger: trigger)
        center.add(request) { (error) in
            if error != nil {
                print("Error = \(error?.localizedDescription ?? "error local notification")")
            }
        }
    }
    //  Displays an alert with customizable actions and handlers.

//    
//    func showAlertWithAction(title: String?, message: String?, actionTitles:[String?], actions:[((UIAlertAction) -> Void)?]) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        for (index, title) in actionTitles.enumerated() {
//            let style: UIAlertAction.Style = (title == "Cancel" || title == "No") ? .cancel : .default
//            let action = UIAlertAction(title: title, style: style, handler: actions[index])
//            alert.addAction(action)
//        }
//        DispatchQueue.main.async {
//            UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
//        }
//    }
//    
    
    // MARK: - generate a unique identifier
    func generateUniqueIdentifier() -> String {
        // Create universally unique identifier (object)
        let uuidObject: CFUUID = CFUUIDCreate(kCFAllocatorDefault)
        // Get the string representation of CFUUID object.
        let uuidStr = (CFUUIDCreateString(kCFAllocatorDefault, uuidObject) as String?)
        return uuidStr!
    }
    
    // MARK: - Activity indicator
    //To show activity indicator with custom background color
//    func showActivityIndicator(bgColor: UIColor){
//        DispatchQueue.main.async {
//            self.activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x:UIScreen.main.bounds.size.width,y: UIScreen.main.bounds.size.height,width: 80,height: 80))
//            self.activityIndicatorView.layer.cornerRadius = 05
//            if #available(iOS 13.0, *) {
//                self.activityIndicatorView.style = UIActivityIndicatorView.Style.large
//            }
//            self.activityIndicatorView.isOpaque = false
//            self.activityIndicatorView.backgroundColor = bgColor.withAlphaComponent(0.7)
//            self.activityIndicatorView.center = (UIApplication.topViewController()?.view.center)!
//            self.activityIndicatorView.color = UIColor.white
//            self.activityIndicatorView.startAnimating()
//            UIApplication.topViewController()?.view.addSubview(self.activityIndicatorView)
//        }
//    }
    //  Displays an activity indicator without blocking the main thread.
    
//    func showActivityIndicatorWithoudAsync(bgColor: UIColor){
//        self.activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x:UIScreen.main.bounds.size.width,y: UIScreen.main.bounds.size.height,width: 80,height: 80))
//        self.activityIndicatorView.layer.cornerRadius = 05
//        if #available(iOS 13.0, *) {
//            self.activityIndicatorView.style = UIActivityIndicatorView.Style.large
//        }
//        self.activityIndicatorView.isOpaque = false
//        self.activityIndicatorView.backgroundColor = bgColor.withAlphaComponent(0.7)
//        self.activityIndicatorView.center = (UIApplication.topViewController()?.view.center)!
//        self.activityIndicatorView.color = UIColor.white
//        self.activityIndicatorView.startAnimating()
//        UIApplication.topViewController()?.view.addSubview(self.activityIndicatorView)
//    }
    
    //To hide activity indicator with custom background color
    func hideActivityIndicator(){
        DispatchQueue.main.async {
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    //Activity indicator with custom message, background color and height
//    func showCustomActivityIndicatoronMainThread(message: String, bgcolor: UIColor, height: CGFloat) {
//        let loadingAlertController: UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        loadingAlertController.view.tintColor = UIColor.blue
//        loadingAlertController.setMessage(font: UIFont(name: "UIFontWeightLight", size: 15), color: UIColor.white)
//        let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
//        if #available(iOS 13.0, *) {
//            activityIndicator.style = UIActivityIndicatorView.Style.large
//        }
//        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
//        // change the background color
//        let subview = (loadingAlertController.view.subviews.first?.subviews.first?.subviews.first!)! as UIView
//        subview.layer.cornerRadius = 1
//        subview.backgroundColor = bgcolor.withAlphaComponent(0.7)
//        activityIndicator.color = .white
//        loadingAlertController.view.addSubview(activityIndicator)
//        
//        let xConstraint: NSLayoutConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: loadingAlertController.view, attribute: .centerX, multiplier: 1, constant: 0)
//        let yConstraint: NSLayoutConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: loadingAlertController.view, attribute: .centerY, multiplier: 1.4, constant: 0)
//        
//        NSLayoutConstraint.activate([ xConstraint, yConstraint])
//        activityIndicator.isUserInteractionEnabled = false
//        activityIndicator.startAnimating()
//        
//        let height: NSLayoutConstraint = NSLayoutConstraint(item: loadingAlertController.view ?? UIView(), attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: height)
//        loadingAlertController.view.addConstraint(height)
//        UIApplication.topViewController()?.present(loadingAlertController, animated: true, completion: nil)
//    }
    
    //Activity indicator with custom message, background color and height
//    func showCustomActivityIndicator(message: String, bgcolor: UIColor, height: CGFloat) {
//        DispatchQueue.main.async {
//            let loadingAlertController: UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//            loadingAlertController.view.tintColor = UIColor.blue
//            loadingAlertController.setMessage(font: UIFont(name: "UIFontWeightLight", size: 15), color: UIColor.white)
//            let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
//            if #available(iOS 13.0, *) {
//                activityIndicator.style = UIActivityIndicatorView.Style.large
//            }
//            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
//            // change the background color
//            let subview = (loadingAlertController.view.subviews.first?.subviews.first?.subviews.first!)! as UIView
//            subview.layer.cornerRadius = 1
//            subview.backgroundColor = bgcolor.withAlphaComponent(0.7)
//            activityIndicator.color = .white
//            loadingAlertController.view.addSubview(activityIndicator)
//            
//            let xConstraint: NSLayoutConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: loadingAlertController.view, attribute: .centerX, multiplier: 1, constant: 0)
//            let yConstraint: NSLayoutConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: loadingAlertController.view, attribute: .centerY, multiplier: 1.4, constant: 0)
//            
//            NSLayoutConstraint.activate([ xConstraint, yConstraint])
//            activityIndicator.isUserInteractionEnabled = false
//            activityIndicator.startAnimating()
//            
//            let height: NSLayoutConstraint = NSLayoutConstraint(item: loadingAlertController.view ?? UIView(), attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: height)
//            loadingAlertController.view.addConstraint(height)
//            UIApplication.topViewController()?.present(loadingAlertController, animated: true, completion: nil)
//        }
//    }
    //To hide activity indicator with custom message, background color and height
//    func hideCustomActivityIndicator(completion: (() -> Void)? = nil) {
//        DispatchQueue.main.async {
//            if let topVC = UIApplication.topViewController() as? UIAlertController {
//                topVC.dismiss(animated: true, completion: {
//                    completion?() // Call the completion block if provided
//                })
//            }
//        }
//    }
    //Saves the expiration date to the Keychain.
    
//    func saveExpairyToKeychain(date: Date) {
//        let keyChain = KeychainItemWrapper(identifier: "CrewBidWbidExpirationDate", accessGroup: nil)
//        keyChain?.setObject(encryptedDateString(date: date), forKey: kSecAttrAccount)
//    }
    
   // Encrypts a given date into a string.
    
//    private func encryptedDateString(date: Date) -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = kCBExpirationDateFormat
//        let dateString = dateFormatter.string(from: date)
//        let encryptedString = FBEncryptorAES.encryptBase64String(dateString, keyString: kFreeMonthEncryptionKey, separateLines: false)
//        return encryptedString!
//    }
    // Retrieves the expiration date from the Keychain.
//    
//    func getExpairtDateFromKeychain() -> Date?{
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = kCBExpirationDateFormat
//        if let keyChain = KeychainItemWrapper(identifier: "CrewBidWbidExpirationDate", accessGroup: nil), let encValue = keyChain.object(forKey: kSecAttrAccount) as? String{
//            // Successfully retrieved account value from keychain
//            let keychainDateString = FBEncryptorAES.decryptBase64String(encValue, keyString: kFreeMonthEncryptionKey) ?? ""
//            if let keychainExpirationDate = dateFormatter.date(from: keychainDateString){
//                return keychainExpirationDate
//            }
//        } else {
//            // Keychain is nil or account value not found in keychain
//            print("Keychain is nil or account value not found in keychain")
//        }
//        return nil
//    }
    //  Shows the user account import view after a delay.
//    
//    func showUserAccountImportView() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            let storyboard : UIStoryboard = UIStoryboard(name: "BidInfo", bundle: nil)
//            let vc = storyboard.instantiateViewController(withIdentifier: "LoginEmbeddController") as! LoginEmbeddController
//            vc.preferredContentSize = CGSize(width: 650, height: 550)
//            if #available(iOS 13.0, *) {
//                vc.isModalInPresentation = true
//            } else {
//                    // Fallback on earlier versions
//            }
//            UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
//        }
//        
//    }
    
}
enum SWVacation : String {
    case LineName="Line#"
    case FrontVO="Front VO"
    case FrontVO1="Front VO1"
    case FrontVO2="Front VO 2"
    case blockName="*Block"
    case BackVO="Back VO"
    case BackVO1="Back VO1"
    case BackVO2="Back VO 2"
    case CarryoutVacationPay="Carry-out Vacation Pay"
    case EffectiveVacationLength="Effective Vacation Length"
    case LongestBlockofDaysOff = "Longest Block of Days Off"
    case CarryoutVOPay="Carry-out VO Pay"
    case VacPayBothBp="VacPayBothBp"
    case VacPayNeBp="VacPayNeBp"
    case TotalPay="Total Pay"
    case FlyPay="Fly Pay"
    case TotalVacationPay="Total Vacation Pay"
    case CarryOutPay_Flying="Carry Out Pay (Flying)"
    case TotalDaysOff="Total Days Off"
    case DaysWorked_inmonth="Days Worked (in month)"
    case DaysWorked="Days Worked"
    case vAbo="VAbo"
    case vAbp="VAbp"
    case vAne="VAne"
    case vAPbo="VAPbo"
    case vAPbp="VAPbp"
    case vAPne="VAPne"
    case holidayPay="Holiday Pay"
}

extension UIView {
    
    func makeCornorRound(radius: CGFloat? = nil) {
        if let radius = radius {
            self.layer.cornerRadius = radius
        } else {
            self.layer.cornerRadius = self.frame.width / 2
        }
        self.layer.masksToBounds = true
    }
    
    var globalPoint :CGPoint? {
        return self.superview?.convert(self.frame.origin, to: nil)
    }
    
    var globalFrame :CGRect? {
        return self.superview?.convert(self.frame, to: nil)
    }
    
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 5
        layer.shadowPath = UIBezierPath(roundedRect:self.bounds, cornerRadius:self.layer.cornerRadius).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}



extension NSMutableAttributedString {
    var fontSize:CGFloat { return 20 }
    var boldFont:UIFont { return UIFont(name: "AvenirNext-Bold", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize) }
    var normalFont:UIFont { return UIFont(name: "AvenirNext-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)}
    
    func bold(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font : boldFont
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    
    func normal(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font : normalFont,
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    /* Other styling methods */
    func orangeHighlight(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font :  normalFont,
            .foregroundColor : UIColor.white,
            .backgroundColor : UIColor.orange
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    
    func blackHighlight(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font :  normalFont,
            .foregroundColor : UIColor.white,
            .backgroundColor : UIColor.black
            
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    
    func underlined(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font :  normalFont,
            .underlineStyle : NSUnderlineStyle.single.rawValue
            
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
}


extension UIAlertController {
    //Set message font and message color
    func setMessage(font: UIFont?, color: UIColor?) {
        guard let title = self.message else {
            return
        }
        let attributedString = NSMutableAttributedString(string: title)
        if let titleFont = font {
            attributedString.addAttributes([NSAttributedString.Key.font : titleFont], range: NSMakeRange(0, title.utf8.count))
        }
        if let titleColor = color {
            attributedString.addAttributes([NSAttributedString.Key.foregroundColor : titleColor], range: NSMakeRange(0, title.utf8.count))
        }
        self.setValue(attributedString, forKey: "attributedMessage")
    }
    
}



extension String {
    
    var isInt: Bool {
        return Int(self) != nil
    }
    
    var bool: Bool? {
        switch self.lowercased() {
        case "true", "t", "yes", "y", "1":
            return true
        case "false", "f", "no", "n", "0":
            return false
        default:
            return nil
        }
    }
    
    func convertToDictionary() -> Any? {
        if let data = self.data(using: .utf8) {
            do {
                let value: Any = try JSONSerialization.jsonObject(with: data, options: []) as Any
                return value
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func getDateString(fromFormat: String, toFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "UTC")
        dateFormatter.dateFormat = fromFormat
        let date = dateFormatter.date(from:self)!
        dateFormatter.dateFormat = toFormat
        return dateFormatter.string(from: date)
    }
    
    
    func getDate(fromFormat: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "UTC")
        dateFormatter.dateFormat = fromFormat
        let date = dateFormatter.date(from:self)!
        return date
    }
}

class CBToast: UIView {
    
    private var _isAlreadyShown = false
    
    var isAlreadyShown: Bool {
        set { _isAlreadyShown = newValue }
        get { return _isAlreadyShown }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 19
        self.layer.masksToBounds = true
        self.alpha = 0
    }
}

extension Dictionary where Value: Equatable {
    func key(from value: Value) -> Key? {
        return self.first(where: { $0.value == value })?.key
    }
    
    func allKeys(forValue val: Value) -> [Key]? {
        return self.filter { $1 == val }.map { $0.0 }
    }
    
   
}

extension UITextField {
    func shakeTextField() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 6, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 6, y: self.center.y))
        self.layer.add(animation, forKey: "position")
        self.attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
}
extension UIImage {
    class func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
}
