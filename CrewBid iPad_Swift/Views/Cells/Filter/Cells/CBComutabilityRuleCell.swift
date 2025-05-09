//
//  CBComutabilityRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBComutabilityRuleCell: UITableViewCell,CBFilterRuleCellDelegateAssignable {
    weak var delegate: CBFilterRuleCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func deleteCellRow(_ sender: Any) {
        delegate?.deleteCellRow(in: self)
    }
}
