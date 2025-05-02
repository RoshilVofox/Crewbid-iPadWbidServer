//
//  CBTripAwardViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 17/04/25.
//

import UIKit

class CBTripAwardViewController: UIViewController {
    
    @IBOutlet weak var lblMonthTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var txtTripID: customUITextField!
    @IBOutlet weak var txtPosition: customUITextField!
    @IBOutlet weak var viewWeekDays: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func btnGoAction(_ sender: Any) {
    }
    
}
