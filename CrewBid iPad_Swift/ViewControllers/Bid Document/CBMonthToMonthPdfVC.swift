//
//  CBMonthToMonthPdfVC.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 18/04/25.
//

import UIKit
import WebKit

class CBMonthToMonthPdfVC: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var lblTitle: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true) 
    }
    
}
