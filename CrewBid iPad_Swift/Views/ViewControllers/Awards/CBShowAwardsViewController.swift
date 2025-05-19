//
//  CBShowAwardsViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 22/04/25.
//

import UIKit

class CBShowAwardsViewController: UIViewController {
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    
    @IBOutlet weak var btnShareAction: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        btnClose.setTitle("", for: .normal)
        btnShare.setTitle("", for: .normal)
        
    }

    @IBAction func btnDismissAction(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnShareAction(_ sender: Any) {
        
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AwardActionsTableController") as! AwardActionsTableController
       
        vc.preferredContentSize = CGSize(width: 310, height: 300)
        vc.modalPresentationStyle = .custom
        let frame = CGRect(x: 15, y: 35, width: 0, height: 0)
        vc.showPopover(sourceView: btnShareAction, sourceRect: frame)
    }
}
