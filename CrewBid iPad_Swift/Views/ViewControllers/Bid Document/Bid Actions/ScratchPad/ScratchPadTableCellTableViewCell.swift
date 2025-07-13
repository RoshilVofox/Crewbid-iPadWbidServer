//
//  ScratchPadTableCellTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 15/04/25.
//

import UIKit
import CoreData

var kCBLineValueViewWidth : CGFloat = 55.0
var kCBLineValueViewHeight : CGFloat = 28.0

var CBLineTableCellFABidLineNotification = "CBLineTableCellFABidLineNotification"
var CBLineTableCellBidLineNotification = "CBLineTableCellBidLineNotification"
var CBLineTableCellBidLineKey = "CBLineTableCellBidLineKey"
var CBLineTableCellPositionKey = "CBLineTableCellPositionKey"
var CBLineTableCellButtonViewKey = "CBLineTableCellButtonViewKey"
var CBLineTableCellIndexPathKey = "CBLineTableCellIndexPathKey"
var CBLinesTableBidLinesNotification = "CBLinesTableBidLinesNotification"
var CBLinesTableBidLinesArrayKey = "CBLinesTableBidLinesArrayKey"

class ScratchPadTableCellTableViewCell: UITableViewCell,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout, CBUserFlagTableControllerDelegate {
    func changeLineUserFlagTypeTo(flagType: CBUserFlagType, selectedLine: BILine?) {
        if CBGlobalMethods.shared.selectedBidPeriod!.isFABid() {
            for case let tempLine as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
                if selectedLine != nil {
                    if (selectedLine!.number == tempLine.number) && (tempLine.bidOrder == 0){
                        tempLine.userFlagType = flagType.rawValue as NSNumber
                    }
                }
            }
        }else{
            if selectedLine != nil {
                selectedLine!.userFlagType = flagType.rawValue as NSNumber
            }
        }
        
