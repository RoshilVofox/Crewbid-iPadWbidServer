import UIKit

enum UserWebType {
    case webCreateUser
    case webUpdateUser
    case webCheckPassword
    case webForgotPassword
    case webSavePassword
    case webUserExist
    case updateUser
    case checkServiceTypeHelp
    case soapCreateUser
}

class userAccountViewController: BaseViewController, UITextFieldDelegate, ServiceConnectionDelegate {
    func responseError(_ errMsg: String) {
        print("response error")
    }
    
    func serviceResponse(_ arrResponse: [Any]) {
        CBGlobalMethods.shared.hideActivityIndicator()
        print(arrResponse.description)
        var flag = false
        var value = 0
        let userArray = arrResponse as! [[String: Any]]
        if arrResponse.count > 0 {
            
            switch webType {
            case .webCreateUser:
                print("web create user")
            case .webUpdateUser:
                print("web update user")
            case .webCheckPassword:
                print("web check pwd")
            case .webForgotPassword:
                print("web forgot pwd")
            case .webSavePassword:
                print("web save pwd")
            case .webUserExist:
                print("web user exist")
                value = userArray.first?["EmpNum"] as! Int
                
                if value != 0 {
                    dicTempUserInformation = userArray[0]
                    self.checkForDifference()
                }
                break
            case .updateUser:
                print("update user")
                let firstItem = arrResponse.first as? [String: Any]
                flag = (firstItem?["Status"] as? Bool) ?? false
                
                if flag{
                    if switchMail.isOn{
                        dicLocalUserInfo["AcceptEmail"] = "1"
                    }else{
                        dicLocalUserInfo["AcceptEmail"] = "0"
                    }
                    self.localAccountCreation()
                    CBUtils.setPushNotifications()
                    AlertService.showAlertForTopVC(title: "CrewBid", message: "You have updated user account successfully")
                }
                break
            case .checkServiceTypeHelp:
                print("create user")
            case .soapCreateUser:
                print("create user")
            default: break
            }
            
        }
    }
    
    func checkForDifference(){
        let arrHeader = Array(dicLocalUserInfo.keys)
        var dicCommonDiffInfo: [String: String] = [:]
        for key in arrHeader {
                let locValue = "\(dicLocalUserInfo[key] ?? "")"
                let dbValue = "\(dicTempUserInformation[key] ?? "")"

                if locValue.lowercased() != dbValue.lowercased() {
                    if ["AcceptEmail", "CellPhone", "EmpNum", "Password",
                        "LastName", "FirstName", "Position", "CarrierNum"].contains(key) {

                        dicCommonDiffInfo[key] = "\(dicLocalUserInfo[key] ?? ""),\(dicTempUserInformation[key] ?? "")"
                    }
                }
            }
        
        let arrCommonHeader = Array(dicCommonDiffInfo.keys)
        if !arrCommonHeader.isEmpty {
            showDifferenceWindow(filteredDic: dicCommonDiffInfo, commonHeader: arrCommonHeader)
        } else {
            let tempIsMail = switchMail.isOn
            if tempIsMail != app.ObjUserAccount?.isAcceptMail {
                self.updateUserAccount()
                return
            }
            setLocalUserInfo()
            localAccountCreation()
            AlertService.showAlertForTopVC(title: "CrewBid", message: "CrewBid")
        }
    }
    
    func updateUserAccount() {
        if app.connectedToInternet() {
            CBGlobalMethods.shared.showActivityIndicator(bgColor: CBColor.purple)
            app.sc?.delegate = self
            webType = .updateUser
            setLocalUserInfo()
            objDataBuilder.updateUserAccount(employeeDetails: dicLocalUserInfo)
        } else {
            AlertService.showAlertForTopVC(title: "Network not available!", message: "Please check your internet connection")
        }
    }
    
