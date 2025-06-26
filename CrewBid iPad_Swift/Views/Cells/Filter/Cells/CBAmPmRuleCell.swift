//
//  CBAmPmRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBAmPmRuleCell: UITableViewCell {
    
    @IBOutlet weak var amLinesButton: CBBorderToggleButton!
    @IBOutlet weak var pmLinesButton: CBBorderToggleButton!
    @IBOutlet weak var mixedAmPmLinesButton: CBBorderToggleButton!
    @IBOutlet weak var redEyeLinesButton: CBBorderToggleButton!
    var buttonTextColor: UIColor = .white
    var bidPeriod: BIBidPeriod?
    
    var filterRule: BIFilterRule? {
        didSet {
            guard let filterRule = filterRule else { return }
            

            if let variables = filterRule.variables!["SET"] as? Set<NSNumber> {
                amLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.AMLine.rawValue))
                pmLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.PMLine.rawValue))
                mixedAmPmLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.MixedAMPMLine.rawValue))
                redEyeLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.RedEyeAMPMLine.rawValue))
            } else {
                // Reset buttons if variables is nil
                amLinesButton.isSelected = false
                pmLinesButton.isSelected = false
                mixedAmPmLinesButton.isSelected = false
                redEyeLinesButton.isSelected = false
            }
        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
