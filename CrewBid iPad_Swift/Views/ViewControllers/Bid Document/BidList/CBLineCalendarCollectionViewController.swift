//
//  CBLineCalendarCollectionViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 01/08/25.
//

import UIKit

class CBLineCalendarCollectionViewController: BaseViewController, KUIPopOverUsable, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate {

    

    @IBOutlet weak var collectionView: CBBidLineCalendarCollectionView!
    @IBOutlet weak var viewBackground: UIView!
    var line: BILine?
    var calendarData: BICalendarData?
    var CollectionCellCalendarDaysArr = [Any]()
    var tripDateFormatter: DateFormatter?
    var tripButtons: NSMutableArray?
    var fvVacationButtons: NSMutableArray?
    var cfvVacationButtons: NSMutableArray?
    var vacationButtons: NSMutableArray?
    var tripButtonsArray: NSMutableArray?
    var bidPeriod: BIBidPeriod!
    var vacayGestureRecognizers = NSMutableArray()
    let kCBButtonTag = 800
    var isTripButtonsInitialized = false
    var tripTextController: CBTripTextViewController?
    var fromScrachpadView:Bool?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewBackground.clipsToBounds = true
        self.viewBackground.layer.cornerRadius = 5
        tripDateFormatter = DateFormatter()
        tripDateFormatter?.dateFormat = "dd MMM yy"
        navigationController?.delegate = self as UINavigationControllerDelegate
        resetLayout()
    }
    
    var arrowDirection: UIPopoverArrowDirection = .any

    var contentSize: CGSize {
        var size:CGSize?
        size = CGSize(width: 300.0, height: 270.0)
        return size!
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8){
            self.isTripButtonsInitialized = false
            self.collectionView.removeAllSubviewsExceptCells()
            self.resetLayout()
        }
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
       if bidPeriod.containsVacay!.boolValue && (self.bidPeriod.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
           if vacayGestureRecognizers.contains(gestureRecognizer) {
               var touchInsideVacayButton = false
               let count = vacationButtons?.count
               for i in 0 ..< count! {
                   var vButton: Any!
                   vButton = vacationButtons![i]
                   if let vButton = vButton as? UIImageView {
                       if vButton.frame.contains(touch.location(in: self.collectionView)) {
                           touchInsideVacayButton = true
                       }
                   }
               }
               let FVcount = fvVacationButtons?.count
               for i in 0 ..< FVcount! {
                   var vButton: Any!
                   vButton = fvVacationButtons![i]
                   if let vButton = vButton as? UIImageView {
                       if vButton.frame.contains(touch.location(in: self.collectionView)) {
                           touchInsideVacayButton = true
                       }
                   }
               }
               if touchInsideVacayButton {
                   // Check to make sure it wasn't a touch on one of the tripButtons inside the vacayButton
                   let count = self.tripButtons?.count
                   for i in 0 ..< count! {
                       if let tripButton = self.tripButtons![i] as? CBTripButton {
                           if tripButton.frame.contains(touch.location(in: self.collectionView)) {
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
    
    @objc func tripButtonAction(_ tripButton: CBTripButton) {
        //tripButtonActionBlock!(tripButton)
        
        let tripText: String = tripButton.trip!.tripText()
        let tripTextController = CBTripTextViewController.instantiateFromStoryboard(withTripText: tripText, button: tripButton)
        let numberValue: String = (tripButton.trip!.info?.number)!
        let date: String = tripDateFormatter!.string(from: tripButton.trip!.startDate! as Date)
        let title = String(format: "%@%@%@",numberValue," on ",date)
        (tripTextController as AnyObject).navigationItem.title = title
        self.tripTextController = tripTextController as? CBTripTextViewController
        navigationController?.navigationBar.backgroundColor = .lightGray
        
        let backItem = UIBarButtonItem()
        backItem.title = self.navigationItem.title
        navigationItem.backBarButtonItem = backItem
        navigationController?.pushViewController(tripTextController as! UIViewController, animated: true)
    }
    
    func resetLayout() {
        if !isTripButtonsInitialized {
            self.refreshCalendar()
            isTripButtonsInitialized = true
        }
        view.layoutSubviews()
    }
    
    
    func refreshCalendar() {
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
        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let itemSize: CGSize? = flowLayout?.itemSize
        let inset: CGFloat = 15.0
        let WidthSize = ((self.collectionView.frame.width)) / 7
        let insets: UIEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        var buttonFrame = CGRect(x: 0.0, y: 0.0, width: WidthSize , height: itemSize?.height ?? 0.0)
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
            let highlighted = trip.highlightCount!.intValue > 0
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
                buttonFrame.size.width = CGFloat(buttonLength) * (WidthSize)
                if trip.isRedEyeTrip {
                    buttonImage = UIImage(named: "TripButton-rounded-left-redEye_red_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
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
                            buttonImage = UIImage(named: "TripButton-rounded-left-green_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }else {
                            buttonImage = UIImage(named: "TripButton-rounded-left-orange_iOS7@2x")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }else{
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-left-red2_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }else {
                            buttonImage = UIImage(named: "TripButton-rounded-left-purple_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }
                }
                buttonFrame.size.width =  CGFloat(buttonLength) * (WidthSize)
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
                collectionView.addSubview(button)
                let nextButtonLength: Int = tripLength - buttonLength
                let nextButtonIndex: Int = index + buttonLength
                buttonFrame.size.width =  CGFloat(nextButtonLength) * (WidthSize)
                if trip.isRedEyeTrip{
                    buttonImage = UIImage(named: "TripButton-rounded-right-redEye_red_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
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
                            buttonImage = UIImage(named: "TripButton-rounded-right-green_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-right-orange_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }else {
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-right-red2_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-right-purple_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
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
                    collectionView.addSubview(otherButton!)
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
                    buttonImage = UIImage(named: "TripButton-rounded-both-redEye_red_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
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
                            buttonImage = UIImage(named: "TripButton-rounded-both-green_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-both-orange_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }else{
                        if trip.isReserve {
                            buttonImage = UIImage(named: "TripButton-rounded-both-red2_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        } else {
                            buttonImage = UIImage(named: "TripButton-rounded-both-purple_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        }
                    }
                }
                buttonFrame.size.width =  CGFloat(tripLength) * (WidthSize)
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
                collectionView.addSubview(button)
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
                labelFrame.size.width = WidthSize
                var dayIndex = d
                
                
                if !self.bidPeriod.isFABid() && (trip.info?.dutyPeriodsCount != trip.info?.calendarDaysCount) {
                    if !showingRedEyeIconForThisTrip {
                        if trip.isRedEyeTrip && (dayIndex >= missingDateIndex) && missingDateIndex != -1 {
                            labelFrame.origin.x = CGFloat(d) * WidthSize + 3
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
                labelFrame.origin.x = CGFloat(dayIndex) * WidthSize
                // Show labels in other button if day is greater than length of
                // first button. Adjust origin of label to other button.
                if otherButton != nil && dayIndex >= buttonLength {
                    labelButton = otherButton!
                    labelFrame.origin.x = CGFloat(d - buttonLength) * WidthSize + 3
                    if !self.bidPeriod.isFABid() && trip.info?.dutyPeriodsCount != trip.info?.calendarDaysCount {
                        if !showingRedEyeIconForThisTrip {
                            if trip.isRedEyeTrip && ((dayIndex - buttonLength) >= missingDateIndex || d == buttonLength) && missingDateIndex != -1 {
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
                    labelFrame.origin.x = CGFloat(dayIndex - buttonLength) * WidthSize
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
                            xValue = label.frame.origin.x + WidthSize - 13
                            let weekDayInt = CBUtils.weekDay(from: trip.startDate!)
                            let isSaturday = (weekDayInt + d == 7)
                            if isSaturday{
                                xValue = fromScrachpadView == true ? xValue - 6 : xValue - 7
                            }
                            let verticalLabelFrame = CGRect(x: xValue, y: labelFrame.origin.y + 12, width: 26, height: 10)
                            
                            let verticalLabel = UILabel(frame: verticalLabelFrame)
                            verticalLabel.textColor = CBColor.cbGreen
                            verticalLabel.textAlignment = .center
                            verticalLabel.font = UIFont.boldSystemFont(ofSize: 8)
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
            var vacayButtonFrame = CGRect(x: 0, y: 0, width: WidthSize, height: itemSize!.height)
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
//                    buttonImage = UIImage(named: "TripButton-rounded-left-yellow_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.left))?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    vacayButtonFrame.size.width = min(CGFloat(tripLength), 7) * WidthSize
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    vacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.6
                    self.collectionView.addSubview(button2)
                    
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
                        addGestureRecognizersToVacationButton(button2, line: line ?? BILine())
                    }
                    tripLength -= buttonLength
                    index += buttonLength
                    while tripLength > 0 {
                        buttonLength = tripLength > 7 ? 7 : tripLength
                        
                        if index < daysInCalendar {
                            vacayButtonFrame.size.width = min(CGFloat(buttonLength), 7) * WidthSize
                            if tripLength > 7{
                                vacayButtonFrame.size.width += 15
                            }
//                            buttonImage = UIImage(named:"TripButton-rounded-right-yellow_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                            buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.right))?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                            let otherButton2 = UIImageView(frame: vacayButtonFrame)
                            otherButton2.image = buttonImage
                            vacationButtons?.replaceObject(at: index, with: otherButton2)
                            otherButton2.alpha = 0.6
                            self.collectionView.addSubview(otherButton2)
                                
                            if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                                otherButton2.isUserInteractionEnabled = true
                                otherButton2.clipsToBounds = true
                                otherButton2.isOpaque = false
                                otherButton2.contentMode = .scaleToFill

//                                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                                longPressGesture.minimumPressDuration = 0.5
//                                longPressGesture.cancelsTouchesInView = false
//                                otherButton2.addGestureRecognizer(longPressGesture)
//                                longPressGesture.delegate = self
//                                vacayGestureRecognizers.add(longPressGesture)
                                addGestureRecognizersToVacationButton(otherButton2, line: line ?? BILine())
                            }
                        }
                    tripLength -= buttonLength
                    index += buttonLength
                    }
                }
                else{// Vacation in one row only of the calendar.
                    if index < 0 {// Vacation starts before the visible calendar days, so show the rounded right image
//                        buttonImage = UIImage(named: "TripButton-rounded-right-yellow_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.right))?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }else if (index+tripLength-1) > (daysInCalendar-1){
                        // Vacay ends after the visible calendar days, so show the rounded left image
//                        buttonImage = UIImage(named: "TripButton-rounded-left-yellow_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.left))?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }else{
//                        buttonImage = UIImage(named: "TripButton-rounded-both-yellow_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                        buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.both))?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }
                    vacayButtonFrame.size.width = CGFloat(tripLength) * WidthSize
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    vacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.6
                    self.collectionView.addSubview(button2)
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
                        addGestureRecognizersToVacationButton(button2, line: line ?? BILine())
                    }
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
        fvVacationButtons?.addObjects(from: CollectionCellCalendarDaysArr)
        
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
        cfvVacationButtons?.addObjects(from: CollectionCellCalendarDaysArr)
        
        for view in self.collectionView.subviews {
                if view.tag == 99 {
                    view.removeFromSuperview()
                }
        }
        if self.bidPeriod.containsVacay!.boolValue {
            var vacayButtonFrame = CGRect(x: 0, y: 0, width: WidthSize, height: WidthSize)
            var buttonImage:UIImage? = nil
            let vacations = self.line?.fvvacations
            let arrVacationIndexes = NSMutableArray()
            let removeCFV = userDefaults.bool(forKey: "RemoveCfv")
            if (self.line?.cfvVacDates?.count) ?? 0 > 0{
                if !removeCFV {
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
                        let buttonLayoutAttributes1 = self.collectionView.layoutAttributesForItem(at: indexPath1)!
                        let height: CGFloat = 28.0
                        let cfvFrame = CGRect(x: (buttonLayoutAttributes1.frame.minX), y: (buttonLayoutAttributes1.frame.minY), width: (buttonLayoutAttributes1.frame.width)-5, height: height)
                        cfv.frame = cfvFrame
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
                    vacayButtonFrame.size.width = WidthSize * CGFloat(buttonLength)
                    buttonImage = UIImage(named:"TripButton-rounded-left-FVBlue_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    vacayButtonFrame.size.width = min(CGFloat(tripLength), 7) * WidthSize
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    fvVacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.7
                    self.collectionView.addSubview(button2)
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
                        addGestureRecognizersToVacationButton(button2, line: line ?? BILine())
                    }
                    tripLength -= buttonLength
                    index += buttonLength
                    while tripLength > 0 {
                        buttonLength = tripLength > 7 ? 7 : tripLength
                        if index < daysInCalendar{
                            vacayButtonFrame.size.width = min(CGFloat(buttonLength), 7) * WidthSize
                            if tripLength > 7 {
                                vacayButtonFrame.size.width += 15
                            }
                                buttonImage = UIImage(named:"TripButton-rounded-right-FVBlue_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                                let otherButton2 = UIImageView(frame: vacayButtonFrame)
                                otherButton2.image = buttonImage
                                fvVacationButtons?.replaceObject(at: index, with: otherButton2)
                                otherButton2.alpha = 0.7
                                self.collectionView.addSubview(otherButton2)
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
                                    addGestureRecognizersToVacationButton(otherButton2, line: line ?? BILine())
                                }
                            }
                            tripLength -= buttonLength
                            index += buttonLength
                        }
                    }
                else{ // Vacation in one row only of the calendar.
                    if index < 0 {
                        // Vacation starts before the visible calendar days, so show the rounded right image
                        buttonImage = UIImage(named: "TripButton-rounded-right-FVBlue_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }else if (index + tripLength - 1) > (daysInCalendar - 1) {
                        // Vacay ends after the visible calendar days, so show the rounded left image
                        buttonImage = UIImage(named: "TripButton-rounded-left-FVBlue_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }else{
                        buttonImage = UIImage(named: "TripButton-rounded-both-FVBlue_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    }
                    vacayButtonFrame.size.width = CGFloat(tripLength) * WidthSize
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    fvVacationButtons?.replaceObject(at: index, with: button2)
                    button2.alpha = 0.7
                    self.collectionView.addSubview(button2)
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
                        addGestureRecognizersToVacationButton(button2, line: line ?? BILine())
                    }
                }
            }
        }
        self.collectionView.reloadData()
        self.collectionView.tripButtons = tripButtons
        self.collectionView.vacationButtons = vacationButtons
        self.collectionView.fvVacationButtons = fvVacationButtons
        self.collectionView.cfvVacationButtons = cfvVacationButtons
    }
    
    func addGestureRecognizersToVacationButton(_ button: UIView, line: BILine) {
            let doubleTap = VacationTapGestureRecognizer(target: self,
                                                         action: #selector(handleVacationDoubleTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            doubleTap.delegate = self
            doubleTap.line = line
            button.addGestureRecognizer(doubleTap)
            vacayGestureRecognizers.add(doubleTap)
        }

        @objc private func handleVacationDoubleTap(_ gesture: VacationTapGestureRecognizer) {
            guard let tappedView = gesture.view,
                  let line = gesture.line else { return }
            showVacationPopover(for: tappedView, line: line)
        }
    
    @objc func showSWAPtimizerTripOptionsPopover(_ gesture: UILongPressGestureRecognizer) {
        
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CollectionCellCalendarDaysArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let kDayCellIdentifer = "DayCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kDayCellIdentifer, for: indexPath as IndexPath) as! CBBidListSmallCollectionViewCell
        cell.contentView.frame = cell.bounds
        cell.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let calendeday = CollectionCellCalendarDaysArr[indexPath.row] as! BICalendarDay
        cell.dayLabel.text = calendeday.text
        let currentMonth = calendeday.isCurrentMonth
        if currentMonth {
            cell.dayLabel.alpha = 1
        } else {
            cell.dayLabel.alpha = 0.5
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: 40)
    }
    
    //    vacation line value popover view
        func showVacationPopover(for sourceView: UIView, line: BILine?) {
            if bidPeriod?.userVacationWbidOrCrewBid == "CREWBID" || bidPeriod?.userVacationWbidOrCrewBid == "CREWBIDF" {
                return
            }
            let storyboard = UIStoryboard(name: "FlightDataChange", bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: "CBVacationDataVC") as? CBVacationDataVC else {
                return
            }

            if let line = line {
                vc.line = line
            }
            vc.bidPeriod = self.bidPeriod
            vc.modalPresentationStyle = .popover
            vc.preferredContentSize = CGSize(width: 320, height: 420)

            if let popover = vc.popoverPresentationController {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
                popover.permittedArrowDirections = [.up, .down]
                popover.delegate = self
            }

            present(vc, animated: true)
            
        }
}

extension UICollectionView {
    func removeAllSubviewsExceptCells() {
        for subview in subviews {
            if !(subview is UICollectionViewCell) {
                subview.removeFromSuperview()
            }
        }
    }
}
