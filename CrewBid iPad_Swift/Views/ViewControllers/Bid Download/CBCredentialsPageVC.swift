//
//  CBCredentialsPageVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit
import CoreData
import WebKit

protocol submissionGoActiondelegate{
    func goActionFromSubmitCertifyDelegate()
}

protocol CBCredentialsPageVCDelegate: AnyObject {
    func credentialsDidRefreshToken(_ vc: CBCredentialsPageVC)
}

enum TypeWebServices {
    case wbidUserCheck
    case importUserDetails
    case vacationFileNames
}


enum credentialVCType{
    case defaultType
    case retrieveAwards
    case submitBid
}

enum LoginReason {
    case normalBidFlow
    case tokenExpired
}

class CBCredentialsPageVC: BaseViewController, submissionGoActiondelegate, UIAdaptivePresentationControllerDelegate, ServiceConnectionDelegate {
    func responseError(_ errMsg: String) {
        print("responseError:\(errMsg)")
    }
    
    func serviceResponse(_ arrResponse: [Any]) {
        var value: Int = 0
        var enteredEmpNo: String?
        var historySecretEnabled: String?
        let userArray = arrResponse as! [[String: Any]]
        print(arrResponse.description)
        if arrResponse.count > 0{
            switch webType {
            case .wbidUserCheck:
                if webViewloaded{
                    // Web login → ID comes from decoded token
                    enteredEmpNo = userid?.replacingOccurrences(of: "e", with: "")
                                         .replacingOccurrences(of: "x", with: "")
                                         .trimmingCharacters(in: .symbols)
                }else{
                    // Old login → ID comes from textfield
                    var empID = txtUserID.text ?? ""
                    if empID.lowercased().hasPrefix("e") || empID.lowercased().hasPrefix("x") {
                        empID = String(empID.dropFirst())
                    }
                    enteredEmpNo = empID
                }
                
                
                dicWBAuthorizationDetails = NSMutableDictionary(dictionary: userArray.first!, copyItems: true) as! [String : Any]

                historySecretEnabled = UserDefaults.standard.string(forKey: "isMaxSubScriptionOfEnteredUser")
                app.ObjUserAccount?.LoginuserId = enteredEmpNo ?? ""
                if historySecretEnabled == "YES"{
                    app.ObjUserAccount?.LoginuserId = UserDefaults.standard.string(forKey: "SecretVDuserName")!
                    app.ObjUserAccount?.saveUserInfo()
                    enteredEmpNo = app.ObjUserAccount?.LoginuserId
                    app.ObjUserAccount?.dicLogInAuthExternalUser = NSMutableDictionary(dictionary: dicWBAuthorizationDetails, copyItems: true)
                }
                if enteredEmpNo == app.ObjUserAccount?.employeeNumber{
                    let secretEnabled = UserDefaults.standard.string(forKey: "isSecretVDSwitchEnabled")
                    if secretEnabled == "YES"{
                        app.ObjUserAccount?.dicLogInAuthExternalUser = NSMutableDictionary(dictionary: dicWBAuthorizationDetails, copyItems: true)
                    }
                    app.isNeedToDownloadSeniorityFromServer = userArray.first?["IsNeedToDownloadSeniorityFromServer"] as! Bool
                    app.ObjUserAccount?.topSubscriptionLine = userArray.first?["TopSubscriptionLine"] as! String
                    app.ObjUserAccount?.secondSubscriptionLine = userArray.first?["SecondSubscriptionLine"] as! String
                    app.ObjUserAccount?.thirdSubscriptionLine = userArray.first?["ThirdSubscriptionLine"] as! String
                    app.ObjUserAccount?.saveUserInfo()
                }
                
                let type = (userArray.first?["Type"] as? String)?.lowercased() ?? ""
                let message = userArray.first?["Message"] as? String ?? ""

                if type == "biddownloadblocked" {
                    DispatchQueue.main.async {
                        AlertService.showAlertForTopVC(title: "Oops!", message: message, actions: [(title: "OK", style: .default, handler: { _ in
                            self.dismiss(animated: true)
                        })])
                    }
                    break
                } else if type == "invalid version" {
                    DispatchQueue.main.async {
                        self.view.hideActivityIndicator()
                        AlertService.showAlertForTopVC(title: "Oops!", message: message, actions: [
                            (title: "Cancel", style: .cancel, handler: { _ in
                                self.dismiss(animated: true)
                            }),
                            (title: "Go to AppStore", style: .default, handler: { _ in
                                if let url = URL(string: "https://itunes.apple.com/us/app/crewbid/id563832596?mt=8") {
                                    UIApplication.shared.open(url)
                                }
                                self.dismiss(animated: true)
                            })
                        ])
                    }
                    break
                }
                let hasLocalUserInfo = CBUtils.isLocalUserInformationAvailable()
                if hasLocalUserInfo {
                    
                    if webViewloaded{
                        // WEBVIEW authentication path (no password!)
                        let formattedUserID = userid ?? ""
                        let empID = enteredEmpNo ?? ""

                        self.startAuthentication(empID: empID,
                                                 formattedUserID: formattedUserID,
                                                 password: "")   // no password for web login
                    }else{
                        
                        var empID = self.txtUserID.text ?? ""
                        if empID.lowercased().hasPrefix("e") || empID.lowercased().hasPrefix("x") {
                            empID = String(empID.dropFirst())
                        }
                        let formattedUserID = self.txtUserID.text ?? ""
                        let password = self.txtPassword.text ?? ""
                            self.startAuthentication(empID: empID, formattedUserID: formattedUserID, password: password)
                    }
                    //Check if employee is external user
//                    if app.ObjUserAccount?.employeeNumber == enteredEmpNo{
//                        // Internal user
//                        WBSubscriptionChecking()
//                    }else{
//                        // External user
//                        WBSubscriptionChecking()
//                    }
                    
                    
                } else {
                    if let account = KeychainHelper.retrieveUsername(forService: "CWAUserAccountDetails"){
                        KeychainHelper.delete(account: account, service: "CWAUserAccountDetails")
                    }
                    // Import existing account data
                    self.getUserInformation()
                }

            case .importUserDetails:
                self.view.hideActivityIndicator()
                let empNum = userArray.first?["EmpNum"] as? Int
                value = empNum!
                
                if value != 0 {
                    dicWbidResponce = NSMutableDictionary(dictionary: userArray.first!, copyItems: true) as! [String : Any]
                    localAccountCreation()
                    updateCBExpirationDate()
                    
                    app.ObjUserAccount?.captureUserEmail(app.ObjUserAccount?.email)
                    AlertService.showAlertForTopVC(title: "Great!", message: "We found a previous account from CrewBid or WbidMax.\nWe've imported those settings.\nPlease verify the settings and change as needed", actions: [(title: "OK", style: .default, handler:{_ in
                        if self.isImportedinMacOS(){
                            self.sendMacImportedLog()
                        }
                        self.showUserAccountView()
                    })])
                }else{
                    AlertService.showAlertForTopVC(title: "No Existing Account", message: "We checked, but no previous account exists for you.\n\nThe next view will let you create your account.", actions: [(title: "Go To Create Account", style: .default, handler:{_ in
                        self.app.ObjUserAccount?.deleteUserAccount()
                        self.app.createEmpNo = self.txtUserID.text //need to check
                        self.showUserAccountView()
                    })])
                }
                break
            case .vacationFileNames:
                let dicFileNames = userArray[0]
                if let fileNames = dicFileNames["FileNames"] as? [Any] {
                    let arrVacationList = fileNames.map { $0 }
                    if !arrVacationList.isEmpty {
                        app.ObjUserAccount?.arrVacationList = arrVacationList
                        }
                    }
                break
            case nil:break
    
            }
        }
        
    }
    
