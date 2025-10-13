//
//  CBAvoidanceBidViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 17/05/25.
//

import UIKit

class CBAvoidanceBidViewController: UIViewController {

    @IBOutlet weak var txtAvoidance1: customUITextField!
    @IBOutlet weak var txtAvoidance2: customUITextField!
    @IBOutlet weak var txtAvoidance3
    : customUITextField!
    @IBOutlet weak var lblTitle: UILabel!
    var bidPeriod: BIBidPeriod?
    var empID:String?
    var optionalEmployees = NSMutableArray()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
    }
    
    func setupUI() {
        txtAvoidance1.delegate = self
        txtAvoidance2.delegate = self
        txtAvoidance3.delegate = self
        txtAvoidance1.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtAvoidance1.frame.height))
        txtAvoidance1.leftViewMode = .always
        txtAvoidance2.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtAvoidance2.frame.height))
        txtAvoidance2.leftViewMode = .always
        txtAvoidance3.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtAvoidance3.frame.height))
        txtAvoidance3.leftViewMode = .always
        lblTitle.text = "Submit bid or Avoidance Bid bid for EID \(empID ?? "")"
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        if let text1 = txtAvoidance1.text, !text1.isEmpty {
                self.optionalEmployees.add(text1)
            }
            if let text2 = txtAvoidance2.text, !text2.isEmpty {
                self.optionalEmployees.add(text2)
            }
            if let text3 = txtAvoidance3.text, !text3.isEmpty {
                self.optionalEmployees.add(text3)
            }
        
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
        vc.type = .submitBid
        vc.bidPeriod = self.bidPeriod
        vc.defaultEmplyeeNumber = self.empID
        vc.optionalEmployees = self.optionalEmployees
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension CBAvoidanceBidViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == txtAvoidance1 || textField == txtAvoidance2 || textField == txtAvoidance3{
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
