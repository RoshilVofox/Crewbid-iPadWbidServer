//
//  CBAlertVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

enum CBRetryFlow {
    case bidDownload
    case bidSubmission
}

class CBAlertVC: BaseViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tryAgainBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    var alertTitle:String?
    var attributedMessage:NSAttributedString?
    var fromView:UIViewController?
    var isSimpleAlert: Bool = false
    var retryFlow: CBRetryFlow? = .bidDownload
    var bidPeriod: BIBidPeriod?
    var empName: String?
    var confirmEmpNum: String?
    
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
//            switch self.retryFlow {
//            case .bidDownload:
//                NotificationCenter.default.post(
//                    name: NSNotification.Name("dismissLoginView"),
//                    object: nil
//                )
//                guard let sourceVC = self.fromView else { return }
//
//                if let presentingVC = sourceVC.presentingViewController {
//                    presentingVC.dismiss(animated: false) {
//                        AppNavigation.startNewBidFlow(from: presentingVC)
//                    }
//                } else {
//                    AppNavigation.startNewBidFlow(from: sourceVC)
//                }
//
//            case .bidSubmission:
//                guard let sourceVC = self.fromView else { return }
//                if let presentingVC = sourceVC.presentingViewController {
//                    presentingVC.dismiss(animated: false) {
//                        AppNavigation.restartBidSubmissionFlow(
//                            from: presentingVC,
//                            empName: self.empName,
//                            bidPeriod: self.bidPeriod
//                        )
//                    }
//                } else {
//                    AppNavigation.restartBidSubmissionFlow(
//                        from: sourceVC,
//                        empName: self.empName,
//                        bidPeriod: self.bidPeriod
//                    )
//                }
//
//
//
//            case .none:
//                break
//            }
        }
    }
    
    @IBAction func cancelBtnAction(_ sender: Any) {
//        navigationController?.popViewController(animated: false)
//        if navigationController == nil {
//            self.presentingViewController?.dismiss(animated: false, completion: {
//                if let _ = self.fromView as? CBCredentialsPageVC {
//                    NotificationCenter.default.post(name: .init("dismissLoginView"), object: self)
//                }
//            });
//        }
        self.dismiss(animated: true) {
            if let presentingVC = self.fromView {
                if let nav = presentingVC.navigationController {
                    nav.dismiss(animated: false)
                } else {
                    presentingVC.dismiss(animated: false)
                }
                if presentingVC is CBCredentialsPageVC {
                    NotificationCenter.default.post(
                        name: .init("dismissLoginView"),
                        object: nil
                    )
                }
            }
        }
    }
}
enum AppNavigation {

    static func startNewBidFlow(from presenter:UIViewController) {
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

            presenter.present(vc, animated: true)
        }
        let app = UIApplication.shared.delegate as! AppDelegate
        
        if let authDetails = app.ObjUserAccount?.dicLoginAuthDetails,
           authDetails.count > 0 {

            if app.connectedToInternet() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
    
    static func restartBidSubmissionFlow(
            from sourceVC: UIViewController,
            empName: String?,
            bidPeriod: BIBidPeriod?
        ) {
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(
                withIdentifier: "CBDefaultEmployeeVC"
            ) as! CBDefaultEmployeeVC
            guard let topVC = UIApplication.topViewController() else { return }
            vc.empName = empName ?? ""
            vc.type = .submitEmployeeNumber
            vc.isEmpIDVerified = false
            vc.bidPeriod = bidPeriod

            vc.preferredContentSize = CGSize(width: 600, height: 500)
            vc.isModalInPresentation = true
            
            let navController = UINavigationController(rootViewController: vc)
            navController.setNavigationBarHidden(true, animated: false)
            navController.modalPresentationStyle = .formSheet
            navController.preferredContentSize = CGSize(width: 600, height: 500)
            
            topVC.present(navController, animated: true)
        }
    
}
