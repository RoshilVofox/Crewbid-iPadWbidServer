//
//  EmbeddedSettingsVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/04/25.
//

import UIKit

class EmbeddedSettingsVC: BaseViewController,KUIPopOverUsable {

    var contentSize: CGSize {
        return CGSize(width: 300, height: self.bidPeriod == nil ? 376 : 500)
    }
    
    var bidPeriod: BIBidPeriod?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navVC = segue.destination as? UINavigationController
        let vc = navVC?.viewControllers.first as! SettingsViewController
        vc.bidPeriod = bidPeriod

    }


}