    /*
    func WBSubscriptionChecking(){
        
        app.ObjUserAccount?.isFree = dicWBAuthorizationDetails["IsFree"] as! Bool
        app.ObjUserAccount?.isMonthlySubscribed = dicWBAuthorizationDetails["IsMonthlySubscribed"] as! Bool
        app.ObjUserAccount?.isYearlySubscribed = dicWBAuthorizationDetails["IsYearlySubscribed"] as! Bool
        app.ObjUserAccount?.isCBYearlySubscribed = dicWBAuthorizationDetails["IsCBYearlySubscribed"] as! Bool
        app.ObjUserAccount?.isCBMonthlySubscribed = dicWBAuthorizationDetails["IsCBMonthlySubscribed"] as! Bool
        app.ObjUserAccount?.saveUserInfo()
    }
    */
    
    func showUserAccountView(){
        let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "userAccountViewController") as! userAccountViewController
        vc.isfrom = self
//        vc.btnBack.setImage(UIImage(named: "NewBid-navbar-ncelbutton"), for: .normal)
        vc.preferredContentSize = CGSize(width: 764, height: 630)
        if let pc = vc.presentationController {
            pc.delegate = self
        }
        self.present(vc, animated: true)
    }

    func getVacationFilenames(){ //need to hanlde the call for this fucntion in the go button
        if app.connectedToInternet(){
            //show indicator
            app.sc?.delegate = self
            webType = .vacationFileNames
            var dicAuthenticationInfo: [String: Any] = [:]

            dicAuthenticationInfo["Base"] = self.dataSource.base
            print("Position--\(self.dataSource.position.shortName)")
            dicAuthenticationInfo["Position"] = self.dataSource.position.shortName
            dicAuthenticationInfo["Month"] = self.month
            dicAuthenticationInfo["Year"] = self.year
            dicAuthenticationInfo["FileName"] = ""

            // Handle round
            var roundStr = ""
            let roundValue = self.dataSource.round
            switch roundValue {
                case 1: roundStr = "M"
                case 2: roundStr = "S"
                default: break
            }
            dicAuthenticationInfo["Round"] = roundStr

            // Clean up employee number string
            if let empNumStr = self.empNum {
                var enteredEmpNo = empNumStr.replacingOccurrences(of: "x", with: "")
                enteredEmpNo = enteredEmpNo.replacingOccurrences(of: "e", with: "")
                enteredEmpNo = enteredEmpNo.trimmingCharacters(in: .symbols)
                
                if let empNumInt = Int(enteredEmpNo) {
                    dicAuthenticationInfo["EmpNum"] = empNumInt
                }
            }

            // Call the method
            objDataBuilder.getWBidVacationFileNames(dicAuthenticationInfo)
        }
    }
    
    
    func updateCBExpirationDate(){
        var dicMailInfo:[String: Any] = [:]
        dicMailInfo["EmpNum"] = app.ObjUserAccount?.employeeNumber
        let expiry = CBIAPHelper.shared.getBestAvailableCBExpirationDateFromiCloudAndKeyChain()
        
        if let expiry = expiry{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = kCBExpirationDateFormat
            dateFormatter.timeZone = TimeZone(identifier: "GMT")
            let stringDate = dateFormatter.string(from: expiry)
            let dateFromString = dateFormatter.date(from: stringDate)
            let startDate = dateFromString!.timeIntervalSince1970 * 1000
            let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)
            dicMailInfo["CBPaidUntilDate"] = dateStarted
        }else{
            dicMailInfo["CBPaidUntilDate"] = NSNull()
        }
        
        let productType = CBIAPHelper.shared.latestPurchaseType()
        
        dicMailInfo["LastCBPaymentType"] = productType
        
        let url = URL(string: EndPoint.shared.updateCrewbidUserPaidUntilDate)
        
        var urlRequest = URLRequest(url: url!)
        let jsonData = try? JSONSerialization.data(withJSONObject: dicMailInfo)
        let jsonString = String(data: jsonData!, encoding: .utf8)!
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonString.data(using: .utf8)
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let data = data {
                if let httpResponse = response as? HTTPURLResponse {
                    let mimeType = response?.mimeType ?? ""
                    print("Status code -- \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 && mimeType.contains("application/json") {
                        do {
                            _ = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                        } catch {
                            print("JSON parse error: \(error)")
                        }
                    }
                }
            } else if let error = error {
                print("Request error: \(error.localizedDescription)")
            }
        }
        dataTask.resume()
        
    }
    
    
    func localAccountCreation(){
        app.ObjUserAccount?.cellPhone = dicWbidResponce["CellPhone"] as! String
        app.ObjUserAccount?.firstName = dicWbidResponce["FirstName"] as! String
        app.ObjUserAccount?.lastName = dicWbidResponce["LastName"] as! String
        app.ObjUserAccount?.employeeNumber = "\(dicWbidResponce["EmpNum"]!)"
        app.ObjUserAccount?.email = dicWbidResponce["Email"] as! String
        app.ObjUserAccount?.position = dicWbidResponce["Position"] as! Int
        app.ObjUserAccount?.isAcceptMail = dicWbidResponce["AcceptEmail"] as! Bool
        app.ObjUserAccount?.CarrierNum = dicWbidResponce["CarrierNum"] as! Int
        app.ObjUserAccount?.UserAccountDateTime = dicWbidResponce["UserAccountDateTime"] as! String
        app.ObjUserAccount?.dicLoginAuthDetails = NSMutableDictionary(dictionary: dicWBAuthorizationDetails, copyItems: true)
        app.ObjUserAccount?.saveUserInfo()
    }
    
    
    func isImportedinMacOS() -> Bool {
        if #available(iOS 13.0, *) {
            return ProcessInfo.processInfo.isMacCatalystApp
        } else {
            return false
        }
    }
    
    func sendMacImportedLog() {
        var dicMailInfo: [String: Any] = [:]
        
        dicMailInfo["EmployeeNumber"] = self.empNum
        dicMailInfo["Event"] = "MacCBinstall"
        dicMailInfo["Message"] = "MacCBinstall"
        dicMailInfo["Base"] = "ATL"
        
        dicMailInfo["Position"] = CBUtils.shortName(for: self.dataSource.position)
        
        
        dicMailInfo["Round"] = 1
        dicMailInfo["SWAMessage"] = ""
        dicMailInfo["OperatingSystemNum"] = "Mac OS"
        dicMailInfo["VersionNumber"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        dicMailInfo["PlatformNumber"] = "iPad"
        dicMailInfo["BidForEmpNum"] = 0
        dicMailInfo["BuddyBid1"] = 0
        dicMailInfo["BuddyBid2"] = 0
        dicMailInfo["BuddyBid3"] = 0
        dicMailInfo["FromApp"] = "5"
        dicMailInfo["FromAppNum"] = "5"
        
        let currentDate = Date()
        let currentMonth = Calendar.current.component(.month, from: currentDate)
        dicMailInfo["Month"] = CBUtils.shortMonthName(month: currentMonth, uc: false)
        
        let startDate = CFAbsoluteTimeGetCurrent() * 1000
        let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)
        dicMailInfo["Date"] = dateStarted
        
        let objEvent = CBOfflineEvents()
        objEvent.addOfflineEvent(dicMailInfo)
        objEvent.sendOfflineData()
    }
    
    func responseStatus(_ responseStatus: Int) {
        print("responseStatus")
    }
    
    
    func connectionFailed() {
        print("connectionFailed")
    }
    
    func requestFailed() {
        print("requestFailed")
    }
    
    func connectionDataReceived(_ progress: Float) {
        print("connectionDataReceived")
    }
    
    var webType:TypeWebServices?
    var delegate:ServiceConnectionDelegate?
    var objDataBuilder = ODataBuilder()
    var isCWAUserExist: Bool = false
    var isWbidUserExist: Bool = false
    var dicWbidResponce: [String: Any] = [:]
    var dicWBAuthorizationDetails: [String: Any] = [:]
    
    @IBOutlet weak var txtUserID: customUITextField!
    @IBOutlet weak var txtPassword: customUITextField!
    @IBOutlet weak var showPasswordBtn: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var lblQaMode: UILabel!
    @IBOutlet weak var goBtn: UIButton!
    @IBOutlet weak var webView: WKWebView!
    
    
    let reachability = try! Reachability()
    var isHistoricBid : Bool = false
    var isNewBid:Bool = false
    var selectedRound:Int?
    var selectedPosition:BICrewPositionType?
    var selectedDomicile:String?
    var empNum:String?
    var month:Int?
    var year:Int?
    var userid:String?
    var password:String?
    var loginType:LoginType = .newBid
    var type:credentialVCType = .defaultType
    var bidPeriod: BIBidPeriod?
    let loginViewModel = CBLoginViewModel()
    let bidDownloadViewModel = BIBidFileDownloadViewModel()
    let context = CoreDataManager.shared.persistentContainer.viewContext
    let dataSource = GlobalBidInfo.shared
    var bidPeriodList:[BIBidPeriod] = []
    private var hasStartedBidProcessing = false
    var awardsViewModel:AwardsViewModel?
    var submissionViewModel:CBBidSubmissionViewModel?
    var formattedEmpNum: String?
    var defaultEmplyeeNumber:String?
    var optionalEmployees = NSMutableArray()
    var bidListNumbers = NSMutableArray()
    let allbidDownloadViewModel = BIAllDomicileDownloadViewModel()
    var jobShare1:String?
    var jobShare2:String?
    
    //for new API
    var webViewloaded = false
    var clientID: String = "p502838"
    var redirectURI: String = ""
    var authorizationEndpoint: String = ""
    var tokenEndpoint: String = ""
    var codeVerifier: String = ""
    var env = ""
    var selectedObject: [String: Any] = [:]
    let webViewModel = BISwaBidDataDownloadViewModel()
    var bidDetails:[String:Any] = [:]
    var isForReauth: Bool = false
    let swaBidDataDownload = BISwaBidDataDownload()
    var loginReason: LoginReason = .normalBidFlow
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter
    }()
     
    override func viewWillAppear(_ animated: Bool) {
        
        if isForReauth {
            backBtn.setImage(UIImage(named: "cc"), for: .normal)
        }else{
            backBtn.setImage(UIImage(named: "arrowleftbutton"), for: .normal)
        }
        
        
        if self.dataSource.position == BICrewPositionType.FlightAttendant{
            if app.connectedToInternet(){
                self.view.showActivityIndicator(message: "Loading SWA Login...")
            }else{
                AlertService.showAlertForTopVC(title: "No Internet Connection", message: "An internet connection is required to Login. Please connect to the internet and try again.")
            }
        }
        
            NotificationCenter.default.addObserver(self, selector: #selector(closeCredentilaPage), name: Notification.Name("CloseCredentilaPage"), object: nil)
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if let bidPeriod = CBGlobalMethods.shared.selectedBidPeriod {
            awardsViewModel = AwardsViewModel(bidPeriod: bidPeriod)
        }
        //for new API
        if self.dataSource.position == BICrewPositionType.FlightAttendant{
            self.setupSwaLogin()
        }else{
            self.setupLegacyLogin()
        }
        
        if !UserDefaults.standard.bool(forKey: "isSecretForAllDomicileDownloadEnabled") {
            NotificationCenter.default.addObserver(self, selector: #selector(showProgressView), name: Notification.Name("ShowProgressView"), object: nil)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(showBidAwardReadError(notification:)), name: NSNotification.Name("BidAwardReadError"), object: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.dataSource.position == BICrewPositionType.FlightAttendant {
            if type == .defaultType && loginReason == .normalBidFlow{
                if self.bidAlreadyExists() {
                    // show alert which will call the closure on "Download Again"
                    self.showAlertForExistingBid {
                        // user chose Download Again -> start FA web login after deletion
                        DispatchQueue.main.async {
                            self.setupSwaLogin()
    //                        self.setupLegacyLogin()
                        }
                    }
                } else {
                    // no existing bid -> start FA web login now
                    self.setupSwaLogin()
    //                self.setupLegacyLogin()
                }
            }else{
                self.setupSwaLogin()
            }

        } else {
            // legacy (pilot) flow: if you want the pilot path to still show the existing-bid alert here,
            // you can do the same check or keep your existing go-button based flow.
            // If you want to start legacy login immediately:
            self.setupLegacyLogin()
        }
    }

    
    @objc func closeCredentilaPage() {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func showProgressView() {
        let progressVC = UIStoryboard(name: "BidInfo", bundle: nil).instantiateViewController(withIdentifier: "CBProgressVC") as! CBProgressVC
        self.navigationController?.pushViewController(progressVC, animated: true)
    }
    
    func setupTitle(){
        let isQATest = UserDefaults.standard.bool(forKey: "isQATest")
        if isQATest == true {
            let qaMonth = UserDefaults.standard.string(forKey: "QATestMonth") ?? "0"
            let qaYear = UserDefaults.standard.string(forKey: "QATestYear") ?? "0"
            lblQaMode.text = "QA Mode: \(qaMonth) - \(qaYear)"
        }
        else {
            lblQaMode.text = ""
        }
        if type == .retrieveAwards {
            lblTitle.text = "Retrieve Awards"
        }
        else if type == .submitBid {
            lblTitle.text = "Submit Bid"
        }
        else if isHistoricBid {
            lblTitle.text = "Historic Bid Data"
        } else {
            lblTitle.text = "New Bid Data"
        }
    }

    
    func setupSwaLogin(){
        let apiEnv = UserDefaults.standard.string(forKey: "SwaApiEnv")
        if apiEnv == "Dev"{
            env = "dev"
            redirectURI = "com.crewbid-wbidmax://callback"
        }else if apiEnv == "QA"{
            env = "qa"
            redirectURI = "https://crewbidapp.com/callback"
        }else{
            env = "prod"
            redirectURI = "com.crewbid-wbidmax://callback"
        }
        authorizationEndpoint = "https://sso.fed.\(env).aws.swalife.com/as/authorization.oauth2"
        tokenEndpoint = "https://sso.fed.\(env).aws.swalife.com/as/token.oauth2"
        if app.connectedToInternet(){
            self.startAuthFlow()
        }
    }
    
    func setupLegacyLogin(){
        
        if type == .retrieveAwards {
            backBtn.setImage(UIImage(named: "cc"), for: .normal)
        }else{
            backBtn.setImage(UIImage(named: "arrowleftbutton"), for: .normal)
        }
        if CBUtils.isRunningOnSimulator(){
            self.txtUserID.text = DevUserID
            self.txtPassword.text = DevUserPassword
        }else{
            let service = "loginCredentials"
            if let username = KeychainHelper.retrieveUsername(forService: service),
            let password = KeychainHelper.retrieve(account: username, service: service) {
                txtUserID.text = username
                txtPassword.text = password
            }
        }

    }
    
    func setupUI(){
        setupTitle()
        if type == .defaultType && loginReason == .normalBidFlow{
            checkEarlyBidding()
        }
        
        if self.dataSource.position == BICrewPositionType.FlightAttendant{
            self.webView.isHidden = false
            self.goBtn.isHidden = true
        }else{
            self.webView.isHidden = true
            txtUserID.delegate = self
            txtPassword.delegate = self
            txtUserID.textContentType = .username
            txtPassword.textContentType = .password
            txtUserID.layer.borderWidth = 4
            txtUserID.layer.borderColor = UIColor.gray.cgColor
            txtPassword.layer.borderWidth = 4
            txtPassword.layer.borderColor = UIColor.gray.cgColor
            showPasswordBtn.setImage(UIImage(named: "showPwd")?.withRenderingMode(.alwaysTemplate), for: .normal)
            showPasswordBtn.tintColor = .label
            txtUserID.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtUserID.frame.height))
            txtUserID.leftViewMode = .always
            txtPassword.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtPassword.frame.height))
            txtPassword.leftViewMode = .always
        }

        //------viewmodel--------
        loginViewModel.onLoginSuccess = { sessionKey in
            //Saving userID to keychain
            let service = "com.yourapp.login"
            let account = self.txtUserID.text ?? ""
            let password = self.txtPassword.text ?? ""
            if !CBUtils.isRunningOnSimulator(){
                let success = KeychainHelper.save(account: account, service: service, value: password)
                if success{
                    print("Saved to keychain")
                }
            }
            if self.type == .retrieveAwards{
                self.handleAwardRetrieval(sessionKey: sessionKey)
            }
            else if self.type == .submitBid{
                self.handleBidSubmission(sessionKey: sessionKey)
            }
            else{
                self.handleBidDownload(sessionKey: sessionKey)
            }
        }
        loginViewModel.onLoginFailure = { error in
            self.view.hideActivityIndicator()
           
            let errorString = error.localizedDescriptionString.lowercased()
            print("Error:\(errorString)")
            if errorString.contains("login failed") || errorString.contains("security purposes") || errorString.contains("invalid account"){
                if let account = KeychainHelper.retrieveUsername(forService: "SaveLoginDetails") {
                    KeychainHelper.delete(account: account, service: "SaveLoginDetails")
                }
                let str1 = AlertService.getAttributedMessage(from: "To LOGIN, you need to use your SwaLife password!", highlight: "SwaLife")
                let str2 = AlertService.getAttributedMessage(from: "\n\nMost likely, your SwaLife password has expired.", highlight: "SwaLife")
                let str3 = AlertService.getAttributedMessage(from: "\n\nBTW, it is possible your password to LOGIN on swacrew.com is valid and your", highlight: "swacrew.com")
                let str4 = AlertService.getAttributedMessage(from: " SwaLife password is expired.", highlight: "SwaLife")
                let str5 = AlertService.getAttributedMessage(from: "\n\nThe only way to fix this problem is to go to the Swalife Password Manager and change your password.", highlight: "Swalife")
                str1.append(str2)
                str1.append(str3)
                str1.append(str4)
                str1.append(str5)
                AlertService.showDBAlert(title: "Oops!", attributedMessage: str1, from: self)
                
            }else if errorString.contains("timed out"){
                if self.app.objNetworkType == .free || self.app.objNetworkType == .paid{
                    AlertService.showDBAlert(title: "Darn it!", attributedMessage: NSAttributedString(string: "The company 3rd Party server is not responding.\nThis is not uncommon.\nYour only cources of action are to wait a while and try again, or try another internet connection.\nSometimes the internet signal on the plane is just too weak"), from: self)
                }else if self.app.objNetworkType == .ground{
                    AlertService.showDBAlert(title: "Darn it!", attributedMessage: NSAttributedString(string: "The company 3rd Party server is not responding.\nThis is not uncommon.\nYour only cources of action are to wait a while and try again, or try using a cellular internet connection.\n"), from: self)
                }
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(dismissVC), name: NSNotification.Name(rawValue: "dismissLoginView"), object: nil)
    }

    func handleBidDownload(sessionKey: String){
        self.view.hideActivityIndicator()
        NotificationCenter.default.post(name: Notification.Name("ShowProgressView"), object: nil)
        let bidFileName = BIBidInfo.shared.bidDataFilename()
        let linesTextFileName = BIBidInfo.shared.linesTextFilename()
        print("Filename: \(bidFileName)")
        if AppState.shared.isHistoricBid{
            //MARK:  Historic Bid Data
            print("Bid: Historic Bid")
            if self.isSecondRoundBid() && !self.isFABid() {
                    // First download TXT file
                self.bidDownloadViewModel.fetchHistoricBidLines(filename: linesTextFileName, useDataRest: false) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let fileURL):
                                print("TXT file saved at: \(fileURL)")
                                
                                // After TXT, proceed with bid file
                                self.downloadHistoricBidFile(bidFileName: bidFileName)
                                
                            case .failure(let error):
                                print("Historic TXT download failed: \(error.localizedDescription)")
                                
                                // Still proceed with bid file even if TXT fails
                                self.downloadHistoricBidFile(bidFileName: bidFileName)
                            }
                        }
                    }
                } else {
                    // Directly download main bid file
                    self.downloadHistoricBidFile(bidFileName: bidFileName)
                }
            
        }
        else if AppState.shared.isMockData{
            //MARK:  Mock Bid Data
            print("Bid: Mock data")
            
        }
        //MARK:  Bulk Data
        else if UserDefaults.standard.bool(forKey: "isSecretForAllDomicileDownloadEnabled") == true {
            let dictionary = GlobalBidInfo.shared.allDomicileDownloadDictionary
            let tableViewData: [String] = []
            let isBothSelected: Bool = (dictionary["both"] as? Bool)!
            var initialbases: [String] = (dictionary["bases"] as! [String])
            if isBothSelected {
                for base in initialbases {
                    initialbases.append(base)
                }
                GlobalBidInfo.shared.allDomicileDownloadDictionary["bases"] = initialbases
            }
            GlobalBidInfo.shared.isCurrentlyDownloadingAllBid = 1
            GlobalBidInfo.shared.alertCount = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.navigationController?.popViewController(animated: true)
            }
            self.allbidDownloadViewModel.downladAllDomicileBid(bases: initialbases, tableViewData: tableViewData)
        }
        
        else{
            //MARK:  New Bid Data
            print("Bid: New bid")
            bidDownloadViewModel.fetchNewBidData(sessionKey: sessionKey, fileName: bidFileName) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let fileURL):
                        self.handleNewBidDownloadSuccess(fileURL: fileURL)
                        
                    case .failure(let error):
                        self.handleNewBidDownloadFailure(error: error)
                    }
                }
            }
        }
    }
    
    private func downloadHistoricBidFile(bidFileName: String) {
        self.bidDownloadViewModel.fetchHistoricBidLines(filename: bidFileName, useDataRest: true) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fileURL):
                    print("File unzipped at: \(fileURL)")
                    NotificationCenter.default.post(name: Notification.Name("BidDownloaded"), object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        BIBidInfoReader.shared.checkForSeniorityVacationAndReadBidInfo() { success in
                            if success {
                                self.loginActions()
                            }else {
                                NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
                            }
                        }
                    }
                case .failure(let error):
                    print("Historic bid download failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    private func handleNewBidDownloadSuccess(fileURL: URL) {
        print("File unzipped at: \(fileURL)")
        NotificationCenter.default.post(name: Notification.Name("BidDownloaded"), object: nil)
        
        guard !self.hasStartedBidProcessing else { return }
        self.hasStartedBidProcessing = true
        
        BIBidInfoReader.shared.checkForSeniorityVacationAndReadBidInfo { success in
            if success {
                DispatchQueue.main.async {
                    self.loginActions()
                }
            } else {
                NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
            }
        }
    }

    private func handleNewBidDownloadFailure(error: Error) {
        print("Error downloading new bid: \(error.localizedDescription)")
        NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("showBidDownloadError"), object: error)
 
    }
    
    var lineAwardDetails:[String:Any] = [:]
    var lineAwardDownloaded = false
    
    var mrtAwardDetails:[String:Any] = [:]
    var mrtAwardDownloaded = false
    
    var jobshareAwardDetails:[String:Any] = [:]
    var jobShareAwardDownloaded = false
    
    var reserveAwardDetails:[String:Any] = [:]
    var reserveAwardDownloaded = false
    
    var awardError:Error?
    //MARK: Award retrieval
    func handleAwardRetrieval(sessionKey: String? = nil){
        guard let bidPeriod = CBGlobalMethods.shared.selectedBidPeriod else {
            AlertService.showAlertForTopVC(title: "Award Retrieval Error", message: "No bid period selected.")
            return
        }
        let empNum = bidPeriod.crewIdentifier?.stringValue ?? ""
        
        //New API (FA)
        if bidPeriod.isFABid() && bidPeriod.isSwaAPI?.boolValue == true { //MARK: &&
            DispatchQueue.main.async {
                self.view.updateActivityIndicator(message: "Retrieving bid awards...")
            }
            self.retrieveAwardsForFA()
            
        }else{
            guard let sk = sessionKey, !sk.isEmpty else {
                AlertService.showAlertForTopVC(title: "Pilot Award Retrieval", message: "Missing session key for pilot award retrieval. Please login to continue.")
                return
            }
            CBGlobalMethods.shared.secretKey = sk
            awardsViewModel?.retrieveAwardFile(sessionKey: sk){ result in
                if result{
                    DispatchQueue.main.async{
                        self.dismiss(animated: false) {
                            if self.awardsViewModel?.bidPeriod.awardString != nil {
                                var emp = ""
                                if (CBGlobalMethods.shared.awardLertSecretEmpNum?.length ?? 0 > 0) {
                                    emp = CBGlobalMethods.shared.awardLertSecretEmpNum!;
                                } else {
                                    emp = empNum
                                }
                                self.awardsViewModel?.getAwardAlertFromServer(empNum: emp) { finished in
                                    CBGlobalMethods.shared.awardLertSecretEmpNum = nil;
                                 }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func retrieveAwardsForFA(){
        swaBidDataDownload?.getAwards(){ result in
            DispatchQueue.main.async {
                switch result {
                case .success(let responseDict):
                    self.lineAwardDownloaded = true
                    self.lineAwardDetails = responseDict
                case .failure(let error):
                    self.lineAwardDownloaded = true
                    self.awardError = error
                }
                self.checkForAwardError()
            }
        }
        
        if !self.bidPeriod!.isSecondRoundBid(){
            // MRT awards
            swaBidDataDownload?.getMrtAwards(){ result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let responseDict):
                        self.mrtAwardDownloaded = true
                        self.mrtAwardDetails = responseDict
                    case .failure(let error):
                        self.mrtAwardDownloaded = true
                        self.awardError = error
                    }
                    self.checkForAwardError()
                }
            }
            // JobShare awards
            swaBidDataDownload?.getJobShareAwards { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let responseDict):
                        self.jobShareAwardDownloaded = true
                        self.jobshareAwardDetails = responseDict
                    case .failure(let error):
                        self.jobShareAwardDownloaded = true
                        self.awardError = error
                    }
                    self.checkForAwardError()
                }
            }
            
            // Reserve data
            swaBidDataDownload?.getReserveDataForAward { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let responseDict):
                        self.reserveAwardDownloaded = true
                        self.reserveAwardDetails = responseDict
                    case .failure(let error):
                        self.reserveAwardDownloaded = true
                        self.awardError = error
                    }
                    self.checkForAwardError()
                }
            }
        }
    }
    
    func checkForAwardError() {
        // If not a second round, wait until all 4 downloads have finished
        if !(bidPeriod?.isSecondRoundBid() ?? false) {
            if !(reserveAwardDownloaded && mrtAwardDownloaded && lineAwardDownloaded && jobShareAwardDownloaded) {
                return
            }
        }

        if let error = self.awardError {
            let okAction = (title: "OK", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction) in
                self.awardParsingAndTextFileCreation()
            })

            DispatchQueue.main.async {
                AlertService.showAlertForTopVC(
                    title: "Award Download Error",
                    message: error.localizedDescription,
                    actions: [okAction]
                )
            }
        } else {
            self.awardParsingAndTextFileCreation()
        }
    }
    func awardParsingAndTextFileCreation() {
        let bidAwardText = CBUtils.generateTextForAwardData(
            lineAwardDetails,
            mrtAward: mrtAwardDetails,
            jobShareAward: jobshareAwardDetails,
            reserveData: reserveAwardDetails,
            bidPeriod: bidPeriod
        )

        bidPeriod?.deleteTextFile(text: bidAwardText, name: BIAwardsTextFileName)
        bidPeriod?.addTextFile(text: bidAwardText, name: BIAwardsTextFileName)

        guard let empNo = self.defaultEmplyeeNumber else {return}
        DispatchQueue.main.async {
            self.view.hideActivityIndicator()
        }
        self.awardsViewModel?.getAwardAlertFromServer(empNum: empNo) { success in
        }
    }
    
    
    @objc func showBidAwardReadError(notification: NSNotification){
        let str1 = AlertService.getAttributedMessage(from: notification.object as! String)
        let str2 = AlertService.getAttributedMessage(from: "\n\nPlease make sure that bid awards are available at this time.")
        str1.append(str2)
        DispatchQueue.main.async{
            AlertService.showDBAlert(title: "Awards Retrieval Failed",attributedMessage: str1, from: self)
        }
    }
    
    func handleBidSubmission(sessionKey: String? = nil){
        self.view.hideActivityIndicator()
        print("Submit bid")
        guard let bidPeriod = self.bidPeriod else {
            AlertService.showAlertForTopVC(title: "Submission Error", message: "Bid period is not set.")
            return
        }
            
        var empNum = self.txtUserID.text ?? ""
        if bidPeriod.isFABid() && bidPeriod.isSwaAPI?.boolValue == true{
            if let token = KeychainHelper.retrieveTokenFromKeyChain(),
                let userDetails = JWTDecoder.decode(jwtToken: token),
                let user = userDetails["cn"] as? String{
                    empNum = user
            }
        }
        submissionViewModel = CBBidSubmissionViewModel(bidPeriod: bidPeriod, userID: empNum, password: self.dataSource.password, defaultEmpNum: self.defaultEmplyeeNumber, optionalEmpNum: self.optionalEmployees, selectedObject: self.selectedObject)

        submissionViewModel?.setBidLineNumbers { (success) in
//            self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Submitting Bid...")
            if success{
                DispatchQueue.main.async {
                    self.view.showActivityIndicator(message: "Submitting your bid...")
                }
                self.submissionViewModel?.startBidSubmission(sessionKey: sessionKey) { result in
                    DispatchQueue.main.async {
                        self.view.hideActivityIndicator()
                    }
                    switch result{
                    case .success(let submitted):
                        if submitted{
                            DispatchQueue.main.async {
                                self.view.hideActivityIndicator()
                                
                                AlertService.showAlertForTopVC(title: "Bid Successfully Submitted", message: "The bid receipt shown is the bid receipt for the last bid submitted.\n\n Bid receipts are available under the Bid Action (top right) menu and in SwaLife in BidInfo.\n\n Caution: You must see your bid receipt. If you DON'T see your bid receipt, then \"Please try to submit again\".", actions: [(title: "OK", style: .default, handler:{_ in
                                    
                                    let completion: (Bool) -> Void = { _ in
                                        DispatchQueue.main.async {
                                            self.dismissVC()
                                            NotificationCenter.default.post(name: NSNotification.Name("showBidReceipt"), object: self)
                                            
                                        }
                                    }

                                    if self.bidPeriod?.isFABid() == true {
                                        self.submissionViewModel?.addSubmittedDataToServerForFA(completion: completion)
                                    } else {
                                        self.submissionViewModel?.handleAddSubmittedBid(
                                            empNumber: self.defaultEmplyeeNumber!,
                                            completion: completion
                                        )
                                    }
                                    
                                    
//                                    // ---- PILOT ----
//                                    if !self.bidPeriod!.isFABid(){
//                                        self.submissionViewModel?.handleAddSubmittedBid(empNumber: self.defaultEmplyeeNumber!){success in
//                                            if success{
//                                                self.dismissVC()
//                                            }
//                                        }
//                                        return
//                                    }
//                                    
//                                    // ---- FA ----
//                                    self.submissionViewModel?.addSubmittedDataToServerForFA { success in
//                                        if !success { self.dismissVC() }
//                                    }
                                })])
                            }
                        }

                    case .failure(let error):
                        DispatchQueue.main.async {
                            AlertService.showAlertForTopVC(
                                title: "Submission Failed",
                                message: error.localizedDescription
                            )
                            self.dismissVC()
                        }

                    }
                }
            }
        }
    }
    
    
    

    
    private func checkEarlyBidding(){
        let currentDate = Date()
        let units: Set<Calendar.Component> = [.hour, .day, .month, .year]
        var dc = Calendar.current.dateComponents(units, from: currentDate)
        dc.hour = 12
        dc.timeZone = TimeZone(identifier: "US/Central")!
        var dayString: String? = nil
        if selectedRound == 1{
            if selectedPosition?.shortName == "FA"{
                dc.day = 2
                dayString = "2nd"
            }else{
                dc.day = 4
                dayString = "4th"
            }
        }else{
            if selectedPosition?.shortName == "FA"{
                dc.day = 11
                dayString = "11th"
            }else{
                dc.day = 17
                dayString = "17th"
            }
        }
        let bidReleaseDate: Date? = Calendar.current.date(from: dc)
        if bidReleaseDate?.compare(currentDate) == .orderedDescending {
            if !isHistoricBid{
                DispatchQueue.main.asyncAfter(deadline: .now()+0.3){
                    AlertService.showAlertForTopVC(title: "Early Bid Warning", message: "SWA guarantees that the lines will be released by noon Central Time on the \(dayString!).  Sometimes SWA releases the lines earlier. If SWA has not released the lines early, then attempting to download them now will result in a BID INFO UNAVAILABLE error.  So if you receive this error, try again later.")
                }
                
            }
        }
    }
    
    @objc func dismissVC() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func showPasswordAction(_ sender: UIButton) {
        txtPassword.isSecureTextEntry = !txtPassword.isSecureTextEntry
        let icon = UIImage(named: txtPassword.isSecureTextEntry ? "showPwd" : "hidePwd")
        sender.setImage(icon , for: .normal)
    }
    
    @IBAction func btnBackAction(_ sender: UIButton) {
        
        if isForReauth {
            NotificationCenter.default.post(name: Notification.Name("AuthFlowEnded"), object: nil)
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        if type == .retrieveAwards {
            self.dismiss(animated: true, completion: nil)
            return
        }

        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnGoAction(_ sender: UIButton) {
        UserDefaults.standard.set(txtUserID.text, forKey: KCBEmpNumWithPrefix)
        if type == .retrieveAwards {
            self.retriveAwardsAction()
        }
        else if type == .submitBid {
            self.submitBidAction()
        }else{
            if self.bidAlreadyExists(){
                self.showAlertForExistingBid {
                    self.loginValidation()
                }
            }else{
                self.loginValidation()
            }
        }
    }
    
    func loginValidation(){
        guard reachability.isReachable == true else {
            let alert = AlertService.showAlert(title: Warning, message: NetworkNotAvailable, actions: nil)
            self.present(alert, animated: true)
            return
        }
        guard let rawUserID = txtUserID.text, !rawUserID.isEmpty,
              let password = txtPassword.text, !password.isEmpty else {
            shakeTextField(textField: txtUserID)
            return
        }
        if rawUserID.count < 2 || rawUserID.count > 8 {
            shakeTextField(textField: txtUserID)
            return
        } else if password.count < 4 {
            shakeTextField(textField: txtPassword)
            return
        }
        var formattedUserID = rawUserID
        if !rawUserID.lowercased().hasPrefix("x") && !rawUserID.lowercased().hasPrefix("e") {
            formattedUserID = (rawUserID == DevUserID) ? "x\(rawUserID)" : "e\(rawUserID)"
        }
        txtUserID.text = formattedUserID
        var empID = self.txtUserID.text ?? ""
        if empID.hasPrefix("e") || empID.hasPrefix("x") {
            let userID = String(empID.dropFirst())
            GlobalBidInfo.shared.userid = userID
            CBGlobalMethods.shared.userid = userID
            GlobalBidInfo.shared.password = self.txtPassword.text ?? ""
        }else if !empID.lowercased().hasPrefix("x") && !empID.lowercased().hasPrefix("e") {
            GlobalBidInfo.shared.userid = empID
            CBGlobalMethods.shared.userid = empID
            GlobalBidInfo.shared.password = self.txtPassword.text ?? ""
        }
        if empID.lowercased().hasPrefix("x") || empID.lowercased().hasPrefix("e") {
            empID = String(empID.dropFirst())
        }
        self.checkAuthentication()
    }
        
    
    func checkAuthentication(message: String = "Authentication Checking...") {
        self.view.showActivityIndicator(message: message)
        var dictAuthenticationInfo:[String: Any] = [:]
        
        dictAuthenticationInfo["Platform"] = "iPad"
        dictAuthenticationInfo["OperatingSystem"] = "iPad OS"
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        dictAuthenticationInfo["Version"] = appVersion
        dictAuthenticationInfo["Base"] = GlobalBidInfo.shared.base
        dictAuthenticationInfo["BidRound"] = GlobalBidInfo.shared.round
        dictAuthenticationInfo["Month"] = CBUtils.shortMonthName(month: GlobalBidInfo.shared.month, uc: true)
        dictAuthenticationInfo["Postion"] = CBUtils.shortName(for: GlobalBidInfo.shared.position)
        
        // Historic / Current
        dictAuthenticationInfo["RequestType"] = AppState.shared.isHistoricBid ? 5 : 0
        
//        self.userid = self.txtUserID.text
        let empID = self.userid ?? self.txtUserID.text ?? ""
        
        let formattedEmpID = empID.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .symbols)
        
        dictAuthenticationInfo["EmployeeNumber"] = "\(formattedEmpID)"
        let historySecretEnabled = UserDefaults.standard.string(forKey: "isMaxSubScriptionOfEnteredUser")
        
        if historySecretEnabled == "YES"{
            if let userString = UserDefaults.standard.string(forKey: "SecretVDuserName"),
               let userInt = Int(userString) {
                dictAuthenticationInfo["EmployeeNumber"] = userInt
            }
        }
        
        let userParseID = CBUtils.generateUniqueIdentifier()
        dictAuthenticationInfo["GuidToken"] = userParseID
        
        app.sc?.delegate = self
        webType = .wbidUserCheck
        app.lastDownloadedBidInfo = dictAuthenticationInfo as? NSMutableDictionary
        objDataBuilder.checkAuthentication(&dictAuthenticationInfo)

    }
    
    
        
    private func startAuthentication(empID: String, formattedUserID: String, password: String) {

        AuthService.shared.checkAuthentication(empID: empID) { [weak self] authResult in
            guard let self = self else { return }

            if authResult.isAuthorized || authResult.isSomehowSubscribed || formattedUserID == DevUserID {
                saveSelectionToUserDefaults()
                if webViewloaded{
                    if self.dataSource.position == .FlightAttendant{
                        switch self.type {
                        case .defaultType:
                            self.startBidDownload()
                        case .retrieveAwards:
                            print("FA Award Retrieval")
                            //handle awards
                            self.handleAwardRetrieval()
                        case .submitBid:
                            print("FA Bid submission")
                            self.handleBidSubmission()
                            //handle submission
                        }
                    }
                }else{
                    self.loginViewModel.checkLogin(userID: formattedUserID, password: password)
                }
                
                
            } else {
                self.view.hideActivityIndicator()
                self.loginViewModel.onLoginFailure?(
                    Errors.unauthorized(message: authResult.message ?? "You are not subscribed or authorized.")
                )
            }

        } onFailure: { [weak self] error in
            self?.view.hideActivityIndicator()
            self?.loginViewModel.onLoginFailure?(error)
        }
    }
    
    
    private func saveSelectionToUserDefaults(){
        UserDefaults.standard.set(GlobalBidInfo.shared.base, forKey: kCBCrewBaseDefaultKey)
        UserDefaults.standard.set(GlobalBidInfo.shared.position.rawValue, forKey: kCBCrewPositionTypeDefaultKey)
        UserDefaults.standard.set(GlobalBidInfo.shared.employeeNumber, forKey: kCBEmployeeNumberDefaultKey)
        UserDefaults.standard.set(GlobalBidInfo.shared.round, forKey: kCBCrewRoundTypeDefaultKey)
    }
    

    private func bidAlreadyExists() -> Bool {
        let fileURL = BIBidInfo().bidDocumentFileURL()
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
//    private func bidAlreadyExists() -> Bool {
//        let downloadDir = BIBidInfo().downloadDirectory()
//
//        // Check if the directory exists
//        var isDir: ObjCBool = false
//        let exists = FileManager.default.fileExists(atPath: downloadDir.path, isDirectory: &isDir)
//
//        // Return true only if it exists and is a directory
//        return exists && isDir.boolValue
//    }
    
//    private func showAlertForExistingBid(onRetry: @escaping () -> Void) {
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
//        let entity = NSEntityDescription.entity(forEntityName: "BidPeriod", in: self.context)
//        fetchRequest.entity = entity
//        var array:[NSPredicate] = []
//        array.append(NSPredicate(format: "base == %@", self.dataSource.base))
//        array.append(NSPredicate(format: "round == %d", self.dataSource.round))
//        array.append(NSPredicate(format: "month == %d", self.dataSource.month))
//        array.append(NSPredicate(format: "positionType == %d", self.dataSource.position.rawValue))
//        array.append(NSPredicate(format: "year == %d", self.dataSource.year))
//        
//        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
//        let list = try! self.context.fetch(fetchRequest) as! [BIBidPeriod]
//        
//        let monthArr = ["January", "February", "March", "April", "May", "June", "July", "August","September","October","November","December"]
//        let alert = AlertService.showAlert(title: "Download Bid Again?", message: "The Bid for \(monthArr[dataSource.month-1]) \(dataSource.base) \(dataSource.position) Round \(dataSource.round) already exists. If you download it again, all existing data, including bid receipts, will be removed.", actions: [(title: "Download Again", style: .default, handler: {_ in
//            
//            // Build file path
//            let tempDir = BIBidInfo.temporaryDirectory()
//            let originalFileName = BIBidInfo.shared.dataFilenameBase()
//            let fileURL = tempDir.appendingPathComponent(originalFileName)
//             
//            // Delete the file if it exists
//            let fileManager = FileManager.default
//            if fileManager.fileExists(atPath: fileURL.path) {
//                do {
//                    try fileManager.removeItem(at: fileURL)
//                    print("Deleted file: \(fileURL.lastPathComponent)")
//                } catch {
//                    print("Failed to delete file: \(error.localizedDescription)")
//                }
//            }
//            let context = self.context
//            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = BIBidPeriod.fetchRequest()
//            fetchRequest.predicate = NSPredicate(format: "month == %d AND base == %@ AND positionType == %d AND round == %d AND year == %d",self.dataSource.month, self.dataSource.base, self.dataSource.position.rawValue, self.dataSource.round, self.dataSource.year)
//            let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//            batchDelete.resultType = .resultTypeObjectIDs
//
//            do {
//                let result = try context.execute(batchDelete) as? NSBatchDeleteResult
//                if let objectIDs = result?.result as? [NSManagedObjectID] {
//                    // Merge changes into context so collectionView sees deletion
//                    let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
//                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
//                }
//                NotificationCenter.default.post(name: NSNotification.Name(ReloadCollectionView), object: nil)
//                print("Deleted BidPeriod objects using batch delete.")
//                onRetry()
//            } catch {
//                print("Failed batch delete: \(error)")
//            }
//            
//        }), (title: "Cancel", style: .cancel, handler: {_ in}), (title: "Open Bid", style: .default, handler: {_ in
//            self.view.hideActivityIndicator()
//            if list.count > 0 {
//                let obj = list[0]
//                CBGlobalMethods.shared.selectedBidPeriod = obj
//                UserDefaults.standard.setValue(obj.round!.intValue, forKey: "SelectedRound")
//                self.dismiss(animated: true)
//                self.loginActions()
//            }
//            
//        })])
//        self.present(alert, animated: true)
//    }
    
    private func showAlertForExistingBid(onRetry: @escaping () -> Void) {
        // Fetch existing BidPeriod objects (same as before)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entity = NSEntityDescription.entity(forEntityName: "BidPeriod", in: self.context)
        fetchRequest.entity = entity
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "base == %@", self.dataSource.base))
        predicates.append(NSPredicate(format: "round == %d", self.dataSource.round))
        predicates.append(NSPredicate(format: "month == %d", self.dataSource.month))
        predicates.append(NSPredicate(format: "positionType == %d", self.dataSource.position.rawValue))
        predicates.append(NSPredicate(format: "year == %d", self.dataSource.year))

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let list = (try? self.context.fetch(fetchRequest) as? [BIBidPeriod]) ?? []

        // Build message using bidDocument filename
        let fileURL = BIBidInfo().bidDocumentFileURL()
        let bidFileName = fileURL.deletingPathExtension().lastPathComponent
        let message = "The bid for\n\(bidFileName)\nalready exists. If you download it again, all existing data, including bid receipts, will be removed."

        let alert = AlertService.showAlert(
            title: "Download Bid Again?",
            message: message,
            actions: [
                (title: "Download Again", style: .default, handler: { _ in
                    CBGlobalMethods.shared.selectedBidPeriod = nil
                    CBGlobalMethods.shared.selectedBidPeriodID = nil
                    // Delete the bid document file if present
                    let fileManager = FileManager.default
                    let bidDocURL = BIBidInfo().bidDocumentFileURL()
                    
                    if fileManager.fileExists(atPath: bidDocURL.path) {
                        do {
                            try fileManager.removeItem(at: bidDocURL)
                            print("Deleted bid document file: \(bidDocURL.lastPathComponent)")
                        } catch {
                            print("Failed to delete bid document file: \(error.localizedDescription)")
                        }
                    }

                    // Also remove the temporary data file if your flow uses it (optional)
                     let tempDir = BIBidInfo.temporaryDirectory()
                     let originalFileName = BIBidInfo.shared.dataFilenameBase()
                     let tempFileURL = tempDir.appendingPathComponent(originalFileName)
                     try? fileManager.removeItem(at: tempFileURL)

                    // Batch delete existing BidPeriod objects matching the selection
                    let context = CoreDataManager.shared.persistentContainer.viewContext
                    context.perform {
                        let fetchReq: NSFetchRequest<BIBidPeriod> = BIBidPeriod.fetchRequest()
                        fetchReq.predicate = NSPredicate(format: "month == %d AND base == %@ AND positionType == %d AND round == %d AND year == %d",
                                                        self.dataSource.month,
                                                        self.dataSource.base,
                                                        self.dataSource.position.rawValue,
                                                        self.dataSource.round,
                                                        self.dataSource.year)
//                        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchReq)
//                        batchDelete.resultType = .resultTypeObjectIDs

                        do {
                            let result = try context.fetch(fetchReq) /*as? NSBatchDeleteResult*/
//                            if let objectIDs = result?.result as? [NSManagedObjectID] {
//                                let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
//                                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
//                            }
//                            context.reset()
                            
                            for bid in result {
                                context.delete(bid)
                            }

                            if context.hasChanges {
                                try context.save()
                            }
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: NSNotification.Name(ReloadCollectionView), object: nil)
                                print("Deleted BidPeriod objects using batch delete.")
                                onRetry()
                            }
                        } catch {
                            print("Failed batch delete: \(error)")
                        }
                    }

                }),
                (title: "Cancel", style: .cancel, handler: { _ in
                    self.dismiss(animated: true, completion: nil)
                }),
                (title: "Open Bid", style: .default, handler: { _ in
                    self.view.hideActivityIndicator()
                    if let obj = list.first {
                        CBGlobalMethods.shared.selectedBidPeriod = obj
                        UserDefaults.standard.setValue(obj.round!.intValue, forKey: "SelectedRound")
                        self.dismiss(animated: true)
                        self.loginActions()
                    }
                })
            ]
        )

        self.present(alert, animated: true)
    }
    
    func getAttributedMessage(from text: String, for targetText: String) -> NSMutableAttributedString {
        let messageFont = UIFont.systemFont(ofSize: 20)
        let boldFont = UIFont.boldSystemFont(ofSize: 24)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        let targetRange = (text as NSString).range(of: targetText)
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        attributedString.addAttribute(.font, value: messageFont, range: fullRange)
        if targetRange.location != NSNotFound {
            attributedString.addAttribute(.font, value: boldFont, range: targetRange)
        }
        return attributedString
    }
    func DBAlert(title:String, message:NSAttributedString){
        let vc = UIStoryboard(name: "BidInfo", bundle: nil).instantiateViewController(withIdentifier: "CBAlertVC") as! CBAlertVC
        vc.alertTitle = title
        vc.attributedMessage = message
        
    }
    
