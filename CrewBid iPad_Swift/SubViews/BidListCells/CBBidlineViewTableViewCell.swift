//
//  CBBidlineViewTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CBBidlineViewTableViewCell: UITableViewCell {

    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var reserveLabel: UILabel!
    @IBOutlet weak var positionCircleView: UIView!
    @IBOutlet weak var mLblLineNumber: UILabel!
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var userFlagControl: UIControl!
    @IBOutlet weak var lineValuesView: UIView!
    @IBOutlet weak var scrollLineValue: UIScrollView!
    @IBOutlet weak var mLblSlNo: UILabel!
    @IBOutlet weak var lblInsertLineHere: UILabel!
    @IBOutlet weak var imgAccessoryView: UIImageView!
    @IBOutlet weak var selectionToggleButton: CBToggleButton!
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
