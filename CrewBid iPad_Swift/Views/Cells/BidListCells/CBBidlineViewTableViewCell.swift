//
//  CBBidlineViewTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CBBidlineViewTableViewCell: UITableViewCell, UITextFieldDelegate,UICollectionViewDelegate, UICollectionViewDataSource,CBUserFlagTableControllerDelegate {


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
    
    weak var userFlagIconView: UIView?
    var bidPeriod = BIBidPeriod()
    var line = BILine()
    var calendarData: BICalendarData?
    var calendarDaysCount: NSMutableArray?
    var markerTextField = UITextField ()
    var markerView: UIView?
    var insertionView: UIView?
    var mainViewTopConstraint: NSLayoutConstraint?
    var mainTopViewOffset: Int = 0
    var insertionViewTopConstraint: NSLayoutConstraint?
    var insertionViewHeightConstraint: NSLayoutConstraint?
    var markerViewTopConstraint: NSLayoutConstraint?
    var markerViewHeightConstraint: NSLayoutConstraint?
    var markerTextFieldHeightConstraint: NSLayoutConstraint?
    var markerTextFieldBaselineConstraint: NSLayoutConstraint?
    var bidListCellCalendarDaysArr = [Any]()
    var calendarTripDayTypes: NSMutableArray?
    var calendarTripDayColors: NSMutableArray?
    weak var tapGesture: UITapGestureRecognizer?
    
    private var kSelectionButtonTag: Int = 80
    private var kSnowflakeTag: Int = 1040
    private var kLineValuesHorizOffset: Int = 0
    private var kLineValuesVertOffset: Int = 15
    private var kLineValuesHorizSpacing = Int(50.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        markerTextField.delegate = self
        self.calendarCollectionView.layer.cornerRadius = 3
        self.calendarCollectionView.layer.borderWidth = 0.5
        self.calendarCollectionView.layer.borderColor = UIColor.lightGray.cgColor
        
        positionCircleView.layer.cornerRadius = positionCircleView.frame.size.width / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bidListCellCalendarDaysArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        <#code#>
    }
    
    func changeLineUserFlagTypeTo(flagType: CBUserFlagType, selectedLine: BILine?) {
        <#code#>
    }
    
    
}
