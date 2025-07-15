//
//  CBWorkBlockRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBWorkBlockRuleCell: UITableViewCell, RefreshDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueButton: UIButton!
    @IBOutlet weak var comparisonButton: UIButton!
    @IBOutlet weak var ruleTypeButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    var filterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod?
    var bacViewColor: UIColor = .white
    var modeTexttColor: UIColor = .gray
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext!
    
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
        NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: nil)
    }
    
    func didSetDays(itemName: String) {
        ruleTypeButton.setTitle(itemName, for: .normal)
        NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: nil)
    }

    @IBAction func showRuleTypeOptions(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshVC = storyBoard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshVC.popOverType = PopoverViewType.RuleValue
        refreshVC.selectedValue = (sender as! UIButton).currentTitle ?? ""
        refreshVC.arrCellParameters = ["1 Day", "2 Days", "3 Day", "4 Day"]
        refreshVC.arrowDirection = .right
        refreshVC.filterRule = self.filterRule
        refreshVC.modalPresentationStyle = .popover
        refreshVC.Delegate = self
        refreshVC.showPopover(sourceView: ruleTypeButton)
    }
    
    @IBAction func showComparisonOptions(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshVC = storyBoard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshVC.popOverType = PopoverViewType.comparisonButton
        refreshVC.selectedValue = (sender as! UIButton).currentTitle ?? ""
        refreshVC.arrCellParameters = ["At Most", "Exactly", "At Least"]
        refreshVC.arrowDirection = .right
        refreshVC.filterRule = self.filterRule
        refreshVC.modalPresentationStyle = .popover
        refreshVC.Delegate = self
        refreshVC.showPopover(sourceView: comparisonButton)
        
    }
    
    @IBAction func showValueOptions(_ sender: Any) {
        var menuItems = NSMutableArray(capacity: 16)
        let startString = filterRule?.variables![BIFilterRuleRangeStartVariablesKey]
        let startValue = (startString as! NSString).floatValue
        let endString = filterRule?.variables![BIFilterRuleRangeEndVariablesKey]
        let endValue = (endString as! NSString).floatValue
        var step: Float = 1
        if (filterRule?.variables!["DECIMAL"] != nil) {
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
                    menuItems.add(String(format: "%.1f", currentValue))
                }
                currentValue += step
            }
        }
        else {
            let numValues = Int((endValue - startValue) / step + 2)
            menuItems = NSMutableArray(capacity: numValues)
            var currentValue = startValue
            for _ in 0..<numValues {
                menuItems.add(String(format:"%.0f",currentValue))
                currentValue += step
            }
        }
        
        let storyBoard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshVC = storyBoard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshVC.popOverType = PopoverViewType.valuesButton
        refreshVC.selectedValue = (sender as! UIButton).currentTitle ?? ""
        refreshVC.arrowDirection = .any
        refreshVC.arrCellParameters = menuItems
        refreshVC.filterRule = self.filterRule
        refreshVC.modalPresentationStyle = .popover
        refreshVC.Delegate = self
        refreshVC.showPopover(sourceView: valueButton)
    }
    
    @IBAction func deleteCellAction(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        if (filterRule?.ruleHighlightsTrips())! {
            filterRule?.deHighlightTrips()
        }
        self.bidPeriod!.managedObjectContext!.delete(filterRule!)
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
