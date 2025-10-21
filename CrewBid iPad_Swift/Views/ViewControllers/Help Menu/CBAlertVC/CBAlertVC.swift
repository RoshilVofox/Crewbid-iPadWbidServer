//
//  CBAlertVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

class CBAlertVC: BaseViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tryAgainBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    var alertTitle:String?
    var attributedMessage:NSAttributedString?
    var fromView:UIViewController?
    var isSimpleAlert: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.attributedText = attributedMessage
        titleLabel.text = alertTitle
        setupUI()
    }
    
    func setupUI(){
        if isSimpleAlert {
               tryAgainBtn.isHidden = true
               cancelBtn.setTitle("OK", for: .normal)
           } else {
               tryAgainBtn.isHidden = false
               cancelBtn.setTitle("Cancel", for: .normal)
           }
        tryAgainBtn.layer.cornerRadius = 5
        tryAgainBtn.layer.borderWidth = 1
        tryAgainBtn.layer.borderColor = UIColor.black.cgColor
        cancelBtn.layer.cornerRadius = 5
        cancelBtn.layer.borderWidth = 1
        cancelBtn.layer.borderColor = UIColor.black.cgColor
    }
    

    @IBAction func tryBtnAction(_ sender: Any) {
        if let _ = self.fromView as? CBCredentialsPageVC{
            navigationController?.popViewController(animated: true)
            if navigationController == nil{
                self.dismiss(animated: true)
            }
        }
    }
    
    @IBAction func cancelBtnAction(_ sender: Any) {
        navigationController?.popViewController(animated: false)
        if navigationController == nil {
            self.presentingViewController?.dismiss(animated: false, completion: {
                if let _ = self.fromView as? CBCredentialsPageVC {
                    NotificationCenter.default.post(name: .init("dismissLoginView"), object: self)
                }
            });
        }
    }
}
