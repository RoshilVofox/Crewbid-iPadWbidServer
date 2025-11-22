//
//  CBWebViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 08/11/25.
//

import UIKit
import WebKit
import CoreData



class CBWebViewCredentialPageVC: BaseViewController,WKNavigationDelegate/*, ServiceConnectionDelegate*/ {
    
//    var webType:TypeWebServices?
//    var isWbidUserExist: Bool = false
//    var dicWbidResponce: [String: Any] = [:]
//    var dicWBAuthorizationDetails: [String: Any] = [:]
//    func responseError(_ errMsg: String) {
//        <#code#>
//    }
//    
//    func serviceResponse(_ arrResponse: [Any]) {
//        var value: Int = 0
//        var enteredEmpNo: String?
//        var historySecretEnabled: String?
//        let userArray = arrResponse as! [[String: Any]]
//        print(arrResponse.description)
//        if arrResponse.count > 0{
//            switch webType {
//            case .wbidUserCheck:
//                dicWBAuthorizationDetails = NSMutableDictionary(dictionary: userArray.first!, copyItems: true) as! [String : Any]
//                enteredEmpNo = self.userid?.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .symbols)
//                historySecretEnabled = UserDefaults.standard.string(forKey: "isMaxSubScriptionOfEnteredUser")
//                
//                if historySecretEnabled == "YES"{
//                    app.ObjUserAccount?.LoginuserId = UserDefaults.standard.string(forKey: "SecretVDuserName")!
//                    app.ObjUserAccount?.saveUserInfo()
//                    enteredEmpNo = app.ObjUserAccount?.LoginuserId
//                    app.ObjUserAccount?.dicLogInAuthExternalUser = NSMutableDictionary(dictionary: dicWBAuthorizationDetails, copyItems: true)
//                }
//                if enteredEmpNo == app.ObjUserAccount?.employeeNumber{
//                    let secretEnabled = UserDefaults.standard.string(forKey: "isSecretVDSwitchEnabled")
//                    if secretEnabled == "YES"{
//                        app.ObjUserAccount?.dicLogInAuthExternalUser = NSMutableDictionary(dictionary: dicWBAuthorizationDetails, copyItems: true)
//                    }
//                    app.isNeedToDownloadSeniorityFromServer = userArray.first?["IsNeedToDownloadSeniorityFromServer"] as! Bool
//                    app.ObjUserAccount?.topSubscriptionLine = userArray.first?["TopSubscriptionLine"] as! String
//                    app.ObjUserAccount?.secondSubscriptionLine = userArray.first?["SecondSubscriptionLine"] as! String
//                    app.ObjUserAccount?.thirdSubscriptionLine = userArray.first?["ThirdSubscriptionLine"] as! String
//                    app.ObjUserAccount?.saveUserInfo()
//                }
//                
//                
//                
//                let type = (userArray.first?["Type"] as? String)?.lowercased() ?? ""
//                let message = userArray.first?["Message"] as? String ?? ""
//
//                if type == "biddownloadblocked" {
//                    DispatchQueue.main.async {
//                        AlertService.showAlertForTopVC(title: "Oops!", message: message, actions: [(title: "OK", style: .default, handler: { _ in
//                            self.dismiss(animated: true)
//                        })])
//                    }
//                    break
//                } else if type == "invalid version" {
//                    DispatchQueue.main.async {
//                        self.view.hideActivityIndicator()
//                        AlertService.showAlertForTopVC(title: "Oops!", message: message, actions: [
//                            (title: "Cancel", style: .cancel, handler: { _ in
//                                self.dismiss(animated: true)
//                            }),
//                            (title: "Go to AppStore", style: .default, handler: { _ in
//                                if let url = URL(string: "https://itunes.apple.com/us/app/crewbid/id563832596?mt=8") {
//                                    UIApplication.shared.open(url)
//                                }
//                                self.dismiss(animated: true)
//                            })
//                        ])
//                    }
//                    break
//                }
//                let hasLocalUserInfo = CBUtils.isLocalUserInformationAvailable()
//                if hasLocalUserInfo {
//                    var empID = self.userid ?? ""
//                    if empID.lowercased().hasPrefix("e") || empID.lowercased().hasPrefix("x") {
//                        empID = String(empID.dropFirst())
//                    }
//                    let formattedUserID = self.userid ?? ""
//                    let password = self.txtPassword.text ?? ""
//                        self.startAuthentication(empID: empID, formattedUserID: formattedUserID, password: password)
//                } else {
//                    if let account = KeychainHelper.retrieveUsername(forService: "CWAUserAccountDetails"){
//                        KeychainHelper.delete(account: account, service: "CWAUserAccountDetails")
//                    }
//                    // Import existing account data
//                    self.getUserInformation()
//                }
//
//            case .importUserDetails:
//                self.view.hideActivityIndicator()
//                let empNum = userArray.first?["EmpNum"] as? Int
//                value = empNum!
//                
//                if value != 0 {
//                    dicWbidResponce = NSMutableDictionary(dictionary: userArray.first!, copyItems: true) as! [String : Any]
//                    localAccountCreation()
//                    updateCBExpirationDate()
//                    
//                    app.ObjUserAccount?.captureUserEmail(app.ObjUserAccount?.email)
//                    AlertService.showAlertForTopVC(title: "Great!", message: "We found a previous account from CrewBid or WbidMax.\nWe've imported those settings.\nPlease verify the settings and change as needed", actions: [(title: "OK", style: .default, handler:{_ in
//                        if self.isImportedinMacOS(){
//                            self.sendMacImportedLog()
//                        }
//                        self.showUserAccountView()
//                    })])
//                }else{
//                    AlertService.showAlertForTopVC(title: "No Existing Account", message: "We checked, but no previous account exists for you.\n\nThe next view will let you create your account.", actions: [(title: "Go To Create Account", style: .default, handler:{_ in
//                        self.app.ObjUserAccount?.deleteUserAccount()
//                        self.app.createEmpNo = self.txtUserID.text //need to check
//                        self.showUserAccountView()
//                    })])
//                }
//                break
//            case .vacationFileNames:
//                let dicFileNames = userArray[0]
//                if let fileNames = dicFileNames["FileNames"] as? [Any] {
//                    let arrVacationList = fileNames.map { $0 }
//                    if !arrVacationList.isEmpty {
//                        app.ObjUserAccount?.arrVacationList = arrVacationList
//                        }
//                    }
//                break
//            case nil:break
//    
//            }
//        }
//        
//    }
//    
//    func responseStatus(_ responseStatus: Int) {
//        <#code#>
//    }
//    
//    func connectionFailed() {
//        <#code#>
//    }
//    
//    func requestFailed() {
//        <#code#>
//    }
//    
//    func connectionDataReceived(_ progress: Float) {
//        <#code#>
//    }
    

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var backBtn: UIButton!
    var selectedRound:Int?
    var isHistoricBid : Bool = false
    var userid:String?
    var empNum : String?
    var selectedDomicile : String?
    var month :  Int?
    var year:Int?
    var webViewloaded = false
    private var clientID: String = "p502838"
    private var redirectURI: String = ""
    private var authorizationEndpoint: String = ""
    private var tokenEndpoint: String = ""
    private var codeVerifier: String = ""
    let viewModel = BISwaBidDataDownloadViewModel()
    var bidPeriod: BIBidPeriod?
    var empID = String()
    let reachability : Reachability = try! Reachability()
    var env = ""
    var tokenexpiredFA = false
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter
    }()
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if app.connectedToInternet(){
            self.view.showActivityIndicator(message: "Loading SWA Login...")
        }else{
            AlertService.showAlertForTopVC(title: "No Internet Connection", message: "An internet connection is required to Login. Please connect to the internet and try again.")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkEarlyBidding()
        var apiEnv = UserDefaults.standard.string(forKey: "SwaApiEnv")
        apiEnv = "QA"
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
            startAuthFlow()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged), name: NSNotification.Name("ReachabilityChanged"), object: nil)
        if !UserDefaults.standard.bool(forKey: "isSecretForAllDomicileDownloadEnabled") {
            NotificationCenter.default.addObserver(self, selector: #selector(showProgressView), name: Notification.Name("ShowProgressView"), object: nil)
        }
    }
    @objc func showProgressView() {
        let progressVC = UIStoryboard(name: "BidInfo", bundle: nil).instantiateViewController(withIdentifier: "CBProgressVC") as! CBProgressVC
        self.navigationController?.pushViewController(progressVC, animated: true)
    }
    
    private func checkEarlyBidding(){
        let currentDate = Date()
        let units: Set<Calendar.Component> = [.hour, .day, .month, .year]
        var dc = Calendar.current.dateComponents(units, from: currentDate)
        dc.hour = 12
        dc.timeZone = TimeZone(identifier: "US/Central")!
        var dayString: String? = nil
        if selectedRound == 1{
            dc.day = 2
            dayString = "2nd"
        }else{
            dc.day = 11
            dayString = "11th"
        }
        let bidReleaseDate: Date? = Calendar.current.date(from: dc)
        if bidReleaseDate?.compare(currentDate) == .orderedDescending {
            if !isHistoricBid{
                let alert = AlertService.showAlert(title: "Early Bid Warning", message: "SWA guarantees that the lines will be released by noon Central Time on the \(dayString!).  Sometimes SWA releases the lines earlier. If SWA has not released the lines early, then attempting to download them now will result in a BID INFO UNAVAILABLE error.  So if you receive this error, try again later.", actions: nil)
                self.present(alert, animated: true)
            }
        }
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ReachabilityChanged"), object: nil)
    }
    
    
    
    @objc func networkStatusChanged(){
        if reachability.connection == .unavailable{
            AlertService.showAlertForTopVC(title: "No Internet Connection", message: "Your internet connection is interrupted. Please connect to the internet and try again.")
        }
    }
    
    
    func startAuthFlow(){
        if let url = createAuthURL(){
            webView.navigationDelegate = self
            webView.load(URLRequest(url: url))
        }
    }
    
    
    private func createAuthURL() -> URL?{
        codeVerifier = generateCodeVerifier()
        guard let codeChallenge = generateCodeChallenge(from: codeVerifier) else {return nil}
        
        var components = URLComponents(string: authorizationEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "prompt", value: "login"),
            URLQueryItem(name: "scope", value: "openid email profile address phone")
        ]
        return components?.url
    }
    
    private func generateCodeVerifier() -> String{
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<128).compactMap { _ in characters.randomElement() })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        let hashData = Data(hash)
        let base64String = hashData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return base64String
    }
    
    private func exchangeCodeForToken(authCode: String) {
        webViewloaded = true
        let urlString = tokenEndpoint
        let grantType = "grant_type=authorization_code"
        let codeParam = "&code=\(authCode)"
        let redirectURIParam = "&redirect_uri=\(self.redirectURI)"
        let clientIDParam = "&client_id=\(self.clientID)"
        let codeVerifierParam = "&code_verifier=\(self.codeVerifier)"
        let audience1 = "&aud=aud://sso.fed.\(env).aws.swacorp.com/cbna/p502553"
        let audience2 = "&aud=aud://sso.fed.\(env).aws.swacorp.com/cbna/p502552"
        let audience3 = "&aud=aud://sso.fed.\(env).aws.swacorp.com/cbna/p502554"
        
        let body = "\(grantType)\(codeParam)\(redirectURIParam)\(clientIDParam)\(codeVerifierParam)\(audience1)\(audience2)\(audience3)"
        let bodyData = body.data(using: .utf8)
        
        APIService.shared.fetch(
            urlString: urlString,
            method: .POST,
            body: bodyData,
            headers: ["Content-Type":"application/x-www-form-urlencoded"],
            parse: { data in
                let jsonResponse = try JSONSerialization.jsonObject(with: data) as! [String:Any]
                return jsonResponse
            },
            completion: { result in
                switch result{
                case .success(let response):
                    let token = response["access_token"] as! String
                    self.saveToKeychain(token: token)
                    
                case .failure(let error):
                    AlertService.showAlertForTopVC(title: "Authentication Failed", message: error.localizedDescription)
                    print("Error: \(error.localizedDescription)")
                }
            })
    }
    
    private func saveToKeychain(token: String){
        let userDetail = JWTDecoder.decode(jwtToken: token)!
        
        let group = userDetail["groups"] as! String
        
        if !group.contains("Attendant"){
            AlertService.showAlertForTopVC(title: "Authentication Failed", message: "You are attempting to log in with Pilot credentials. Please use valid Flight Attendant credentials instead.")
            return
        }
        
        let tokenData = token.data(using: .utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "BearerToken"
        ]
        
        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound {
            print("Keychain item deleted (or not found). Proceeding to add the new token.")
        } else {
            print("Failed to delete Keychain item, error code: \(deleteStatus)")
            return
        }
        // Add the new token
        var addQuery = query
        addQuery[kSecValueData as String] = tokenData

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess {
            print("Token saved successfully!")
            
            DispatchQueue.main.async {
                self.stopWebViewOperations()
                
                self.viewModel?.onDownloadError = { [weak self] error in
                    self?.handleDownloadError(error)
                }
                NotificationCenter.default.post(name: Notification.Name("ShowProgressView"), object: nil)
                self.checkAuthenticationAndStartDownload()
            }
        }
    }
    
    func checkAuthenticationAndStartDownload(){
        
        if app.connectedToInternet(){
            switch app.objNetworkType {
            case .ground:
//                self.checkAuthentication()
                break
            case .free:
                break
            case .paid:
                break
            }
        }
        
        
        self.viewModel?.startBidInfoDownload(){ result in
            DispatchQueue.main.async {
                switch result{
                case .success(()):
                    print("Historic Bid download complete — navigating")
                    self.loginActions()
                case .failure(let error):
                    print("Historic bid download failed: \(error.localizedDescription)")
                    AlertService.showAlertForTopVC(title: "Error", message: "Failed to download bid data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkAuthentication(message: String = "Authentication Checking...") {
        self.view.showActivityIndicator(message: message)
//        var dictAuthenticationInfo:[String: Any] = [:]
//        
//        dictAuthenticationInfo["Platform"] = "iPad"
//        dictAuthenticationInfo["OperatingSystem"] = "iPad OS"
//        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
//        dictAuthenticationInfo["Version"] = appVersion
//        dictAuthenticationInfo["Base"] = GlobalBidInfo.shared.base
//        dictAuthenticationInfo["BidRound"] = GlobalBidInfo.shared.round
//        if AppState.shared.isHistoricBid{
//         dictAuthenticationInfo["RequestType"] = 5
//        }else{
//            dictAuthenticationInfo["RequestType"] = 0
//        }
//        dictAuthenticationInfo["Month"] = CBUtils.shortMonthName(month: GlobalBidInfo.shared.month, uc: true)
//        dictAuthenticationInfo["Postion"] = CBUtils.shortName(for: GlobalBidInfo.shared.position)
////        self.userid = self.txtUserID.text
//        
//        let formattedEmpID = self.userid?.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .symbols)
//        
//        dictAuthenticationInfo["EmployeeNumber"] = "\(formattedEmpID!)"
//        let historySecretEnabled = UserDefaults.standard.string(forKey: "isMaxSubScriptionOfEnteredUser")
//        
//        if historySecretEnabled == "YES"{
//            if let userString = UserDefaults.standard.string(forKey: "SecretVDuserName"),
//               let userInt = Int(userString) {
//                dictAuthenticationInfo["EmployeeNumber"] = userInt
//            }
//        }
//        
//        let userParseID = CBUtils.generateUniqueIdentifier()
//        dictAuthenticationInfo["GuidToken"] = userParseID
//        
//        app.sc?.delegate = self
//        webType = .wbidUserCheck
//        app.lastDownloadedBidInfo = dictAuthenticationInfo as? NSMutableDictionary
//        objDataBuilder.checkAuthentication(&dictAuthenticationInfo)
    }
    
    
    var bidPeriodList:[BIBidPeriod] = []
    func loginActions(){
        print("called login")
        let context = CoreDataManager.shared.persistentContainer.viewContext
                let fetchRequest: NSFetchRequest<BIBidPeriod> = BIBidPeriod.fetchRequest()
                do {
                    // Fetch bid periods and reverse to show newest first
                    self.bidPeriodList = try context.fetch(fetchRequest).reversed()
                    CBGlobalMethods.shared.selectedBidPeriod = bidPeriodList[0]
                } catch {
                    print("Failed to fetch bid periods: \(error)")
                    self.bidPeriodList = []
                }
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
    
    
    func handleDownloadError(_ error: NSError) {
        if isAllDomicelEnabled() {
            var parameters: [String: Any] = [:]
            parameters["errorInfo"] = error.localizedDescription
            NotificationCenter.default.post(
                name: Notification.Name("BidDownloadError"),
                object: parameters
            )
        } else {
            let attrString = AlertService.getAttributedMessage(from: error.localizedDescription, highlight: "Bid Download Error")
            DispatchQueue.main.async {
                AlertService.showDBAlert(title: "Bid Download Error!", attributedMessage: attrString, from: self)
            }
        }
    }
    
    func isAllDomicelEnabled() -> Bool {
        if let secretDownloadAllDomicileEnabled = UserDefaults.standard.string(forKey: "isSecretForAllDomicileDownloadEnabled") {
            return secretDownloadAllDomicileEnabled == "YES"
        }
        return false
    }

//    func startBidInfoDownload(){
//        print("Bid download started")
//        // For SWA PKCE Auth
//        let token = KeychainHelper.retrieveTokenFromKeyChain()
//        let userDetails = JWTDecoder.decode(jwtToken: token!)!
//        self.userid = userDetails["cn"] as? String
//        
//        let daysOnFreeTrial = 0
//        let daysLeft = 0
//        let Entered_Emp_No = ""
//        
//        
//        if app.connectedToInternet(){
//            switch app.objNetworkType {
//            case .ground:
//                self.checkAuthentication()
//            case .free:
//                break
//            case .paid:
//                break
//            }
//        }
//    }
    
//    private func checkAuthentication(){
//        switch app.objNetworkType {
//        case .free:AlertService.showAlertForTopVC(title: "Cannot Download!", message: "You cannot access this service via SouthwestWifi or 2Wire. Please try again later when you’re safely on the ground and connected to another internet network.")
//            break
//        default: break
//        }
//        self.view.showActivityIndicator()
//        
//    }
    
    
    func stopWebViewOperations(){
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        print("Stopped WebView operations.")
    }
    

    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.absoluteString.contains("code="),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                let queryItems = components.queryItems ?? []
                if let authCode = queryItems.first(where: { $0.name == "code" })?.value {
                    exchangeCodeForToken(authCode: authCode)
                    decisionHandler(.cancel)
                    return
                }
            }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        backBtn.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webViewloaded = true
        backBtn.isHidden = false

        let js = """
        (function() {
            var errorEl = document.querySelector('.ping-error');
            var usernameEl = document.querySelector('#username');
            var errorMsg = errorEl ? errorEl.textContent.trim() : null;
            var usernameVal = usernameEl ? usernameEl.value : null;
            return { error: errorMsg, username: usernameVal };
        })();
        """
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                print("JavaScript evaluation error: \(error)")
                return
            }

            if let dict = result as? [String: Any] {

//                self.logFailedAuthenticationDetails(dict)
                
            } else if result != nil {
                print("JS result: \(String(describing: result))")
            } else {
                print("No result returned from JS")
            }
        }
        self.view.hideActivityIndicator()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.webViewloaded = true
        self.view.hideActivityIndicator()
        backBtn.isHidden = false

    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.webViewloaded = true
        self.view.hideActivityIndicator()
        backBtn.isHidden = false

    }
}
