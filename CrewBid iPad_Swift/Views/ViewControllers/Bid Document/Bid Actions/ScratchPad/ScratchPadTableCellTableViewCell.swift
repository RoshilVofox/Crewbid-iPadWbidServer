//
//  ScratchPadTableCellTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 15/04/25.
//

import UIKit

class ScratchPadTableCellTableViewCell: UITableViewCell,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {

    var kCBLineValueViewWidth : CGFloat = 55.0
    var kCBLineValueViewHeight : CGFloat = 28.0
    
    @IBOutlet weak var collectionView: UICollectionView!
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
//    var tripButtonActionBlock: CBLineCellTripButtonActionBlock?
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
    //--------------------------
    var selectedValues:[String] = []
    var CalendarData: [[(day: Int?, isBidMonth: Bool)]] = []
    var tripIndexes: [(row: Int, col: Int)] = []
    let tripDays = [1,2,3,4,8,9,10,11,15,16,17,18,22,23,24,25]
    let month = 5
    let year = 2025
    
//    to get calendar days
    func getCalendarData(for month: Int, year: Int){
        let calendar = Calendar.current
        //---------Bid Month Details-----------
        let firstDayOfBidMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let firstWeekdayofBidMonth = calendar.component(.weekday, from: firstDayOfBidMonth)     //S,M,T,W,T,F,S as 1,2,3,4,5,6,7
        let rangeBidMonth = calendar.range(of: .day, in: .month, for: firstDayOfBidMonth)!
        let totalDaysinBidMonth = rangeBidMonth.count
        //---------Previous Month Details----------
        let lastWeekDayofPreviousMonth = firstWeekdayofBidMonth - 1     //S,M,T,W,T,F,S as 1,2,3,4,5,6,7
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfBidMonth)!
        let rangePrevMonth = calendar.range(of: .day, in: .month, for: previousMonth)!
        let totalDaysinPreviousMonth = rangePrevMonth.count
        
        var calendarData: [[(day:Int?,isBidMonth:Bool)]] = Array(repeating: Array(repeating: (nil,false), count: 7), count: 6)
        
        var currentDay = 1
        var day = totalDaysinPreviousMonth - lastWeekDayofPreviousMonth + 1
        
        for col in 0..<lastWeekDayofPreviousMonth {
            calendarData[0][col] = (day,false)
            day += 1
        }
        var row = 0
        var col = lastWeekDayofPreviousMonth
        while currentDay <= totalDaysinBidMonth {
            calendarData[row][col] = (currentDay,true)
            currentDay += 1
            col += 1
            if col == 7{
                col = 0
                row += 1
            }
        }
        var nextMonthDay = 1
            for row in 0..<6 {
                for col in 0..<7 {
                    if calendarData[row][col].day == nil {
                        calendarData[row][col] = (nextMonthDay,false)
                        nextMonthDay += 1
                    }
                }
            }
        CalendarData = calendarData
    }
    
    // Function to display the day and apply styles based on the bid month
    func displayDay(for collection: CBBidListSmallCollectionViewCell, day: Int?, isBidMonth: Bool) {
        // Display the day or placeholder if nil
        collection.dayLabel.text = day != nil ? "\(day!)" : ""
        
        // Change text color if it's not part of the bid month
        if !isBidMonth {
            collection.dayLabel.textColor = UIColor(red: 195/255, green: 195/255, blue: 197/255, alpha: 1.0)
        }
    }

    func cellLayout(){
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = layout
    }
    //--------------------------
    
    
