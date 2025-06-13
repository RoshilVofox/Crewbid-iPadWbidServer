//
//  CBDefaultEmployeeVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBDefaultEmployeeVC: BaseViewController {
    
    @IBOutlet weak var textEmpNum: customUITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    private let viewModel = CBDefaultEmployeeViewModel()
    var type:String?
    var confirmEmpNum:String?
    var hud = MBProgressHUD()
    var isHistoricBid:Bool = false
    var isNewBid:Bool = false
    var isEmpVerified:Bool = false
    let dataSource = GlobalBidInfo.shared
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    
    
    func setupUI(){
        titleSetup()
        textEmpNum.becomeFirstResponder()
        textEmpNum.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textEmpNum.frame.height))
        textEmpNum.leftViewMode = .always
        textEmpNum.delegate = self
        textEmpNum.text = UserDefaults.standard.string(forKey: kCBDefaultEmployeeNumberKey)
            viewModel.onAuthSuccess = { [weak self] result in
                self?.view.hideActivityIndicator()
                self?.handleAuthResult(result)
            }
            viewModel.onAuthFailure = { [weak self] error in
                self?.view.hideActivityIndicator()
                self?.showAlert(message: error.localizedDescription)
            }
    }
    
    func titleSetup(){
        if type == "Show Awarded Line" {
            titleLabel.text = "Enter Employee Number"
            descriptionTextView.text = "Enter employee number (no \"e\") to fetch the awarded line."
        }
        else if type == "Submit employee number" {
            titleLabel.text = "Enter Employee Number"
            descriptionTextView.text = "Enter employee number (no \"e\") for whom the bid will be submitted"
        }
        else if type == "Confirm Employee Number" {
            titleLabel.text = "Confirm Employee Number"
            descriptionTextView.text = "Confirm employee number (no \"e\") for whom the bid will be submitted"
        }
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        if type == "Show Awarded Line" || type == "Show Awarded Line" {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        guard let empID = textEmpNum.text, !empID.isEmpty else {
                   shakeTextField(textField: textEmpNum)
                   return
               }
        dataSource.employeeNumber = empID
        UserDefaults.standard.set(textEmpNum.text!, forKey: kCBDefaultEmployeeNumberKey)
        self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Authentication Checking...")
        viewModel.checkAuthentication(empID: empID)
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
            else if type == "Submit employee number" {
                self.gotoConfirmEmployeeNumber()
            }
            else if type == "Confirm Employee Number" {
                self.goFromConfirmEmployeeNumber()
            }
            else {
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
    
    func gotoConfirmEmployeeNumber(){
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBDefaultEmployeeVC") as! CBDefaultEmployeeVC
        vc.type = "Confirm Employee Number"
        vc.confirmEmpNum = self.textEmpNum.text!
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func goFromConfirmEmployeeNumber(){
        if confirmEmpNum == textEmpNum.text{
            if AppData.shared.postion == "FA" && AppData.shared.Round == 1 {
                let alert = UIAlertController(
                    title: "Alert",
                    message: "If you are Buddy Bidding you need to verify that you are buddy bidders on your Buddy list, and they know you are buddy bidding with them.",
                    preferredStyle: .alert
                )
                let buddyBiddingAction = UIAlertAction(title: "I have Verified", style: .default) { _ in
                    self.buddyBidSelected()
                }
                let notBuddyBiddingAction = UIAlertAction(title: "I am not Buddy Bidding", style: .default) { _ in
                    self.buddyBidNotSelected()
                }
                alert.addAction(buddyBiddingAction)
                alert.addAction(notBuddyBiddingAction)
                present(alert, animated: true)
            }
            else if AppData.shared.postion == "FO" && AppData.shared.Round == 1 {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBAvoidaceBidViewController") as! CBAvoidaceBidViewController
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBSubmitCredentialVC") as! CBSubmitCredentialVC
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        else {
            let alert = UIAlertController(
                title: "Alert",
                message: "The entered employee number does not match the original entry. Please check and try again.",
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(title: "OK", style: .cancel)
            alert.addAction(cancelAction)
            present(alert, animated: true)
        }
    }
    
    func buddyBidSelected() {
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBOptionalEmployeesPageViewController") as! CBOptionalEmployeesPageViewController
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func buddyBidNotSelected() {
        jobShareAlert()
        
    }
    
    func jobShareAlert() {
        let alert = UIAlertController(
            title: "Job Share",
            message: "Do you want job share?",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "Yes", style: .default) { _ in
            let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "JobShareViewController") as! JobShareViewController
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "No", style: .cancel) { _ in
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
            vc.type = "Submit Bid"
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
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
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard let empID = textEmpNum.text, !empID.isEmpty else {
             showAlert(message: "Please enter a valid employee number.")
             return false
         }
        viewModel.checkAuthentication(empID: empID)
        return true
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
