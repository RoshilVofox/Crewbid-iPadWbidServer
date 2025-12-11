//
//  RefreshController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

protocol CommutabilityCellDelegate {
    func firstCellAction(_ value: Int)
    func secondCellAction(_ value: Int)
    func thirdCellAction(_ value: Int)
    func fourthCellAction(_ value: Int)
}

protocol CommutingManualRuleCellDelegate {
    func valueBtnAction(_ value: Int)
}

protocol StartOverDelegate:AnyObject {
    func startOver()
}

@objc protocol RefreshDelegate {
    func didSelected(itemName: String)
    @objc optional func didSetDays(itemName: String)
}

class RefreshController: UIViewController, UITableViewDataSource, UITableViewDelegate, KUIPopOverUsable, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var viewBackground: UIView!
    
    let kRefreshMenuCell = "RefreshCell"
    var Commutabilitydelegate: CommutabilityCellDelegate?
    var CommutingManualDelegate: CommutingManualRuleCellDelegate!
    var bidPeriod = BIBidPeriod()
    var selectedLinesCount:NSMutableArray = NSMutableArray()
    var popOverType = PopoverViewType.MockYear
    var arrMonth :NSArray = NSArray()
    var arrYear :NSArray = NSArray()
    //    var objSecretView: SecretFeaturesHandlingController?
    var arrFAPositions:NSMutableArray = NSMutableArray()
    var arrCellParameters:NSArray = NSArray()
    var filterRule: BIFilterRule?
    var Delegate: RefreshDelegate?
    var menuItems = NSMutableArray()
    var line : BILine?
    var arrayLinesDetails:NSArray = NSArray()
    var selectedValue = ""
    
    weak var delgate:StartOverDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewBackground.clipsToBounds = true
        self.viewBackground.layer.cornerRadius = 5
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        arrMonth = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        arrYear = ["2018","2017","2016","2015"]
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if popOverType == PopoverViewType.cityPopUp {
            let type: NSInteger = (self.filterRule?.type?.intValue)!
            if self.filterRule?.category?.intValue == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue && (BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue == type) {
                
                if self.filterRule?.ruleHighlightsTrips() == true {
                    self.filterRule?.deHighlightTrips()
                }
                
                let SET: NSSet = NSSet(array: (self.filterRule?.selectedRegionalCities())! as! [Any])
                var filterVars = NSMutableDictionary()
                filterVars = self.filterRule?.variables?.mutableCopy() as! NSMutableDictionary
                filterVars.setObject(SET, forKey: "SET" as NSCopying)
                self.filterRule?.variables = NSDictionary(dictionary: filterVars)
                
                if (self.filterRule?.ruleHighlightsTrips())! {
                    self.filterRule?.highlightTrips()
                }
            }
            try? self.bidPeriod.managedObjectContext!.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        var indexPath = IndexPath(row: 0, section: 0)
        
        if selectedValue != "" {
            if let paramsArray = (arrCellParameters as? [String]) {
                if let index = paramsArray.firstIndex(of: selectedValue) {
                    indexPath = IndexPath(row: index, section: 0)
                }
            } else if let paramsArray = (arrCellParameters as? [Int]) {
                selectedValue = selectedValue.replacingOccurrences(of: "%", with: "")
                if let index = paramsArray.firstIndex(of: Int(selectedValue)!) {
                    indexPath = IndexPath(row: index, section: 0)
                }
            }
        }
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
    }
    
    var contentSize: CGSize {
        var size:CGSize?
        if popOverType == PopoverViewType.Refresh
        {
            size = CGSize(width: 150.0, height: 177)
        }
        else if popOverType == PopoverViewType.MockMonth
        {
            size = CGSize(width: 150.0, height: 200)
        }
        else if popOverType == PopoverViewType.MockYear
        {
            size = CGSize(width: 150.0, height: 200)
        }
        else if popOverType == PopoverViewType.warning
        {
            size = CGSize(width: 280.0, height: 80)
        }
        else if popOverType == PopoverViewType.MoveFAPositions
        {
            if arrFAPositions.count == 4 {
                size = CGSize(width: 280.0, height: 180)
            }
            else if arrFAPositions.count == 3 {
                size = CGSize(width: 280.0, height: 136)
            } else {
                size = CGSize(width: 280.0, height: 180)
            }
        }
        else if popOverType == PopoverViewType.MoreButton
        {
            size = CGSize(width: 300.0, height: 350)
        }
        else if popOverType == PopoverViewType.comparisonButton
        {
            size = CGSize(width: 140, height: 152)
        }
        else if popOverType == PopoverViewType.valuesButton
        {
            size = CGSize(width: 100.0, height: CGFloat(arrCellParameters.count * 44))
        }
        else if popOverType == PopoverViewType.RuleValue
        {
            size = CGSize(width: 120.0, height: CGFloat(arrCellParameters.count * 44))
        }
        else if popOverType == PopoverViewType.pdoBeforeorAfter
        {
            size = CGSize(width: 140, height: 102)
        }
        else if  popOverType == PopoverViewType.pdoValue{
            size = CGSize(width: 130.0, height: CGFloat(arrCellParameters.count * 44))
        }
        else if popOverType == PopoverViewType.cityPopUp  || popOverType == PopoverViewType.pdoCities
        {
            if filterRule?.category?.intValue == BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue {
                size = CGSize(width: 100.0, height: CGFloat(menuItems.count * 44))
            }
            else {
                size = CGSize(width: 140.0, height: CGFloat(menuItems.count * 44))
            }
        }
        else if popOverType == PopoverViewType.CommutabilityFirstCell
        {
            size = CGSize(width: 140.0, height: 100)
        }
        else if popOverType == PopoverViewType.CommutabilityThirdCell
        {
            size = CGSize(width: 100.0, height: 100)
        }
        else if popOverType == PopoverViewType.CommutabilitySecondCell
        {
            size = CGSize(width: 120.0, height: 140)
        }
        else if popOverType == PopoverViewType.CommutabilityFourthCell
        {
            size = CGSize(width: 100.0, height: 140)
        }
        else if popOverType == PopoverViewType.CommutingManualValueCell
        {
            size = CGSize(width: 80.0, height: 140)
        }
        else if popOverType == PopoverViewType.CommutingManualNoMidInfo || popOverType == PopoverViewType.CommutingManualNoMidInfoSort //For displaying commute manual popup
        {
            size = CGSize(width: 300, height: 80)
        }
        return size!
    }
    
    var popOverBackgroundColor: UIColor? {
        var color: UIColor?
        if popOverType == PopoverViewType.warning || popOverType == PopoverViewType.CommutingManualNoMidInfo || popOverType == PopoverViewType.CommutingManualNoMidInfoSort
        {
            color = .gray//UIColor(red: 0.941, green: 0.922, blue: 0.965, alpha: 1.000)
        }
        else {
            color = UIColor.white
        }
        return color
        
    }
    var arrowDirection: UIPopoverArrowDirection = .right
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowsCount = 0
        if popOverType == PopoverViewType.Refresh {
            rowsCount = 4
        }
        else if popOverType == PopoverViewType.MockMonth {
            rowsCount = 12
        }
        else if popOverType == PopoverViewType.MockYear {
            rowsCount = 4
        }
        else if popOverType == PopoverViewType.warning || popOverType == PopoverViewType.CommutingManualNoMidInfo || popOverType == PopoverViewType.CommutingManualNoMidInfoSort {
            rowsCount = 1
        }
        else if popOverType == PopoverViewType.MoveFAPositions {
            rowsCount = arrFAPositions.count
        }
        else if popOverType == PopoverViewType.comparisonButton || popOverType == PopoverViewType.valuesButton || popOverType == PopoverViewType.cityPopUp || popOverType == PopoverViewType.CommutabilityFirstCell || popOverType == PopoverViewType.CommutabilitySecondCell || popOverType == PopoverViewType.CommutabilityThirdCell || popOverType == PopoverViewType.CommutabilityFourthCell || popOverType == PopoverViewType.CommutingManualValueCell || popOverType == PopoverViewType.RuleValue || popOverType == PopoverViewType.pdoBeforeorAfter || popOverType == PopoverViewType.pdoCities || popOverType == PopoverViewType.pdoValue {
            rowsCount = arrCellParameters.count
        }
        return rowsCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 44.0
        if popOverType == PopoverViewType.warning {
            height = 80.0
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        self.tableView.separatorInset = UIEdgeInsets.zero
        
           let cell = UITableViewCell(style: .default, reuseIdentifier: kRefreshMenuCell)
        if popOverType == PopoverViewType.Refresh {
//            MARK: code need to be added for refresh
        }
        else if popOverType == PopoverViewType.MockYear {
            cell.textLabel?.text = arrYear[indexPath.row] as? String
        }
        else if popOverType == PopoverViewType.MockMonth {
            cell.textLabel?.text = arrMonth[indexPath.row] as? String
        }
        else if popOverType == PopoverViewType.warning {
            //            MARK: code need to be added for Warning
        }
        else if popOverType == PopoverViewType.CommutingManualNoMidInfo || popOverType == PopoverViewType.CommutingManualNoMidInfoSort {
            let textView = UITextView(frame: self.viewBackground.frame)
            tableView.contentInsetAdjustmentBehavior = .automatic
            tableView.isScrollEnabled = false
            textView.layer.cornerRadius = 10
            textView.layer.masksToBounds = true
            textView.textAlignment = NSTextAlignment.center
            if #available(iOS 13.0, *) {
                textView.textColor = UIColor.label
            } else {
                textView.textColor = UIColor.black// Fallback on earlier versions
            }
            if #available(iOS 13.0, *) {
                textView.backgroundColor = .systemBackground
            } else {
                textView.backgroundColor = UIColor(red: 0.941, green: 0.922, blue: 0.965, alpha: 1.000)// Fallback on earlier versions
            }
            if #available(iOS 13.0, *) {
                cell.backgroundColor = .systemBackground
            } else {
                cell.backgroundColor = UIColor(red: 0.941, green: 0.922, blue: 0.965, alpha: 1.000)// Fallback on earlier versions
            }
            if #available(iOS 13.0, *) {
                self.tableView.backgroundColor = .systemBackground
            } else {
                self.tableView.backgroundColor = UIColor(red: 0.941, green: 0.922, blue: 0.965, alpha: 1.000)// Fallback on earlier versions
            }
            self.tableView.separatorStyle = .none
            self.view.backgroundColor = .lightGray
            textView.font = UIFont(name: "LiberationMono", size: 11.0)
            
            if popOverType == PopoverViewType.CommutingManualNoMidInfo {
                textView.text = "If noMid is checked, WorkBlocks are considered"
            } else {
                textView.text = "If noMid is checked, WorkBlocks are considered"
            }
            cell.addSubview(textView)
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            cell.isUserInteractionEnabled = false
        }
        
        else if popOverType == PopoverViewType.MoveFAPositions {
            let arrValues:NSMutableDictionary = arrFAPositions[indexPath.row] as! NSMutableDictionary
            cell.textLabel?.text = arrValues.value(forKey: "strToShow") as? String
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        }
        else if popOverType == PopoverViewType.MoreButton {
            //            MARK: code need to be added for more button
        }
        else if popOverType == PopoverViewType.comparisonButton {
            cell.textLabel?.text = arrCellParameters[indexPath.row] as? String
        }
        else if popOverType == PopoverViewType.RuleValue {
            cell.textLabel?.text = arrCellParameters[indexPath.row] as? String
        }
        else if popOverType == PopoverViewType.valuesButton || popOverType == PopoverViewType.pdoValue {
            cell.textLabel?.text = arrCellParameters[indexPath.row] as? String
        }
        else if popOverType == PopoverViewType.cityPopUp {
            let cities: NSArray = filterRule!.selectedRegionalCities() as NSArray
            let selectedCities = NSMutableArray(array: cities)
            if filterRule?.category?.intValue == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue {
                let newCity: String = arrCellParameters[indexPath.row] as! String
                if selectedCities.contains(newCity) {
                    cell.accessoryType = UITableViewCell.AccessoryType.checkmark
                }
                else {
                    cell.accessoryType = UITableViewCell.AccessoryType.none
                }
            }
            cell.textLabel?.text = arrCellParameters[indexPath.row] as? String
        }
        else if popOverType == PopoverViewType.CommutabilityFirstCell {
            cell.textLabel?.text = arrCellParameters[indexPath.row] as? String
        }
        else if popOverType == PopoverViewType.CommutabilitySecondCell {
            cell.textLabel?.text = arrCellParameters[indexPath.row] as? String
        }
        else if popOverType == PopoverViewType.CommutabilityThirdCell {
            cell.textLabel?.text = arrCellParameters[indexPath.row] as? String
        }
        else if popOverType == PopoverViewType.CommutabilityFourthCell {
            cell.textLabel?.text = String(describing: arrCellParameters[indexPath.row])
        }
        else if popOverType == PopoverViewType.CommutingManualValueCell {
            cell.textLabel?.text = String(describing: arrCellParameters[indexPath.row])
        }
        
        else if popOverType == PopoverViewType.pdoBeforeorAfter{
            cell.textLabel?.text =  String(describing: arrCellParameters[indexPath.row])
        }
        else if popOverType == PopoverViewType.pdoCities{
            cell.textLabel?.text =  String(describing: arrCellParameters[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if popOverType == PopoverViewType.Refresh {
//            MARK: code need to be added for refresh
            if indexPath.row == 0 {
                let results = self.bidPeriod.getTrashedLines()
                for line in results {
                    line.isTrashed = false
                }
                
                let objDeleteArray = self.bidPeriod.lastTrashedDetails?.mutableCopy() as! NSMutableArray
                objDeleteArray.removeAllObjects()
                self.bidPeriod.lastTrashedDetails = objDeleteArray.copy() as? NSArray
                try? self.bidPeriod.managedObjectContext!.save()
                self.dismissPopover(animated: true)
            }
            else if indexPath.row == 1 {
                
                let LastObject = self.bidPeriod.lastTrashedDetails?.lastObject as! String
                let seperatedComponents = LastObject.components(separatedBy: ",") as [String]
                let arrAll: NSMutableArray = NSMutableArray(array: seperatedComponents)
                

                let Objresults = bidPeriod.lines!.allObjects as NSArray
                for case let line as BILine in Objresults {
                    for i in 0...arrAll.count - 1 {
                        let lineNumber: Int = line.number as! Int
                        let arrLinevalue = (arrAll[i] as! NSString).integerValue
                        
                        if lineNumber == arrLinevalue {
                            line.isTrashed = false
                        }
                    }
                }
                let objDeleteArray = self.bidPeriod.lastTrashedDetails?.mutableCopy() as! NSMutableArray
                objDeleteArray.removeLastObject()
                self.bidPeriod.lastTrashedDetails = objDeleteArray.copy() as? NSArray
                try? self.bidPeriod.managedObjectContext!.save()
                self.dismissPopover(animated: true)
            }
            else if indexPath.row == 2 {
                for case let line as BILine in arrayLinesDetails {
                    // for line: BILine in arrayLinesDetails {
                    line.isTrashed = true
                }
                
                let LinesList  = self.arrayLinesDetails.value(forKey: "number") as Any
                // var arr = Array(LinesList as! Array<Any>)
                let arrLinesList : NSArray = LinesList as! NSArray
                
                let joinedComponents: String? = arrLinesList.componentsJoined(by: ",")
                let objDeleteArray:NSMutableArray = self.bidPeriod.lastTrashedDetails?.mutableCopy() as! NSMutableArray
                objDeleteArray.add(joinedComponents!)
                self.bidPeriod.lastTrashedDetails = objDeleteArray.copy() as? NSArray
                try? self.bidPeriod.managedObjectContext!.save()
                self.dismissPopover(animated: true)
            }
                
            else if indexPath.row == 3 {
                
                self.dismissPopover(animated: true)
            }

        }
        else if popOverType == PopoverViewType.MockYear {
            self.dismissPopover(animated: true)
        }
        else if popOverType == PopoverViewType.MockMonth {
            self.dismissPopover(animated: true)
        }
        else if popOverType == PopoverViewType.MoveFAPositions {
            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            let arrValues:NSMutableDictionary = arrFAPositions[indexPath.row] as! NSMutableDictionary
            let value = arrValues.value(forKey: "lineValue")
            let isAll: Bool = arrValues.value(forKey: "bidAll") as! Bool
            let appendDictionary = NSMutableDictionary()
            appendDictionary["bidAll"] = isAll
            appendDictionary["lineValue"] = value
            let bidLinesNotification = Notification(name: Notification.Name("MoveFALines"), object: self, userInfo: [CBLinesTableBidLinesArrayKey: appendDictionary])
            NotificationCenter.default.post(bidLinesNotification)
            self.dismissPopover(animated: true)
        }
        else if popOverType == PopoverViewType.MoreButton {
//            MARK: needed to add did select for more button
            if indexPath.row == 0 {
                let message = """
                Enter a line number to scroll to\(bidPeriod.isFABid() ? " in the format [number][position] (i.e. 287A)" : "") or select another option. 
                You can auto-scroll to the top by tapping the middle of the gray bar above the Bid List.
                """
                
                AlertService.showAlertForTopVC(
                    title: "Scroll to Line",
                    message: message,
                    actions: [
                        (title: "Scroll to Line", style: .default, handler: { _, textFields in
                            if let text = textFields?.first?.text {
                                let appendDictionary = NSMutableDictionary()
                                appendDictionary["lineNumber"] = text
                                NotificationCenter.default.post(name: Notification.Name("ScrollToLineNotification"), object: appendDictionary)
                            }
                        }),
                        (title: "Scroll to Insertion Bar", style: .default, handler: { _, _ in
                            NotificationCenter.default.post(name: Notification.Name("ScrollToInsertionLineNotification"), object: nil)
                        }),
                        (title: "Scroll to Bottom", style: .default, handler: { _, _ in
                            NotificationCenter.default.post(name: Notification.Name("ScrollToBottomLineNotification"), object: nil)
                        }),
                        (title: "Cancel", style: .cancel, handler: nil)
                    ],
                    textFields: [
                        (placeholder: "Line number", keyboardType: .namePhonePad, tag: 401, delegate: self)
                    ]
                )
                
            }
            else if indexPath.row == 1 {
                
                NotificationCenter.default.post(name: Notification.Name("CBDeselectAllLinesNotification"), object: nil)
                self.dismissPopover(animated: true)
            }
            else if indexPath.row == 2 {
                NotificationCenter.default.post(name: Notification.Name("CBMoveSelectedNotification"), object: nil)
                self.dismissPopover(animated: true)
            }
            else if indexPath.row == 3 {
                NotificationCenter.default.post(name: Notification.Name("CBUndoNotification"), object: nil)
                self.bidPeriod.loadedPresetIdentifier = nil
                CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
                CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
                 self.dismissPopover(animated: true)
            }
            else if indexPath.row == 4 {
               NotificationCenter.default.post(name: Notification.Name("CBRedoNotification"), object: nil)
                self.bidPeriod.loadedPresetIdentifier = nil
                CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
                CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
                self.dismissPopover(animated: true)
            }
            else if indexPath.row == 5 {
                NotificationCenter.default.post(name: Notification.Name("CBReturnSelectedLinesNotification"), object: nil)
                self.dismissPopover(animated: true)
            }
            else if indexPath.row == 6 {
                AlertService.showAlertForTopVC(
                    title: "Tap OK to remove all unfrozen lines.",
                    message: nil,
                    actions: [
                        (
                            title: "OK",
                            style: .default,
                            handler: { _ in
                                NotificationCenter.default.post(
                                    name: Notification.Name("CBReturnUnfrozenLinesNotification"),
                                    object: nil
                                )
                                self.dismissPopover(animated: true)
                                self.bidPeriod.loadedPresetIdentifier = nil
                                CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
                                CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
                            }
                        ),
                        (
                            title: "Cancel",
                            style: .cancel,
                            handler: { _ in
                                self.dismissPopover(animated: true)
                            }
                        )
                    ]
                )
            }
        }
        else if popOverType == PopoverViewType.comparisonButton {
            
            var comparison: NSNumber? = nil
            switch indexPath.row {
            case 0:
                comparison = 1
            case 1:
                comparison = 2
            case 2:
                comparison = 3
            default:
                comparison = 0
            }
            // Do nothing is selected comparison is the same as the filter rule's
            // current comparison.
            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            if !(comparison == filterRule?.comparison) {
                if (filterRule?.ruleHighlightsTrips() == true) {
                    filterRule?.deHighlightTrips()
                }
                filterRule?.comparison = comparison
                // If this is overnight length, trigger on the minimum time versus maximum
                // time depending if the user has selected at least or at most
                if filterRule?.category?.intValue == BIFilterRuleCategory.BIOvernightLengthFilterRuleCategory.rawValue {
                    if comparison?.intValue == 1 {
                        filterRule?.type = BIOvernightLengthFilterRuleType.BIMaximumOvernightLengthType.rawValue as NSNumber
                    }
                    else {
                        filterRule?.type = BIOvernightLengthFilterRuleType.BIMinimumOvernightLengthType.rawValue as NSNumber
                    }
                }
                if (filterRule?.ruleHighlightsTrips() == true) {
                    filterRule?.highlightTrips()
                }
                try? self.bidPeriod.managedObjectContext!.save()
                self.Delegate?.didSelected(itemName: arrCellParameters.object(at: indexPath.row) as! String)
                self.dismissPopover(animated: true)
            }
            self.dismissPopover(animated: true)
        }
        else if popOverType == PopoverViewType.valuesButton {
            // Do nothing if selected value is the same as the filter rule's
            // current value.
            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            let currentString = filterRule?.variables![BIFilterRuleValueVariablesKey]
            let currentValue = (currentString as! NSNumber).floatValue
            let startString = filterRule?.variables![BIFilterRuleRangeStartVariablesKey]
            let StartValue = (startString as! NSString).floatValue
            var step: Float = 1
            if (filterRule?.variables!["DECIMAL"] != nil) {
                step = (filterRule?.variables!["STEP"] as! NSNumber).floatValue
            }
            
            let floatValue = (indexPath.row as NSNumber).floatValue * step + StartValue
            var selectedValue = Float(floatValue)
            if BIFilterRuleCategory.BIGTavgFilterRuleCategory.rawValue == filterRule?.category?.intValue || BIFilterRuleCategory.BIGTmaxFilterRuleCategory.rawValue == filterRule?.category?.intValue {
                let array = ["01:00", "01:15", "01:30", "01:45", "02:00", "02:15", "02:30", "02:45", "03:00", "03:15", "03:30", "03:45", "04:00", "04:15", "04:30", "04:45", "05:00", "05:15", "05:30", "05:45", "06:00"]
                let selectedItem = array[indexPath.row]
                let components = selectedItem.components(separatedBy: ":")
                let hour = Int(components[0]) ?? 0
                let minuts = Int(components[1]) ?? 0
                selectedValue = Float((hour * 60) + minuts)
            }
            if !(currentValue == selectedValue) {
                if (filterRule?.ruleHighlightsTrips()) == true {
                    filterRule?.deHighlightTrips()
                }
                let variables = NSMutableDictionary(dictionary:(filterRule?.variables)!)
                variables[BIFilterRuleValueVariablesKey] = selectedValue
                filterRule?.variables = variables
                if (filterRule?.ruleHighlightsTrips() == true) {
                    filterRule?.highlightTrips()
                }
            }
            try? self.bidPeriod.managedObjectContext!.save()
            self.dismissPopover(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
        }
        else if popOverType == PopoverViewType.RuleValue {
            // Do nothing if selected value is the same as the filter rule's
            // current value.
            
            var value: NSString? = nil
            switch indexPath.row {
            case 0:
                value =  "workBlock1"
            case 1:
                value =  "workBlock2"
            case 2:
                value =  "workBlock3"
            case 3:
                value =  "workBlock4"
            default:
                value =  "workBlock3"
            }
            
            filterRule?.keyPath = value as String?
            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            if (filterRule?.ruleHighlightsTrips())! {
                filterRule?.highlightTrips()
            }
            try? self.bidPeriod.managedObjectContext!.save()
            self.dismissPopover(animated: true)
            self.Delegate?.didSetDays?(itemName: arrCellParameters.object(at: indexPath.row) as! String)
            NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: nil)
        }
        else if popOverType == PopoverViewType.cityPopUp {
            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            if filterRule?.category?.intValue == BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue {
                let currentCity: String = filterRule?.variables![BIFilterRuleCityVariablesKey] as! String
                let selectedCity:String = arrCellParameters[indexPath.row] as! String
                if !(currentCity == selectedCity) {
                    if (filterRule?.ruleHighlightsTrips() == true) {
                        filterRule?.deHighlightTrips()
                    }
                    let variables = filterRule?.variables
                    variables?.setValue(selectedCity, forKey: BIFilterRuleCityVariablesKey)
                    filterRule?.variables = variables
                    if (filterRule?.ruleHighlightsTrips() == true) {
                        filterRule?.highlightTrips()
                    }
                }
                try? self.bidPeriod.managedObjectContext!.save()
                self.dismissPopover(animated: true)
            }
            else {
//                regional cities popover
                var cities = NSArray()
                cities = filterRule!.selectedRegionalCities() as NSArray
                let selectedCities = NSMutableArray(array: cities)
                let newCity:String = arrCellParameters[indexPath.row] as! String
                if selectedCities.contains(newCity) {
                    selectedCities.remove(newCity)
                }
                else {
                    selectedCities.add(newCity)
                }
                filterRule?.saveSelectedCities((selectedCities as? [Any])!)
                try? self.bidPeriod.managedObjectContext!.save()
                self.tableView.reloadData()
            }
        }
        else if popOverType == PopoverViewType.CommutabilityFirstCell {
            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            self.Commutabilitydelegate?.firstCellAction(indexPath.row + 1)
            self.dismissPopover(animated: true)
        }
        else if popOverType == PopoverViewType.CommutabilitySecondCell {
            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            self.Commutabilitydelegate?.secondCellAction(indexPath.row + 1)
            self.dismissPopover(animated: true)
        }
        else if popOverType == PopoverViewType.CommutabilityThirdCell {
            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            self.Commutabilitydelegate?.thirdCellAction(indexPath.row + 1)
            self.dismissPopover(animated: true)
        }
        else if popOverType == PopoverViewType.CommutabilityFourthCell {
            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            self.Commutabilitydelegate?.fourthCellAction(indexPath.row)
            self.dismissPopover(animated: true)
        }
        else if popOverType == PopoverViewType.CommutabilityFirstCell {
            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            self.CommutingManualDelegate?.valueBtnAction(indexPath.row)
            self.dismissPopover(animated: true)
        }
        else if popOverType == PopoverViewType.pdoBeforeorAfter {
            if let filterRule = filterRule,
               filterRule.category?.intValue == BIFilterRuleCategory.BIPDOFilterRuleCategory.rawValue {

                if let selected = arrCellParameters[indexPath.row] as? String {
                    
                    Delegate?.didSelected(itemName: selected)
                    dismissPopover(animated: true)
                    return
                }
            }
        }

        
        else if popOverType == PopoverViewType.pdoCities {
            if let filterRule = filterRule,
               filterRule.category?.intValue == BIFilterRuleCategory.BIPDOFilterRuleCategory.rawValue {

                if let city = arrCellParameters[indexPath.row] as? String {
                  
                    Delegate?.didSelected(itemName: city)
                    dismissPopover(animated: true)
                    return
                }
            }
        }

        else if popOverType == PopoverViewType.pdoValue {

            self.bidPeriod.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)

            guard let filterRule = filterRule,
                  filterRule.category?.intValue == BIFilterRuleCategory.BIPDOFilterRuleCategory.rawValue else {
                dismissPopover(animated: true)
                return
            }

            guard let selectedTime = arrCellParameters[indexPath.row] as? String else {
                dismissPopover(animated: true)
                return
            }

         
            Delegate?.didSelected(itemName: selectedTime)
            dismissPopover(animated: true)
            return
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters:String?
        if bidPeriod.isFABid() == true {
            
            allowedCharacters = "0123456789aAbBcCdD"
        }
        else {
            allowedCharacters = "0123456789"
        }
        return allowedCharacters!.contains(string) || range.length == 1
    }
}



