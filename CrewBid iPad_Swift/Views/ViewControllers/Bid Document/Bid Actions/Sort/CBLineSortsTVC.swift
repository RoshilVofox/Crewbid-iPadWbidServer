//
//  CBLineSortsTVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBLineSortsTVC: UIViewController {

    @IBOutlet weak var btnBidListCount: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Do any additional setup after loading the view.
    }
    func setupUI(){
        btnBidListCount.layer.cornerRadius = btnBidListCount.frame.height/2
    }
    @IBAction func btnFilterAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBFilterRulesTableVC") as! CBFilterRulesTableVC
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func btnPresetAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBPresetsTVC") as! CBPresetsTVC
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func btnBidsAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidListVC") as! CBBidListVC
        self.navigationController?.pushViewController(vc, animated: false)
        UIView.transition(from: self.view, to: vc.view, duration: 0.65, options: [.transitionFlipFromLeft])
    }
    @IBAction func btnAddAction(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Filter", bundle: nil)
        let filterMenuController = storyboard.instantiateViewController(withIdentifier: "CBSortRulesMenuTableVC") as! CBSortRulesMenuTableVC
        let title = String(format: "Add Sort")
        filterMenuController.navigationItem.title = title
        filterMenuController.navigationController?.navigationBar.backgroundColor = .lightGray
        filterMenuController.menuItems = BILineSort.lineSortCategories() as NSArray
        let navigationController = UINavigationController(rootViewController: filterMenuController)
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.barTintColor = .lightGray
        let frame = CGRect(x: sender.frame.origin.x - 30, y: sender.frame.origin.y - 20, width: sender.frame.width, height: sender.frame.height)
        filterMenuController.showPopover(withNavigationController: sender, sourceRect: frame)
    }
}

