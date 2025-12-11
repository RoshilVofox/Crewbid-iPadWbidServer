//
//  CBFilterRulesTableVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//


import UIKit
import CoreData

enum ComparisonType: Int {
    case atMost = 1
    case exactly
    case atLeast
}


class CBFilterRulesTableVC: BaseViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var btnBids: UIButton!
    @IBOutlet weak var btnBidListCount: UIButton!
    @IBOutlet weak var objFilterTableView: UITableView!
    var bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
    var disabledCellIndexPaths = NSMutableArray()
    var context: NSManagedObjectContext?
    var filterRulesController: NSFetchedResultsController<BIFilterRule>?
    var calendarData = BICalendarData()
    var cellFlagBorderColor: UIColor = .systemGray
    var filterRules = [Any]()

    
    var selectedFilters: [String] = []
    var cellidentifiers: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.clipsToBounds = true
        self.view.layer.cornerRadius = 5
        calendarData = calendarData.initWithBidPeriod(bidPeriod: bidPeriod!)!
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext
        filterRules = (bidPeriod!.lineFilters!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "type", ascending: true), NSSortDescriptor(key: "category", ascending: true)]) as [Any]
//        fetchFromFilterAndUpdateCategory()
        setupUI()
        reloadRuleCell()
        NotificationCenter.default.addObserver(self, selector: #selector(updateLines), name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshBidListCount), name: NSNotification.Name("RefreshBidListLineCountFilter"), object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadRuleCell()
        objFilterTableView.allowsSelection = false
        NotificationCenter.default.addObserver(self, selector: #selector(updateBidListCount), name: NSNotification.Name("updateBidListCount"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFilters), name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("flipToBidList"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(flipToBidList), name: NSNotification.Name("flipToBidList"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadFilterTable), name: NSNotification.Name("ReloadFilterTable"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver("refreshLines")
        NotificationCenter.default.removeObserver("RefreshBidListLineCountFilter")
    }
    
    func setupUI(){
        btnBidListCount.layer.cornerRadius = btnBidListCount.frame.height/2
        updateBidListCount()
    }
    
    @objc func reloadFilterTable(){
        self.objFilterTableView.reloadData()
    }
    
    @objc func updateFilters(){
        filterRules = (CBGlobalMethods.shared.selectedBidPeriod!.lineFilters!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "type", ascending: true), NSSortDescriptor(key: "category", ascending: true)]) as [Any]
        self.objFilterTableView.reloadData()
    }
    
    @objc func updateBidListCount(){
        var linesArray : [BILine] = []
        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
            linesArray.append(line)
        }
        var array : [NSPredicate] = []
        array.append(NSPredicate(format: "bidOrder > %@", NSNumber(integerLiteral: 0)))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        linesArray = (linesArray as NSArray).filtered(using: predicate) as! [BILine]
        DispatchQueue.main.async {
            self.btnBidListCount.setTitle("\(linesArray.count)", for: .normal)
        }
    }
    
    @objc func flipToBidList(_ notification: Notification){
        var isNeedtoPush : Bool = true
        if let viewControllers = self.navigationController?.viewControllers  {
            for controller in viewControllers {
                if controller is CBBidListVC {
                    isNeedtoPush = false
                }
            }
        }
            let presentingViewController = self.presentingViewController
            self.dismiss(animated: false, completion: {
                presentingViewController?.dismiss(animated: false, completion: {})
            })
        if isNeedtoPush {
            let vc = UIStoryboard.init(name: "BidDocument", bundle: Bundle.main).instantiateViewController(withIdentifier: "CBBidListVC") as! CBBidListVC
            self.navigationController?.pushViewController(vc, animated: false)
            UIView.transition(from: self.view, to: vc.view, duration: 0.85, options: [.transitionFlipFromLeft])
        }
    }
    
    
    func reloadRuleCell() {
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        let filterRules = (bidPeriod!.lineFilters!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "type", ascending: true), NSSortDescriptor(key: "category", ascending: true)]) as [Any]
        let moc = bidPeriod?.managedObjectContext
        let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "category", ascending: true),
            NSSortDescriptor(key: "type", ascending: true)
        ]
        fetchRequest.predicate = NSPredicate(format: "bidPeriod == %@", bidPeriod!)
