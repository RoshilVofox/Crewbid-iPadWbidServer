//
//  CBCommutabilitySortCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBCommutabilitySortCell: UITableViewCell {
    
    var lineSort1: BILineSort!
    
    
    var lineSort: BILineSort? {
        set(newLineSort){
           lineSort1 = newLineSort
        }
        get {
            return lineSort1
        }
    }

    @IBOutlet weak var btnTitle: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configurecommutabilitySortCell() {
        
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        NotificationCenter.default.post(
            name: Notification.Name("DeleteCellNotification"),
            object: self // Pass the cell itself as the object
        )
    }
}
