//
//  CBDefaultEmployeeVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBDefaultEmployeeVC: UIViewController {

    @IBOutlet weak var textEmpNum: customUITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    func setupUI(){
        textEmpNum.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textEmpNum.frame.height))
        textEmpNum.leftViewMode = .always
        textEmpNum.delegate = self
    }
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBBiddataDownloadVC") as! CBBiddataDownloadVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension CBDefaultEmployeeVC : UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == textEmpNum {
            // Limit characters to 7
            let currentText = textField.text ?? ""
            let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
            // Check if prospectiveText length is more than 7
            if prospectiveText.count > 7 {
                return false
            }
            let allowedCharacters = CharacterSet(charactersIn:"0123456789")//Here change this characters based on your requirement
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == textEmpNum {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.purple.cgColor
        } else {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.darkGray.cgColor
        }
    }
}
