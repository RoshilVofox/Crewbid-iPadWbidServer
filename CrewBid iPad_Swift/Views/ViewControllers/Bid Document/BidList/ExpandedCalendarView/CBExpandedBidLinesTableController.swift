//
//  CBExpandedBidLinesTableController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit
import CoreData

var kReserveMrtViewTagExpandedView: Int = 1006
var kReserveMrtLabelTagExpandedView: Int = 5006

class CBExpandedBidLinesTableController: BaseViewController {
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var expandedTableView: UITableView!
    
    var CollectionCellCalendarDaysArr = [Any]()
    var linesArray : [BILine] = []
    var bidPeriod: BIBidPeriod!
    var bidListCalenderDays = [Any]()
    var bidListCalendarData = BICalendarData()
    var tripCBButton: CBTripButton!
    var isAwardSort = false
    var isSubmitSort = false
    var awardedLineNum: String!
    var dataSource = GlobalBidInfo.shared
    
    var selectedCellIndexPaths = NSMutableArray()
    var insertionPoint: BIInsertionPoint?
    var previousInsertionIndex: Int = 0
    private var _insertionIndex: Int?
    
    var count = 0
    
    var insertionIndex: Int  {
        get {
            //code to execute
            return Int(truncating: insertionPoint!.index!)
        }
        set(newValue) {
            _insertionIndex = newValue
            insertionPoint?.index = _insertionIndex! as NSNumber
            //code to execute
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isSubmitSort = CBGlobalMethods.shared.selectedBidPeriod!.isSortBySubmitOn?.boolValue ?? false
        setupUI()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        expandedTableView.setEditing(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let visibleRows = expandedTableView.indexPathsForVisibleRows, !visibleRows.isEmpty {
            let middleIndex = visibleRows.count / 2
                let middleIndexPath = visibleRows[middleIndex]
                    
                    UserDefaults.standard.set(middleIndexPath.row, forKey: "LastScrollRow")
                    UserDefaults.standard.set(middleIndexPath.section, forKey: "LastScrollSection")
                    UserDefaults.standard.set(true, forKey: "HasSavedScrollPosition")
                
            }
    }
    
    func setupUI(){
        self.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        bidListCalendarData = bidListCalendarData.initWithBidPeriod(bidPeriod: CBGlobalMethods.shared.selectedBidPeriod!)!
        bidListCalenderDays = bidListCalendarData.calendarDays as! [Any]
        expandedTableView.delegate = self
        expandedTableView.dataSource = self
        updateBidList()
        NotificationCenter.default.addObserver(self, selector: #selector(self.lineValuesToDisplayChanged(notification:)), name: Notification.Name(CBLineValuesToDisplayDidChangeNotification), object: nil)
        setupVariables()
        NotificationCenter.default.addObserver(self, selector: #selector(updateBidList), name: NSNotification.Name("refreshLines"), object: nil)
        if isAwardSort {
            if self.bidPeriod.awardDetails == nil || self.bidPeriod.awardDetails?.allObjects.count == 0 {
                return
            }
            let array = self.bidPeriod.awardDetails?.allObjects as! [AwardDetails]
            var awardSequenceNumArray = [NSNumber]()
            //let bidUserId = CBUserAccountDetail.shared.EmpNum
            var bidUserId = CBUserAccountDetail.shared.employeeNumber
            if self.bidPeriod.crewIdentifier?.stringValue != nil{
                bidUserId = self.bidPeriod.crewIdentifier!.stringValue
            }
            for obj in array {
                let awardLineNumber = "\(obj.lineNum)"
                let awardEmpNum = obj.empNum
                let seqNum = obj.seqNumber
                awardSequenceNumArray.append(NSNumber(value: seqNum))
                if awardEmpNum == bidUserId {
                    self.awardedLineNum = awardLineNumber
                    if self.bidPeriod.isFABid() {
                        self.awardedLineNum = awardLineNumber + obj.type!
                    }
                } else {
                    print("ALERT!!!")
                }
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.deHighlightTrip), name: NSNotification.Name(rawValue: CBLineTableCellTripButtonDehighlightNotification), object: nil)

        let positionArray = ["CP","FO","FA"]
        let index = dataSource.position.rawValue
        let version = "(\(CBUtils.AppVersion()))"
        let month = CBGlobalMethods.shortMonthNameOf(monthInt: dataSource.month)
        let position = positionArray[index]
        let year = dataSource.year
        let base = dataSource.base
        let round = dataSource.round
        lblTitle.text = "Expanded Bid List \(version) \(month) \(year) \(base) \(position) Rnd \(round)"
        
        let closeImg = UIImage(named: "NewBid-navbar-xcancelbutton")?.withRenderingMode(.alwaysTemplate)
        let shareImg = UIImage(named: "NavBarGray-ActionButton")?.withRenderingMode(.alwaysTemplate)
        btnClose.setImage(closeImg, for: .normal)
        btnShare.setImage(shareImg, for: .normal)
        btnClose.imageView?.tintColor = .white
        btnShare.imageView?.tintColor = .white
        btnClose.tintColor = .white
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        (sender as? UIButton)?.isEnabled = false
        self.dismiss(animated: true)
    }
    
    // Sets up variables related to the insertion point

    func setupVariables(){
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        if bidPeriod.insertionPoints?.allObjects.count ?? 0 > 0 {
            insertionPoint = bidPeriod.insertionPoints!.allObjects[0] as? BIInsertionPoint
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "InsertionPoint", in: bidPeriod.managedObjectContext!)
            insertionPoint = BIInsertionPoint(entity: entity!, insertInto: bidPeriod.managedObjectContext!)
            insertionPoint?.bidPeriod = self.bidPeriod
            insertionPoint?.index = 0
            insertionPoint?.above = false
            try? bidPeriod.managedObjectContext?.save()
        }
        updateBidList()
    }
    
    
    // Method called when line values to display change
    @objc func lineValuesToDisplayChanged(notification: Notification) {
        self.expandedTableView.reloadData()
    }
    
    // Dehighlights the trip button
    @objc func deHighlightTrip(_ notification: Notification) {
        let isFromScratchpadDetails = notification.object
        let dictValues:NSMutableDictionary = isFromScratchpadDetails as! NSMutableDictionary
        let isFromBidList: Bool = dictValues.value(forKey: "isFromBidList") as! Bool
        if (isFromBidList) {
            if let tripButton = tripCBButton {
                tripButton.setHighlighted(false)            }
        } else {
            
        }
    }
    
    // Method to update the bid list
    @objc func updateBidList() {
        self.linesArray.removeAll()
        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
            linesArray.append(line)
        }
        var array : [NSPredicate] = []
        array.append(NSPredicate(format: "bidOrder > %@", NSNumber(integerLiteral: 0)))
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        self.linesArray = (linesArray as NSArray).filtered(using: predicate) as! [BILine]
        
        //sorting the line numbers
        let sort = NSSortDescriptor(key: "bidOrder", ascending: true)
        self.linesArray = (linesArray as NSArray).sortedArray(using: [sort]) as! [BILine]
        
        if self.isSubmitSort {
            self.linesArray = (linesArray as NSArray).sortedArray(using: [NSSortDescriptor(key: "submitSortOrder", ascending: true)]) as! [BILine]
        }
        
        DispatchQueue.main.async {
            self.expandedTableView.reloadData()
        }
    }
    
    func showTripTextPopover(for tripButton: CBTripButton) {
        if (self.presentedViewController is CBTripTextViewController){
            self.dismiss(animated: true)
            return
        }
        let tripText: String = tripButton.trip!.tripText()
        let tripTextController = CBTripTextViewController.instantiateFromStoryboard(withTripText: tripText, button: tripButton) as! CBTripTextViewController
        tripTextController.modalPresentationStyle = .custom
        tripButton.setHighlighted(true)
        tripTextController.tripText1 = tripText
        self.tripCBButton = tripButton
        tripTextController.button = tripButton
        tripTextController.isFromBidList = true
        tripTextController.showPopover(sourceView: tripButton)
    }
    
    func configureCell(_ cell:CBExpandedBidLinesTableControllerCell, at indexPath: IndexPath) {
        let line = self.linesArray[indexPath.row]
        if (self.bidPeriod.isAwardSortOn ?? 0).boolValue {
            if (line.faBidLineMrt ?? 0).boolValue || (line.faBidLineReserve ?? 0).boolValue {
                cell.isHidden = true
            } else {
                cell.isHidden = false
                count += 1
            }
        } else {
            count += 1
            cell.isHidden = false
        }
        cell.userFlagControl.backgroundColor = CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType(rawValue: Int(truncating: (line.userFlagType)!))!)
        if CBUserFlagType.none.rawValue == line.userFlagType?.intValue {
            cell.userFlagControl.alpha = 1
        } else {
            cell.userFlagControl.alpha = 1.0
        }
        cell.mLblSlNo.text = "\(indexPath.row + 1)"
        cell.mLblLineNo.text = String(describing: line.number!)
        var setupLineValues = true
        if nil == cell.backgroundView {
            cell.backgroundView = UIView(frame: cell.bounds)
            cell.backgroundView?.backgroundColor = UIColor.appColor(.contentBgColor)
        }
        if bidPeriod.isFABid() && line.faPosition?.intValue != BIFaPosition.FaPositionNA.rawValue {
            cell.mLblLineNo.textColor = .white
            if line.faPosition?.intValue == BIFaPosition.FaPositionA.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosAColor
                cell.mLblLineNo.text = cell.mLblLineNo.text! + ("A")
            } else if line.faPosition?.intValue == BIFaPosition.FaPositionB.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosBColor
                cell.mLblLineNo.text = cell.mLblLineNo.text! + ("B")
            } else if line.faPosition?.intValue == BIFaPosition.FaPositionC.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosCColor
                cell.mLblLineNo.text = cell.mLblLineNo.text! + ("C")
            } else if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosDColor
                cell.mLblLineNo.text = cell.mLblLineNo.text! + ("D")
            } else {
                cell.positionCircleView.backgroundColor = UIColor.purple
                cell.mLblLineNo.text = cell.mLblLineNo.text! + ("M")
            }
            cell.positionCircleView.alpha = 1.0
            cell.positionCircleView.alpha = 1.0
            cell.handlingFreezingCondition(line: line)
            if isAwardSort {
                if let awardedLineNum = self.awardedLineNum {
                    var lineNum = line.number!.stringValue
                    if bidPeriod.isFABid() {
                        lineNum = line.number!.stringValue + line.faPositionString
                    }
                    if awardedLineNum == lineNum {
                        cell.layer.borderColor = UIColor.red.cgColor
                        cell.layer.borderWidth = 2.0
                    } else {
                        cell.layer.borderWidth = 0.0
                    }
                } else {
                    cell.layer.borderWidth = 0.0
                }
            } else {
                cell.layer.borderWidth = 0.0
            }
        }else {
            cell.positionCircleView.alpha = 0.0
            if isAwardSort {
                if let awardedLineNum = self.awardedLineNum {
                    if awardedLineNum == line.number?.stringValue {
                        cell.layer.borderColor = UIColor.red.cgColor
                        cell.layer.borderWidth = 2.0
                    } else {
                        cell.layer.borderWidth = 0.0
                    }
                } else {
                    cell.layer.borderWidth = 0.0
                }
            } else {
                cell.layer.borderWidth = 0.0
            }
        }
        cell.line = line
        cell.calendarData = bidListCalendarData
        
        cell.cellType = cellTypeForRow(at: indexPath)
        cell.handleMarkerCondition()
        //MRT and Reserve line
        let reserveMrtLabel = cell.viewWithTag(kReserveMrtLabelTagExpandedView) as? UILabel
        let reserveMrtView = cell.viewWithTag(kReserveMrtViewTagExpandedView)
        cell.lineValuesContainerView.isHidden = false
        if bidPeriod.isFirstRoundBid() && bidPeriod.isFABid() {
            if (line.faBidLineMrt?.boolValue)! {
                cell.positionCircleView.isHidden = true
                cell.collectionView.isHidden = true
                cell.lineValuesContainerView.isHidden = true
                cell.mLblLineNo.isHidden = true
                
                reserveMrtLabel?.alpha = 1.0
                reserveMrtView?.alpha = 1.0
                reserveMrtLabel?.backgroundColor = CBColor.faPosBColor
                reserveMrtView?.backgroundColor = CBColor.faPosBColor
                cell.backgroundView?.backgroundColor = CBColor.faPosBColor
                reserveMrtLabel?.text = "MRT Line"
                setupLineValues = false
            } else if (line.faBidLineReserve?.boolValue)! {
                cell.positionCircleView.isHidden = true
                cell.collectionView.isHidden = true
                cell.mLblLineNo.isHidden = true
                cell.lineValuesContainerView.isHidden = true
                cell.contentView.backgroundColor = CBColor.faPosBColor
                reserveMrtLabel?.text = "Reserve Line"
                reserveMrtLabel?.alpha = 1.0
                reserveMrtLabel?.backgroundColor = CBColor.faPosBColor
                reserveMrtView?.alpha = 1.0
                reserveMrtView?.backgroundColor = CBColor.faPosBColor
                cell.backgroundView?.backgroundColor = CBColor.faPosBColor
                setupLineValues = false
            } else {
                cell.positionCircleView.isHidden = false
                cell.collectionView.isHidden = false
                cell.mLblLineNo.isHidden = false
                if #available(iOS 13.0, *) {
                    cell.backgroundView?.backgroundColor = UIColor.appColor(.contentBgColor)
                    cell.contentView.backgroundColor =  UIColor.appColor(.contentBgColor)
                } else {
                    cell.backgroundView?.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
                    cell.contentView.backgroundColor =  UIColor(white: 0.97, alpha: 1.0)
                }
                reserveMrtLabel?.alpha = 0.0
                reserveMrtView?.alpha = 0.0
            }
        } else {
            cell.positionCircleView.isHidden = false
            cell.collectionView.isHidden = false
            cell.mLblLineNo.isHidden = false
            if #available(iOS 13.0, *) {
                cell.backgroundView?.backgroundColor = UIColor.appColor(.contentBgColor)
                cell.contentView.backgroundColor =  UIColor.appColor(.contentBgColor)
            } else {
                cell.backgroundView?.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
                cell.contentView.backgroundColor =  UIColor(white: 0.97, alpha: 1.0)
            }
            reserveMrtLabel?.alpha = 0.0
            reserveMrtView?.alpha = 0.0
        }
        //Set Etops line
        if line.isETOPS?.boolValue == true {
            cell.mLblLineNo.text = cell.mLblLineNo.text! + ("e") + " "
            let strTitle:NSString = cell.mLblLineNo.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "e")
            let normalRange: NSRange = NSRange(location: 0, length: strTitle.length - 1)
            let attributedString = NSMutableAttributedString(string: cell.mLblLineNo.text!)
            
            if bidPeriod.isFABid() {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: normalRange)
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.yellow , range: tickRange)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: tickRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
                }
                
            }
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10), range: tickRange)
            if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: tickRange)
            } else {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            }
            cell.mLblLineNo.attributedText = attributedString
        }
        if line.isETOPSRES?.boolValue == true {
            cell.mLblLineNo.text = cell.mLblLineNo.text! + ("Re")
            let strTitle:NSString = cell.mLblLineNo.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "Re")
            let normalRange: NSRange = NSRange(location: 0, length: strTitle.length - 2)
            let attributedString = NSMutableAttributedString(string: cell.mLblLineNo.text!)
            
            if bidPeriod.isFABid() {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: normalRange)
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue , range: tickRange)
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10), range: tickRange)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: tickRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
                }
                
            }
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10), range: tickRange)
            if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: tickRange)
            } else {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            }
            cell.mLblLineNo.attributedText = attributedString
        }else if !bidPeriod.isFABid() && bidPeriod.isSecondRoundBid() && (line.type == BILineType.MixedLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsMixed.rawValue.asNSNumber) {
            cell.mLblLineNo.text = cell.mLblLineNo.text! + ("mR")
            let strTitle:NSString = cell.mLblLineNo.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "mR")
            //let normalRange: NSRange = NSRange(location: 0, length: strTitle.length - 2)
            let attributedString = NSMutableAttributedString(string: cell.mLblLineNo.text!)
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10), range: tickRange)
            if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: tickRange)
            } else {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            }
            cell.mLblLineNo.attributedText = attributedString
        }else if bidPeriod.isFABid() && bidPeriod.isSecondRoundBid() {
            let reserveTypeSuffixMap: [NSNumber: String] = [
                BIFaReserveLineType.SnrAMres.rawValue.asNSNumber: "sa",
                BIFaReserveLineType.SnrPMres.rawValue.asNSNumber: "sp",
                BIFaReserveLineType.JnrAMres.rawValue.asNSNumber: "ja",
                BIFaReserveLineType.JnrPMres.rawValue.asNSNumber: "jp",
                BIFaReserveLineType.JnrLateRes.rawValue.asNSNumber: "jl"
            ]

            if let faReserveLineType = line.faReserveLineType,
               let suffix = reserveTypeSuffixMap[faReserveLineType] {
                cell.mLblLineNo.text = cell.mLblLineNo.text! + suffix
                let strTitle: NSString = cell.mLblLineNo.text! as NSString
                let tickRange: NSRange = strTitle.range(of: suffix)
                //let normalRange: NSRange = NSRange(location: 0, length: strTitle.length - 2)
                let attributedString = NSMutableAttributedString(string: cell.mLblLineNo.text!)
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10), range: tickRange)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: tickRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
                }
                cell.mLblLineNo.attributedText = attributedString
            }
        }else if line.type == BILineType.ReserveLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsReserve.rawValue.asNSNumber{
            cell.mLblLineNo.text = cell.mLblLineNo.text! + ("R")
            let strTitle:NSString = cell.mLblLineNo.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "R")
            let normalRange: NSRange = NSRange(location: 0, length: strTitle.length - 2)
            let attributedString = NSMutableAttributedString(string: cell.mLblLineNo.text!)
            
            if bidPeriod.isFABid() {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: normalRange)
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue , range: tickRange)
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10), range: tickRange)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: tickRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
                }
                
            }
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10), range: tickRange)
            if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: tickRange)
            } else {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            }
            cell.mLblLineNo.attributedText = attributedString
        }
        cell.handlingFreezingCondition(line: line)
        if setupLineValues {
            // Line values.
            let lineValuesKey: String = CBLineValuesMenuController.lineValuesKey(for: bidPeriod)
            let lineValuesToDisplay:NSMutableArray = NSMutableArray()
            if (UserDefaults.standard.object(forKey: lineValuesKey) != nil) {
                // perform your task here
                let arr = UserDefaults.standard.value(forKey: lineValuesKey) as! [Any]
                lineValuesToDisplay.addObjects(from: arr)
            }
            for i in 0..<lineValuesToDisplay.count {
                let tag: Int = LineValueViewTag +  i * 10
                let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
                let val = lineValuesToDisplay[i] as! Int
                let valueType = NSInteger(val)
                if lineValueView == nil {
                    print("linevalueView is nill")
                } else {
                    CBLineValuesMenuController.setLineValueView(lineValueView!, with: line, forType: CBLineValueTypes(rawValue: valueType)!, bidPeriod: bidPeriod)
                }
                lineValueView?.alpha = 1.0
                // To handle the vDiff line value show / hide for Swaptimizer enable condition
                if CBLineValueTypes(rawValue: valueType) == .VacationPayDifference {
                    if line.vCBVacPay as? Double ?? 0.0 > 0.0 || line.orderedTrips.count == 0 {
                        lineValueView?.alpha = 1.0
                    } else {
                        lineValueView?.alpha = 0
                    }
                } else {
                    lineValueView?.alpha = 1.0
                }
            }
            for i in lineValuesToDisplay.count..<5 {
                let tag: Int = LineValueViewTag +  i * 10
                let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
                lineValueView?.alpha = 0.0
            }
        }
    }
    
    
    
    func cellTypeForRow(at indexPath: IndexPath) -> CBBidLineTableCellType {
        var cellType = CBBidLineTableCellType.cbPlainBidLineTableCellType as CBBidLineTableCellType
        let line: BILine = self.linesArray[indexPath.row]
        if line.markerTitle != nil {
            cellType = CBBidLineTableCellType.cbMarkerBidLineTableCellType
        }
        return cellType
    }
    
    // Removes any A-Sort UI elements
    private func removeASortUI() {
        // removing A-Sort properties
                if isAwardSort || isSubmitSort {
                    setPreviousBidOrder()
                }
        self.bidPeriod.isAwardSortOn = No
        self.bidPeriod.isSortBySubmitOn = No
        self.isAwardSort = false
        self.isSubmitSort = false
    }
    
    private func setPreviousBidOrder() {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        // setting the pervious bid order while turning off A-Sort
        for line in linesArray {
            line.bidOrder = line.previousBidOrder
        }
    }
    
}

