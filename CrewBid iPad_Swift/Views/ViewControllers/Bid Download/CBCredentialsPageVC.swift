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
    
    var isFromHistoric : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
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
        loginAction()
    }
    
    func setupUI(){
        txtUserID.delegate = self
        txtPassword.delegate = self
        
        txtUserID.textContentType = .username
        txtPassword.textContentType = .password
        
        if isFromHistoric == true {
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
    
    func verifyBidInfoFileDownload(completion: @escaping (_ shouldDownload: Bool, _ shouldOpen: Bool) -> Void) {
        
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
    
    func loginAction(){
        var userIDParam = txtUserID.text!
        if txtUserID.text!.prefix(1) != "x" && txtUserID.text!.prefix(1) != "e" {
            if txtUserID.text! == DevUserID {
                userIDParam = "x\(txtUserID.text!)"
            } else {
                userIDParam = "e\(txtUserID.text!)"
            }
        }
        txtUserID.text! = userIDParam
        UserDefaults.standard.set(txtUserID.text, forKey: KCBEmpNumWithPrefix)
        
        
        
        
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
