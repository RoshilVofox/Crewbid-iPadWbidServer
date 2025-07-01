//
//  CBCommutingRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBCommutingRuleCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    var bidPeriod: BIBidPeriod?
    var filterRule: BIFilterRule?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func deleteCellRow(_ sender: Any) {
//        code need to be added
        filterRule?.managedObjectContext?.delete(filterRule!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
}
