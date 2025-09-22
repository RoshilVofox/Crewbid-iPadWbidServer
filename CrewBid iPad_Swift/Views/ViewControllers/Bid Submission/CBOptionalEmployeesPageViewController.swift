

import UIKit

class CBOptionalEmployeesPageViewController: BaseViewController {
    
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var buddyBidTxtField_1: customUITextField!
    @IBOutlet weak var buddyBidderName_1: UILabel!
    @IBOutlet weak var buddyBidTxtField_2: customUITextField!
    @IBOutlet weak var buddyBidderName_2: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    
    @IBOutlet weak var buddyBidderDomicile_1: UILabel!
    @IBOutlet weak var buddyBidderDomicile_2: UILabel!
    
    @IBOutlet weak var lblWarning: UILabel!
    @IBOutlet weak var lblBuddyBid: UILabel!
    
    @IBOutlet weak var lblTitle: UILabel!
    var isBuddy1Valid: Bool = false
    var isBuddy2Valid: Bool = false
    var empID: String?
    var bidPeriod: BIBidPeriod!
    var FAListDict:[String:Any]? = nil
    var optionalEmployees = NSMutableArray()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        FAListDict = CBUtils.readJSONStringFromFile()
    }
    
    func setupUI() {
        self.lblTitle.text = "Submit bid or Buddy bid for EID \(empID ?? "")"
        buddyBidTxtField_1.delegate = self
        buddyBidTxtField_2.delegate = self
        buddyBidTxtField_1.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: buddyBidTxtField_1.frame.height))
        buddyBidTxtField_2.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: buddyBidTxtField_2.frame.height))
        buddyBidTxtField_1.leftViewMode = .always
        buddyBidTxtField_2.leftViewMode = .always
        buddyBidderDomicile_1.isHidden = true
        buddyBidderDomicile_2.isHidden = true
        buddyBidderName_1.text = ""
        buddyBidderName_2.text = ""
        btnClose.setTitle("", for: .normal)
        btnNext.setTitle("", for: .normal)
        buddyBidTxtField_1.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        buddyBidTxtField_2.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        if buddyBidTxtField_1.text!.isEmpty && buddyBidTxtField_2.text!.isEmpty{
//            print("Job Share Alert")
            NotificationCenter.default.post(name:Notification.Name("showJobShareAlert"), object: nil)
        }else{
            if self.buddyBidTxtField_1.text == self.buddyBidTxtField_2.text {
                AlertService.showAlertForTopVC(title: "CrewBid", message: "You cannot enter the same employee number in Buddy 1 and Buddy 2", actions: [(title: "OK", style: .default, handler: { _ in
                    self.buddyBidTxtField_2.text = ""
                    self.buddyBidderName_2.text = ""
                    self.buddyBidderDomicile_2.text = ""
                })])
            }else if CBGlobalMethods.shared.domicileIsDifferent == true{
                AlertService.showAlertForTopVC(title: "CrewBid", message: "One of the Buddy Bidders is NOT in \(CBGlobalMethods.shared.selectedBidPeriod?.base ?? "")", actions: [(title: "OK", style: .default, handler: {_ in
                    self.buddyBidTxtField_1.text = ""
                    self.buddyBidTxtField_2.text = ""
                    self.buddyBidderName_1.text = ""
                    self.buddyBidderDomicile_1.text = ""
                    self.buddyBidderName_2.text = ""
                    self.buddyBidderDomicile_2.text = ""
                    self.optionalEmployees.removeAllObjects()
                })])
            }
            
            //needs code for buddy id validation from new API
//            else if self.ifEmployeeContainsInFALIST(){
//                if isBuddy1Valid && isBuddy2Valid{
//                    if self.buddyBidTxtField_1.text != ""{
//                        self.optionalEmployees.add(self.buddyBidTxtField_1.text!)
//                    }
//                    if self.buddyBidTxtField_2.text != ""{
//                        self.optionalEmployees.add(self.buddyBidTxtField_2.text!)
//                    }
//                    finalAlert()
//                }
//            }
            
        }
    }
    
    
    
    func finalAlert() {
        AlertService.showAlertForTopVC(title: "Buddy Bidding Terms", message: "By continuing, you represent that you have the permission of your buddy or buddies to Buddy Bid with them and you have taken the necessary steps inSwA lite to out them on vour BuddyBidding list.I Understand and Accept", actions: [(title: "OK", style: .default, handler: { _ in
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
            vc.type = "Submit Bid"
            vc.bidPeriod = self.bidPeriod
            vc.optionalEmployees = self.optionalEmployees
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            self.navigationController?.pushViewController(vc, animated: true)
        })])
    }
    
    func ifEmployeeContainsInFALIST() ->Bool {
        if CBGlobalMethods.shared.falistDict.count == 0{
            CBGlobalMethods.shared.falistDict = CBUtils.readJSONStringFromFile()!
        }
        var emplyeeInFALIST = false
        var isFirstBuddyCorrect = false
        var isSecondBuddyCorrect = false
        if self.buddyBidTxtField_1.text == "" {
            isFirstBuddyCorrect = true
        }
        if self.buddyBidTxtField_2.text == "" {
            isSecondBuddyCorrect = true
        }
        if self.bidPeriod.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue {
            if !emplyeeInFALIST {
                if !isFirstBuddyCorrect {
                    let firstEmpName = CBGlobalMethods.shared.falistDict[self.buddyBidTxtField_1.text!]
                    if firstEmpName == nil {
                        isFirstBuddyCorrect = false
                    } else {
                        isFirstBuddyCorrect = true
                    }
                }
                if !isSecondBuddyCorrect {
                    let secondEmpName = CBGlobalMethods.shared.falistDict[self.buddyBidTxtField_2.text!]
                    if secondEmpName == nil {
                        isSecondBuddyCorrect = false
                    } else {
                        isSecondBuddyCorrect = true
                    }
                }
                if isFirstBuddyCorrect && isSecondBuddyCorrect {
                    emplyeeInFALIST = true
                    
                } else {
                    emplyeeInFALIST = false
                }
                
            }
            if !isFirstBuddyCorrect {
                buddyBidderName_1.isHidden = false
                buddyBidderName_1.text = "Invalid Employee Number"
                buddyBidderName_1.textColor = .red
                buddyBidderDomicile_1.text = ""
                shakeTextField(textField: buddyBidTxtField_1)
            }
            if !isSecondBuddyCorrect {
                buddyBidderName_2.isHidden = false
                buddyBidderName_2.text = "Invalid Employee Number"
                buddyBidderName_2.textColor = .red
                buddyBidderDomicile_2.text = ""
                shakeTextField(textField: buddyBidTxtField_2)
            }
        }
        return true
    }
    
    
}

