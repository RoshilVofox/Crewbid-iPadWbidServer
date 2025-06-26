//
//  CBPositionRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBPositionRuleCell: UITableViewCell {

    @IBOutlet weak var positionAButton: CBBorderToggleButton!
    @IBOutlet weak var positionBButton: CBBorderToggleButton!
    @IBOutlet weak var positionCButton: CBBorderToggleButton!
    @IBOutlet weak var positionDButton: CBBorderToggleButton!
    @IBOutlet weak var positionMButton: CBBorderToggleButton!
    
    var bidPeriod: BIBidPeriod?
    var buttonTextColor: UIColor = .white
    
    var filterRule: BIFilterRule? {
        didSet {
            guard let filterRule = filterRule else { return }

            if let variables = filterRule.variables!["SET"] as? Set<Int> {
                positionAButton.isSelected = variables.contains(BIFaPosition.FaPositionA.rawValue)
                positionBButton.isSelected = variables.contains(BIFaPosition.FaPositionB.rawValue)
                positionCButton.isSelected = variables.contains(BIFaPosition.FaPositionC.rawValue)
                positionDButton.isSelected = variables.contains(BIFaPosition.FaPositionD.rawValue)
                positionMButton.isSelected = variables.contains(BIFaPosition.FaPositionMultiple.rawValue)
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
