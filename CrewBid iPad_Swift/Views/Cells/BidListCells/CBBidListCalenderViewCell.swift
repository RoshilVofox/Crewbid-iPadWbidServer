//
//  CBBidListCalenderViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

protocol CBBidListCalenderViewCellDelegate {
    func didTappedOnCalandarView(indexPath: IndexPath)
}


class CBBidListCalenderViewCell: UITableViewCell, UITextFieldDelegate, CBUserFlagTableControllerDelegate {

    

    
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
    @IBOutlet weak var selectionToggleButton: CBToggleButton!
    @IBOutlet weak var calendarCollectionView: CBLineCalendarCollectionView!
    
    var calendarData: BICalendarData?
    var line: BILine?
    var indexPath: IndexPath!
    var tripButtons: NSMutableArray?
    var vacationButtons: NSMutableArray?
    var fvVacationButtons: NSMutableArray?
    var cfvVacationButtons: NSMutableArray?
    var tripButtonsArray: NSMutableArray?
    var bidPeriod: BIBidPeriod!
    var delegate: CBBidListCalenderViewCellDelegate?
    var vacayGestureRecognizers = NSMutableArray()
    var userFlagIconView: UIView = UIView()
    var warningButton: UIButton = UIButton ()
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
    private var kLineNumberVertOrigin: Int = 50
    private var kCircleSize: Int = 16 //25
    private var kCircleHorizontalOffset: Int = 10 //28
    private var kCircleVerticalOffset: Int = 110 //90
    private var kCircleVerticalIncrement: Int = 20 //30
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
    
