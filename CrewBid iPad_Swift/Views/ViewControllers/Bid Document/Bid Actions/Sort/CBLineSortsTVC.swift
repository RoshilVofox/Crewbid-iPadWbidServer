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
    @IBOutlet weak var tableView: UITableView!
    
    var cellIdentifiers: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cellIdentifiers.append("LineSortCell")

        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.setupLayoutView), name: NSNotification.Name("SortBidListAction"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLines), name: NSNotification.Name("refreshLines"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deleteCellRow), name: Notification.Name("DeleteCellNotification"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver("refreshLines")
        NotificationCenter.default.removeObserver("DeleteCellNotification")
        NotificationCenter.default.removeObserver("SortBidListAction")
    }
    
    func setupUI(){
        btnBidListCount.layer.cornerRadius = btnBidListCount.frame.height/2
        btnSortTheBidlist.backgroundColor = .systemRed
        btnSortTheScratchpad.backgroundColor = .systemGreen
    }
    
    @objc func setupLayoutView() {
        if AppData.shared.isBidListSort {
            self.btnFilter.isHidden = true
            self.btnPreset.isHidden = true
            self.btnBids.isHidden = true
        }
        else {
            self.btnFilter.isHidden = false
            self.btnPreset.isHidden = false
            self.btnBids.isHidden = false
        }
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
    
    @IBAction func btnSortTheBidListAction(_ sender: Any) {
        if btnSortTheBidlist.backgroundColor == .systemRed {
            btnSortTheBidlist.backgroundColor = .systemGreen
            btnSortTheScratchpad.backgroundColor = .systemRed
            AppData.shared.isBidListSort = true
            let alert = UIAlertController(title: "Confirmation", message: "Do you want to sort the bid list?", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                NotificationCenter.default.post(name: NSNotification.Name("SortBidListAction"), object: self)
                self.btnFilter.isHidden = true
                self.btnPreset.isHidden = true
                self.btnBids.isHidden = true
                self.btnBidListCount.isHidden = true
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
            btnFilter.isHidden = false
            btnPreset.isHidden = false
            btnBids.isHidden = false
            btnBidListCount.isHidden = false
        }
    }
    
    @objc func updateLines() {
        let arr = AppData.shared.sortsToBeAddedInTable
        let indexpath = arr.count - 1
//        let newRow = cellIdentifier(for: arr[indexpath]["category"]!, type: arr[indexpath]["type"]!)!
        cellIdentifiers.append("LineSortCell")
        tableView.reloadData()
    }
}

extension CBLineSortsTVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppData.shared.sortsToBeAddedInTable.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kLineSortCellIdentifier = "LineSortCell"
        let kCityLineSortCellIdentifier = "CityLineSortCell"
        let kCommutingLineSortCellIdentifier = "CommutingLineSortCell"
        let kCommutabilityLineSortCellIdentifier = "CommutabilitySortCell"
        let kDaysOffLineSortCellIdentifier = "DayMonthLineSortCell"
        let kFlagSortCellIdentifier = "flagSortCell"
        
        let lineSort = AppData.shared.sortsToBeAddedInTable[indexPath.row]
        var cellIdentifier = kLineSortCellIdentifier
        let category = lineSort["category"] as? Int
        let type = lineSort["type"] as? Int
        let title = lineSort["title"] as? String
        
        if ((category == BILineSortCategory.BICitiesLineSortCategory.rawValue &&
             type != BICityLineSortType.BICitiesLineSortTypeNonConusLegs.rawValue) ||
            (category == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue &&
             (type == BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue ||
              type == BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue ||
              type == BIDeadheadLineSortType.BIDeadheadAtBothSortType.rawValue))) {
            
            cellIdentifier = kCityLineSortCellIdentifier
        }
        
        
        else if category == BILineSortCategory.BICommutingLineSortCategory.rawValue {
            cellIdentifier = kCommutingLineSortCellIdentifier
        }
        else if category == BILineSortCategory.BICommutabilityLineSortCategory.rawValue {
            cellIdentifier = kCommutabilityLineSortCellIdentifier
        }
        else if category == BILineSortCategory.BIDaysOffLineSortCategory.rawValue {
            cellIdentifier = kDaysOffLineSortCellIdentifier
        }
        else if category == BILineSortCategory.BIDaysWorkLineSortCategory.rawValue {
            cellIdentifier = kDaysOffLineSortCellIdentifier
        }
        else if category == BILineSortCategory.BIDaysTripStartSortCategory.rawValue {
            cellIdentifier = kDaysOffLineSortCellIdentifier
        }
        else if category == BILineSortCategory.BIFlagLineSortCategory.rawValue {
            cellIdentifier = kFlagSortCellIdentifier
        }
        
        if cellIdentifier == "flagSortCell" {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CBFlagSortCell
            return cell
        }
       else if  cellIdentifier == kCommutingLineSortCellIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CBCommutingSortCell
           cell.titleLabel.text = title
            return cell
        }
        else if  cellIdentifier == kDaysOffLineSortCellIdentifier {
             let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CBDayMonthSortCell
             return cell
         }
        else if  cellIdentifier == kCommutabilityLineSortCellIdentifier {
             let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CBCommutabilitySortCell
            cell.btnTitle.setTitle(title, for: .normal)
             return cell
         }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CBLineSortCell
        cell.titleLabel.text = title
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let lineSort = AppData.shared.sortsToBeAddedInTable[indexPath.row]
        let category = lineSort["category"] as? Int
        
        if category == BILineSortCategory.BICommutingLineSortCategory.rawValue {
            return 270.0
        }
        else if category == BILineSortCategory.BIDaysOffLineSortCategory.rawValue {
            return 330.0
        }
        else if category == BILineSortCategory.BIDaysWorkLineSortCategory.rawValue {
            return 330.0
        }
        else if category == BILineSortCategory.BIDaysTripStartSortCategory.rawValue {
            return 330.0
        }
        else if category == BILineSortCategory.BIFlagLineSortCategory.rawValue {
            return CGFloat(/*(sort.variables?.count)!*/ 6 * 50)
        }
        else if category == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue {
            return 70.0
        }
        else if category == BILineSortCategory.BICommutabilityLineSortCategory.rawValue {
            return 70.0
        } else {
            return 70
        }
    }
    
//    MARK: delete cell notification method
    @objc func deleteCellRow(_ notification: Notification) {
        guard let cell = notification.object as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) else { return }

        AppData.shared.sortsToBeAddedInTable.remove(at: indexPath.row)
//        cellIdentifiers.remove(at: indexPath.row)

//        print(AppData.shared.filtersToBeAddedInTable.count)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
}