//    MARK: login action
    func loginActions(){
        print("called login")
        let context = CoreDataManager.shared.persistentContainer.viewContext

        if let bidID = CBGlobalMethods.shared.selectedBidPeriodID {
            do {
                let bid = try context.existingObject(with: bidID) as! BIBidPeriod
                CBGlobalMethods.shared.selectedBidPeriod = bid
            } catch {
                print("Failed to refetch bid by objectID:", error)
                CBGlobalMethods.shared.selectedBidPeriod = nil
            }
        }

//        let context = CoreDataManager.shared.persistentContainer.viewContext
//                let fetchRequest: NSFetchRequest<BIBidPeriod> = BIBidPeriod.fetchRequest()
//                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]
//                do {
//                    // Fetch bid periods and reverse to show newest first
//                    self.bidPeriodList = try context.fetch(fetchRequest)
////                    CBGlobalMethods.shared.selectedBidPeriod = bidPeriodList[0]
//                } catch {
//                    print("Failed to fetch bid periods: \(error)")
//                    self.bidPeriodList = []
//                }
//        if let selectedID = CBGlobalMethods.shared.selectedBidPeriodID,
//           let selectedBid = try? context.existingObject(with: selectedID) as? BIBidPeriod {
//
//            CBGlobalMethods.shared.selectedBidPeriod = selectedBid
//        } else {
//            // Fallback (only if something went very wrong)
//            CBGlobalMethods.shared.selectedBidPeriod = self.bidPeriodList.first
//        }
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let docVC = storyboard.instantiateViewController(withIdentifier: "CBBidDocumentController") as! CBBidDocumentController
        guard let homeNav = UIApplication.shared.windows.first?.rootViewController as? UINavigationController else { return }
            self.dismiss(animated: false) {
                let transition = CATransition()
                transition.duration = 0.4
                transition.type = .fade
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                homeNav.view.layer.add(transition, forKey: kCATransition)
                homeNav.pushViewController(docVC, animated: false)
            }
    }
    
 
