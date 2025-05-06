//
//  CBLineNumberController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 17/04/25.
//

import UIKit

class CBLineNumberController: UIViewController {

    @IBOutlet weak var txtLineNumber: customUITextField!
    @IBOutlet weak var txtPosition: customUITextField!
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var btnClose: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtPosition.delegate = self
        txtLineNumber.delegate = self
        btnClose.setTitle("", for: .normal)

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
    }
    
    @IBAction func btnGoAction(_ sender: Any) {
    }
    
}

extension CBLineNumberController: UITextFieldDelegate {
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