//    func refreshTripButtons(highlightFlag:Bool) {
//        if nil == tripButtons {
//            tripButtons = NSMutableArray()
//        }
//        let count: Int = (tripButtons?.count)!
//        for i in 0..<count {
//            let tripButton = tripButtons?[i] as? UIButton
//            if tripButton != nil {
//                tripButton?.removeFromSuperview()
//            }
//        }
//        tripButtonsArray.removeAllObjects()
//        tripButtons?.removeAllObjects()
//        tripButtons?.addObjects(from: calendarDaysArr)
//        let userDefaults = UserDefaults.standard
//        // Get size of calendar items (cells) and create button frame from size.
//        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
//        let itemSize: CGSize? = flowLayout?.itemSize
//        let inset: CGFloat = 15.0
//        
//        let insets: UIEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
//        
//        //let WidthSize = (self.frame.width - 160) / 7 - changed by basith
//        
//        //var WidthSize = (self.frame.width - 160) / 7
//        let screenSize = UIScreen.main.bounds
//        let screenWidth = screenSize.width / 2
//        let WidthSize = (screenWidth - 187) / 7
//        /*if CBGlobalMethods.shared.frameWidth > self.frame.width{
//            WidthSize = (CBGlobalMethods.shared.frameWidth - 160) / 7
//        }else{
//            CBGlobalMethods.shared.frameWidth =  self.frame.width
//        }*/
//        var buttonFrame = CGRect(x: 0.0, y: 0.0, width: WidthSize , height: itemSize?.height ?? 0.0)
//        var buttonImage: UIImage? = nil
//        var button = CBTripButton()
//        let daysInCalendar: Int = calendarDaysArr.count
//        let trips = line?.trips
//        for item in trips! {
//            let trip = item as! BITrip
//            var highlighted: Bool = Int(truncating: trip.highlightCount!)>0 && highlightFlag
//            var isTripInVacation = false
//            if trip.orderedDays.count > 0 && (bidPeriod?.vacations?.allObjects.count ?? 0) > 0 {
//                isTripInVacation = (trip.orderedDays ).first!.displayType != 0 || (trip.orderedDays ).last!.displayType != 0
//            }
//            
//            let index: Int = calendarData!.indexForDate(date: trip.startDate! as Date)
//            if index > (daysInCalendar - 1) || index < 0 {
//                continue
//            }
//            let column: Int = index % 7
//            //Added by Kripa for red eye related implementation on Dec 3
//            let tripLength: Int = trip.info!.calendarDaysCount as! Int
////            if trip.isRedEyeTrip?.boolValue == true && !self.bidPeriod!.isFlightAttendantBid(){
////                tripLength = tripLength + 1
////            }
//            var buttonLength: Int = 0
//            var otherButton:CBTripButton? = nil
//            // If trip will go across two rows in calendar, create both buttons.
//            if column + tripLength > 7 {
//                buttonLength = 7 - column
//              
//                buttonFrame.size.width = CGFloat(buttonLength) * (WidthSize)
//                if bidPeriod!.isFlightAttendantBid() && trip.isReserve() {
//                    if BIFaReserveLineType.BIFaReserveLineTypeSnrAMres.rawValue == Int(truncating: (line?.faReserveLineType)!) {
//                        buttonImage = UIImage(named: "TripButton-rounded-left-green_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }else if BIFaReserveLineType.BIFaReserveLineTypeSnrPMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage(named: "TripButton-rounded-left-red2_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                    else if BIFaReserveLineType.BIFaReserveLineTypeJnrAMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage.imageWithColor(CBColor.lightGreenColor())
//                    }
//                    else if BIFaReserveLineType.BIFaReserveLineTypeJnrPMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage.imageWithColor(CBColor.lightTripButtonRedColor())
//                    }
//                    else {
//                        buttonImage = UIImage(named: "TripButton-rounded-left-brown_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                } else {
//                    if trip.isAM(){
//                        if trip.isReserve() {
//                            buttonImage = UIImage(named: "TripButton-rounded-left-green_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        }else {
//                            buttonImage = UIImage(named: "TripButton-rounded-left-orange_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        }
//                    }
//                    else {
//                        if trip.isReserve() {
//                            buttonImage = UIImage(named: "TripButton-rounded-left-red2_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        }else {
//                            buttonImage = UIImage(named: "TripButton-rounded-left-purple_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        }
//                    }
//                }
//                if trip.isRedEyeTrip?.boolValue == true {
//                    buttonImage = UIImage.imageWithColor(UIColor.red)
//                }
//                
//                buttonFrame.size.width =  CGFloat(buttonLength) * (WidthSize)
//                button = CBTripButton(frame: buttonFrame)
//                button.tag = kCBButtonTag
//                button.setBackgroundImage(buttonImage, for: .normal)
//                if trip.isRedEyeTrip?.boolValue == true {
//                    if button.layer.frame.size.height > 0 {
//                        let maskPath = UIBezierPath(roundedRect: button.bounds,
//                                                    byRoundingCorners: [.topLeft, .bottomLeft],
//                                                    cornerRadii: CGSize(width: button.layer.frame.size.height / 2, height: button.layer.frame.size.height / 2))
//                        let maskLayer = CAShapeLayer()
//                        maskLayer.path = maskPath.cgPath
//                        button.layer.mask = maskLayer
//                        button.clipsToBounds = true
//                    }
//                }
//                button.trip = trip
//                
//                button.addTarget(self, action: #selector(self.tripButtonAction), for: .touchUpInside)
//                tripButtons?.replaceObject(at: index, with: button)
//                tripButtonsArray.add(button)
//                collectionView.addSubview(button)
//                let nextButtonLength: Int = tripLength - buttonLength
//                let nextButtonIndex: Int = index + buttonLength
//                buttonFrame.size.width = CGFloat(nextButtonLength) * (WidthSize)
//                if bidPeriod!.isFlightAttendantBid() && trip.isReserve() {
//                    if BIFaReserveLineType.BIFaReserveLineTypeSnrAMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage(named: "TripButton-rounded-right-green_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                    else if BIFaReserveLineType.BIFaReserveLineTypeSnrPMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage(named: "TripButton-rounded-right-red2_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                    else if BIFaReserveLineType.BIFaReserveLineTypeJnrAMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage.imageWithColor(CBColor.lightGreenColor())
//                    }
//                    else if BIFaReserveLineType.BIFaReserveLineTypeJnrPMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage.imageWithColor(CBColor.lightTripButtonRedColor())
//                    }
//                    else {
//                        buttonImage = UIImage(named: "TripButton-rounded-right-brown_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                } else {
//                    if trip.isAM() {
//                        if trip.isReserve() {
//                            buttonImage = UIImage(named: "TripButton-rounded-right-green_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        } else {
//                            buttonImage = UIImage(named: "TripButton-rounded-right-orange_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        }
//                    } else {
//                        if trip.isReserve() {
//                            buttonImage = UIImage(named: "TripButton-rounded-right-red2_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        } else {
//                            buttonImage = UIImage(named: "TripButton-rounded-right-purple_iOS7.png")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        }
//                    }
//                }
//                if trip.isRedEyeTrip?.boolValue == true {
//                    buttonImage = UIImage.imageWithColor(UIColor.red)
//                }
//                otherButton = CBTripButton(frame: buttonFrame)
//                otherButton?.tag = kCBButtonTag
//                if trip.isRedEyeTrip?.boolValue == true {
//                    if let otherButton = otherButton, otherButton.layer.frame.size.height > 0 {
//                        let maskPath = UIBezierPath(roundedRect: otherButton.bounds,
//                                                    byRoundingCorners: [.topRight, .bottomRight],
//                                                    cornerRadii: CGSize(width: otherButton.layer.frame.size.height / 2, height: otherButton.layer.frame.size.height / 2))
//                        let maskLayer = CAShapeLayer()
//                        maskLayer.path = maskPath.cgPath
//                        otherButton.layer.mask = maskLayer
//                        otherButton.clipsToBounds = true
//                    }
//                }
//                otherButton?.setBackgroundImage(buttonImage, for: .normal)
//                otherButton?.trip = trip
//                otherButton?.addTarget(self, action: #selector(self.tripButtonAction), for: .touchUpInside)
//                button.otherButton = otherButton
//                otherButton?.otherButton = button
//                tripButtons?.replaceObject(at: nextButtonIndex, with: otherButton!)
//                tripButtonsArray.add(button)
//                collectionView.addSubview(otherButton!)
//                
//                if highlighted {
//                    
//                    let leftBorder = CALayer()
//                    leftBorder.cornerRadius = 16.0
//                    leftBorder.borderColor = CBColor.tripHighlightColor().cgColor
//                    leftBorder.borderWidth = 2.0
//                    leftBorder.frame = CGRect(x: 0, y: 0, width: button.frame.width + 20, height: button.frame.height + 1)
//                    button.layer.addSublayer(leftBorder)
//                    
//                    let rightBorder = CALayer()
//                    rightBorder.cornerRadius = 16.0
//                    rightBorder.borderColor = CBColor.tripHighlightColor().cgColor
//                    rightBorder.borderWidth = 2.0
//                    rightBorder.frame = CGRect(x: -15, y: -1, width: (otherButton?.frame.width)! + 15, height: (otherButton?.frame.height)! + 1)
//                    otherButton?.layer.addSublayer(rightBorder)
//                    
//                    // Add a long-press for a failsafe
//                    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.resetHighlights))
//                    longPressGesture.minimumPressDuration = 2.0 as CFTimeInterval
//                    button.addGestureRecognizer(longPressGesture)
//                    otherButton?.addGestureRecognizer(longPressGesture)
//                    longPressGesture.delegate = self
//                }
//            } else {   // Trip in one row only of the calendar.
//                if bidPeriod!.isFlightAttendantBid() && trip.isReserve() {
//                    if BIFaReserveLineType.BIFaReserveLineTypeSnrAMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage(named: userDefaults.string(forKey: kCBTripButtonRoundedBothGreenImageNameKey)!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                    else if BIFaReserveLineType.BIFaReserveLineTypeSnrPMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage(named: userDefaults.string(forKey: kCBTripButtonRoundedBothRedImageNameKey)!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                    else if BIFaReserveLineType.BIFaReserveLineTypeJnrAMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage.imageWithColor(CBColor.lightGreenColor())
//                    }
//                    else if BIFaReserveLineType.BIFaReserveLineTypeJnrPMres.rawValue == line?.faReserveLineType?.intValue {
//                        buttonImage = UIImage.imageWithColor(CBColor.lightTripButtonRedColor())
//                    }
//                    else {
//                        buttonImage = UIImage(named: "TripButton-rounded-both-brown_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                } else {
//                    if trip.isAM() {
//                        if trip.isReserve() {
//                            buttonImage = UIImage(named: userDefaults.string(forKey: kCBTripButtonRoundedBothGreenImageNameKey)!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        } else {
//                            buttonImage = UIImage(named: userDefaults.string(forKey: kCBTripButtonRoundedBothOrangeImageNameKey)!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        }
//                    } else {
//                        if trip.isReserve() {
//                            buttonImage = UIImage(named: userDefaults.string(forKey: kCBTripButtonRoundedBothRedImageNameKey)!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        } else {
//                            buttonImage = UIImage(named: userDefaults.string(forKey: kCBTripButtonRoundedBothPurpleImageNameKey)!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        }
//                    }
//                }
//                if trip.isRedEyeTrip?.boolValue == true {
//                    buttonImage = UIImage.imageWithColor(UIColor.red)
//                }
//                buttonFrame.size.width = CGFloat(tripLength) * (WidthSize)
//                button = CBTripButton(frame: buttonFrame)
//                button.tag = kCBButtonTag
//                //                button.backgroundColor = .red
//                button.setBackgroundImage(buttonImage, for: .normal)
//
//                if (self.bidPeriod?.isFlightAttendantBid() ?? false && trip.isReserve()) || trip.isRedEyeTrip?.boolValue == true {
//                    // Ensure the button has a valid frame before setting corner radius
//                    if button.layer.frame.size.height > 0 {
//                        button.layer.cornerRadius = button.layer.frame.size.height / 2
//                        button.clipsToBounds = true
//                    }
//                }
//                button.trip = trip
//                if highlighted {
//                    let roundedBorder = CALayer()
//                    roundedBorder.cornerRadius = 16.0
//                    roundedBorder.borderColor = CBColor.tripHighlightColor().cgColor
//                    roundedBorder.borderWidth = 2.0
//                    roundedBorder.frame = CGRect(x: -0.5, y: -1, width: button.frame.width + 1, height: button.frame.height + 1)
//                    button.layer.addSublayer(roundedBorder)
//                    // Add a long-press for a failsafe
//                    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.resetHighlights))
//                    longPressGesture.minimumPressDuration = 3.0 as CFTimeInterval
//                    button.addGestureRecognizer(longPressGesture)
//                    longPressGesture.delegate = self
//                }
//                button.addTarget(self, action: #selector(self.tripButtonAction), for: .touchUpInside)
//                tripButtons?.replaceObject(at: index, with: button)
//                tripButtonsArray.add(button)
//                collectionView.addSubview(button)
//            }
//            let orderedDays = trip.orderedDays()
//            let daysCount: Int = orderedDays.count
//            var labelButton: CBTripButton? = button
//            var wasDateMissingInPreviousIteration = false
//            for d in 0..<daysCount {
//                var isDateMissing = false
//                var labelFrame: CGRect = button.bounds
//                //                labelFrame.origin.x = CGFloat(d) * itemSize!.width
//                labelFrame.origin.x = CGFloat(d) * WidthSize
//                let day: BIDay? = (orderedDays[d] as! BIDay)
//                //Added by Kripa on 17 Dec for red eye icon display on the trip button
//                if d != daysCount - 1 {
//                    let FirstDayRed: BIDay? = (orderedDays[d] as! BIDay)
//                    let SecondDayRed: BIDay? = (orderedDays[d + 1] as! BIDay)
//                    let firstDayDate = FirstDayRed?.date
//                    let secondDayDate = SecondDayRed?.date
//                    isDateMissing = CBUtils.compareDatesToDecideRedEye(Date1: firstDayDate ?? Date(), Date2: secondDayDate ?? Date())
//                }
//                let dayInfo: BIDayInfo? = day?.info
//                var currentDayHasRedEyeLeg = false
//                for legInfo in dayInfo?.orderedLegs() ?? [] {
//                    if legInfo.isRedEye?.boolValue == true{
//                        currentDayHasRedEyeLeg = true
//                    }
//                }
//                if trip.isRedEyeTrip?.boolValue == true && currentDayHasRedEyeLeg && trip.info?.calendarDaysCount as? Int ?? 0 > daysCount{
//                    labelFrame.origin.x = (CGFloat(d) * WidthSize) + WidthSize
//                    let xPoint = (CGFloat(d) * WidthSize) + WidthSize - 43
//                    if ((trip.vacationOverlapType?.intValue)! > 0) {
//                        var redimageLabel = UILabel()
//                        let redimageLabelFrame = CGRect(x: xPoint , y: labelFrame.origin.y + 7, width: 25, height: 25)
//                        redimageLabel.frame = redimageLabelFrame
//                        redimageLabel.text = "$"
//                        redimageLabel.textColor = .white
//                        redimageLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
//                        redimageLabel.textAlignment = .center
//                        redimageLabel.backgroundColor = .clear // Or add a debug color like .red
//                        labelButton?.addSubview(redimageLabel)
//                    }
//                    else{
//                        var redimageView = UIImageView()
//                        let redEyeImageFrame = CGRect(x: xPoint , y: labelFrame.origin.y + 13, width: 38, height: 12)
//                        if #available(iOS 13.0, *) {
//                            redimageView = UIImageView(image: UIImage(systemName: "eye.fill"))
//                        } else {
//                            redimageView = UIImageView(image: UIImage(named: "RedEye"))
//                        }
//                        redimageView.contentMode = .scaleAspectFit
//                        redimageView.tintColor = .white
//                        redimageView.frame = redEyeImageFrame
//                        labelButton?.addSubview(redimageView)
//                    }
//                }
//                //  signaling:
//                //                labelFrame.size.width = (itemSize?.width)!
//                labelFrame.size.width = (WidthSize)
//                // Show labels in other button if day is greater than length of
//                // first button. Adjust origin of label to other button.
//                if (otherButton != nil) && d >= buttonLength {
//                    labelButton = otherButton
//                    //                    labelFrame.origin.x = CGFloat(d - buttonLength) * (itemSize?.width)!
//                    labelFrame.origin.x = CGFloat(d - buttonLength) * (WidthSize)
//                    if trip.isRedEyeTrip?.boolValue == true && currentDayHasRedEyeLeg && trip.info?.calendarDaysCount as? Int ?? 0 > daysCount{
//                        labelFrame.origin.x = (CGFloat(d - buttonLength) * (WidthSize)) + WidthSize
//                        let xPoint = (CGFloat(d - buttonLength) * (WidthSize)) + 10
//                        if ((trip.vacationOverlapType?.intValue)! > 0) {
//                            var redimageLabel = UILabel()
//                            let redimageLabelFrame = CGRect(x: xPoint , y: labelFrame.origin.y + 7, width: 25, height: 25)
//                            redimageLabel.frame = redimageLabelFrame
//                            redimageLabel.text = "$"
//                            redimageLabel.textColor = .white
//                            redimageLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
//                            redimageLabel.textAlignment = .center
//                            redimageLabel.backgroundColor = .clear // Or add a debug color like .red
//                            
//                            labelButton?.addSubview(redimageLabel)
//                        }
//                        else{
//                            var redimageView = UIImageView()
//                            let redEyeImageFrame = CGRect(x: xPoint , y: labelFrame.origin.y + 13, width: 38, height: 12)
//                            if #available(iOS 13.0, *) {
//                                redimageView = UIImageView(image: UIImage(systemName: "eye.fill"))
//                            } else {
//                                redimageView = UIImageView(image: UIImage(named: "RedEye"))
//                            }
//                            redimageView.contentMode = .scaleAspectFit
//                            redimageView.tintColor = .white
//                            redimageView.frame = redEyeImageFrame
//                            labelButton?.addSubview(redimageView)
//                        }
//                    }
//                }
//                if (otherButton != nil) && d < buttonLength && trip.isRedEyeTrip?.boolValue == true && currentDayHasRedEyeLeg && trip.info?.calendarDaysCount as? Int ?? 0 > daysCount{
//                    labelButton = otherButton
//                    labelFrame.origin.x = (CGFloat(d - buttonLength) * (WidthSize)) + WidthSize
//                }
//                let label = UILabel(frame: labelFrame)
//                label.textAlignment = .center
//                if (trip.highlightCount?.intValue)! > 0 && !isTripInVacation{
//                    label.textColor = CBColor.tripHighlightColor()
//                } else {
//                    label.textColor = UIColor.white
//                }
//                label.font = UIFont.boldSystemFont(ofSize: 13.0)
////                let day: BIDay? = (orderedDays[d] as! BIDay)
////                let dayInfo: BIDayInfo? = day?.info
//                //&& (trip.vacationOverlapType?.intValue)! > 0 // may be we need to add this condition also
//                if ((bidPeriod!.swaptimizerStatus?.intValue)! == CBSwaptimizerStatus.enabled.rawValue) && !((day?.displayType?.intValue)! == BIDayDisplayType.normal.rawValue) {
//                    if day?.displayType?.intValue == BIDayDisplayType.fullPay.rawValue {
//                        label.text = "$"
//                    }
//                    else if (day?.displayType?.intValue) == BIDayDisplayType.partialPay.rawValue {
//                        label.text = "¢"
//                    } else {
//                        label.text = "x"
//                    }
//                    if bidPeriod!.isFlightAttendantBid() {
//                        let timeLabelFrame = CGRect(x: labelFrame.origin.x, y: labelFrame.origin.y + labelFrame.size.height - 12.0, width: labelFrame.size.width, height: 10.0)
//                        let timeLabel = UILabel(frame: timeLabelFrame)
//                        timeLabel.font = UIFont.systemFont(ofSize: 10.0)
//                        if (trip.highlightCount?.intValue)! > 0 && !isTripInVacation {
//                            timeLabel.textColor = CBColor.tripHighlightColor()
//                        }
//                        else {
//                            timeLabel.textColor = UIColor.white
//                        }
//                        timeLabel.textAlignment = .center
//                        var returnTime: Int = convertMinutesToHours(dayInfo!.orderedLegs().last!.arriveMinutes!.intValue)
//                        if trip.isReserve() {
//                            returnTime = (trip.info?.returnTime!.intValue)!
//                        }
//                        timeLabel.text = String(format: "%04zd", returnTime % 2400)
//                        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
//                            let arriveFormatter = DateFormatter()
//                            arriveFormatter.dateFormat = "HHmm"
//                            arriveFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo!.orderedLegs().last!.arriveCity!)
//                            
//                            var calendar = Calendar(identifier: .gregorian)
//                            calendar.locale = Locale(identifier: "en_US")
//                            calendar.timeZone = TimeZone(identifier: "US/Central")!
//                            
//                            var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate! as Date)
//                            dateComps.minute =  dayInfo!.orderedLegs().last!.arriveMinutes!.intValue
//                            if trip.isReserve() {
//                                dateComps.minute = CBUtils.getMinsFromHourMinFormat(minut: returnTime)
//                            }
//                            let arriveDate = calendar.date(from: dateComps)
//                            timeLabel.text = arriveFormatter.string(from: arriveDate!)
//                        }
//                        if UserDefaults.standard.bool(forKey: "IsSelectedReporTimeForTripButton") == true && !trip.isReserve(){
//                            timeLabel.text = String(format: "%04zd", (day?.info?.releaseTime as! Int) % 2400)
//                            if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
//                                let departFormatter = DateFormatter()
//                                departFormatter.dateFormat = "HHmm"
//                                departFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo!.orderedLegs().last!.arriveCity!)
//                                
//                                var calendar = Calendar(identifier: .gregorian)
//                                calendar.locale = Locale(identifier: "en_US")
//                                calendar.timeZone = TimeZone(identifier: "US/Central")!
//                                
//                                var dateComps = calendar.dateComponents([.year, .month, .day], from: (day?.date!)! as Date)
//                                var lastDepartMinutes = 0
//                                if let lastLeg = dayInfo?.orderedLegs().last {
//                                    // Access properties of the last leg
//                                     lastDepartMinutes = Int(truncating: lastLeg.arriveMinutes!)
//                                    // Perform operations with lastDepartMinutes
//                                }
//                                dateComps.minute =  lastDepartMinutes + Int(truncating: (trip.info?.debriefMinutes!)!)
//                                let departDate = calendar.date(from: dateComps)
//                                timeLabel.text = departFormatter.string(from: departDate!)
//                            }
//                        }
//                        timeLabel.backgroundColor = UIColor.clear
//                        labelButton?.addSubview(timeLabel)
//                         
//                        // First day of trip. Show depart time.
//                        if(true){
//    //                    if nil == dayInfo?.previousDay {
//                            let timeLabelFrame = CGRect(x: labelFrame.origin.x, y: labelFrame.origin.y + 2.0, width: labelFrame.size.width, height: 10.0)
//                            let timeLabel = UILabel(frame: timeLabelFrame)
//                            timeLabel.font = UIFont.systemFont(ofSize: 10.0)
//                            if (trip.highlightCount?.intValue)! > 0 && !isTripInVacation {
//                                timeLabel.textColor = CBColor.tripHighlightColor()
//                            } else {
//                                timeLabel.textColor = UIColor.white
//                            }
//                            timeLabel.textAlignment = .center
//                            var departTime: Int = convertMinutesToHours(dayInfo!.orderedLegs().first!.departMinutes!.intValue)
//                            if trip.isReserve() {
//                                departTime = (trip.info?.departTime!.intValue)!
//                            }
//                            timeLabel.text = String(format: "%04zd", departTime % 2400)
//                            if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
//                                let departFormatter = DateFormatter()
//                                departFormatter.dateFormat = "HHmm"
//                                departFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo!.orderedLegs().first!.departCity!)
//                                
//                                var calendar = Calendar(identifier: .gregorian)
//                                calendar.locale = Locale(identifier: "en_US")
//                                calendar.timeZone = TimeZone(identifier: "US/Central")!
//                                
//                                var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate! as Date)
//                                dateComps.minute =  dayInfo!.orderedLegs().first!.departMinutes!.intValue
//                                if trip.isReserve() {
//                                    dateComps.minute = CBUtils.getMinsFromHourMinFormat(minut: departTime)
//                                }
//                                let departDate = calendar.date(from: dateComps)
//                                timeLabel.text = departFormatter.string(from: departDate!)
//                            }
//                            if UserDefaults.standard.bool(forKey: "IsSelectedReporTimeForTripButton") == true && !trip.isReserve(){
//                                timeLabel.text = String(format: "%04zd", (day?.info?.reportTime as! Int) % 2400)
//                                if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
//                                    let departFormatter = DateFormatter()
//                                    departFormatter.dateFormat = "HHmm"
//                                    departFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo!.orderedLegs().first!.departCity!)
//                                    
//                                    var calendar = Calendar(identifier: .gregorian)
//                                    calendar.locale = Locale(identifier: "en_US")
//                                    calendar.timeZone = TimeZone(identifier: "US/Central")!
//                                    
//                                    var dateComps = calendar.dateComponents([.year, .month, .day], from: (day?.date!)! as Date)
//                                    dateComps.minute =  dayInfo!.reportTime!.intValue
//                                    
//                                    //dateComps.minute = Int(truncating: dayInfo!.orderedLegs()[0].departMinutes!) - Int(truncating: (trip.info?.briefMinutes)!)
//                                    if (d == 0) {
//                                        dateComps.minute = Int(truncating: dayInfo!.orderedLegs()[0].departMinutes!) - Int(truncating: (trip.info?.briefMinutes)!)
//                                    } else {
//                                        dateComps.minute = Int(truncating: dayInfo!.orderedLegs()[0].departMinutes!) - Int(truncating: (trip.info?.debriefMinutes)!)
//                                    }
//                                    let departDate = calendar.date(from: dateComps)
//                                    timeLabel.text = departFormatter.string(from: departDate!)
//                                }
//                            }
//                            
//                            timeLabel.backgroundColor = UIColor.clear
//                            labelButton?.addSubview(timeLabel)
//                        }
//                    }
//                    
//                    label.font = UIFont.boldSystemFont(ofSize: 20.0)
//                } else {
//                    // Last day of trip. Show pay and return time.
////                    if (nil == dayInfo?.nextDay) {
//                    if (true) {
//                        if bidPeriod!.isFlightAttendantBid() && trip.isReserve() {
//                            if BIFaReserveLineType.BIFaReserveLineTypeSnrAMres.rawValue == (line?.faReserveLineType?.intValue) {
//                                label.text = "SA"
//                            }
//                            else if BIFaReserveLineType.BIFaReserveLineTypeSnrPMres.rawValue == (line?.faReserveLineType?.intValue) {
//                                label.text = "SP"
//                            }
//                            else if BIFaReserveLineType.BIFaReserveLineTypeJnrAMres.rawValue == line?.faReserveLineType?.intValue {
//                                label.text = "JA"
//                            }
//                            else if BIFaReserveLineType.BIFaReserveLineTypeJnrPMres.rawValue == line?.faReserveLineType?.intValue {
//                                label.text = "JP"
//                            }
//                            else if BIFaReserveLineType.BIFaReserveLineTypeJnrLateRes.rawValue == (line?.faReserveLineType?.intValue) {
//                                label.text = "JL"
//                            }
//                        }
//                        else if bidPeriod!.isFlightAttendantBid() {
//                            //MyCode
//                            label.text = String(format: "%1.1f", trip.info!.faPay!.floatValue)
//                        }
//                        else {
//                            let tripPay = String(describing: trip.info!.pay())
//                            let floatTripPay = Float(tripPay)
//                            label.text = String(format: "%1.1f", floatTripPay!)
//                        }
//                        
//                        let timeLabelFrame = CGRect(x: labelFrame.origin.x, y: labelFrame.origin.y + labelFrame.size.height - 12.0, width: labelFrame.size.width, height: 10.0)
//                        let timeLabel = UILabel(frame: timeLabelFrame)
//                        timeLabel.font = UIFont.systemFont(ofSize: 10.0)
//                        if (trip.highlightCount?.intValue)! > 0 && !isTripInVacation {
//                            timeLabel.textColor = CBColor.tripHighlightColor()
//                        }
//                        else {
//                            timeLabel.textColor = UIColor.white
//                        }
//                        timeLabel.textAlignment = .center
//                        var returnTime: Int = convertMinutesToHours(dayInfo!.orderedLegs().last!.arriveMinutes!.intValue)
//                        if trip.isReserve() {
//                            returnTime = (trip.info?.returnTime!.intValue)!
//                        }
//                        // For reserve trips the return time is the end of RAP.
//                        //if (trip.isReserve) {
//                        //    returnTime += (trip.info.debriefMinutes.integerValue / 60) * 100;
//                        //}
//                        timeLabel.text = String(format: "%04zd", returnTime % 2400)
//                        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
//                            let arriveFormatter = DateFormatter()
//                            arriveFormatter.dateFormat = "HHmm"
//                            arriveFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo!.orderedLegs().last!.arriveCity!)
//                            
//                            var calendar = Calendar(identifier: .gregorian)
//                            calendar.locale = Locale(identifier: "en_US")
//                            calendar.timeZone = TimeZone(identifier: "US/Central")!
//                            
//                            var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate! as Date)
//                            dateComps.minute =  dayInfo!.orderedLegs().last!.arriveMinutes!.intValue
//                            if trip.isReserve() {
//                                dateComps.minute = CBUtils.getMinsFromHourMinFormat(minut: returnTime)
//                            }
//                            let arriveDate = calendar.date(from: dateComps)
//                            timeLabel.text = arriveFormatter.string(from: arriveDate!)
//                        }
//                        if UserDefaults.standard.bool(forKey: "IsSelectedReporTimeForTripButton") == true && !trip.isReserve(){
//                            timeLabel.text = String(format: "%04zd", (day?.info?.releaseTime as! Int) % 2400)
//                            if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
//                                let departFormatter = DateFormatter()
//                                departFormatter.dateFormat = "HHmm"
//                                departFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo!.orderedLegs().last!.arriveCity!)
//                                
//                                var calendar = Calendar(identifier: .gregorian)
//                                calendar.locale = Locale(identifier: "en_US")
//                                calendar.timeZone = TimeZone(identifier: "US/Central")!
//                                
//                                var dateComps = calendar.dateComponents([.year, .month, .day], from: (day?.date!)! as Date)
//                                var lastDepartMinutes = 0
//                                if let lastLeg = dayInfo?.orderedLegs().last {
//                                    // Access properties of the last leg
//                                     lastDepartMinutes = Int(truncating: lastLeg.arriveMinutes!)
//                                    // Perform operations with lastDepartMinutes
//                                }
//                                dateComps.minute =  lastDepartMinutes + Int(truncating: (trip.info?.debriefMinutes!)!)
//                                let departDate = calendar.date(from: dateComps)
//                                timeLabel.text = departFormatter.string(from: departDate!)
//                            }
//                        }
//                        timeLabel.backgroundColor = UIColor.clear
//                        labelButton?.addSubview(timeLabel)
//                        
//                    }
//                        // All except last day. Show overnight city.
//                    if (nil != dayInfo?.nextDay) {
//                        label.text = dayInfo?.city
//                        //let rightBorderAdjustPoint = isSaturday(date: day?.date) ? 24.5 : 19.0
//                        var rightBorderAdjustPoint = 0.0
//                        if isSaturday(date: day?.date) {
//                            if CBUtils.isIPadAir5() {
//                                rightBorderAdjustPoint = 29.0
//                            } else {
//                                rightBorderAdjustPoint = CBUtils.isIPadMini() ? 24.5 : 26.5
//                            }
//                        } else {
//                            rightBorderAdjustPoint = 19.0
//                        }
//                        if trip.isRedEyeTrip?.boolValue == true && wasDateMissingInPreviousIteration && trip.info?.calendarDaysCount as? Int ?? 0 == daysCount {
//                            if isSunday(date: day?.date) {
//                                if CBUtils.isIPadAir5() {
//                                    rightBorderAdjustPoint = 29.0
//                                } else {
//                                    rightBorderAdjustPoint = CBUtils.isIPadMini() ? 24.5 : 26.5
//                                }
//                            }
//                            else {
//                                rightBorderAdjustPoint = 19.0
//                            }
//                        }
//                        var xPoint : Double = label.frame.origin.x + (WidthSize) - rightBorderAdjustPoint
//                        let overnightFrame = CGRect(x: xPoint, y: labelFrame.origin.y + 15, width: 38, height: 10.0)
//                        let overNightTimeLabel = UILabel(frame: overnightFrame)
//                        overNightTimeLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
//                        overNightTimeLabel.textColor = UIColor(named: "cb_green")!
//                        overNightTimeLabel.textAlignment = .center
//                        overNightTimeLabel.text = dayInfo?.getOvernightTime(tripObj: trip) ?? ""
//                        overNightTimeLabel.backgroundColor = UIColor.clear
//                        overNightTimeLabel.translatesAutoresizingMaskIntoConstraints = true
//                        labelButton?.addSubview(overNightTimeLabel)
//                        overNightTimeLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-90.0 * .pi / 180.0))
//                    }
//                    // First day of trip. Show depart time.
//                    if(true){
////                    if nil == dayInfo?.previousDay {
//                        let timeLabelFrame = CGRect(x: labelFrame.origin.x, y: labelFrame.origin.y + 2.0, width: labelFrame.size.width, height: 10.0)
//                        let timeLabel = UILabel(frame: timeLabelFrame)
//                        timeLabel.font = UIFont.systemFont(ofSize: 10.0)
//                        if (trip.highlightCount?.intValue)! > 0 && !isTripInVacation {
//                            timeLabel.textColor = CBColor.tripHighlightColor()
//                        } else {
//                            timeLabel.textColor = UIColor.white
//                        }
//                        timeLabel.textAlignment = .center
//                        var departTime: Int = convertMinutesToHours(dayInfo!.orderedLegs().first!.departMinutes!.intValue)
//                        if trip.isReserve() {
//                            departTime = (trip.info?.departTime!.intValue)!
//                        }
//                        // For reserve trips the depart time is the RAP start time.
//                        //if (trip.isReserve) {
//                        //    departTime -= (trip.info.briefMinutes.integerValue / 60) * 100;
//                        //}
//                        timeLabel.text = String(format: "%04zd", departTime % 2400)
//                        
//                        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
//                            let departFormatter = DateFormatter()
//                            departFormatter.dateFormat = "HHmm"
//                            departFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo!.orderedLegs().first!.departCity!)
//                            
//                            var calendar = Calendar(identifier: .gregorian)
//                            calendar.locale = Locale(identifier: "en_US")
//                            calendar.timeZone = TimeZone(identifier: "US/Central")!
//                            
//                            var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate! as Date)
//                            dateComps.minute =  dayInfo!.orderedLegs().first!.departMinutes!.intValue
//                            if trip.isReserve() {
//                                dateComps.minute = CBUtils.getMinsFromHourMinFormat(minut: departTime)
//                            }
//                            let departDate = calendar.date(from: dateComps)
//                            timeLabel.text = departFormatter.string(from: departDate!)
//                        }
//                        if UserDefaults.standard.bool(forKey: "IsSelectedReporTimeForTripButton") == true && !trip.isReserve(){
//                            timeLabel.text = String(format: "%04zd", (day?.info?.reportTime as! Int) % 2400)
//                            if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
//                                let departFormatter = DateFormatter()
//                                departFormatter.dateFormat = "HHmm"
//                                departFormatter.timeZone = CBUtils.timeZone(forAirportCode: dayInfo!.orderedLegs().first!.departCity!)
//                                
//                                var calendar = Calendar(identifier: .gregorian)
//                                calendar.locale = Locale(identifier: "en_US")
//                                calendar.timeZone = TimeZone(identifier: "US/Central")!
//                                
//                                var dateComps = calendar.dateComponents([.year, .month, .day], from: (day?.date!)! as Date)
//                                dateComps.minute =  dayInfo!.reportTime!.intValue
//                                
//                                //dateComps.minute = Int(truncating: dayInfo!.orderedLegs()[0].departMinutes!) - Int(truncating: (trip.info?.briefMinutes)!)
//                                if (d == 0) {
//                                    dateComps.minute = Int(truncating: dayInfo!.orderedLegs()[0].departMinutes!) - Int(truncating: (trip.info?.briefMinutes)!)
//                                } else {
//                                    dateComps.minute = Int(truncating: dayInfo!.orderedLegs()[0].departMinutes!) - Int(truncating: (trip.info?.debriefMinutes)!)
//                                }
//                                let departDate = calendar.date(from: dateComps)
//                                timeLabel.text = departFormatter.string(from: departDate!)
//                            }
//                        }
//                        
//                        timeLabel.backgroundColor = UIColor.clear
//                        labelButton?.addSubview(timeLabel)
//                    }
//                }
//                app = UIApplication.shared.delegate as? AppDelegate
//                let hideVacation: Bool = UserDefaults.standard.bool(forKey: kCBHideVacationKey)
//                if bidPeriod!.isFlightAttendantBid() && !hideVacation {
//                    if (day?.displayType?.intValue) == BIDayDisplayType.fullPay.rawValue {
//                        label.text = "$"
//                        label.font = UIFont.boldSystemFont(ofSize: 20.0)
//                    }
//                    else if (day?.displayType?.intValue) == BIDayDisplayType.partialPay.rawValue {
//                        label.text = "¢"
//                    }
//                    else if (day?.displayType?.intValue) == BIDayDisplayType.noPay.rawValue {
//                        label.text = "x"
//                        label.font = UIFont.boldSystemFont(ofSize: 20.0)
//                    }
//                }
//                label.backgroundColor = UIColor.clear
//                labelButton?.addSubview(label)
//                wasDateMissingInPreviousIteration = isDateMissing
//            }
//        }
//  
//        if nil == vacationButtons {
//            vacationButtons = NSMutableArray()
//        }
//        
//        let Vcount: Int = (vacationButtons?.count)!
//        
//        for i in 0..<Vcount {
//            let vacationbutton = vacationButtons?[i] as? UIImageView
//            if vacationbutton != nil {
//                vacationbutton?.removeFromSuperview()
//            }
//        }
//        vacationButtons?.removeAllObjects()
//        vacationButtons?.addObjects(from: calendarDaysArr)
//        let hideVacation: Bool = UserDefaults.standard.bool(forKey: kCBHideVacationKey)
//        
//        // Add vacation pill
//        if !(hideVacation && (bidPeriod!.containsVacay?.boolValue == true)) {
//            var vacayButtonFrame = CGRect(x: 0.0, y: 0.0, width: (WidthSize), height: (itemSize?.height)!)
//            var buttonImage: UIImage? = nil
//            let vacations = bidPeriod!.vacations
//            for vacation in vacations! {
//                let vacay = vacation as! BIVacation
//                var index: Int = calendarData!.indexForDate(date: vacay.startDate! as Date)
//                var tripLength: Int = 0
//                if index < 0 {
//                    tripLength = (vacay.length?.intValue)! + index
//                    index = 0
//                }
//                else if index > (daysInCalendar - 1) {
//                    continue
//                }
//                else {
//                    tripLength = vacay.length as! Int
//                }
//                
//                let column: Int = index % 7
//                var buttonLength: Int = 0
//                
//                // If vacation pill will go across two rows in calendar, create both buttons.
//                if column + tripLength > 7 {
//                    buttonLength = 7 - column
//                    vacayButtonFrame.size.width = CGFloat(buttonLength) * (WidthSize)
//                    buttonImage = UIImage(named: bidPeriod!.getVacationImageName(.letf))?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    vacayButtonFrame.size.width = min(CGFloat(tripLength), 7.0) * (WidthSize)
//                    let button2 = UIImageView(frame: vacayButtonFrame)
//                    button2.image = buttonImage
//                    vacationButtons?.replaceObject(at: index, with: button2)
//                    button2.alpha = 0.6
//                    collectionView.addSubview(button2)
//                    
//                    if (bidPeriod!.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
//                        button2.isUserInteractionEnabled = true
//                        button2.isOpaque = false
//                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                        longPressGesture.minimumPressDuration = 0.5
//                        longPressGesture.cancelsTouchesInView = false
//                        button2.addGestureRecognizer(longPressGesture)
//                        longPressGesture.delegate = self
//                        vacayGestureRecognizers.add(longPressGesture)
//                    }
//                    
//                    tripLength -= buttonLength
//                    index += buttonLength
//                    while tripLength > 0 {
//                        buttonLength = tripLength > 7 ? 7 : tripLength
//                        if index < daysInCalendar {
//                            vacayButtonFrame.size.width = min(CGFloat(buttonLength), CGFloat(7.0)) * (WidthSize)
//                            // Check to see if we need to get it to draw a bit farther to the right to get the double flat
//                            // side effect
//                            if tripLength > 7 {
//                                vacayButtonFrame.size.width += 15.0
//                            }
//                            
//                            buttonImage = UIImage(named: bidPeriod!.getVacationImageName(.right))?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                            let otherButton2 = UIImageView(frame: vacayButtonFrame)
//                            otherButton2.image = buttonImage
//                            vacationButtons?.replaceObject(at: index, with: otherButton2)
//                            //                            vacationButtons.replacePointer(at: index, withPointer: (otherButton2 as? Void))
//                            otherButton2.alpha = 0.6
//                            collectionView.addSubview(otherButton2)
//                            
//                            if (bidPeriod!.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
//                                otherButton2.isUserInteractionEnabled = true
//                                otherButton2.isOpaque = false
//                                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                                longPressGesture.minimumPressDuration = 0.5
//                                longPressGesture.cancelsTouchesInView = false
//                                otherButton2.addGestureRecognizer(longPressGesture)
//                                longPressGesture.delegate = self
//                                vacayGestureRecognizers.add(longPressGesture)
//                            }
//                        }
//                        tripLength -= buttonLength
//                        index += buttonLength
//                    }
//                } else {
//                    if index < 0 {
//                        // Vacation starts before the visible calendar days, so show the rounded right image
//                        let imageName = bidPeriod!.getVacationImageName(.right)
//                        buttonImage = UIImage(named: imageName)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                    else if (index + tripLength - 1) > (daysInCalendar - 1) {
//                        // Vacay ends after the visible calendar days, so show the rounded left image
//                        let imageName = bidPeriod!.getVacationImageName(.letf)
//                        buttonImage = UIImage(named: imageName)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    } else {
//                        let imageName = bidPeriod!.getVacationImageName(.both)
//                        buttonImage = UIImage(named: imageName)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                    vacayButtonFrame.size.width = CGFloat(tripLength) * (WidthSize)
//                    let button2 = UIImageView(frame: vacayButtonFrame)
//                    button2.image = buttonImage
//                    vacationButtons?.replaceObject(at: index, with: button2)
//                    button2.alpha = 0.6
//                    collectionView.addSubview(button2)
//                    if (bidPeriod!.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
//                        button2.isUserInteractionEnabled = true
//                        button2.isOpaque = false
//                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                        longPressGesture.minimumPressDuration = 0.5
//                        longPressGesture.cancelsTouchesInView = false
//                        //longPressGesture.numberOfTapsRequired = 0;
//                        button2.addGestureRecognizer(longPressGesture)
//                        longPressGesture.delegate = self
//                        vacayGestureRecognizers.add(longPressGesture)
//                    }
//                }
//            }
//        }
//        
//        //Remove FV
//        if fvVacationButtons == nil {
//            fvVacationButtons = NSMutableArray()
//        }
//        let FVcount: Int = (fvVacationButtons?.count)!
//        for i in 0 ..< FVcount {
//            let fvVacationButton = fvVacationButtons?[i] as? UIImageView
//            if fvVacationButton != nil {
//                fvVacationButton?.removeFromSuperview()
//            }
//        }
//        fvVacationButtons?.removeAllObjects()
//        fvVacationButtons?.addObjects(from: calendarDaysArr)
//        
//        //Remove CFV
//        if cfvVacationButtons == nil {
//            cfvVacationButtons = NSMutableArray()
//        }
//        let CFVcount: Int = (cfvVacationButtons?.count)!
//        for i in 0 ..< CFVcount {
//            let cfvVacationButton = cfvVacationButtons?[i] as? UIImageView
//            if cfvVacationButton != nil {
//                cfvVacationButton?.removeFromSuperview()
//            }
//        }
//        cfvVacationButtons?.removeAllObjects()
//        cfvVacationButtons?.addObjects(from: calendarDaysArr)
//        
//        for view in self.collectionView.subviews {
//            if view.tag == 99 {
//                view.removeFromSuperview()
//            }
//        }
//        
//        // FV vacation and CFV vacation
//        // Add vacation pill
//        if !(hideVacation && (bidPeriod!.containsVacay?.boolValue == true)) {
//            var vacayButtonFrame = CGRect(x: 0.0, y: 0.0, width: (WidthSize), height: (itemSize?.height)!)
//            var buttonImage: UIImage? = nil
//            
//            var removeCFV = false
//            if UserDefaults.standard.value(forKey: "RemoveCfv") != nil {
//                removeCFV = UserDefaults.standard.bool(forKey: "RemoveCfv")
//            }
//            if removeCFV == false && self.bidPeriod!.containsCFV == true && (self.line?.cfvVacDates?.count ?? 0) > 0 {
//                for i in 0 ..< (self.line?.cfvVacDates?.count)! {
//                    let cfvDates = self.line?.cfvVacDates?.object(at: i) as? String
//                    let cfv = UILabel()
//                    cfv.backgroundColor = .darkGray
//                    cfv.alpha = 1
//                    cfv.tag = 99
//                    cfv.text = "$FV"
//                    cfv.textAlignment = .center
//                    cfv.font = .boldSystemFont(ofSize: 14)
//                    cfv.textColor = .white
//                    
//                    let dateString = "\(cfvDates ?? "")-\(self.bidPeriod!.month?.intValue ?? 0)-\(self.bidPeriod!.year?.intValue ?? 0000)"
//                    let dateFormatter = DateFormatter()
//                    dateFormatter.dateFormat = "d-M-yyyy"
//                    let timeZone = TimeZone(secondsFromGMT: 0)
//                    dateFormatter.timeZone = timeZone
//                    let cfvDATE = dateFormatter.date(from: dateString)
//                    let index = self.calendarData?.indexForDate(date: cfvDATE!)
//
//                    let indexPath1 = IndexPath(row: index! + 1, section: 0)
//                    let buttonLayoutAttributes1 = self.collectionView.layoutAttributesForItem(at: indexPath1)
//                    let height: CGFloat = 38.0
//                    let cfvFrame = CGRect(x: (buttonLayoutAttributes1?.frame.minX)!, y: (buttonLayoutAttributes1?.frame.minY)!, width: (buttonLayoutAttributes1?.frame.width)!-2, height: height)
////                    let vacayButtonFrame = buttonLayoutAttributes1?.frame
//                    cfv.frame = cfvFrame
//                    cfv.layer.cornerRadius = 17
//                    cfv.layer.masksToBounds = true
//                    cfvVacationButtons?.replaceObject(at: index! + 1, with: cfv)
//                    self.collectionView.addSubview(cfv)
//                }
//            }
//            if let vacations = line?.fvvacations?.allObjects {
//                let vacationArray = Array(vacations)
//                for vacation in vacationArray {
//
//                        let vacay = vacation as! BIVacation
//                    if  vacay.fvStartdate == nil{
//                        self.bidPeriod?.managedObjectContext?.delete(vacay)
//                        continue
//                    }
//                    
//                    
//                        var index: Int = calendarData!.indexForDate(date: vacay.fvStartdate! as Date)
//                        var tripLength: Int = 0
//                        if index < 0 {
//                            tripLength = (vacay.fvLength?.intValue)! + index
//                            index = 0
//                        }
//                        else if index > (daysInCalendar - 1) {
//                            continue
//                        }
//                        else {
//                            tripLength = vacay.fvLength as! Int
//                        }
//                        
//                        let column: Int = index % 7
//                        var buttonLength: Int = 0
//                        
//                        // If vacation pill will go across two rows in calendar, create both buttons.
//                        if column + tripLength > 7 {
//                            buttonLength = 7 - column
//                            vacayButtonFrame.size.width = CGFloat(buttonLength) * (WidthSize)
//                            buttonImage = UIImage(named: userDefaults.string(forKey: kCBTripButtonRoundedLeftFVBlueImageNameKey)!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                            vacayButtonFrame.size.width = min(CGFloat(tripLength), 7.0) * (WidthSize)
//                            let button2 = UIImageView(frame: vacayButtonFrame)
//                            button2.image = buttonImage
//                            fvVacationButtons?.replaceObject(at: index, with: button2)
//                            button2.alpha = 0.6
//                            collectionView.addSubview(button2)
//                            
//                            if (bidPeriod!.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
//                                button2.isUserInteractionEnabled = true
//                                button2.isOpaque = false
//                                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                                longPressGesture.minimumPressDuration = 0.5
//                                longPressGesture.cancelsTouchesInView = false
//                                button2.addGestureRecognizer(longPressGesture)
//                                longPressGesture.delegate = self
//                                vacayGestureRecognizers.add(longPressGesture)
//                            }
//                            tripLength -= buttonLength
//                            index += buttonLength
//                            while tripLength > 0 {
//                                buttonLength = tripLength > 7 ? 7 : tripLength
//                                if index < daysInCalendar {
//                                    vacayButtonFrame.size.width = min(CGFloat(buttonLength), CGFloat(7.0)) * (WidthSize)
//                                    // Check to see if we need to get it to draw a bit farther to the right to get the double flat
//                                    // side effect
//                                    if tripLength > 7 {
//                                        vacayButtonFrame.size.width += 15.0
//                                    }
//                                    buttonImage = UIImage(named: userDefaults.string(forKey: kCBTripButtonRoundedRightFVBlueImageNameKey)!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                                    let otherButton2 = UIImageView(frame: vacayButtonFrame)
//                                    otherButton2.image = buttonImage
//                                    fvVacationButtons?.replaceObject(at: index, with: otherButton2)
//                                    otherButton2.alpha = 0.6
//                                    collectionView.addSubview(otherButton2)
//                                    if (bidPeriod!.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
//                                        otherButton2.isUserInteractionEnabled = true
//                                        otherButton2.isOpaque = false
//                                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                                        longPressGesture.minimumPressDuration = 0.5
//                                        longPressGesture.cancelsTouchesInView = false
//                                        otherButton2.addGestureRecognizer(longPressGesture)
//                                        longPressGesture.delegate = self
//                                        vacayGestureRecognizers.add(longPressGesture)
//                                    }
//                                }
//                                tripLength -= buttonLength
//                                index += buttonLength
//                            }
//                        } else {
//                            
//                            if index < 0 {
//                                // Vacation starts before the visible calendar days, so show the rounded right image
//                                let imageName = userDefaults.string(forKey: kCBTripButtonRoundedRightFVBlueImageNameKey)
//                                buttonImage = UIImage(named: imageName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                            }
//                            else if (index + tripLength - 1) > (daysInCalendar - 1) {
//                                // Vacay ends after the visible calendar days, so show the rounded left image
//                                let imageName = userDefaults.string(forKey: kCBTripButtonRoundedLeftFVBlueImageNameKey)
//                                buttonImage = UIImage(named: imageName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                            } else {
//                                let imageName = userDefaults.string(forKey: kCBTripButtonRoundedBothFVBlueImageNameKey)
//                                buttonImage = UIImage(named: imageName!)?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                            }
//                            vacayButtonFrame.size.width = CGFloat(tripLength) * (WidthSize)
//                            let button2 = UIImageView(frame: vacayButtonFrame)
//                            button2.image = buttonImage
//                            fvVacationButtons?.replaceObject(at: index, with: button2)
//                            button2.alpha = 0.6
//                            collectionView.addSubview(button2)
//                            if (bidPeriod!.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
//                                button2.isUserInteractionEnabled = true
//                                button2.isOpaque = false
//                                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                                longPressGesture.minimumPressDuration = 0.5
//                                longPressGesture.cancelsTouchesInView = false
//                                button2.addGestureRecognizer(longPressGesture)
//                                longPressGesture.delegate = self
//                                vacayGestureRecognizers.add(longPressGesture)
//                            }
//                        }
//                }
//            }
//        }
//        
//        if (self.bidPeriod?.myCalEnabled?.boolValue ?? false) && self.bidPeriod!.isNeedToShowMyCal() {
//            var vacayButtonFrame = CGRect(x: 0.0, y: 0.0, width: (WidthSize), height: (itemSize?.height)!)
//            var buttonImage: UIImage? = nil
//            var tripLength: Int = 0
//            var index: Int = calendarData!.indexForDateGMT(date: self.bidPeriod!.myCalStartDate! as Date)
//            let length = self.calculateLengthBetween(startDate: self.bidPeriod!.myCalStartDate! as Date, andEndDate: self.bidPeriod!.myCalEndDate! as Date)
//            if index < 0 {
//                tripLength = length.intValue + index
//                index = 0
//            }  else if index > (daysInCalendar - 1) {
//                tripLength = 0
//            } else {
//                tripLength = length.intValue
//            }
//            
//            let column: Int = index % 7
//            var buttonLength: Int = 0
//            
//            // If vacation pill will go across two rows in calendar, create both buttons.
//            if column + tripLength > 7 {
//                buttonLength = 7 - column
//                vacayButtonFrame.size.width = CGFloat(buttonLength) * (WidthSize)
//                buttonImage = UIImage(named: "TripButton-rounded-left-red2_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                vacayButtonFrame.size.width = min(CGFloat(tripLength), 7.0) * (WidthSize)
//                let button2 = UIImageView(frame: vacayButtonFrame)
//                button2.image = buttonImage
//                fvVacationButtons?.replaceObject(at: index, with: button2)
//                button2.alpha = 0.5
//                collectionView.addSubview(button2)
//                
//                if (bidPeriod!.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
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
//                    buttonLength = tripLength > 7 ? 7 : tripLength
//                    if index < daysInCalendar {
//                        vacayButtonFrame.size.width = min(CGFloat(buttonLength), CGFloat(7.0)) * (WidthSize)
//                        // Check to see if we need to get it to draw a bit farther to the right to get the double flat
//                        // side effect
//                        if tripLength > 7 {
//                            vacayButtonFrame.size.width += 15.0
//                        }
//                        buttonImage = UIImage(named: "TripButton-rounded-right-red2_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                        let otherButton2 = UIImageView(frame: vacayButtonFrame)
//                        otherButton2.image = buttonImage
//                        fvVacationButtons?.replaceObject(at: index, with: otherButton2)
//                        otherButton2.alpha = 0.5
//                        collectionView.addSubview(otherButton2)
//                        if (bidPeriod!.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
//                            otherButton2.isUserInteractionEnabled = true
//                            otherButton2.isOpaque = false
//                            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                            longPressGesture.minimumPressDuration = 0.5
//                            longPressGesture.cancelsTouchesInView = false
//                            otherButton2.addGestureRecognizer(longPressGesture)
//                            longPressGesture.delegate = self
//                            vacayGestureRecognizers.add(longPressGesture)
//                        }
//                    }
//                    tripLength -= buttonLength
//                    index += buttonLength
//                }
//            } else {
//                buttonImage = UIImage(named: "TripButton-rounded-both-red2_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                vacayButtonFrame.size.width = CGFloat(tripLength) * (WidthSize)
//                let button2 = UIImageView(frame: vacayButtonFrame)
//                button2.image = buttonImage
//                fvVacationButtons?.replaceObject(at: index, with: button2)
//                button2.alpha = 0.5
//                collectionView.addSubview(button2)
//                if (bidPeriod!.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
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
//        collectionView.reloadData()
//        collectionView.tripButtons = tripButtons
//        collectionView.vacationButtons = vacationButtons
//        collectionView.fvVacationButtons = fvVacationButtons
//        collectionView.cfvVacationButtons = cfvVacationButtons
//    }
    
    
    
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
        posAGrayView.alpha = 1.0
        
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
        posBGrayView.alpha = 1.0
        
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
        posCGrayView.alpha = 1.0
        
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
        posDGrayView.alpha = 1.0
        
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
        //-----------------------
        
        getCalendarData(for: month, year: year)
       
        //-----------------------
    }

    @objc func longPressLineValueContainerView(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBLineValuesMenuController") as! CBLineValuesMenuController
        lineValuesController.modalPresentationStyle = .custom
        let touchPoint = gesture.location(in: self.lineValuesView)
        let frame = CGRect(x: lineValuesView.frame.origin.x, y: touchPoint.y - 80, width: lineValuesView.frame.width, height: lineValuesView.frame.height)
        lineValuesController.showPopover(sourceView: self.lineValuesView, sourceRect: frame)
    }
    
    @objc func showUserFlagMenu() {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBUserFlagTableController") as! CBUserFlagTableController
//        lineValuesController.line = line
//        lineValuesController.delegate = self
        lineValuesController.modalPresentationStyle = .popover
        lineValuesController.showPopover(sourceView: self.userFlagIconView)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarDaysArr.count
//        return 42
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath as IndexPath) as! CBBidListSmallCollectionViewCell
//        let row = indexPath.row/7
//        let col = indexPath.row%7
//        let data = CalendarData[row][col]
//        let day = data.day
//        let isbidmonth = data.isBidMonth
//        displayDay(for: cell, day: day, isBidMonth: isbidmonth)
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
//        let width = floor(collectionView.frame.width / 7)
//        return CGSize(width: width, height: 55)
        return CGSizeMake((self.contentView.frame.width - 160)/7, 45)
    }

    @IBAction func removeLineAction(_ sender: Any) {
    }
    
    @IBAction func moveLinesToBidListAction(_ sender: Any) {
        
    }
}
