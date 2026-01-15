//
//  CBBidlineViewTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit


var CBBidLineTableCellDidSelectNotification = "CBBidLineTableCellDidSelectNotification"
var CBBidLineTableCellDidDeselectNotification = "CBBidLineTableCellDidDeselectNotification"
var kCBBidLineTableCellMainViewHeight: CGFloat = 57.0
var kCBBidLineTableCellMainViewHeightCalendarView: CGFloat = 273
var kCBBidLineTableCellInsertionHeight: CGFloat = 24.0
var kCBBidLineTableCellMarkerHeight: CGFloat = 24.0

@objc enum CBBidLineTableCellType : Int {
    case cbPlainBidLineTableCellType
    case cbInsertAboveBidLineTableCellType
    case cbInsertBelowBidLineTableCellType
    case cbMarkerBidLineTableCellType
    case cbMarkerInsertAboveBidLineTableCellType
    case cbMarkerInsertBelowBidLineTableCellType
    case cbInsertAboveMarkerBidLineTableCellType
    
    func name () -> Int {
        switch self
        {
        case .cbPlainBidLineTableCellType: return 1 << 1
        case .cbInsertAboveBidLineTableCellType: return 1 << 2
        case .cbInsertBelowBidLineTableCellType: return 1 << 3
        case .cbMarkerBidLineTableCellType: return 1 << 4
        case .cbMarkerInsertAboveBidLineTableCellType: return 1 << 5
        case .cbMarkerInsertBelowBidLineTableCellType: return 1 << 6
        case .cbInsertAboveMarkerBidLineTableCellType: return 1 << 7
        }
    }
    
}
enum CBCalendarTripDayType : Int {
    case cbCalendarTripDayNone = 0
    case cbCalendarTripDayStart
    case cbCalendarTripDayMiddle
    case cbCalendarTripDayEnd
    case cbCalendarTripDaySingle
}

class CBBidlineViewTableViewCell: UITableViewCell, UITextFieldDelegate,UICollectionViewDelegate, UICollectionViewDataSource,CBUserFlagTableControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {


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
    var cellType = CBBidLineTableCellType(rawValue: 0)
    var markerAtTop = false
    weak var userFlagIconView: UIView?
    var bidPeriod: BIBidPeriod!
    var line = BILine(context: CoreDataManager.shared.managedObjectContext)
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
        positionCircleView.layer.cornerRadius = positionCircleView.frame.size.height / 2
        
        var newFrame = CGRect ()
        for i in 0..<5 {
            var lineValueView = CBLineValueView(frame: CGRect.zero)
            lineValueView = lineValueView.initWithFrame(aRect: CGRect.zero)
            newFrame = CGRect(x: CGFloat(kLineValuesHorizOffset + i * kLineValuesHorizSpacing), y:CGFloat(kLineValuesVertOffset), width: 55.0, height: 28.0)
            lineValueView.frame = newFrame
            lineValueView.tag = LineValueViewTag + i * 10
            lineValuesView.addSubview(lineValueView)
        }
        
        // linevalues gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self , action: #selector(self.longPressLineValueContainerView))
        longPressGesture.minimumPressDuration = 0.3
        scrollLineValue.addGestureRecognizer(longPressGesture)
        longPressGesture.delegate = self
        longPressGesture.delaysTouchesBegan = true
        
