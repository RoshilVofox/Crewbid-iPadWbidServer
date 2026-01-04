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
        self.view.layer.masksToBounds = true
        self.view.layer.cornerRadius = 10
        self.view.layer.borderWidth = 5
        self.view.layer.borderColor = UIColor.gray.cgColor
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textAlignment = .center
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
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
        dismiss(animated: true) {
            AppNavigation.startNewBidFlow()
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
enum AppNavigation {

    static func startNewBidFlow() {
        UserDefaults.standard.set(
            false,
            forKey: "isSecretForAllDomicileDownloadEnabled"
        )

        guard let topVC = UIApplication.topViewController() else { return }

        let presentNewBid: () -> Void = {
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(
                withIdentifier: "CBNewBidVC"
            ) as! CBNewBidVC

            vc.preferredContentSize = CGSize(width: 600, height: 550)
            vc.modalTransitionStyle = .crossDissolve
            vc.isModalInPresentation = true

            topVC.present(vc, animated: true)
        }
        let app = UIApplication.shared.delegate as! AppDelegate
        
        if let authDetails = app.ObjUserAccount?.dicLoginAuthDetails,
           authDetails.count > 0 {

            if app.connectedToInternet() {
                topVC.view.showActivityIndicator(
                    message: "Checking User Account"
                )

                CBSubscriptionInfoController()
                    .updateSubscriptionDetails(silent: true)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    topVC.view.hideActivityIndicator()
                    presentNewBid()
                }

            } else {
                let alert = UIAlertController(
                    title: "Network not available!!",
                    message: "Please check your internet connection",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                topVC.present(alert, animated: true)
            }
        } else {
            presentNewBid()
        }
    }
}