//    MARK: Retrieve Awards Action
    func retriveAwardsAction() {
        guard let rawUserID = txtUserID.text, !rawUserID.isEmpty,
              let password = txtPassword.text, !password.isEmpty else {
            shakeTextField(textField: txtUserID)
            return
        }
        if rawUserID.count < 2 || rawUserID.count > 8 {
            shakeTextField(textField: txtUserID)
            return
        } else if password.count < 4 {
            shakeTextField(textField: txtPassword)
            return
        }
        var formattedUserID = rawUserID
        if !rawUserID.lowercased().hasPrefix("x") && !rawUserID.lowercased().hasPrefix("e") {
            formattedUserID = (rawUserID == DevUserID) ? "x\(rawUserID)" : "e\(rawUserID)"
        }
        txtUserID.text = formattedUserID
        self.view.showActivityIndicator()
        loginViewModel.checkLogin(userID: formattedUserID,password: password)
    }
    
//    MARK: Submit Bid Action
    func submitBidAction() {
        if (txtUserID.text!.count < 2) || (txtUserID.text!.count > 8) {
            self.shakeTextField(textField: txtUserID)
            return
        }else if (txtPassword.text!.count < 4){
            self.shakeTextField(textField: txtPassword)
            return
        }
        let empNum = self.defaultEmplyeeNumber ?? ""
        txtUserID.text = txtUserID.text!.lowercased()
        var txtUserIDString = txtUserID.text!
        if txtUserIDString.hasPrefix("x") || txtUserIDString.hasPrefix("e"){
            txtUserIDString.removeFirst()
        }
        
        if empNum != txtUserIDString && CBGlobalMethods.shared.certified == false{
            // show certify VC
            print("Show certify VC")
            let vc = UIStoryboard(name: "BidActions", bundle: nil).instantiateViewController(withIdentifier: "CBSubmissionCertifyVC") as! CBSubmissionCertifyVC
            vc.submittedEmpNum = empNum
            vc.bidderEmpNum = txtUserIDString
            vc.delegate = self
            vc.modalPresentationStyle = .formSheet
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            if let presentationController = vc.presentationController{
                presentationController.delegate = self
            }
            self.present(vc, animated: true)
            
        }else{
            // Directly submit the bid
            print("Direct bid")
            guard let rawUserID = txtUserID.text, !rawUserID.isEmpty,
                  let password = txtPassword.text, !password.isEmpty else {
                shakeTextField(textField: txtUserID)
                return
            }
            if rawUserID.count < 2 || rawUserID.count > 8 {
                shakeTextField(textField: txtUserID)
                return
            } else if password.count < 4 {
                shakeTextField(textField: txtPassword)
                return
            }
            var formattedUserID = rawUserID
            if !rawUserID.lowercased().hasPrefix("x") && !rawUserID.lowercased().hasPrefix("e") {
                formattedUserID = (rawUserID == DevUserID) ? "x\(rawUserID)" : "e\(rawUserID)"
            }
            txtUserID.text = formattedUserID
            self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Please wait...")
            loginViewModel.checkLogin(userID: formattedUserID,password: password)
        }
    }
    

    
    
    func goActionFromSubmitCertifyDelegate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){
            self.submitBidAction()
        }
    }
    
    
    private func isSecondRoundBid() -> Bool {
        let isSecondRoundBid = dataSource.round == 2
        return isSecondRoundBid
    }
    
    private func isFABid() -> Bool {
        let isFABid = BICrewPositionType.FlightAttendant.rawValue == self.dataSource.position.rawValue
        return isFABid
    }
    
    
    //MARK: User info
    
    func getUserInformation(){
        if app.connectedToInternet(){
            self.view.updateActivityIndicator(message: "Importing User Information...")
            app.sc?.delegate = self
            webType = .importUserDetails
            let userID = self.userid ?? self.txtUserID.text ?? ""
            let formattedUserID = userID.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .symbols)
            objDataBuilder.checkUserExistOrNot(formattedUserID)
        }else{
            AlertService.showAlertForTopVC(title: "Network not available!", message: "Please check your internet connection", actions: nil)
        }
    }
    
    
    
    
}


