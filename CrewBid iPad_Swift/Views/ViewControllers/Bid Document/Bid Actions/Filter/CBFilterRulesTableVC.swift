//
//  CBFilterRulesTableVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//


import UIKit

protocol CBFilterRuleCellDelegateAssignable: AnyObject {
    var delegate: CBFilterRuleCellDelegate? { get set }
}

protocol CBFilterRuleCellDelegate: AnyObject {
    func deleteCellRow(in cell: UITableViewCell)
}


class CBFilterRulesTableVC: BaseViewController {
    
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var btnBids: UIButton!
    @IBOutlet weak var btnBidListCount: UIButton!
    @IBOutlet weak var objFilterTableView: UITableView!
    
    var selectedFilters: [String] = []
    
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
        filterMenuController.delegate = self
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
    
    var cellidentifiers = ["LineTypeFilterRuleCell","AmPmFilterRuleCell","WeekdayRuleCell","TripLengthRuleCell"]
    
    var kLineTypeFilterRuleCell = "LineTypeFilterRuleCell"
    var kAmPmFilterRuleCell = "AmPmFilterRuleCell"
    var kTripLengthFilterRuleCell = "TripLengthRuleCell"
    var kWeekdayFilterRuleCell = "WeekdayRuleCell"
    var kComparisonFilterRuleCell = "ComparisonRuleCell"
    var kCityComparisonFilterRuleCell = "CityComparisonRuleCell"
    var kAircraftChangesFilterRuleCell = "AircraftChangesRuleCell"
    var kLegComparisonFilterRuleCell = "LegComparisonRuleCell"
    var kDayMonthFilterRuleCell = "DayMonthRuleCell"
    var kCommutingRuleCell = "CommutingRuleCell"
    var kPositionRuleCell = "PositionRuleCell"
    var kFaReserveRuleCell = "FaReserveRuleCell"
    var kUserFlagRuleCell = "UserFlagRuleCell"
    var kCommutabilityRuleCell = "CommutabilityRuleCell"
    var kOverNightBulkRuleCell = "OvernightBulkRuleCell"
    var kReportReleaseRuleCell = "ReportReleaseCell"
    var kworkBlockRuleCell = "CBWorkBlockRuleCell"
    
    func cellIdentifier(for category: BIFilterRuleCategory.RawValue, type: Int) -> String? {
        var cellIdentifier: String? = nil
        switch category {
    
        case BIFilterRuleCategory.BIWorkBlockRuleCategory.rawValue:
            cellIdentifier = kworkBlockRuleCell
        
        case BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue:
            cellIdentifier = kLineTypeFilterRuleCell
            
        case BIFilterRuleCategory.BIEtopsFilterRuleCategory.rawValue:
            cellIdentifier = kLineTypeFilterRuleCell
            
        case BIFilterRuleCategory.BIEtopsResFilterRuleCategory.rawValue:
            cellIdentifier = kLineTypeFilterRuleCell
            
        case BIFilterRuleCategory.BIAmPmFilterRuleCategory.rawValue:
            cellIdentifier = kAmPmFilterRuleCell
            
        case BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue:
            cellIdentifier = kFaReserveRuleCell
            
        case BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue:
            cellIdentifier = kPositionRuleCell
            
        case BIFilterRuleCategory.BIDaysOfWeekFilterRuleCategory.rawValue:
            if BIWeekdaysFilterRuleType.BIWeekdaysCompoundType.rawValue == type {
                cellIdentifier = kWeekdayFilterRuleCell
            } else {
                cellIdentifier = kComparisonFilterRuleCell
            }
            
        case BIFilterRuleCategory.BITripLengthFilterRuleCategory.rawValue:
            if BITripLengthFilterRuleType.BITripLengthCompoundType.rawValue == type {
                cellIdentifier = kTripLengthFilterRuleCell
            } else {
                cellIdentifier = kComparisonFilterRuleCell
            }
            
        case BIFilterRuleCategory.BIAircraftTypeFilterRuleCategory.rawValue:
            cellIdentifier = kComparisonFilterRuleCell
            
        case BIFilterRuleCategory.BICommutingFilterRuleCategory.rawValue:
            cellIdentifier = kCommutingRuleCell
            
        case BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue:
            if BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConusLegs.rawValue == type {
                cellIdentifier = kComparisonFilterRuleCell
            } else {
                cellIdentifier = kCityComparisonFilterRuleCell
            }
            
        case BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue:
            if BIDeadheadsFilterRuleType.BIDeadheadsType.rawValue == type {
                cellIdentifier = kComparisonFilterRuleCell
            } else {
                cellIdentifier = kCityComparisonFilterRuleCell
            }
            
        case BIFilterRuleCategory.BIOvernightCitiesBulkRuleCategory.rawValue:
            cellIdentifier = kOverNightBulkRuleCell
            
        case BIFilterRuleCategory.BINumLegsFilterRuleCategory.rawValue:
            cellIdentifier = kComparisonFilterRuleCell
            
        case BIFilterRuleCategory.BIMaxLegsFilterRuleCategory.rawValue:
            cellIdentifier = kComparisonFilterRuleCell
            
        case BIFilterRuleCategory.BIDaysOfMonthFilterRuleCategory.rawValue:
            cellIdentifier = kDayMonthFilterRuleCell
            
        case BIFilterRuleCategory.BIUserFlagFilterRuleCategory.rawValue:
            cellIdentifier = kUserFlagRuleCell
            
        case BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue:
            cellIdentifier = kCommutabilityRuleCell
            
        case BIFilterRuleCategory.BIReportReleaseFilterCategory.rawValue:
            cellIdentifier = kReportReleaseRuleCell
            
        case BIFilterRuleCategory.BIWorkBlockCountCategory.rawValue:
            cellIdentifier = kComparisonFilterRuleCell
        default:
            cellIdentifier = kComparisonFilterRuleCell
        }
        return cellIdentifier
    }
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
        //MARK: Delegate function
        if let closableCell = cell,
           let delegateAware = closableCell as? CBFilterRuleCellDelegateAssignable {
            delegateAware.delegate = self
        }
        return cell!
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch cellidentifiers[indexPath.row]{
            case kReportReleaseRuleCell:
            return 280
        case kOverNightBulkRuleCell:
            return 400
        case kCommutingRuleCell:
            return 250
        case kDayMonthFilterRuleCell:
            return 275
        default:
            return 56
        }
    }
    
}
//MARK: Delegate method
extension CBFilterRulesTableVC: CBRulesMenuFilterDelegate,CBFilterRuleCellDelegate {
    func filterSelected(filter: NSDictionary) {
        guard
            let category = filter["category"] as? Int,
            let type = filter["type"] as? Int
        else {
            print("Missing category or type in filter: \(filter)")
            return
        }
        if let identifier = cellIdentifier(for: category, type: type) {
            cellidentifiers.append(identifier)
            objFilterTableView.reloadData()
        } else {
            print("No matching cell identifier for category \(category), type \(type)")
        }
    }

    func deleteCellRow(in cell: UITableViewCell) {
        guard let indexPath = objFilterTableView.indexPath(for: cell) else { return }

        // Remove the corresponding identifier from the data source
        cellidentifiers.remove(at: indexPath.row)
        
        // Delete the row from the table view
        objFilterTableView.deleteRows(at: [indexPath], with: .fade)
    }
    
}
