//
//  CBAwardLineCalendarViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 17/04/25.
//

import UIKit
import MessageUI
import EventKit
import EventKitUI

class CBAwardLineCalendarViewController: UIViewController, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate, EKCalendarChooserDelegate, UIPrintInteractionControllerDelegate {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblLineNumber: UILabel!
    @IBOutlet weak var lblFaPosition: UILabel!
    @IBOutlet weak var collectionView: AwardCalendarCollectionViewVC!
    @IBOutlet weak var viewLineValues: UIView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    
    var line: BILine?
    var calendarData: BICalendarData?
    var calendarDayArr : [BICalendarDay] = []
    var bidPeriod : BIBidPeriod?
    var tripTextController: CBTripTextViewController?
    var employeeNumber : String?
    var tripCBButton: CBTripButton!
    var selectedLine: BILine?
    let kCBButtonTag = 800
    var isFromLineFetch : Bool = false
    var fromScrachpadView:Bool?
    let permissionMsg = "CrewBid needs access Calendar to add awards.\nGo to device Settings -> Privacy -> Calendars to enable access"
    let eventStore = EKEventStore()
    var tripButtons: NSMutableArray?
    var tripButtonsArray = NSMutableArray()
    var vacationButtons: NSMutableArray = NSMutableArray()
    var fvVacationButtons: NSMutableArray = NSMutableArray()
    var cfvVacationButtons: NSMutableArray = NSMutableArray()
    var vacayGestureRecognizers = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarData = BICalendarData().initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        calendarDayArr = calendarData!.calendarDays as! [BICalendarDay]
        setupUI()
    }
    
    func setupUI() {
        btnClose.setTitle("", for: .normal)
        btnShare.setTitle("", for: .normal)
        
        lblLineNumber.text = self.line?.number?.stringValue
        lblTitle.text = "Awarded Line \(self.line!.number!.stringValue) for EID \(employeeNumber!)"
        if isFromLineFetch == true {
            lblTitle.text = "Line \(self.line!.number!.stringValue)"
            btnClose.setImage(UIImage(named: "arrowleftbutton"), for: .normal)
        }
        
        collectionView.isScrollEnabled = false
        
        
        if !(self.bidPeriod!.isFABid()){
            lblFaPosition.isHidden = true
        }else{
            lblFaPosition.isHidden = false
            lblFaPosition.makeCornerRound()
            lblFaPosition.text = line?.faPositionString
            lblFaPosition.backgroundColor = line?.faPositionColor()
        }
        
        let verticalSpace: CGFloat = 6.0
        for i in 0..<5 {
            var lineValueView = CBLineValueView()
            lineValueView = lineValueView.initWithFrame(aRect: CGRect.zero)
            lineValueView.tag = LineValueViewTag + i * 10
            lineValueView.translatesAutoresizingMaskIntoConstraints = false
            viewLineValues.addSubview(lineValueView)
            // Line value view centered in container.
            viewLineValues.addConstraint(NSLayoutConstraint(item: lineValueView, attribute: .centerX, relatedBy: .equal, toItem: viewLineValues, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            // Top spacing from superview.
            viewLineValues.addConstraint(NSLayoutConstraint(item: lineValueView, attribute: .top, relatedBy: .equal, toItem: viewLineValues, attribute: .top, multiplier: 1.0, constant: CGFloat(i) * (kCBLineValueViewHeight + verticalSpace)))
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressLineValueContainerView))
        longPressGesture.minimumPressDuration = 0.3
        viewLineValues.addGestureRecognizer(longPressGesture)
        longPressGesture.delaysTouchesBegan = true
        setLineValues()
        NotificationCenter.default.addObserver(self, selector: #selector(self.deHighlightTrip), name: NSNotification.Name(rawValue: CBLineTableCellTripButtonDehighlightNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setLineValues), name: NSNotification.Name(CBLineValuesToDisplayDidChangeNotification), object: nil)
        self.refreshCalendar()
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView.collectionViewLayout = layout
    }
    
    @objc func deHighlightTrip(_ notification: Notification) {
        let isFromScratchpadDetails = notification.object
        let dictValues:NSMutableDictionary = isFromScratchpadDetails as! NSMutableDictionary
        let isFromScratchpad: Bool = dictValues.value(forKey: "isFromScratchpad") as! Bool
        if (isFromScratchpad) {
            if let tripButton = tripCBButton {
                tripButton.setHighlighted(false)
            }
        } else {
            
        }
    }
    
    @objc func setLineValues(){
        let lineValuesKey: String = CBLineValuesMenuController.lineValuesKey(for: bidPeriod!)
        let lineValuesToDisplay:NSMutableArray = NSMutableArray()
        if (UserDefaults.standard.object(forKey: lineValuesKey) != nil) {
            let arr = UserDefaults.standard.value(forKey: lineValuesKey) as! [Any]
            lineValuesToDisplay.addObjects(from: arr)
        }
        
        for i in 0..<lineValuesToDisplay.count {
            let tag: Int = LineValueViewTag + i * 10
            let valueType:NSInteger
            let lineValueView = self.view.viewWithTag(tag) as? CBLineValueView
            if let val = lineValuesToDisplay[i] as? NSNumber {
                valueType = NSInteger(truncating: val)
            } else if let val = lineValuesToDisplay[i] as? String {
                valueType = NSInteger(val)!
            } else {
                let val = lineValuesToDisplay[i] as! Int
                valueType = NSInteger(val)
            }
            CBLineValuesMenuController.setLineValueView(lineValueView!, with: line!, forType: CBLineValueTypes(rawValue: valueType)!, bidPeriod: bidPeriod!)
            lineValueView?.alpha = 1.0
            if CBLineValueTypes(rawValue: valueType) == .VacationPayDifference {
                if line?.vVacationPay as? Double ?? 0.0 > 0.0 {
                    lineValueView?.alpha = 1.0
                } else {
                    lineValueView?.alpha = 0
                }
            } else {
                lineValueView?.alpha = 1.0
            }
        }
        // Set any unused lineValueViews to transparent
        for i in lineValuesToDisplay.count..<5 {
            let tag: Int = LineValueViewTag + i * 10
            let lineValueView = self.view.viewWithTag(tag) as? CBLineValueView
            lineValueView?.alpha = 0.0
        }
    }
    
    
    @objc func longPressLineValueContainerView(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBLineValuesMenuController") as! CBLineValuesMenuController
        lineValuesController.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        lineValuesController.modalPresentationStyle = .custom
        let touchPoint = gesture.location(in: self.viewLineValues)
        let frame = CGRect(x: viewLineValues.frame.origin.x, y: touchPoint.y - 180, width: viewLineValues.frame.width, height: viewLineValues.frame.height)
        lineValuesController.showPopover(sourceView: self.viewLineValues, sourceRect: frame)
    }
    

    @IBAction func btnShareAction(_ sender: Any) {
        guard let line = self.line else { return }

           let actions: [(title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?)] = [
               ("Email Line \(line.number!) Trip Sheet", .default, { [weak self] _ in
                   self?.handleShareAction(title: "Email Line \(line.number!) Trip Sheet")
               }),
               ("Print Line \(line.number!) Trip Sheet", .default, { [weak self] _ in
                   self?.handleShareAction(title: "Print Line \(line.number!) Trip Sheet")
               }),
               ("Export to FFDO format", .default, { [weak self] _ in
                   self?.handleShareAction(title: "Export to FFDO format")
               }),
               ("Add Line to Calender", .default, { [weak self] _ in
                   self?.handleShareAction(title: "Add Line to Calender")
               }),
               ("Cancel", .cancel, nil)
           ]

           AlertService.showAlertForTopVC(
               title: "Actions",
               message: nil,
               actions: actions
           )
    }
    
    func handleShareAction(title: String) {
        guard let line = self.line else { return }
        
        var tripText = ""
        for trip in line.trips! {
            if let tripObj = trip as? BITrip {
                tripText.append(tripObj.tripText())
                tripText.append("\n\n------------------------------------------------------\n")
            }
        }
        switch title {
            case "Email Line \(line.number!) Trip Sheet":
                emailTextFile(text: tripText)

            case "Print Line \(line.number!) Trip Sheet":
                showPrintController(text: tripText)

            case "Export to FFDO format":
                if bidPeriod?.isFABid() ?? true {
                    AlertService.showAlertForTopVC(
                        title: "FFDO Export Not Allowed",
                        message: "FFDO format export is only allowed for pilot lines.")
                } else {
                    emailFFDO(line: line)
                }

            case "Add Line to Calender":
                self.selectedLine = line
                addLinetoCalendar()

            default:
                break
        }
    }
    
    func emailFFDO(line : BILine){
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            if let data = line.lineFfdoLegsSingleSpacing().data(using: .utf8) {
                mail.addAttachmentData(data as Data, mimeType: "text/plain" , fileName: "Line_\(line.number!.intValue)_SingleSpacing_FFDO_Format_Trip_Sheets")
            }
            if let data = line.lineFfdoLegsDoubleSpacing().data(using: .utf8) {
                mail.addAttachmentData(data as Data, mimeType: "text/plain" , fileName: "Line_\(line.number!.intValue)_DoubleSpacing_FFDO_Format_Trip_Sheets")
            }
            mail.setSubject("FFDO Format for Line \(line.number!.intValue)")
            present(mail, animated: true)
        }
    }
    
    func showPrintController(text : String){
        let printController = UIPrintInteractionController.shared
        printController.delegate = self
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .grayscale
        printInfo.duplex = .none
        printInfo.jobName = "Print Awarded Line"
        printController.printInfo = printInfo
        printInfo.orientation = .landscape
        let printFormatter = UISimpleTextPrintFormatter(text: text)
        printFormatter.startPage = 0
        printFormatter.font = .systemFont(ofSize: 10)
        printController.printFormatter = printFormatter
        printController.present(animated: true, completionHandler: nil)
    }
    
    func emailTextFile(text : String){
        let file = (self.bidPeriod?.awardString)!
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            if let data = text.data(using: .utf8) {
                mail.addAttachmentData(data as Data, mimeType: "text/plain" , fileName: file)
            }
            mail.setSubject(title ?? "")
            present(mail, animated: true)
        }
    }
    
    func addLinetoCalendar() {
        if selectedLine!.type!.intValue == BILineType.BlankLine.rawValue{
            let alert = UIAlertController(title: "Line type is \"Blank\"", message: "Cannot add a \"Blank\" line to Calendar", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true)
        }else{
            checkPermission()
        }
    }
    
    func checkPermission() {
        
        switch EKEventStore.authorizationStatus(for: .event) {
            
        case .writeOnly, .fullAccess, .authorized:
            self.showCalendarChooser()
            
        case .denied:
            CBGlobalMethods.shared.ShowAlert(TitleString: "Permission Required", MessageString: permissionMsg)
            
        case .notDetermined:
            if #available(iOS 17, *) {
                eventStore.requestFullAccessToEvents {(granted, error) in
                    if granted {
                        self.showCalendarChooser()
                    } else {
                        CBGlobalMethods.shared.ShowAlert(TitleString: "Permission Required", MessageString: self.permissionMsg)
                    }
                }
            } else {
                eventStore.requestAccess(to: .event, completion: {(granted, error) in
                    if granted {
                        self.showCalendarChooser()
                    } else {
                        CBGlobalMethods.shared.ShowAlert(TitleString: "Permission Required", MessageString: self.permissionMsg)
                    }
                })
            }
        default:
            print("Default Selection")
        }
    }
    
    func showCalendarChooser() {
        DispatchQueue.main.async {
            let vc = EKCalendarChooser(selectionStyle: .single, displayStyle: .writableCalendarsOnly, entityType: .event, eventStore: self.eventStore)
            vc.showsDoneButton = true
            vc.showsCancelButton = true
            vc.delegate = self
            let nvc = UINavigationController(rootViewController: vc)
            self.present(nvc, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        if let navigationController = self.navigationController {
                if navigationController.viewControllers.first != self {
                    navigationController.popViewController(animated: true)
                    return
                }
            }
        self.dismiss(animated: true, completion: nil)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (bidPeriod?.containsVacay!.boolValue)! && (self.bidPeriod?.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
            if vacayGestureRecognizers.contains(gestureRecognizer) {
                var touchInsideVacayButton = false
                let count = vacationButtons.count
                for i in 0 ..< count {
                    var vButton: Any!
                    vButton = vacationButtons[i]
                    if let vButton = vButton as? UIImageView {
                        if vButton.frame.contains(touch.location(in: self.collectionView)) {
                            touchInsideVacayButton = true
                        }
                    }
                }
                let FVcount = fvVacationButtons.count
                for i in 0 ..< FVcount {
                    var vButton: Any!
                    vButton = fvVacationButtons[i]
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
    
    @objc func tripButtonAction(_ tripButton: CBTripButton){
        self.showTripTextPopover(for: tripButton)
    }
    
    func showTripTextPopover(for tripButton: CBTripButton) {
        
        if (self.presentedViewController is CBTripTextViewController){
            tripTextController?.dismissPopover(animated: true)
            return
        }
        let tripText: String = tripButton.trip!.tripText()
        let tripTextController = CBTripTextViewController.instantiateFromStoryboard(withTripText: tripText, button: tripButton) as! CBTripTextViewController
        tripTextController.modalPresentationStyle = .custom
        self.tripCBButton = tripButton
        tripButton.setHighlighted(true)
        tripTextController.tripText1 = tripText
        tripTextController.button = tripButton
        tripTextController.isFromScratchpad = true
        tripTextController.showPopover(sourceView: tripButton)
    }
    
    @objc func showSWAPtimizerTripOptionsPopover(_ gesture: UILongPressGestureRecognizer) {
        
    }
    
    func refreshCalendar() {
        if nil == tripButtons {
            tripButtons = NSMutableArray()
        }
        for case let button as UIButton in tripButtons! {
            button.removeFromSuperview()
        }
        tripButtonsArray.removeAllObjects()
        tripButtons?.removeAllObjects()
        tripButtons?.addObjects(from: calendarDayArr)
        let userDefaults = UserDefaults.standard
        let cCount = calendarDayArr.count
        var rowCount = cCount/7
        if cCount % 7 != 0 {
            rowCount = rowCount + 1
        }
        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let itemSize: CGSize = flowLayout!.itemSize
        let inset: CGFloat = 15
        
        let xSize = collectionView.frame.width/7
        let ySize = itemSize.height + 8
        
        let widthSize = ((self.collectionView.frame.width-2)) / 7
        let insets: UIEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        var buttonFrame = CGRect(x: 0.0, y: 0.0, width: widthSize , height: itemSize.height-10)
        var buttonImage: UIImage? = nil
        var button = CBTripButton()
        let daysInCalendar: Int = calendarDayArr.count
        let trips = line?.trips
        for item in trips!{
            let trip = item as! BITrip
            if let tripOption = BIVacationOverlapTripOption(rawValue: userDefaults.integer(forKey: kCBVacationOverlapTripDisplayOption)),
               (self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue ||
                self.bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue),
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
            let row: Int = index / 7
            let tripLength: Int = trip.info!.calendarDaysCount as! Int
            var buttonLength: Int = 0
            var otherButton:CBTripButton? = nil
            // If trip will go across two rows in calendar, create both buttons.
            if column + tripLength > 7 {
                buttonLength = 7 - column
                buttonFrame.size.width = CGFloat(buttonLength) * (widthSize)
                buttonFrame = CGRect(x: (CGFloat(column) * (xSize)), y: (CGFloat(row) * (ySize)), width: buttonFrame.width , height: buttonFrame.height)
                if trip.isRedEyeTrip {
                    buttonImage = UIImage(named: "TripButton-rounded-left-redEye_red_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                }else if bidPeriod!.isFABid() && trip.isReserve {
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
                buttonFrame.size.width =  CGFloat(buttonLength) * (widthSize)
                button = CBTripButton(frame: buttonFrame)
                button.tag = kCBButtonTag
                button.trip = trip
                button.setBackgroundImage(buttonImage, for: .normal)
                if (self.bidPeriod!.isFABid() && trip.isReserve) {
                    button.layer.cornerRadius = (button.frame.height) / 2
                    button.clipsToBounds = true
                }
                button.addTarget(self, action: #selector(tripButtonAction), for: .touchUpInside)
                tripButtons?.replaceObject(at: index, with: button)
                tripButtonsArray.add(button)
                collectionView.addSubview(button)
                let nextButtonLength: Int = tripLength - buttonLength
                let nextButtonIndex: Int = index + buttonLength
                buttonFrame.size.width =  CGFloat(nextButtonLength) * (widthSize)
                if trip.isRedEyeTrip{
                    buttonImage = UIImage(named: "TripButton-rounded-right-redEye_red_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                }
                else if bidPeriod!.isFABid() && trip.isReserve {
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
                if (self.bidPeriod!.isFABid() && trip.isReserve) {
                    otherButton?.layer.cornerRadius = (otherButton?.frame.height)! / 2
                    otherButton?.clipsToBounds = true
                }
                otherButton?.trip = trip
                otherButton?.addTarget(self, action: #selector(self.tripButtonAction), for: .touchUpInside)
                button.otherButton = otherButton
                otherButton?.otherButton = button
                if nextButtonIndex < tripButtons!.count{
                    tripButtons?.replaceObject(at: nextButtonIndex, with: otherButton!)
                    tripButtonsArray.add(button)
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
                else if bidPeriod!.isFABid() && trip.isReserve {
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
                buttonFrame.size.width =  CGFloat(tripLength) * (widthSize)
                button = CBTripButton(frame: buttonFrame)
                button.tag = kCBButtonTag
                button.setBackgroundImage(buttonImage, for: .normal)
                
                if self.bidPeriod!.isFABid() && trip.isReserve{
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
                tripButtonsArray.add(button)
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
                labelFrame.size.width = widthSize
                var dayIndex = d
                
                
                if !self.bidPeriod!.isFABid() && (trip.info?.dutyPeriodsCount != trip.info?.calendarDaysCount) {
                    if !showingRedEyeIconForThisTrip {
                        if trip.isRedEyeTrip && (dayIndex >= missingDateIndex) && missingDateIndex != -1 {
                            labelFrame.origin.x = CGFloat(d) * widthSize + 3
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
                labelFrame.origin.x = CGFloat(dayIndex) * widthSize
                // Show labels in other button if day is greater than length of
                // first button. Adjust origin of label to other button.
                if otherButton != nil && dayIndex >= buttonLength {
                    labelButton = otherButton!
                    labelFrame.origin.x = CGFloat(d - buttonLength) * widthSize + 3
                    if !self.bidPeriod!.isFABid() && trip.info?.dutyPeriodsCount != trip.info?.calendarDaysCount {
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
                    labelFrame.origin.x = CGFloat(dayIndex - buttonLength) * widthSize
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
                
                if trip.isRedEyeTrip && d == missingDateIndex && (self.bidPeriod!.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) && trip.vacationOverlapType!.intValue > 0 {
                    redEyePayLabel?.textAlignment = .center
                    redEyePayLabel?.font = UIFont.boldSystemFont(ofSize: 12)
                    redEyePayLabel?.textColor = trip.highlightCount!.intValue > 0 ? CBColor.tripHighlightColor : .white
                }else{
                    redEyePayLabel = nil
                }
                if (self.bidPeriod!.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) && trip.vacationOverlapType!.intValue > 0 && day.displayType!.intValue != BIDayDisplayType.normal.rawValue{
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
                        if (userDefaults.integer(forKey: kCBTimeZoneSetting) != CBTimeZoneSetting.herbTime.rawValue) || (trip.isReserve && self.bidPeriod!.isFABid()){
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
                        labelButton?.addSubview(timeLabel)
                        
                        if day.displayType?.intValue == BIDayDisplayType.normal.rawValue{
                            var xValue:CGFloat = 0.0
                            xValue = label.frame.origin.x + widthSize - 13
                            let weekDayInt = CBUtils.weekDay(from: trip.startDate!)
                            let isSaturday = (weekDayInt + d == 7)
                            if isSaturday{
                                xValue = fromScrachpadView == true ? xValue - 6 : xValue - 7
                            }
                            let verticalLabelFrame = CGRect(x: xValue, y: labelFrame.origin.y + 20, width: 26, height: 10)
                            
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
//        if vacationButtons == nil {
//            vacationButtons = NSMutableArray()
//        }
        for case let view as UIView in vacationButtons {
            view.removeFromSuperview()
        }
        vacationButtons.removeAllObjects()
        vacationButtons.addObjects(from: calendarDayArr)
        if self.bidPeriod!.containsVacay!.boolValue{
            var vacayButtonFrame = CGRect(x: 0, y: 0, width: widthSize, height: itemSize.height - 10)
            var buttonImage:UIImage? = nil
            let vacations = self.bidPeriod!.vacations
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
                    tripLength = vacay.length!.intValue
                }
                let column = index % 7
                var buttonLength = 0
                // If vacation pill will go across two rows in calendar, create both buttons.
                if column+tripLength > 7 {
                    buttonLength = 7 - column
//                    buttonImage = UIImage(named: "TripButton-rounded-left-yellow_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.left))?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                    vacayButtonFrame.size.width = min(CGFloat(tripLength), 7) * widthSize
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    vacationButtons.replaceObject(at: index, with: button2)
                    button2.alpha = 0.6
                    self.collectionView.addSubview(button2)
                    
                    if self.bidPeriod!.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
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
                            vacayButtonFrame.size.width = min(CGFloat(buttonLength), 7) * widthSize
                            if tripLength > 7{
                                vacayButtonFrame.size.width += 15
                            }
//                            buttonImage = UIImage(named:"TripButton-rounded-right-yellow_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                            buttonImage = UIImage(named: self.bidPeriod!.getVacationImage(.right))?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
                            let otherButton2 = UIImageView(frame: vacayButtonFrame)
                            otherButton2.image = buttonImage
                            vacationButtons.replaceObject(at: index, with: otherButton2)
                            otherButton2.alpha = 0.6
                            self.collectionView.addSubview(otherButton2)
                                
                            if self.bidPeriod!.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
                                otherButton2.isUserInteractionEnabled = true
                                otherButton2.isOpaque = false
                                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
                                longPressGesture.minimumPressDuration = 0.5
                                longPressGesture.cancelsTouchesInView = false
                                otherButton2.addGestureRecognizer(longPressGesture)
                                longPressGesture.delegate = self
                                vacayGestureRecognizers.add(longPressGesture)
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
                    vacayButtonFrame.size.width = CGFloat(tripLength) * widthSize
                    let button2 = UIImageView(frame: vacayButtonFrame)
                    button2.image = buttonImage
                    vacationButtons.replaceObject(at: index, with: button2)
                    button2.alpha = 0.6
                    self.collectionView.addSubview(button2)
                    if self.bidPeriod!.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod!.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
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
//        if fvVacationButtons == nil {
//            fvVacationButtons = NSMutableArray()
//        }
        
//        let FVcount: Int = (fvVacationButtons.count)
//        for i in 0 ..< FVcount {
//            let fvVacationButton = fvVacationButtons[i] as? UIImageView
//            if fvVacationButton != nil {
//                fvVacationButton?.removeFromSuperview()
//            }
//        }
//        fvVacationButtons.removeAllObjects()
//        fvVacationButtons.addObjects(from: CollectionCellCalendarDaysArr)
//        
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
//        cfvVacationButtons?.addObjects(from: CollectionCellCalendarDaysArr)
//        
//        for view in self.collectionView.subviews {
//                if view.tag == 99 {
//                    view.removeFromSuperview()
//                }
//        }
//        if self.bidPeriod.containsVacay!.boolValue {
//            var vacayButtonFrame = CGRect(x: 0, y: 0, width: WidthSize, height: WidthSize)
//            var buttonImage:UIImage? = nil
//            let vacations = self.line?.fvvacations
//            let arrVacationIndexes = NSMutableArray()
//            let removeCFV = userDefaults.bool(forKey: "RemoveCfv")
//            if (self.line?.cfvVacDates?.count) ?? 0 > 0{
//                if !removeCFV {
//                    for i in 0..<(self.line?.cfvVacDates!.count)!{
//                        let cfvDate = (self.line!.cfvVacDates![i] as! NSNumber).intValue
//                        let cfv = UILabel()
//                        cfv.backgroundColor = .darkGray
//                        cfv.alpha = 1
//                        cfv.tag = 99
//                        cfv.text = "$FV"
//                        cfv.textAlignment = .center
//                        cfv.font = UIFont.boldSystemFont(ofSize: 14)
//                        cfv.textColor = .white
//                        let dateString = "\(cfvDate)-\(self.bidPeriod.month!)-\(self.bidPeriod.year!)"
//                        let dateFormatter = DateFormatter()
//                        dateFormatter.dateFormat = "d-M-yyyy"
//                        let timeZone = TimeZone(abbreviation: "GMT")!
//                        dateFormatter.timeZone = timeZone
//                        let cfvDATE = dateFormatter.date(from: dateString)
//                        let index = (self.calendarData?.indexForDate(date: cfvDATE))!
//                        let indexPath1 = IndexPath(row: index + 1, section: 0)
//                        let buttonLayoutAttributes1 = self.collectionView.layoutAttributesForItem(at: indexPath1)!
//                        let height: CGFloat = 28.0
//                        let cfvFrame = CGRect(x: (buttonLayoutAttributes1.frame.minX), y: (buttonLayoutAttributes1.frame.minY), width: (buttonLayoutAttributes1.frame.width)-5, height: height)
//                        cfv.frame = cfvFrame
//                        cfv.layer.cornerRadius = cfv.frame.height/2
//                        cfv.layer.masksToBounds = true
//                        cfvVacationButtons?.replaceObject(at: index + 1, with: cfv)
//                        self.collectionView.addSubview(cfv)
//                    }
//                }
//            }
//            for case let vacay as BIVacation in vacations!{
//                var index = self.calendarData!.indexForDateGMT(date: vacay.fvStartdate!)
//                if arrVacationIndexes.contains(index){
//                    continue
//                }
//                arrVacationIndexes.add(index)
//                
//                var tripLength = 0
//                if index < 0 {
//                    tripLength = vacay.fvLength!.intValue + index
//                }else if index > (daysInCalendar - 1) {
//                    continue
//                }else{
//                    tripLength = vacay.fvLength!.intValue
//                }
//                let column = index % 7
//                var buttonLength = 0
//                
//                // If vacation pill will go across two rows in calendar, create both buttons.
//                if column + tripLength > 7 {
//                    buttonLength = 7 - column
//                    vacayButtonFrame.size.width = WidthSize * CGFloat(buttonLength)
//                    buttonImage = UIImage(named:"TripButton-rounded-left-FVBlue_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    vacayButtonFrame.size.width = min(CGFloat(tripLength), 7) * WidthSize
//                    let button2 = UIImageView(frame: vacayButtonFrame)
//                    button2.image = buttonImage
//                    fvVacationButtons?.replaceObject(at: index, with: button2)
//                    button2.alpha = 0.7
//                    self.collectionView.addSubview(button2)
//                    if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
//                        button2.isUserInteractionEnabled = true
//                        button2.isOpaque = false
//                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                        longPressGesture.minimumPressDuration = 0.5
//                        longPressGesture.cancelsTouchesInView = false
//                        button2.addGestureRecognizer(longPressGesture)
//                        longPressGesture.delegate = self
//                        vacayGestureRecognizers.add(longPressGesture)
//                    }
//                    tripLength -= buttonLength
//                    index += buttonLength
//                    while tripLength > 0 {
//                        buttonLength = tripLength > 7 ? 7 : tripLength
//                        if index < daysInCalendar{
//                            vacayButtonFrame.size.width = min(CGFloat(buttonLength), 7) * WidthSize
//                            if tripLength > 7 {
//                                vacayButtonFrame.size.width += 15
//                            }
//                                buttonImage = UIImage(named:"TripButton-rounded-right-FVBlue_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                                let otherButton2 = UIImageView(frame: vacayButtonFrame)
//                                otherButton2.image = buttonImage
//                                fvVacationButtons?.replaceObject(at: index, with: otherButton2)
//                                otherButton2.alpha = 0.7
//                                self.collectionView.addSubview(otherButton2)
//                                if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
//                                    otherButton2.isUserInteractionEnabled = true
//                                    otherButton2.isOpaque = false
//                                    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                                    longPressGesture.minimumPressDuration = 0.5
//                                    longPressGesture.cancelsTouchesInView = false
//                                    otherButton2.addGestureRecognizer(longPressGesture)
//                                    longPressGesture.delegate = self
//                                    vacayGestureRecognizers.add(longPressGesture)
//                                }
//                            }
//                            tripLength -= buttonLength
//                            index += buttonLength
//                        }
//                    }
//                else{ // Vacation in one row only of the calendar.
//                    if index < 0 {
//                        // Vacation starts before the visible calendar days, so show the rounded right image
//                        buttonImage = UIImage(named: "TripButton-rounded-right-FVBlue_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }else if (index + tripLength - 1) > (daysInCalendar - 1) {
//                        // Vacay ends after the visible calendar days, so show the rounded left image
//                        buttonImage = UIImage(named: "TripButton-rounded-left-FVBlue_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }else{
//                        buttonImage = UIImage(named: "TripButton-rounded-both-FVBlue_iOS7")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
//                    }
//                    vacayButtonFrame.size.width = CGFloat(tripLength) * WidthSize
//                    let button2 = UIImageView(frame: vacayButtonFrame)
//                    button2.image = buttonImage
//                    fvVacationButtons?.replaceObject(at: index, with: button2)
//                    button2.alpha = 0.7
//                    self.collectionView.addSubview(button2)
//                    if self.bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue || self.bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue{
//                        button2.isUserInteractionEnabled = true
//                        button2.isOpaque = false
//                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showSWAPtimizerTripOptionsPopover))
//                        longPressGesture.minimumPressDuration = 0.5
//                        longPressGesture.cancelsTouchesInView = false
//                        button2.addGestureRecognizer(longPressGesture)
//                        longPressGesture.delegate = self
//                        vacayGestureRecognizers.add(longPressGesture)
//                    }
//                }
//            }
//        }
        self.collectionView.reloadData()
        self.collectionView.tripButtons = tripButtons
        self.collectionView.vacationButtons = vacationButtons
        self.collectionView.fvVacationButtons = fvVacationButtons
        self.collectionView.cfvVacationButtons = cfvVacationButtons
    }
    
}

extension CBAwardLineCalendarViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarDayArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AwardCalendarCollectionViewCell", for: indexPath) as! AwardCalendarCollectionViewCell
        cell.contentView.frame = cell.bounds
        cell.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let calendarDay = calendarDayArr[indexPath.row]
        cell.dayLabel.text = calendarDay.text
        let currentMonth = calendarDay.isCurrentMonth
        if currentMonth{
            cell.dayLabel.alpha = 1
        }else{
            cell.dayLabel.alpha = 0.5
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 7, height: 55)
    }
}
