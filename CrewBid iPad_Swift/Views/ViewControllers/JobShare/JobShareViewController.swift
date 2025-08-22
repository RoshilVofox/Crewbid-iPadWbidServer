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
    @IBOutlet weak var domicileLbl: UILabel!
    @IBOutlet weak var empNameLbl: UILabel!
    var isChecked: Bool = false
    var bidPeriod = BIBidPeriod()
    var FAListDict:[String:Any]? = nil
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    func setupUI() {
        txtJobShare1.text = self.bidPeriod.crewIdentifier?.stringValue
        txtJobShare1.isEnabled = false
        txtJobShare1.isUserInteractionEnabled = false
        txtJobShare1.textColor = UIColor.darkGray
        txtJobShare2.becomeFirstResponder()
        txtJobShare2.delegate = self
        btnCheckBox.setTitle("", for: .normal)
        empNameLbl.isHidden = true
        domicileLbl.isHidden = true
        FAListDict = CBUtils.readJSONStringFromFile()
        
        txtJobShare2.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
    }

    @IBAction func btnOkAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
        vc.type = "Submit Bid"
        vc.bidPeriod = self.bidPeriod
        vc.jobShare1 = self.txtJobShare1.text ?? ""
        vc.jobShare2 = self.txtJobShare2.text ?? ""
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        self.navigationController?.pushViewController(vc, animated: true)
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
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let empDict = self.FAListDict?[textField.text!] as? [String: Any]
        let empName = empDict?["Name"]
        let empDomicile = empDict?["Domicile"]
        if empName == nil{
            domicileLbl.isHidden = true
            empNameLbl.isHidden = true
        }else{
            domicileLbl.isHidden = false
            domicileLbl.text = empDomicile as? String
            empNameLbl.isHidden = false
            empNameLbl.text = empName as? String
            empNameLbl.textColor = CBColor.buddyTextColor
        }
    }
    
    
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