        // Selection button.
        selectionToggleButton.setImage(#imageLiteral(resourceName: "radioButton-Off"), for: .normal)
        selectionToggleButton.setImage(#imageLiteral(resourceName: "RadioButton-On"), for: .selected)
        selectionToggleButton.addTarget(self, action: #selector(self.selectionButtonAction), for: .touchUpInside)
        
        // Snowflake
        let snowflake = viewWithTag(kSnowflakeTag) as? UIImageView
        let snowflakeImage = UIImage(named: "Blue_Snowflake")
        snowflake?.image = snowflakeImage
        snowflake?.alpha = 0.0
        
        let iconControl: UIControl? = CBUserFlagTableController.userFlagControlForColor(color: UIColor.clear, diameter: 20.0)
        iconControl?.frame = CGRect(x: 3.0, y: 38.0, width: 20.0, height: 20.0)
        iconControl?.addTarget(self, action: #selector(showUserFlagMenu), for: .touchUpInside)
        if let aControl = iconControl {
            mainView.addSubview(aControl)
        }
        userFlagControl = iconControl
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        markerTextField.delegate = self
        HandleInsertLineHere()
        self.accessoryType = .none
    }
    
    
    func setMarkerText(_ text: String?) {
        markerTextField.text = text
    }

    func beginEditingMarker() {
        markerTextField.becomeFirstResponder()
    }
    
    func selectButton(_ selected: Bool) {
        if selected {
            selectionToggleButton.setImage(#imageLiteral(resourceName: "RadioButton-On"), for: .normal)
        }
        else {
            selectionToggleButton.setImage(#imageLiteral(resourceName: "radioButton-Off"), for: .normal)
        }
    }
    
    func handlingFreezingCondition()  {
        imgAccessoryView.isHidden = false
        if (line.isFrozen != 0) {
            let snowflakeImage = UIImage(named: "Blue_Snowflake")
            imgAccessoryView?.image = snowflakeImage
            mLblLineNumber.textColor = UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0)
            
            if line.isETOPS?.boolValue == true{
                let attributedString = NSMutableAttributedString(string: mLblLineNumber.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNumber.text!.count - 1, 1)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNumber.attributedText = attributedString
                
            }
            if line.isETOPSRES?.boolValue == true{
                let attributedString = NSMutableAttributedString(string: mLblLineNumber.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNumber.text!.count - 2, 2)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNumber.attributedText = attributedString
            }
            else if bidPeriod.isFABid() && bidPeriod.isSecondRoundBid() {
                if line.faReserveLineType == (BIFaReserveLineType.SnrAMres.rawValue) as NSNumber || line.faReserveLineType == (BIFaReserveLineType.SnrPMres.rawValue) as NSNumber || line.faReserveLineType == (BIFaReserveLineType.JnrAMres.rawValue) as NSNumber || line.faReserveLineType == (BIFaReserveLineType.JnrPMres.rawValue) as NSNumber || line.faReserveLineType == (BIFaReserveLineType.JnrLateRes.rawValue) as NSNumber{
                    let attributedString = NSMutableAttributedString(string: mLblLineNumber.text!)
                    let lastCharacterRange = NSMakeRange( mLblLineNumber.text!.count - 2, 2)
                    if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                    } else {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                    }
                    mLblLineNumber.attributedText = attributedString
                }
            }
           else if line.type == BILineType.ReserveLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsReserve.rawValue.asNSNumber{
                let attributedString = NSMutableAttributedString(string: mLblLineNumber.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNumber.text!.count - 1, 1)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
               mLblLineNumber.attributedText = attributedString
            }
           else if !bidPeriod.isFABid() && bidPeriod.isSecondRoundBid() && (line.type == BILineType.MixedLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsMixed.rawValue.asNSNumber){
                let attributedString = NSMutableAttributedString(string: mLblLineNumber.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNumber.text!.count - 2, 2)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
               mLblLineNumber.attributedText = attributedString
            }
            
            
            let button = viewWithTag(kSelectionButtonTag) as? UIButton
            button?.isHidden = true
            selectionToggleButton.isHidden = true
            self.isEditing = false
        } else {
            let snowflakeImage = UIImage(named: "Blue_SnowflakeEmpty")
            imgAccessoryView?.image = snowflakeImage
            imgAccessoryView.isHidden = true
            let button = viewWithTag(kSelectionButtonTag) as? UIButton
            button?.isHidden = false
            if bidPeriod.isFABid() && line.faPosition?.intValue != BIFaPosition.FaPositionNA.rawValue {
                mLblLineNumber.textColor = UIColor.white
            }else {
                mLblLineNumber.textColor = UIColor.label
            }
            if line.isETOPS?.boolValue == true{
                let attributedString = NSMutableAttributedString(string: mLblLineNumber.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNumber.text!.count - 1, 1)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNumber.attributedText = attributedString
            }
            if line.isETOPSRES?.boolValue == true{
                let attributedString = NSMutableAttributedString(string: mLblLineNumber.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNumber.text!.count - 2, 2)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNumber.attributedText = attributedString
            }
            else if bidPeriod.isFABid() && bidPeriod.isSecondRoundBid() {
                if line.faReserveLineType == (BIFaReserveLineType.SnrAMres.rawValue) as NSNumber || line.faReserveLineType == (BIFaReserveLineType.SnrPMres.rawValue) as NSNumber || line.faReserveLineType == (BIFaReserveLineType.JnrAMres.rawValue) as NSNumber || line.faReserveLineType == (BIFaReserveLineType.JnrPMres.rawValue) as NSNumber || line.faReserveLineType == (BIFaReserveLineType.JnrLateRes.rawValue) as NSNumber{
                    let attributedString = NSMutableAttributedString(string: mLblLineNumber.text!)
                    let lastCharacterRange = NSMakeRange( mLblLineNumber.text!.count - 2, 2)
                    if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                    } else {
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                    }
                    mLblLineNumber.attributedText = attributedString
                }
            }
            else if line.type == BILineType.ReserveLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsReserve.rawValue.asNSNumber{
                let attributedString = NSMutableAttributedString(string: mLblLineNumber.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNumber.text!.count - 1, 1)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNumber.attributedText = attributedString
            }
            else if !bidPeriod.isFABid() && bidPeriod.isSecondRoundBid() && (line.type == BILineType.MixedLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsMixed.rawValue.asNSNumber){
                let attributedString = NSMutableAttributedString(string: mLblLineNumber.text!)
                let lastCharacterRange = NSMakeRange( mLblLineNumber.text!.count - 2, 2)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: lastCharacterRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: lastCharacterRange)
                }
                mLblLineNumber.attributedText = attributedString
            }
            
            
            
            selectionToggleButton.isHidden = false
            self.isEditing = true
        }
    }

