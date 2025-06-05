//
//  CBCredentialsPageVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit
import CoreData

class CBCredentialsPageVC: BaseViewController {
    
    @IBOutlet weak var txtUserID: customUITextField!
    @IBOutlet weak var txtPassword: customUITextField!
    @IBOutlet weak var showPasswordBtn: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
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
    let loginViewModel = CBLoginViewModel()
    let bidDownloadViewModel = BIBidFileDownloadViewModel()
    let context = CoreDataManager.shared.managedObjectContext
    let dataSource = GlobalBidInfo.shared
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if CBUtils.isRunningOnSimulator(){
            self.txtUserID.text = DevUserID
            self.txtPassword.text = DevUserPassword
        }
        NotificationCenter.default.addObserver(self, selector: #selector(showProgressView), name: Notification.Name("ShowProgressView"), object: nil)
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
        txtUserID.becomeFirstResponder()
        txtUserID.delegate = self
        txtPassword.delegate = self
        txtUserID.textContentType = .username
        txtPassword.textContentType = .password
       
        showPasswordBtn.setImage(UIImage(named: "showPwd")?.withRenderingMode(.alwaysTemplate), for: .normal)
        showPasswordBtn.tintColor = .label
        txtUserID.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtUserID.frame.height))
        txtUserID.leftViewMode = .always
        txtPassword.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtPassword.frame.height))
        txtPassword.leftViewMode = .always
        

        //------viewmodel--------
        loginViewModel.onLoginSuccess = { sessionKey in
            print("Session Key: \(sessionKey)")
            self.view.hideActivityIndicator()
            let bidFileName = BIBidInfo.shared.bidDataFilename()
            let linesTextFileName = BIBidInfo.shared.linesTextFilename()
            print("Filename: \(bidFileName)")
//            let bidDownload = BIBidFileDownload()
            if AppState.shared.isHistoricBid{
                //MARK:  Historic Bid Data
                print("Bid: Historic")
                if self.isSecondRoundBid() && !self.isFABid(){
                    self.bidDownloadViewModel.fetchHistoricBidLines(filename: linesTextFileName){result in
                        DispatchQueue.main.async {
                            switch result{
                            case .success(let fileURL): print("File saved at: \(fileURL)")
                            case .failure(let error): print("Historic bid download failed: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                self.bidDownloadViewModel.fetchHistoricBidLines(filename: bidFileName){ result in
                    DispatchQueue.main.async {
                        switch result{
                        case .success(let fileURL): print("File saved at: \(fileURL)")
                        case .failure(let error): print("Historic bid download failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
            else if AppState.shared.isMockData{
                //MARK:  Mock Bid Data
                print("Bid: Mock data")
                
                
                
            }else{//MARK:  New Bid Data
                print("Bid: New bid")
                NotificationCenter.default.post(name: Notification.Name("ShowProgressView"), object: nil)
                
                self.bidDownloadViewModel.fetchNewBidData(sessionKey: sessionKey, fileName: bidFileName){result in
                    switch result{
                    case .success(let fileURL):
                        DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .init("DownloadingBid"), object: nil)
                                }
                        print("File unzipped at: \(fileURL)")
                        
                    case .failure(let error):
                        print("Error downloading new bid: \(error.localizedDescription)")
                        NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
                    }
                }
            }
        }
        loginViewModel.onLoginFailure = { error in
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
        self.loginValidation()
        if type == "Retrieve Awards" {
            self.retriveAwardsAction()
        }
        else if type == "Submit Bid" {
            self.submitBidAction()
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
        guard let empID = self.txtUserID.text, let month = self.month, let year = self.year, let round = self.selectedRound, let selectedbase = self.selectedDomicile, let position = self.selectedPosition else { return }
        self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Please wait...")
        
        //--Login action--
        if bidAlreadyExists(){
            showAlertForExistingBid()
        }else{
            loginViewModel.checkLogin(userID: formattedUserID,password: password,empNum: empID)
            
        }
        //----------------
    }

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
    
    private func showAlertForExistingBid() {
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
            if list.count > 0 {
                let obj = list[0]
                self.context.delete(obj)
//                NotificationCenter.default.post(name: NSNotification.Name(reloadCollectionView), object: nil)
            }
            self.loginActions()
        }), (title: "Cancel", style: .cancel, handler: {_ in}), (title: "Open Bid", style: .default, handler: {_ in
            if list.count > 0 {
                let obj = list[0]
                CBGlobalMethods.shared.selectedBidPeriod = obj
                UserDefaults.standard.setValue(obj.round?.intValue ?? 1, forKey: "SelectedRound")
                self.dismiss(animated: true)
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
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let docVC = storyboard.instantiateViewController(withIdentifier: "CBBidDocumentController") as! CBBidDocumentController
        if let homeNav = UIApplication.shared.windows.first?.rootViewController as? UINavigationController {
            self.dismiss(animated: false) {
                homeNav.pushViewController(docVC, animated: true)
            }
        }
    }
    
//    MARK: Retrieve Awards Action
    func retriveAwardsAction() {
        if let presentingVC = self.presentingViewController {
            self.dismiss(animated: true) {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBShowAwardsViewController") as! CBShowAwardsViewController
                vc.modalPresentationStyle = .fullScreen
                presentingVC.present(vc, animated: true)
            }
        }
    }
    
//    MARK: Submit Award Action
    func submitBidAction() {
        if let presentingVC = self.presentingViewController {
            self.dismiss(animated: true) {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "SubmissionErrorVC") as! SubmissionErrorVC
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                presentingVC.present(vc, animated: true)
            }
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
}


extension CBCredentialsPageVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtUserID {
            txtPassword.becomeFirstResponder()
        } else if textField == txtPassword {
            txtPassword.resignFirstResponder()
            self.loginValidation()
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

