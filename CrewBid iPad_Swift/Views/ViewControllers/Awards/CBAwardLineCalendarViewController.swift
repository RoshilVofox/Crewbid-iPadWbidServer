//
//  CBAwardLineCalendarViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 17/04/25.
//

import UIKit

class CBAwardLineCalendarViewController: UIViewController {

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
//        self.refreshCalendar()
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
            // Below condition uopdated bt Raja on 17 jan 2024
            // To handle the vDiff line value show / hide for Swaptimizer enable condition
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
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
