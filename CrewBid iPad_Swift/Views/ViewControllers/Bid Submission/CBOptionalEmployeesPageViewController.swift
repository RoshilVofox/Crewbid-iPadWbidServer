

import UIKit

class CBOptionalEmployeesPageViewController: UIViewController {
    
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var txtEmpNum1: customUITextField!
    @IBOutlet weak var lblOptionalUser1: UILabel!
    @IBOutlet weak var txtEmpNum2: customUITextField!
    @IBOutlet weak var lblOptionalUser2: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    
    @IBOutlet weak var optionalUser1Domicile: UILabel!
    @IBOutlet weak var optionalUser2Domicile: UILabel!
    
    @IBOutlet weak var lblWarning: UILabel!
    @IBOutlet weak var lblBuddyBid: UILabel!
    
    @IBOutlet weak var lblTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        txtEmpNum1.delegate = self
        txtEmpNum2.delegate = self
        optionalUser1Domicile.isHidden = true
        optionalUser2Domicile.isHidden = true
        lblOptionalUser1.text = ""
        lblOptionalUser2.text = ""
        btnClose.setTitle("", for: .normal)
        btnNext.setTitle("", for: .normal)
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        finalAlert()
    }
    
    func finalAlert() {
        let alert = UIAlertController(
            title: "Buddy Bidding Terms",
            message: "By continuing, you represent that you have the permission of your buddy or buddies to Buddy Bid with them and you have taken the necessary steps inSwA lite to out them on vour BuddyBidding list.I Understand and Accept",
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "OK", style: .default) { _ in
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
            vc.type = "Submit Bid"
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
}

extension CBOptionalEmployeesPageViewController: UITextFieldDelegate {
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