    func localAccountCreation(){
        app.ObjUserAccount?.cellPhone = dicLocalUserInfo["CellPhone"] as? String ?? ""
        app.ObjUserAccount?.firstName = dicLocalUserInfo["FirstName"] as? String ?? ""
        app.ObjUserAccount?.lastName = dicLocalUserInfo["LastName"] as? String ?? ""
        app.ObjUserAccount?.employeeNumber = dicLocalUserInfo["EmpNum"] as? String ?? ""
        app.ObjUserAccount?.email = dicLocalUserInfo["Email"] as? String ?? ""
        app.ObjUserAccount?.position = dicLocalUserInfo["Position"] as? Int ?? 0
        app.ObjUserAccount?.isAcceptMail = (dicLocalUserInfo["AcceptEmail"] as? String ?? "0") == "1"
        app.ObjUserAccount?.CarrierNum = Int(dicLocalUserInfo["CarrierNum"] as? String ?? "") ?? 0
        app.ObjUserAccount?.UserAccountDateTime = dicLocalUserInfo["UserAccountDateTime"] as? String ?? ""
        app.ObjUserAccount?.saveUserInfo()
    }
    
    func showDifferenceWindow(filteredDic:[String:Any],commonHeader arrayCommonHeader:[String]){
        let storyboard = UIStoryboard(name: "HelpMenu", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "CBDifferentAccountDetailsVC") as! CBDifferentAccountDetailsVC
        vc.diffDict = filteredDic
        vc.dicLocalAccountInfo = dicLocalUserInfo
        vc.arrCommonHeader = arrayCommonHeader
        vc.isFromAccount = true
        vc.preferredContentSize = CGSize(width: 764, height: 630)
        self.present(vc, animated: true, completion: nil)
    }
    
    func responseStatus(_ responseStatus: Int) {
        print("response status")
    }
    
    func connectionFailed() {
        print("connection failed")
    }
    
    func requestFailed() {
        print("request failed")
    }
    
