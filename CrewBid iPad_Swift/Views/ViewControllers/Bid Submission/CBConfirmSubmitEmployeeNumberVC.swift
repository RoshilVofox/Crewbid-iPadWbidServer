//
//  CBConfirmSubmitEmployeeNumberVC.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 15/05/25.
//

import UIKit

class CBConfirmSubmitEmployeeNumberVC:
    UIViewController {
    
    var employeeNumber: String = ""
    @IBOutlet weak var txtEmpNum: customUITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtEmpNum.delegate = self
        txtEmpNum.becomeFirstResponder()
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        confirmSubmitBidAlert()
    
    }
    
    func confirmSubmitBidAlert() {
        if txtEmpNum.text == employeeNumber{
            if AppData.shared.postion == "FA" && AppData.shared.Round == 1 {
                let alert = UIAlertController(
                    title: "Alert",
                    message: "If you are Buddy Bidding you need to verify that you are buddy bidders on your Buddy list, and they know you are buddy bidding with them.",
                    preferredStyle: .alert
                )
                let buddyBiddingAction = UIAlertAction(title: "I have Verified", style: .default) { _ in
                    self.buddyBidSelected()
                }
                let notBuddyBiddingAction = UIAlertAction(title: "I am not Buddy Bidding", style: .default) { _ in
                    self.buddyBidNotSelected()
                }
                alert.addAction(buddyBiddingAction)
                alert.addAction(notBuddyBiddingAction)
                present(alert, animated: true)
            }
            else if AppData.shared.postion == "FO" && AppData.shared.Round == 1 {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBAvoidaceBidViewController") as! CBAvoidaceBidViewController
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBSubmitCredentialVC") as! CBSubmitCredentialVC
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        else {
            let alert = UIAlertController(
                title: "Alert",
                message: "The entered employee number does not match the original entry. Please check and try again.",
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(title: "OK", style: .cancel)
            alert.addAction(cancelAction)
            present(alert, animated: true)
        }
    }
    
    func buddyBidSelected() {
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBOptionalEmployeesPageViewController") as! CBOptionalEmployeesPageViewController
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func buddyBidNotSelected() {
        jobShareAlert()
       
    }
    
    func jobShareAlert() {
        let alert = UIAlertController(
            title: "Job Share",
            message: "Do you want job share?",
            preferredStyle: .alert
        )
        //        MARK: - wait
        let okAction = UIAlertAction(title: "Yes", style: .default) { _ in
            let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "JobShareViewController") as! JobShareViewController
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "No", style: .cancel) { _ in
            let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBSubmitCredentialVC") as! CBSubmitCredentialVC
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

extension CBConfirmSubmitEmployeeNumberVC: UITextFieldDelegate {
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
