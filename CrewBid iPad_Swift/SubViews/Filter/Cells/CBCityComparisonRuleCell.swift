//
//  CBCityComparisonRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBCityComparisonRuleCell: UITableViewCell,CBFilterRuleCellDelegateAssignable {
    weak var delegate: CBFilterRuleCellDelegate?
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueButton: UIButton!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var comparisonButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func deleteCellAction(_ sender: Any) {
        delegate?.deleteCellRow(in: self)
    }
}