extension CBCredentialsPageVC: UITextFieldDelegate {
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if textField == txtUserID {
//            txtPassword.becomeFirstResponder()
//        } else if textField == txtPassword {
//            txtPassword.resignFirstResponder()
//            self.loginValidation()
//        }
//        return true
//    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var shouldChangeCharacters: Bool = true
        if textField == txtUserID {
            var validUserid: Bool = true
            let inverseSet = CharacterSet(charactersIn: "0123456789").inverted
            let components = string.components(separatedBy: inverseSet)
            let filtered = components.joined(separator: "")
            if let currentText = textField.text {
                // Allow deletion
                if string.isEmpty {
                    return true
                }
                // Full replacement scenario
                if range.length == currentText.count {
                    if string.hasPrefix("e") || string.hasPrefix("x") {
                        let newStringWithoutPrefix = String(string.dropFirst())
                        let newStringIsValid = newStringWithoutPrefix.rangeOfCharacter(from: inverseSet) == nil
                        if !newStringIsValid {
                            textField.shakeTextField()
                        }
                        return newStringIsValid
                    } else if string.rangeOfCharacter(from: inverseSet) == nil {
                        return true
                    } else {
                        textField.shakeTextField()
                        return false
                    }
                }
                // Prevent extra leading 'e' or 'x'
                if currentText.hasPrefix("e") || currentText.hasPrefix("x") {
                    if string == "e" || string == "x" {
                        textField.shakeTextField()
                        return false
                    }
                    if range.location == 0 {
                        textField.shakeTextField()
                        return false
                    }
                }
            }
            if range.location == 0 {
                validUserid = false
                if string == "" {
                    validUserid = true
                } else if string.count > 0 && ((string.first == "e") || (string.first == "x") || string == filtered) {
                    validUserid = true
                }
            } else {
                let isValid = string == filtered
                if !isValid {
                    textField.shakeTextField()
                }
                return isValid
            }
            if !validUserid {
                textField.shakeTextField()
                shouldChangeCharacters = false
            }
        }
        return shouldChangeCharacters
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Reset both fields to gray first
        txtUserID.layer.borderWidth = 4
        txtUserID.layer.borderColor = UIColor.gray.cgColor
        txtPassword.layer.borderWidth = 4
        txtPassword.layer.borderColor = UIColor.gray.cgColor

        // Then highlight only the active one
        textField.layer.borderWidth = 4
        textField.layer.borderColor = UIColor.purple.cgColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.purple.cgColor
    }
    
    
}

