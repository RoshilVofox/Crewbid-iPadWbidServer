//
//  CBFilterRulesTableVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBFilterRulesTableVC: BaseViewController {
    
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var btnBids: UIButton!
    @IBOutlet weak var btnBidListCount: UIButton!
    @IBOutlet weak var objFilterTableView: UITableView!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        setupUI()
        // Do any additional setup after loading the view.
    }
    
    func setupUI(){
        btnBidListCount.layer.cornerRadius = btnBidListCount.frame.height/2
    }
    
    
    @IBAction func btnSortAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBLineSortsTVC") as! CBLineSortsTVC
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
        let filterMenuController = storyboard.instantiateViewController(withIdentifier: "CBRulesMenuTableVC") as! CBRulesMenuTableVC
        let title = String(format: "Add Filter")
        filterMenuController.navigationItem.title = title
        filterMenuController.navigationController?.navigationBar.backgroundColor = .lightGray
        filterMenuController.menuItems = BIFilterRule.menuItemsForBidPeriod() as NSArray
        let navigationController = UINavigationController(rootViewController: filterMenuController)
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.barTintColor = .lightGray
        let frame = CGRect(x: sender.frame.origin.x - 30, y: sender.frame.origin.y - 20, width: sender.frame.width, height: sender.frame.height)
        filterMenuController.showPopover(withNavigationController: sender, sourceRect: frame)
    }
    
    @IBAction func btnBidListCountAction(_ sender: Any) {
    }
    
    let cellidentifiers = ["LineTypeFilterRuleCell","AmPmFilterRuleCell","WeekdayRuleCell","TripLengthRuleCell"]
    
     
}

extension CBFilterRulesTableVC: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellidentifiers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellidentifier = cellidentifiers[indexPath.row]
        let cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellidentifier, for: indexPath)
        let customViewFrame = CGRect(x: 0, y: (cell?.contentView.layer.frame.maxY)! - 1, width: (cell?.contentView.frame.width)!, height: 1)
        let borderView = UIView(frame: customViewFrame)
        borderView.backgroundColor = UIColor.lightGray
        cell?.addSubview(borderView)
        return cell!
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
}
