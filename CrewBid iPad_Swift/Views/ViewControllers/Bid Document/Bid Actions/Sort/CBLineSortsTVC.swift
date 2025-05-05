//
//  CBLineSortsTVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBLineSortsTVC: UIViewController {

    @IBOutlet weak var btnBidListCount: UIButton!
    @IBOutlet weak var btnSortTheBidlist: UIButton!
    @IBOutlet weak var btnSortTheScratchpad: UIButton!
    @IBOutlet weak var btnFilter: UIButton!
    @IBOutlet weak var btnSort: UIButton!
    @IBOutlet weak var btnPreset: UIButton!
    @IBOutlet weak var btnBids: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(self.setupLayoutView), name: NSNotification.Name("SortBidListAction"), object: nil)
    }
    func setupUI(){
        btnBidListCount.layer.cornerRadius = btnBidListCount.frame.height/2
        btnSortTheBidlist.backgroundColor = .systemRed
        btnSortTheScratchpad.backgroundColor = .systemGreen
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
    
//    MARK: setup layout for notification
    @objc func setupLayoutView(){
        if AppData.shared.isBidListSort == true {
            btnFilter.isHidden = true
            btnPreset.isHidden = true
            btnBids.isHidden = true
            btnBidListCount.isHidden = true
        }
        else {
            btnFilter.isHidden = false
            btnPreset.isHidden = false
            btnBids.isHidden = false
            btnBidListCount.isHidden = false
        }
    }
    
    @IBAction func btnSortTheBidListAction(_ sender: Any) {
        if btnSortTheBidlist.backgroundColor == .systemRed {
            btnSortTheBidlist.backgroundColor = .systemGreen
            btnSortTheScratchpad.backgroundColor = .systemRed
            AppData.shared.isBidListSort = true
            let alert = UIAlertController(title: "Confirmation", message: "Do you want to sort the bid list?", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                NotificationCenter.default.post(name: NSNotification.Name("SortBidListAction"), object: self)
            }
            let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            alert.addAction(noAction)
            alert.addAction(yesAction)

            self.present(alert, animated: true, completion: nil)

            
        }
    }
    
    @IBAction func btnSortTheScratchpadAction(_ sender: Any) {
        if btnSortTheScratchpad.backgroundColor == .systemRed {
            btnSortTheScratchpad.backgroundColor = .systemGreen
            btnSortTheBidlist.backgroundColor = .systemRed
            AppData.shared.isBidListSort = false
            NotificationCenter.default.post(name: NSNotification.Name("SortBidListAction"), object: self)
        }
    }
}

