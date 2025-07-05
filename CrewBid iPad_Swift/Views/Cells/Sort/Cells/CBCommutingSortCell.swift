//
//  CBCommutingSortCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBCommutingSortCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    var lineSort: BILineSort!
    var bidPeriod: BIBidPeriod!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func CalculateCommutingManualSort() {
        
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        NotificationCenter.default.post(
            name: Notification.Name("DeleteCellNotification"),
            object: self // Pass the cell itself as the object
        )
    }
}
