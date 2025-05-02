

import UIKit

class CBOptionalEmployeesPageViewController: UIViewController {
    
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var txtEmpNum1: customUITextField!
    @IBOutlet weak var lblOptionalUser1: UILabel!
    @IBOutlet weak var txtEmpNum2: customUITextField!
    @IBOutlet weak var lblOptionalUser2: UILabel!
    @IBOutlet weak var txtEmpNum3: customUITextField!
    
    @IBOutlet weak var optionalUser1Domicile: UILabel!
    @IBOutlet weak var optionalUser2Domicile: UILabel!
    
    @IBOutlet weak var lblWarning: UILabel!
    @IBOutlet weak var lblBuddyBid: UILabel!
    
    @IBOutlet weak var lblTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

       
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func btnNextAction(_ sender: Any) {
        if let presentingVC = self.presentingViewController {
            self.dismiss(animated: true) {
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBSubmitCredentialVC") as! CBSubmitCredentialVC
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                presentingVC.present(vc, animated: true)
            }
        }
    }
    
}
