


import UIKit

class CBSubmissionCertifyVC: UIViewController {
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var certifyLabel: UILabel!
    @IBOutlet weak var imgvw: UIImageView!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    private let viewModel = CBDefaultEmployeeViewModel()
    var bidderEmpNum = ""
    var submittedEmpNum = ""
    var submittedEmpName = ""
    var delegate:submissionGoActiondelegate? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        if CBGlobalMethods.shared.certifiedLastName == "" || CBGlobalMethods.shared.certifiedFirstName == ""{
            self.firstLabel.text = "We have detected that you (\(self.bidderEmpNum)) are attempting to submit a bid for employee \(self.submittedEmpNum)."
        }else{
            self.firstLabel.text = "We have detected that you (\(self.bidderEmpNum)) are attempting to submit a bid for employee \(self.submittedEmpNum) (\(CBGlobalMethods.shared.certifiedFirstName) \(CBGlobalMethods.shared.certifiedLastName))."
        }
        let text = "If this is correct, then check the CERTIFY CHECK BOX below, otherwise if this is a mistake, then click on CANCEL."
        let attributedText = NSMutableAttributedString(string: text)
        
        // Define the attributes for the bold text
        let boldFontAttribute: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: self.secondLabel.font.pointSize)]
        
        // Apply bold to "certify check box"
        if let certifyRange = text.range(of: "CERTIFY CHECK BOX") {
            let nsRange = NSRange(certifyRange, in: text)
            attributedText.addAttributes(boldFontAttribute, range: nsRange)
        }
        
        // Apply bold to "CANCEL"
        if let cancelRange = text.range(of: "CANCEL") {
            let nsRange = NSRange(cancelRange, in: text)
            attributedText.addAttributes(boldFontAttribute, range: nsRange)
        }
        
        self.secondLabel.attributedText = attributedText
        self.imgvw.image = UIImage(named: "unchecked")
        if (CBGlobalMethods.shared.certifiedLastName == "" || CBGlobalMethods.shared.certifiedFirstName == ""){
            self.certifyLabel.text = "I certify that I have permission from \(self.submittedEmpNum) to submit a bid for them."
        }
        else{
            self.certifyLabel.text = "I certify that I have permission from \(self.submittedEmpNum) (\(CBGlobalMethods.shared.certifiedFirstName) \(CBGlobalMethods.shared.certifiedLastName)) to submit a bid for them."
        }
        certifyLabel.textColor = UIColor.red
//        self.submitBtn.backgroundColor = CBColor.customGreenColor
        self.submitBtn.backgroundColor = .lightGrey
//        self.submitBtn.isHidden = true
        self.submitBtn.isUserInteractionEnabled = false
    }
    
    @IBAction func btnCheckBoxAction(_ sender: Any) {
        if self.imgvw.image == UIImage(named: "checked") {
            self.imgvw.image = UIImage(named: "unchecked")
            certifyLabel.textColor = .red
//            submitBtn.isHidden = true
            self.submitBtn.isUserInteractionEnabled = false
            self.submitBtn.backgroundColor = .lightGrey
            CBGlobalMethods.shared.certified = false
        } else {
            self.imgvw.image = UIImage(named: "checked")
            certifyLabel.textColor = CBColor.customGreenColor
//            submitBtn.isHidden = false
            self.submitBtn.isUserInteractionEnabled = true
            self.submitBtn.backgroundColor = CBColor.customGreenColor
            CBGlobalMethods.shared.certified = true
        }
    }
    
    @IBAction func btnCancelAction(_ sender: Any) {
        CBGlobalMethods.shared.certified = false
        self.dismiss(animated: true)
    }
    
    @IBAction func btnSubmitAction(_ sender: Any) {
        CBGlobalMethods.shared.bid4empnum = submittedEmpNum
        CBGlobalMethods.shared.bidder = bidderEmpNum
        delegate?.goActionFromSubmitCertifyDelegate()
        self.dismiss(animated: true)
//        viewModel.checkAuthentication(empID: bidderEmpNum!)
    }
    
    
    func handleAuthResult(_ result: AuthResult) {
        let msg = result.message ?? ""
//        guard let empID = textEmpNum.text else {return}
        if msg == "Invalid Account" || msg == "For security purposes, all users need a CrewBid or WBidMax account.  Go to www.crewbidmax.com and create an account" {
//            showAlert(message: "User \(empID) does not have a CrewBid account. Go to www.crewbid.com to create the account.")
        } else if msg == "Subscription Expired" && !result.isSomehowSubscribed {
//            showAlert(message: "User \(empID) does not have a valid subscription with Crewbid Account. Please Subscribe.")
        } else if msg.contains("Your subscription to CrewBid has expired.  Go to www.crewbid.com and re-subscribe - Go to crewbid.com") && !result.isSomehowSubscribed {
//            showAlert(message: msg)
        }
    }
    
}
