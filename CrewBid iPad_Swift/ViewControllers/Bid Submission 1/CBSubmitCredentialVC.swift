

import UIKit

class CBSubmitCredentialVC: UIViewController {
    
    
    @IBOutlet weak var txtEmpNum: customUITextField!
    
    @IBOutlet weak var txtPassword: customUITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        finalAlert()
    }


    @IBAction func btnDismissActiomn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBAction func btnGoAction(_ sender: Any) {
        if let presentingVC = self.presentingViewController {
            self.dismiss(animated: true) {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "SubmissionErrorVC") as! SubmissionErrorVC
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                presentingVC.present(vc, animated: true)
            }
        }
        
    }
    @IBAction func btnShowPasswordAction(_ sender: Any) {
    }
    
    func finalAlert() {
        let alert = UIAlertController(
            title: "Buddy Bidding Terms",
            message: "By continuing, you represent that you have the permission of your buddy or buddies to Buddy Bid with them and you have taken the necessary steps inSwA lite to out them on vour BuddyBidding list.I Understand and Accept",
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "ok", style: .cancel)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}
