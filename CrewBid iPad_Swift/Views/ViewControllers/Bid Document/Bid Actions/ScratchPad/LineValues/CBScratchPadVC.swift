//
//  CBScatchPadVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit
import CoreData

class CBScratchPadVC: BaseViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var lblTrashLineCount: UILabel!
    @IBOutlet weak var btnTrash: UIButton!
    @IBOutlet weak var btnFlag: UIButton!
    @IBOutlet weak var btnMoveToLine: UIButton!
    @IBOutlet weak var btnMoveAllToBidList: UIButton!
    @IBOutlet weak var lblScratchpadLineCount: UILabel!
    @IBOutlet weak var scratchPadTableView: UITableView!
    
    var lines : [BILine] = []
    var linePosDictionary : [Int : Int] = [:]
    var linesFetchController:NSFetchedResultsController<BILine>!
    var filtersFetchController: NSFetchedResultsController<BIFilterRule>!
    var sortsFetchController:NSFetchedResultsController<BILineSort>!
    var sectionLines : [[BILine]] = []
    var bidPeriod : BIBidPeriod?
    var ScratchPadCalendarData = BICalendarData()
    var calendarDay : [BICalendarDay] = []
    var trashedPredicate: NSPredicate?
    var tripTextPopover: UIPopoverPresentationController?
    var notTrashedPredicate: NSPredicate!
    var notBidPredicate: NSPredicate!
    var tripCBButton: CBTripButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        scratchPadTableView.delegate = self
        scratchPadTableView.dataSource = self
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        ScratchPadCalendarData = ScratchPadCalendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        calendarDay = ScratchPadCalendarData.calendarDays as! [BICalendarDay]
        
        lblScratchpadLineCount.isUserInteractionEnabled = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapToScrollTop(_:)))
        tap.numberOfTapsRequired = 1
        lblScratchpadLineCount.addGestureRecognizer(tap)
        
        //To make lblTrashLineCount a circle
        lblTrashLineCount.layer.cornerRadius = lblTrashLineCount.frame.width/2
        lblTrashLineCount.layer.masksToBounds = true
        
        //Tap gesture for refresh button.
        let refreshTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.trashRefreshButton))
        btnTrash.addGestureRecognizer(refreshTapGesture)
        refreshTapGesture.delaysTouchesBegan = true
        if self.bidPeriod!.managedObjectContext!.undoManager == nil {
            self.bidPeriod!.managedObjectContext!.undoManager = UndoManager()
        }
//        notificationObserver()
        
        // Filters fetched results controller.
        let filterFetch = NSFetchRequest<BIFilterRule>(entityName: "FilterRule")
        filterFetch.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true),    NSSortDescriptor(key: "type", ascending: true)]
        let moc = self.bidPeriod?.managedObjectContext
        self.filtersFetchController = NSFetchedResultsController(fetchRequest: filterFetch, managedObjectContext: moc!, sectionNameKeyPath: nil, cacheName: nil)
        self.filtersFetchController.delegate = self
        do{
            try self.filtersFetchController.performFetch()
        }catch{
            print("Filter fetch error: \(error.localizedDescription)")
        }
        
        // Sorts fetched results controller.
//        let sortFetch = NSFetchRequest<BILineSort>(entityName: "LineSort")
//        sortFetch.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
//        sortFetch.predicate = NSPredicate(format: "isBidListSort != %@", NSNumber(value: true))
//        self.sortsFetchController = NSFetchedResultsController(fetchRequest: sortFetch, managedObjectContext: moc!, sectionNameKeyPath: nil, cacheName: nil)
//        self.sortsFetchController.delegate = self
//        do{
//            try self.sortsFetchController.performFetch()
//        }catch{
//            print("Sort fetch error: \(error.localizedDescription)")
//        }
        
        // Lines fetched results controller.
        self.notTrashedPredicate = NSPredicate(format: "isTrashed == NO")
        self.notBidPredicate = NSPredicate(format: "bidOrder == 0")
//        let subArray = NSMutableArray(array: [self.filtersFetchController.fetchedObjects!])
//        let subpredicates = subArray.value(forKey: "predicate")
        updateLines()
    }
    
    func updateLines(){
        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
            lines.append(line)
        }
        self.lines.sort {
            ($0.number?.intValue ?? 0) < ($1.number?.intValue ?? 0)
        }
        print("Lines count: \(lines.count)")
        var tempArray : [BILine] = []
        var count : Int = -1
        for line in self.lines {
            count = count + 1
            if tempArray.count == 0 {
                tempArray.append(line)
            }else{
                if tempArray[0].number == line.number {
                    tempArray.append(line)
                }else{
                    self.sectionLines.append(tempArray)
                    tempArray = []
                    tempArray.append(line)
                }
            }
            if (count + 1) == self.lines.count {
                self.sectionLines.append(tempArray)
            }
        }
        DispatchQueue.main.async {
            self.lblScratchpadLineCount.text = "Scratchpad- \(self.lines.count) Lines"
//            self.fetchTrashedLinesCount()
            self.scratchPadTableView.reloadData()
        }
    }
    
