//
//  CBLineSortCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBLineSortCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var LHsegment: UISegmentedControl!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cityNametxt: UITextField!
    
    var bidPeriod: BIBidPeriod?
    private var lineSort1: BILineSort!
    var swapImgView: UIImageView!
    var lineSort: BILineSort? {
        set(newLineSort){
           lineSort1 = newLineSort
            if let nameLabel = nameLabel {
                nameLabel.text = newLineSort?.name
            }
            if let LHsegment = self.LHsegment {
                LHsegment.selectedSegmentIndex = ((newLineSort?.ascending?.boolValue) ?? false) ? 0 : 1
                LHsegment.isHidden = !(newLineSort?.isMutable!.boolValue)!
            }
        }
        get {
            return lineSort1
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        swapImgView = UIImageView(frame: CGRect(x: self.contentView.frame.width - 310, y: (self.contentView.frame.height/2) - 15, width: 30, height: 30))
        swapImgView.isHidden = true
        self.addSubview(swapImgView)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        NotificationCenter.default.post(
            name: Notification.Name("DeleteCellNotification"),
            object: self // Pass the cell itself as the object
        )
    }
}
