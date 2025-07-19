//
//  CBComparisonRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBComparisonRuleCell: UITableViewCell, RefreshDelegate {
    
    @IBOutlet weak var comparisonButton: UIButton!
    @IBOutlet weak var valueButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deletButton: UIButton!
    
    var filterRule: BIFilterRule?
    var modeTexttColor: UIColor = .gray
    var bacViewColor: UIColor = .white
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func didSelected(itemName: String) {
        comparisonButton.setTitle(itemName, for: .normal)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
    }
    
    @IBAction func showValueOptions(_ sender: Any) {
        var menuItems = NSMutableArray(capacity: 16)
        let startString = filterRule?.variables![BIFilterRuleRangeStartVariablesKey]
        let startValue = (startString as! NSString).floatValue
        let endString = filterRule?.variables![BIFilterRuleRangeEndVariablesKey]
        let endValue = (endString as! NSString).floatValue
        var step: Float = 1
        if filterRule?.variables!["DECIMAL"] != nil {
            step = (filterRule?.variables!["STEP"] as! NSNumber).floatValue
            var numValues = Int((endValue - startValue) / step + 2)
            numValues = numValues - 1
            let numPlaces: Double = filterRule?.variables!["NUMPLACES"] as! Double
            menuItems = NSMutableArray(capacity: numValues)
            var currentValue = startValue
            for _ in 0..<numValues {
                if numPlaces == 2 {
                    menuItems.add(String(format: "%.2f", currentValue))
                }
                else {
                    menuItems.add(String(format: "%.2f", currentValue))
                }
                currentValue += step
            }
        }
        else {
            let numValues = Int((endValue - startValue) / step + 2)
            menuItems = NSMutableArray(capacity: numValues)
            var currentValue = startValue
            for _ in 0..<numValues {
                menuItems.add(String(format: "%.0f", currentValue))
                currentValue += step
            }
        }
        if BIFilterRuleCategory.BIGTavgFilterRuleCategory.rawValue == self.filterRule?.category?.intValue || BIFilterRuleCategory.BIGTmaxFilterRuleCategory.rawValue == self.filterRule?.category?.intValue {
            menuItems = ["01:00", "01:15", "01:30", "01:45", "02:00", "02:15", "02:30", "02:45", "03:00", "03:15", "03:30", "03:45", "04:00", "04:15", "04:30", "04:45", "05:00", "05:15", "05:30", "05:45", "06:00"]
        }
        
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshViewController.popOverType = PopoverViewType.valuesButton
        refreshViewController.selectedValue = (sender as! UIButton).currentTitle ?? ""
        refreshViewController.arrowDirection = .any
        refreshViewController.arrCellParameters = menuItems
        refreshViewController.filterRule = self.filterRule
        refreshViewController.modalPresentationStyle = .popover
        refreshViewController.Delegate = self
        refreshViewController.showPopover(sourceView: valueButton)
    }
    
    @IBAction func showComparisonOptions(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshViewController.popOverType = PopoverViewType.comparisonButton
        refreshViewController.arrCellParameters = ["At Most", "Exactly", "At Least"]
        refreshViewController.selectedValue = (sender as! UIButton).currentTitle ?? ""
        refreshViewController.filterRule = self.filterRule
        refreshViewController.modalPresentationStyle = .popover
        refreshViewController.Delegate = self
        refreshViewController.arrowDirection = .right
        refreshViewController.showPopover(sourceView: comparisonButton)
    }
    
    @IBAction func deleteCellRow(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod?.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        if filterRule?.ruleHighlightsTrips() == true {
            filterRule?.deHighlightTrips()
        }
        context!.delete(filterRule!)
        do {
            try context?.save()
        }
        catch {
            print("Error deleting object \(error.localizedDescription)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
        
    }
}