//    func fetchTrashedLinesCount(){
//        var tempLines:[BILine] = []
//        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
//            tempLines.append(line)
//        }
//        
//        let sort = NSSortDescriptor(key: "number", ascending: true)
//        let sortedLines = (tempLines as NSArray).sortedArray(using: [sort]) as! [BILine]
//        
//        var array:[NSPredicate] = []
//        array.append(NSPredicate(format: "isTrashed == %@", NSNumber(booleanLiteral: true)))
//        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
//        let predicateValue = (sortedLines as NSArray).filtered(using: predicate) as! [BILine]
//        let isTrashedCount = predicateValue.count
//        if isTrashedCount == 0 {
//            self.lblTrashLineCount.isHidden = true
//            self.lblTrashLineCount.text = "\(0)"
//        }else{
//            self.lblTrashLineCount.isHidden = false
//            self.lblTrashLineCount.text = "\(isTrashedCount)"
//        }
//    }
    
    func showTripTextPopover(for tripButton: CBTripButton){
        if tripTextPopover == nil {
            if self.presentedViewController is CBTripTextViewController{
                self.dismiss(animated: true)
                return
            }
//            let tripText = tripButton.trip!.tripText()
//            let tripTextController = CBTripTextViewController.instantiateFromStoryboard(withTripText: tripText, button: tripButton) as! CBTripTextViewController
//            tripTextController.modalPresentationStyle = .custom
//            self.tripCBButton = tripButton
//            tripButton.setHighlighted(true)
//            tripTextController.tripText1 = tripText
//            tripTextController.button = tripButton
//            tripTextController.isFromScratchpad = true
//            tripTextController.showPopover(sourceView: tripButton)
        }
    }
    
    @objc func handleTapToScrollTop(_ sender: UITapGestureRecognizer) {
        guard self.scratchPadTableView.numberOfSections > 0 else {
            return
        }
        guard self.scratchPadTableView.numberOfRows(inSection: 0) > 0 else {
            return
        }
        self.scratchPadTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    //Tap gesture for refresh button in trash menu.
    @objc func trashRefreshButton(_ gesture: UITapGestureRecognizer) {
//        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
//        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshMenuController") as! RefreshMenuController
//        refreshViewController.popOverType = PopoverViewType.Refresh
//        refreshViewController.modalPresentationStyle = .popover
//        let frame = CGRect(x: btnTrash.frame.origin.x - 40, y: btnTrash.frame.origin.y + 20 , width: 0, height: 0)
//        refreshViewController.showPopover(sourceView: self.btnTrash, sourceRect: frame)
    }

    @IBAction func btnFlagAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBUserFlagTableController") as! CBUserFlagTableController
        lineValuesController.modalPresentationStyle = .popover
        lineValuesController.showPopover(sourceView: self.btnFlag)
    }
    
    //Scroll to Line
    @IBAction func btnMoveToLineAction(_ sender: Any) {
        let alert = UIAlertController(title: "Scroll to Line", message: "Enter the line number you wish to scroll to:", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Enter line no"
            textField.delegate = self
            textField.keyboardType = .numberPad
            textField.tag = 333
        }
        alert.addAction(UIAlertAction(title: "Scroll in Scratchpad", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            let lineNumber: String = textField!.text!
            if(!(lineNumber.length > 0)) {
                AlertService.showAlertForTopVC(title: "Line not found", message: "Line \(lineNumber) is not in the Scratchpad.  It is either filtered out, trashed, or in the Bid List.", actions: nil)
                return
            }
            for i in 0..<self.sectionLines.count {
                for line in self.sectionLines[i] {
                    let numberOnly = lineNumber.filter { $0.isNumber }
                    if line.number?.stringValue == numberOnly {
                        self.scratchPadTableView.scrollToRow(at: IndexPath(row: 0, section: i), at: .middle, animated: true)
                        return
                    }
                }
            }
            AlertService.showAlertForTopVC(title: "Line not found", message: "Line \(lineNumber) is not in the Scratchpad. It is either filtered out, trashed, or in the Bid List.", actions: nil)
                
        }))
        
        alert.addAction(UIAlertAction(title: "Scroll in BidList", style: .default, handler: {
            [weak alert] (_) in
                let textField = alert?.textFields![0]
                let lineNumber: String = textField!.text!
                if(!(lineNumber.length > 0)) {
                    let alertController = UIAlertController(title: "No line entered.", message: "You must enter a line number when selecting the Scroll to Line option.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                
                let appendDictionary = NSMutableDictionary()
                appendDictionary["lineNumber"] = lineNumber
                self.dismiss(animated: true) {
                    //need to function
                    NotificationCenter.default.post(name: Notification.Name("ScrollToLineNotification"), object: appendDictionary)
                }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    
}

extension CBScratchPadVC: UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionLines.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScratchPadTableCellTableViewCell") as! ScratchPadTableCellTableViewCell
        cell.selectionStyle = .none
        cell.availableFaLines = self.sectionLines[indexPath.section]
        cell.orderLabel.text = "\(indexPath.section + 1)"
        let line = self.sectionLines[indexPath.section][indexPath.row]
        configureCell(cell, line: line, row: indexPath.section)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 273
    }
    
    func configureCell(_ cell:ScratchPadTableCellTableViewCell, line:BILine, row : Int) {
        cell.lineNumberLabel.text = line.number?.stringValue
        cell.calendarData = ScratchPadCalendarData
        cell.calendarDaysArr = calendarDay
        cell.bidPeriod = bidPeriod!
        cell.line = line
        cell.contentView.tag = row
        cell.index = row
        cell.tableView = scratchPadTableView
        //function to set trip text view
        
        let setupCircles = true
        if (bidPeriod?.isFABid())!{
            cell.removeAllTripButtons()
            cell.posAGrayView.alpha = 0
            cell.posBGrayView.alpha = 0
            cell.posCGrayView.alpha = 0
            cell.posDGrayView.alpha = 0
            cell.posAView.alpha = 0
            cell.posBView.alpha = 0
            cell.posCView.alpha = 0
            cell.posDView.alpha = 0
            cell.posMView.alpha = 0
            cell.posNAView.alpha = 0
            
            if line.faPositionString() == "NA"{
                cell.posNAView.alpha = 1
                //refresh trips button funciton
            }else if line.faPositionString() == "M"{
                cell.posMView.alpha = 1
                //refresh trip button function
            }else{
                if setupCircles{
                    cell.posAGrayView.alpha = 0.15
                    cell.posBGrayView.alpha = 0.15
                    cell.posCGrayView.alpha = 0.15
                    cell.posDGrayView.alpha = 0.15
                    if line.number == 350{
                        print("")
                    }
                    let linesFA = self.sectionLines[row]
                    for (index,posLine) in linesFA.enumerated() {
                        let posString = posLine.faPositionString()
                        if posString == "A" {
                            cell.setCircle(index, withPos: posLine.faPositionString(), color: CBColor.faPosAColor, isGray: false)
                        }else if posString == "B" {
                            cell.setCircle(index, withPos: posLine.faPositionString(), color: CBColor.faPosBColor, isGray: false)
                        }else if posString == "C" {
                            cell.setCircle(index, withPos: posLine.faPositionString(), color: CBColor.faPosCColor, isGray: false)
                        }else {
                            cell.setCircle(index, withPos: posLine.faPositionString(), color: CBColor.faPosDColor, isGray: false)
                        }
                    }
                    //needs function
                    
                }
            }
        }else{
            cell.posAGrayView.alpha = 0
            cell.posBGrayView.alpha = 0
            cell.posCGrayView.alpha = 0
            cell.posDGrayView.alpha = 0
            cell.posAView.alpha = 0
            cell.posBView.alpha = 0
            cell.posCView.alpha = 0
            cell.posDView.alpha = 0
            cell.posMView.alpha = 0
            cell.posNAView.alpha = 0
        }
        
        if line.isRedEyeLine == true{
            cell.redEyeImage.isHidden = false
        }else{
            cell.redEyeImage.isHidden = true
        }
        
        //Set Etops line
        if line.isETOPSRES?.boolValue == true{
            cell.lineNumberLabel.text = cell.lineNumberLabel.text! + "Re"
            let strTitle = cell.lineNumberLabel.text! as NSString
            let tickRange = strTitle.range(of: "Re")
            let attrString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
            attrString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: tickRange)
            cell.lineNumberLabel.attributedText = attrString
        }else if !bidPeriod!.isFABid() && bidPeriod!.isSecondRoundBid() && (line.type == BILineType.MixedLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsMixed.rawValue.asNSNumber){
            cell.lineNumberLabel.text = cell.lineNumberLabel.text! + "mR"
            let strTitle = cell.lineNumberLabel.text! as NSString
            let tickRange = strTitle.range(of: "mR")
            let attrString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
            attrString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: tickRange)
            cell.lineNumberLabel.attributedText = attrString
        }else if bidPeriod!.isFABid() && bidPeriod!.isSecondRoundBid(){
            let reserveTypeSuffixMap:[NSNumber:String] = [BIFaReserveLineType.SnrAMres.rawValue.asNSNumber: "sa", BIFaReserveLineType.SnrPMres.rawValue.asNSNumber: "sp", BIFaReserveLineType.JnrAMres.rawValue.asNSNumber: "ja", BIFaReserveLineType.JnrPMres.rawValue.asNSNumber: "jp", BIFaReserveLineType.JnrLateRes.rawValue.asNSNumber: "jl"]
            
            if let faReserveLineType = line.faReserveLineType, let suffix = reserveTypeSuffixMap[faReserveLineType] {
                cell.lineNumberLabel.text = cell.lineNumberLabel.text! + suffix
                let strTitle = cell.lineNumberLabel.text! as NSString
                let tickRange = strTitle.range(of: suffix)
                let attrString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
                attrString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
                attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: tickRange)
                cell.lineNumberLabel.attributedText = attrString
            }
        }else if line.type == BILineType.ReserveLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsReserve.rawValue.asNSNumber {
            cell.lineNumberLabel.text = cell.lineNumberLabel.text! + "R"
            let strTitle = cell.lineNumberLabel.text! as NSString
            let tickRange = strTitle.range(of: "R")
            let attrString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
            attrString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: tickRange)
            cell.lineNumberLabel.attributedText = attrString
        }
        if line.isETOPS?.boolValue == true{
            cell.lineNumberLabel.text = cell.lineNumberLabel.text! + "e"
            let strTitle = cell.lineNumberLabel.text! as NSString
            let tickRange = strTitle.range(of: "e")
            let attrString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
            attrString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range:tickRange)
            cell.lineNumberLabel.attributedText = attrString
        }
        //Setting the flag
        cell.userFlagIconView.backgroundColor = CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType(rawValue: Int(truncating: (line.userFlagType)!))!)
        if CBUserFlagType.none == CBUserFlagType(rawValue: line.userFlagType as! Int) {
            cell.userFlagIconView.alpha = 1
        }else{
            cell.userFlagIconView.alpha = 1
        }
        // Line values.
        let lineValuesKey = CBLineValuesMenuController.lineValuesKey(for: self.bidPeriod!)
        let lineValuesToDisplay = NSMutableArray()
        if UserDefaults.standard.object(forKey: lineValuesKey) != nil {
            let arr = UserDefaults.standard.value(forKey: lineValuesKey) as! [Any]
            lineValuesToDisplay.addObjects(from: arr)
        }
        for i in 0..<lineValuesToDisplay.count {
            let tag = 100 + i * 10
            let valueType: NSInteger
            let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
            if let val = lineValuesToDisplay[i] as? NSNumber {
                valueType = NSInteger(truncating: val)
            }else if let val = lineValuesToDisplay[i] as? String {
                valueType = NSInteger(val)!
            }else{
                let val = lineValuesToDisplay[i] as! Int
                valueType = NSInteger(val)
            }
            if lineValueView != nil {
                CBLineValuesMenuController.setLineValueView(lineValueView!, with: line, forType: CBLineValueTypes(rawValue: valueType)!, bidPeriod: self.bidPeriod!)
            }else{
                print("Line value is nil - \(tag) - \(row) - \(CBLineValueTypes(rawValue: valueType)!)")
            }
            lineValueView?.alpha = 1
            if CBLineValueTypes(rawValue: valueType) == .cbVacationPayDifference {
                if self.bidPeriod?.cbFileIntent != nil {
                    if line.vCBVacPay!.doubleValue > 0 || line.orderedTrips.count == 0 {
                        lineValueView?.alpha = 1
                    }else{
                        lineValueView?.alpha = 0
                    }
                }else{
                    lineValueView?.alpha = 0
                }
            }else{
                lineValueView?.alpha = 1
            }
        }
        // Set any unused lineValueViews to transparent
        for i in lineValuesToDisplay.count..<5 {
            let tag = 100 + i * 10
            let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
            lineValueView?.alpha = 0
        }
    }
}

extension CBScratchPadVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow backspace to work
        if string.isEmpty {
            return true
        }
        
        // Allow only numbers in the text field for Pilot Bids.
        if !self.bidPeriod!.isFABid() {
            let numberCharSet = CharacterSet(charactersIn: "0123456789")
            for character in string {
                if !numberCharSet.contains(Unicode.Scalar(String(character))!) {
                    return false
                }
            }
        }
        
        return true
    }
}
