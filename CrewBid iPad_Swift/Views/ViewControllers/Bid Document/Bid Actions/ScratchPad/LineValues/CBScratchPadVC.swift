//
//  CBScratchPadVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit
import CoreData


protocol ScratchPadCellDelegate: AnyObject {
    func scratchPadCellRemoveLineRequest(_ cell: ScratchPadTableCellTableViewCell)
}
class CBScratchPadVC: BaseViewController, NSFetchedResultsControllerDelegate, UIPopoverControllerDelegate, ScratchPadCellDelegate, UIPopoverPresentationControllerDelegate {
    
    



    @IBOutlet weak var lblTrashLineCount: UILabel!
    @IBOutlet weak var btnTrash: UIButton!
    @IBOutlet weak var btnFlag: UIButton!
    @IBOutlet weak var btnMoveToLine: UIButton!
    @IBOutlet weak var btnMoveAllToBidList: UIButton!
    @IBOutlet weak var lblScratchpadLineCount: UILabel!
    @IBOutlet weak var scratchPadTableView: UITableView!
    
    var lines : [BILine] = []
    var sectionLines:[[BILine]] = []
    var bidPeriod : BIBidPeriod?
    var ScratchPadCalendarData = BICalendarData()
    var calendarDay : [BICalendarDay] = []
    var tripTextPopover: UIPopoverPresentationController?
    var notBidPredicate: NSPredicate!
    var tripCBButton: CBTripButton!
    private var maxPositionsPerLine: Int = 4
    var userFaPosOrder:NSMutableArray!
    var updateScratchpadTitle: Bool = true
    var linesArray:NSMutableArray?
    var linePosDict:NSDictionary?
    var lineBILineDict: [String: [BILine]] = [:]
    var arrayLinesDetails:NSArray = NSArray()
    var positionFlag1 = 0
    var positionFlag2 = 0
    var tempPositionLine : [BILine] = []
    var menuItems = NSMutableArray()
    var menuController:CBMenuController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.clipsToBounds = true
        self.view.layer.cornerRadius = 5
        scratchPadTableView.delegate = self
        scratchPadTableView.dataSource = self
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        self.bidPeriod?.isBidListSortOn = false
        self.bidPeriod?.deleteAllBidListSorts()
        updateLines()
        fetchTrashedLinesCount()
        ScratchPadCalendarData = ScratchPadCalendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        calendarDay = ScratchPadCalendarData.calendarDays as! [BICalendarDay]
        lblScratchpadLineCount.isUserInteractionEnabled = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapToScrollTop(_:)))
        tap.numberOfTapsRequired = 1
        lblScratchpadLineCount.addGestureRecognizer(tap)
        
        //To make lblTrashLineCount a circle
        lblTrashLineCount.layer.cornerRadius = lblTrashLineCount.frame.height/2
        lblTrashLineCount.layer.masksToBounds = true
        
        //Tap gesture for refresh button.
        let refreshTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.trashRefreshButton))
        btnTrash.addGestureRecognizer(refreshTapGesture)
        refreshTapGesture.delaysTouchesBegan = true
        notificationObserver()
        calculateAMPMFromSync()
        //For setting undo in bidlist
        self.arrayLinesDetails = self.bidPeriod?.lastTrashedDetails ?? NSMutableArray()
        if self.bidPeriod!.managedObjectContext!.undoManager == nil {
            self.bidPeriod!.managedObjectContext!.undoManager = UndoManager()
        }

    }
        
    @objc func updateLines(){
        self.lines.removeAll()
        self.sectionLines.removeAll()
        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
            lines.append(line)
        }
        //sorting the line numbers
        let sortPredicates = updateSorts()
//        print(sortPredicates)
        self.lines = (lines as NSArray).sortedArray(using: sortPredicates) as! [BILine]
        
        //Filtering the lines
        var subpredicatesArr = [BIFilterRule]()
        subpredicatesArr = (self.bidPeriod!.lineFilters ?? NSSet()).allObjects as! [BIFilterRule]
        if !(bidPeriod!.vacationType?.count ?? 0 > 0) {
            let pr = NSPredicate(format: "category != \(NSNumber(value: BIFilterRuleCategory.BIVacationFilterRuleCategory.rawValue))")
            let pr2 = NSPredicate(format: "category != \(NSNumber(value: BIFilterRuleCategory.BIFaVacationFilterRuleCategory.rawValue))")
            subpredicatesArr = (subpredicatesArr as NSArray).filtered(using: NSCompoundPredicate.init(andPredicateWithSubpredicates: [pr, pr2])) as! [BIFilterRule]
        }
        var array : [NSPredicate] = []
        //For getting filter predicate
        array = subpredicatesArr.map { $0.predicate }
