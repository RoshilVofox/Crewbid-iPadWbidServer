//
//  CBWorkBlockRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBWorkBlockRuleCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueButton: UIButton!
    @IBOutlet weak var comparisonButton: UIButton!
    @IBOutlet weak var ruleTypeButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    var filterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod?
    var bacViewColor: UIColor = .white
    var modeTexttColor: UIColor = .gray
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func deleteCellAction(_ sender: Any) {
        NotificationCenter.default.post(
                name: Notification.Name("DeleteCellNotification"),
                object: self // Pass the cell itself as the object
            )
    }
}