    var calendarDaysCount: NSMutableArray?
    var markerTextField = UITextField()
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
    var cellType = CBBidLineTableCellType(rawValue: 0)
    private var kSelectionButtonTag: Int = 80
    var fromScrachpadView:Bool?
    var vacationDoubleTapActionBlock: ((_ view: UIView) -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        markerTextField.delegate = self
        HandleInsertLineHere()
        
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellLayout()
        let verticalSpace: CGFloat = 6.0
        for i in 0..<5 {
            var lineValueView = CBLineValueView(frame: CGRect.zero)
            lineValueView = lineValueView.initWithFrame(aRect: CGRect.zero)
            lineValueView.tag = LineValueViewTag + i * 10
            lineValueView.translatesAutoresizingMaskIntoConstraints = false
            lineValuesContainerView.addSubview(lineValueView)
            // Line value view centered in container.
            lineValuesContainerView.addConstraint(NSLayoutConstraint(item: lineValueView, attribute: .centerX, relatedBy: .equal, toItem: lineValuesContainerView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            // Top spacing from superview.
            lineValuesContainerView.addConstraint(NSLayoutConstraint(item: lineValueView, attribute: .top, relatedBy: .equal, toItem: lineValuesContainerView, attribute: .top, multiplier: 1.0, constant: CGFloat(i) * (kCBLineValueViewHeight + verticalSpace)))
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressLineValueContainerView))
        longPressGesture.minimumPressDuration = 0.3
        lineValuesContainerView.addGestureRecognizer(longPressGesture)
        longPressGesture.delaysTouchesBegan = true
        
        var posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posAView = posView
        posAView.tag = kPosAViewTag
        posAView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        var circleFrame: CGRect = posAView.frame
        circleFrame.origin.x = 0.0
        circleFrame.origin.y = 0.0
        posAView.backgroundColor = CBColor.faPosAColor
        var posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.textColor = UIColor.white
        posText.tag = 7
        posText.font = posText.font.withSize(10)
        posText.text = "A"
        posAView.addSubview(posText)
        posAView.alpha = 0.0
        self.posAView = posView
        
        
        // Position A Gray
        
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posAGrayView = posView
        posAGrayView.tag = kPosAGrayViewTag
        posAGrayView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posAGrayView.backgroundColor = UIColor.lightGray
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.textColor = UIColor.white
        posText.tag = 7
        posText.font = posText.font.withSize(10)
        posText.text = "A"
        posAGrayView.addSubview(posText)
        posAGrayView.alpha = 0.0
        
        // Position B Colored
        
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posBView = posView
        posBView.tag = kPosBViewTag
        posBView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posBView.backgroundColor = CBColor.faPosBColor
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.font = posText.font.withSize(10)
        posText.text = "B"
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posBView.addSubview(posText)
        posBView.alpha = 0.0
        
        // Position B Gray
        
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posBGrayView = posView
        posBGrayView.tag = kPosBGrayViewTag
        posBGrayView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posBGrayView.backgroundColor = UIColor.lightGray
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.textColor = UIColor.white
        posText.tag = 7
        posText.font = posText.font.withSize(10)
        posText.text = "B"
        posBGrayView.addSubview(posText)
        posBGrayView.alpha = 0.0
        
        // Position C colored
        
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + 2 * kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posCView = posView
        posCView.tag = kPosCViewTag
        posCView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posCView.backgroundColor = CBColor.faPosCColor
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.font = posText.font.withSize(10)
        posText.text = "C"
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posCView.addSubview(posText)
        posCView.alpha = 0.0
        
        // Position C Gray
        
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + 2 * kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posCGrayView = posView
        posCGrayView.tag = kPosCGrayViewTag
        posCGrayView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posCGrayView.backgroundColor = UIColor.lightGray
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posText.font = posText.font.withSize(10)
        posText.text = "C"
        posCGrayView.addSubview(posText)
        posCGrayView.alpha = 0.0
        
        // Position D Colored
        
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + 3 * kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posDView = posView
        posDView.tag = kPosDViewTag
        posDView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posDView.backgroundColor = CBColor.faPosDColor
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.font = posText.font.withSize(10)
        posText.text = "D"
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posDView.addSubview(posText)
        posDView.alpha = 0.0
        
        // Position D Gray
        
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + 3 * kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posDGrayView = posView
        posDGrayView.tag = kPosDGrayViewTag
        posDGrayView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posDGrayView.backgroundColor = UIColor.lightGray
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posText.font = posText.font.withSize(10)
        posText.text = "D"
        posDGrayView.addSubview(posText)
        posDGrayView.alpha = 0.0
        
        // M Colored
        
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posMView = posView
        posMView.tag = kPosDGrayViewTag
        posMView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posMView.backgroundColor = UIColor.purple
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posText.font = posText.font.withSize(10)
        posText.text = "M"
        posMView.addSubview(posText)
        posMView.alpha = 0.0
        
        // NA Colored
        
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posNAView = posView
        posNAView.tag = kPosDGrayViewTag
        posNAView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posNAView.backgroundColor = UIColor.black
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posText.text = "NA"
        posText.font = posText.font.withSize(10)
        posNAView.addSubview(posText)
        posNAView.alpha = 0.0
        
        
        
        let button = viewWithTag(kSelectionButtonTag) as? UIButton
        button?.setImage(#imageLiteral(resourceName: "radioButton-Off"), for: .normal)
        button?.setImage(#imageLiteral(resourceName: "RadioButton-On"), for: .highlighted)
        button?.addTarget(self, action: #selector(self.selectionButtonAction), for: .touchUpInside)

        // Snowflake
        let snowflake = viewWithTag(kSnowflakeTag) as? UIImageView
        let snowflakeImage = UIImage(named: "Blue_Snowflake")
        snowflake?.image = snowflakeImage
        snowflake?.alpha = 0.0

        
        let iconControl: UIControl? = CBUserFlagTableController.userFlagControlForColor(color: UIColor.clear, diameter: 40.0)
        iconControl?.frame = CGRect(x: 20.0, y: 65.0, width: 40.0, height: 40.0)
        iconControl?.addTarget(self, action: #selector(showUserFlagMenu), for: .touchUpInside)
        if let aControl = iconControl {
            mainView.addSubview(aControl)
        }
        userFlagControl = iconControl
    }
    
    func cellLayout(){
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        calendarCollectionView.collectionViewLayout = layout
    }
    
    @objc func selectionButtonAction(_ sender: UIButton) {
        self.bidPeriod.currentDateTime = Date()
        self.bidPeriod.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        sender.isSelected = !sender.isSelected
        selectButton(sender.isSelected)
        var notification: Notification? = nil
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let dict = ["object":self,"indexPath":indexPath] as [String : Any]
        if sender.isSelected {
            notification = Notification(name: Notification.Name(rawValue: CBBidLineTableCellDidSelectNotification), object: dict)
        }
        else {
            notification = Notification(name: Notification.Name(rawValue: CBBidLineTableCellDidDeselectNotification), object: dict)
        }
        if let aNotification = notification {
            NotificationCenter.default.post(aNotification)
        }
    }
    
    
    @objc func showUserFlagMenu() {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let flagVC = storyboard.instantiateViewController(withIdentifier: "CBUserFlagTableController") as!CBUserFlagTableController
        flagVC.delegate = self
        flagVC.modalPresentationStyle = .popover
        flagVC.line = line
        flagVC.showPopover(sourceView: userFlagControl)
        
    }
    

    @objc func longPressLineValueContainerView(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBLineValuesMenuController") as! CBLineValuesMenuController
        lineValuesController.bidPeriod = bidPeriod
        lineValuesController.modalPresentationStyle = .popover
        let touchPoint = gesture.location(in: self.lineValuesContainerView)
        let frame = CGRect(origin: touchPoint, size: CGSize(width: 1, height: 1))
        lineValuesController.showPopover(sourceView: self.lineValuesContainerView, sourceRect: frame)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setMarkerText(_ text: String?) {
        markerTextField.text = text
    }
    
    func selectButton(_ selected: Bool) {
        if selected {
            selectionToggleButton.setImage(#imageLiteral(resourceName: "RadioButton-On"), for: .normal)
        }
        else {
            selectionToggleButton.setImage(#imageLiteral(resourceName: "radioButton-Off"), for: .normal)
        }
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
            try self.bidPeriod.managedObjectContext!.save()
        } catch {
            print(error)
        }
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    
    // Function to handle freezing condition

    func handlingFreezingCondition()  {
        imgAccessoryView.isHidden = false
        if (line!.isFrozen != 0) {
            let snowflakeImage = UIImage(named: "Blue_Snowflake")
            imgAccessoryView?.image = snowflakeImage
            lineLabel.textColor = UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0)
            selectionToggleButton.isHidden = true
            self.isEditing = false
        }
        else
         {
            let snowflakeImage = UIImage(named: "Blue_SnowflakeEmpty")
            imgAccessoryView?.image = snowflakeImage
            imgAccessoryView.isHidden = true
             lineLabel.textColor = UIColor.black
            if bidPeriod.isFABid() && self.line!.faPosition?.intValue != BIFaPosition.FaPositionNA.rawValue {
                lineLabel.textColor = UIColor.white
            }else {
                lineLabel.textColor = UIColor.label
            }
            selectionToggleButton.isHidden = false
            self.isEditing = false
        }
    }
    
    func refreshCalendar(){
        //let daysInCalendar: Int = calendarData!.calendarDays.count
         let daysInCalendar: Int = (calendarDaysCount?.count)!
        // Create pointer array for calendar day types, if not yet created.
        if nil == calendarTripDayTypes {
            calendarTripDayTypes = NSMutableArray()
            calendarTripDayTypes?.removeAllObjects()
            calendarTripDayTypes?.addObjects(from: (calendarDaysCount as! [Any]))
           
            
            calendarTripDayColors = NSMutableArray()
            calendarTripDayColors?.removeAllObjects()
            calendarTripDayColors?.addObjects(from: (calendarDaysCount as! [Any]))
            
            
            // Calendar collection view is 67 X 50. If only 5 weeks, set top inset
            // and line spacing to fit 5 lines.
            if 5 == calendarData?.weeksInMonth {
                let flowLayout = calendarCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
                var sectionInset: UIEdgeInsets? = flowLayout?.sectionInset
                sectionInset?.top = 4.0
                flowLayout?.sectionInset = sectionInset!
                flowLayout?.minimumLineSpacing = 3.0
            }
//            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
//            calendarCollectionView.addGestureRecognizer(tapGesture)
//            self.tapGesture = tapGesture
        }
        // If calendar trip day types array already exists, set all calendar trip
        // day types to 0 (CBCalendarTripDayNone).
        else {
            let count: Int = calendarTripDayTypes!.count
            for i in 0..<count {
                if i > (daysInCalendar - 1) {
                    continue
                }
                calendarTripDayTypes?.replaceObject(at: i, with: CBCalendarTripDayType.cbCalendarTripDayNone)
//                let pointer = Unmanaged<AnyObject>.passUnretained(CBCalendarTripDayType.cbCalendarTripDayNone as AnyObject).toOpaque()
//                calendarTripDayTypes?.replacePointer(at: i, withPointer: pointer)
            }
        }
        
        let trips = line!.trips
        
        
        for case let trip as BITrip in trips!{
            
            //BIVacationOverlapTripOption tripOption = [[[NSUserDefaults standardUserDefaults] objectForKey:kCBVacationOverlapTripDisplayOption] integerValue];
            let tripOption = UserDefaults.standard.object(forKey: kCBVacationOverlapTripDisplayOption)
            if (bidPeriod.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) && (tripOption != nil) {
                if BIVacationOverlapTripOption.dropAll.rawValue == Int(tripOption as! Int) && (trip.vacationOverlapType?.intValue)! > 0 {
                    continue
                }
                else if Int(tripOption as! Int) == trip.vacationOverlapType?.intValue {
                    continue
                }
            }
            
            //NSInteger tripStartDay = trip.startDay.integerValue;
            
            let startIndex: Int = calendarData!.indexForDate(date: trip.startDate! as Date)
            // Account for nil pairings showing up in the blank lines
            if startIndex > (daysInCalendar - 1) || startIndex < 0 {
                continue
            }
            // Color of trip cell.
            var color: UIColor? = nil
            if bidPeriod.isFABid() && trip.isReserve {
                if BIFaReserveLineType.SnrAMres.rawValue == line?.faReserveLineType?.intValue {
                    color = CBColor.green
                } else if BIFaReserveLineType.SnrPMres.rawValue == line?.faReserveLineType?.intValue {
                    color = CBColor.tripButtonredColor
                }
                else if BIFaReserveLineType.JnrAMres.rawValue == line?.faReserveLineType?.intValue {
                    color = CBColor.lightGreenColor
                }
                else if BIFaReserveLineType.JnrPMres.rawValue == line?.faReserveLineType?.intValue {
                    color = CBColor.lightTripButtonRedColor
                }
                else {
                    color = CBColor.brown
                }
            } else {
                if trip.isAM() {
                    if trip.isReserve {
                        color = CBColor.green
                    }  else {
                        color = CBColor.orange
                    }
                } else {
                    if trip.isReserve {
                        color = CBColor.tripButtonredColor
                    } else {
                        color = CBColor.purpleColor
                    }
                }
            }
            if trip.isRedEyeTrip == true {
                color = UIColor.red
            }
            
            // Shape of calendar cells (rounded left, right, both, or neither).
            let tripLength: Int = trip.info!.calendarDaysCount as! Int
            
            for i in 0..<tripLength {
                // Single day trip (turn).CBCalendarTripDayType
                if 1 == tripLength {
                   calendarTripDayTypes?.replaceObject(at: startIndex + i, with: CBCalendarTripDayType.cbCalendarTripDaySingle)
                    
                }else if 0 == i {
                    calendarTripDayTypes?.replaceObject(at: startIndex + i, with: CBCalendarTripDayType.cbCalendarTripDayStart)
                }
                else if tripLength - 1 == i {
                    if (startIndex + i) < (calendarTripDayTypes?.count)! {
                        calendarTripDayTypes?.replaceObject(at: startIndex + i, with: CBCalendarTripDayType.cbCalendarTripDayEnd)
                    }
                }else {
                    if (startIndex + i) < (calendarTripDayTypes?.count)! {
                        calendarTripDayTypes?.replaceObject(at: startIndex + i, with: CBCalendarTripDayType.cbCalendarTripDayMiddle)
                    }
                }
                
                // Set color for day.
                if (startIndex + i) < (calendarTripDayColors?.count)! {
                    calendarTripDayColors?.replaceObject(at: startIndex + i, with: color!)
                }
            }
        }
        calendarCollectionView.reloadData()
    }
    
    func refreshTripButtons(highlightFlag:Bool, calendarWidth:CGFloat) {
        var shouldRemoveCFV = true
        if nil == tripButtons {
            tripButtons = NSMutableArray()
        }
        if tripButtonsArray == nil {
            tripButtonsArray = NSMutableArray(capacity: 15)
        }
        for case let button as UIButton in tripButtons! {
            button.removeFromSuperview()
        }
//        tripButtonsArray?.removeAllObjects()
        tripButtons?.removeAllObjects()
        tripButtons?.addObjects(from: calendarData?.calendarDays as! [Any])
        let userDefaults = UserDefaults.standard
        // Get size of calendar items (cells) and create button frame from size.
        let flowLayout = calendarCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemSize = CGSizeMake(calendarWidth/7, flowLayout.itemSize.height)
//        let inset: CGFloat = itemSize.height/2.0
        let rightRoundedInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 18)
        let leftRoundedInsets  = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)
        let bothRoundedInsets  = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
//        let insets: UIEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        let verticalPadding: CGFloat = 12.0
        let buttonHeight = itemSize.height - verticalPadding
        let yOffset = (itemSize.height - buttonHeight) / 2.0
        var buttonFrame = CGRect( x: 0.0, y: yOffset, width: itemSize.width, height: buttonHeight )
        var buttonImage: UIImage? = nil
        var button = CBTripButton()
        let daysInCalendar: Int = self.calendarData!.calendarDays.count
        let trips = line?.trips
        for item in trips!{
            let trip = item as! BITrip
            if let tripOption = BIVacationOverlapTripOption(rawValue: userDefaults.integer(forKey: kCBVacationOverlapTripDisplayOption)),
               (self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue ||
                self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue),
               let overlapType = trip.vacationOverlapType?.intValue, overlapType > 0 {
                
                // Only apply filtering logic if this trip overlaps with vacation
                if tripOption == .dropAll {
                    continue
                } else if tripOption.rawValue == overlapType {
                    continue
                }
            }
            let highlighted = trip.highlightCount!.intValue > 0 && highlightFlag
            let index = calendarData!.indexForDate(date: trip.startDate!)
            if index > (daysInCalendar-1) || index < 0 {
                continue
            }
            let column: Int = index % 7
            let tripLength: Int = trip.info!.calendarDaysCount as! Int
            var buttonLength: Int = 0
            var otherButton:CBTripButton? = nil
            // If trip will go across two rows in calendar, create both buttons.
            if column + tripLength > 7 {
                buttonLength = 7 - column
                buttonFrame.size.width = CGFloat(buttonLength) * (itemSize.width)
                if trip.isRedEyeTrip {
                    buttonImage = UIImage(named: "TripButton-rounded-left-redEye_red_iOS7")?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                }else if bidPeriod.isFABid() && trip.isReserve {
                    if BIFaReserveLineType.SnrAMres.rawValue == Int(truncating: (line?.faReserveLineType)!) {
                        buttonImage = UIImage.imageWithColor(CBColor.cbGreenColor)
                    }
                    else if BIFaReserveLineType.SnrPMres.rawValue == line?.faReserveLineType?.intValue {
                        buttonImage = UIImage.imageWithColor(CBColor.tripButtonredColor)
                    }
                    else if BIFaReserveLineType.JnrAMres.rawValue == line?.faReserveLineType?.intValue {
                        buttonImage = UIImage.imageWithColor(CBColor.lightGreenColor)
                    }
                    else if BIFaReserveLineType.JnrPMres.rawValue == line?.faReserveLineType?.intValue {
                        buttonImage = UIImage.imageWithColor(CBColor.lightTripButtonRedColor)
                    }
                    else {
                        buttonImage = UIImage.imageWithColor(CBColor.cbBrownColor)
                    }
                } else {
                    if trip.isAM(){
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-left-green_iOS7")?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                        }else {
                            buttonImage = UIImage(named: "TripButton-rounded-left-orange_iOS7@2x")?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                        }
                    }else{
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-left-red2_iOS7")?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                        }else {
                            buttonImage = UIImage(named: "TripButton-rounded-left-purple_iOS7")?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                        }
                    }
                }
                buttonFrame.size.width =  CGFloat(buttonLength) * (itemSize.width)
                button = CBTripButton(frame: buttonFrame)
                button.tag = kCBButtonTag
                button.trip = trip
                button.setBackgroundImage(buttonImage, for: .normal)
                if (self.bidPeriod.isFABid() && trip.isReserve) {
                    button.layer.cornerRadius = (button.frame.height) / 2
                    button.clipsToBounds = true
                }
                button.addTarget(self, action: #selector(tripButtonAction), for: .touchUpInside)
                tripButtons?.replaceObject(at: index, with: button)
                tripButtonsArray?.add(button)
                calendarCollectionView.addSubview(button)
                let nextButtonLength: Int = tripLength - buttonLength
                let nextButtonIndex: Int = index + buttonLength
                buttonFrame.size.width = CGFloat(nextButtonLength) * (itemSize.width)
                if trip.isRedEyeTrip{
                    buttonImage = UIImage(named: "TripButton-rounded-right-redEye_red_iOS7")?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                }
                else if bidPeriod.isFABid() && trip.isReserve {
                    if BIFaReserveLineType.SnrAMres.rawValue == line?.faReserveLineType?.intValue {
                        buttonImage = UIImage.imageWithColor(CBColor.cbGreenColor)
                    }else if BIFaReserveLineType.SnrPMres.rawValue == line?.faReserveLineType?.intValue {
                        buttonImage = UIImage.imageWithColor(CBColor.tripButtonredColor)
                    }else if BIFaReserveLineType.JnrAMres.rawValue == line?.faReserveLineType?.intValue{
                        buttonImage = UIImage.imageWithColor(CBColor.lightGreenColor)
                    }else if BIFaReserveLineType.JnrPMres.rawValue == line?.faReserveLineType?.intValue {
                        buttonImage = UIImage.imageWithColor(CBColor.lightTripButtonRedColor)
                    }else {
                        buttonImage = UIImage.imageWithColor(CBColor.cbBrownColor)
                    }
                } else {
                    if trip.isAM(){
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-right-green_iOS7")?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-right-orange_iOS7")?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                        }
                    }else {
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-right-red2_iOS7")?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-right-purple_iOS7")?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                        }
                    }
                }
                
                otherButton = CBTripButton(frame: buttonFrame)
                otherButton?.tag = kCBButtonTag
                otherButton?.setBackgroundImage(buttonImage, for: .normal)
                if (self.bidPeriod.isFABid() && trip.isReserve) {
                    otherButton?.layer.cornerRadius = (otherButton?.frame.height)! / 2
                    otherButton?.clipsToBounds = true
                }
                otherButton?.trip = trip
                otherButton?.addTarget(self, action: #selector(self.tripButtonAction), for: .touchUpInside)
                button.otherButton = otherButton
                otherButton?.otherButton = button
                if nextButtonIndex < tripButtons!.count{
                    tripButtons?.replaceObject(at: nextButtonIndex, with: otherButton!)
                    tripButtonsArray?.add(button)
                    calendarCollectionView.addSubview(otherButton!)
                }
                if highlighted {
                    let leftBorder = CALayer()
                    leftBorder.cornerRadius = 18.0
                    leftBorder.borderColor = CBColor.tripHighlightColor.cgColor
                    
                    leftBorder.borderWidth = 2.0
                    leftBorder.frame = CGRect(x: 0, y: -2, width: button.frame.width + 10, height: button.frame.height + 4)
                    button.layer.addSublayer(leftBorder)
                    
                    let rightBorder = CALayer()
                    rightBorder.cornerRadius = 18.0
                    rightBorder.borderColor = CBColor.tripHighlightColor.cgColor
                    rightBorder.borderWidth = 2.0
                    rightBorder.frame = CGRect(x: -15, y: -2, width: (otherButton?.frame.width)! + 15, height: (otherButton?.frame.height)! + 4)
                    otherButton?.layer.addSublayer(rightBorder)
                }
            }else{   // Trip in one row only of the calendar.
                if trip.isRedEyeTrip == true {
                    buttonImage = UIImage(named: "TripButton-rounded-both-redEye_red_iOS7")?.resizableImage(withCapInsets: bothRoundedInsets, resizingMode: .stretch)
                }
                else if bidPeriod.isFABid() && trip.isReserve {
                    if BIFaReserveLineType.SnrAMres.rawValue == line?.faReserveLineType?.intValue {
                        buttonImage = UIImage.imageWithColor(CBColor.cbGreenColor)
                    }else if BIFaReserveLineType.SnrPMres.rawValue == line?.faReserveLineType?.intValue {
                        buttonImage = UIImage.imageWithColor(CBColor.tripButtonredColor)
                    }else if BIFaReserveLineType.JnrAMres.rawValue == line?.faReserveLineType?.intValue{
                        buttonImage = UIImage.imageWithColor(CBColor.lightGreenColor)
                    }else if BIFaReserveLineType.JnrPMres.rawValue == line?.faReserveLineType?.intValue {
                        buttonImage = UIImage.imageWithColor(CBColor.lightTripButtonRedColor)
                    }else {
                        buttonImage = UIImage.imageWithColor(CBColor.cbBrownColor)
                    }
                } else {
                    if trip.isAM(){
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-both-green_iOS7")?.resizableImage(withCapInsets: bothRoundedInsets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-both-orange_iOS7")?.resizableImage(withCapInsets: bothRoundedInsets, resizingMode: .stretch)
                        }
                    }else{
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-both-red2_iOS7")?.resizableImage(withCapInsets: bothRoundedInsets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-both-purple_iOS7")?.resizableImage(withCapInsets: bothRoundedInsets, resizingMode: .stretch)
                        }
                    }
                }
                
