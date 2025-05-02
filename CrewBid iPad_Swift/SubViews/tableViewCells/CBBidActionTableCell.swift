//
//  CBBidActionTableCell.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 21/04/25.
//

import UIKit

class CBBidActionTableCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imgv: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
