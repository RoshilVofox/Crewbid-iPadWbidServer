//
//  JobShareViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 17/05/25.
//

import UIKit

class JobShareViewController: UIViewController {
    @IBOutlet weak var txtJobShare1: UITextField!
    @IBOutlet weak var txtJobShare2: UITextField!
    @IBOutlet weak var btnCheckBox: UIButton!
    var isChecked: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    func setupUI() {
        txtJobShare1.text = "21221"
        txtJobShare1.isEnabled = false
        
        txtJobShare1.delegate = self
        txtJobShare2.becomeFirstResponder()
        txtJobShare2.delegate = self
        
        btnCheckBox.setTitle("", for: .normal)
    }

    @IBAction func btnOkAction(_ sender: Any) {
    }
    
    @IBAction func btnClearFeildsAction(_ sender: Any) {
        txtJobShare2.text = ""
    }
    
    @IBAction func btnCancelAction(_ sender: Any) {
        // Pop the current view controller
        navigationController?.popViewController(animated: false)

        // Push the new view controller after the current one is popped
        
            let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "CBSubmitCredentialVC") as! CBSubmitCredentialVC
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            self.navigationController?.pushViewController(vc, animated: true)
    
    }

    
    @IBAction func btnBackAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnChekboxAction(_ sender: Any) {
        isChecked.toggle()  // Shorter toggle syntax

        let imageName = isChecked ? "checkmark.square" : "unCheckBox"
        let checkBoxImage = UIImage(systemName: imageName)
        btnCheckBox.setBackgroundImage(nil, for: .normal)
        btnCheckBox.setBackgroundImage(checkBoxImage, for: .normal)
    }

    
}

extension JobShareViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == txtJobShare2 || textField == txtJobShare1 {
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
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        textField.layer.borderColor = UIColor.gray.cgColor
    }
    
}