extension CBOptionalEmployeesPageViewController: UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let empDict = self.FAListDict?[textField.text!] as? [String: Any]
        let empName = empDict?["Name"] as? String
        let empDomicile = empDict?["Domicile"] as? String
        
        if empName == nil {
            if textField == buddyBidTxtField_1{
                self.buddyBidderName_1.isHidden = true
                self.buddyBidderDomicile_1.isHidden = true
            }else if textField == buddyBidTxtField_2{
                self.buddyBidderName_2.isHidden = true
                self.buddyBidderDomicile_2.isHidden = true
            }
        }else{
            if textField == buddyBidTxtField_1{
                self.buddyBidderName_1.isHidden = false
                self.buddyBidderName_1.text = empName
                self.buddyBidderName_1.textColor = CBColor.buddyTextColor
                self.buddyBidderDomicile_1.isHidden = false
                self.buddyBidderDomicile_1.text = empDomicile
                self.isBuddy1Valid = true
            }else if textField == buddyBidTxtField_2{
                self.buddyBidderName_2.isHidden = false
                self.buddyBidderName_2.text = empName
                self.buddyBidderName_2.textColor = CBColor.buddyTextColor
                self.buddyBidderDomicile_2.isHidden = false
                self.buddyBidderDomicile_2.text = empDomicile
                self.isBuddy2Valid = true
            }
        }
        if empDomicile == self.bidPeriod.base{
            CBGlobalMethods.shared.domicileIsDifferent = false
        }else{
            CBGlobalMethods.shared.domicileIsDifferent = true
        }
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
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == buddyBidTxtField_1 || textField == buddyBidTxtField_2 {
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
}
