//
//  CBSubmitEmployeeNumberVC.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 15/05/25.
//

import UIKit

class CBSubmitEmployeeNumberVC: UIViewController {
    @IBOutlet weak var txtEmpNum: customUITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtEmpNum.delegate = self
        txtEmpNum.becomeFirstResponder()
    }
    
    @IBAction func btnCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBConfirmSubmitEmployeeNumberVC") as! CBConfirmSubmitEmployeeNumberVC
        vc.employeeNumber = txtEmpNum.text!
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension CBSubmitEmployeeNumberVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == txtEmpNum {
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

    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text!.isEmpty {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.purple.cgColor
        } else {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.gray.cgColor
        }
    }
}
