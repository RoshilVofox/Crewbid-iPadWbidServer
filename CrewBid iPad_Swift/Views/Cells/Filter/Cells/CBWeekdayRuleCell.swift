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
}