        var sortRule = (CBGlobalMethods.shared.selectedBidPeriod!.lineSorts!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 10")) as! [BILineSort]
        sortRule = (sortRule as NSArray).sortedArray(using: [NSSortDescriptor.init(key: "category", ascending: true),NSSortDescriptor.init(key: "type", ascending: true)] as [NSSortDescriptor]) as! [BILineSort]
        
        if sortRule.count > 0 {
            let arrayVariales = sortRule.first?.arrayVariables as! [NSNumber]
            var userFlags = [Int]()
            var userFlagColors = [UIColor]()
            
            for variable in arrayVariales{
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
                default:break
                }
            }
            reSetFlagOrder(userFlags: userFlags)
        }else{
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
        }
        
    }
    
    func reSetFlagOrder(userFlags: [Int]){
        var arrIndexValue: Int
        let lines = CBGlobalMethods.shared.selectedBidPeriod!.lines!.allObjects as! [BILine]
        for line in lines {
            if userFlags.contains(line.userFlagType!.intValue){
                line.flagOrder = NSNumber(integerLiteral: 8)
            }
        }
        for i in 0..<userFlags.count{
            arrIndexValue = userFlags[i]
            let notBlankPredicate = NSPredicate(format: "userFlagType == %d", arrIndexValue)
            let sortedLines = CBGlobalMethods.shared.selectedBidPeriod!.lines!.allObjects.filter{
                notBlankPredicate.evaluate(with: $0)} as! [BILine]
            for line in sortedLines {
                line.flagOrder = NSNumber(integerLiteral: i)
            }
        }
        
        do{
            try self.bidPeriod?.managedObjectContext!.save()
        }catch{
            print("Error saving context in reSetFlagOrder: \(error.localizedDescription)")
        }
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
    }
    


    
    @IBOutlet weak var collectionView: CBLineCalendarCollectionView!
    @IBOutlet weak var lineValuesView: UIView!
    @IBOutlet weak var moveBidListButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var calendarView: UIView!
    @IBOutlet weak var orderLabel: UILabel!
    @IBOutlet weak var lineNumberLabel: UILabel!
    @IBOutlet weak var redEyeImage: UIImageView!
    
    var app: AppDelegate?
    var calendarData: BICalendarData?
    var line: BILine?
    var index: Int?
    var tableView: UITableView?
    var availableFaLines : [BILine] = []
    var bidPeriod: BIBidPeriod?
    var tripButtons: NSMutableArray?
    var vacationButtons: NSMutableArray?
    var fvVacationButtons: NSMutableArray?
    var cfvVacationButtons: NSMutableArray?
    var tripButtonsArray = NSMutableArray()
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
    private var kLineNumberVertOrigin: Int = 73
    private var kCircleSize: Int = 20 //25
    private var kCircleHorizontalOffset: Int = 30 //28
    private var kCircleVerticalOffset: Int = 120 //90
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
    var calendarDaysArr : [BICalendarDay] = []
    var calendarDay : [BICalendarDay] = []
    var deletedObjArray:[String] = []
    typealias CBLineCellTripButtonActionBlock = (_ tripButton: CBTripButton) -> Void
    weak var controllerDelegate: UIViewController?
    var fromScrachpadView:Bool?

    func cellLayout(){
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = layout
    }
    
    
    func refreshTripButtons(highlightFlag:Bool, calendarWidth:CGFloat) {
        if tripButtons == nil {
            self.tripButtons = NSMutableArray()
        }
        let count: Int = tripButtonsArray.count
        for i in 0..<count {
            let tripButton = tripButtons?[i] as? UIButton
            if tripButton != nil {
                tripButton?.removeFromSuperview()
            }
        }
        tripButtonsArray.removeAllObjects()
        tripButtons?.removeAllObjects()
        tripButtons?.addObjects(from: calendarDaysArr)
        var shouldRemoveCFV = true
        let userdefaults = UserDefaults.standard
        // Get size of calendar items (cells) and create button frame from size.
        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let itemSize = CGSize(width: calendarWidth/7, height: (flowLayout?.itemSize.height)!)
        let inset = itemSize.height / 2
        let insets: UIEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        var buttonFrame = CGRect(x: 0.0, y: 0.0, width: itemSize.width , height: itemSize.height)
        var buttonImage: UIImage? = nil
        var button = CBTripButton()
        let daysInCalendar: Int = calendarDaysArr.count
        let trips = line?.trips
        for item in trips! {
            let trip = item as! BITrip
            // Check to see if the trip is hidden due to vacation overlap
            let tripOption = BIVacationOverlapTripOption(rawValue: userdefaults.integer(forKey: kCBVacationOverlapTripDisplayOption))
            if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue && (tripOption != nil){
                if BIVacationOverlapTripOption.dropAll.rawValue == tripOption!.rawValue && trip.vacationOverlapType!.intValue > 0 {
                    continue
                }else if tripOption?.rawValue == trip.vacationOverlapType?.intValue {
                    continue
                }
            }
            let highlighted = trip.highlightCount!.intValue > 0 && highlightFlag
            // Account for nil pairings showing up in the blank lines
            let index = self.calendarData!.indexForDate(date: trip.startDate!)
            if index > (daysInCalendar - 1) || index < 0 {
                continue
            }
            
            let column = index % 7
            let tripLength = (trip.info?.calendarDaysCount?.intValue)!
            var buttonLength = 0
            var otherButton: CBTripButton? = nil
            // If trip will go across two rows in calendar, create both buttons.
            if column + tripLength > 7 {
                buttonLength = 7 - column
                buttonFrame.size.width = CGFloat(buttonLength) * itemSize.width
                
                if bidPeriod!.isFABid() && trip.isReserve {
                    if BIFaReserveLineType.SnrAMres.rawValue == line?.faReserveLineType?.intValue {
                        buttonImage = UIImage.imageWithColor(CBColor.cbGreenColor)
                    }else if BIFaReserveLineType.SnrPMres.rawValue == line?.faReserveLineType?.intValue {
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
                }else {
                    if trip.isAM(){
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-left-green_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }else {
                            buttonImage = UIImage(named: "TripButton-rounded-left-orange_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }else{
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-left-red2_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }else {
                            buttonImage = UIImage(named: "TripButton-rounded-left-purple_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }
                }
                if trip.isRedEyeTrip == true {
                    buttonImage = UIImage.imageWithColor(UIColor.red)
                }
                buttonFrame.size.width = CGFloat(tripLength) * itemSize.width
                button = CBTripButton(frame: buttonFrame)
                button.tag = kCBButtonTag
                button.setBackgroundImage(buttonImage, for: .normal)
                if trip.isRedEyeTrip == true {
                    if button.layer.frame.size.height > 0 {
                        let maskPath = UIBezierPath(roundedRect: button.bounds,
                                                    byRoundingCorners: [.topLeft, .bottomLeft],
                                                    cornerRadii: CGSize(width: button.layer.frame.size.height / 2, height: button.layer.frame.size.height / 2))
                        let maskLayer = CAShapeLayer()
                        maskLayer.path = maskPath.cgPath
                        button.layer.mask = maskLayer
                        button.clipsToBounds = true
                    }
                }
                button.trip = trip
                button.addTarget(self, action: #selector(self.tripButtonAction), for: .touchUpInside)
                tripButtons?.replaceObject(at: index, with: button)
                tripButtonsArray.add(button)
                collectionView.addSubview(button)
                let nextButtonLength: Int = tripLength - buttonLength
                let nextButtonIndex: Int = index + buttonLength
                buttonFrame.size.width = CGFloat(nextButtonLength) * itemSize.width
                if bidPeriod!.isFABid() && trip.isReserve{
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
                }else{
                    if trip.isAM(){
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-right-green_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-right-orange_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }else {
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-right-red2_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-right-purple_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }
                }
                if trip.isRedEyeTrip == true {
                    buttonImage = UIImage.imageWithColor(.red)
                }
                otherButton = CBTripButton(frame: buttonFrame)
                otherButton?.tag = kCBButtonTag
                if trip.isRedEyeTrip == true {
                    if let otherButton = otherButton, otherButton.layer.frame.size.height > 0 {
                        let maskPath = UIBezierPath(roundedRect: otherButton.bounds,
                                                    byRoundingCorners: [.topRight, .bottomRight],
                                                    cornerRadii: CGSize(width: otherButton.layer.frame.size.height / 2, height: otherButton.layer.frame.size.height / 2))
                        let maskLayer = CAShapeLayer()
                        maskLayer.path = maskPath.cgPath
                        otherButton.layer.mask = maskLayer
                        otherButton.clipsToBounds = true
                    }
                }
                otherButton?.setBackgroundImage(buttonImage, for: .normal)
                otherButton?.trip = trip
                otherButton?.addTarget(self, action: #selector(self.tripButtonAction), for: .touchUpInside)
                button.otherButton = otherButton
                otherButton?.otherButton = button
                tripButtons?.replaceObject(at: nextButtonIndex, with: otherButton!)
                tripButtonsArray.add(button)
                collectionView.addSubview(otherButton!)
                
                if highlighted{
                    let leftBorder = CALayer()
                    leftBorder.cornerRadius = 16.0
                    leftBorder.borderColor = CBColor.tripHighlightColor.cgColor
                    leftBorder.borderWidth = 2.0
                    leftBorder.frame = CGRect(x: 0, y: 0, width: button.frame.width + 20, height: button.frame.height + 1)
                    button.layer.addSublayer(leftBorder)
                    
                    let rightBorder = CALayer()
                    rightBorder.cornerRadius = 16.0
                    rightBorder.borderColor = CBColor.tripHighlightColor.cgColor
                    rightBorder.borderWidth = 2.0
                    rightBorder.frame = CGRect(x: -15, y: -1, width: (otherButton?.frame.width)! + 15, height: (otherButton?.frame.height)! + 1)
                    otherButton?.layer.addSublayer(rightBorder)
                }
            }else{// Trip in one row only of the calendar.
                if bidPeriod!.isFABid() && trip.isReserve {
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
                }else{
                    if trip.isAM(){
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-right-green_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-right-orange_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }else {
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-right-red2_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-right-purple_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }
                }
                if trip.isRedEyeTrip == true {
                    buttonImage = UIImage.imageWithColor(.red)
                }
                buttonFrame.size.width = CGFloat(tripLength) * itemSize.width
                button = CBTripButton(frame: buttonFrame)
                button.tag = kCBButtonTag
                button.setBackgroundImage(buttonImage, for: .normal)
                
                if self.bidPeriod?.isFABid() ?? false && trip.isReserve || trip.isRedEyeTrip == true{
                    // Ensure the button has a valid frame before setting corner radius
                    if button.layer.frame.size.height > 0 {
                        button.layer.cornerRadius = button.layer.frame.size.height / 2
                        button.clipsToBounds = true
                    }
                }
                button.trip = trip
                if highlighted {
                    let roundedBorder = CALayer()
                    roundedBorder.cornerRadius = 16.0
                    roundedBorder.borderColor = CBColor.tripHighlightColor.cgColor
                    roundedBorder.borderWidth = 2.0
                    roundedBorder.frame = CGRect(x: -0.5, y: -1, width: button.frame.width + 1, height: button.frame.height + 1)
                    button.layer.addSublayer(roundedBorder)
                }
                button.addTarget(self, action: #selector(self.tripButtonAction), for: .touchUpInside)
                tripButtons?.replaceObject(at: index, with: button)
                tripButtonsArray.add(button)
                collectionView.addSubview(button)
            }
            let orderedDays = trip.orderedDays
            let daysCount: Int = orderedDays.count
            var labelButton: CBTripButton? = button
            
            var missingDateIndex = -1
            var missingRedEyeDate: Date? = nil
            var isDateMissingInPreviousDay = false
            
            if /*trip != nil && */trip.isRedEyeTrip{
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
                
                if !self.bidPeriod!.isFABid() && (trip.info?.dutyPeriodsCount != trip.info?.calendarDaysCount) {
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
                    labelButton = otherButton
                    labelFrame.origin.x = CGFloat(d - buttonLength) * itemSize.width + 3
                    
                    if self.bidPeriod!.isFABid() && trip.info?.dutyPeriodsCount != trip.info?.calendarDaysCount {
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
                
                if trip.isRedEyeTrip && d == missingDateIndex && self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue && trip.vacationOverlapType!.intValue > 0 {
                    redEyePayLabel?.textAlignment = .center
                    redEyePayLabel?.font = UIFont.boldSystemFont(ofSize: 12)
                    redEyePayLabel?.textColor = trip.highlightCount!.intValue > 0 ? CBColor.tripHighlightColor : .white
                }else{
                    redEyePayLabel = nil
                }
                
                if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue && trip.vacationOverlapType!.intValue > 0 && day.displayType!.intValue != BIDayDisplayType.normal.rawValue{
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
                }
                else{
                    // Last day of trip. Show pay and return time.
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
                        }
                        else if self.bidPeriod!.isFABid(){
                            label.text = String(format: "%.1f", trip.info!.faPay!.floatValue)
                        }
                        else{
                            if let number = trip.info!.number, number.count > 1 {
                                let secondChar = number[number.index(number.startIndex, offsetBy: 1)]
                                if secondChar == "P" {
                                    label.text = String(format: "%.1f", trip.info!.jsonPay?.floatValue ?? 0.0)
                                } else {
                                    label.text = String(format: "%.1f", trip.info!.faPay?.floatValue ?? 0.0)
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
                            
                            let timeZoneStr = CBUtils.rawTimeZoneString(forAirportCode: (dayInfo.orderedLegs.first)!.arriveCity!)!
                            let arriveDateStr = BITrip.staticTimeForReserveType(trip: trip, line: self.line!, key: "arrive", timeZone: timeZoneStr)
                            if arriveDateStr != nil {
                                timeLabel.text = arriveDateStr
                            }
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
                        
                        if !(self.bidPeriod!.isFABid() && trip.isReserve){
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
                            var xValue:CGFloat = 0
                            let verticalLabelWidth:CGFloat = 22
                            let verticalLabelHeight:CGFloat = 10
                            
                            xValue = labelFrame.origin.x + (labelFrame.size.width - verticalLabelHeight)
                            
                            let weekDayInt = CBUtils.weekDay(from: trip.startDate!)
                            var isSaturday = false
                            if weekDayInt + d == 7 {
                                isSaturday = true
                            }
                            if isSaturday{
                                xValue = fromScrachpadView == true ? xValue - 6 : xValue - 7
                            }
                            let verticalLabelFrame = CGRect(x: xValue, y: (verticalLabelWidth - verticalLabelHeight), width: verticalLabelWidth, height: verticalLabelHeight)
                            
                            let verticalLabel = UILabel(frame: verticalLabelFrame)
                            verticalLabel.textColor = CBColor.cbGreen
                            verticalLabel.textAlignment = .center
                            verticalLabel.font = UIFont.systemFont(ofSize: 24)
                            verticalLabel.transform = CGAffineTransform(rotationAngle: -.pi / 2)
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
                labelButton?.addSubview(label)
            }
        }
        if vacationButtons == nil {
            vacationButtons = NSMutableArray()
        }
        
        let vCount = (vacationButtons?.count)!
        
        for i in 0..<vCount {
            let vacationButton = vacationButtons?[i] as? UIImageView
            if vacationButton != nil {
                vacationButton?.removeFromSuperview()
            }
        }
        vacationButtons?.removeAllObjects()
        vacationButtons?.addObjects(from: calendarDaysArr)
        
        //Add vacation pill
        if self.bidPeriod!.containsVacay!.boolValue{
            var vacayButtonFrame = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
            var buttonImage:UIImage? = nil
            let vacations = self.bidPeriod!.vacations
            for case let vacay as BIVacation in vacations! {
                var index = (self.calendarData?.indexForDate(date: vacay.startDate))!
                var tripLength = 0
                if index < 0 {
                    tripLength = vacay.length!.intValue + index
                    index = 0
                }else if index > daysInCalendar - 1 {
                    continue
                }
                else{
                    tripLength = vacay.length!.intValue
                }
                let column = index % 7
                var buttonLength = 0
                // If vacation pill will go across two rows in calendar, create both buttons.
                if column+tripLength > 7 {
                    buttonLength = 7 - column
                    vacayButtonFrame.size.width = CGFloat(buttonLength) * itemSize.width
                    let imgName = userdefaults.string(forKey: kCBTripButtonRoundedLeftYellowImageNameKey)
                    buttonImage = UIImage(named: imgName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    vacayButtonFrame.size.width = min(CGFloat(tripLength), 7) * itemSize.width
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    vacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.6
                    self.collectionView?.addSubview(button2)
                    
                    if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                        button2.isUserInteractionEnabled = true
                        button2.isOpaque = false
                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
                        longPressGesture.minimumPressDuration = 0.5
                        longPressGesture.cancelsTouchesInView = false
                        button2.addGestureRecognizer(longPressGesture)
                        longPressGesture.delegate = self
                        vacayGestureRecognizers.add(longPressGesture)
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
                            let imgName = userdefaults.string(forKey: kCBTripButtonRoundedRightYellowImageNameKey)
                            buttonImage = UIImage(named:imgName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                            let otherButton2 = UIImageView(frame: vacayButtonFrame)
                            otherButton2.image = buttonImage
                            vacationButtons?.replaceObject(at: index, with: otherButton2)
                            otherButton2.alpha = 0.6
                            self.collectionView.addSubview(otherButton2)
                            
                            if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                                otherButton2.isUserInteractionEnabled = true
                                otherButton2.isOpaque = false
                                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
                                longPressGesture.minimumPressDuration = 0.5
                                longPressGesture.cancelsTouchesInView = false
                                button2.addGestureRecognizer(longPressGesture)
                                longPressGesture.delegate = self
                                vacayGestureRecognizers.add(longPressGesture)
                            }
                        }
                        tripLength -= buttonLength
                        index += buttonLength
                    }
                }
                else{ // Vacation in one row only of the calendar.
                    if index < 0 {
                        // Vacation starts before the visible calendar days, so show the rounded right image
                        let imgName = userdefaults.string(forKey: kCBTripButtonRoundedRightYellowImageNameKey)
                        buttonImage = UIImage(named: imgName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }else if (index+tripLength-1) > (daysInCalendar-1){
                        // Vacay ends after the visible calendar days, so show the rounded left image
                        let imgName = userdefaults.string(forKey: kCBTripButtonRoundedBothYellowImageNameKey)
                        buttonImage = UIImage(named: imgName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }else{
                        let imgName = userdefaults.string(forKey: kCBTripButtonRoundedBothYellowImageNameKey)
                        buttonImage = UIImage(named: imgName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }
                    vacayButtonFrame.size.width = CGFloat(tripLength) * itemSize.width
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    vacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.6
                    self.collectionView.addSubview(button2)
                    
                    if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                        button2.isUserInteractionEnabled = true
                        button2.isOpaque = false
                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
                        longPressGesture.minimumPressDuration = 0.5
                        longPressGesture.cancelsTouchesInView = false
                        button2.addGestureRecognizer(longPressGesture)
                        longPressGesture.delegate = self
                        vacayGestureRecognizers.add(longPressGesture)
                    }
                }
            }
        }
        //Remove FV
        if fvVacationButtons == nil {
            fvVacationButtons = NSMutableArray()
        }
        let fvCount = (fvVacationButtons?.count)!
        for i in 0..<fvCount {
            let fvVacationButton = fvVacationButtons?[i] as? UIImageView
            if fvVacationButton != nil {
                fvVacationButton?.removeFromSuperview()
            }
        }
        fvVacationButtons?.removeAllObjects()
        fvVacationButtons?.addObjects(from: calendarDaysArr)
        
        //Remove CFV
        if cfvVacationButtons == nil {
            cfvVacationButtons = NSMutableArray()
        }
        let cfvCount: Int = (cfvVacationButtons?.count)!
        for i in 0 ..< cfvCount {
            let cfvVacationButton = cfvVacationButtons?[i] as? UIImageView
            if cfvVacationButton != nil {
                cfvVacationButton?.removeFromSuperview()
            }
        }
        cfvVacationButtons?.removeAllObjects()
        cfvVacationButtons?.addObjects(from: calendarDaysArr)
        
        for view in self.collectionView.subviews {
            if shouldRemoveCFV{
                if view.tag == 99 {
                    view.removeFromSuperview()
                }
            }
        }
        
        if self.bidPeriod!.containsVacay!.boolValue {
            var vacayButtonFrame = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
            var buttonImage:UIImage? = nil
            let vacations = self.line?.fvvacations
            let arrVacationIndexes = NSMutableArray()
            let removeCFV = userdefaults.bool(forKey: "RemoveCfv")
            if (self.line?.cfvVacDates!.count)! > 0{
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
                        
                        let dateString = "\(cfvDate)-\(self.bidPeriod!.month!)-\(self.bidPeriod!.year!)"
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "d-M-yyyy"
                        let timeZone = TimeZone(abbreviation: "GMT")!
                        dateFormatter.timeZone = timeZone
                        let cfvDATE = dateFormatter.date(from: dateString)
                        let index = (self.calendarData?.indexForDate(date: cfvDATE))!
                        let indexPath1 = IndexPath(row: index + 1, section: 0)
                        let buttonLayoutAttributes1 = self.collectionView.layoutAttributesForItem(at: indexPath1)!
                        var vacayButtonFrame = buttonLayoutAttributes1.frame
                        vacayButtonFrame.size.width = itemSize.width
                        cfv.frame = vacayButtonFrame
                        cfv.layer.cornerRadius = cfv.frame.height/2
                        cfv.layer.masksToBounds = true
                        cfvVacationButtons?.replaceObject(at: index + 1, with: cfv)
                        self.collectionView.addSubview(cfv)
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
                }
                let column = index % 7
                var buttonLength = 0
                
                // If vacation pill will go across two rows in calendar, create both buttons.
                if column + tripLength > 7 {
                    buttonLength = 7 - column
                    vacayButtonFrame.size.width = itemSize.width * CGFloat(buttonLength)
                    let imgName = userdefaults.string(forKey: kCBTripButtonRoundedLeftFVBlueImageNameKey)
                    buttonImage = UIImage(named: imgName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    vacayButtonFrame.size.width = min(CGFloat(tripLength), 7) * itemSize.width
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    fvVacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.7
                    self.collectionView.addSubview(button2)
                    if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                        button2.isUserInteractionEnabled = true
                        button2.isOpaque = false
                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
                        longPressGesture.minimumPressDuration = 0.5
                        longPressGesture.cancelsTouchesInView = false
                        button2.addGestureRecognizer(longPressGesture)
                        longPressGesture.delegate = self
                        vacayGestureRecognizers.add(longPressGesture)
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
                            let imgName = userdefaults.string(forKey: kCBTripButtonRoundedRightFVBlueImageNameKey)
                            buttonImage = UIImage(named: imgName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                            let otherButton2 = UIImageView(frame: vacayButtonFrame)
                            otherButton2.image = buttonImage
                            fvVacationButtons?.replaceObject(at: index, with: otherButton2)
                            otherButton2.alpha = 0.7
                            self.collectionView.addSubview(otherButton2)
                            
                            if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                                otherButton2.isUserInteractionEnabled = true
                                otherButton2.isOpaque = false
                                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
                                longPressGesture.minimumPressDuration = 0.5
                                longPressGesture.cancelsTouchesInView = false
                                button2.addGestureRecognizer(longPressGesture)
                                longPressGesture.delegate = self
                                vacayGestureRecognizers.add(longPressGesture)
                            }
                        }
                        tripLength -= buttonLength
                        index += buttonLength
                    }
                }
                else{ // Vacation in one row only of the calendar.
                    if index < 0 {
                        // Vacation starts before the visible calendar days, so show the rounded right image
                        let imgName = userdefaults.string(forKey: kCBTripButtonRoundedRightFVBlueImageNameKey)
                        buttonImage = UIImage(named: imgName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }else if (index + tripLength - 1) > (daysInCalendar - 1) {
                        // Vacay ends after the visible calendar days, so show the rounded left image
                        let imgName = userdefaults.string(forKey: kCBTripButtonRoundedLeftFVBlueImageNameKey)
                        buttonImage = UIImage(named: imgName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }else{
                        let imgName = userdefaults.string(forKey: kCBTripButtonRoundedBothFVBlueImageNameKey)
                        buttonImage = UIImage(named: imgName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }
                    vacayButtonFrame.size.width = CGFloat(tripLength) * itemSize.width
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    fvVacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.7
                    self.collectionView.addSubview(button2)
                    if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                        button2.isUserInteractionEnabled = true
                        button2.isOpaque = false
                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
                        longPressGesture.minimumPressDuration = 0.5
                        longPressGesture.cancelsTouchesInView = false
                        button2.addGestureRecognizer(longPressGesture)
                        longPressGesture.delegate = self
                        vacayGestureRecognizers.add(longPressGesture)
                    }
                }
            }
        }
        if (self.bidPeriod?.myCalEnabled?.boolValue == true) && self.bidPeriod!.isNeedToShowMyCal() && (self.line?.bidOrder == 0) {
            var vacayButtonFrame = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
            var buttonImage:UIImage? = nil
            var index = self.calendarData!.indexForDateGMT(date: (self.bidPeriod?.myCalStartDate)!)
            let length = self.calculateLengthBetween(startDate: (self.bidPeriod?.myCalStartDate)!, endDate: (self.bidPeriod?.myCalEndDate)!)
            var tripLength = 0
            if index < 0 {
                tripLength = length.intValue + index
            }else if index > (daysInCalendar - 1){
                tripLength = 0
            }else{
                tripLength = length.intValue
            }
            let column = index % 7
            var buttonLength = 0
            
            // If vacation pill will go across two rows in calendar, create both buttons.
            if column + tripLength > 7 {
                buttonLength = 7 - column
                vacayButtonFrame.size.width = CGFloat(buttonLength) * itemSize.width
                buttonImage = UIImage(named: "TripButton-rounded-left-red2_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                vacayButtonFrame.size.width = min(CGFloat(tripLength), 7) * itemSize.width
                let button2 = UIImageView(frame: vacayButtonFrame)
                button2.image = buttonImage
                fvVacationButtons?.replaceObject(at: index, with: button2)
                button2.alpha = 0.5
                self.collectionView.addSubview(button2)
                if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                    button2.isUserInteractionEnabled = true
                    button2.isOpaque = false
                    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
                    longPressGesture.minimumPressDuration = 0.5
                    longPressGesture.cancelsTouchesInView = false
                    button2.addGestureRecognizer(longPressGesture)
                    longPressGesture.delegate = self
                    vacayGestureRecognizers.add(longPressGesture)
                }
                tripLength -= buttonLength
                index += buttonLength
                while tripLength > 0 {
                    buttonLength = tripLength > 7 ? 7 :tripLength
                    if index < daysInCalendar {
                        vacayButtonFrame.size.width = min(CGFloat(buttonLength), 7) * itemSize.width
                        
                        if tripLength > 7{
                            vacayButtonFrame.size.width += 15
                        }
                        buttonImage = UIImage(named: "TripButton-rounded-right-red2_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        let otherButton2 = UIImageView(frame: vacayButtonFrame)
                        otherButton2.image = buttonImage
                        fvVacationButtons?.replaceObject(at: index, with: otherButton2)
                        otherButton2.alpha = 0.5
                        self.collectionView.addSubview(otherButton2)
                        
                        if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                            otherButton2.isUserInteractionEnabled = true
                            otherButton2.isOpaque = false
                            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
                            longPressGesture.minimumPressDuration = 0.5
                            longPressGesture.cancelsTouchesInView = false
                            button2.addGestureRecognizer(longPressGesture)
                            longPressGesture.delegate = self
                            vacayGestureRecognizers.add(longPressGesture)
                        }
                    }
                    tripLength -= buttonLength
                    index += buttonLength
                }
            }
            else{// Vacation in one row only of the calendar.
                buttonImage = UIImage(named: "TripButton-rounded-both-red2_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                vacayButtonFrame.size.width = CGFloat(tripLength) * itemSize.width
                let button2 = UIImageView(frame: vacayButtonFrame)
                button2.image = buttonImage
                fvVacationButtons?.replaceObject(at: index, with: button2)
                button2.alpha = 0.5
                self.collectionView.addSubview(button2)
                if self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                    button2.isUserInteractionEnabled = true
                    button2.isOpaque = false
                    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
                    longPressGesture.minimumPressDuration = 0.5
                    longPressGesture.cancelsTouchesInView = false
                    button2.addGestureRecognizer(longPressGesture)
                    longPressGesture.delegate = self
                    vacayGestureRecognizers.add(longPressGesture)
                }
            }
        }
        self.collectionView.reloadData()
        self.collectionView.tripButtons = tripButtons
        self.collectionView.vacationButtons = vacationButtons
        self.collectionView.fvVacationButtons = fvVacationButtons
        self.collectionView.cfvVacationButtons = cfvVacationButtons
    }
    
    @objc func showSWAPtimizerTripOptionsPopover(_ gesture:UILongPressGestureRecognizer){
    }
    
    
    @objc func tripButtonAction(_ tripButton: CBTripButton){
        
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
    
    func removeAllTripButtons() {
        for case let view as UIView in tripButtonsArray {
            view.removeFromSuperview()
        }
    }
    
    
    func setCircle(_ circleNum: Int, withPos pos: String, color: UIColor, isGray gray: Bool) {
        if circleNum == 0 {
            if gray {
                let posText = posAGrayView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posAView.alpha = 0.0
            }
            else {
                let posText = posAView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posAView.backgroundColor = color
                posAView.alpha = 1.0
                posAGrayView.alpha = 0.0
            }
        }
        else if circleNum == 1 {
            if gray {
                let posText = posBGrayView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posBView.alpha = 0.0
            }
            else {
                let posText = posBView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posBView.backgroundColor = color
                posBView.alpha = 1.0
                posBGrayView.alpha = 0.0
            }
        }
        else if circleNum == 2 {
            if gray {
                let posText = posCGrayView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posCView.alpha = 0.0
            }
            else {
                let posText = posCView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posCView.backgroundColor = color
                posCView.alpha = 1.0
                posCGrayView.alpha = 0.0
            }
        }
        else {
            if gray {
                let posText = posDGrayView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posDView.alpha = 0.0
            }
            else {
                let posText = posDView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posDView.backgroundColor = color
                posDView.alpha = 1.0
                posDGrayView.alpha = 0.0
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        
        let verticalSpace: CGFloat = 6.0
        for i in 0..<5 {
//            adding the line values as subview
            var lineValueView1 = CBLineValueView()
            lineValueView1 = lineValueView1.initWithFrame(aRect: CGRect.zero)
            lineValueView1.tag = LineValueViewTag + i * 10
            lineValueView1.translatesAutoresizingMaskIntoConstraints = false
            lineValuesView.addSubview(lineValueView1)
            // Line value view centered in container.
            lineValuesView.addConstraint(NSLayoutConstraint(item: lineValueView1, attribute: .centerX, relatedBy: .equal, toItem: lineValuesView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            // Top spacing from superview.
            lineValuesView.addConstraint(NSLayoutConstraint(item: lineValueView1, attribute: .top, relatedBy: .equal, toItem: lineValuesView, attribute: .top, multiplier: 1.0, constant: CGFloat(i) * (kCBLineValueViewHeight + verticalSpace)))
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressLineValueContainerView))
        longPressGesture.minimumPressDuration = 0.3
        lineValuesView.addGestureRecognizer(longPressGesture)
        longPressGesture.delaysTouchesBegan = true
//            adding the flags values as subview
        let iconView: UIControl? = CBUserFlagTableController.userFlagControlForColor(color: UIColor.white, diameter: 30.0)
        iconView?.frame = CGRect(x: 23.0, y: 50, width: 30.0, height: 30.0)
        iconView?.addTarget(self, action: #selector(self.showUserFlagMenu), for: .touchUpInside)
        addSubview(iconView ?? UIView())
        self.userFlagIconView = iconView!

        // Set up the position circles
        
        // Position A Colored
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
        posAView.alpha = 0
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
        posAGrayView.alpha = 0
        
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
        posBGrayView.alpha = 0
        
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
        posCView.alpha = 0
        
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
        posCGrayView.alpha = 0
        
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
        posDView.alpha = 0
        
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
        posDGrayView.alpha = 0
        
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
        posMView.alpha = 0
        
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
        posNAView.alpha = 0
 
    }

    @objc func longPressLineValueContainerView(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBLineValuesMenuController") as! CBLineValuesMenuController
        lineValuesController.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        lineValuesController.modalPresentationStyle = .custom
        let touchPoint = gesture.location(in: self.lineValuesView)
        let frame = CGRect(x: lineValuesView.frame.origin.x, y: touchPoint.y - 80, width: lineValuesView.frame.width, height: lineValuesView.frame.height)
        lineValuesController.showPopover(sourceView: self.lineValuesView, sourceRect: frame)
    }
    
    @objc func showUserFlagMenu() {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBUserFlagTableController") as! CBUserFlagTableController
        lineValuesController.line = line
        lineValuesController.delegate = self
        lineValuesController.modalPresentationStyle = .popover
        lineValuesController.showPopover(sourceView: self.userFlagIconView)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarDaysArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath as IndexPath) as! CBBidListSmallCollectionViewCell
        cell.contentView.frame = cell.bounds
        cell.contentView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        let calendarDay = calendarDaysArr[indexPath.row]
        cell.dayLabel.text = calendarDay.text
        let currentMonth = calendarDay.isCurrentMonth
        if currentMonth {
            cell.dayLabel.alpha = 1
        }else{
            cell.dayLabel.alpha = 0.5
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSizeMake((self.contentView.frame.width - 160)/7, 45)
    }

    @IBAction func removeLineAction(_ sender: Any) {
        if self.bidPeriod!.isFABid() {
            NotificationCenter.default.post(name: NSNotification.Name("removedLines"), object: nil, userInfo: [CBLineTableCellBidLineKey:self.line!])
        }else{
            line?.isTrashed = true
            do{
                try self.bidPeriod?.managedObjectContext?.save()
            }catch{
                print("Error removing lines: \(error.localizedDescription)")
            }
            let lineNumber = line?.number as! Int
            let number = String(lineNumber)
            let objDeleteArray = NSMutableArray()
            objDeleteArray.add(number)
            NotificationCenter.default.post(name: NSNotification.Name("removedLines"), object: objDeleteArray)
        }
    }
    
    @IBAction func moveLinesToBidListAction(_ sender: Any) {
        moveBidListButton.isUserInteractionEnabled = false
        perform(#selector(moveBidLineDelay), with: nil, afterDelay: 1.0)
//        if let sView = sender as? UIView {
//            sView.isUserInteractionEnabled = false
//            perform(#selector(resetButton(_:)), with: sView, afterDelay: 0.5)
//        }
        
    }
    
    @objc func moveBidLineDelay() {
        moveBidListButton.isUserInteractionEnabled = true
    }
//    
//    @objc func resetButton(_ sender: UIView) {
//        sender.isUserInteractionEnabled = true
//    }
}
