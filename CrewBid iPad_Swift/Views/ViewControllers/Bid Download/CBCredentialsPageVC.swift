//
//  CBCredentialsPageVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

class CBCredentialsPageVC: BaseViewController {

    
    
    @IBOutlet weak var txtUserID: customUITextField!
    @IBOutlet weak var txtPassword: customUITextField!
    @IBOutlet weak var showPasswordBtn: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    var bidDownload = BIBidFileDownload()
    let reachability = try? Reachability()
    var isHistoricBid : Bool = false
    var isNewBid:Bool = false
    var selectedRound:Int?
    var selectedPosition:String?
    var selectedDomicile:String?
    var empNum:String?
    var month:Int?
    var year:Int?
    var userid:String?
    var password:String?
    var objUserAccount:CBUserAccountDetail!
    var loginType:LoginType = .newBid
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if CBUtils.isRunningOnSimulator(){
            self.txtUserID.text = DevUserID
            self.txtPassword.text = DevUserPassword
        }
    }
    
    func setupUI(){
        txtUserID.delegate = self
        txtPassword.delegate = self
        txtUserID.textContentType = .username
        txtPassword.textContentType = .password
        if isHistoricBid == true {
            lblTitle.text = "Historic Bid Data"
        }else{
            lblTitle.text = "New Bid Data"
        }
        showPasswordBtn.setImage(UIImage(named: "showPwd")?.withRenderingMode(.alwaysTemplate), for: .normal)
        showPasswordBtn.tintColor = .label
        txtUserID.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtUserID.frame.height))
        txtUserID.leftViewMode = .always
        txtPassword.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtPassword.frame.height))
        txtPassword.leftViewMode = .always
        NotificationCenter.default.addObserver(self, selector: #selector(dismissVC), name: NSNotification.Name(rawValue: "dismissLoginView"), object: nil)
        
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
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnGoAction(_ sender: UIButton) {
        goAction()
    }


    func goAction(){
        if (txtUserID.text!.count < 2) || (txtUserID.text!.count > 8) {
            self.shakeTextField(textField: txtUserID)
            return
        }else if (txtPassword.text!.count < 4){
            self.shakeTextField(textField: txtPassword)
            return
        }
        var userID = txtUserID.text!
        if txtUserID.text!.prefix(1) != "x" && txtUserID.text!.prefix(1) != "e" {
            if txtUserID.text! == DevUserID {
                userID = "x\(txtUserID.text!)"
            } else {
                userID = "e\(txtUserID.text!)"
            }
        }
        txtUserID.text! = userID
        view.endEditing(true)
        self.checkLoginCredentials(userID: getUserIdAfterValidation(userId: self.txtUserID.text!), pwd: self.txtPassword.text!, completionHandler: { (response:String?) in
            print(response?.description ?? "no response")
            if response == "error"{
                DispatchQueue.main.async {
                    let vc = UIStoryboard(name: "BidInfo", bundle: nil).instantiateViewController(withIdentifier: "CBAlertVC") as! CBAlertVC
                    vc.fromView = self
                    self.present(vc, animated: true)
                }
                return
            }
        })
    }

    func checkLoginCredentials(userID:String,pwd:String,completionHandler:((String?) ->Void)?){
        if !reachability!.isReachable{
            let alert = AlertService.showAlert(title: Warning, message: NetworkNotAvailable, actions: nil)
            self.present(alert, animated: true)
            return
        }
        //passing data to access it later
        GlobalBidInfo.shared.userid = txtUserID.text!
        GlobalBidInfo.shared.password = txtPassword.text!
        GlobalBidInfo.shared.month = month!
        GlobalBidInfo.shared.year = year!
        GlobalBidInfo.shared.round = selectedRound!
        GlobalBidInfo.shared.employeeNumber = empNum!

        self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Please wait...")
        UserDefaults.standard.set(txtUserID.text, forKey: KCBEmpNumWithPrefix)

        bidDownload.checkCrewBidLogin(dataSource: GlobalBidInfo.shared, delegate: nil, finishedHandler: {
            print("Finish")
        }, progressHandler: {_ in }, errorHandler: {error in
            self.view.hideActivityIndicator()
            if self.checkLoginError(error as NSError, searchString: "Login failed"){
                self.logBidSubmissionProcess(error: error as NSError)
                if let account = KeychainHelper.retrieveUsername(forService: "SaveLoginDetails") {
                    KeychainHelper.delete(account: account, service: "SaveLoginDetails")
                }
            }
        })
        
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
    
    
    func loginActions(){
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidDocumentController") as! CBBidDocumentController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(vc, animated: true, completion: nil)
        }
    }
    
    func stringFormatter(_ string: String) -> String {
        var encodedString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        encodedString = encodedString.replacingOccurrences(of: "+", with: "%2B")
        return encodedString
    }
    
    
    func checkLoginError(_ error: NSError, searchString: String) -> Bool {
        var errorFlag = false
        var alertMessage = "Unknown error."
        var failureReason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String
        if failureReason == nil,
           let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            failureReason = underlyingError.localizedDescription
        }
        if let reason = failureReason,
           let suggestion = error.localizedRecoverySuggestion {
            alertMessage = "\(reason)\n\n\(suggestion)"
        }
        if alertMessage.lowercased().contains(searchString.lowercased()){
            errorFlag = true
        }
        return errorFlag
    }
    
    
    func logBidSubmissionProcess(error:NSError){
        let SWAMessage = error.userInfo["SWAMessage"] as? String ?? ""
        var mailInfo: [String:Any] = [:]
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        if let userid = self.userid, userid.contains("e"){
            let clean = self.userid?.replacingOccurrences(of: "e", with: "").trimmingCharacters(in: .symbols)
            mailInfo["EmployeeNumber"] = Int(clean!)
        }else if let userid = self.userid, userid.contains("x"){
            let clean = self.userid?.replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .symbols)
            mailInfo["EmployeeNumber"] = Int(clean!)
        }else{
            mailInfo["EmployeeNumber"] = 0
        }
        mailInfo["Event"] = "bad password"
        mailInfo["Base"] = self.selectedDomicile
        mailInfo["SWAMessage"] = SWAMessage
        mailInfo["Month"] = CBUtils.shortMonthName(month: self.month!, uc: false)
        mailInfo["Position"] = CBUtils.shortName(for: self.positionType(from: self.selectedPosition)!)