    func connectionDataReceived(_ progress: Float) {
        print("connection data received")
    }
    

    
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
    var carrierIndex:Int!
    var webType:UserWebType?
    let objDataBuiler = ODataBuilder()
    var dicLocalUserInfo: [String: Any] = [:]
    var dicTempUserInformation: [String: Any] = [:]
    let objDataBuilder = ODataBuilder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if CBUserAccountDetail.shared.isUserInfoAvailable(){
            setupAccountValues()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(setupAccountValues), name: Notification.Name("setupAccountValues"), object: nil)
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
    
    
    @objc func setupAccountValues(){
        firstName.text = app.ObjUserAccount?.firstName
        lastName.text = app.ObjUserAccount?.lastName
        email.text = app.ObjUserAccount?.email
        confirmEmail.text = app.ObjUserAccount?.email
        cellPhone.text = app.ObjUserAccount?.cellPhone
        empNumber.text = app.ObjUserAccount?.employeeNumber
        
        if app.ObjUserAccount?.isAcceptMail == true{
            switchMail.isOn = true
        }else{
            switchMail.isOn = false
        }
        
        if app.ObjUserAccount?.position == 3{
            positionControl.selectedSegmentIndex = 1
        }else{
            positionControl.selectedSegmentIndex = 0
        }
        
        cellCarrier.selectedIndex = nil
        if cellCarrier.optionArray.indices.contains(app.ObjUserAccount?.CarrierNum ?? 0){
            cellCarrier.text = cellCarrier.optionArray[app.ObjUserAccount?.CarrierNum ?? 0]
            cellCarrier.isSearchEnable = false
            carrierIndex = app.ObjUserAccount?.CarrierNum
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
        if app.objNetworkType == .free{
            AlertService.showAlertForTopVC(title: "Network not available!", message: "You are on the plane using the free company limited internet connection.\nYou cannot update account information using the limited internet connection.Either pay for a full internet connection or wailt until you get on the ground and have a full internet connection")
            return
        }
        
        if (firstName.text!.count == 0) {
            AlertService.showAlertForTopVC(title: "Warning!", message: "Please enter First name")
            return
        }else if self.isValidString(firstName.text!) == false{
            AlertService.showAlertForTopVC(title: "Warning!", message: "Please enter valid First name")
            return
        }
        
        if (lastName.text!.count == 0) {
            AlertService.showAlertForTopVC(title: "Warning!", message: "Please enter Last name")
            return
        }else if self.isValidString(lastName.text!) == false{
            AlertService.showAlertForTopVC(title: "Warning!", message: "Please enter valid Last name")
            return
        }
        
        if (empNumber.text!.count == 0) {
            AlertService.showAlertForTopVC(title: "Warning!", message: "Please enter Employee number")
            return
        }else if self.isValidString(empNumber.text!) == false{
            AlertService.showAlertForTopVC(title: "Warning!", message: "Please enter valid Employee number")
            return
        }
        
        if (email.text!.count == 0){
            AlertService.showAlertForTopVC(title: "Warning!", message: "Please enter Email address")
            return
        }else if self.isValidEmail(email.text!) == false{
            AlertService.showAlertForTopVC(title: "Warning!", message: "Please enter valid Email address")
            return
        }
        
        if email.text! != confirmEmail.text! {
            AlertService.showAlertForTopVC(title: "Warning!", message: "Email addresses do not match")
            return
        }
        
        if (cellPhone.text!.count == 0){
            AlertService.showAlertForTopVC(title: "Warning!", message: "Please enter Cell phone number")
            return
        }else if (cellPhone.text!.count < 12){
            AlertService.showAlertForTopVC(title: "Warning!", message: "Invalid Cell Number eg: xxx-xxx-xxxx format.")
            return
        }
        if cellCarrier.optionArray.contains(self.cellCarrier.text!){
            carrierIndex = cellCarrier.optionArray.firstIndex(of: self.cellCarrier.text!) ?? 1
        }
        if carrierIndex == nil {
            AlertService.showAlertForTopVC(title: "Warning!", message: "Please select a cell carrier")
            return
        }
        
        checkIfEmailExist()
        
    }
    
    func checkIfEmailExist(){
        if app.connectedToInternet(){
            self.setLocalUserInfo()
            webType = .webUserExist
            CBGlobalMethods.shared.showActivityIndicator(bgColor: CBColor.purple)
            app.sc?.delegate = self
            objDataBuiler.checkUserExistOrNot(empNumber.text!)
        }else{
            AlertService.showAlertForTopVC(title: "Network not available!", message: "Please check your internet connection")
        }
    }
    
    
    func setLocalUserInfo(){
        dicLocalUserInfo["CellPhone"] = cellPhone.text ?? ""
        dicLocalUserInfo["FirstName"] = firstName.text ?? ""
        dicLocalUserInfo["LastName"] = lastName.text ?? ""
        dicLocalUserInfo["EmpNum"] = empNumber.text?.replacingOccurrences(of: "e", with: "").replacingOccurrences(of: "x", with: "") ?? ""
        dicLocalUserInfo["Email"] = email.text ?? ""
        
        if switchMail.isOn{
            dicLocalUserInfo["AcceptEmail"] = "1"
        }else{
            dicLocalUserInfo["AcceptEmail"] = "0"
        }
        
        if positionControl.selectedSegmentIndex == 0 {
            dicLocalUserInfo["Position"] = "\(4)"
        }else{
            dicLocalUserInfo["Position"] = "\(3)"
        }
        
        dicLocalUserInfo["CarrierNum"] = "\(carrierIndex ?? 0)"
        
        let format = DateFormatter()
        format.dateFormat = "MMM/dd/yyyy hh:mm a"
        let now = Date()
        let startDate = now.timeIntervalSince1970 * 1000
        let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)
        
        dicLocalUserInfo["UserAccountDateTime"] = dateStarted
        
    }
    
    @IBAction func BtnPrivacyAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "HelpMenu", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedPrivacyVC")
        vc.preferredContentSize = CGSize(width: 600, height: 600)
        present(vc, animated: true)
    }
    
    @IBAction func BtnLicenceAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "HelpMenu", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedLicenseVC")
        vc.preferredContentSize = CGSize(width: 600, height: 600)
        present(vc, animated: true)
    }
    
    func isValidString(_ string: String) -> Bool{
        let set = CharacterSet.whitespaces
        if string.trimmingCharacters(in: set).length == 0{
            return false
        }
        return true
    }
    
    func isValidEmail(_ emailStr: String) -> Bool{
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if emailTest.evaluate(with: emailStr) == true {
            return true
        }else{
            return false
        }
    }
    
}
