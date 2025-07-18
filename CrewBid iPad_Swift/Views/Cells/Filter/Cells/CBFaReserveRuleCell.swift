//
//  CBFaReserveRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBFaReserveRuleCell: UITableViewCell {
    
    @IBOutlet weak var SnrAMresButton: CBBorderToggleButton!
    @IBOutlet weak var SnrPMresButton: CBBorderToggleButton!
    @IBOutlet weak var JnrAMresButton: CBBorderToggleButton!
    @IBOutlet weak var JnrPMresButton: CBBorderToggleButton!
    @IBOutlet weak var JnrLateResButton: CBBorderToggleButton!
    
    
    var buttonTextColor: UIColor = .white
    var backViewColor: UIColor = .white

    
    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func buttonAction(_ sender: CBBorderToggleButton) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        sender.isSelected = !sender.isSelected
        let SET = NSMutableSet()
        if SnrAMresButton.isSelected {
            SET.add(BIFaReserveLineType.SnrAMres.rawValue)
        }
        if SnrPMresButton.isSelected {
            SET.add(BIFaReserveLineType.SnrPMres.rawValue)
        }
        if JnrAMresButton.isSelected {
            SET.add(BIFaReserveLineType.JnrAMres.rawValue)
        }
        if JnrPMresButton.isSelected {
            SET.add(BIFaReserveLineType.JnrPMres.rawValue)
        }
        if JnrLateResButton.isSelected {
            SET.add(BIFaReserveLineType.JnrLateRes.rawValue)
        }
        // Always include this to keep the non-reserve lines from getting filtered out
        SET.add(BIFaReserveLineType.NoType.rawValue)
        let dict  = NSDictionary(object: SET, forKey: "SET" as NSCopying)
        filterRule.variables = dict
        try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    private var _filterRule: BIFilterRule?
    var filterRule: BIFilterRule {
        get {
            return _filterRule!
        }
        set(newvalue) {
            _filterRule = newvalue
            if self.filterRule != filterRule {
                //self.filterRule = filterRule
            }
            setTheme()
            if let variables = filterRule.variables!["SET"] as? Set<Int> {
                SnrAMresButton.isSelected = variables.contains(BIFaReserveLineType.SnrAMres.rawValue)
                SnrPMresButton.isSelected = variables.contains(BIFaReserveLineType.SnrPMres.rawValue)
                JnrAMresButton.isSelected = variables.contains(BIFaReserveLineType.JnrAMres.rawValue)
                JnrPMresButton.isSelected = variables.contains(BIFaReserveLineType.JnrPMres.rawValue)
                JnrLateResButton.isSelected = variables.contains(BIFaReserveLineType.JnrLateRes.rawValue)
            }
        }
    }
    
    private func setTheme() {
        
        SnrAMresButton.backgroundColor = backViewColor
        SnrPMresButton.backgroundColor = backViewColor
        JnrAMresButton.backgroundColor = backViewColor
        JnrPMresButton.backgroundColor = backViewColor
        JnrLateResButton.backgroundColor = backViewColor
        self.backgroundColor =  backViewColor// Fallback on earlier versions
        SnrAMresButton.textColor = buttonTextColor
        SnrPMresButton.textColor = buttonTextColor
        JnrAMresButton.textColor = buttonTextColor
        JnrPMresButton.textColor = buttonTextColor
        JnrLateResButton.textColor = buttonTextColor
    }

}
