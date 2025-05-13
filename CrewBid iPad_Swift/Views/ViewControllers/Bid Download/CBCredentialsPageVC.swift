//
//  CBCredentialsPageVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

class CBCredentialsPageVC: UIViewController {
    
    @IBOutlet weak var txtUserID: customUITextField!
    @IBOutlet weak var txtPassword: customUITextField!
    @IBOutlet weak var showPasswordBtn: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    var bidDownload = BIBidFileDownload()
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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if CBUtils.isRunningOnSimulator(){
            self.txtUserID.text = DevUserID
            self.txtPassword.text = DevUserPassword
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
//    MARK: ======================
//        goAction()
        self.bidDownload.checkCrewBidLogin()
    }
    func goAction(){
        UserDefaults.standard.set(txtUserID.text, forKey: KCBEmpNumWithPrefix)
        if (txtUserID.text!.count < 2) || (txtUserID.text!.count > 8) {
            self.shakeTextField(textField: txtUserID)
            return
        }else if (txtPassword.text!.count < 4){
            self.shakeTextField(textField: txtPassword)
            return
        }else{
            self.loginAction()
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
    }
    
    func stringFormatter(_ string: String) -> String {
        var encodedString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        encodedString = encodedString.replacingOccurrences(of: "+", with: "%2B")
        return encodedString
    }
}



extension CBCredentialsPageVC: UITextFieldDelegate {
    
    
    func shakeTextField(textField: UITextField){
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: textField.center.x - 10, y: textField.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: textField.center.x + 10, y: textField.center.y))
        textField.layer.add(animation, forKey: "position")
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
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
    
    func loginAction(){
        
        UserDefaults.standard.set(txtUserID.text, forKey: KCBEmpNumWithPrefix)
        var userID = txtUserID.text!
        if txtUserID.text!.prefix(1) != "x" && txtUserID.text!.prefix(1) != "e" {
            if txtUserID.text! == DevUserID {
                userID = "x\(txtUserID.text!)"
            } else {
                userID = "e\(txtUserID.text!)"
            }
        }
        txtUserID.text! = userID
        bidDownload.retrievePreLogonKey(completionHandler: { (response:String?) in
            let preLoginKey = response!
            CBGlobalMethods.shared.secretKey = preLoginKey
            print("preLoginKey: \(preLoginKey)")
            DispatchQueue.main.async {
                self.bidDownload.retrieveSessionKey(username: self.txtUserID.text!, password: self.txtPassword.text!, preloginKey: preLoginKey, completionHandler: { (response:String?) in
                    print("Response2: \(response!)")
                    
                })
            }
         
        })
        self.bidDownload.downloadBidDataFiles()
        
        
        self.dismiss(animated: false)
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
}