//        fetchRequest.predicate =
        self.filterRulesController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: moc!,
            sectionNameKeyPath: nil,
            cacheName: nil
            )
        self.filterRulesController?.delegate = self
        do {
            try self.filterRulesController?.performFetch()
        }
        catch {
            print("Failed to perform filter rule fetch: \(error.localizedDescription)")
        }
//        let fetchedObjects = try! moc!.fetch(fetchRequest)
        DispatchQueue.main.async {
            self.objFilterTableView.reloadData()
        }
    }
    
    @IBAction func btnSortAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBLineSortsTVC") as! CBLineSortsTVC
        vc.bidPeriod = self.bidPeriod
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
        UIView.transition(from: self.view, to: vc.view, duration: 0.85, options: [.transitionFlipFromLeft])
//        guard let nav = self.navigationController else { return }
//        if let topVC = nav.topViewController, topVC is CBBidListVC {
//            return
//        }
//        if let existingVC = nav.viewControllers.first(where: { $0 is CBBidListVC }) {
//            nav.popToViewController(existingVC, animated: false)
//            UIView.transition(with: nav.view,duration: 0.65,options: [.transitionFlipFromLeft],animations: nil)
//            return
//        }
//        let vc = UIStoryboard(name: "BidDocument", bundle: nil).instantiateViewController(withIdentifier: "CBBidListVC") as! CBBidListVC
//        nav.pushViewController(vc, animated: false)
//        UIView.transition(with: nav.view,duration: 0.65,options: [.transitionFlipFromLeft],animations: nil)
    }
    
    @IBAction func btnAddAction(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Filter", bundle: nil)
        let filterMenuController = storyboard.instantiateViewController(withIdentifier: "CBRulesMenuTableVC") as! CBRulesMenuTableVC
        let title = String(format: "Add Filter")
        filterMenuController.delegate = self
        filterMenuController.navigationItem.title = title
        filterMenuController.disabledCellIndexPaths = self.disabledCellIndexPaths
        filterMenuController.bidPeriod = self.bidPeriod!
        filterMenuController.navigationController?.navigationBar.backgroundColor = .lightGray
        filterMenuController.menuItems = BIFilterRule.menuItemsForBidPeriod(CBGlobalMethods.shared.selectedBidPeriod!) as NSArray
        let navigationController = UINavigationController(rootViewController: filterMenuController)
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.barTintColor = .lightGray
        let frame = CGRect(x: sender.frame.origin.x - 30, y: sender.frame.origin.y - 20, width: sender.frame.width, height: sender.frame.height)
        filterMenuController.showPopover(withNavigationController: sender, sourceRect: frame)
    }
    
    @IBAction func btnBidListCountAction(_ sender: Any) {
    }
    
//    var cellidentifiers = ["LineTypeFilterRuleCell","AmPmFilterRuleCell","WeekdayRuleCell","TripLengthRuleCell"]
    
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
    var kpdoRuleCell = "PDORuleCell"
    
    //    seting filter identifier
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
        case BIFilterRuleCategory.BIPDOFilterRuleCategory.rawValue:
            cellIdentifier = kpdoRuleCell
        default:
            cellIdentifier = kComparisonFilterRuleCell
        }
        return cellIdentifier
    }
    
    @objc func refreshBidListCount(){
        self.btnBidListCount.setTitle(String(format: "%@",self.bidPeriod?.bidListLineCount ?? "0"), for: .normal)
    }
    
//    MARK: refresh line notification
    @objc func updateLines() {
        reloadRuleCell()
        updateBidListCount()
    }
}
extension CBFilterRulesTableVC: UITableViewDelegate,UITableViewDataSource{

