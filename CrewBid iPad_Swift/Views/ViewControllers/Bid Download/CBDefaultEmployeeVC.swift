//
//  CBDefaultEmployeeVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

enum defaultVCType {
    case defaultType
    case confirmEmployeeNumber
    case submitEmployeeNumber
    case showAwardedLine
}

class CBDefaultEmployeeVC: BaseViewController {
    
    @IBOutlet weak var textEmpNum: customUITextField!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var nextBtn: UIButton!
    //    private let viewModel = AuthService()
    var type:defaultVCType = .defaultType
    var confirmEmpNum:String?
    var hud = MBProgressHUD()
    var isHistoricBid:Bool = false
    var isNewBid:Bool = false
    var isEmpIDVerified:Bool = false
    let dataSource = GlobalBidInfo.shared
    var bidPeriod: BIBidPeriod?
    var isJobShareAlertShowing:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
//        bidPeriod = BIBidPeriod(context: CoreDataManager.shared.managedObjectContext)
        setupUI()
        textEmpNum.keyboardType = UIKeyboardType.numberPad
        if type == .confirmEmployeeNumber{
            NotificationCenter.default.addObserver(self, selector: #selector(jobShareAlert), name: NSNotification.Name("showJobShareAlert"), object: nil)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    func setupUI(){
        titleSetup()
        textEmpNum.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textEmpNum.frame.height))
        textEmpNum.leftViewMode = .always
        textEmpNum.delegate = self
        textEmpNum.layer.borderWidth = 4
        textEmpNum.layer.borderColor = UIColor.gray.cgColor

