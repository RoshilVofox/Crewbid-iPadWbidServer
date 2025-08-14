//
//  CBMonthToMonthAlertVC.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 02/08/25.
//

import UIKit

class CBMonthToMonthAlertVC: UIViewController {
    
    var text = ""
    var tapOkBlock: ((Bool) -> Void)?


    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 400, height: 400)
        // Do any additional setup after loading the view.
    }
    

    func showAlertFromViewController(from viewController: UIViewController, tappedOK: @escaping (Bool) -> Void) {
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
        viewController.present(self, animated: true, completion: nil)
        self.tapOkBlock = tappedOK
    }

    @IBAction func btnOkAction(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
}
