//
//  CBBidReciptViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 18/04/25.
//

import UIKit

class CBBidReciptViewController: UIViewController {
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var txtView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    @IBAction func btnShareAction(_ sender: Any) {
    }
    
}
