//
//  CBBidDataTypeViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

class CBBidDataTypeViewController: UIViewController {

    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnHistoricBP: UIButton!
    @IBOutlet weak var btnNewBP: UIButton!
    @IBOutlet weak var viewBottom: UIView!
    @IBOutlet weak var lblQaMode: UILabel!
    let app = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    func setupUI() {
        let isQATest = UserDefaults.standard.bool(forKey: "isQATest")
        if isQATest == true {
            let qaMonth = UserDefaults.standard.string(forKey: "QATestMonth") ?? "0"
            let qaYear = UserDefaults.standard.string(forKey: "QATestYear") ?? "0"
            lblQaMode.text = "QA Mode: \(qaMonth) - \(qaYear)"
        }
        else {
            lblQaMode.text = ""
        }
    }
    
    @IBAction func btnCloseAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func btnNewBidPeriod(_ sender: Any) {
        AppState.shared.isHistoricBid = false
        AppState.shared.isMockData = false
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBDefaultEmployeeVC") as! CBDefaultEmployeeVC
        vc.isNewBid = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnHistoricBidPeriod(_ sender: Any) {
        AppState.shared.isHistoricBid = true
        let dialogMessage = UIAlertController(title: "CrewBid", message: "When viewing Historical Bid Data, WBid and SWAPTimizer Vacation will not be available.\n\nNor will you be able to accidentally submit any bid using the Historical Bid Data", preferredStyle: .alert)
        UserDefaults.standard.set("21221", forKey: kCBDefaultEmployeeNumberKey)
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBBiddataDownloadVC") as! CBBiddataDownloadVC
            vc.isHistoricBid = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true)
    }
}
