//
//  CBReportReleaseRuleCellTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBReportReleaseRuleCellTableViewCell: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var txtReport: UITextField!
    @IBOutlet weak var txtRelease: UITextField!
    @IBOutlet weak var btnCalculate: CBBorderToggleButton!
    @IBOutlet weak var btnChooseDate: CBBorderToggleButton!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var viewAllDays: UIView!
    @IBOutlet weak var viewTripOrWorkDays: UIView!
    @IBOutlet weak var viewDates: UIView!
    @IBOutlet weak var allDaysCheckButton: UIButton!
    
    @IBOutlet weak var tripWorkBlkButton: UIButton!
    @IBOutlet weak var tripFirstButton: UIButton!
    @IBOutlet weak var tripLastButton: UIButton!
    @IBOutlet weak var noMidButton: UIButton!
    
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
