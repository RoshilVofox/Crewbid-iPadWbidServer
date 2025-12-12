//
//  CBMonthToMonthAlertVC.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 02/08/25.
//

import UIKit

protocol CBMonthToMonthAlertDelegate: AnyObject {
    func monthToMonthViewDismissed() -> Void
}

class CBMonthToMonthAlertVC: UIViewController {
    
    
    @IBOutlet weak var content: UITextView!
    var text = ""
//    var delegate: CBMonthToMonthAlertDelegate?
    var onDismiss: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 700, height: 500)
        content.text = text
        // Do any additional setup after loading the view.
    }
    

//    func showAlertFromViewController(from viewController: UIViewController, tappedOK: @escaping (Bool) -> Void) {
//        self.modalPresentationStyle = .overFullScreen
//        self.modalTransitionStyle = .crossDissolve
//        viewController.present(self, animated: true, completion: nil)
//        self.tapOkBlock = tappedOK
//    }
    
    // Action method when the first link button is tapped
    @IBAction func linkBtn1Tapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let monthToMonthPdf = storyboard.instantiateViewController(withIdentifier: "CBMonthToMonthPdfVC") as! CBMonthToMonthPdfVC
        monthToMonthPdf.titles = ""
        monthToMonthPdf.modalPresentationStyle = .overFullScreen
        monthToMonthPdf.modalTransitionStyle = .crossDissolve
        monthToMonthPdf.urlString = "https://www.wbidmax.com/downloads/swa/The Limitations and Opportunity of a Month-to-Month Vacation.pdf"
        self.present(monthToMonthPdf, animated: true, completion: nil)
    }
    
    @IBAction func linkBtn2Tapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let monthToMonthPdf = storyboard.instantiateViewController(withIdentifier: "CBMonthToMonthPdfVC") as! CBMonthToMonthPdfVC
        monthToMonthPdf.titles = ""
        monthToMonthPdf.modalPresentationStyle = .overFullScreen
        monthToMonthPdf.modalTransitionStyle = .crossDissolve
        monthToMonthPdf.urlString = "https://www.wbidmax.com/downloads/swa/Who Wants 65 tfp for one week of Vacation.pdf"
        self.present(monthToMonthPdf, animated: true, completion: nil)
    }

    @IBAction func btnOkAction(_ sender: UIButton) {
//        CBGlobalMethods.shared.selectedBidPeriod!.vactionWeekAlertDisplayed = NSNumber(value: true)
//        self.dismiss(animated: true)
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?(true)
        }
    }
    
}
