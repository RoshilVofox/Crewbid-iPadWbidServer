//
//  CBDefaultEmployeeVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBDefaultEmployeeVC: BaseViewController {
    
    @IBOutlet weak var textEmpNum: customUITextField!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
//    private let viewModel = AuthService()
    var type:String?
    var confirmEmpNum:String?
    var hud = MBProgressHUD()
    var isHistoricBid:Bool = false
    var isNewBid:Bool = false
    var isEmpIDVerified:Bool = false
    let dataSource = GlobalBidInfo.shared
    var bidPeriod = BIBidPeriod()
    var isJobShareAlertShowing:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        textEmpNum.keyboardType = UIKeyboardType.numberPad
        if type == "Confirm Employee Number"{
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
//            viewModel.onAuthSuccess = { [weak self] result in
//                self?.view.hideActivityIndicator()
//                self?.handleAuthResult(result)
//            }
//            viewModel.onAuthFailure = { [weak self] error in
//                self?.view.hideActivityIndicator()
//                self?.showAlert(message: error.localizedDescription)
//            }
        if type == "Submit Employee Number"{
            backBtn.setImage(UIImage(named: "cc"), for: .normal)
        }else{
            backBtn.setImage(UIImage(named: "arrowleftbutton"), for: .normal)
        }
        
        if type == "Confirm Employee Number" {
            textEmpNum.text = ""
        }else{
            textEmpNum.text = UserDefaults.standard.string(forKey: kCBDefaultEmployeeNumberKey)
        }
    }

    
    func titleSetup(){
        if type == "Show Awarded Line" {
            titleLabel.text = "Enter Employee Number"
            descriptionTextView.text = "Enter employee number (no \"e\") to fetch the awarded line."
        }
        else if type == "Submit Employee Number" {
            titleLabel.text = "Enter Employee Number"
            descriptionTextView.text = "Enter employee number (no \"e\") for whom the bid will be submitted"
        }
        else if type == "Confirm Employee Number" {
            titleLabel.text = "Confirm Employee Number"
            descriptionTextView.text = "Confirm employee number (no \"e\") for whom the bid will be submitted"
        }
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        if type == "Show Awarded Line" || type == "Show Awarded Line" || type == "Submit Employee Number"{
            self.dismiss(animated: true, completion: nil)
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
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
            if type == "Show Awarded Line" {
                self.goToAwardedCallendarLine()
            }
            else if type == "Submit Employee Number" {
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
    
    func goToAwardedCallendarLine() {
        if let presentingVC = self.presentingViewController {
            self.dismiss(animated: true) {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBAwardLineCalendarViewController") as! CBAwardLineCalendarViewController
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                presentingVC.present(vc, animated: true)
            }
        }
    }
    
    func gotoConfirmEmployeeView(){
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBDefaultEmployeeVC") as! CBDefaultEmployeeVC
        vc.type = "Confirm Employee Number"
        vc.isEmpIDVerified = true
        vc.bidPeriod = self.bidPeriod
        vc.confirmEmpNum = self.textEmpNum.text!
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func goToNextPage(){
        if self.bidPeriod.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue && self.bidPeriod.round == 1 {
                AlertService.showAlertForTopVC(title: "Alert", message: "If you are Buddy Bidding you need to verify that you are buddy bidders on your Buddy list, and they know you are buddy bidding with them.", actions: [(title: "I have Verified", style: .default, handler: {_ in
                    self.buddyBid(selected: true)

                }),(title: "I am NOT Buddy Bidding", style: .default, handler: {_ in
                    self.buddyBid(selected: false)
                })])
            }
            else if self.bidPeriod.positionType?.intValue == BICrewPositionType.FirstOfficer.rawValue && self.bidPeriod.round == 1 {
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
        vc.type = "Submit Bid"
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
            vc.bidPeriod = self.bidPeriod
            self.navigationController?.pushViewController(vc, animated: true)
        }else{
            jobShareAlert()
        }
    }
    
    
    
    
    @objc func jobShareAlert() {
        AlertService.showAlertForTopVC(title: "Job Share", message: "Do you want Job Share?", actions: [(title:"Yes", style: .default, handler: {_ in
            let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "JobShareViewController") as! JobShareViewController
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            vc.bidPeriod = self.bidPeriod
            self.navigationController?.pushViewController(vc, animated: true)
        }),
        (title:"No", style: .cancel , handler: {_ in
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

        if type != "Confirm Employee Number" {
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
