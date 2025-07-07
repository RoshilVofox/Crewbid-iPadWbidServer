//
//  CBWeekdayRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBWeekdayRuleCell: UITableViewCell {

    @IBOutlet weak var sundayButton: CBBorderToggleButton!
    @IBOutlet weak var mondayButton: CBBorderToggleButton!
    @IBOutlet weak var tuesdayButton: CBBorderToggleButton!
    @IBOutlet weak var wednesdayButton: CBBorderToggleButton!
    @IBOutlet weak var thursdayButton: CBBorderToggleButton!
    @IBOutlet weak var fridayButton: CBBorderToggleButton!
    @IBOutlet weak var saturdayButton: CBBorderToggleButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func btnAction(_ sender: CBBorderToggleButton) {
    }
    
    private var _filterRule: BIFilterRule?
    var filterRule: BIFilterRule  {
        get {
            //code to execute
            return _filterRule!
        }
        set(newValue) {
            _filterRule = newValue
            if self.filterRule != filterRule {
                //self.filterRule = filterRule
            }

            let weekdayBits: Int = Int(truncating: self.filterRule.variables?["WEEKDAY_BITS"]! as! NSNumber)
            for wkday in 0..<7 {
                let bitSet: Int = weekdayBits & (1 << wkday)
                let select: Bool = bitSet == 0
                switch wkday {
                case 0:
                    sundayButton.isSelected = select
                case 1:
                    mondayButton.isSelected = select
                case 2:
                    tuesdayButton.isSelected = select
                case 3:
                    wednesdayButton.isSelected = select
                case 4:
                    thursdayButton.isSelected = select
                case 5:
                    fridayButton.isSelected = select
                case 6:
                    saturdayButton.isSelected = select
                    
                default:
                    break
                }
            }
            
        }
    }
}
