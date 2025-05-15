//
//  CBAlertVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

enum AlertType: Int{
    case inCorrectCredentials = 0
    case none = 1
}

class CBAlertVC: BaseViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tryAgainBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    var isFromLoginPage:Bool = false
    var alertType:AlertType = .inCorrectCredentials
    var fromView:UIViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        switch alertType {
        case .inCorrectCredentials:
            let alertString = NSMutableAttributedString()
                .normal("To LOGIN, you need to use your ")
                .bold("SwaLife")
                .normal(" password!\n\nMost likely, your ")
                .bold("SwaLife")
                .normal(" password has expired.\n\nBTW, it is possible your password to LOGIN on ")
                .bold("swacrew.com")
                .normal(" is valid and your ")
                .bold("SwaLife")
                .normal(" password is expired.\n\n The only way to fix this problem is to go to the Swalife Password Manager and change your password. ")
            textView.attributedText = alertString
            textView.textColor = .label
            break
        case .none:
            break
        }
    }
    func setupUI(){
        if isFromLoginPage == false{
            tryAgainBtn.isHidden = false
        }else{
            tryAgainBtn.isHidden = true
        }
        tryAgainBtn.layer.cornerRadius = 5
        tryAgainBtn.layer.borderWidth = 1
        tryAgainBtn.layer.borderColor = UIColor.black.cgColor
        cancelBtn.layer.cornerRadius = 5
        cancelBtn.layer.borderWidth = 1
        cancelBtn.layer.borderColor = UIColor.black.cgColor
        
    }
    @IBAction func tryBtnAction(_ sender: Any) {
        if (fromView?.isKind(of: CBCredentialsPageVC.self)) != nil{
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
                if ((self.fromView?.isKind(of: CBSubmitCredentialVC.self)) != nil){
                    NotificationCenter.default.post(name: NSNotification.Name("dismissLoginView"), object: self)
                    
                }
            });
        }
    }
}