    func numberOfSections(in tableView: UITableView) -> Int {
//        print("Table reloaded in number of sections")
        return (self.filterRulesController?.sections!.count)!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section
        if let sectionInfo = filterRulesController?.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        // Fallback if sections is nil
        // return filterRulesController?.fetchedObjects?.count ?? 0
        return 0
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rule = filterRulesController?.object(at: indexPath)
        let cellIdentifier = self.cellIdentifier(for: rule!.category as! BIFilterRuleCategory.RawValue, type: rule!.type!.intValue)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier!, for: indexPath)
        self.configureCell(cell: cell, for: rule!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionInfo = self.filterRulesController?.sections?[indexPath.section] as? NSFetchedResultsSectionInfo
        let numRows = sectionInfo?.numberOfObjects ?? 0
        tableView.rowHeight = UITableView.automaticDimension
        
        if indexPath.row < numRows {
            if let rule = self.filterRulesController!.object(at: indexPath) as? BIFilterRule {
                if BIFilterRuleCategory.BIDaysOfMonthFilterRuleCategory.rawValue == rule.category?.intValue {
                    return 273.0
                } else if BIFilterRuleCategory.BICommutingFilterRuleCategory.rawValue == rule.category?.intValue {
                    return 255.0
                } else if BIFilterRuleCategory.BIOvernightCitiesBulkRuleCategory.rawValue == rule.category?.intValue {
                    return 405.0
                } else if BIFilterRuleCategory.BIEtopsFilterRuleCategory.rawValue == rule.category?.intValue {
                    return 0.0
                }else if BIFilterRuleCategory.BIEtopsResFilterRuleCategory.rawValue == rule.category?.intValue {
                    return 0.0
                } else if BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue == rule.category?.intValue {
                    return 56.0
                } else if BIFilterRuleCategory.BIReportReleaseFilterCategory.rawValue == rule.category?.intValue {
                    return 280
                } else {
                    return 56.0
                }
            }
            
        }
        else {
            return 56.0
        }
    }
    

    
    func configureCell(cell: UITableViewCell?, for rule: BIFilterRule?) {
//        print(rule?.category?.intValue as Any)
        var useComparisonCell = false
        if BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue == rule?.category?.intValue {
            //fetch etops filter
            var ruleFetched :BIFilterRule?
            var resultsFilter = ((CBGlobalMethods.shared.selectedBidPeriod!.lineFilters!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 35")) as NSArray).sortedArray(using: [NSSortDescriptor(key: "category", ascending: true), NSSortDescriptor(key: "type", ascending: true)])
            
            if resultsFilter.count > 0 {
                ruleFetched = resultsFilter[0] as? BIFilterRule
            }
            
            // Fetch EtopsRes filter
            resultsFilter = ((CBGlobalMethods.shared.selectedBidPeriod!.lineFilters!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 38")) as NSArray).sortedArray(using: [NSSortDescriptor(key: "category", ascending: true), NSSortDescriptor(key: "type", ascending: true)])
            var etopsResruleFetched :BIFilterRule?
            if resultsFilter.count > 0 {
                etopsResruleFetched = resultsFilter[0] as? BIFilterRule
            }
            
            let ruleCell = cell as? CBLineTypeRuleCell
            ruleCell?.bidPeriod = self.bidPeriod!
            ruleCell?.etopsfilterRule = ruleFetched
            ruleCell?.etopsResfilterRule = etopsResruleFetched
            ruleCell?.filterRule = rule!
            ruleCell?.buttonTextColor = self.cellFlagBorderColor
        }
        else if BIFilterRuleCategory.BIEtopsFilterRuleCategory.rawValue == rule?.category?.intValue {
            let ruleCell = cell as? CBLineTypeRuleCell
            ruleCell?.bidPeriod = self.bidPeriod!
            ruleCell?.isHidden = true
            ruleCell?.buttonTextColor = self.cellFlagBorderColor
        }
        else if BIFilterRuleCategory.BIEtopsResFilterRuleCategory.rawValue == rule?.category?.intValue {
            let ruleCell = cell as? CBLineTypeRuleCell
            ruleCell?.bidPeriod = self.bidPeriod!
            ruleCell?.isHidden = true
            ruleCell?.buttonTextColor = self.cellFlagBorderColor
        }
        else if BIFilterRuleCategory.BIAmPmFilterRuleCategory.rawValue == rule?.category?.intValue {
            let ruleCell = cell as! CBAmPmRuleCell
            ruleCell.bidPeriod =  self.bidPeriod!
            ruleCell.buttonTextColor = self.cellFlagBorderColor
            ruleCell.filterRule = rule!
            //ruleCell?.setredEyeLinesButton()
        }
        else if BIFilterRuleCategory.BIWorkBlockRuleCategory.rawValue == rule?.category?.intValue {
            let ruleCell = cell as? CBWorkBlockRuleCell
            useComparisonCell = false
            ruleCell?.bidPeriod = self.bidPeriod
            let viewToRemove: UIView? = cell?.contentView.viewWithTag(101)
            if viewToRemove != nil {
                viewToRemove?.removeFromSuperview()
            }
            
            ruleCell?.titleLabel.text = rule?.name
            if (rule?.variables?["DECIMAL"] != nil) {
                let ruleValue = (rule?.variables?[BIFilterRuleValueVariablesKey] as! NSNumber).floatValue
                let numPlaces: Double = rule!.variables!["NUMPLACES"] as! Double
                var formatString = String ()
                if numPlaces == 2 {
                    formatString = String(format:"%.2f", ruleValue)
                } else {
                    formatString = String(format:"%.1f", ruleValue)
                }
                ruleCell?.valueButton.setTitle("\(formatString)", for: .normal)
            } else {
                let strValue = rule?.variables![BIFilterRuleValueVariablesKey]
                let endValue = (strValue as! NSNumber).stringValue
                ruleCell?.valueButton.setTitle("\(endValue)", for: .normal)
            }
            
            var comparisonString = "At Most"
            if rule?.comparison?.intValue == 2 {
                comparisonString = "Exactly"
            }else if rule?.comparison?.intValue == 3 {
                comparisonString = "At Least"
            }
            
            var ruleTypeString = "3 Day"
            if rule?.keyPath == "workBlock1" {
                ruleTypeString = "1 Day"
            }
            if rule?.keyPath == "workBlock2" {
                ruleTypeString = "2 Day"
            }
            if rule?.keyPath == "workBlock3" {
                ruleTypeString = "3 Day"
            }
            if rule?.keyPath == "workBlock4" {
                ruleTypeString = "4 Day"
            }
            ruleCell?.ruleTypeButton.setTitle(ruleTypeString, for: .normal)
            ruleCell?.comparisonButton.setTitle(comparisonString, for: .normal)
            ruleCell?.filterRule = rule
        }
        else if BIFilterRuleCategory.BIDaysOfWeekFilterRuleCategory.rawValue == rule?.category?.intValue {
            if BIWeekdaysFilterRuleType.BIWeekdaysCompoundType.rawValue == rule?.type?.intValue {
                let ruleCell = cell as? CBWeekdayRuleCell
                ruleCell?.filterRule = rule!
                ruleCell?.filterRule = rule!
            } else {
                useComparisonCell = true
            }
        }
        else if BIFilterRuleCategory.BITripLengthFilterRuleCategory.rawValue == rule?.category?.intValue {
            if BITripLengthFilterRuleType.BITripLengthCompoundType.rawValue == rule?.type?.intValue {
                let ruleCell = cell as? CBTripLengthRuleCell
                ruleCell?.filterRule = rule!
                ruleCell?.bidPeriod = bidPeriod!
            } else {
                useComparisonCell = true
            }
        }
        else if BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue == rule?.category?.intValue  {
            let ruleCell = cell as? CBPositionRuleCell
            ruleCell?.filterRule = rule!
            ruleCell?.bidPeriod = bidPeriod!
            ruleCell?.buttonTextColor = cellFlagBorderColor
            useComparisonCell = false
        }
        else if BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = false
            let ruleCell = cell as? CBFaReserveRuleCell
            ruleCell?.backViewColor = UIColor.appColor(.contentBgColor)!
            ruleCell?.filterRule = rule!
            ruleCell?.buttonTextColor = cellFlagBorderColor
        }
        else if BIFilterRuleCategory.BICommutingFilterRuleCategory.rawValue == rule?.category?.intValue { // MANUAL
            useComparisonCell = false
            let ruleCell = cell as? CBCommutingRuleCell
            ruleCell?.filterRule = rule!
           ruleCell?.bidPeriod = self.bidPeriod!
//            ruleCell?.calculateCommutingManualFilter()
        }//Flag filter page navigation
        else if BIFilterRuleCategory.BIUserFlagFilterRuleCategory.rawValue == rule?.category?.intValue {
            let ruleCell = cell as? CBUserFlagRuleCell
            ruleCell?.flagColor = cellFlagBorderColor
            ruleCell?.bacViewColor = UIColor.appColor(.contentBgColor)!
            ruleCell?.bidPeriod = bidPeriod!
            ruleCell?.filterRule = rule!
            useComparisonCell = false
        }
        else if BIFilterRuleCategory.BIDaysOfMonthFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = false;
            let ruleCell = cell as? CBDayMonthRuleCell
            ruleCell?.calendarData = self.calendarData
            ruleCell?.filterRule = rule!
            ruleCell?.bidPeriod = bidPeriod!
//            ruleCell?.calendarCollectionView.reloadData()
        }
        else if BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue == rule?.category?.intValue { //AUTO
            useComparisonCell = false
            let ruleCell = cell as? CBComutabilityRuleCell
            ruleCell?.filterRule = rule!
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                ruleCell?.configureCommutabilityCell()
            }
            
        }
        else if BIFilterRuleCategory.BIReportReleaseFilterCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = false
            let ruleCell = cell as? CBReportReleaseRuleCellTableViewCell
            ruleCell?.bidPeriod = bidPeriod!
            ruleCell?.filterRule = rule;
            ruleCell?.calendarData = self.calendarData
            ruleCell?.handleExistingCases()
        }
        else if BIFilterRuleCategory.BIDaysOffFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIBlockTimeFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIAircraftChangesFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIVacationFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIFaVacationFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIBlockOfDaysOffFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIAircraftTypeFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BINumLegsFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BIMaxLegsFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BIDutyTimeFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BIOverlapFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BINumTripsFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BITafbTimeFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BIWorkDaysFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BIPayFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BIPassesThruBaseFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BIOvernightsInBaseFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BIOvernightLengthFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true;
        }
        else if BIFilterRuleCategory.BIWorkBlockCountCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIReserveOffDaysFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIGTmaxFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIRedEyeTripsFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIGTavgFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIOvAvgFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BI1or2OFFFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = true
        }
        else if BIFilterRuleCategory.BIOvernightCitiesBulkRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = false
            let ruleCell = cell as? CBOvernightBulkRuleCell
            ruleCell?.filterRule = rule!
            ruleCell?.bidPeriod = bidPeriod
            ruleCell?.configureOvernightBulkCell()
        }
        else if BIFilterRuleCategory.BIPDOFilterRuleCategory.rawValue == rule?.category?.intValue {
            useComparisonCell = false
            let ruleCell = cell as? CBPDORuleCell
            ruleCell?.bidPeriod = bidPeriod
            ruleCell?.calendarData = calendarData
            ruleCell?.setFilterRule(rule)
        }
        
        if useComparisonCell {
            let viewToRemove: UIView? = cell?.contentView.viewWithTag(101)
            if viewToRemove != nil {
                viewToRemove?.removeFromSuperview()
            }
            let ruleCell = cell as? CBComparisonRuleCell
            ruleCell?.modeTexttColor = self.cellFlagBorderColor
            ruleCell?.titleLabel.text = rule?.name
            if (rule?.variables?["DECIMAL"] != nil) {
                let ruleValue = (rule?.variables?[BIFilterRuleValueVariablesKey] as! NSNumber).floatValue
                var numPlaces: Double = 0.0
                if let _ = rule!.variables!["NUMPLACES"] as? String {
                    numPlaces = Double(rule!.variables!["NUMPLACES"] as! String)!
                }
                if let _ = rule!.variables!["NUMPLACES"] as? Double {
                    numPlaces = rule!.variables!["NUMPLACES"] as! Double
                }
                var formatString = String ()
                if numPlaces == 2 {
                    formatString = String(format:"%.2f", ruleValue)
                } else {
                    formatString = String(format:"%.1f", ruleValue)
                }
                ruleCell?.valueButton.setTitle("\(formatString)", for: .normal)
                if  BIFilterRuleCategory.BIGTavgFilterRuleCategory.rawValue == rule?.category?.intValue || BIFilterRuleCategory.BIGTmaxFilterRuleCategory.rawValue == rule?.category?.intValue {
                    let hours = Int(ruleValue / 60)
                    let minutes = Int(ruleValue.truncatingRemainder(dividingBy: 60))
                    // Create a string in the format "hh:mm"
                    let formattedTime = String(format: "%02d:%02d", hours, minutes)
                    ruleCell?.valueButton.setTitle(formattedTime, for: .normal)
                }
                
            } else {
                let strValue = rule?.variables![BIFilterRuleValueVariablesKey]
                let endValue = (strValue as! NSNumber).stringValue
                ruleCell?.valueButton.setTitle("\(endValue)", for: .normal)
            }
            var comparisonString = "At Most"
            if rule?.comparison?.intValue == 2 {
                comparisonString = "Exactly"
            }
            else if rule?.comparison?.intValue == 3 {
                comparisonString = "At Least"
            }
            ruleCell?.comparisonButton.setTitle(comparisonString, for: .normal)
            ruleCell?.filterRule = rule
            if BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue == rule?.category?.intValue && BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConusLegs.rawValue != rule?.type?.intValue || BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue == rule?.category?.intValue && BIDeadheadsFilterRuleType.BIDeadheadsAtEndType.rawValue == rule?.type?.intValue || BIDeadheadsFilterRuleType.BIDeadheadsAtStartType.rawValue == rule?.type?.intValue || BIDeadheadsFilterRuleType.BIDeadheadsAtEitherType.rawValue == rule?.type?.intValue {
                let city = rule?.variables![BIFilterRuleCityVariablesKey]
                let cityComparisonCell = cell as? CBCityComparisonRuleCell
                cityComparisonCell?.cityTextField.text = city as? String
                cityComparisonCell?.titleLabel.text = rule?.name
                cityComparisonCell?.bidPeriod = bidPeriod
                cityComparisonCell?.filterRule = rule
            }
            cell?.textLabel?.alpha = 1
            cell?.isUserInteractionEnabled = true
            cell?.contentView.alpha = 1
            if (BIFilterRuleCategory.BIVacationFilterRuleCategory.rawValue == rule!.category?.intValue) {
                let swapImage = UIImage(named: SwaptimizerVacationImage)
                let swapImgView = UIImageView(frame: CGRect(x: 230.0, y: 12.0, width: 40.0, height: 40.0))
                swapImgView.tag = 101
                swapImgView.image = swapImage
                cell!.contentView.addSubview(swapImgView)
                
                if let vacationType = self.bidPeriod!.vacationType, vacationType.count > 1 {
                    swapImgView.alpha = 1.0
                    cell?.textLabel?.alpha = 1.0
                    cell!.isUserInteractionEnabled = true
                    cell!.contentView.alpha = 1.0
                } else {
                    swapImgView.alpha = 0.5
                    cell?.textLabel?.alpha = 0.5
                    cell!.isUserInteractionEnabled = false
                    cell!.contentView.alpha = 0.5
                }
            }
            else if (BIFilterRuleCategory.BIFaVacationFilterRuleCategory.rawValue == rule!.category?.intValue) {
                let swapImage = UIImage(named: "FA_Vacation_Image_Shadow")
                let swapImgView = UIImageView(frame: CGRect(x: 230.0, y: 12.0, width: 40.0, height: 40.0))
                swapImgView.tag = 101
                swapImgView.image = swapImage
                cell!.contentView.addSubview(swapImgView)
                
                let manageVacationEnabled = UserDefaults.standard.bool(forKey: kCBManageVacationEnabledKey)
                
                if (self.bidPeriod!.vacationType?.count ?? 0) <= 1 && !manageVacationEnabled {
                    swapImgView.alpha = 0.5
                    cell?.textLabel?.alpha = 0.5
                    cell!.isUserInteractionEnabled = false
                    cell!.contentView.alpha = 0.5
                } else {
                    swapImgView.alpha = 1.0
                    cell?.textLabel?.alpha = 1.0
                    cell!.isUserInteractionEnabled = true
                    cell!.contentView.alpha = 1.0
                }
            }
            else {
                if let viewToRemove = cell!.contentView.viewWithTag(101) {
                    viewToRemove.removeFromSuperview()
                }
                cell?.textLabel?.alpha = 1.0
                cell!.isUserInteractionEnabled = true
                cell!.contentView.alpha = 1.0
            }
        }
    }

}