//        let roundString: String
//        if self.selectedRound == 1 {
//            roundString = "M"
//        } else if self.selectedRound == 2 {
//            roundString = "S"
//        } else {
//            roundString = ""
//        }

        mailInfo["Round"] = round
        mailInfo["Message"] = "bad password"
        mailInfo["OperatingSystemNum"] = "iPad OS"
        mailInfo["VersionNumber"] = appVersion
        mailInfo["PlatformNumber"] = "iPad"
        mailInfo["BidForEmpNum"] = 0
        mailInfo["BuddyBid1"] = 0
        mailInfo["BuddyBid2"] = 0
        mailInfo["BuddyBid3"] = 0
        let app = UIApplication.shared.delegate as! AppDelegate
        let now = Date()
        let timestamp = Int(now.timeIntervalSince1970 * 1000)
        let dateStarted = "/Date(\(timestamp)+0800)/"
        mailInfo["Date"] = dateStarted
        mailInfo["IpAddress"] = app.IPAddress

        if app.objNetworkType == .free {
//            let event = CBOfflineEvents()
            mailInfo["Message"] = "SouthWestWifi bad password"
//            event.addOfflineEvent(mailInfo)
            return
        }

        guard let url = URL(string: "\(app.Domain!)LogCrewBidSubmitBidDetails/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: mailInfo, options: [])
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            print("Failed to serialize JSON: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               response?.mimeType?.contains("application/json") == true {
            }
        }
        task.resume()
    }
    
    func positionType(from string: String?) -> BICrewPositionType? {
        guard let string = string?.lowercased() else { return nil }
        
        switch string {
        case "captain":
            return .Captain
        case "firstofficer", "first officer":
            return .FirstOfficer
        case "flightattendant", "flight attendant":
            return .FlightAttendant
        default:
            return nil
        }
    }
}


extension CBCredentialsPageVC: UITextFieldDelegate {
    
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
        if textField.text!.isEmpty {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.purple.cgColor
        } else {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.gray.cgColor
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.gray.cgColor
    }
    
    
}

