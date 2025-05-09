//
//  CBBIdDataTypeViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

class CBBIdDataTypeViewController: UIViewController {

    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnHistoricBP: UIButton!
    @IBOutlet weak var btnNewBP: UIButton!
    @IBOutlet weak var viewBottom: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnCloseAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func btnNewBidPeriod(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBDefaultEmployeeVC") as! CBDefaultEmployeeVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnHistoricBidPeriod(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "CrewBid", message: "When viewing Historical Bid Data, WBid and SWAPTimizer Vacation will not be available.\n\nNor will you be able to accidentally submit any bid using the Historical Bid Data", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBBiddataDownloadVC") as! CBBiddataDownloadVC
            vc.isFromHistoric = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true)
    }
}
