//
//  CBTripAwardTextViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 17/04/25.
//

import UIKit

class CBTripAwardTextViewController: UIViewController {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var txtView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

    @IBAction func btnShareAction(_ sender: Any) {
    }
}