        if type == .showAwardedLine{
            nextBtn.setImage(nil, for: .normal)
            let title = "Go"
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 19, weight: .heavy), .foregroundColor: UIColor.black]
            let attributedTitle = NSAttributedString(string: title, attributes: attributes)
            nextBtn.setAttributedTitle(attributedTitle, for: .normal)
        }
        if type == .submitEmployeeNumber || type == .showAwardedLine{
            backBtn.setImage(UIImage(named: "cc"), for: .normal)
        }else{
            backBtn.setImage(UIImage(named: "arrowleftbutton"), for: .normal)
        }
        
        if type == .confirmEmployeeNumber {
            textEmpNum.text = ""
        }else{
            textEmpNum.text = UserDefaults.standard.string(forKey: kCBDefaultEmployeeNumberKey)
        }
    }

    
    func titleSetup(){
        if type == .showAwardedLine {
            titleLabel.text = "Enter Employee Number"
            descriptionTextView.text = "Enter employee number (no \"e\") to fetch the awarded line."
        }
        else if type == .submitEmployeeNumber {
            titleLabel.text = "Submit Bid"
            descriptionTextView.text = "Enter employee number (no \"e\") for whom the bid will be submitted"
        }
        else if type == .confirmEmployeeNumber {
            titleLabel.text = "Submit Bid"
            descriptionTextView.text = "Confirm employee number (no \"e\") for whom the bid will be submitted"
        }
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        if type == .showAwardedLine || type == .submitEmployeeNumber{
            self.dismiss(animated: true, completion: nil)
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        if type == .showAwardedLine {
            self.askForEmployeeNumber()
        }else{
            if !isEmpIDVerified {
                 guard let empID = textEmpNum.text, !empID.isEmpty else {
                     shakeTextField(textField: textEmpNum)
                     return
                 }

                 dataSource.employeeNumber = empID
                 UserDefaults.standard.set(empID, forKey: kCBDefaultEmployeeNumberKey)

                 self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Authentication Checking...")

                 // Use new AuthService
                 AuthService.shared.checkAuthentication(empID: empID) { [weak self] authResult in
                     guard let self = self else { return }
                     self.view.hideActivityIndicator()
                     self.handleAuthResult(authResult)

                 } onFailure: { [weak self] error in
                     guard let self = self else { return }
                     self.view.hideActivityIndicator()
                     self.showAlert(message: error.localizedDescription)
                 }

             } else {
                 // Already verified
                 if confirmEmpNum != textEmpNum.text! {
                     self.navigationController?.popViewController(animated: true)
                 } else {
                     self.goToNextPage()
                 }
             }
        }
        
    }
    func handleAuthResult(_ result: AuthResult) {
        let msg = result.message ?? ""
        guard let empID = textEmpNum.text else {return}
        if msg == "Invalid Account" || msg == "For security purposes, all users need a CrewBid or WBidMax account.  Go to www.crewbidmax.com and create an account" {
            showAlert(message: "User \(empID) does not have a CrewBid account. Go to www.crewbid.com to create the account.")
        } else if msg == "Subscription Expired" && !result.isSomehowSubscribed {
            showAlert(message: "User \(empID) does not have a valid subscription with Crewbid Account. Please Subscribe.")
        } else if msg.contains("Your subscription to CrewBid has expired.  Go to www.crewbid.com and re-subscribe - Go to crewbid.com") && !result.isSomehowSubscribed {
            showAlert(message: msg)
        } else {
            print("Valid Employee ID")
            if type == .submitEmployeeNumber {
                self.gotoConfirmEmployeeView()
            }else {
                self.gotoNextView()
            }
        }
    }
    func showAlert(message: String) {
        let alert = AlertService.showAlert(title: "CrewBid",message: message,actions: [(title: "Go to crewbid.com", style: .default, handler: { _ in
            if let url = URL(string: "http://www.crewbid.com/") {
                UIApplication.shared.open(url, options: [:])
            }
        }),(title: "Cancel", style: .cancel, handler: nil)])
        self.present(alert, animated: true)
    }
    func gotoNextView(){
         UserDefaults.standard.set(textEmpNum.text!, forKey: kCBDefaultEmployeeNumberKey)
         let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
         let vc = storyboard.instantiateViewController(withIdentifier: "CBBiddataDownloadVC") as! CBBiddataDownloadVC
         vc.empNum = self.textEmpNum.text
         vc.isNewBid = self.isNewBid
         self.navigationController?.pushViewController(vc, animated: true)
     }
    //MARK: Show Awarded line
    var action:String?
    func askForEmployeeNumber(){
        if let text = textEmpNum.text, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            //validate
        }else{
            self.textEmpNum.resignFirstResponder()
            let emp = textEmpNum.text!
            var line:BILine?
            if self.bidPeriod!.isFABid(){
                let awardedLineDic = self.awardedLineForFA(employeeNumber: emp)
                if let awardedLineString = awardedLineDic["awardedLine"] as? String, let awardedPos = awardedLineDic["awardedPos"] as? String {
                    let awardedLine = Int(awardedLineString)
                    if awardedLine != 0 {
                        line = self.fetchLine(lineNumber: awardedLine!, isFA: true, pos: awardedPos)!
                    }else{
                        dismissFn()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            AlertService.showAlertForTopVC(title: "Alert", message: "Awarded Line Not Found")
                            return
                        }
                    }
                }
            }else{
                let awardedLine = self.awardedLineForPilot(employeeNumber: emp)
                if awardedLine != 0 {
                    line = self.fetchLine(lineNumber: awardedLine, isFA: false, pos: nil)!
                }
            }
            if action == "Add Awarded Line to Calendar"{
                if line != nil {
                    //MARK: need code to save to calendar
//                    self.selectedLine = line
//                    addtoLineClnder()
                }
            }else{
                if line != nil {
                    self.showAwardedCalendarLineView(line: line!)
                }
            }
        }
    }
    
    func fetchLine(lineNumber: Int, isFA: Bool, pos: String?) -> BILine? {
        let lineTypeSort = NSSortDescriptor(key: "type", ascending: true)
        let lineNumberSort = NSSortDescriptor(key: "number", ascending: true)
        
        let lineSorts = [lineTypeSort, lineNumberSort]
        var predicate = NSPredicate(format: "number == %@", NSNumber(value: lineNumber))
        
        if isFA && !(bidPeriod?.isSecondRoundBid())! {
            var faPos : BIFaPosition = BIFaPosition.FaPositionA
            if pos == "A" {
                faPos = BIFaPosition.FaPositionA
            } else if pos == "B" {
                faPos = BIFaPosition.FaPositionB
            } else if pos == "C" {
                faPos = BIFaPosition.FaPositionC
            } else if pos == "D" {
                faPos = BIFaPosition.FaPositionD
            } else {
                return nil
            }
            let posPred = NSPredicate(format: "faPosition == %@", NSNumber(value: faPos.rawValue))
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, posPred])
        }
        let lines = (CBGlobalMethods.shared.selectedBidPeriod!.lines!.allObjects as NSArray).sortedArray(using: lineSorts)
        let results = (lines as NSArray).filtered(using: predicate) as! [BILine]
        
        if results.count > 0 {
            return results.first
        }
        return nil
    }
    
    
    func awardedLineForFA(employeeNumber:String) -> NSDictionary{
        let awardText = bidPeriod?.awardString
        var awardedLine: String? = ""
        var awardedPos: String? = ""
            // Add leading zeros to the employee number and then pad with a space on each side
        let stringToScan = "[\(employeeNumber)]"
        let scanner = Scanner(string: awardText!)
        let numCharSet = CharacterSet(charactersIn: "0123456789")
        let posCharSet = CharacterSet(charactersIn: "ABCD")
        let eidCharSet = CharacterSet(charactersIn: "[]0123456789")
        let dashCharSet = CharacterSet(charactersIn: "-")
        let newLineCharSet = CharacterSet(charactersIn: "\r\n")
        
        _ = scanner.scanUpToString(stringToScan)
        if scanner.isAtEnd {
            AlertService.showAlertForTopVC(title: "Employee Number \(employeeNumber) Not Found", message: "This could be due to an issue with the format of the Bid Awards file. As a workaround, you can use the Show Line option from the Lines Text File under Show Bid Files in the Bid Actions menu.")
                // This means that the scanner scanned but did not find the employeeNumber
            return NSDictionary(objects:[NSNumber(value: 0)], forKeys:["awardedLine"] as [NSCopying])
        } else {
            let firstEIDLoc = scanner.currentIndex
            if !(bidPeriod?.isSecondRoundBid())! {
                    // Scan past the employee number to see if the EID occurs again, if so, the FA
                    // was awarded a hard line
                _ = scanner.scanCharacters(from: eidCharSet)
                _ = scanner.scanUpToString(stringToScan)
                if !scanner.isAtEnd {
                        // The EID has occured again, which means we are in the alphabetical listing
                        // So scan past the EID and then scan the line number and position
                        // Scan up to the awarded line number
                    _ = scanner.scanCharacters(from: eidCharSet)
                    _ = scanner.scanUpToCharacters(from: numCharSet)
                    if !scanner.isAtEnd {
                            // Scan the awarded line
                        awardedLine = scanner.scanCharacters(from: numCharSet)
                            // Scan the dash
                        _ = scanner.scanCharacters(from: dashCharSet)
                            // Scan the awarded position
                        awardedPos = scanner.scanCharacters(from: posCharSet)
                    }
                }
                else{
                    let newIndex = scanner.string.index(firstEIDLoc, offsetBy: -50, limitedBy: scanner.string.startIndex)!
                        scanner.currentIndex = newIndex
//                    scanner.scanLocation = firstEIDLoc - 50
                        // scan up to the new line
                    _ = scanner.scanUpToCharacters(from: newLineCharSet)
                    if !scanner.isAtEnd {
                            // scan up to the reserve number
                        _ = scanner.scanUpToCharacters(from: numCharSet)
                        if !scanner.isAtEnd {
                            awardedLine = scanner.scanCharacters(from: numCharSet)
                                // Alert the FA to their reserve position
                            AlertService.showAlertForTopVC(title: "Reserve List Award", message: "EID \(employeeNumber) is number \(awardedLine ?? "") on the Reserve List.")
                            return NSDictionary(objects:[NSNumber(value: 0)], forKeys:["awardedLine"] as [NSCopying])
                        }
                    }
                }
            }else{
                    // Back up 50 characters and find the next line
                var awardedLineCheck: String? = ""
//                scanner.scanLocation -= 45
                let newIndex = scanner.string.index(scanner.currentIndex, offsetBy: -45, limitedBy: scanner.string.startIndex)!
                    scanner.currentIndex = newIndex
                awardedLineCheck = scanner.scanUpToCharacters(from: newLineCharSet)
                awardedLineCheck = scanner.scanUpToCharacters(from: numCharSet)
                    // Scan the awarded line number
                awardedLine = scanner.scanCharacters(from: numCharSet)
                awardedPos = " "
                print("\(String(describing: awardedLineCheck))")
            }
        }
        let returnDict = NSDictionary(objects:[awardedLine!, awardedPos!], forKeys:["awardedLine", "awardedPos"] as [NSCopying]) as Dictionary
        return returnDict as NSDictionary
    }
    
    
    func awardedLineForPilot(employeeNumber:String) -> Int {
        let awardText = bidPeriod?.awardString
        var awardedLine: NSString? = ""
        var stringToScan: String? = ""
        let first = "0"
        let last = " "
        
        let test = employeeNumber[employeeNumber.index(employeeNumber.startIndex, offsetBy: 0)]
        if employeeNumber.length == 4 {
            stringToScan = "\(first)\(first)\(employeeNumber)\(last)"
        } else if employeeNumber.length == 5 {
            stringToScan = "\(first)\(employeeNumber)\(last)"
        } else if employeeNumber.length == 6 && test == "0" {
            stringToScan = "\(employeeNumber)\(last)"
        } else if employeeNumber.length == 6 {
            stringToScan = "\(last)\(employeeNumber)\(last)"
        } else {
            AlertService.showAlertForTopVC(title: "Employee Number \(employeeNumber) Not Found", message: "This could be due to an issue with the format of the Bid Awards file. As a workaround, you can use the Show Line option from the Lines Text File under Show Bid Files in the Bid Actions menu.")
            return 0
        }
        
        let scanner = Scanner(string: awardText!)
        let numCharSet = CharacterSet(charactersIn: "0123456789")
        
            // Scan all characters before employee number plus a space
        _ = scanner.scanUpToString(stringToScan!)
        if scanner.isAtEnd {
            AlertService.showAlertForTopVC(title: "Employee Number \(employeeNumber) Not Found", message: "This could be due to an issue with the format of the Bid Awards file. As a workaround, you can use the Show Line option from the Lines Text File under Show Bid Files in the Bid Actions menu.")
            return 0
        }else {
            _ = scanner.scanCharacters(from: numCharSet)
            if !scanner.isAtEnd {
                    // Scan up to the awarded line number
                _ = scanner.scanUpToCharacters(from: numCharSet)
                if !scanner.isAtEnd {
                    awardedLine = scanner.scanCharacters(from: numCharSet) as NSString? // Scan the awarded line
                }
            }
        }
        return awardedLine!.integerValue
    }
    
    func showAwardedCalendarLineView(line:BILine) {
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBAwardLineCalendarViewController") as! CBAwardLineCalendarViewController
        vc.line = line
        vc.employeeNumber = self.textEmpNum.text!.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "")
        vc.bidPeriod = self.bidPeriod
        vc.fromScrachpadView = true
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        vc.modalPresentationStyle = .formSheet
        self.present(vc, animated: true)
    }
    
    func gotoConfirmEmployeeView(){
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBDefaultEmployeeVC") as! CBDefaultEmployeeVC
        vc.type = .confirmEmployeeNumber
        vc.isEmpIDVerified = true
        vc.bidPeriod = self.bidPeriod
        vc.confirmEmpNum = self.textEmpNum.text!
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func goToNextPage(){
        if self.bidPeriod!.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue{
//            if self.bidPeriod!.isSwaAPI?.boolValue == true{
                if self.bidPeriod!.round == 1 {
                AlertService.showAlertForTopVC(title: "CrewBid iPad", message: "If you are Buddy Bidding you need to verify that you are buddy bidders on your Buddy list, and they know you are buddy bidding with them.", actions: [(title: "I have Verified", style: .default, handler: {_ in
                    self.buddyBid(selected: true)
                    
                    }),(title: "I am NOT Buddy Bidding", style: .default, handler: {_ in
                    self.buddyBid(selected: false)
                    })])
                }else{
                    self.loginView()
                }
//            }
        }
        else if self.bidPeriod!.positionType?.intValue == BICrewPositionType.FirstOfficer.rawValue && self.bidPeriod!.round == 1 {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBAvoidanceBidViewController") as! CBAvoidanceBidViewController
                vc.empID = self.textEmpNum.text!
                vc.bidPeriod = self.bidPeriod
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                loginView()
            }
    }
    
    func loginView(){
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
        vc.type = .submitBid
        vc.bidPeriod = self.bidPeriod
        vc.defaultEmplyeeNumber = self.textEmpNum.text!
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func buddyBid(selected: Bool){
        if selected{
            let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBOptionalEmployeesPageViewController") as! CBOptionalEmployeesPageViewController
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            vc.empID = self.textEmpNum.text!
            vc.bidPeriod = self.bidPeriod!
            
            self.navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        self.bidPeriod?.buddyBidder1 = nil
        self.bidPeriod?.buddyBidder2 = nil
        
            jobShareAlert()
        
    }
    
    
    
    
    @objc func jobShareAlert() {
        AlertService.showAlertForTopVC(title: "Do you want to JOB SHARE?", message: "If you are Job Share Bidding, you need to verify that your Job Share Bidders are on your Buddy List, and they know you are Job Sharing with them!", actions: [(title:"I have verified", style: .default, handler: {_ in
            let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "JobShareViewController") as! JobShareViewController
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            vc.bidPeriod = self.bidPeriod!
            self.navigationController?.pushViewController(vc, animated: true)
        }),
        (title:"I am NOT Job Share bidding", style: .cancel , handler: {_ in
            self.loginView()
        })])
    }
    
    
}

extension CBDefaultEmployeeVC : UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == textEmpNum {
            // Limit characters to 7
            let currentText = textField.text ?? ""
            let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
            if prospectiveText.count > 7 {
                textField.shakeTextField() // Exceeds length limit
                return false
            }
            let allowedCharacters = CharacterSet(charactersIn: "0123456789") // Modify if needed
            let characterSet = CharacterSet(charactersIn: string)
            
            if !allowedCharacters.isSuperset(of: characterSet) {
                textField.shakeTextField() // Disallowed characters
                return false
            }
            return true
        }
        return true
    }
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        if type != "Confirm Employee Number"{
//            guard let empID = textEmpNum.text, !empID.isEmpty else {
//                 showAlert(message: "Please enter a valid employee number.")
//                 return false
//             }
//            UserDefaults.standard.set(textEmpNum.text!, forKey: kCBDefaultEmployeeNumberKey)
//            self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Authentication Checking...")
//            viewModel.checkAuthentication(empID: empID)
//            return true
//        }else{
//            return false
//        }
//    }
  
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        if type != .confirmEmployeeNumber {
            guard let empID = textEmpNum.text, !empID.isEmpty else {
                shakeTextField(textField: textEmpNum)
                return false
            }

            dataSource.employeeNumber = empID
            UserDefaults.standard.set(empID, forKey: kCBDefaultEmployeeNumberKey)

            self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Authentication Checking...")

            AuthService.shared.checkAuthentication(empID: empID) { [weak self] authResult in
                guard let self = self else { return }
                self.view.hideActivityIndicator()

                if authResult.isSomehowSubscribed {
                    self.isEmpIDVerified = true
                    self.confirmEmpNum = empID
                    self.handleAuthResult(authResult) // existing method
                    self.goToNextPage()
                } else {
                    let alert = AlertService.showAlert(
                        title: "Authentication Failed",
                        message: authResult.message ?? "You are not subscribed or authorized.",
                        actions: nil
                    )
                    self.present(alert, animated: true)
                }

            } onFailure: { [weak self] error in
                guard let self = self else { return }
                self.view.hideActivityIndicator()
                self.showAlert(message: error.localizedDescription)
            }

            return true
        } else {
            // Confirm Employee Number
            if confirmEmpNum != textEmpNum.text! {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.goToNextPage()
            }
            return true
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == textEmpNum {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.purple.cgColor
        } else {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.darkGray.cgColor
        }
    }
}
