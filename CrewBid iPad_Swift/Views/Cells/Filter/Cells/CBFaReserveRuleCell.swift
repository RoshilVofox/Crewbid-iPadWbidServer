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
    
    var filterRule: BIFilterRule?
    var buttonTextColor: UIColor = .white
    var backViewColor: UIColor = .white


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setFilterRule(_ filterRule: BIFilterRule) {
        if self.filterRule !== filterRule {
            self.filterRule = filterRule
        }
        if let variables = filterRule.variables!["SET"] as? Set<Int> {
            SnrAMresButton.isSelected = variables.contains(BIFaReserveLineType.SnrAMres.rawValue)
            SnrPMresButton.isSelected = variables.contains(BIFaReserveLineType.SnrPMres.rawValue)
            JnrAMresButton.isSelected = variables.contains(BIFaReserveLineType.JnrAMres.rawValue)
            JnrPMresButton.isSelected = variables.contains(BIFaReserveLineType.JnrPMres.rawValue)
            JnrLateResButton.isSelected = variables.contains(BIFaReserveLineType.JnrLateRes.rawValue)
        }
    }

}
