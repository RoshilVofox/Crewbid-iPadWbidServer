

import UIKit

class userAccountViewController: BaseViewController, UITextFieldDelegate {

    
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var empNumber: UITextField!
    @IBOutlet weak var positionControl: UISegmentedControl!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var confirmEmail: UITextField!
    @IBOutlet weak var cellPhone: UITextField!
    @IBOutlet weak var cellCarrier: DropDown!
    @IBOutlet weak var updateBtn: UIButton!
    @IBOutlet weak var switchMail: UISwitch!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var doneBtn: UIButton!
    var isfrom:UIViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if CBUserAccountDetail.shared.isUserInfoAvailable(){
            setupAccountValues()
        }
    }
    
    func setupUI(){
        btnBack.setTitle("", for: .normal)
        doneBtn.setTitle("", for: .normal)
        updateBtn.layer.masksToBounds = true
        updateBtn.layer.cornerRadius = 5
        if isfrom!.isKind(of: CBCredentialsPageVC.self){
            btnBack.setImage(UIImage(named: "NewBid-navbar-ncelbutton"), for: .normal)
        }
        
        cellCarrier.optionArray = ["ATandT",
                                   "Cingular",
                                   "Metro_PCS",
                                   "Nextel",
                                   "Other",
                                   "Sprint",
                                   "Tmobile",
                                   "Verizon",
                                   "Virgin_Mobile"]
        cellCarrier.didSelect(completion: {(selectedText, index, id) in
            self.cellCarrier.text = "\(selectedText)"
        })
    }
    
    
    func setupAccountValues(){
        firstName.text = CBUserAccountDetail.shared.firstName
        lastName.text = CBUserAccountDetail.shared.lastName
        email.text = CBUserAccountDetail.shared.email
        confirmEmail.text = CBUserAccountDetail.shared.email
        cellPhone.text = CBUserAccountDetail.shared.cellPhone
        switchMail.isOn = CBUserAccountDetail.shared.AcceptEmail
        empNumber.text = CBUserAccountDetail.shared.employeeNumber
        
        
        if CBUserAccountDetail.shared.position == 3 || CBUserAccountDetail.shared.position == 2{
            positionControl.selectedSegmentIndex = 1
        }else{
            positionControl.selectedSegmentIndex = 0
        }
        
        cellCarrier.selectedIndex = nil
        if cellCarrier.optionArray.indices.contains(CBUserAccountDetail.shared.CarrierNum){
            cellCarrier.text = cellCarrier.optionArray[CBUserAccountDetail.shared.CarrierNum]
            cellCarrier.isSearchEnable = false
        }
    }
    
    
    @IBAction func btnBackAction(_ sender: Any) {
        if let credentialsVC = isfrom as? CBCredentialsPageVC {
            self.dismiss(animated: true) {
                credentialsVC.checkAuthentication()
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func doneBtnAction(_ sender: Any) {
        if let credentialsVC = isfrom as? CBCredentialsPageVC {
            self.dismiss(animated: true) {
                credentialsVC.checkAuthentication()
            }
        } else {
            self.dismiss(animated: true)
        }
    }
    @IBAction func updateBtnAction(_ sender: Any) {
    }
    
    @IBAction func BtnPrivacyAction(_ sender: Any) {
    }
    
    @IBAction func BtnLicenceAction(_ sender: Any) {
    }
    
    //Populate account values

    
    
    
}

