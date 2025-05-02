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
        // Do any additional setup after loading the view.
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
}


extension CBCredentialsPageVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var shouldChangeCharacters: Bool = true
            // Make sure that userid text field always has leading 'e' and all digits
            // after that.
        if textField == txtUserID {
            var validUserid: Bool = true
            let inverseSet = NSCharacterSet(charactersIn:"0123456789").inverted
            let components = string.components(separatedBy: inverseSet)
            let filtered = components.joined(separator: "")
                // Prevent changing leading 'e', which is entered in the
                // useridTextField in the viewWillAppear: method.
            // Get the current text in the text field
            if let currentText = textField.text {
                // Allow deletion
                if string.isEmpty {
                    return true
                }
                
                // If the entire text is selected and about to be replaced, check the new string for validity
                if range.length == currentText.count {
                    if string.hasPrefix("e") || string.hasPrefix("x") {
                        // Allow replacement if it starts with 'e' or 'x', followed by digits
                        let newStringWithoutPrefix = String(string.dropFirst())
                        let newStringIsValid = newStringWithoutPrefix.rangeOfCharacter(from: inverseSet) == nil
                        return newStringIsValid
                    } else if string.rangeOfCharacter(from: inverseSet) == nil {
                        // Allow pure numbers (e.g., 21221)
                        return true
                    } else {
                        // Reject if it contains invalid characters
                        return false
                    }
                }
                
                // If the current text already starts with 'e' or 'x', prevent adding another 'e' or 'x'
                if currentText.hasPrefix("e") || currentText.hasPrefix("x") {
                    if string == "e" || string == "x" {
                        return false
                    }
                    // Prevent any characters from being added at the start if 'e' or 'x' is already present
                    if range.location == 0 {
                        return false
                    }
                }
            }
            if 0 == range.location {
                validUserid = false
                if string == "" {
                    validUserid = true
                } else if string.count > 0 && (( string.first == "e" ) || (string.first == "x") || string == filtered){
                    validUserid = true
                }
            }
            else {
                return string == filtered
            }
            if !validUserid {
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
    func loginAction(){
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
