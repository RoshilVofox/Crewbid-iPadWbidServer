//
//  CBTripLengthRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBTripLengthRuleCell: UITableViewCell {
    
    @IBOutlet weak var turnsButton: CBBorderToggleButton!
    @IBOutlet weak var fourDaysButton: CBBorderToggleButton!
    @IBOutlet weak var threeDaysButton: CBBorderToggleButton!
    @IBOutlet weak var twoDaysButton: CBBorderToggleButton!

    var bidPeriod: BIBidPeriod?
    
    override func layoutSubviews() {
        if bidPeriod?.isFABid() == true {
            fourDaysButton.isHidden = false
        }
        backgroundView?.backgroundColor = UIColor.black
        backgroundColor = UIColor.darkGray
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
        let variables = NSMutableDictionary(dictionary: filterRule.variables!)
        if turnsButton == sender {
            let TURNS_ON = sender.isSelected
            variables.setObject(TURNS_ON.intValue, forKey: "TURNS_ON" as NSCopying)
        } else if twoDaysButton == sender {
            let TWO_DAYS_ON = sender.isSelected
            variables.setObject(TWO_DAYS_ON.intValue, forKey: "TWO_DAYS_ON" as NSCopying)
        } else if threeDaysButton == sender {
            let THREE_DAYS_ON = sender.isSelected
            variables.setObject(THREE_DAYS_ON.intValue, forKey: "THREE_DAYS_ON" as NSCopying)
        } else if fourDaysButton == sender {
            let FOUR_DAYS_ON = sender.isSelected
            variables.setObject(FOUR_DAYS_ON.intValue, forKey: "FOUR_DAYS_ON" as NSCopying)
        }
        filterRule.variables = variables
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
        set(newValue) {
            _filterRule = newValue
            if self.filterRule != filterRule {
                //self.filterRule = filterRule
            }
            let variables : NSDictionary = filterRule.variables!
            let turnsOn = Bool(truncating: variables.object(forKey: "TURNS_ON") as! NSNumber)
            turnsButton.isSelected =  turnsOn
            let twoDaysOn = Bool(truncating: variables.object(forKey: "TWO_DAYS_ON") as! NSNumber)
            twoDaysButton.isSelected = twoDaysOn
            let threeDaysOn = Bool(truncating: variables.object(forKey: "THREE_DAYS_ON") as! NSNumber)
            threeDaysButton.isSelected = threeDaysOn
            let fourDaysOn = Bool(truncating: variables.object(forKey: "FOUR_DAYS_ON") as! NSNumber)
            fourDaysButton.isSelected = fourDaysOn
        }
    }
}


extension Bool {
    var intValue: Int {
        return self ? 1 : 0
    }
}
