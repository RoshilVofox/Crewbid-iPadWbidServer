//
//  CBAwardsRetrievalViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 17/04/25.
//

import UIKit

class CBAwardsRetrievalViewController: UIViewController {
    
    
    @IBOutlet weak var txtEmpNum: customUITextField!
    @IBOutlet weak var txtPassword: customUITextField!
    @IBOutlet weak var btnClose: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        txtPassword.delegate = self
        txtEmpNum.delegate = self
        btnClose.setTitle("", for: .normal)

        
    }
    
    @IBAction func btnShowPasswordAction(_ sender: Any) {
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnGoAction(_ sender: Any) {
        if let presentingVC = self.presentingViewController {
            self.dismiss(animated: true) {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBShowAwardsViewController") as! CBShowAwardsViewController
                vc.modalPresentationStyle = .fullScreen
                presentingVC.present(vc, animated: true)
            }
        }
    }
}

extension CBAwardsRetrievalViewController: UITextFieldDelegate {
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
