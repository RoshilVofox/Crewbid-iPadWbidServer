//
//  CBRulesMenuTableVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import UIKit
import CoreData

protocol CBRulesMenuFilterDelegate: AnyObject {
    func filterSelected(filter: NSDictionary)
}

class CBRulesMenuTableVC: UIViewController,UITableViewDelegate,UITableViewDataSource,KUIPopOverUsable {
    private var kCellReuseIdentifier = "menuCell"
    var menuItems = NSArray()
    var disabledCellIndexPaths = NSMutableArray()
    var bidPeriod = BIBidPeriod()
    var arrowDirection: UIPopoverArrowDirection = UIPopoverArrowDirection.right
    var context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext
    
    weak var delegate: AnyObject?
    var contentSize: CGSize {
        var height : CGFloat = 40 * CGFloat(self.menuItems.count)
        if height > 700 {
            height = 700
        }
        preferredContentSize = CGSize(width: 310, height: height + 30)
        return CGSize(width: preferredContentSize.width, height: preferredContentSize.height)
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: kCellReuseIdentifier)
        self.tableView.separatorInset = .zero
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                tableView.allowsSelection = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var title:String?
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier, for: indexPath)
        let item: NSDictionary = menuItems[indexPath.row] as! NSDictionary
        title = item.object(forKey: "title") as? String
        if title == nil {
            title = item.object(forKey: "name") as? String
        }
        cell.textLabel?.text = title!
        cell.selectionStyle = .gray
        
        let types = item["types"] as? [Any]
        if (types != nil && types!.count > 0) {
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        } else {
            cell.accessoryType = UITableViewCell.AccessoryType.none
        }
        var category = 0
        let categoryAny = item.object(forKey: "category")
        if (categoryAny != nil) {
            category = (item.object(forKey: "category") as? Int)!
        }
        
        if BIFilterRuleCategory.BIVacationFilterRuleCategory.rawValue == category || (title == "SWAPtimizer") {
            let type = item.object(forKey: "type")
            if ((title != "SWAPtimizer") && cellIsHidden(for: type as! Int)) {
                var size: CGSize = preferredContentSize
                size.height -= tableView.rowHeight
                preferredContentSize = size
                cell.isHidden = true
            }
            else {
                let swapImage = UIImage(named: SwaptimizerVacationImage)
                
                if let types = types, !types.isEmpty {
                    if SwaptimizerVacationImage == "SwaptAlert" {
                        cell.textLabel?.text = "SWAPtimizer"
                    } else if SwaptimizerVacationImage == "WBidmax-logo" {
                        cell.textLabel?.text = "WBidmax"
                    }
                }
                
                let swapImgView = UIImageView(frame: CGRect(x: 200.0, y: 2.0, width: 40.0, height: 40.0))
                swapImgView.tag = 101
                swapImgView.alpha = 1.0
                swapImgView.image = swapImage
                cell.contentView.addSubview(swapImgView)
                
                if self.bidPeriod.vacationType!.count <= 1 {
                    swapImgView.alpha = 0.5
                    cell.textLabel?.alpha = 0.5
                    cell.isUserInteractionEnabled = false
                }
            }
        }
        else if BIFilterRuleCategory.BIFaVacationFilterRuleCategory.rawValue == category || (title == "Vacation") {
            let swapImage = UIImage(named: "FA_Vacation_Image_Shadow")
            let swapImgView = UIImageView(frame: CGRect(x: 200.0, y: 3.0, width: 34.0, height: 34.0))
            swapImgView.tag = 101
            swapImgView.image = swapImage
            cell.contentView.addSubview(swapImgView)
        }
        //        else if BIFilterRuleCategory.BICommutingFilterRuleCategory.rawValue == category {
        //            let fetchedObjects = ((CBGlobalMethods.shared.selectedBidPeriod!.commutabilities?.allObjects ?? []) as NSArray).filtered(using: NSPredicate(format: "commutableType == 0")) as! [Commutability]
        //            if fetchedObjects.count > 0 {
        //                cell.isUserInteractionEnabled = false
        //            } else {
        //                cell.isUserInteractionEnabled = true
        //            }
        //        }
        else if BIFilterRuleCategory.BIOvernightCitiesBulkRuleCategory.rawValue == category {
            
        }
        else {
            let viewToRemove: UIView? = cell.contentView.viewWithTag(101)
            if viewToRemove != nil {
                viewToRemove?.removeFromSuperview()
            }
        }
        
        if disabledCellIndexPaths.contains(indexPath) {
            cell.textLabel?.textColor = .lightGray
        }
        else {
            if #available(iOS 13.0, *) {
                cell.textLabel?.textColor = .label
            } else {
                cell.textLabel?.textColor = .black// Fallback on earlier versions
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item: NSDictionary = menuItems[indexPath.row] as! NSDictionary
        var category:Int = 0
        let categoryAny = item.object(forKey: "category")
        if (categoryAny != nil) {
            category = (item.object(forKey: "category") as? Int)!
        }
        if BIFilterRuleCategory.BIVacationFilterRuleCategory.rawValue == category {
            let type:Int = item.object(forKey: "type") as! Int
            if cellIsHidden(for: type) {
                return 0.0
            } else {
                return 40
            }
        } else {
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        var shouldHighlight = true
        if disabledCellIndexPaths.contains(indexPath) {
            shouldHighlight = false
        }
        return shouldHighlight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if disabledCellIndexPaths.contains(indexPath) {
            return
        }
        let item:NSDictionary = menuItems[indexPath.row] as! NSDictionary
        let types:NSArray?
        types = item.object(forKey: "types") as? NSArray
        var category:Int = 0
        let categoryAny = item.object(forKey: "category")
        if (categoryAny != nil) {
            category = (item.object(forKey: "category") as? Int)!
        }
        
        var title:String?
        title = item.object(forKey: "title") as? String
        if title == nil {
            title = item.object(forKey: "name") as? String
        }
        if (category == BIFilterRuleCategory.BIOvernightCitiesBulkRuleCategory.rawValue) {
            self.bidPeriod.isOverNightBulkApplied = "YES";
        }
        
        selectFilterMenuAt(indexPath: indexPath, with: category, and: types)
        
    }
    func selectFilterMenuAt(indexPath: IndexPath, with category: Int, and types: NSArray?) {
        let item  = menuItems.object(at: indexPath.row) as! [String: Any]
        //        for menu items which have next arrow
        if let types = types as? [Any], !types.isEmpty {
            let storyboard = UIStoryboard(name: "Filter", bundle: nil)
            let subRulesTableVC = storyboard.instantiateViewController(withIdentifier: "CBRulesMenuTableVC") as! CBRulesMenuTableVC
            subRulesTableVC.menuItems = types as NSArray
            subRulesTableVC.title = item["title"] as? String
            subRulesTableVC.bidPeriod = self.bidPeriod
            subRulesTableVC.context = self.context
            subRulesTableVC.navigationItem.title = item["title"] as? String
            subRulesTableVC.navigationController?.navigationBar.prefersLargeTitles = false
            subRulesTableVC.delegate = delegate
            let fetchRequst: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
            var abbreviations = subRulesTableVC.menuItems.value(forKey: "abbreviation") as? NSArray
            let tempAbbreviations = abbreviations!.mutableCopy() as? NSMutableArray
            for i in 0..<abbreviations!.count {
                let abbreviation = abbreviations![i]
                if !(abbreviation is NSNull) {
                    if let abbreviationStr = abbreviation as? String,
                       abbreviationStr == "LegCty" || abbreviationStr == "OC" {
                        tempAbbreviations!.replaceObject(at: i, with: NSNull())
                    }
                }
            }
            abbreviations = tempAbbreviations
            let predicate1 = NSPredicate(format: "bidPeriod == %@", bidPeriod)
            let predicate2 = NSPredicate(format: "abbreviation IN %@", abbreviations!)
            let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
            fetchRequst.predicate = combinedPredicate
            let results = try! self.context!.fetch(fetchRequst)
            for linerule in results {
                let index = abbreviations!.index(of: linerule.abbreviation)
                if index != NSNotFound {
                    let indexPath = IndexPath(row: index, section: 0)
                    disabledCellIndexPaths.add(indexPath)
                }
            }
            subRulesTableVC.disabledCellIndexPaths = disabledCellIndexPaths
            navigationController?.pushViewController(subRulesTableVC, animated: true)
        }
        //        for menu items which does not have next arrow
        else {
            CBGlobalMethods.shared.selectedBidPeriod?.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
                            tableView.allowsSelection = false
            var rule = BIFilterRule()
            if BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue != category {
                let resultsFilter = (CBGlobalMethods.shared.selectedBidPeriod!.lineFilters!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 33")) as! [BIFilterRule]
                let resultsSort = (CBGlobalMethods.shared.selectedBidPeriod!.lineSorts!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 9")) as! [BILineSort]
                if (resultsSort.count > 0 || resultsFilter.count > 0) &&  (item["category"] as! Int == 12 || item["category"] as! Int == 4 ) {
                    AlertService.showAlertForTopVC(title: "Crewbid", message: "You can only add a Commutable Line - Auto or a Commutable Line - Manual constraint, but NOT both.", actions: [
                        (title: "OK", style: .default, handler: { _ in
                            DispatchQueue.main.async {
                                self.dismiss(animated: true, completion: nil)
                            }
                        }),
                        (title: "Cancel", style: .cancel, handler: { _ in
                            print("Cancel tapped")
                                                            self.tableView.allowsSelection = true
                        })
                    ])
                    return
                }
                if let context = self.bidPeriod.managedObjectContext {
                    rule = BIFilterRule(context: context)
                    rule.setValuesForKeys(menuItems[indexPath.row] as! [String : Any])
                    rule.bidPeriod = self.bidPeriod
                    self.dismissPopover(animated: true)
                }
            }
            if BIFilterRuleCategory.BIDaysOfMonthFilterRuleCategory.rawValue == category {
                let mBits: UInt64 = 0
                let MONTH_BITS = mBits
                
                let dict  = NSDictionary(object: MONTH_BITS, forKey: "MONTH_BITS" as NSCopying)
                rule.variables = dict
            }
            else if (BIFilterRuleCategory.BIReportReleaseFilterCategory.rawValue == category) {
                
                let mBits: UInt64 = 0
                let MONTH_BITS = NSNumber(value: mBits)
                let dict  = NSDictionary(object: MONTH_BITS, forKey: "MONTH_BITS" as NSCopying)
                rule.variables = dict
                let variables = NSMutableDictionary(dictionary: rule.variables!)
                let arrDates = NSMutableArray()
                variables[BIFilterRuleSelectedDaysVariablesKey] = arrDates
                variables[BIFilterRuleReportVariablesKey] = ""
                variables[BIFilterRuleReleaseVariablesKey] = ""
                variables[BIFilterRuleCheckStateReportVariablesKey] = NSNumber(value: false)
                variables[BIFilterRuleCheckstateReleaseVariablesKey] = NSNumber(value: false)
                rule.variables = variables
            }
            else if (BIFilterRuleCategory.BIUserFlagFilterRuleCategory.rawValue == category) {
                
                let SET = Set([CBUserFlagType.none.rawValue, CBUserFlagType.yellow.rawValue, CBUserFlagType.orange.rawValue, CBUserFlagType.red.rawValue, CBUserFlagType.green.rawValue, CBUserFlagType.blue.rawValue, CBUserFlagType.brown.rawValue, CBUserFlagType.pink.rawValue])
                let dict  = NSDictionary(object: SET, forKey: "SET" as NSCopying)
                rule.variables = dict
            }
            else if BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue == category {
                let fetchRequestForSort: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
                fetchRequestForSort.predicate = NSPredicate(format: "category == 4")
                let resultSort = try! context?.fetch(fetchRequestForSort) ?? []
                let fetchRequestForFilter: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
                fetchRequestForFilter.predicate = NSPredicate(format: "category == 12")
                let results = try! context?.fetch(fetchRequestForFilter) ?? []
                
                if (results.count > 0 || resultSort.count > 0) {
                    AlertService.showAlertForTopVC(title: "Crewbid", message: "You can only add a Commutable Line - Auto or a Commutable Line - Manual constraint, but NOT both.")
                }
                else {
                    let fetchCommutablityRequset: NSFetchRequest<Commutability> = Commutability.fetchRequest()
                    fetchCommutablityRequset.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.sort.rawValue)
                    let fetchedObjects = try! context!.fetch(fetchCommutablityRequset) ?? []
                    
                    if fetchedObjects.count > 0 {
                        rule = BIFilterRule(context: context!)
                        rule.bidPeriod = self.bidPeriod
                        if let dict = self.menuItems[indexPath.row] as? [String: Any] {
                            rule.setValuesForKeys(dict)
                        }
                        let objCommutabilitySort = fetchedObjects[0]
                        
                        let objCommutabilityFilter = Commutability(context: self.bidPeriod.managedObjectContext!)
                        
                        objCommutabilityFilter.type = 1
                        objCommutabilityFilter.secondCellValue = 1
                        objCommutabilityFilter.value = 100
                        objCommutabilityFilter.commutableType = 0
                        objCommutabilityFilter.city = objCommutabilitySort.city
                        objCommutabilityFilter.checkInTime = objCommutabilitySort.checkInTime
                        objCommutabilityFilter.connectTime = objCommutabilitySort.connectTime
                        objCommutabilityFilter.baseTime = objCommutabilitySort.baseTime
                        do {
                            try context!.save()
                        }
                        catch {
                            print("error saving commute auto details \(error.localizedDescription)")
                        }
                    }
                    else {
                        NotificationCenter.default.post(name: Notification.Name("ShowCommutabilityFilterView"), object: self)
                        
//                        self.dismiss(animated: true)
                    }
                    
                }
            }
            if BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue != category {
                if (rule.ruleHighlightsTrips() == true) {
                    rule.highlightTrips()
                }
            }
            
            try? bidPeriod.managedObjectContext!.save()
            NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
            //        else {
            ////            MARK: in the case of commute auto
            //            if item["name"] as? String == "Commuting - Auto" {
            //                if let presentingVC = self.presentingViewController {
            //                    self.dismiss(animated: true) {
            //                        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
            //                        let vc = storyboard.instantiateViewController(withIdentifier: "CommuteInformation") as! CBCommuteInfoViewController
            //                        vc.preferredContentSize = CGSize(width: 320, height: 320)
            //                        presentingVC.present(vc, animated: true)
            //                    }
            //                }
            //                return
            //            }
            //            else {
            //                let newRow = [
            //                    "category": item["category"] as! Int,
            //                    "type": item["type"] as? Int ?? 0,
            //                    "title": item["name"] as? String ?? "",
            //                ] as [String : Any]
            //                AppData.shared.filtersToBeAddedInTable.append(newRow)
            //                NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
            //                self.dismiss(animated: true, completion: nil)
            //                return
            //            }
            //        }
        }
    }
    func cellIsHidden(for type: BIVacationFilterRuleType.RawValue) -> Bool {
        let hiddenDict: [String: Any] = UserDefaults.standard.object(forKey: kCBSwaptimizerHiddenDict) as! [String : Any]
        if ((BIVacationFilterRuleType.BIVacationFilterRuleTypeEffectiveVacationLength.rawValue == type && hiddenDict[kCBSwaptmizerEffVacayLengthHidden] as? Bool == true) || (BIVacationFilterRuleType.BIVacationFilterRuleTypeBLongestBlockofDaysOff.rawValue == type && hiddenDict[kCBSwaptmizerLongestBlockofDaysOffHidden] as? Bool == true) || (BIVacationFilterRuleType.BIVacationFilterRuleTypeCarryOutPay.rawValue == type && hiddenDict[kCBSwaptmizerCarryOutPayHidden] as? Bool == true) || (BIVacationFilterRuleType.BIVacationFilterRuleTypeFrontVoPay.rawValue == type && hiddenDict[kCBSwaptmizerFrontVoHidden] as? Bool == true) || (BIVacationFilterRuleType.BIVacationFilterRuleTypeBackVoPay.rawValue == type && hiddenDict[kCBSwaptmizerBackVoHidden] as? Bool == true) || (BIVacationFilterRuleType.BIVacationFilterRuleTypeVacayCarryOutPay.rawValue == type && hiddenDict[kCBSwaptmizerVacayCarryOutPayHidden] as? Bool == true) ||
            BIVacationFilterRuleType.BIVacationFilterRuleTypeCarryOutVoPay.rawValue == type && hiddenDict[kCBSwaptmizerCarryOutVoHidden] as? Bool == true) {
            return true
        }
        else {
            return false
        }
    }
}
