//
//  CBBidDocumentController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/03/25.
//

import UIKit

class CBBidDocumentController: UIViewController {

    @IBOutlet weak var btnHome: UIButton!
    @IBOutlet weak var btnSettings: UIButton!
    @IBOutlet weak var btnEOM: UIButton!
    @IBOutlet weak var btnWbidMax: UIButton!
    @IBOutlet weak var lblHome: UILabel!
    @IBOutlet weak var btnSwaptimizer: UIButton!
    @IBOutlet weak var btnHelp: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnLocalHerbView: UIView!
    @IBOutlet weak var herbLabel: UILabel!
    @IBOutlet weak var localLabel: UILabel!
    @IBOutlet weak var btnLocalHerb: UIButton!
    
    @IBOutlet weak var leftShadowView: UIView!
    @IBOutlet weak var rightShadowView: UIView!
    @IBOutlet weak var leftContainerView: UIView!
    @IBOutlet weak var rightContainerView: UIView!
    @IBOutlet weak var btnShareAction: UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnHomeAction(_ sender: UIButton) {
        if let navigationController = self.navigationController {
            navigationController.popToRootViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    
    
    
    @IBAction func localHerbAction(_ sender: Any) {
    }
    
    @IBAction func btnShareAction(_ sender: Any) {
    
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedBidActionsVC") as! EmbeddedBidActionsVC
       
        vc.preferredContentSize = CGSize(width: 310, height: 610)
        vc.modalPresentationStyle = .custom
        let frame = CGRect(x: 15, y: 35, width: 0, height: 0)
        vc.showPopover(sourceView: btnShareAction, sourceRect: frame)
    }
    
    @IBAction func btnHelpAction(_ sender: Any) {
        print("HelpMenu")
        let storyBoard = UIStoryboard(name: "HelpMenu", bundle: nil)
        if let helpMenuVC = storyBoard.instantiateViewController(withIdentifier: "helpMenuViewController") as? helpMenuViewController{
//            helpMenuVC.modalPresentationStyle = .formSheet
            helpMenuVC.preferredContentSize = CGSize(width: 764, height: 630)
            present(helpMenuVC, animated: true)
        }
    }
}