extension CBExpandedBidLinesTableController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        count = 0
        return self.linesArray.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CBExpandedBidLinesTableControllerCell") as! CBExpandedBidLinesTableControllerCell
        let line = self.linesArray[indexPath.row]
        cell.bidPeriod = self.bidPeriod
        cell.setMarkerText(line.markerTitle)
        cell.bidListCellCalendarDaysArr = bidListCalendarData.calendarDaysExpandedBidLinesView() as! [Any]
        configureCell(cell, at: indexPath)

        cell.tripButtonActionBlock = {(_ tripButton: CBTripButton) -> Void in
            DispatchQueue.main.async {
                self.showTripTextPopover(for: tripButton)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
            return nil
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            return 0.001
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var heightForRow: CGFloat = 87
        let line = linesArray[indexPath.row]
        if (line.markerTitle != nil) {
            heightForRow += kCBBidLineTableCellMarkerHeight
        }
        if (self.bidPeriod.isAwardSortOn ?? 0).boolValue {
            if (line.faBidLineMrt ?? 0).boolValue || (line.faBidLineReserve ?? 0).boolValue {
                return 0
            }
        }
        return heightForRow
    }
    
    //Reorder
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        //self.linesArray.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        // Do nothing until the move actually finishes
        if sourceIndexPath == destinationIndexPath{
            return
        }
        removeASortUI()
        let originRow: Int = sourceIndexPath.row
        let destRow: Int = destinationIndexPath.row
        let startLine = linesArray[sourceIndexPath.row]
        if (startLine.isFrozen != 0) {
            expandedTableView.reloadData()
            return
        }
        // Freeze the line if you moved it within the frozen lines block.
        let endLine = linesArray[destinationIndexPath.row]
        if (endLine.isFrozen != 0) {
            startLine.isFrozen = true
        }
        // Uncomment if you want to prevent moves of single rows into the frozen rows section
        let firstRow: Int = originRow > destRow ? destRow : originRow
        let lastRow: Int = originRow > destRow ? originRow : destRow
        let ind = IndexPath(row: originRow, section: 0)
        var affectedRows = NSMutableArray()
        affectedRows = (linesArray as NSArray).mutableCopy() as! NSMutableArray
        
        (affectedRows as NSArray?)?.sortedArray(using: [NSSortDescriptor(key: "bidOrder", ascending: true)])
        let insertionIndex: Int = destRow
        let removedIndex: Int = originRow
        let row: Int = ind.row
        let line = affectedRows[row] as? BILine
        // Attempt to preserve marker by moving it to line below (if one
        // exists below line and that line does not have a marker).
        var oldMarkerTitle: String? = nil
        if (line?.markerTitle != nil) {
            oldMarkerTitle = line?.markerTitle
        }
        line?.markerTitle = nil
        // If inserting above a line that has a marker, transfer marker to
        // moved line.
        let insertionPointLine: BILine? = affectedRows.object(at: insertionIndex) as? BILine
        if insertionPointLine?.markerTitle != nil {
            line?.markerTitle = insertionPointLine?.markerTitle
            insertionPointLine?.markerTitle = nil
        }
        // affectedRows.remove(at: removedIndex)
        affectedRows.removeObject(at: removedIndex)
        let insertedIndexes = NSIndexSet(indexesIn: NSRange(location: insertionIndex, length: insertionIndex))
        if let aLine = line {
            
            affectedRows.insert(aLine, at: insertionIndex)
        }
        // Add the old marker to the new line at the moved line's previous row
        let newLine: BILine? = affectedRows.object(at: row) as? BILine
        if newLine?.markerTitle == nil {
            newLine?.markerTitle = oldMarkerTitle
        }
        for i in firstRow...lastRow {
            let line: BILine? = affectedRows.object(at: i) as? BILine
            line?.bidOrder = i + 1 as NSNumber
        }
        previousInsertionIndex = self.insertionIndex
        //        previousInsertionIndex = 8
        if originRow > insertionIndex && destRow < insertionIndex {
            self.insertionIndex += 1
        }
        if originRow < insertionIndex && destRow > insertionIndex {
            self.insertionIndex -= 1
        }
        insertedIndexes.enumerate({(_ idx: Int, _ stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            let idxPth = IndexPath(row: idx, section: 0)
            expandedTableView.selectRow(at: idxPth, animated: false, scrollPosition: .none)
            if !self.selectedCellIndexPaths.contains(idxPth) {
                self.selectedCellIndexPaths.add(idxPth)
            }
            
        })
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        //No reordering in Freeze line
        let startLine = linesArray[indexPath.row]
        if (startLine.isFrozen != 0) {
            return false
        }
        return true
    }
    
    //Removing the delete button
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    //Removing the space of delete button
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
}

class ExpandedCalendarCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var lblWeekDays: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    
    
}
