//
//  CBExpandedBidLinesTableControllerCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CBExpandedBidLinesTableControllerCell: UITableViewCell {

    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var userFlagControl: UIControl!
    @IBOutlet weak var positionCircleView: UIView!
    @IBOutlet weak var mLblLineNo: UILabel!
    @IBOutlet weak var mLblSlNo: UILabel!
    @IBOutlet weak var collectionView: CBLineCalendarCollectionView!
    @IBOutlet weak var collectionViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var lineValuesContainerView: UIView!
    @IBOutlet weak var imgAccessoryView: UIImageView!
    @IBOutlet weak var txtMarker: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
