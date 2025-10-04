//
//  CBCredentialsPageVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit
import CoreData

protocol submissionGoActiondelegate{
    func goActionFromSubmitCertifyDelegate()
}
enum TypeWebServices {
    case wbidUserCheck
    case importUserDetails
    case vacationFileNames
}
class CBCredentialsPageVC: BaseViewController, submissionGoActiondelegate, UIAdaptivePresentationControllerDelegate, ServiceConnectionDelegate {
    func responseError(_ errMsg: String) {
        print("responseError")
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
                dicWBAuthorizationDetails = NSMutableDictionary(dictionary: userArray.first!, copyItems: true) as! [String : Any]
                enteredEmpNo = self.userid?.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .symbols)
                historySecretEnabled = UserDefaults.standard.string(forKey: "isMaxSubScriptionOfEnteredUser")
                
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
                        AlertService.showAlertForTopVC(title: "Oops!", message: message, actions: [
                            (title: "Cancel", style: .cancel, handler: { _ in
                                self.dismiss(animated: true)
                            }),
                            (title: "Go to App Store", style: .default, handler: { _ in
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
                    var empID = self.txtUserID.text ?? ""
                    if empID.lowercased().hasPrefix("e") || empID.lowercased().hasPrefix("x") {
                        empID = String(empID.dropFirst())
                    }
                    let formattedUserID = self.txtUserID.text ?? ""
                    let password = self.txtPassword.text ?? ""
                    if !UserDefaults.standard.bool(forKey: "isSecretForAllDomicileDownloadEnabled") {
                        if self.bidAlreadyExists() {
                            self.showAlertForExistingBid {
                                self.startAuthentication(empID: empID, formattedUserID: formattedUserID, password: password)
                            }
                        } else {
                            self.startAuthentication(empID: empID, formattedUserID: formattedUserID, password: password)
                        }
                    }else{
                        self.startAuthentication(empID: empID, formattedUserID: formattedUserID, password: password)
                    }
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
    
    func showUserAccountView(){
        print("Show user account screen")
        let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "userAccountViewController") as! userAccountViewController
        vc.isfrom = self
//        vc.btnBack.setImage(UIImage(named: "NewBid-navbar-ncelbutton"), for: .normal)
        vc.preferredContentSize = CGSize(width: 764, height: 630)
        if let pc = vc.presentationController {
            pc.delegate = self
        }
        self.present(vc, animated: true)
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if presentationController.presentedViewController is userAccountViewController {
            // After user account is dismissed, authenticate again and continue flow
            self.checkAuthentication(message: "Authenticating...")
        }
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
    let reachability = try? Reachability()
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
    var type:String?
    var bidPeriod: BIBidPeriod?
    let loginViewModel = CBLoginViewModel()
    let bidDownloadViewModel = BIBidFileDownloadViewModel()
    let context = CoreDataManager.shared.managedObjectContext
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        if let bidPeriod = CBGlobalMethods.shared.selectedBidPeriod {
            awardsViewModel = AwardsViewModel(bidPeriod: bidPeriod)
        }
        if type == "Retrieve Awards" {
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
        if !UserDefaults.standard.bool(forKey: "isSecretForAllDomicileDownloadEnabled") {
            NotificationCenter.default.addObserver(self, selector: #selector(showProgressView), name: Notification.Name("ShowProgressView"), object: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
            NotificationCenter.default.addObserver(self, selector: #selector(closeCredentilaPage), name: Notification.Name("CloseCredentilaPage"), object: nil)
        }
    
    @objc func closeCredentilaPage() {
            self.navigationController?.popViewController(animated: true)
        }
    
    @objc func showProgressView() {
        let progressVC = UIStoryboard(name: "BidInfo", bundle: nil).instantiateViewController(withIdentifier: "CBProgressVC") as! CBProgressVC
        self.navigationController?.pushViewController(progressVC, animated: true)
    }
    
    func setupTitle(){
        if type == "Retrieve Awards" {
            lblTitle.text = "Retrieve Awards"
        }
        else if type == "Submit Bid" {
            lblTitle.text = "Submit Bid"
        }
        else if isHistoricBid {
            lblTitle.text = "Historic Bid Data"
        } else {
            lblTitle.text = "New Bid Data"
        }
    }

    func setupUI(){
        setupTitle()
        checkEarlyBidding()
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
            if self.type == "Retrieve Awards"{
                self.handleAwardRetrieval(sessionKey: sessionKey)
            }
            else if self.type == "Submit Bid"{
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
            if errorString.contains("login failed") || errorString.contains("security purposes"){
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
        //-----------------------
        
        
        
        
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
            
        }else if AppState.shared.isMockData{//MARK:  Mock Bid Data
            
            print("Bid: Mock data")
            
        }
        //MARK:  Bulk Data
        if UserDefaults.standard.bool(forKey: "isSecretForAllDomicileDownloadEnabled") == true {
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
            self.allbidDownloadViewModel.downladAllDomicileBid(bases: initialbases, tableViewData: tableViewData)
        }
        
        else{//MARK:  New Bid Data
            
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
                    NotificationCenter.default.post(name: Notification.Name("DownloadingBid"), object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        BIBidInfoReader.shared.checkForSeniorityVacationAndReadBidInfo() { success in
                            if success {
                                self.loginActions()
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
        NotificationCenter.default.post(name: Notification.Name("DownloadingBid"), object: nil)
        
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
    }
    
    
    
    func handleAwardRetrieval(sessionKey: String){
        print("Award retrieval")
        let bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        let empNum = bidPeriod?.crewIdentifier?.stringValue
        CBGlobalMethods.shared.secretKey = sessionKey
        awardsViewModel?.retrieveAwardFile(){ result in
            DispatchQueue.main.async{
                self.dismiss(animated: false) {
                    if self.awardsViewModel?.bidPeriod.awardString != nil {
                        var emp = ""
                        if (CBGlobalMethods.shared.awardLertSecretEmpNum?.length ?? 0 > 0) {
                            emp = CBGlobalMethods.shared.awardLertSecretEmpNum!;
                        } else {
                            emp = empNum!
                        }
                        self.awardsViewModel?.getAwardAlertFromServer(empNum: emp) { finished in
                            print("success")
                            CBGlobalMethods.shared.awardLertSecretEmpNum = nil;
                            
                        }
                        NotificationCenter.default.post(name: Notification.Name("AwrdFileRetrieved"), object: nil)
                    }
                }
            }
            
            
        }
    }
    
    func handleBidSubmission(sessionKey: String){
        self.view.hideActivityIndicator()
        print("Submit bid")
        if let bidPeriod = CBGlobalMethods.shared.selectedBidPeriod {
            submissionViewModel = CBBidSubmissionViewModel(bidPeriod: bidPeriod, userID: self.txtUserID.text!, password: self.txtPassword.text!, defaultEmpNum: self.defaultEmplyeeNumber!, optionalEmpNum: self.optionalEmployees)
        }
//        submissionViewModel?.setBidLineNumbers { (success) in
//            self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Submitting Bid...")
//            if success{
//                self.submissionViewModel?.startBidSubmission(sessionKey: sessionKey) { result in
//                    self.view.hideActivityIndicator()
//                    switch result{
//                    case .success(let dataString):
//                        self.bidPeriod?.addBidReceiptWithText(bidReceiptText: dataString)
//                        AlertService.showAlertForTopVC(title: "Bid Successfully Submitted", message: "The bid receipt shown is the bid receipt for the last bid submitted.\n\n Bid receipts are available under the Bid Action (top right) menu and in SwaLife in BidInfo.\n\n Caution: You must see your bid receipt. If you DON'T see your bid receipt, then \"Please try to submit again\".", actions: [(title: "OK", style: .default, handler:{_ in
//                            self.submissionViewModel?.handleAddSubmittedBid(empNumber: self.defaultEmplyeeNumber!){result in
//                                if result == false{
//                                    self.dismissVC()
//                                }
//                            }
//                        })])
//                    case .failure(let error): print(error.localizedDescription)
//                        
//                    }
//                    
//                }
//            }
//        }
        
       
        
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
                let alert = AlertService.showAlert(title: "Early Bid Warning", message: "SWA guarantees that the lines will be released by noon Central Time on the \(dayString!).  Sometimes SWA releases the lines earlier. If SWA has not released the lines early, then attempting to download them now will result in a BID INFO UNAVAILABLE error.  So if you receive this error, try again later.", actions: nil)
                self.present(alert, animated: true)
                
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
        if type == "Retrieve Awards" {
              self.dismiss(animated: true, completion: nil)
          }
          else {
              self.navigationController?.popViewController(animated: true)
          }
    }
    
    @IBAction func btnGoAction(_ sender: UIButton) {
        UserDefaults.standard.set(txtUserID.text, forKey: KCBEmpNumWithPrefix)
        if type == "Retrieve Awards" {
            self.retriveAwardsAction()
        }
        else if type == "Submit Bid" {
            self.submitBidAction()
        }else{
            self.loginValidation()
        }
    }
    func loginValidation(){
        guard reachability?.isReachable == true else {
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
        }else if !empID.lowercased().hasPrefix("x") && !empID.lowercased().hasPrefix("e") {
            GlobalBidInfo.shared.userid = empID
            CBGlobalMethods.shared.userid = empID
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
        if AppState.shared.isHistoricBid{
         dictAuthenticationInfo["RequestType"] = 5
        }else{
            dictAuthenticationInfo["RequestType"] = 0
        }
        dictAuthenticationInfo["Month"] = CBUtils.shortMonthName(month: GlobalBidInfo.shared.month, uc: true)
        dictAuthenticationInfo["Postion"] = CBUtils.shortName(for: GlobalBidInfo.shared.position)
        self.userid = self.txtUserID.text
        
        let formattedEmpID = self.userid?.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .symbols)
        
        dictAuthenticationInfo["EmployeeNumber"] = "\(formattedEmpID!)"
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
//        self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Authentication Checking...")

        AuthService.shared.checkAuthentication(empID: empID) { [weak self] authResult in
            guard let self = self else { return }

            if authResult.isAuthorized, authResult.isSomehowSubscribed || formattedUserID == DevUserID {
                self.loginViewModel.checkLogin(userID: formattedUserID, password: password)
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
        //--Login action--
//        if bidAlreadyExists(){
//            showAlertForExistingBid{
//                self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Please wait...")
//                self.loginViewModel.checkLogin(userID: formattedUserID,password: password)
//            }
//        }else{
//            self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Please wait...")
//            loginViewModel.checkLogin(userID: formattedUserID,password: password)
//            
//        }
        //----------------
    

    private func bidAlreadyExists() -> Bool {
        var status = false
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entity = NSEntityDescription.entity(forEntityName: "BidPeriod", in: self.context)
        fetchRequest.entity = entity
        var array:[NSPredicate] = []
        array.append(NSPredicate(format: "base == %@", self.dataSource.base))
        array.append(NSPredicate(format: "round == %d", self.dataSource.round))
        array.append(NSPredicate(format: "month == %d", self.dataSource.month))
        array.append(NSPredicate(format: "positionType == %d", self.dataSource.position.rawValue))
        array.append(NSPredicate(format: "year == %d", self.dataSource.year))
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        let list = try! self.context.fetch(fetchRequest) as! [BIBidPeriod]
        if list.count > 0 {
            status = true
        }
        return status
    }
    
    private func showAlertForExistingBid(onRetry: @escaping () -> Void) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entity = NSEntityDescription.entity(forEntityName: "BidPeriod", in: self.context)
        fetchRequest.entity = entity
        var array:[NSPredicate] = []
        array.append(NSPredicate(format: "base == %@", self.dataSource.base))
        array.append(NSPredicate(format: "round == %d", self.dataSource.round))
        array.append(NSPredicate(format: "month == %d", self.dataSource.month))
        array.append(NSPredicate(format: "positionType == %d", self.dataSource.position.rawValue))
        array.append(NSPredicate(format: "year == %d", self.dataSource.year))
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        let list = try! self.context.fetch(fetchRequest) as! [BIBidPeriod]
        
        let monthArr = ["January", "February", "March", "April", "May", "June", "July", "August","September","October","November","December"]
        let alert = AlertService.showAlert(title: "Download Bid Again?", message: "The Bid for \(monthArr[dataSource.month-1]) \(dataSource.base) \(dataSource.position) Round \(dataSource.round) already exists. If you download it again, all existing data, including bid receipts, will be removed.", actions: [(title: "Download Again", style: .default, handler: {_ in
            
            // Build file path
            let tempDir = BIBidInfo.temporaryDirectory()
            let originalFileName = BIBidInfo.shared.dataFilenameBase()
            let fileURL = tempDir.appendingPathComponent(originalFileName)
             
            // Delete the file if it exists
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    print("Deleted file: \(fileURL.lastPathComponent)")
                } catch {
                    print("Failed to delete file: \(error.localizedDescription)")
                }
            }
            if list.count > 0 {
                let obj = list[0]
                self.context.delete(obj)
                do {
                    try self.context.save()
                } catch {
                    print("Failed to save context after deletion: \(error)")
                }
                NotificationCenter.default.post(name: NSNotification.Name(ReloadCollectionView), object: nil)
                onRetry()
            }
            
        }), (title: "Cancel", style: .cancel, handler: {_ in}), (title: "Open Bid", style: .default, handler: {_ in
            if list.count > 0 {
                let obj = list[0]
                CBGlobalMethods.shared.selectedBidPeriod = obj
                UserDefaults.standard.setValue(obj.round!.intValue, forKey: "SelectedRound")
                self.dismiss(animated: true)
                self.loginActions()
//                NotificationCenter.default.post(name: NSNotification.Name("openBidPeriodFromDownloadPage"), object: nil)
            }
            
        })])
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
        let context = self.dataSource.managedObjectContext
                let fetchRequest: NSFetchRequest<BIBidPeriod> = BIBidPeriod.fetchRequest()
                do {
                    // Fetch bid periods and reverse to show newest first
                    self.bidPeriodList = try context.fetch(fetchRequest).reversed()
                    CBGlobalMethods.shared.selectedBidPeriod = bidPeriodList[0]
                } catch {
                    print("Failed to fetch bid periods: \(error)")
                    self.bidPeriodList = []
                }
        CBUserAccountDetail.shared.saveUserInfo()
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let docVC = storyboard.instantiateViewController(withIdentifier: "CBBidDocumentController") as! CBBidDocumentController
        docVC.modalTransitionStyle = .crossDissolve
        if let homeNav = UIApplication.shared.windows.first?.rootViewController as? UINavigationController {
            self.dismiss(animated: false) {
                homeNav.pushViewController(docVC, animated: true)
            }
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
            let formattedUserID = txtUserID.text!.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .symbols)
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