    func HandleInsertLineHere(){
        let Devicewidth = self.contentView.frame.width
        lblInsertLineHere.isHidden = true
        txtMarker.isHidden = true
        txtMarker.delegate = self
        txtMarker.returnKeyType = .done
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
            lblInsertLineHere.frame = CGRect(x: 0.0, y: 0.0, width: Devicewidth + 50, height: kCBBidLineTableCellInsertionHeight)
            let a = lblInsertLineHere
            self.addSubview(a!)
            mainTopViewOffset = Int(kCBBidLineTableCellInsertionHeight)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 24)  , width: 24, height: 24)
            break
        case CBBidLineTableCellType.cbInsertBelowBidLineTableCellType.rawValue:
            mainTopViewOffset = Int(0.0)
            lblInsertLineHere.isHidden = false
            lblInsertLineHere.frame = CGRect(x: 0.0, y: 65 , width: Devicewidth + 50, height: kCBBidLineTableCellInsertionHeight)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 24)  , width: 24, height: 24)
            break
        case CBBidLineTableCellType.cbMarkerBidLineTableCellType.rawValue:
            txtMarker.isHidden = false
            mainTopViewOffset = Int(0.0)
            txtMarker.frame =  CGRect(x: 0.0, y: 65 , width: Devicewidth + 50, height: kCBBidLineTableCellInsertionHeight)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 24)  , width: 24, height: 24)
            break
        case CBBidLineTableCellType.cbMarkerInsertAboveBidLineTableCellType.rawValue:
            txtMarker.isHidden = false
            lblInsertLineHere.isHidden = false
            lblInsertLineHere.frame = CGRect(x: 0.0, y: 0.0, width: Devicewidth + 50, height: kCBBidLineTableCellInsertionHeight)
            let a = lblInsertLineHere
            self.addSubview(a!)
            txtMarker.frame =  CGRect(x: 0.0, y: kCBBidLineTableCellMainViewHeight , width: Devicewidth + 50 , height: kCBBidLineTableCellInsertionHeight)
            mainTopViewOffset = Int(kCBBidLineTableCellInsertionHeight)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 36)  , width: 24, height: 24)
            break
        case CBBidLineTableCellType.cbMarkerInsertBelowBidLineTableCellType.rawValue:
            mainTopViewOffset = Int(0.0)
            txtMarker.isHidden = false
            lblInsertLineHere.isHidden = false
            lblInsertLineHere.frame = CGRect(x: 0.0, y: 65 , width: Devicewidth + 50, height: kCBBidLineTableCellInsertionHeight)
            lblInsertLineHere.frame = CGRect(x: 0.0, y: 65 + kCBBidLineTableCellInsertionHeight , width: Devicewidth + 50, height: kCBBidLineTableCellInsertionHeight)
            txtMarker.frame =  CGRect(x: 0.0, y: 65 , width: Devicewidth + 50, height: kCBBidLineTableCellInsertionHeight)
            imgAccessoryView.frame =  CGRect(x: Devicewidth - 34 , y: ((contentView.bounds.height/2) - 36)  , width: 24, height: 24)
            for view in subviews where view.description.contains("Reorder") {
                for case let subview as UIImageView in view.subviews {
                    subview.frame = CGRect(x: 0 , y: 25, width: 27, height: 15)
                }
            }
            break
        default:
            break
        }
        
        var newFrame: CGRect = mainView.frame
        newFrame.origin.y = CGFloat(mainTopViewOffset)
        newFrame.size.width = self.frame.width
        mainView.frame = newFrame
    }
    
    // Function to handle selection button action
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bidListCellCalendarDaysArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MiniCalendarCell", for: indexPath) as? CBCalendarDayCell
        if (calendarTripDayTypes?.count)! != 0 {
            if let cellType: CBCalendarTripDayType = calendarTripDayTypes?.object(at: indexPath.item) as? CBCalendarTripDayType {
                cell?.type = cellType
            }
        }
        if (calendarTripDayColors?.count)! != 0 {
            if let cellColor: UIColor = calendarTripDayColors?.object(at: indexPath.item) as? UIColor {
                cell?.color = cellColor
            }
        }
        
        cell?.setNeedsDisplay()
        return cell!
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
    
    
    @objc func longPressLineValueContainerView(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBLineValuesMenuController") as! CBLineValuesMenuController
        lineValuesController.bidPeriod = bidPeriod;
        lineValuesController.modalPresentationStyle = .popover
        let touchPoint = gesture.location(in: self.contentView)
//        let frame = CGRect(origin: touchPoint, size: CGSize(width: 1, height: 1))
        let frame = CGRect(x: self.contentView.frame.origin.x, y: touchPoint.y - 80, width: self.contentView.frame.width, height: self.contentView.frame.height)
        lineValuesController.showPopover(sourceView: scrollLineValue, sourceRect: frame)
    }
    
    @objc func showUserFlagMenu() {
        DispatchQueue.main.async{
            let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
            let flagVC = storyboard.instantiateViewController(withIdentifier: "CBUserFlagTableController") as! CBUserFlagTableController
            flagVC.delegate = self
            flagVC.modalPresentationStyle = .popover
            flagVC.line = self.line
            flagVC.showPopover(sourceView: self.userFlagControl)
        }
    }
    
    @objc func handleTapGesture(_ tapGesture: UITapGestureRecognizer) {
        let refreshViewController = UIStoryboard(name: "BidDocument", bundle: nil).instantiateViewController(withIdentifier: "CBLineCalendarCollectionViewController") as! CBLineCalendarCollectionViewController
        refreshViewController.line = line
        refreshViewController.numberofRows = numberOfCalendarRows(year: CBGlobalMethods.shared.selectedBidPeriod!.year!.intValue, month: CBGlobalMethods.shared.selectedBidPeriod!.month!.intValue)
        refreshViewController.bidPeriod = bidPeriod
        refreshViewController.CollectionCellCalendarDaysArr = bidListCellCalendarDaysArr
        refreshViewController.calendarData = calendarData
        refreshViewController.fromScrachpadView = true
        let lineNumber: Int = self.line.number as! Int
        let title = String(format: "%@%d", "Line ",lineNumber)
        refreshViewController.navigationItem.title = title
        let navigationController = UINavigationController(rootViewController: refreshViewController)
        navigationController.delegate = self
        navigationController.navigationBar.isTranslucent = false
        refreshViewController.showPopover(withNavigationController: self, sourceRect: self.calendarCollectionView.frame)
    }
    
    
    func refreshCalendar()  {
        
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
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
            calendarCollectionView.addGestureRecognizer(tapGesture)
            self.tapGesture = tapGesture
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
            }
        }
        
        let trips = line.trips
        
        
        for case let trip as BITrip in trips!{
            
            let tripOption = UserDefaults.standard.object(forKey: kCBVacationOverlapTripDisplayOption)
            if (bidPeriod.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) && (tripOption != nil) {
                if BIVacationOverlapTripOption.dropAll.rawValue == Int(tripOption as! Int) && (trip.vacationOverlapType?.intValue)! > 0 {
                    continue
                }
                else if Int(tripOption as! Int) == trip.vacationOverlapType?.intValue {
                    continue
                }
            }
            
            
            let startIndex: Int = calendarData!.indexForDate(date: trip.startDate! as Date)
            
            // Account for nil pairings showing up in the blank lines
            if startIndex > (daysInCalendar - 1) || startIndex < 0 {
                continue
            }
            // Color of trip cell.
            var color: UIColor? = nil
            if bidPeriod.isFABid() && trip.isReserve {
                if BIFaReserveLineType.SnrAMres.rawValue == line.faReserveLineType?.intValue {
                    color = CBColor.green
                }
                else if BIFaReserveLineType.SnrPMres.rawValue == line.faReserveLineType?.intValue {
                    color = CBColor.tripButtonredColor
                }
                else if BIFaReserveLineType.JnrAMres.rawValue == line.faReserveLineType?.intValue {
                    color = CBColor.lightGreenColor
                }
                else if BIFaReserveLineType.JnrPMres.rawValue == line.faReserveLineType?.intValue {
                    color = CBColor.lightTripButtonRedColor
                }
                else {
                    color = CBColor.brown
                }
            }
            else {
                if trip.isAM() {
                    if trip.isReserve {
                        color = CBColor.green
                    }
                    else {
                        color = CBColor.orange
                    }
                }
                else {
                    if trip.isReserve {
                        color = CBColor.tripButtonredColor
                    }
                    else {
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
                if 1 == tripLength {
                    calendarTripDayTypes?.replaceObject(at: startIndex + i, with: CBCalendarTripDayType.cbCalendarTripDaySingle)
                } else if 0 == i {
                    calendarTripDayTypes?.replaceObject(at: startIndex + i, with: CBCalendarTripDayType.cbCalendarTripDayStart)
                } else if tripLength - 1 == i {
                    if (startIndex + i) < (calendarTripDayTypes?.count)! {
                        calendarTripDayTypes?.replaceObject(at: startIndex + i, with: CBCalendarTripDayType.cbCalendarTripDayEnd)
                    }
                } else {
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
 
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.markerTextField.resignFirstResponder()
        return true
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField)
    {
        markerViewHeightConstraint?.constant = 32.0
        markerTextField.isHidden = false
        markerTextFieldBaselineConstraint?.constant = 11.0
        markerTextFieldHeightConstraint?.constant = -6.0
        textField.borderStyle = .roundedRect
        textField.backgroundColor = UIColor.white
        textField.textColor = CBColor.purpleColor
        markerTextField.becomeFirstResponder()
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text ?? ""
        self.markerViewHeightConstraint?.constant = kCBBidLineTableCellMarkerHeight
        self.markerTextField.isHidden = false
        self.markerTextFieldBaselineConstraint?.constant = 6
        self.markerTextFieldHeightConstraint?.constant = 0
        textField.borderStyle = .none
        textField.backgroundColor = .darkGray
        textField.textColor = .white
        self.line.markerTitle = text
        self.bidPeriod.managedObjectContext?.processPendingChanges()
        self.bidPeriod.managedObjectContext?.undoManager?.removeAllActions()
    }
    public func textFieldShouldClear(_ textField: UITextField) -> Bool
    {
        textField.text = ""
        
        return true
    }
    
    func numberOfCalendarRows(year: Int, month: Int) -> Int {
        let calendar = Calendar.current

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        let firstDate = calendar.date(from: components)!
        let weekday = calendar.component(.weekday, from: firstDate) // Sunday = 1

        var leadingDays = weekday - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDate)!.count

        // 🔴 Special February rule:
        // If Jan 31 is Saturday, show full Jan week
        if month == 2 {
            let jan31 = calendar.date(from: DateComponents(year: year, month: 1, day: 31))!
            let jan31Weekday = calendar.component(.weekday, from: jan31)

            if jan31Weekday == 7 { // Saturday
                leadingDays = 7
            }
        }

        let filledDays = leadingDays + daysInMonth

        var trailingDays = (7 - (filledDays % 7)) % 7

        // Minimum 3 next-month days
        if trailingDays < 3 {
            trailingDays += 7
        }

        let totalDays = leadingDays + daysInMonth + trailingDays
        return totalDays / 7
    }


}
