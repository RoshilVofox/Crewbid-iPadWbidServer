//
//  CBComparisonRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBComparisonRuleCell: UITableViewCell,CBFilterRuleCellDelegateAssignable {

    weak var delegate: CBFilterRuleCellDelegate?
    
    @IBOutlet weak var comparisonButton: UIButton!
    @IBOutlet weak var valueButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deletButton: UIButton!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func showValueOptions(_ sender: Any) {
    }
    
    @IBAction func showComparisonOptions(_ sender: Any) {
    }
    
    @IBAction func deleteCellRow(_ sender: Any) {
        delegate?.deleteCellRow(in: self)
        
    }
}