                buttonFrame.size.width = CGFloat(tripLength) * (itemSize.width)
                button = CBTripButton(frame: buttonFrame)
                button.tag = kCBButtonTag
                button.setBackgroundImage(buttonImage, for: .normal)
                
                if self.bidPeriod.isFABid() && trip.isReserve{
                    button.layer.cornerRadius = button.layer.frame.size.height / 2
                    button.clipsToBounds = true
                    
                }
                button.trip = trip
                if highlighted {
                    let roundedBorder = CALayer()
                    roundedBorder.cornerRadius = 18.0
                    roundedBorder.borderColor = CBColor.tripHighlightColor.cgColor
                    roundedBorder.borderWidth = 2.0
                    roundedBorder.frame = CGRect(x: -1, y: -2, width: button.frame.width + 2, height: button.frame.height + 4)
                    button.layer.addSublayer(roundedBorder)
                }
                button.addTarget(self, action: #selector(tripButtonAction), for: .touchUpInside)
                tripButtons?.replaceObject(at: index, with: button)
                tripButtonsArray?.add(button)
                calendarCollectionView.addSubview(button)
            }
            let orderedDays = trip.orderedDays
            let daysCount: Int = orderedDays.count
            var labelButton: CBTripButton? = button
            
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
            
            for d in 0..<daysCount{
                showingRedEyeIconForThisDay = false
                var labelFrame = button.bounds
                labelFrame.size.width = itemSize.width
                var dayIndex = d
                
                
                if !self.bidPeriod.isFABid() && (trip.info?.dutyPeriodsCount != trip.info?.calendarDaysCount) {
                    if !showingRedEyeIconForThisTrip {
                        if trip.isRedEyeTrip && (dayIndex >= missingDateIndex) && missingDateIndex != -1 {
                            labelFrame.origin.x = CGFloat(d) * itemSize.width + 3
                            redEyeIconButton.frame = labelFrame
                            labelButton?.addSubview(redEyeIconButton)
                            redEyePayLabel = UILabel(frame: labelFrame)
                            labelButton?.addSubview(redEyePayLabel!)
                            
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
                labelFrame.origin.x = CGFloat(dayIndex) * itemSize.width
                // Show labels in other button if day is greater than length of
                // first button. Adjust origin of label to other button.
                if otherButton != nil && dayIndex >= buttonLength {
                    labelButton = otherButton!
                    labelFrame.origin.x = CGFloat(d - buttonLength) * itemSize.width + 3
                    if !self.bidPeriod.isFABid() && trip.info?.dutyPeriodsCount != trip.info?.calendarDaysCount {
                        if !showingRedEyeIconForThisTrip {
                            if trip.isRedEyeTrip && (dayIndex - buttonLength) >= missingDateIndex && missingDateIndex != -1 {
                                redEyeIconButton.frame = labelFrame
                                labelButton?.addSubview(redEyeIconButton)
                                redEyePayLabel = UILabel(frame: labelFrame)
                                labelButton?.addSubview(redEyePayLabel!)
                                if trip.info?.dutyPeriodsCount == trip.info?.calendarDaysCount {
                                    showingRedEyeIconForThisDay = true
                                    showingRedEyeIconForThisTrip = true
                                }else{
                                    showingRedEyeIconForThisDay = false
                                }
                            }
                        }
                    }
                    labelFrame.origin.x = CGFloat(dayIndex - buttonLength) * itemSize.width
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
                
                if trip.isRedEyeTrip && d == missingDateIndex && (self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) && trip.vacationOverlapType!.intValue > 0 {
                    redEyePayLabel?.textAlignment = .center
                    redEyePayLabel?.font = UIFont.boldSystemFont(ofSize: 12)
                    redEyePayLabel?.textColor = trip.highlightCount!.intValue > 0 ? CBColor.tripHighlightColor : .white
                }else{
                    redEyePayLabel = nil
                }
                if (self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) && trip.vacationOverlapType!.intValue > 0 && day.displayType!.intValue != BIDayDisplayType.normal.rawValue{
                    if day.displayType?.intValue == BIDayDisplayType.fullPay.rawValue{
                        if CBUtils.isClawBack(line: self.line!, day: day, bidPeriod: self.bidPeriod){
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
                        if self.bidPeriod.isFABid() && trip.isReserve{
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
                        }else if self.bidPeriod.isFABid(){
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
                        if (userDefaults.integer(forKey: kCBTimeZoneSetting) != CBTimeZoneSetting.herbTime.rawValue) || (trip.isReserve && self.bidPeriod.isFABid()){
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
                            
                            let timeZoneStr = CBUtils.rawTimeZoneString(forAirportCode: (dayInfo.orderedLegs.first)!.arriveCity!)!
                            let arriveDateStr = BITrip.staticTimeForReserveType(trip: trip, line: self.line!, key: "arrive", timeZone: timeZoneStr)
                            if arriveDateStr != nil {
                                timeLabel.text = arriveDateStr
                            }
                        }
                        if userDefaults.bool(forKey: "IsSelectedReporTimeForTripButton") == true{
                            timeLabel.text = String(format: "%04d", day.info!.releaseTime!.intValue % 2400)
                            if userDefaults.integer(forKey: kCBTimeZoneSetting) != CBTimeZoneSetting.herbTime.rawValue {
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
                        labelButton?.addSubview(timeLabel)
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
                        if userDefaults.integer(forKey: kCBTimeZoneSetting) != CBTimeZoneSetting.herbTime.rawValue {
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
                        if userDefaults.bool(forKey: "IsSelectedReporTimeForTripButton") == true{
                            timeLabel.text = String(format: "%04d", (day.info?.reportTime!.intValue)! % 2400)
                            if userDefaults.integer(forKey: kCBTimeZoneSetting) != CBTimeZoneSetting.herbTime.rawValue {
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
                        if !self.bidPeriod.isFABid() && trip.isReserve{
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
                        labelButton?.addSubview(timeLabel)
                        
                        if day.displayType?.intValue == BIDayDisplayType.normal.rawValue{
                            var xValue:CGFloat = 0.0
                            xValue = label.frame.origin.x + itemSize.width - 13
                            let weekDayInt = CBUtils.weekDay(from: trip.startDate!)
                            let isSaturday = (weekDayInt + d == 7)
                            if isSaturday{
                                xValue = fromScrachpadView == true ? xValue - 6 : xValue - 7
                            }
                            let verticalLabelFrame = CGRect(x: xValue, y: labelFrame.origin.y + 15, width: 26, height: 10)
                            
                            let verticalLabel = UILabel(frame: verticalLabelFrame)
                            verticalLabel.textColor = CBColor.cbGreen
                            verticalLabel.textAlignment = .center
                            verticalLabel.font = UIFont.boldSystemFont(ofSize: 9)
                            verticalLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-90.0 * .pi / 180.0))
                            verticalLabel.translatesAutoresizingMaskIntoConstraints = true
                            labelButton?.addSubview(verticalLabel)
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
                let hideVacation = userDefaults.bool(forKey: kCBHideVacationKey)
                if self.bidPeriod.isFABid() && !hideVacation && (day.displayType?.intValue != BIDayDisplayType.normal.rawValue) {
                    if day.displayType?.intValue == BIDayDisplayType.fullPay.rawValue {
                        if CBUtils.isClawBack(line: self.line!, day: day, bidPeriod: self.bidPeriod) {
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
                labelButton?.addSubview(label)
            }
        }
        if vacationButtons == nil {
            vacationButtons = NSMutableArray()
        }
        for case let view as UIView in vacationButtons! {
            view.removeFromSuperview()
        }
        vacationButtons?.removeAllObjects()
        vacationButtons?.addObjects(from: calendarData!.calendarDays as! [Any])
        if self.bidPeriod.containsVacay!.boolValue{
            var vacayButtonFrame = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
            var buttonImage:UIImage? = nil
            let vacations = self.bidPeriod.vacations
            for case let vacay as BIVacation in vacations! {
                var index = (self.calendarData?.indexForDate(date: vacay.startDate))!
                var tripLength = 0
                if index < 0 {
                    tripLength = vacay.length!.intValue + index
                    index = 0
                }else if index > (daysInCalendar - 1) {
                    continue
                }
                else{
                    tripLength = vacay.length!.intValue - 1
                }
                let column = index % 7
                var buttonLength = 0
                // If vacation pill will go across two rows in calendar, create both buttons.
                if column+tripLength > 7 {
                    buttonLength = 7 - column
//                    vacayButtonFrame.size.width = CGFloat(buttonLength) * itemSize.width
//                    buttonImage = UIImage(named: "TripButton-rounded-left-yellow_iOS7")?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                    buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.left))?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                    vacayButtonFrame.size.height = buttonHeight
                    vacayButtonFrame.size.width = min(CGFloat(tripLength), 7) * itemSize.width
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    vacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.6
                    self.calendarCollectionView.addSubview(button2)
                    
                    if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                        button2.isUserInteractionEnabled = true
                        button2.clipsToBounds = true
                        button2.isOpaque = false
                        button2.contentMode = .scaleToFill

//                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                        longPressGesture.minimumPressDuration = 0.5
//                        longPressGesture.cancelsTouchesInView = false
//                        button2.addGestureRecognizer(longPressGesture)
//                        longPressGesture.delegate = self
//                        vacayGestureRecognizers.add(longPressGesture)
                        addGestureRecognizersToVacationButton(button2)
                    }
                    tripLength -= buttonLength
                    index += buttonLength
                    while tripLength > 0 {
                        buttonLength = tripLength > 7 ? 7 : tripLength
                        
                        if index < daysInCalendar {
                            vacayButtonFrame.size.width = min(CGFloat(buttonLength), 7) * itemSize.width
                            if tripLength > 7{
                                vacayButtonFrame.size.width += 15
                            }
                            vacayButtonFrame.size.height = buttonHeight
//                            buttonImage = UIImage(named:"TripButton-rounded-right-yellow_iOS7")?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                            buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.right))?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                            let otherButton2 = UIImageView(frame: vacayButtonFrame)
                            otherButton2.image = buttonImage
                            vacationButtons?.replaceObject(at: index, with: otherButton2)
                            otherButton2.alpha = 0.6
                            self.calendarCollectionView.addSubview(otherButton2)
                                
                            if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                                otherButton2.isUserInteractionEnabled = true
                                otherButton2.isOpaque = false
                                otherButton2.clipsToBounds = true
                                otherButton2.contentMode = .scaleToFill

//                                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                                longPressGesture.minimumPressDuration = 0.5
//                                longPressGesture.cancelsTouchesInView = false
//                                otherButton2.addGestureRecognizer(longPressGesture)
//                                longPressGesture.delegate = self
//                                vacayGestureRecognizers.add(longPressGesture)
                                addGestureRecognizersToVacationButton(otherButton2)
                            }
                        }
                    tripLength -= buttonLength
                    index += buttonLength
                    }
                }
                else{// Vacation in one row only of the calendar.
                    if index < 0 {// Vacation starts before the visible calendar days, so show the rounded right image
//                        buttonImage = UIImage(named: "TripButton-rounded-right-yellow_iOS7")?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                        buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.right))?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                    }else if (index+tripLength-1) > (daysInCalendar-1){
                        // Vacay ends after the visible calendar days, so show the rounded left image
//                        buttonImage = UIImage(named: "TripButton-rounded-left-yellow_iOS7")?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                        buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.left))?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                    }else{
//                        buttonImage = UIImage(named: "TripButton-rounded-both-yellow_iOS7")?.resizableImage(withCapInsets: bothRoundedInsets, resizingMode: .stretch)
                        buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.both))?.resizableImage(withCapInsets: bothRoundedInsets, resizingMode: .stretch)
                    }
                    vacayButtonFrame.size.width = CGFloat(tripLength) * itemSize.width
                    vacayButtonFrame.size.height = buttonHeight
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    vacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.6
                    self.calendarCollectionView.addSubview(button2)
                    if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                        button2.isUserInteractionEnabled = true
                        button2.clipsToBounds = true
                        button2.isOpaque = false
                        button2.contentMode = .scaleToFill

//                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                        longPressGesture.minimumPressDuration = 0.5
//                        longPressGesture.cancelsTouchesInView = false
//                        //longPressGesture.numberOfTapsRequired = 0;
//                        button2.addGestureRecognizer(longPressGesture)
//                        longPressGesture.delegate = self
//                        vacayGestureRecognizers.add(longPressGesture)
                        addGestureRecognizersToVacationButton(button2)
                    }
                }
            }
        }
        if fvVacationButtons == nil {
            fvVacationButtons = NSMutableArray()
        }
        if cfvVacationButtons == nil {
            cfvVacationButtons = NSMutableArray()
        }
        for case let view as UIView in fvVacationButtons! {
            view.removeFromSuperview()
        }
        fvVacationButtons?.addObjects(from: calendarData!.calendarDays as! [Any])
        for case let view as UIView in cfvVacationButtons! {
            view.removeFromSuperview()
        }
        cfvVacationButtons?.addObjects(from: calendarData!.calendarDays as! [Any])
        
        for case let view in calendarCollectionView.subviews {
            if shouldRemoveCFV {
                if view.tag == 99 {
                    view.removeFromSuperview()
                }
            }
        }
        if self.bidPeriod.containsVacay!.boolValue {
            var vacayButtonFrame = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
            var buttonImage:UIImage? = nil
            let vacations = self.line?.fvvacations
            let arrVacationIndexes = NSMutableArray()
            let removeCFV = userDefaults.bool(forKey: "RemoveCfv")
            if (self.line?.cfvVacDates?.count) ?? 0 > 0{
                if !removeCFV {
                    shouldRemoveCFV = false
                    for i in 0..<(self.line?.cfvVacDates!.count)!{
                        let cfvDate = (self.line!.cfvVacDates![i] as! NSNumber).intValue
                        let cfv = UILabel()
                        cfv.backgroundColor = .darkGray
                        cfv.alpha = 1
                        cfv.tag = 99
                        cfv.text = "$FV"
                        cfv.textAlignment = .center
                        cfv.font = UIFont.boldSystemFont(ofSize: 14)
                        cfv.textColor = .white
                        let dateString = "\(cfvDate)-\(self.bidPeriod.month!)-\(self.bidPeriod.year!)"
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "d-M-yyyy"
                        let timeZone = TimeZone(abbreviation: "GMT")!
                        dateFormatter.timeZone = timeZone
                        let cfvDATE = dateFormatter.date(from: dateString)
                        let index = (self.calendarData?.indexForDate(date: cfvDATE))!
                        let indexPath1 = IndexPath(row: index + 1, section: 0)
                        let buttonLayoutAttributes1 = self.calendarCollectionView.layoutAttributesForItem(at: indexPath1)!
                        var vacayButtonFrame = buttonLayoutAttributes1.frame
                        vacayButtonFrame.size.width = itemSize.width
                        cfv.frame = vacayButtonFrame
                        cfv.layer.cornerRadius = cfv.frame.height/2
                        cfv.layer.masksToBounds = true
                        cfvVacationButtons?.replaceObject(at: index + 1, with: cfv)
                        self.calendarCollectionView.addSubview(cfv)
                    }
                }
            }
            for case let vacay as BIVacation in vacations!{
                var index = self.calendarData!.indexForDateGMT(date: vacay.fvStartdate!)
                if arrVacationIndexes.contains(index){
                    continue
                }
                arrVacationIndexes.add(index)
                
                var tripLength = 0
                if index < 0 {
                    tripLength = vacay.fvLength!.intValue + index
                }else if index > (daysInCalendar - 1) {
                    continue
                }else{
                    tripLength = vacay.fvLength!.intValue - 1
                }
                let column = index % 7
                var buttonLength = 0
                
                // If vacation pill will go across two rows in calendar, create both buttons.
                if column + tripLength > 7 {
                    buttonLength = 7 - column
                    vacayButtonFrame.size.width = itemSize.width * CGFloat(buttonLength)
                    buttonImage = UIImage(named:"TripButton-rounded-left-FVBlue_iOS7")?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                    vacayButtonFrame.size.width = min(CGFloat(tripLength), 7) * itemSize.width
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    fvVacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.7
                    self.calendarCollectionView.addSubview(button2)
                    if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                        button2.isUserInteractionEnabled = true
                        button2.clipsToBounds = true
                        button2.isOpaque = false
                        button2.contentMode = .scaleToFill

//                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                        longPressGesture.minimumPressDuration = 0.5
//                        longPressGesture.cancelsTouchesInView = false
//                        button2.addGestureRecognizer(longPressGesture)
//                        longPressGesture.delegate = self
//                        vacayGestureRecognizers.add(longPressGesture)
                        addGestureRecognizersToVacationButton(button2)
                    }
                    tripLength -= buttonLength
                    index += buttonLength
                    while tripLength > 0 {
                        buttonLength = tripLength > 7 ? 7 : tripLength
                        if index < daysInCalendar{
                            vacayButtonFrame.size.width = min(CGFloat(buttonLength), 7) * itemSize.width
                            if tripLength > 7 {
                                vacayButtonFrame.size.width += 15
                            }
                                buttonImage = UIImage(named:"TripButton-rounded-right-FVBlue_iOS7")?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                                let otherButton2 = UIImageView(frame: vacayButtonFrame)
                                otherButton2.image = buttonImage
                                fvVacationButtons?.replaceObject(at: index, with: otherButton2)
                                otherButton2.alpha = 0.7
                                self.calendarCollectionView.addSubview(otherButton2)
                                if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                                    otherButton2.isUserInteractionEnabled = true
                                    otherButton2.clipsToBounds = true
                                    otherButton2.isOpaque = false
                                    otherButton2.contentMode = .scaleToFill

//                                    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                                    longPressGesture.minimumPressDuration = 0.5
//                                    longPressGesture.cancelsTouchesInView = false
//                                    otherButton2.addGestureRecognizer(longPressGesture)
//                                    longPressGesture.delegate = self
//                                    vacayGestureRecognizers.add(longPressGesture)
                                    addGestureRecognizersToVacationButton(otherButton2)
                                }
                            }
                            tripLength -= buttonLength
                            index += buttonLength
                        }
                    }
                else{ // Vacation in one row only of the calendar.
                    if index < 0 {
                        // Vacation starts before the visible calendar days, so show the rounded right image
                        buttonImage = UIImage(named: "TripButton-rounded-right-FVBlue_iOS7")?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
                    }else if (index + tripLength - 1) > (daysInCalendar - 1) {
                        // Vacay ends after the visible calendar days, so show the rounded left image
                        buttonImage = UIImage(named: "TripButton-rounded-left-FVBlue_iOS7")?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
                    }else{
                        buttonImage = UIImage(named: "TripButton-rounded-both-FVBlue_iOS7")?.resizableImage(withCapInsets: bothRoundedInsets, resizingMode: .stretch)
                    }
                    vacayButtonFrame.size.width = CGFloat(tripLength) * itemSize.width
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    fvVacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.7
                    self.calendarCollectionView.addSubview(button2)
                    if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                        button2.isUserInteractionEnabled = true
                        button2.clipsToBounds = true
                        button2.isOpaque = false
                        button2.contentMode = .scaleToFill

//                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                        longPressGesture.minimumPressDuration = 0.5
//                        longPressGesture.cancelsTouchesInView = false
//                        button2.addGestureRecognizer(longPressGesture)
//                        longPressGesture.delegate = self
//                        vacayGestureRecognizers.add(longPressGesture)
                        addGestureRecognizersToVacationButton(button2)
                    }
                }
            }
        }
//        if (self.bidPeriod.myCalEnabled?.boolValue == true) && self.bidPeriod.isNeedToShowMyCal() && (self.line?.bidOrder == 0) {
//            var vacayButtonFrame = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
//            var buttonImage:UIImage? = nil
//            var index = self.calendarData!.indexForDateGMT(date: (self.bidPeriod.myCalStartDate)!)
//            let length = self.calculateLengthBetween(startDate: (self.bidPeriod.myCalStartDate)!, endDate: (self.bidPeriod.myCalEndDate)!)
//            var tripLength = 0
//            if index < 0 {
//                tripLength = length.intValue + index
//            }else if index > (daysInCalendar - 1){
//                tripLength = 0
//            }else{
//                tripLength = length.intValue
//            }
//            let column = index % 7
//            var buttonLength = 0
//         
//            
//            // If vacation pill will go across two rows in calendar, create both buttons.
//            if column + tripLength > 7 {
//                buttonLength = 7 - column
//                vacayButtonFrame.size.width = CGFloat(buttonLength) * itemSize.width
//                buttonImage = UIImage(named: "TripButton-rounded-left-red2_iOS7")?.resizableImage(withCapInsets: leftRoundedInsets, resizingMode: .stretch)
//                vacayButtonFrame.size.width = min(CGFloat(tripLength), 7) * itemSize.width
//                let button2 = UIImageView(frame: vacayButtonFrame)
//                button2.image = buttonImage
//                fvVacationButtons?.replaceObject(at: index, with: button2)
//                button2.alpha = 0.5
//                self.calendarCollectionView.addSubview(button2)
//                
//                if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
//                    button2.isUserInteractionEnabled = true
//                    button2.isOpaque = false
//                    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                    longPressGesture.minimumPressDuration = 0.5
//                    longPressGesture.cancelsTouchesInView = false
//                    button2.addGestureRecognizer(longPressGesture)
//                    longPressGesture.delegate = self
//                    vacayGestureRecognizers.add(longPressGesture)
//                }
//                tripLength -= buttonLength
//                index += buttonLength
//                while tripLength > 0 {
//                    buttonLength = tripLength > 7 ? 7 :tripLength
//                    if index < daysInCalendar {
//                        vacayButtonFrame.size.width = min(CGFloat(buttonLength), 7) * itemSize.width
//                        
//                        if tripLength > 7{
//                            vacayButtonFrame.size.width += 15
//                        }
//                        buttonImage = UIImage(named: "TripButton-rounded-right-red2_iOS7")?.resizableImage(withCapInsets: rightRoundedInsets, resizingMode: .stretch)
//                        let otherButton2 = UIImageView(frame: vacayButtonFrame)
//                        otherButton2.image = buttonImage
//                        fvVacationButtons?.replaceObject(at: index, with: otherButton2)
//                        otherButton2.alpha = 0.5
//                        self.calendarCollectionView.addSubview(otherButton2)
//                        if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
//                            otherButton2.isUserInteractionEnabled = true
//                            otherButton2.isOpaque = false
//                            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                            longPressGesture.minimumPressDuration = 0.5
//                            longPressGesture.cancelsTouchesInView = false
//                            button2.addGestureRecognizer(longPressGesture)
//                            longPressGesture.delegate = self
//                            vacayGestureRecognizers.add(longPressGesture)
//                        }
//                    }
//                    tripLength -= buttonLength
//                    index += buttonLength
//                }
//            }
//            else{// Vacation in one row only of the calendar.
//                buttonImage = UIImage(named: "TripButton-rounded-both-red2_iOS7")?.resizableImage(withCapInsets: bothRoundedInsets, resizingMode: .stretch)
//                vacayButtonFrame.size.width = CGFloat(tripLength) * itemSize.width
//                let button2 = UIImageView(frame: vacayButtonFrame)
//                button2.image = buttonImage
//                fvVacationButtons?.replaceObject(at: index, with: button2)
//                button2.alpha = 0.5
//                self.calendarCollectionView.addSubview(button2)
//                
//                if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
//                    button2.isUserInteractionEnabled = true
//                    button2.isOpaque = false
//                    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                    longPressGesture.minimumPressDuration = 0.5
//                    longPressGesture.cancelsTouchesInView = false
//                    button2.addGestureRecognizer(longPressGesture)
//                    longPressGesture.delegate = self
//                    vacayGestureRecognizers.add(longPressGesture)
//                }
//            }
//        }
        self.calendarCollectionView.reloadData()
        self.calendarCollectionView.tripButtons = tripButtons
        self.calendarCollectionView.vacationButtons = vacationButtons
        self.calendarCollectionView.fvVacationButtons = fvVacationButtons
        self.calendarCollectionView.cfvVacationButtons = cfvVacationButtons
    }
    
    @objc func showSWAPtimizerTripOptionsPopover(_ gesture: UILongPressGestureRecognizer) {
        
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if bidPeriod.containsVacay!.boolValue && (self.bidPeriod.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
            if vacayGestureRecognizers.contains(gestureRecognizer) {
                var touchInsideVacayButton = false
                let count = vacationButtons?.count
                for i in 0 ..< count! {
                    var vButton: Any!
                    vButton = vacationButtons![i]
                    if let vButton = vButton as? UIImageView {
                        if vButton.frame.contains(touch.location(in: self.calendarCollectionView)) {
                            touchInsideVacayButton = true
                        }
                    }
                }
                let FVcount = fvVacationButtons?.count
                for i in 0 ..< FVcount! {
                    var vButton: Any!
                    vButton = fvVacationButtons![i]
                    if let vButton = vButton as? UIImageView {
                        if vButton.frame.contains(touch.location(in: self.calendarCollectionView)) {
                            touchInsideVacayButton = true
                        }
                    }
                }
                if touchInsideVacayButton {
                    // Check to make sure it wasn't a touch on one of the tripButtons inside the vacayButton
                    let count = self.tripButtons?.count
                    for i in 0 ..< count! {
                        if let tripButton = self.tripButtons![i] as? CBTripButton {
                            if tripButton.frame.contains(touch.location(in: self.calendarCollectionView)) {
                                self.tripButtonAction(tripButton)
                                return false
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    func calculateLengthBetween(startDate: Date, endDate: Date) -> NSNumber {
        let calendar = Calendar.current
        let timeZone = TimeZone(identifier: "GMT")

        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.timeZone = timeZone

        let startDateStr = formatter.string(from: startDate)
        let endDateStr = formatter.string(from: endDate)

        guard let newStartDate = formatter.date(from: startDateStr),
              let newEndDate = formatter.date(from: endDateStr) else {
            return 0
        }

        let components = calendar.dateComponents([.day], from: newStartDate, to: newEndDate)
        let length = abs(components.day ?? 0) + 1 // include both start and end date

        return NSNumber(value: length)
    }
    
    
    
    @objc func tripButtonAction(_ tripButton: CBTripButton) {
        tripButtonActionBlock!(tripButton)
    }
    
    
    // Function to handle insert line here and marker
    func HandleInsertLineHere()   {
        let Devicewidth = UIScreen.main.bounds.width/2 - 25
        lblInsertLineHere.isHidden = true
        txtMarker.isHidden = true
        txtMarker.delegate = self
        let placeholderText = "Untitled Marker."
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        txtMarker.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        markerTextField = txtMarker
        txtMarker.backgroundColor = .darkGray
        imgAccessoryView.isHidden = false
        let type = Int((cellType?.rawValue)!)
        
        switch type {
        case CBBidLineTableCellType.cbPlainBidLineTableCellType.rawValue:
            lblInsertLineHere.isHidden = true
            mainTopViewOffset = Int(0.0)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 12)  , width: 24, height: 24)
            break
        case CBBidLineTableCellType.cbInsertAboveBidLineTableCellType.rawValue:
            lblInsertLineHere.isHidden = false
            lblInsertLineHere.frame = CGRect(x: 0.0, y: 0.0, width: Devicewidth, height: kCBBidLineTableCellInsertionHeight)
            let a = lblInsertLineHere
            self.addSubview(a!)
            mainTopViewOffset = Int(kCBBidLineTableCellInsertionHeight)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 24)  , width: 24, height: 24)
            break
        case CBBidLineTableCellType.cbInsertBelowBidLineTableCellType.rawValue:
            mainTopViewOffset = Int(0.0)
            lblInsertLineHere.isHidden = false
            lblInsertLineHere.frame = CGRect(x: 0.0, y: kCBBidLineTableCellMainViewHeightCalendarView , width: Devicewidth, height: kCBBidLineTableCellInsertionHeight)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 24)  , width: 24, height: 24)
            break
        case CBBidLineTableCellType.cbMarkerBidLineTableCellType.rawValue:
            txtMarker.isHidden = false
            mainTopViewOffset = Int(0.0)
            txtMarker.frame =  CGRect(x: 0.0, y: kCBBidLineTableCellMainViewHeightCalendarView , width: Devicewidth, height: kCBBidLineTableCellInsertionHeight)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 24)  , width: 24, height: 24)
            break
        case CBBidLineTableCellType.cbMarkerInsertAboveBidLineTableCellType.rawValue:
            txtMarker.isHidden = false
            lblInsertLineHere.isHidden = false
            lblInsertLineHere.frame = CGRect(x: 0.0, y: 0.0 , width: Devicewidth, height: kCBBidLineTableCellInsertionHeight)
            let a = lblInsertLineHere
            self.addSubview(a!)
            txtMarker.frame =  CGRect(x: 0.0, y: kCBBidLineTableCellMainViewHeightCalendarView , width: Devicewidth, height: kCBBidLineTableCellInsertionHeight)
            mainTopViewOffset = Int(kCBBidLineTableCellInsertionHeight)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 36)  , width: 24, height: 24)
            break
        case CBBidLineTableCellType.cbMarkerInsertBelowBidLineTableCellType.rawValue:
            mainTopViewOffset = Int(0.0)
            txtMarker.isHidden = false
            lblInsertLineHere.isHidden = false
            lblInsertLineHere.frame = CGRect(x: 0.0, y: kCBBidLineTableCellMainViewHeightCalendarView , width: Devicewidth, height: kCBBidLineTableCellInsertionHeight)
            lblInsertLineHere.frame = CGRect(x: 0.0, y: kCBBidLineTableCellMainViewHeightCalendarView + kCBBidLineTableCellInsertionHeight , width: Devicewidth, height: kCBBidLineTableCellInsertionHeight)
            txtMarker.frame =  CGRect(x: 0.0, y: kCBBidLineTableCellMainViewHeightCalendarView , width: Devicewidth, height: kCBBidLineTableCellInsertionHeight)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 36)  , width: 24, height: 24)
            break
            
        default:
            break
        }
        
        
        // Update the contentView frame.
        var newFrame: CGRect = mainView.frame
        newFrame.origin.y = CGFloat(mainTopViewOffset)
        newFrame.size.width = self.frame.width
        mainView.frame = newFrame
    }
    
    
    
    
    
    
}

extension CBBidListCalenderViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bidListCellCalendarDaysArr.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSizeMake((self.contentView.frame.width - 160)/7, 45)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell12", for: indexPath) as! InnerCollectionViewCell
        cell.contentView.frame = cell.bounds
        cell.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let calendarDay = bidListCellCalendarDaysArr[indexPath.row] as! BICalendarDay
        cell.dayLabel.text = calendarDay.text
        let currentMonth = calendarDay.isCurrentMonth
        if currentMonth {
            cell.dayLabel.alpha = 1
        } else {
            cell.dayLabel.alpha = 0.5
        }
        return cell
    }
    
    func addGestureRecognizersToVacationButton(_ button: UIView) {
        let doubleTap = UITapGestureRecognizer(target: self,
                                               action: #selector(handleVacationDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        button.addGestureRecognizer(doubleTap)
        vacayGestureRecognizers.add(doubleTap)
    }
    @objc private func handleVacationDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }
            vacationDoubleTapActionBlock?(tappedView)
    }
}
