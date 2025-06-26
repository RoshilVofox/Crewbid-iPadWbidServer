//
//  CBLineTypeRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBLineTypeRuleCell: UITableViewCell {

    @IBOutlet weak var hardLinesButton: CBBorderToggleButton!
    @IBOutlet weak var mixedLinesButton: CBBorderToggleButton!
    @IBOutlet weak var conusButton: CBBorderToggleButton!
    @IBOutlet weak var nonConusButton: CBBorderToggleButton!
    @IBOutlet weak var reserveLinesButton: CBBorderToggleButton!
    @IBOutlet weak var blankLinesButton: CBBorderToggleButton!
    @IBOutlet weak var etopsButton: CBBorderToggleButton!
    @IBOutlet weak var etopsResButton: CBBorderToggleButton!
    
    weak var etopsfilterRule: BIFilterRule?
    weak var etopsResfilterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod!
    var isETOPSON : Bool = false
    var isETOPSRESON : Bool = false
    var buttonTextColor: UIColor = .white
    var backViewColor: UIColor = .white
    var filterRule: BIFilterRule? {
        didSet {
            etopsButton.isSelected = false
            etopsResButton.isSelected = false
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
