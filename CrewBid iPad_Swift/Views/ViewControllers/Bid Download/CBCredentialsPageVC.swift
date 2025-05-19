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
    var loginType:LoginType = .newBid
    var type:String?
    let viewModel = CBLoginViewModel()
    let app = UIApplication.shared.delegate as! AppDelegate
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
        
        //------viewmodel--------
        viewModel.formatter = self.stringFormatter(_:)
        viewModel.onLoginSuccess = { sessionKey in
            print("Session Key: \(sessionKey)")
            self.view.hideActivityIndicator()
            self.loginActions()
        }
        viewModel.onLoginFailure = { error in
            self.view.hideActivityIndicator()
            
            let errorString = error.localizedDescriptionString.lowercased()
            print("Error:\(errorString)")
            if errorString.contains("unauthorized request"){
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
        self.login()
    }
    func login(){
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
        guard let empID = self.txtUserID.text, let month = self.month, let year = self.year, let round = self.selectedRound else { return }
        self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Please wait...")
        viewModel.checkLogin(userID: formattedUserID,password: password,empNum: empID,month: month,year: year, round:round)
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
    
    func loginActions(){
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let docVC = storyboard.instantiateViewController(withIdentifier: "CBBidDocumentController") as! CBBidDocumentController
        if let homeNav = UIApplication.shared.windows.first?.rootViewController as? UINavigationController {
            self.dismiss(animated: false) {
                homeNav.pushViewController(docVC, animated: true)
            }
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
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtUserID {
            txtPassword.becomeFirstResponder()
        } else if textField == txtPassword {
            txtPassword.resignFirstResponder()
            self.login()
        }
        return true
    }
    
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

