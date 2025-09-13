//
//  CBExpandedBidLinesTableControllerCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CBExpandedBidLinesTableControllerCell: UITableViewCell, CBUserFlagTableControllerDelegate  {


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
    
    var bidListCellCalendarDaysArr = [Any]()
    private var kSelectionButtonTag: Int = 80
    private var kSnowflakeTag: Int = 1040
    

    var app: AppDelegate?
    var calendarData = BICalendarData()
    var line: BILine?
    var tripButtons: NSMutableArray?
    var vacationButtons: NSMutableArray?
    var fvVacationButtons: NSMutableArray?
    var cfvVacationButtons: NSMutableArray?
    var tripButtonsArray = NSMutableArray()
    var vacayGestureRecognizers = NSMutableArray()
    var userFlagIconView: UIView = UIView()
    var posAView: UIView = UIView()
    var posBView: UIView = UIView()
    var posCView: UIView = UIView()
    var posDView: UIView = UIView()
    var posAGrayView: UIView = UIView()
    var posBGrayView: UIView = UIView()
    var posCGrayView: UIView = UIView()
    var posDGrayView: UIView = UIView()
    var posNAView: UIView = UIView()
    var posMView: UIView = UIView()
    var tripButtonActionBlock: CBLineCellTripButtonActionBlock?
    var daysArray:[String] = []
    var numDays = 0
    var numDays1 = 0
    private var kLineNumberViewTag: Int = 10
    private var kLineNumberVertOrigin: Int = 73
    private var kCircleSize: Int = 20 //25
    private var kCircleHorizontalOffset: Int = 30 //28
    private var kCircleVerticalOffset: Int = 110 //90
    private var kCircleVerticalIncrement: Int = 30 //30
    private var kPosAViewTag: Int = 500
    private var kPosBViewTag: Int = 510
    private var kPosCViewTag: Int = 520
    private var kPosDViewTag: Int = 530
    private var kPosAGrayViewTag: Int = 600
    private var kPosBGrayViewTag: Int = 610
    private var kPosCGrayViewTag: Int = 620
    private var kPosDGrayViewTag: Int = 630
    let kCBButtonTag = 800
    var view: UIView!
    var arrayLinesDetails:NSArray = NSArray()
    var bidPeriod : BIBidPeriod?
    private var kLineValuesHorizOffset: Int = 0
    private var kLineValuesVertOffset: Int = 6
    private var kLineValuesHorizSpacing = Int(170.0)
    var markerTextField : String = ""
    var cellHeight : CGFloat = 35
    var cellWidth: CGFloat = 0.0
    var interItemSpacing: CGFloat = 0.5
    
    var cellType = CBBidLineTableCellType(rawValue: 0)
    var isUserFlagMenuPresented = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layoutIfNeeded()
        setupUI()
        userFlagControl.addTarget(self, action: #selector(showUserFlagMenu), for: .touchUpInside)
        let flagDiameter: CGFloat = 25
        let flagImage: UIImageView = UIImageView(image: UIImage(named: "flag1"))
        flagImage.frame = CGRect(x: 0.0, y: 0.0, width: flagDiameter, height: flagDiameter)
        // Center the flag in the view
        var frame: CGRect? = flagImage.frame
        frame?.origin.x = 2.5
        frame?.origin.y = 2.5
        flagImage.frame = frame!
        flagImage.tag = 112
        userFlagControl.addSubview(flagImage)
        userFlagControl.makeCornorRound()
    }
    
    func setupUI() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        //if (line?.isFrozen == 0) {
        //imgAccessoryView.isHidden = true
        //}
        positionCircleView.layer.cornerRadius = positionCircleView.frame.size.height/2.0
            //Line values
        //let tag: Int = 100
        var newFrame = CGRect ()
        for i in 0..<5 {
            var lineValueView = CBLineValueView(frame: CGRect.zero)
            lineValueView = lineValueView.initWithFrame(aRect: CGRect.zero)
            newFrame = CGRect(x: CGFloat(kLineValuesHorizOffset + i * kLineValuesHorizSpacing), y:CGFloat(kLineValuesVertOffset), width: 55.0, height: 28.0)
            lineValueView.frame = newFrame
            lineValueView.tag = LineValueViewTag + i * 10
            lineValuesContainerView.addSubview(lineValueView)
        }
            // linevalues gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self , action: #selector(self.longPressLineValueContainerView))
        longPressGesture.minimumPressDuration = 0.3
        lineValuesContainerView.addGestureRecognizer(longPressGesture)
        longPressGesture.delegate = self
        longPressGesture.delaysTouchesBegan = true
    }
    
    func setMarkerText(_ text: String?) {
        txtMarker.text = text
    }
    
    // This function handles the visibility of txtMarker based on a cell type condition.

    func handleMarkerCondition() {
        let placeholderText = "Untitled Marker."
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        txtMarker.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        txtMarker.backgroundColor = .darkGray
        if CBBidLineTableCellType.cbMarkerBidLineTableCellType == self.cellType {
            self.txtMarker.isHidden = false
        } else {
            self.txtMarker.isHidden = true
        }
    }
    @objc func longPressLineValueContainerView(_ gesture: UILongPressGestureRecognizer) {
        // Check if the gesture state is not ended.

        if gesture.state != .ended {
            return
        }
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBLineValuesMenuController") as! CBLineValuesMenuController
        lineValuesController.bidPeriod = bidPeriod
        lineValuesController.modalPresentationStyle = .popover
        lineValuesController.showPopover(sourceView: self.lineValuesContainerView, sourceRect: self.collectionView.frame)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if line != nil {
//            collectionViewRightConstraint.constant = (line?.isFrozen == true) ? 52.0 : 10.0
            cellWidth = collectionView.frame.size.width / CGFloat(bidListCellCalendarDaysArr.count)
            cellWidth = cellWidth - interItemSpacing
//            refreshTripButtons(highlightFlag: true)
            collectionView.reloadData()
        }
//        self.layoutIfNeeded()
//        collectionView.reloadData()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @objc func showUserFlagMenu() {
        guard !isUserFlagMenuPresented else {
               return // Exit if already presented
           }
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let flagVC = storyboard.instantiateViewController(withIdentifier: "CBUserFlagTableController") as! CBUserFlagTableController
        flagVC.delegate = self
        flagVC.modalPresentationStyle = .popover
        flagVC.line = line
        flagVC.popoverPresentationController?.delegate = self
        isUserFlagMenuPresented = true
        flagVC.showPopover(sourceView: userFlagControl)
    }
    
    func changeLineUserFlagTypeTo(flagType: CBUserFlagType, selectedLine: BILine?) {
        if selectedLine != nil {
            selectedLine!.userFlagType = flagType.rawValue as NSNumber
        }
        var sortRule = (CBGlobalMethods.shared.selectedBidPeriod!.lineSorts!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 10")) as! [BILineSort]
        sortRule = (sortRule as NSArray).sortedArray(using: [NSSortDescriptor.init(key: "category", ascending: true), NSSortDescriptor.init(key: "type", ascending: true)] as [NSSortDescriptor]) as! [BILineSort]
        
        if sortRule.count > 0 {
            
            let arrayVariables = sortRule.first?.arrayVariables as! [NSNumber]
            var userFlags = [Int]()
            var userFlagColors = [UIColor]()
            
            for variable in arrayVariables {
                switch variable.intValue {
                case 0:
                    userFlags.append(CBUserFlagType.none.rawValue)
                    userFlagColors.append(.clear)
                    break
                case 1:
                    userFlags.append(CBUserFlagType.blue.rawValue)
                    userFlagColors.append(CBColor.faPosAColor)
                    break
                case 2:
                    userFlags.append(CBUserFlagType.green.rawValue)
                    userFlagColors.append(CBColor.faPosBColor)
                    break
                case 3:
                    userFlags.append(CBUserFlagType.red.rawValue)
                    userFlagColors.append(CBColor.faPosDColor)
                    break
                case 4:
                    userFlags.append(CBUserFlagType.yellow.rawValue)
                    userFlagColors.append(CBColor.faPosCColor)
                    break
                case 5:
                    userFlags.append(CBUserFlagType.orange.rawValue)
                    userFlagColors.append(.orange)
                    break
                case 6:
                    userFlags.append(CBUserFlagType.brown.rawValue)
                    userFlagColors.append(CBColor.oldbrownColor)
                    break
                case 7:
                    userFlags.append(CBUserFlagType.pink.rawValue)
                    userFlagColors.append(UIColor.systemPink.withAlphaComponent(0.8))
                    break
                default:
                    break
                }
            }
            reSetFlagOrder(userFlags: userFlags)
        }
        else {
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    func reSetFlagOrder(userFlags: [Int]) {
        var arrIndexValue: Int
        let lines = CBGlobalMethods.shared.selectedBidPeriod!.lines!.allObjects as! [BILine]
        for line in lines {
            line.flagOrder = NSNumber(integerLiteral: 8)
        }
        for i: Int in 0..<userFlags.count {
            arrIndexValue = userFlags[i]
            let notBlankPredicate = NSPredicate(format: "userFlagType == %d", arrIndexValue)
            let sortedLines = CBGlobalMethods.shared.selectedBidPeriod!.lines!.allObjects.filter { notBlankPredicate.evaluate(with: $0) } as! [BILine]
            for line in sortedLines {
                line.flagOrder = NSNumber(integerLiteral: i)
            }
        }
        do {
            try self.bidPeriod?.managedObjectContext!.save()
        } catch {
            print(error)
        }
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    // This function handles various conditions related to freezing a line.

    func handlingFreezingCondition(line: BILine? = nil)  {
        imgAccessoryView.isHidden = false
        if (line?.isFrozen != 0) {
            let snowflakeImage = UIImage(named: "Blue_Snowflake")
            imgAccessoryView?.image = snowflakeImage
            mLblLineNo.textColor = UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0)
            if line!.isETOPS?.boolValue == true{
                let attributedString = NSMutableAttributedString(string: mLblLineNo.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNo.text!.count - 1, 1)
                if line?.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNo.attributedText = attributedString
            }
            // Check if 'isETOPSRES' is true and modify the text color accordingly.

            if line!.isETOPSRES?.boolValue == true{
                let attributedString = NSMutableAttributedString(string: mLblLineNo.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNo.text!.count - 2, 2)
                if line?.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNo.attributedText = attributedString
            }
            else if bidPeriod!.isFABid() && bidPeriod!.isSecondRoundBid() {
                if line!.faReserveLineType == (BIFaReserveLineType.SnrAMres.rawValue) as NSNumber || line!.faReserveLineType == (BIFaReserveLineType.SnrPMres.rawValue) as NSNumber || line!.faReserveLineType == (BIFaReserveLineType.JnrAMres.rawValue) as NSNumber || line!.faReserveLineType == (BIFaReserveLineType.JnrPMres.rawValue) as NSNumber || line!.faReserveLineType == (BIFaReserveLineType.JnrLateRes.rawValue) as NSNumber{
                    let attributedString = NSMutableAttributedString(string: mLblLineNo.text!)
                    let lastCharacterRange = NSMakeRange( mLblLineNo.text!.count - 2, 2)
                    if line?.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                    } else {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                    }
                    mLblLineNo.attributedText = attributedString
                }
            }
            
           else if line!.type == BILineType.ReserveLine.rawValue.asNSNumber || line!.type == BILineType.NonEtopsReserve.rawValue.asNSNumber{
                let attributedString = NSMutableAttributedString(string: mLblLineNo.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNo.text!.count - 1, 1)
                if line?.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNo.attributedText = attributedString
            }
            if !bidPeriod!.isFABid() && bidPeriod!.isSecondRoundBid() && (line!.type == BILineType.MixedLine.rawValue.asNSNumber || line!.type == BILineType.NonEtopsMixed.rawValue.asNSNumber) {
                let attributedString = NSMutableAttributedString(string: mLblLineNo.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNo.text!.count - 2, 2)
                if line?.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNo.attributedText = attributedString
            }
            // Hide a button with a specific tag.

            let button = viewWithTag(kSelectionButtonTag) as? UIButton
            button?.isHidden = true
            self.isEditing = false
        } else {
            // Set a different image and configure the label and button based on conditions.

            let snowflakeImage = UIImage(named: "Blue_SnowflakeEmpty")
            imgAccessoryView?.image = snowflakeImage
            imgAccessoryView.isHidden = true
            let button = viewWithTag(kSelectionButtonTag) as? UIButton
            // Check conditions and modify the label text color.

            if bidPeriod!.isFABid() && line!.faPosition?.intValue != BIFaPosition.FaPositionNA.rawValue {
                mLblLineNo.textColor = UIColor.white
                
            }
            else {
                positionCircleView.backgroundColor = .systemBackground
                mLblLineNo.textColor = UIColor.label
            }
            // Check if 'isETOPS' is true and modify the text color accordingly.

                if line!.isETOPS?.boolValue == true{
                    let attributedString = NSMutableAttributedString(string: mLblLineNo.text!)
                    let lastCharacterRange = NSMakeRange( mLblLineNo.text!.count - 1, 1)
                    if line?.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                    } else {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                    }
                    mLblLineNo.attributedText = attributedString
                }
            // Check if 'isETOPSRES' is true and modify the text color accordingly.

                if line!.isETOPSRES?.boolValue == true{
                    let attributedString = NSMutableAttributedString(string: mLblLineNo.text!)
                    let lastCharacterRange = NSMakeRange( mLblLineNo.text!.count - 2, 2)
                    if line?.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                    } else {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                    }
                    mLblLineNo.attributedText = attributedString
                }
            
            else if bidPeriod!.isFABid() && bidPeriod!.isSecondRoundBid() {
                if line!.faReserveLineType == (BIFaReserveLineType.SnrAMres.rawValue) as NSNumber || line!.faReserveLineType == (BIFaReserveLineType.SnrPMres.rawValue) as NSNumber || line!.faReserveLineType == (BIFaReserveLineType.JnrAMres.rawValue) as NSNumber || line!.faReserveLineType == (BIFaReserveLineType.JnrPMres.rawValue) as NSNumber || line!.faReserveLineType == (BIFaReserveLineType.JnrLateRes.rawValue) as NSNumber{
                    let attributedString = NSMutableAttributedString(string: mLblLineNo.text!)
                    let lastCharacterRange = NSMakeRange( mLblLineNo.text!.count - 2, 2)
                    if line?.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                    } else {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                    }
                    mLblLineNo.attributedText = attributedString
                }
            }
            
            // Show the button.
            else if line!.type == BILineType.ReserveLine.rawValue.asNSNumber || line!.type == BILineType.NonEtopsReserve.rawValue.asNSNumber{
                let attributedString = NSMutableAttributedString(string: mLblLineNo.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNo.text!.count - 1, 1)
                if line?.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNo.attributedText = attributedString
            }
            if !bidPeriod!.isFABid() && bidPeriod!.isSecondRoundBid() && (line!.type == BILineType.MixedLine.rawValue.asNSNumber || line!.type == BILineType.NonEtopsMixed.rawValue.asNSNumber) {
                let attributedString = NSMutableAttributedString(string: mLblLineNo.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNo.text!.count - 2, 2)
                if line?.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNo.attributedText = attributedString
            }

            button?.isHidden = false
            self.isEditing = true
        }
    }
    
    
    func refreshTripButtons(highlightFlag:Bool) {
        if nil == tripButtons {
            tripButtons = NSMutableArray()
        }
        
        let count: Int = (tripButtons?.count)!
        for i in 0..<count {
            let tripButton = tripButtons?[i] as? UIButton
            if tripButton != nil {
                tripButton?.removeFromSuperview()
            }
        }
        
        tripButtonsArray.removeAllObjects()
        tripButtons?.removeAllObjects()
        
        tripButtons?.addObjects(from: bidListCellCalendarDaysArr)
        let userDefaults = UserDefaults.standard
        // Get size and insets of calendar items (cells).
        let inset: CGFloat = cellHeight / 2
        let insets: UIEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        
        var buttonFrame = CGRect(x: 0.0, y: 0.0, width: cellWidth , height: cellHeight)
        var buttonImage: UIImage? = nil
        var button = CBTripButton()
        
        let daysInCalendar: Int = bidListCellCalendarDaysArr.count
        let trips = line?.trips
        
        for item in trips! {
            let trip = item as! BITrip
            // Check if the trip should be highlighted based on the highlightFlag and its type.
            
            let highlighted: Bool = trip.highlightCount!.intValue > 0 && highlightFlag
            
            // Calculate the index for the trip within the calendar.
            
            let index: Int = calendarData.indexForDate(date: trip.startDate! as Date) - calendarData.indexOfFirstDayExpandedView()
            // Skip trips that fall outside the calendar range.
            
            if index > (daysInCalendar - 1) || index < 0 {
                continue
            }
            // Calculate button length and initialize buttonImage based on trip type.
            
            let tripLength: Int = trip.info!.calendarDaysCount as! Int
            let buttonLength: Int = 0
            let otherButton:CBTripButton? = nil
            if trip.isRedEyeTrip {
                buttonImage = UIImage.imageWithColor(.red)
            }else if (bidPeriod?.isFABid())! && trip.isReserve {
                if BIFaReserveLineType.SnrAMres.rawValue == line?.faReserveLineType?.intValue {
                    buttonImage = UIImage.imageWithColor(CBColor.cbGreenColor)
                }else if BIFaReserveLineType.SnrPMres.rawValue == line?.faReserveLineType?.intValue {
                    buttonImage = UIImage.imageWithColor(CBColor.tripButtonredColor)
                }else if BIFaReserveLineType.JnrAMres.rawValue == line?.faReserveLineType?.intValue {
                    buttonImage = UIImage.imageWithColor(CBColor.lightGreenColor)
                }else if BIFaReserveLineType.JnrPMres.rawValue == line?.faReserveLineType?.intValue {
                    buttonImage = UIImage.imageWithColor(CBColor.lightTripButtonRedColor)
                }else{
                    buttonImage = UIImage.imageWithColor(CBColor.cbBrownColor)
                }
            } else {
                if trip.isAM(){
                    if trip.isReserve {
                        buttonImage = UIImage(named: "GreenRect")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }else {
                        buttonImage = UIImage(named: "OrangeRect")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }
                }else{
                    if trip.isReserve {
                        buttonImage = UIImage(named: "RedRect")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }else {
                        buttonImage = UIImage(named: "PurpleRect")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }
                }            }
            // Set button frame and create a CBTripButton.
            
            let buttonWidth = CGFloat(tripLength) * cellWidth
            buttonFrame.size.width = buttonWidth - interItemSpacing
            
            button = CBTripButton(frame: buttonFrame)
            button.tag = kCBButtonTag
            button.setBackgroundImage(buttonImage, for: .normal)
            button.trip = trip
            // Add a border and long-press gesture for highlighted trips.
            
            if highlighted {
                let roundedBorder = CALayer()
                roundedBorder.borderColor = CBColor.tripHighlightColor.cgColor
                roundedBorder.borderWidth = 2.0
                roundedBorder.frame = CGRect(x: -1, y: -2, width: button.frame.width + 2, height: button.frame.height + 2)
                button.layer.addSublayer(roundedBorder)
                // Add a long-press for a failsafe
                // Add a long-press gesture for resetting highlights.
                
                //                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.resetHighlights))
                //                longPressGesture.minimumPressDuration = 3.0
                //                button.addGestureRecognizer(longPressGesture)
                //                longPressGesture.delegate = self
            }
            //            button.addTarget(self, action: #selector(self.tripButtonAction), for: .touchUpInside)
            // Replace the button at the corresponding index in tripButtons.
            
            tripButtons?.replaceObject(at: index, with: button)
            tripButtonsArray.add(button)
            // Add the button to the collectionView.
            
            collectionView.addSubview(button)
            let orderedDays = trip.orderedDays
            let daysCount: Int = orderedDays.count
            var labelButton: CBTripButton = button
            // Loop through ordered days of the trip and add labels.
            var missingDateIndex = -1
            var missingRedEyeDate: Date? = nil
            var isDateMissingInPreviousDay = false
            
            if trip.isRedEyeTrip{
                missingDateIndex = CBUtils.findMissingIndex(inRedEyeTrip: trip)
                missingRedEyeDate = CBUtils.findMissingDate(forRedEyeTrip: trip)
                isDateMissingInPreviousDay = CBUtils.isDateMissingInPreviousDay(trip)
            }
            var showingRedEyeIconForThisDay: Bool = false
            var showingRedEyeIconForThisTrip: Bool = false
            var redEyeDateHandledForOvernight: Bool = false
            
            let redEyeIconButton = CBUtils.redEyeIconButton(fontSize: 20)
            var redEyePayLabel:UILabel? = nil
            
            let userdefaults = UserDefaults.standard
            
            for d in 0..<daysCount {
                showingRedEyeIconForThisDay = false
                var labelFrame = button.bounds
                labelFrame.size.width = cellWidth
                var dayIndex = d
                if !self.bidPeriod!.isFABid() && (trip.info?.dutyPeriodsCount != trip.info?.calendarDaysCount) {
                    if !showingRedEyeIconForThisTrip {
                        if trip.isRedEyeTrip && (dayIndex >= missingDateIndex) && missingDateIndex != -1 {
                            labelFrame.origin.x = CGFloat(d) * cellWidth + 3
                            redEyeIconButton.frame = labelFrame
                            labelButton.addSubview(redEyeIconButton)
                            redEyePayLabel = UILabel(frame: labelFrame)
                            labelButton.addSubview(redEyePayLabel!)
                            
                            if trip.info?.dutyPeriodsCount == trip.info?.calendarDaysCount {
                                showingRedEyeIconForThisDay = true
                                showingRedEyeIconForThisTrip = true
                            }else{
                                dayIndex += 1
                                showingRedEyeIconForThisDay = false
                            }
                        }
                    }
                }
                labelFrame.origin.x = CGFloat(dayIndex) * cellWidth
                // Show labels in other button if day is greater than length of
                // first button. Adjust origin of label to other button.
                if otherButton != nil && dayIndex >= buttonLength {
                    labelButton = otherButton!
                    labelFrame.origin.x = CGFloat(d - buttonLength) * cellWidth + 3
                    if !self.bidPeriod!.isFABid() && trip.info?.dutyPeriodsCount != trip.info?.calendarDaysCount {
                        if !showingRedEyeIconForThisTrip {
                            if trip.isRedEyeTrip && (dayIndex - buttonLength) >= missingDateIndex && missingDateIndex != -1 {
                                redEyeIconButton.frame = labelFrame
                                labelButton.addSubview(redEyeIconButton)
                                redEyePayLabel = UILabel(frame: labelFrame)
                                labelButton.addSubview(redEyePayLabel!)
                                if trip.info?.dutyPeriodsCount == trip.info?.calendarDaysCount {
                                    showingRedEyeIconForThisDay = true
                                    showingRedEyeIconForThisTrip = true
                                }else{
                                    showingRedEyeIconForThisDay = false
                                }
                            }
                        }
                    }
                    labelFrame.origin.x = CGFloat(dayIndex - buttonLength) * cellWidth
                }
                let label = UILabel(frame: labelFrame)
                label.textAlignment = .center
                if trip.highlightCount!.intValue > 0 {
                    label.textColor = CBColor.tripHighlightColor
                }else{
                    label.textColor = .white
                }
                if showingRedEyeIconForThisDay {
                    label.textColor = .clear
                }
                label.font = UIFont.boldSystemFont(ofSize: 12)
                
                let day:BIDay = orderedDays[d]
                let dayInfo:BIDayInfo = day.info!
                
                if trip.isRedEyeTrip && d == missingDateIndex && (self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) && trip.vacationOverlapType!.intValue > 0 {
                    redEyePayLabel?.textAlignment = .center
                    redEyePayLabel?.font = UIFont.boldSystemFont(ofSize: 12)
                    redEyePayLabel?.textColor = trip.highlightCount!.intValue > 0 ? CBColor.tripHighlightColor : .white
                }else{
                    redEyePayLabel = nil
                }
                if (self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) && trip.vacationOverlapType!.intValue > 0 && day.displayType!.intValue != BIDayDisplayType.normal.rawValue{
                    if day.displayType?.intValue == BIDayDisplayType.fullPay.rawValue{
                        if CBUtils.isClawBack(line: self.line!, day: day, bidPeriod: self.bidPeriod!){
                            label.text = "CB"
                        }else{
                            label.text = "$"
                        }
                    }
                    else if day.displayType?.intValue == BIDayDisplayType.partialPay.rawValue{
                        label.text = "¢"
                    }else{ // No pay
                        label.text = "x"
                    }
                    label.font = UIFont.boldSystemFont(ofSize: 20)
                    
                    if redEyePayLabel != nil {
                        redEyePayLabel?.text = "$"
                        redEyePayLabel?.font = UIFont.boldSystemFont(ofSize: 20)
                        redEyeIconButton.removeFromSuperview()
                    }
                }else{
                    if true{
                        if self.bidPeriod!.isFABid() && trip.isReserve{
                            if BIFaReserveLineType.SnrAMres.rawValue == trip.line?.faReserveLineType?.intValue{
                                label.text = "SA"
                            }else if BIFaReserveLineType.SnrPMres.rawValue == trip.line?.faReserveLineType?.intValue{
                                label.text = "SP"
                            }else if BIFaReserveLineType.JnrAMres.rawValue == trip.line?.faReserveLineType?.intValue{
                                label.text = "JA"
                            }else if BIFaReserveLineType.JnrPMres.rawValue == trip.line?.faReserveLineType?.intValue{
                                label.text = "JP"
                            }else if BIFaReserveLineType.JnrLateRes.rawValue == trip.line?.faReserveLineType?.intValue{
                                label.text = "JL"
                            }
                        }else if self.bidPeriod!.isFABid(){
                            label.text = String(format: "%.1f", trip.info!.faPay!.floatValue)
                        }else{
                            if let number = trip.info?.number, number.count > 1 {
                                let secondChar = number[number.index(number.startIndex, offsetBy: 1)]
                                if secondChar == "P" {
                                    label.text = String(format: "%.1f", trip.info?.jsonPay?.floatValue ?? 0)
                                } else {
                                    label.text = String(format: "%.1f", trip.info?.faPay?.floatValue ?? 0)
                                }
                            }
                        }
                        let timeLabelFrame = CGRect(x: labelFrame.origin.x, y: labelFrame.origin.y + labelFrame.size.height - 12, width: labelFrame.size.width, height: 10)
                        let timeLabel = UILabel(frame: timeLabelFrame)
                        timeLabel.font = UIFont.systemFont(ofSize: 8)
                        if trip.highlightCount!.intValue > 0 {
                            timeLabel.textColor = CBColor.tripHighlightColor
                        }else{
                            timeLabel.textColor = .white
                        }
                        if showingRedEyeIconForThisDay{
                            timeLabel.textColor = .clear
                        }
                        timeLabel.textAlignment = .center
                        let leg = dayInfo.orderedLegs.last
                        let arriveMinutes = leg!.arriveMinutes!
                        var returnTime = CBUtils.changeMinutesToShowHours(arriveMinutes).intValue
                        if trip.isReserve{
                            returnTime = (trip.info?.returnTime!.intValue)!
                        }
                        timeLabel.text = String(format: "%04d", returnTime % 2400)
                        if (userdefaults.integer(forKey: kCBTimeZoneSetting) != CBTimeZoneSetting.herbTime.rawValue) || (trip.isReserve && self.bidPeriod!.isFABid()){
                            let arriveFormatter = DateFormatter()
                            arriveFormatter.dateFormat = "HHmm"
                            arriveFormatter.timeZone = CBUtils.timeZone(forAirportCode: (dayInfo.orderedLegs.last)!.arriveCity!)
                            var calendar = Calendar(identifier: .gregorian)
                            calendar.locale = Locale(identifier: "en_US")
                            calendar.timeZone = TimeZone(identifier: "US/Central")!
                            var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate!)
                            dateComps.minute = (dayInfo.orderedLegs.last)?.arriveMinutes?.intValue
                            if trip.isReserve{
                                dateComps.minute = CBUtils.convertTimeToMinutes(trip.info?.returnTime?.intValue)
                            }
                            let arriveDate = calendar.date(from: dateComps)!
                            timeLabel.text = arriveFormatter.string(from: arriveDate)
                            
                            // Static / Fixed time for FA Reserve Type
                            
                            //                            let timeZoneStr = CBUtils.rawTimeZoneString(forAirportCode: (dayInfo.orderedLegs.first)!.arriveCity!)!
                            //                            let arriveDateStr = BITrip.staticTimeForReserveType(trip: trip, line: self.line!, key: "arrive", timeZone: timeZoneStr)
                            //                            if arriveDateStr != nil {
                            //                                timeLabel.text = arriveDateStr
                            //                            }
                        }
                        if userdefaults.bool(forKey: "IsSelectedReporTimeForTripButton") == true{
                            timeLabel.text = String(format: "%04d", day.info!.releaseTime!.intValue % 2400)
                            if userdefaults.integer(forKey: kCBTimeZoneSetting) != CBTimeZoneSetting.herbTime.rawValue {
                                let departFormatter = DateFormatter()
                                departFormatter.dateFormat = "HHmm"
                                departFormatter.timeZone = CBUtils.timeZone(forAirportCode: (dayInfo.orderedLegs.last)!.arriveCity!)
                                var calendar = Calendar(identifier: .gregorian)
                                calendar.locale = Locale(identifier: "en_US")
                                calendar.timeZone = TimeZone(identifier: "US/Central")!
                                var dateComps = calendar.dateComponents([.year, .month, .day ], from: day.date!)
                                dateComps.minute = dayInfo.orderedLegs.last!.arriveMinutes!.intValue + trip.info!.debriefMinutes!.intValue
                                if trip.isReserve{
                                    dateComps.minute = CBUtils.convertTimeToMinutes(trip.info?.returnTime?.intValue)
                                }
                                let departDate = calendar.date(from: dateComps)!
                                timeLabel.text = departFormatter.string(from: departDate)
                                let timeZoneStr = CBUtils.rawTimeZoneString(forAirportCode: dayInfo.orderedLegs.first!.arriveCity!)!
                                let arriveDateStr = BITrip.staticTimeForReserveType(trip: trip, line: self.line!, key: "arrive", timeZone: timeZoneStr)
                                if arriveDateStr != nil {
                                    timeLabel.text = arriveDateStr
                                }
                            }
                        }
                        timeLabel.backgroundColor = .clear
                        labelButton.addSubview(timeLabel)
                    }
                    // All except last day. Show overnight city.
                    if dayInfo.nextDay != nil {
                        label.text = dayInfo.city
                    }
                    
                    // First day of trip. Show depart time.
                    
                    if true{
                        let timeLabelFrame = CGRect(x: labelFrame.origin.x, y: labelFrame.origin.y + 2, width: labelFrame.size.width, height: 10)
                        let timeLabel = UILabel(frame: timeLabelFrame)
                        timeLabel.font = UIFont.systemFont(ofSize: 8)
                        if trip.highlightCount!.intValue > 0{
                            timeLabel.textColor = CBColor.tripHighlightColor
                        }else{
                            timeLabel.textColor = .white
                        }
                        if showingRedEyeIconForThisDay{
                            timeLabel.textColor = .clear
                        }
                        timeLabel.textAlignment = .center
                        let leg = dayInfo.orderedLegs.first
                        let departMinutes = leg!.departMinutes!
                        let departTime = CBUtils.changeMinutesToShowHours(departMinutes).intValue
                        timeLabel.text = String(format: "%04d", departTime % 2400)
                        let timeZoneStr = CBUtils.rawTimeZoneString(forAirportCode: dayInfo.orderedLegs.first!.departCity!)
                        let departDateStr = BITrip.staticTimeForReserveType(trip: trip, line: self.line!, key: "depart", timeZone: timeZoneStr!)
                        if departDateStr != nil {
                            timeLabel.text = departDateStr
                        }
                        if userdefaults.integer(forKey: kCBTimeZoneSetting) != CBTimeZoneSetting.herbTime.rawValue {
                            let departFormatter = DateFormatter()
                            departFormatter.dateFormat = "HHmm"
                            departFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo.orderedLegs.first!.departCity!)
                            var calendar = Calendar(identifier: .gregorian)
                            calendar.locale = Locale(identifier: "en_US")
                            calendar.timeZone = TimeZone(identifier: "US/Central")!
                            var dateComps = calendar.dateComponents([.year, .month,.day], from: trip.startDate!)
                            dateComps.minute = dayInfo.orderedLegs.first?.departMinutes?.intValue
                            let departDate = calendar.date(from: dateComps)!
                            timeLabel.text = departFormatter.string(from: departDate)
                            
                            let timeZoneStr = CBUtils.rawTimeZoneString(forAirportCode: dayInfo.orderedLegs.first!.departCity!)
                            let departDateStr = BITrip.staticTimeForReserveType(trip: trip, line: self.line!, key: "depart", timeZone: timeZoneStr!)
                            if departDateStr != nil {
                                timeLabel.text = departDateStr
                            }
                        }
                        if userdefaults.bool(forKey: "IsSelectedReporTimeForTripButton") == true{
                            timeLabel.text = String(format: "%04d", (day.info?.reportTime!.intValue)! % 2400)
                            if userdefaults.integer(forKey: kCBTimeZoneSetting) != CBTimeZoneSetting.herbTime.rawValue {
                                let departFormatter = DateFormatter()
                                departFormatter.dateFormat = "HHmm"
                                departFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo.orderedLegs.first!.departCity!)
                                var calendar = Calendar(identifier: .gregorian)
                                calendar.locale = Locale(identifier: "en_US")
                                calendar.timeZone = TimeZone(identifier: "US/Central")!
                                var dateComps = calendar.dateComponents([.year, .month,.day], from: day.date!)
                                if d == 0 {
                                    dateComps.minute = (dayInfo.orderedLegs.first?.departMinutes!.intValue)! - (trip.info?.briefMinutes!.intValue)!
                                }else{
                                    dateComps.minute = (dayInfo.orderedLegs.first?.departMinutes!.intValue)! - (trip.info?.debriefMinutes!.intValue)!
                                }
                                let departDate = calendar.date(from: dateComps)!
                                timeLabel.text = departFormatter.string(from: departDate)
                            }
                        }
                        if !self.bidPeriod!.isFABid() && trip.isReserve{
                            let departFormatter = DateFormatter()
                            departFormatter.dateFormat = "HHmm"
                            departFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo.orderedLegs.first!.departCity!)
                            var calendar = Calendar(identifier: .gregorian)
                            calendar.locale = Locale(identifier: "en_US")
                            calendar.timeZone = TimeZone(identifier: "US/Central")!
                            var dateComps = calendar.dateComponents([.year, .month,.day], from: trip.startDate!)
                            let departTime = (trip.info?.departTime!.intValue)! % 2400
                            let arriveMins = (departTime/100) * 60 + departTime%100
                            dateComps.minute = (dayInfo.orderedLegs.first?.departMinutes!.intValue)! - (trip.info?.briefMinutes!.intValue)!
                            dateComps.minute = arriveMins
                            let departDate = calendar.date(from: dateComps)!
                            timeLabel.text = departFormatter.string(from: departDate)
                        }
                        timeLabel.backgroundColor = .clear
                        labelButton.addSubview(timeLabel)
                        
                        if day.displayType?.intValue == BIDayDisplayType.normal.rawValue{
                            var xValue:CGFloat = 0.0
                            xValue = label.frame.origin.x + cellWidth - 13
                            let weekDayInt = CBUtils.weekDay(from: trip.startDate!)
                            let isSaturday = (weekDayInt + d == 7)
//                            if isSaturday{
//                                xValue = fromScrachpadView == true ? xValue - 6 : xValue - 7
//                            }
                            let verticalLabelFrame = CGRect(x: xValue, y: labelFrame.origin.y + 15, width: 26, height: 10)
                            
                            let verticalLabel = UILabel(frame: verticalLabelFrame)
                            verticalLabel.textColor = CBColor.cbGreen
                            verticalLabel.textAlignment = .center
                            verticalLabel.font = UIFont.boldSystemFont(ofSize: 9)
                            verticalLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-90.0 * .pi / 180.0))
                            verticalLabel.translatesAutoresizingMaskIntoConstraints = true
                            labelButton.addSubview(verticalLabel)
                            let releaseTime = (day.info?.releaseTime!.intValue)! % 2400
                            var nextDayReportTime = (dayInfo.nextDay?.reportTime!.intValue) ?? 0 % 2400
                            if trip.isRedEyeTrip && missingRedEyeDate != nil && !redEyeDateHandledForOvernight {
                                let isMissingIndexMatch = (missingDateIndex != -1) && ((missingDateIndex - 1) == d)
                                let isReportReleaseCrossDate = dayInfo.releaseTime!.intValue > dayInfo.reportTime!.intValue
                                let shouldAddOneDay = (dayInfo.reportTime!.intValue < dayInfo.releaseTime!.intValue) && (dayInfo.releaseTime!.intValue < (dayInfo.nextDay?.reportTime!.intValue)!)
                                if isMissingIndexMatch || missingDateIndex == -1 {
                                    if isReportReleaseCrossDate && !isDateMissingInPreviousDay {
                                        nextDayReportTime += 2400
                                    }else{
                                        if isDateMissingInPreviousDay && shouldAddOneDay {
                                            nextDayReportTime += 2400
                                        }
                                    }
                                    redEyeDateHandledForOvernight = true
                                }
                            }
                            if nextDayReportTime != 0 {
                                var groundTime = 0
                                
                                if trip.isReserve {
                                    let minutes = CBUtils.getGroundTimeBetween(reportTime: releaseTime, releaseTime: nextDayReportTime)
                                    groundTime = CBUtils.convertMinsToHHMM(minutes)
                                }else{
                                    let nextDayReportMins = dayInfo.nextDay!.orderedLegs.first?.departMinutes
                                    let releaseMins = dayInfo.orderedLegs.last?.arriveMinutes
                                    var groundMins = nextDayReportMins!.intValue - releaseMins!.intValue
                                    groundMins -= 2 * (trip.info?.debriefMinutes!.intValue)!
                                    groundTime = CBUtils.convertMinsToHHMM(groundMins)
                                }
                                let formattedGroundTime = String(format: "%ld", groundTime)
                                verticalLabel.text = formattedGroundTime
                            }
                        }
                    }
                }
                let hideVacation = userdefaults.bool(forKey: kCBHideVacationKey)
                if self.bidPeriod!.isFABid() && !hideVacation && (day.displayType?.intValue != BIDayDisplayType.normal.rawValue) {
                    if day.displayType?.intValue == BIDayDisplayType.fullPay.rawValue {
                        if CBUtils.isClawBack(line: self.line!, day: day, bidPeriod: self.bidPeriod!) {
                            label.text = "CB"
                        }else{
                            label.text = "$"
                        }
                        label.font = UIFont.boldSystemFont(ofSize: 20)
                    }else if day.displayType?.intValue == BIDayDisplayType.partialPay.rawValue {
                        label.text = "¢"
                        label.font = UIFont.boldSystemFont(ofSize: 20)
                    }else if day.displayType?.intValue == BIDayDisplayType.noPay.rawValue {
                        label.text = "x"
                        label.font = UIFont.boldSystemFont(ofSize: 20)
                    }
                    if redEyePayLabel != nil {
                        redEyePayLabel?.text = "$"
                        redEyePayLabel?.font = UIFont.boldSystemFont(ofSize: 20)
                        redEyeIconButton.removeFromSuperview()
                    }
                }
                label.backgroundColor = .clear
                labelButton.addSubview(label)
            }
        }
        // Check if vacationButtons is nil, and initialize it if necessary.
        
        if nil == vacationButtons {
            vacationButtons = NSMutableArray()
        }
        //        let Vcount: Int = (vacationButtons?.count)!
        for case let view as UIView in vacationButtons! {
            view.removeFromSuperview()
        }
        vacationButtons?.removeAllObjects()
        vacationButtons?.addObjects(from: bidListCellCalendarDaysArr)
        // Check if the user has set to hide vacations (based on UserDefaults).
        
        let hideVacation: Bool = UserDefaults.standard.bool(forKey: kCBHideVacationKey)
        // Add vacation pills if not hidden.
        if !(hideVacation && (bidPeriod?.containsVacay?.boolValue == true)) {
            var vacayButtonFrame = CGRect(x: 0.0, y: 0.0, width: cellWidth, height: cellHeight)
            var buttonImage: UIImage? = nil
            let vacations = bidPeriod?.vacations
            // Loop through vacation periods.
            
            for vacation in vacations! {
                let vacay = vacation as! BIVacation
                // Calculate the index for the vacation within the calendar.
                
                var index: Int = calendarData.indexForDate(date: vacay.startDate! as Date) - calendarData.indexOfFirstDayExpandedView()
                var tripLength: Int = 0
                if index < 0 {
                    tripLength = (vacay.length?.intValue)! + index
                    index = 0
                }
                else if index > (daysInCalendar - 1) {
                    continue
                }
                else {
                    tripLength = vacay.length as! Int
                }
                
                if index < 0 {
                    // Vacation starts before the visible calendar days, so show the rounded right image
                    buttonImage = UIImage(named: "TripButton-rounded-right-yellow_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                }
                else if (index + tripLength - 1) > (daysInCalendar - 1) {
                    // Vacay ends after the visible calendar days, so show the rounded left image
                    buttonImage = UIImage(named: "TripButton-rounded-left-yellow_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                } else {
                    buttonImage = UIImage(named: "TripButton-rounded-both-yellow_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                }
                //vacayButtonFrame.size.width = CGFloat(tripLength) * (cellWidth - 1)
                let vacBtnFrameWidth = CGFloat(tripLength) * (cellWidth + interItemSpacing)
                vacayButtonFrame.size.width = vacBtnFrameWidth
                let button2 = UIImageView(frame: vacayButtonFrame)
                button2.image = buttonImage
                vacationButtons?.replaceObject(at: index, with: button2)
                button2.alpha = 0.6
                collectionView.addSubview(button2)
                // Check if certain conditions allow user interaction with the button.
                
                if (bidPeriod?.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
                    button2.isUserInteractionEnabled = true
                    button2.isOpaque = false
                }
            }
        }
        if fvVacationButtons == nil {
            fvVacationButtons = NSMutableArray()
        }
        let FVcount: Int = (fvVacationButtons?.count)!
        for i in 0 ..< FVcount {
            let fvVacationButton = fvVacationButtons?[i] as? UIImageView
            if fvVacationButton != nil {
                fvVacationButton?.removeFromSuperview()
            }
        }
        fvVacationButtons?.removeAllObjects()
        fvVacationButtons?.addObjects(from: bidListCellCalendarDaysArr)
            //Remove CFV
        if cfvVacationButtons == nil {
            cfvVacationButtons = NSMutableArray()
        }
        let CFVcount: Int = (cfvVacationButtons?.count)!
        for i in 0 ..< CFVcount {
            let cfvVacationButton = cfvVacationButtons?[i] as? UIImageView
            if cfvVacationButton != nil {
                cfvVacationButton?.removeFromSuperview()
            }
        }
        cfvVacationButtons?.removeAllObjects()
        cfvVacationButtons?.addObjects(from: bidListCellCalendarDaysArr)
        
        for view in self.collectionView.subviews {
            if view.tag == 99 {
                view.removeFromSuperview()
            }
        }
        if !(hideVacation && (bidPeriod?.containsVacay?.boolValue == true)) {
            var vacayButtonFrame = CGRect(x: 0.0, y: 0.0, width: (cellWidth - 1), height: cellHeight)
            var buttonImage: UIImage? = nil
            
            var removeCFV = false
            if UserDefaults.standard.value(forKey: "RemoveCfv") != nil {
                removeCFV = UserDefaults.standard.bool(forKey: "RemoveCfv")
            }
            if removeCFV == false && self.bidPeriod!.containsCFV == true && (self.line?.cfvVacDates?.count ?? 0) > 0 {
                for i in 0 ..< (self.line?.cfvVacDates?.count)! {
                    let cfvDates = self.line?.cfvVacDates?.object(at: i) as? String
                    let cfv = UILabel()
                    cfv.backgroundColor = .darkGray
                    cfv.alpha = 1
                    cfv.tag = 99
                    cfv.text = "$FV"
                    cfv.textAlignment = .center
                    cfv.font = UIFont.boldSystemFont(ofSize: 11.0)
                    cfv.textColor = .white
                    let dateString = "\(cfvDates ?? "")-\(self.bidPeriod?.month?.intValue ?? 0)-\(self.bidPeriod?.year?.intValue ?? 0000)"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "d-M-yyyy"
                    let timeZone = TimeZone(secondsFromGMT: 0)
                    dateFormatter.timeZone = timeZone
                    let cfvDATE = dateFormatter.date(from: dateString)
                    let index = self.calendarData.indexForDate(date: cfvDATE!) - calendarData.indexOfFirstDayExpandedView()
                    let indexPath1 = IndexPath(row: index + 1, section: 0)
                    let buttonLayoutAttributes1 = self.collectionView.layoutAttributesForItem(at: indexPath1)
                    let vacayButtonFrame = buttonLayoutAttributes1?.frame
                    cfv.frame = vacayButtonFrame!
                    cfv.layer.cornerRadius = 3
                    cfv.layer.masksToBounds = true
                    cfvVacationButtons?.replaceObject(at: index + 1, with: cfv)
                    self.collectionView.addSubview(cfv)
                }
            }
            
            let vacations = self.line?.fvvacations
            
            for vacation in vacations! {
                let vacay = vacation as! BIVacation
                if  vacay.fvStartdate == nil{
                    continue
                }
                var index: Int = calendarData.indexForDate(date: vacay.fvStartdate! as Date) - calendarData.indexOfFirstDayExpandedView()
                var tripLength: Int = 0
                if index < 0 {
                    tripLength = (vacay.fvLength?.intValue)! + index
                    index = 0
                }
                else if index > (daysInCalendar - 1) {
                    continue
                }
                else {
                    tripLength = vacay.fvLength as! Int
                }
                
                let column: Int = index % 7
                var buttonLength: Int = 0
                    // If vacation pill will go across two rows in calendar, create both buttons.
                if column + tripLength > 7 {
                    buttonLength = 7 - column
                    vacayButtonFrame.size.width = CGFloat(buttonLength) * (cellWidth - 1)
                    buttonImage = UIImage(named: userDefaults.string(forKey: kCBTripButtonRoundedLeftFVBlueImageNameKey)!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    vacayButtonFrame.size.width = min(CGFloat(tripLength), 7.0) * (cellWidth - 1)
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    fvVacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.6
                    collectionView.addSubview(button2)
                    if (bidPeriod?.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
                        button2.isUserInteractionEnabled = true
                        button2.isOpaque = false
                    }
                    tripLength -= buttonLength
                    index += buttonLength
                    while tripLength > 0 {
                        buttonLength = tripLength > 7 ? 7 : tripLength
                        if index < daysInCalendar {
                            vacayButtonFrame.size.width = min(CGFloat(buttonLength), CGFloat(7.0)) * (cellWidth - 1)
                                // Check to see if we need to get it to draw a bit farther to the right to get the double flat
                                // side effect
                            if tripLength > 7 {
                                vacayButtonFrame.size.width += 15.0
                            }
                            buttonImage = UIImage(named: userDefaults.string(forKey: kCBTripButtonRoundedRightFVBlueImageNameKey)!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                            let otherButton2 = UIImageView(frame: vacayButtonFrame)
                            otherButton2.image = buttonImage
                            fvVacationButtons?.replaceObject(at: index, with: otherButton2)
                            otherButton2.alpha = 0.6
                            collectionView.addSubview(otherButton2)
                            if (bidPeriod?.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
                                otherButton2.isUserInteractionEnabled = true
                                otherButton2.isOpaque = false
                            }
                        }
                        tripLength -= buttonLength
                        index += buttonLength
                    }
                } else {
                    if index < 0 {
                            // Vacation starts before the visible calendar days, so show the rounded right image
                        let imageName = userDefaults.string(forKey: kCBTripButtonRoundedRightFVBlueImageNameKey)
                        buttonImage = UIImage(named: imageName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }
                    else if (index + tripLength - 1) > (daysInCalendar - 1) {
                            // Vacay ends after the visible calendar days, so show the rounded left image
                        let imageName = userDefaults.string(forKey: kCBTripButtonRoundedLeftFVBlueImageNameKey)
                        buttonImage = UIImage(named: imageName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    } else {
                        let imageName = userDefaults.string(forKey: kCBTripButtonRoundedBothFVBlueImageNameKey)
                        buttonImage = UIImage(named: imageName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }
                    vacayButtonFrame.size.width = CGFloat(tripLength) * (cellWidth - 1)
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    fvVacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.6
                    collectionView.addSubview(button2)
                    if (bidPeriod?.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
                        button2.isUserInteractionEnabled = true
                        button2.isOpaque = false
                    }
                }
            }
        }

        // Reload the collection view data and set various button arrays.
        collectionView.reloadData()
        collectionView.tripButtons = tripButtons;
        collectionView.vacationButtons = vacationButtons;
        collectionView.fvVacationButtons = fvVacationButtons
        collectionView.cfvVacationButtons = cfvVacationButtons
    }
   
}

extension CBExpandedBidLinesTableControllerCell:UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bidListCellCalendarDaysArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth , height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let kDayCellIdentifer = "ExpandedCalendarCollectionViewCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kDayCellIdentifer, for: indexPath as IndexPath) as! ExpandedCalendarCollectionViewCell
        cell.contentView.frame = cell.bounds
        cell.contentView.isUserInteractionEnabled = false
        cell.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell.dayLabel.textColor = .black
        cell.lblWeekDays.textColor = .label
        if let indexPaths = collectionView.indexPathsForSelectedItems, let indexP = indexPaths.first {
            cell.contentView.backgroundColor = indexP == indexPath ? .white : .lightGray
        }
        let calendeday = bidListCellCalendarDaysArr[indexPath.row] as! BICalendarDay
        cell.dayLabel.text = calendeday.text
        cell.lblWeekDays.text = calendeday.dayOfWeekAbbreviation
        let currentMonth = calendeday.isCurrentMonth
        if currentMonth {
            cell.dayLabel.textColor = UIColor .label
            cell.dayLabel.alpha = 1
        }else {
            cell.dayLabel.textColor = UIColor .label
            cell.dayLabel.alpha = 0.7
        }
        if calendeday.isWeekend{
            cell.dayLabel.textColor = .lightGray
            cell.lblWeekDays.textColor = .lightGray
        }
        return cell
    }
}
extension CBExpandedBidLinesTableControllerCell: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        // Reset the flag when the popover is dismissed
        isUserFlagMenuPresented = false
    }
    
}
