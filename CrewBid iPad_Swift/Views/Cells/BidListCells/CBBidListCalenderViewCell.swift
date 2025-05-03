//
//  CBBidListCalenderViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CBBidListCalenderViewCell: UITableViewCell {
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var lineValuesContainerView: UIView!
    
    @IBOutlet weak var cellNoLabel: UILabel!
    @IBOutlet weak var userFlagControl: UIControl!
    @IBOutlet weak var positionCircleView: UIView!
    @IBOutlet weak var lineLabel: UILabel!
    @IBOutlet weak var etopsTypeLabel: UILabel!
    @IBOutlet weak var lblInsertLineHere: UILabel!
    @IBOutlet weak var txtMarker: UITextField!
    @IBOutlet weak var imgAccessoryView: UIImageView!
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var selectionToggleButton: CBToggleButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