//        print("QuickFilters", array)
        array.append(NSPredicate(format: "bidOrder == %@", NSNumber(integerLiteral: 0)))
        array.append(NSPredicate(format: "isTrashed == %@", NSNumber(booleanLiteral: false)))
        if bidPeriod?.isOverNightBulkApplied == "YES" {
            let overnightPredicates = CBUtils.checkOvernightPredicate()
            for predicate in overnightPredicates {
                array.append(predicate)
            }
        }
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        self.lines = (lines as NSArray).filtered(using: predicate) as! [BILine]
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
        //For updating the scratchpad UI
        DispatchQueue.main.async {
            self.lblScratchpadLineCount.text = "Scratchpad - \(self.lines.count) Lines"
            self.fetchTrashedLinesCount()
            if #available(iOS 26.0, *) {
               let currentOffset = self.scratchPadTableView.contentOffset
                
                UIView.performWithoutAnimation {
                    self.scratchPadTableView.reloadData()
                    self.scratchPadTableView.layoutIfNeeded()
                }
                 
                let maxOffsetY = max(0, self.scratchPadTableView.contentSize.height - self.scratchPadTableView.bounds.height)
                let clampedOffset = CGPoint(x: currentOffset.x, y: min(currentOffset.y, maxOffsetY))
                self.scratchPadTableView.setContentOffset(clampedOffset, animated: false)
            } else {
                self.scratchPadTableView.reloadData()
            }
        }
    }

    
    
    func notificationObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(updateLines), name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLines), name: NSNotification.Name("updateScrthPad"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(removedTrashLines), name: NSNotification.Name("removedLines"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(undoTrashLast), name: NSNotification.Name("undoTrashLast"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trashAll), name: NSNotification.Name("trashAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(recoverAllTrashed), name: NSNotification.Name("recoverAllTrashed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(calculateAMPMFromSync), name: NSNotification.Name("amPmValueChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(calculateAMPMFromButton), name: NSNotification.Name("amPmValueChangedFromButton"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideVacationInScratchpad), name: NSNotification.Name("HideVacationScratchpad"), object: nil)

    }
    
    @objc func hideVacationInScratchpad(){
        self.updateLines()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deHighlightTrip), name: NSNotification.Name(rawValue: CBLineTableCellTripButtonDehighlightNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bidCellLine), name: NSNotification.Name(CBLineTableCellBidLineNotification), object: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //Remove Observe Scratchpad line trashing notification
//        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver("refreshLines")
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updateScrthPad"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("CBLineTableCellTripButtonDehighlightNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(CBLineTableCellTripButtonDehighlightNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(CBLineTableCellBidLineNotification), object: nil)
    }

    //Adding line to bidlist
    @objc func bidCellLine(_ notification: Notification) {
        //For passing FA line to bidlist we need to show a view for position
        if let buttonView = notification.userInfo![CBLineTableCellButtonViewKey] as? UIView, let Lines = notification.userInfo!["Lines"] as? [BILine], let lineNum = notification.userInfo!["LineNum"] as? Int {
            var tempLines : [BILine] = []
            for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
                tempLines.append(line)
            }
            tempLines = (tempLines as NSArray).sortedArray(using: [NSSortDescriptor(key: "number", ascending: true)]) as! [BILine]
            var array : [NSPredicate] = []
            //If bidOrder = 0 only line is in scratchpad
            array.append(NSPredicate(format: "bidOrder == %@", NSNumber(integerLiteral: 0)))
            array.append(NSPredicate(format: "isTrashed == %@", NSNumber(booleanLiteral: false)))
            array.append(NSPredicate(format: "number == %@", NSNumber(value: lineNum)))
            
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
            //Lines in scratchpad
            tempLines = (tempLines as NSArray).filtered(using: predicate) as! [BILine]
            for case let sort as BILineSort in (bidPeriod?.lineSorts?.allObjects ?? []) {
                if sort.category?.intValue == 3{
                    positionFlag1 = 1
                }
            }
            if positionFlag1 == 1{
                let lineSorts = getSortDiscriptorsPosition()
//                print(lineSorts)
                tempPositionLine = (tempLines as NSArray).sortedArray(using: lineSorts ) as! [BILine]
                tempLines = (tempPositionLine as NSArray).sortedArray(using: [NSSortDescriptor(key: "number", ascending: true)]) as! [BILine]
                positionFlag1 = 0
            }
            else{
                tempLines = (tempLines as NSArray).sortedArray(using: [NSSortDescriptor(key: "number", ascending: true),NSSortDescriptor(key: "faPosition", ascending: true)]) as! [BILine]
            }

            
            if Lines.count != tempLines.count {
                if tempLines.first?.number == Lines.first?.number {
                   tempLines = Lines
                }
            }
            if tempLines.count == 0 {
                return
            } else if tempLines.count == 1 { //Lines move directly to bidlist
                let bidlist = CBBidListVC()
                bidlist.setupVariables()
                bidlist.insertLines(tempLines)
                NotificationCenter.default.post(name: NSNotification.Name("flipToBidList"), object: nil)
            } else {
                var arr : [String] = []
                for item in tempLines {
                    arr.append("Move Position \(item.faPositionString) to Bid List")
                }
                arr.sort() //For sorting the position
                arr.append("Move All Positions to Bid List")
                let vc = UIStoryboard(name: "BidDocument", bundle: nil).instantiateViewController(withIdentifier: "FaMoveBidListMenu") as! FaMoveBidListMenu
                vc.array = arr
                vc.lines = tempLines
                vc.modalPresentationStyle = .popover
                let frame = CGRect(x: btnTrash.frame.origin.x - 40, y: btnTrash.frame.origin.y + 20 , width: 0, height: 0)
                vc.showPopover(sourceView: buttonView, sourceRect: frame)
            }
        }
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
    
    func getSortDiscriptorsPosition() -> [NSSortDescriptor] {
        
        // Create an expression for sorting by line number
        let number = NSExpression(forKeyPath: "number")
        let numberExpDescription = NSExpressionDescription()
        numberExpDescription.name = "number"
        numberExpDescription.expression = number
        numberExpDescription.expressionResultType = .integer16AttributeType
        
        // Initialize an array to store sort descriptors

        var lineSortDiscriptors = [NSSortDescriptor]()
        

        
        // Initialize default position order
        var standardPosOrder = [0, 1, 2, 3]
        let userPosOrder = NSMutableArray()
        
        // Iterate through user-defined line sorts

        for case let lineSort in self.bidPeriod!.getOrderedSortsForPosition(){
            // Ignore line sorts that do not have a key path since these will not
            // be valid sorts.
            
            if nil == lineSort.keyPath || 0 == (lineSort.keyPath?.length ?? 0) {
                continue
            } else {
                if lineSort.category == 3 {
                    // Insert the line number sort first
                    let sort = NSSortDescriptor(key: numberExpDescription.name, ascending: true)
                    lineSortDiscriptors.append(sort)
                    userPosOrder.add(lineSort.type!)
                }
                // Create a sort descriptor based on the user's selection

                let sort = NSSortDescriptor(key: lineSort.keyPath, ascending: (lineSort.ascending != 0))
                lineSortDiscriptors.append(sort)
            }
        }
        // Adjust the position order based on user-defined sorts

        for pos in userPosOrder {
            while let elementIndex = standardPosOrder.firstIndex(of: pos as! Int) { standardPosOrder.remove(at: elementIndex) }
        }
        userPosOrder.add(standardPosOrder)
        // If no user-defined sorts, use default sorting by line number

        if self.bidPeriod!.getOrderedSortsForPosition().count == 0 {
            lineSortDiscriptors.append(NSSortDescriptor(key: "bidOrder", ascending: true))
        } else {
            let sort = NSSortDescriptor(key: numberExpDescription.name, ascending: true)
            lineSortDiscriptors.append(sort)
            // Ensure that the lines are sorted by position if FA since the position logic depends on it
            if bidPeriod!.isFABid() {
                let positionSort = NSSortDescriptor(key: "faPosition", ascending: true)
                lineSortDiscriptors.append(positionSort)
            }
        }
        
       
        return lineSortDiscriptors
    }
    
    //Trash all lines from scratchpad
    @objc func trashAll(){
        if self.lines.count > 0 {
            var tempArray : [String] = []
            for line in self.lines {
                line.isTrashed = NSNumber(booleanLiteral: true)
                if bidPeriod!.isFABid() {
                    tempArray.append("\(String(describing: line.number!.stringValue))\(line.faPositionString)")
                }
                else {
                    tempArray.append(line.number!.stringValue)
                }
            }
            let temp : NSMutableArray = self.bidPeriod?.lastTrashedDetails as? NSMutableArray ?? NSMutableArray()
            temp.add(tempArray)
            self.bidPeriod?.lastTrashedDetails = temp
            self.arrayLinesDetails = temp
            self.updateLines()
        }
    }
    
    //Undo trash line
    @objc func undoTrashLast(){
        if let LastObject = self.bidPeriod?.lastTrashedDetails?.lastObject as? NSArray {
            if let myArray = LastObject as? [String] {
                var isItemRemoved = false
                for item in myArray {
                    for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
                        if bidPeriod?.isFABid() == true {
                            let pos = item.last
                            let number = item
                            if line.number?.stringValue == number.trimmingCharacters(in: CharacterSet.letters) {
                                line.isTrashed = NSNumber(booleanLiteral: false)
                                isItemRemoved = true
                            }
                        }
                        else {
                            if line.number?.stringValue == item {
                                line.isTrashed = NSNumber(booleanLiteral: false)
                                isItemRemoved = true
                            }
                        }
                    }
                }
                
                if isItemRemoved {
                    let temp : NSMutableArray = self.bidPeriod?.lastTrashedDetails as? NSMutableArray ?? NSMutableArray()
                    temp.removeLastObject()
                    self.bidPeriod?.lastTrashedDetails = temp
                    self.arrayLinesDetails = temp
                }
            }
        }
        do{
            try self.bidPeriod?.managedObjectContext?.save()
            updateLines()
        }catch {
            print(error)
        }
    }
    
    //Recover all trashed line and move back to scratchpad
    @objc func recoverAllTrashed(){
        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
            line.isTrashed = NSNumber(booleanLiteral: false)
        }
        self.bidPeriod?.lastTrashedDetails = nil
        do{
            try self.bidPeriod?.managedObjectContext?.save()
        }catch {
            print("Error in recoverAllTrashed: \(error.localizedDescription)")
        }
        updateLines()
    }
    
    //Remove trashed lines from scratchpad
    
    func scratchPadCellRemoveLineRequest( _ cell: ScratchPadTableCellTableViewCell) {
        guard let indexPath = scratchPadTableView.indexPath(for: cell) else { return }
        let sectionIndex = indexPath.section
        removeLine(at: sectionIndex)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    private func removeLine(at sectionIndex: Int) {
        for line in sectionLines[sectionIndex] {
            if line.isTrashed == NSNumber(true) { return }
            line.isTrashed = NSNumber(value: true)
        }

        let lineNumbersFa = sectionLines[sectionIndex].compactMap { line in
            let faPos = line.faPositionString
            if let number = line.number?.stringValue{
                return "\(number)\(faPos)"
            }
            return nil
        }

        
        let lineNumbers = sectionLines[sectionIndex].compactMap { $0.number?.stringValue }
        let temp: NSMutableArray = bidPeriod?.lastTrashedDetails as? NSMutableArray ?? NSMutableArray()
        if bidPeriod!.isFABid() {
            temp.add(lineNumbersFa)
        }
        else {
            temp.add(lineNumbers)
        }
        bidPeriod?.lastTrashedDetails = temp.mutableCopy() as? NSArray

        try? bidPeriod?.managedObjectContext?.save()
//        print("Saving lastTrashedDetails = \(bidPeriod?.lastTrashedDetails ?? [])")
    }

//    @objc func removedTrashLines(notification: NSNotification){
//        print("removedTrashLines fired with object: \(String(describing: notification.object)) in \(self)")
//        if self.bidPeriod!.isFABid(){
//            if let index = notification.object as? Int {
//                for line in self.sectionLines[index]{
//                    if line.isTrashed == NSNumber(true) {
//                        return
//                    }
//                    line.isTrashed = NSNumber(true)
//                }
//                let temp : NSMutableArray = self.bidPeriod?.lastTrashedDetails as? NSMutableArray ?? NSMutableArray()
//                temp.add([self.sectionLines[index][0].number!.stringValue])
//                self.bidPeriod?.lastTrashedDetails = temp.mutableCopy() as? NSArray
//
//                print("Saving lastTrashedDetails = \(self.bidPeriod?.lastTrashedDetails ?? [])")
//                try? self.bidPeriod?.managedObjectContext?.save()
//                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
//            }
//        }else{
//            if let lineNumArray = notification.object as? NSArray {
//                let temp : NSMutableArray = self.bidPeriod?.lastTrashedDetails as? NSMutableArray ?? NSMutableArray()
//                temp.add(lineNumArray)
//                self.bidPeriod?.lastTrashedDetails = temp
//                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
//            }
//        }
//    }
    
    func updateSorts() -> [NSSortDescriptor] {
        var count: Int = (bidPeriod!.lineSorts ?? NSSet()).count
        var lineSortsArray = NSArray()
        if count > 0 {
            let predicate = NSPredicate(format: "isBidListSort != \(NSNumber(value: true))")
            lineSortsArray =  ((bidPeriod!.lineSorts!.allObjects as NSArray).filtered(using: predicate) as NSArray).sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as NSArray
            
            if !((bidPeriod?.vacationType?.count ?? 0) > 0) {
                let pr = NSPredicate(format: "category != \(NSNumber(value: BILineSortCategory.BIFaVacationLineSortCategory.rawValue))")
                let pr2 = NSPredicate(format: "category != \(NSNumber(value: BILineSortCategory.BISwaptimizerLineSortCategory.rawValue))")
                lineSortsArray = lineSortsArray.filtered(using: NSCompoundPredicate.init(andPredicateWithSubpredicates: [pr, pr2])) as NSArray
            }
            
            count = lineSortsArray.count
        }
        var lineSorts : [NSSortDescriptor] = []
        // Always get type and number for lines.
        let type = NSExpression(forKeyPath: "type")
        let typeExpDescription = NSExpressionDescription()
        typeExpDescription.name = "type"
        typeExpDescription.expression = type
        typeExpDescription.expressionResultType = .integer16AttributeType
        
        let number = NSExpression(forKeyPath: "number")
        let numberExpDescription = NSExpressionDescription()
        numberExpDescription.name = "number"
        numberExpDescription.expression = number
        numberExpDescription.expressionResultType = .integer16AttributeType
        
        var addedLineNumSort = false
        // Get values for all sort descriptors.
        let standardPosOrder: NSMutableArray = [0, 1, 2, 3]
        let userPosOrder = NSMutableArray(capacity:maxPositionsPerLine)
        for i in 0..<count {
            let lineSort = lineSortsArray[i] as? BILineSort
            if nil == lineSort?.keyPath || 0 == (lineSort?.keyPath?.length ?? 0) {
                continue
            } else {
                if lineSort?.category?.intValue == BILineSortCategory.BIPositionsLineSortCategory.rawValue {
                    if !addedLineNumSort {
                        let sort = NSSortDescriptor(key: numberExpDescription.name, ascending: true)
                        lineSorts.append(sort)
                        addedLineNumSort = true
                    }
                    userPosOrder.add(lineSort?.type as Any)
                }
                let sort = NSSortDescriptor(key: lineSort?.keyPath, ascending: (lineSort?.ascending?.boolValue)!)
                    lineSorts.append(sort)
            }
        }
        for pos in userPosOrder {
            standardPosOrder.remove(pos)
        }
        userPosOrder.add(standardPosOrder)
        var sort = NSSortDescriptor(key: typeExpDescription.name, ascending: true)
        sort = NSSortDescriptor(key: numberExpDescription.name, ascending: true)
        lineSorts.append(sort)
        // Ensure that the lines are sorted by position if FA since the position logic depends on it
        if bidPeriod!.isFABid() {
            let positionSort = NSSortDescriptor(key: "faPosition", ascending: true)
            lineSorts.append(positionSort)
        }
        return lineSorts
    }
    
    
    @objc func calculateAMPMFromSync(){
        let herbTime = Int(UserDefaults.standard.string(forKey: KCBCustomizedHerbValue) ?? "1200")
        self.recalculateAmPmWith(herbTime: herbTime ?? 1200)
    }
    
    func recalculateAmPmWith(herbTime: Int){
        if herbTime != CBGlobalMethods.shared.selectedBidPeriod?.currentAmPmHerb?.intValue{
            for line in CBGlobalMethods.shared.selectedBidPeriod!.orderedLines(){
                for trip in line.orderedTripObjects(){
                    let tripInfo = trip.info!
                    
                    if trip.isReserve{
                        if tripInfo.departTime!.intValue < 800 {
                            tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.AMTrip.rawValue)
                        }else{
                            tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.PMTrip.rawValue)
                        }
                    }else{
                        var tripReportTime = NSNumber()
                        if UserDefaults.standard.bool(forKey: "IsSelectedReporTimeForTripButton") {
                            tripReportTime = tripInfo.reportTime()
                            if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
                                tripReportTime = self.getLocalTimeWithHerb(tripReportTime, forBase: line.bidPeriod?.base ?? "") ?? 0
                            }
                            if tripReportTime.intValue < herbTime {
                            tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.AMTrip.rawValue)
                            }else{
                            tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.PMTrip.rawValue)
                            }
                        }else{
                            var tripDepartTime = NSNumber()
                            tripDepartTime = tripInfo.departTime ?? 0
                            if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue{
                                tripDepartTime = self.getLocalTimeWithHerb(tripDepartTime, forBase: line.bidPeriod?.base ?? "") ?? 0
                            }
                            if (tripDepartTime.intValue < herbTime){
                                
                                tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.AMTrip.rawValue)
                            } else {
                                tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.PMTrip.rawValue)
                            }
                        }
                    }
                }
                self.setLineAm_Pm_Mix(line: line)
            }
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
            CBGlobalMethods.shared.selectedBidPeriod?.currentAmPmHerb = NSNumber(integerLiteral: herbTime)
            do{
                try CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext?.save()
            }catch{
                print("Error saving in recalculateAmPmWith : %@", error.localizedDescription)
            }
        }
    }
    
    func setLineAm_Pm_Mix(line: BILine){
        let amExpression = NSExpression(format: "SUBQUERY(trips, $TRIP, $TRIP.info.amPM == 1).@count")
        let amTripsCount = amExpression.expressionValue(with: line, context: nil) as! NSNumber
        
        let pmExpression = NSExpression(format: "SUBQUERY(trips, $TRIP, $TRIP.info.amPM == 2).@count")
        let pmTripsCount = pmExpression.expressionValue(with: line, context: nil) as! NSNumber
        
        if line.trips?.count == 0 {
            line.amPM = NSNumber(integerLiteral: BILineAMPM.BlankAMPMLine.rawValue)
        }else if line.isRedEyeLine == true{
            line.amPM = NSNumber(integerLiteral: BILineAMPM.RedEyeAMPMLine.rawValue)
        }else{
            if line.trips?.count == amTripsCount.intValue{
                line.amPM = NSNumber(integerLiteral: BILineAMPM.AMLine.rawValue)
            }else if line.trips?.count == pmTripsCount.intValue{
                line.amPM = NSNumber(integerLiteral: BILineAMPM.PMLine.rawValue)
            }else{
                line.amPM = NSNumber(integerLiteral: BILineAMPM.MixedAMPMLine.rawValue)
            }
        }
        
    }
    
    func getLocalTimeWithHerb(_ oldValue: NSNumber, forBase base: String) -> NSNumber?{
        let hours = Int(truncating: oldValue) / 100
        let mins = Int(truncating: oldValue) - hours * 100
        let minsTemp = (hours * 60) + mins
        var newValue = NSNumber()
        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
            let departFormatter = DateFormatter()
            departFormatter.dateFormat = "HHmm"
            departFormatter.timeZone = CBUtils.timeZone(forAirportCode: base)
            
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = Locale(identifier: "en_US")
            calendar.timeZone = TimeZone(identifier: "US/Central")!
            
            var dateComps = calendar.dateComponents([.year, .month, .day], from: Date())
            dateComps.minute =  minsTemp
            let departDate = calendar.date(from: dateComps)
            newValue = NSNumber(value: Int(departFormatter.string(from: departDate!)) ?? 0)
        }
        
        return newValue
    }
    
    @objc func calculateAMPMFromButton(){
        let herbTime = Int(UserDefaults.standard.string(forKey: KCBCustomizedHerbValue) ?? "1200")
        self.recalculateAmPmFromButtonAction(herbTime: herbTime ?? 1200)
    }
    
    func recalculateAmPmFromButtonAction(herbTime: Int){
        for line in CBGlobalMethods.shared.selectedBidPeriod!.orderedLines(){
            for trip in line.orderedTripObjects(){
                let tripInfo = trip.info!
                if trip.isReserve == true {
                    if tripInfo.departTime!.intValue < 800 {
                        tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.AMTrip.rawValue)
                    }else{
                        tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.PMTrip.rawValue)
                    }
                }else{
                    var tripReportTime = NSNumber()
                    if UserDefaults.standard.bool(forKey: "IsSelectedReporTimeForTripButton"){
                        tripReportTime = tripInfo.reportTime()
                        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
                            tripReportTime = self.getLocalTimeWithHerb(tripReportTime, forBase: line.bidPeriod?.base ?? "") ?? 0
                        }
                        if tripReportTime.intValue < herbTime {
                            tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.AMTrip.rawValue)
                        }else{
                            tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.PMTrip.rawValue)
                        }
                    }else{
                        var tripDepartTime = NSNumber()
                        tripDepartTime = tripInfo.departTime ?? 0
                        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
                            tripDepartTime = self.getLocalTimeWithHerb(tripDepartTime, forBase: line.bidPeriod?.base ?? "") ?? 0
                        }
                        if tripDepartTime.intValue < herbTime {
                            tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.AMTrip.rawValue)
                        }else{
                            tripInfo.amPM = NSNumber(integerLiteral: BIAMPMTripType.PMTrip.rawValue)
                        }
                    }
                }
            }
            self.setLineAm_Pm_Mix(line: line)
        }
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
        
        do{
            try CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext?.save()
        }catch{
            print("Error saving in recalculateAmPmFromButtonAction: %@",error.localizedDescription)
        }
    }
    
    func fetchTrashedLinesCount(){
        var tempLines:[BILine] = []
        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
            tempLines.append(line)
        }
        
        let sort = NSSortDescriptor(key: "number", ascending: true)
        let sortedLines = (tempLines as NSArray).sortedArray(using: [sort]) as! [BILine]
        
        var array:[NSPredicate] = []
        array.append(NSPredicate(format: "isTrashed == %@", NSNumber(booleanLiteral: true)))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        let predicateValue = (sortedLines as NSArray).filtered(using: predicate) as! [BILine]
        let isTrashedCount = predicateValue.count
        if isTrashedCount == 0 {
            self.lblTrashLineCount.isHidden = true
            self.lblTrashLineCount.text = "\(0)"
        }else{
            self.lblTrashLineCount.isHidden = false
            self.lblTrashLineCount.text = "\(isTrashedCount)"
        }
    }
    
    func showTripTextPopover(for tripButton: CBTripButton){
        if tripTextPopover == nil {
            if self.presentedViewController is CBTripTextViewController{
                self.dismiss(animated: true)
                return
            }
            let tripText = tripButton.trip!.tripText()
            let tripTextController = CBTripTextViewController.instantiateFromStoryboard(withTripText: tripText, button: tripButton) as! CBTripTextViewController
            tripTextController.modalPresentationStyle = .custom
            self.tripCBButton = tripButton
            tripButton.setHighlighted(true)
            tripTextController.tripText1 = tripText
            tripTextController.button = tripButton
            tripTextController.isFromScratchpad = true
            tripTextController.showPopover(sourceView: tripButton)
        }
    }
    
    @objc func handleTapToScrollTop(_ sender: UITapGestureRecognizer) {
//        self.scratchPadTableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
        guard scratchPadTableView.numberOfSections > 0,
              scratchPadTableView.numberOfRows(inSection: 0) > 0 else { return }

        scratchPadTableView.scrollToRow(
            at: IndexPath(row: 0, section: 0),
            at: .top,
            animated: true
        )
    }
    
    //Tap gesture for refresh button in trash menu.
    @objc func trashRefreshButton(_ gesture: UITapGestureRecognizer) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshMenuController") as! RefreshMenuController
        refreshViewController.bidPeriod = bidPeriod!
        refreshViewController.lines = lines
        refreshViewController.popOverType = PopoverViewType.Refresh
        refreshViewController.arrayLinesDetails = arrayLinesDetails
        refreshViewController.modalPresentationStyle = .popover
        let frame = CGRect(x: btnTrash.frame.origin.x - 40, y: btnTrash.frame.origin.y + 20 , width: 0, height: 0)
        refreshViewController.showPopover(sourceView: self.btnTrash, sourceRect: frame)
    }

    @IBAction func btnFlagAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBUserFlagTableController") as! CBUserFlagTableController
        lineValuesController.delegate = self
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
                AlertService.showAlertForTopVC(title: "Line not found", message: "Line \(lineNumber) is not in the Scratchpad.  It is either filtered out, trashed, or in the Bid List.")
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
            AlertService.showAlertForTopVC(title: "Line not found", message: "Line \(lineNumber) is not in the Scratchpad.  It is either filtered out, trashed, or in the Bid List.")    
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
                    NotificationCenter.default.post(name: Notification.Name("ScrollToLineNotification"), object: appendDictionary)
                }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    @IBAction func btnMoveAllToBidListAction(_ sender: Any) {
        CBGlobalMethods.shared.isMoveAllAction = true
        let bidListVC = CBBidListVC()
        bidListVC.setupVariables()
        bidListVC.insertLines(self.lines)
        NotificationCenter.default.post(name: NSNotification.Name("flipToBidList"), object: nil)
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
        cell.delegate = self
        if indexPath.row > self.sectionLines.count - 1 {
            return UITableViewCell()
        } else {
            let line = self.sectionLines[indexPath.section][indexPath.row]
            cell.availableFaLines = self.sectionLines[indexPath.section]
            cell.orderLabel.text = "\(indexPath.section + 1)"
            configureCell(cell, line: line, row: indexPath.section)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 273
    }
    func configureCell(_ cell: ScratchPadTableCellTableViewCell, line: BILine, row : Int) {
        cell.calendarDaysArr = calendarDay
        cell.contentView.tag = row
        cell.lineNumberLabel.text = line.number?.stringValue
        cell.calendarData = ScratchPadCalendarData
        cell.line = line
        cell.index = row
        cell.tableView = scratchPadTableView
        cell.bidPeriod = bidPeriod!
        //Setting the trip text view
        cell.tripButtonActionBlock = {(_ tripButton: CBTripButton) -> Void in
            DispatchQueue.main.async {
                self.showTripTextPopover(for: tripButton)
            }        }
        cell.vacationDoubleTapActionBlock = { tappedButton in
                    DispatchQueue.main.async {
                        self.showVacationPopover(for: tappedButton, line: line)
                    }
                }
        let setupCircles = true
        
        // set up the position circles if the bid is an FA bid
        if (bidPeriod?.isFABid())! {
            // Remove all current trip buttons
            cell.removeAllTripButtons()
            cell.posAGrayView.alpha = 0.0
            cell.posBGrayView.alpha = 0.0
            cell.posCGrayView.alpha = 0.0
            cell.posDGrayView.alpha = 0.0
            cell.posAView.alpha = 0.0
            cell.posBView.alpha = 0.0
            cell.posCView.alpha = 0.0
            cell.posDView.alpha = 0.0
            cell.posMView.alpha = 0.0
            cell.posNAView.alpha = 0.0
            //Check to make sure this isn't an "NA" line
            if line.faPositionString == "NA" {
                cell.posNAView.alpha = 1.0
                cell.refreshTripButtons(highlightFlag: true, calendarWidth: self.view.frame.size.width - 160)
            }
            else if line.faPositionString == "M" {
                cell.posMView.alpha = 1.0
                cell.refreshTripButtons(highlightFlag: true, calendarWidth: self.view.frame.size.width - 160)
            } else {
                if setupCircles {
                        cell.posAGrayView.alpha = 0.15
                        cell.posBGrayView.alpha = 0.15
                        cell.posCGrayView.alpha = 0.15
                        cell.posDGrayView.alpha = 0.15
                    
                    let linesFa = self.sectionLines[row]
                    //A,B,C,D position checking
                    for (intex,posLine) in linesFa.enumerated() {
                        let positionString : String = posLine.faPositionString
                        if positionString == "A" {
                            cell.setCircle(intex, withPos: posLine.faPositionString, color: CBColor.faPosAColor, isGray: false)
                        }
                        else if positionString == "B" {
                            cell.setCircle(intex, withPos: posLine.faPositionString, color: CBColor.faPosBColor, isGray: false)
                        }
                        else if positionString == "C" {
                            cell.setCircle(intex, withPos: posLine.faPositionString, color: CBColor.faPosCColor, isGray: false)
                        }
                        else {
                            cell.setCircle(intex, withPos: posLine.faPositionString, color: CBColor.faPosDColor, isGray: false)
                        }
                    }
                }
                cell.refreshTripButtons(highlightFlag: true, calendarWidth: self.view.frame.size.width - 160)
            }
        } else {
            cell.refreshTripButtons(highlightFlag: true, calendarWidth: self.view.frame.size.width - 160)
        }
        
//        set LODO
        if line.isLODO?.boolValue == true {
            cell.lineNumberLabel.text = cell.lineNumberLabel.text! + ("L")
            let strTitle:NSString = cell.lineNumberLabel.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "L")
            let attributedString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            cell.lineNumberLabel.attributedText = attributedString
        }
        
        //Set Etops line
        if line.isETOPSRES?.boolValue == true {
            cell.lineNumberLabel.text = cell.lineNumberLabel.text! + ("Re")
            let strTitle:NSString = cell.lineNumberLabel.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "Re")
            let attributedString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            cell.lineNumberLabel.attributedText = attributedString
        }
        else if !bidPeriod!.isFABid() && bidPeriod!.isSecondRoundBid() && (line.type == BILineType.MixedLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsMixed.rawValue.asNSNumber) {
            cell.lineNumberLabel.text = cell.lineNumberLabel.text! + ("mR")
            let strTitle:NSString = cell.lineNumberLabel.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "mR")
            let attributedString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            cell.lineNumberLabel.attributedText = attributedString
        }
        else if bidPeriod!.isFABid() && bidPeriod!.isSecondRoundBid() {
                   let reserveTypeSuffixMap: [NSNumber: String] = [
                       BIFaReserveLineType.SnrAMres.rawValue.asNSNumber: "sa",
                       BIFaReserveLineType.SnrPMres.rawValue.asNSNumber: "sp",
                       BIFaReserveLineType.JnrAMres.rawValue.asNSNumber: "ja",
                       BIFaReserveLineType.JnrPMres.rawValue.asNSNumber: "jp",
                       BIFaReserveLineType.JnrLateRes.rawValue.asNSNumber: "jl"
                   ]

                   if let faReserveLineType = line.faReserveLineType,
                      let suffix = reserveTypeSuffixMap[faReserveLineType] {
                       cell.lineNumberLabel.text = cell.lineNumberLabel.text! + suffix
                       let strTitle: NSString = cell.lineNumberLabel.text! as NSString
                       let tickRange: NSRange = strTitle.range(of: suffix)
                       let attributedString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
                       attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
                       attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
                       cell.lineNumberLabel.attributedText = attributedString
                   }
               }
        else if line.type == BILineType.ReserveLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsReserve.rawValue.asNSNumber{
            cell.lineNumberLabel.text = cell.lineNumberLabel.text! + ("R")
            let strTitle:NSString = cell.lineNumberLabel.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "R")
            let attributedString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            cell.lineNumberLabel.attributedText = attributedString
        }
        else if line.isETOPS?.boolValue == true {
            cell.lineNumberLabel.text = cell.lineNumberLabel.text! + ("e")
            let strTitle:NSString = cell.lineNumberLabel.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "e")
            let attributedString = NSMutableAttributedString(string: cell.lineNumberLabel.text!)
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14.0), range: tickRange)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            cell.lineNumberLabel.attributedText = attributedString
        }
        if line.isRedEyeLine == true {
            cell.redEyeImage.isHidden = false
        } else {
            cell.redEyeImage.isHidden = true
        }
        
        //Set Etopsres line
        cell.warningButton.alpha = 0.0
        
        
        //Setting the flag
        cell.userFlagIconView.backgroundColor = CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType(rawValue: Int(truncating: (line.userFlagType)!))!)
        if (CBUserFlagType.none) == (CBUserFlagType(rawValue: line.userFlagType as! Int)) {
            cell.userFlagIconView.alpha = 1.0
        } else {
            cell.userFlagIconView.alpha = 1.0
        }
        
        // Line values.
        let lineValuesKey: String = CBLineValuesMenuController.lineValuesKey(for:  self.bidPeriod!)
        let lineValuesToDisplay:NSMutableArray = NSMutableArray()
        if (UserDefaults.standard.object(forKey: lineValuesKey) != nil) {
            let arr = UserDefaults.standard.value(forKey: lineValuesKey) as! [Any]
            lineValuesToDisplay.addObjects(from: arr)
        }
        for i in 0..<lineValuesToDisplay.count {
            let tag: Int = LineValueViewTag + i * 10
            let valueType:NSInteger
            let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
            if let val = lineValuesToDisplay[i] as? NSNumber {
                valueType = NSInteger(truncating: val)
            } else if let val = lineValuesToDisplay[i] as? String {
                valueType = NSInteger(val)!
            } else {
                let val = lineValuesToDisplay[i] as! Int
                valueType = NSInteger(val)
            }
            if lineValueView != nil {
                CBLineValuesMenuController.setLineValueView(lineValueView!, with: line, forType: CBLineValueTypes(rawValue: valueType)!, bidPeriod: bidPeriod!)
            } else {
                print("lineValueView is nil - \(tag) - \(row) - \(CBLineValueTypes(rawValue: valueType)!)")
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
        
        // Set any unused lineValueViews to transparent
        for i in lineValuesToDisplay.count..<5 {
            let tag: Int = LineValueViewTag + i * 10
            let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
            lineValueView?.alpha = 0.0
        }
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

extension CBScratchPadVC: CBUserFlagTableControllerDelegate {
    func changeLineUserFlagTypeTo(flagType: CBUserFlagType, selectedLine: BILine?) {
        for line in self.lines {
            line.userFlagType = flagType.rawValue as NSNumber
        }
        try? self.bidPeriod?.managedObjectContext?.save()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    
}

