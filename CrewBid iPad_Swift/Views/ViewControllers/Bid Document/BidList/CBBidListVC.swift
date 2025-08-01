//
//  CBBIdListVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit
import CoreData

class CBBidListVC: BaseViewController, NSFetchedResultsControllerDelegate  {

    
    
    @IBOutlet weak var btnNormalView: UIButton!
    @IBOutlet weak var btnCalendarView: UIButton!
    @IBOutlet weak var btnExpandedView: UIButton!
    @IBOutlet weak var btnActions: UIButton!
    @IBOutlet weak var btnASort: UIButton!
    @IBOutlet weak var tableViewNormalView: UITableView!
    @IBOutlet weak var lblBidLineCount: UILabel!
    @IBOutlet weak var scrollToButton: UIButton!
    var linesFetchController:NSFetchedResultsController<BILine>!
    var sortsFetchController:NSFetchedResultsController<BILineSort>!
    var managedObjectContext:NSManagedObjectContext?
    var bidPeriod = BIBidPeriod()
    var bidListCalenderDays = [Any]()
    var bidListCalendarData = BICalendarData()
    var bidPeriod1: BIBidPeriod?
    var lineValuesKey = ""
    var lineValuesToDisplay = [AnyHashable]()
    var linesArray : [BILine] = []
    var selectedCellIndexPath = NSMutableArray()
    var awardEmpNumArray:NSMutableArray?
    var awardLineNum:String?
    //A-Sort
    var isAwardSort = false
    var isSubmitSort = false
    var insertionPoint:BIInsertionPoint?
    var modifiedIndexPaths:NSMutableSet?
    var selectedCellIndexPaths = NSMutableArray()
    var shouldShowCellMenuPopover: Bool?
    var calendarData:BICalendarData?
    var addedMarkerIndexPath:IndexPath?
    var previousInsertionIndex:Int?
    var shouldScrollToInsertionIndex:Bool?
    var userFaPosOrder:NSArray?
    
    var insertionIndex: Int {
        get {
            return insertionPoint!.index?.intValue ?? 0
        }
        set {
            insertionPoint!.index = NSNumber(value: newValue)
        }
    }
    var insertAbove: Bool {
        return insertionPoint!.above?.boolValue ?? false
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.standard.set(false, forKey: kCBNoAutoswitchToBids)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if self.managedObjectContext == nil {
            self.managedObjectContext = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
        }
        
        
        
        
//        NotificationCenter.default.addObserver(self, selector: #selector(sortBidAction), name: NSNotification.Name("SortBidListAction"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(refreshLines), name: NSNotification.Name("RefreshBidListCalander"), object: nil)
        
    }
    
    func setupVariables(){
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        self.managedObjectContext = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
        let insertionPointFetch = NSFetchRequest<BIInsertionPoint>(entityName: "InsertionPoint")
        insertionPointFetch.fetchLimit = 1
        do {
            let results = try self.managedObjectContext!.fetch(insertionPointFetch)
            if let existingPoint = results.first {
                insertionPoint = existingPoint
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "InsertionPoint", in: self.managedObjectContext!)!
                let newPoint = BIInsertionPoint(entity: entity, insertInto: self.managedObjectContext!)
                newPoint.index = 0
                newPoint.above = false
                insertionPoint = newPoint
            }
        } catch {
            print("Failed to fetch insertion point: \(error)")
        }
        
        let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bidOrder > 0")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]

        if self.bidPeriod.isBidListSortOn?.boolValue == true {
            fetchRequest.sortDescriptors = getSortDescriptorsForBidList()
        }

        let controller = NSFetchedResultsController( fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        do {
            try controller.performFetch()
            self.linesFetchController = controller
        } catch {
            print("Error executing lines fetch: \(error)")
        }
        updateBidList()
    }
    
    func setupUI(){
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        if bidPeriod.isSortBySubmitOn?.boolValue ?? false {
            self.isSubmitSort = true
            self.btnASort.backgroundColor = CBColor.cbGreenColor
        }
        bidListCalendarData = bidListCalendarData.initWithBidPeriod(bidPeriod: CBGlobalMethods.shared.selectedBidPeriod!)!
        bidListCalenderDays = bidListCalendarData.calendarDays as! [Any]
        self.bidPeriod1 = CBGlobalMethods.shared.selectedBidPeriod
        lineValuesKey = CBLineValuesMenuController.lineValuesKey(for: bidPeriod)
        lineValuesToDisplay = UserDefaults.standard.value(forKey: lineValuesKey) as! [AnyHashable]
        setupVariables()
        manageViewSelection()
        btnNormalView.layer.borderWidth = 1
        btnNormalView.layer.borderColor = UIColor.lightGray.cgColor
        btnCalendarView.layer.borderWidth = 1
        btnCalendarView.layer.borderColor = UIColor.lightGray.cgColor
        btnExpandedView.layer.borderWidth = 1
        btnExpandedView.layer.borderColor = UIColor.lightGray.cgColor
        btnASort.layer.cornerRadius = 5
        lblBidLineCount.isUserInteractionEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateBidList(_:)), name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.lineValuesToDisplayChanged(notification:)), name: Notification.Name(CBLineValuesToDisplayDidChangeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.cellDidSelect(notification:)), name: Notification.Name("CBBidLineTableCellDidSelectNotification"), object: nil)
        
        self.isSubmitSort = (self.bidPeriod.isSortBySubmitOn ?? 0).boolValue
        self.isAwardSort = (self.bidPeriod.isAwardSortOn ?? 0).boolValue
        if isAwardSort{
//            loadAwardDetails()
        }
    }
    func removeBidListObservers(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "refreshLines"), object: nil)
    }
    
    @objc func cellDidSelect(notification: Notification) {
        let dict = notification.object as! NSDictionary
        let object = dict["object"]
        print("selectedCellIndexPaths \(selectedCellIndexPaths)")
//        var buttonPosition = (selInt as! UIButton).convert(CGPoint.zero, to: tableViewNormalView)
//
//        let indexPath = tableViewNormalView.indexPathForRow(at:buttonPosition)
        let indexPath = dict["indexPath"] as? IndexPath
        if (object as! UITableViewCell).classForCoder.description() == "CrewBid_iPad.CBBidlineViewTableViewCell" {
            let cell = object as? CBBidlineViewTableViewCell
            if let aCell = cell {
                tableViewNormalView.selectRow(at: tableViewNormalView.indexPath(for: aCell), animated: false, scrollPosition: .none)
            }
          //  let indexPath: IndexPath? = tableViewNormalView.indexPath(for: cell!)
            let arr = selectedCellIndexPaths
            if !arr.contains(indexPath!) {
                selectedCellIndexPaths.add(indexPath!)
            }
        }
        else if (object as! UITableViewCell).classForCoder.description() == "CrewBid_iPad.CBBidListCalenderViewCell" {
            let cell = object as? CBBidListCalenderViewCell
            if let aCell = cell {
                tableViewNormalView.selectRow(at: tableViewNormalView.indexPath(for: aCell), animated: false, scrollPosition: .none)
            }
         //   let indexPath: IndexPath? = tableViewNormalView.indexPath(for: cell!)
            let arr = selectedCellIndexPaths
            if !arr.contains(indexPath!) {
                selectedCellIndexPaths.add(indexPath!)
            }
        }
        print("selectedCellIndexPaths \(selectedCellIndexPaths)")

    }
    
    @objc func lineValuesToDisplayChanged(notification: Notification) {
        if bidPeriod.isBidListSortOn!.boolValue {
            let lineSorts = getSortDescriptorsForBidList()
            self.linesArray = (linesArray as NSArray).sortedArray(using: lineSorts ) as! [BILine]
        }
        try? self.bidPeriod.managedObjectContext!.save()
        self.updateBidList()
        self.tableViewNormalView.reloadData()
    }
    
    @objc func refreshLines(){
//        self.loadBidLine()
        self.updateBidList()
//        self.tableViewNormalView.reloadData()
    }
    
    func loadBidLine(){
        if self.selectedCellIndexPath.count != 0 {
            self.selectedCellIndexPath.removeAllObjects()
        }
        
        let linesFetch = NSFetchRequest<BILine>(entityName: BILineEntityName)
        var userPosition = ""
        if bidPeriod.positionType?.intValue == 0 {
            userPosition = "CP"
        }
        if bidPeriod.positionType?.intValue == 1 {
            userPosition = "FO"
        }
        if bidPeriod.positionType?.intValue == 2{
            userPosition = "FA"
        }
        
        if self.isSubmitSort {
            let linesString = self.bidPeriod.submittedBid!
            if linesString.length == 0 {
//                self.getSubmitted()
                return
            }
            self.bidPeriod.isAwardSortOn = false
            self.bidPeriod.isSortBySubmitOn = true
            self.isAwardSort = false
            self.isSubmitSort = true
            
            var lines = linesString.components(separatedBy: ",")
            var linesArray: [[String: Any]] = []
            var submittedLineNumArray: [String] = []
            var submittedSequenceNumArray: [Int] = []
            
            for i in 0..<lines.count {
                var dict: [String:Any] = [:]
                let lineId = lines[i]
                let faPosition = lineId.substring(from: lineId.length - 1)
                let lineNumInt = Int(lines[i]) ?? 0
                let lineNumStr = "\(lineNumInt)"
                
                dict["LineNum"] = lineNumInt
                dict["SeqNum"] = i + 1
                dict["type"] = faPosition
                
                submittedLineNumArray.append(lineNumStr)
                submittedSequenceNumArray.append(i)
                
                linesArray.append(dict)
            }
            
            linesFetch.predicate = NSPredicate(format: "bidOrder > 0")
            linesFetch.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
            
            self.linesFetchController = NSFetchedResultsController(fetchRequest: linesFetch, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
            self.linesFetchController.delegate = self
            try? self.linesFetchController.performFetch()
            
            let array = self.linesFetchController.fetchedObjects! as NSArray
            
            if self.bidPeriod.faReserveLineExists!.boolValue || self.bidPeriod.faMrtLineExists!.boolValue {
                for i in 0..<self.linesFetchController.fetchedObjects!.count{
                    let line = self.linesFetchController.fetchedObjects![i]
                    let lineNumber = line.number!.stringValue
                    if lineNumber == "1000"{
                        if line.faBidLineReserve!.boolValue{
                            self.bidPeriod.reservedLineIndexForASort = NSNumber(value: i)
                            self.managedObjectContext?.delete(line)
                            self.bidPeriod.reserveEnabledForASort = NSNumber(value: 1)
                        }
                        if line.faBidLineMrt!.boolValue{
                            self.bidPeriod.mRTLineIndexForASort = NSNumber(value: i)
                            self.managedObjectContext?.delete(line)
                            self.bidPeriod.mRTEnabledForASort = NSNumber(value: 1)
                        }
                    }
                }
            }
            linesFetch.predicate = NSPredicate(format: "bidOrder > 0")
            linesFetch.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
            self.linesFetchController = NSFetchedResultsController(fetchRequest: linesFetch, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
            self.linesFetchController.delegate = self
            try? self.linesFetchController.performFetch()
            
            if linesArray.count >= self.linesFetchController.fetchedObjects!.count {
                let bidListArray = NSMutableArray()
                for i in 0..<self.linesFetchController.fetchedObjects!.count {
                    let line = self.linesFetchController.fetchedObjects![i]
                    var lineNumber = line.number!.stringValue
                    if userPosition == "FA"{
                        let faPosition = line.faPositionString
                        lineNumber = String(format: "%@%@", lineNumber,faPosition)
                    }
                    bidListArray.add(lineNumber)
                }
                var subLinesArray = lines
                subLinesArray.removeAll { bidListArray.contains($0) }
                lines.removeAll { subLinesArray.contains($0) }
                bidListArray.removeObjects(in: lines)
                lines.append(contentsOf: bidListArray as! [String])
                linesArray.removeAll()
                submittedLineNumArray.removeAll()
                submittedSequenceNumArray.removeAll()
                
                for i in 0..<lines.count {
                    var dict: [String:Any] = [:]
                    let lineId = lines[i]
                    let faPositon = lineId.substring(from: lineId.length - 1)
                    let lineNumInt = Int(lines[i]) ?? 0
                    let lineNumStr = "\(lineNumInt)"
                    
                    dict["LineNum"] = lineNumInt
                    dict["SeqNum"] = i + 1
                    dict["type"] = faPositon
                    
                    submittedLineNumArray.append(lineNumStr)
                    submittedSequenceNumArray.append(i)
                    
                    linesArray.append(dict)
                }
                
                for i in 0..<linesArray.count {
                    var submittedLineNumber = (linesArray[i]["LineNum"] as? NSNumber)?.stringValue
                    if userPosition == "FA"{
                        let submittedLineType = (linesArray[i]["type"] as? String) ?? ""
                        submittedLineNumber = String(format: "%@%@", submittedLineNumber!,submittedLineType)
                    }
                    let awardType = (linesArray[i]["type"] as? String) ?? ""
                    for j in 0..<self.linesFetchController.fetchedObjects!.count {
                        let line = self.linesFetchController.fetchedObjects![j] 
                        var lineNumber = line.number!.stringValue
                        if userPosition == "FA"{
                            let faPosition = line.faPositionString
                            lineNumber = String(format: "%@%@", lineNumber,faPosition)
                        }
                        if submittedLineNumber == lineNumber{
                            if userPosition == "FA" {
                                let faPosition = line.faPositionString
                                if awardType == faPosition{
                                    if line.previousBidOrder == 0 {
                                        line.previousBidOrder = line.bidOrder
                                    }
                                    line.bidOrder = linesArray[i]["SeqNum"] as? NSNumber
                                }
                            }else{
                                if line.previousBidOrder == 0 {
                                    line.previousBidOrder = line.bidOrder
                                }
                                line.bidOrder = linesArray[i]["SeqNum"] as? NSNumber
                            }
                        }
                    }
                }
            }else {
                let bidListArray = NSMutableArray()
                for i in 0..<self.linesFetchController.fetchedObjects!.count {
                    let line = self.linesFetchController.fetchedObjects![i]
                    var lineNumber = line.number!.stringValue
                    if userPosition == "FA"{
                        let faPosition = line.faPositionString
                        lineNumber = String(format: "%@%@", lineNumber,faPosition)
                    }
                    bidListArray.add(lineNumber)
                }
                bidListArray.removeObjects(in: lines)
                lines.append(contentsOf: bidListArray as! [String])
                linesArray.removeAll()
                submittedLineNumArray.removeAll()
                submittedSequenceNumArray.removeAll()
                
                for i in 0..<lines.count{
                    var dict: [String:Any] = [:]
                    let lineId = lines[i]
                    let faPositon = lineId.substring(from: lineId.length - 1)
                    let lineNumInt = Int(lines[i]) ?? 0
                    let lineNumStr = "\(lineNumInt)"
                    
                    dict["LineNum"] = lineNumInt
                    dict["SeqNum"] = i + 1
                    dict["type"] = faPositon
                    
                    submittedLineNumArray.append(lineNumStr)
                    submittedSequenceNumArray.append(i)
                    
                    linesArray.append(dict)
                }
                
                for i in 0..<linesArray.count{
                    let submittedLineNumber = (linesArray[i]["LineNum"] as? NSNumber)?.stringValue
                    let awardType = (linesArray[i]["type"] as? String) ?? ""
                    for j in 0..<self.linesFetchController.fetchedObjects!.count{
                        let line = self.linesFetchController.fetchedObjects![j]
                        let lineNumber = line.number!.stringValue
                        if submittedLineNumber == lineNumber {
                            if userPosition == "FA" {
                                let faPosition = line.faPositionString
                                if awardType == faPosition {
                                    if line.previousBidOrder == 0 {
                                        line.previousBidOrder = line.bidOrder
                                    }
                                    line.bidOrder = linesArray[i]["SeqNum"] as? NSNumber
                                }
                            }else{
                                if line.previousBidOrder == 0 {
                                    line.previousBidOrder = line.bidOrder
                                }
                                line.bidOrder = linesArray[i]["SeqNum"] as? NSNumber
                            }
                        }
                    }
                }
            }
        }
        else if self.isAwardSort{
            let array = Array(self.bidPeriod.awardDetails ?? [])
            let awardSequencNumArray = NSMutableArray()
            self.awardEmpNumArray = NSMutableArray()
            let bidUserId = self.bidPeriod.crewIdentifier?.stringValue
            
            for case let obj as AwardDetails in array {
                let awardLineNumber = String(obj.lineNum)
                let awardEmpNum = obj.empNum
                let seqNum = obj.seqNumber
                awardSequencNumArray.add(seqNum)
                if awardEmpNum == bidUserId {
                    self.awardLineNum = awardLineNumber
                    if self.bidPeriod.isFABid() {
                        awardLineNum = String(format: "%@%@", awardLineNumber, obj.type!)
                    }
                }else{
                    
                }
            }
            let array2 = try? managedObjectContext?.fetch(linesFetch)
            
            if self.bidPeriod.faReserveLineExists!.boolValue || self.bidPeriod.faMrtLineExists!.boolValue {
                for i in 0..<self.linesFetchController.fetchedObjects!.count {
                    let line = self.linesFetchController.fetchedObjects![i]
                    let lineNumber = line.number?.stringValue
                    if lineNumber == "1000" {
                        if line.faBidLineReserve!.boolValue{
                            self.bidPeriod.reservedLineIndexForASort = NSNumber(value: i)
                            self.managedObjectContext?.delete(line)
                            self.bidPeriod.reserveEnabledForASort = NSNumber(value: 1)
                        }
                        if line.faBidLineMrt!.boolValue{
                            self.bidPeriod.mRTLineIndexForASort = NSNumber(value: i)
                            self.managedObjectContext?.delete(line)
                            self.bidPeriod.mRTEnabledForASort = NSNumber(value: 1)
                        }
                    }
                }
            }
            linesFetch.predicate = NSPredicate(format: "bidOrder > 0")
            linesFetch.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
            self.linesFetchController = NSFetchedResultsController(fetchRequest: linesFetch, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
            self.linesFetchController.delegate = self
            do{
                try linesFetchController.performFetch()
            }catch{
                print("Error: \(error.localizedDescription)")
            }
            let array3 = self.linesFetchController.fetchedObjects
            var extraLinesFetch = NSFetchedResultsController<NSFetchRequestResult>()
            let bidListLineNumArray = NSMutableArray()
            let awardLineNumArray = NSMutableArray()
            
            for i in 0..<array.count {
                let awardDetails = array[i] as! AwardDetails
                var awardLineNumber = String(awardDetails.lineNum)
                if userPosition == "FA" && self.bidPeriod.isFirstRoundBid() {
                    let awardLineType = awardDetails.type
                    awardLineNumber = String(format: "%@%@", awardLineNumber, awardLineType!)
                }
                awardLineNumArray.add(awardLineNumber)
            }
            
            let nonDuplicateAwards = NSMutableArray()
            let checkArray = NSMutableArray()
            for case let award as AwardDetails in array{
                if userPosition == "FA" && self.bidPeriod.isFirstRoundBid() {
                    let lineNum = String(format: "%@%@", award.lineNum, award.type!)
                    if checkArray.contains(lineNum) {
                        continue
                    }
                    checkArray.add(lineNum)
                    nonDuplicateAwards.add(award)
                }else{
                    let lineNum = String(award.lineNum)
                    if checkArray.contains(lineNum){
                        continue
                    }
                    checkArray.add(lineNum)
                    nonDuplicateAwards.add(award)
                }
            }
            
            let orderedSet = NSOrderedSet(array: awardLineNumArray as! [Any])
            let awardLineNumArrayNonDuplicate = orderedSet.array
            
            for j in 0..<self.linesFetchController.fetchedObjects!.count {
                let line = self.linesFetchController.fetchedObjects![j]
                var lineNumber = line.number?.stringValue
                if userPosition == "FA" && self.bidPeriod.isFirstRoundBid() {
                    let awardLineType = line.faPositionString
                    lineNumber = String(format: "%@%@", lineNumber!, awardLineType)
                }
                bidListLineNumArray.add(lineNumber!)
            }
            let extraLinesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: BILineEntityName)
            bidListLineNumArray.removeObjects(in: awardLineNumArrayNonDuplicate)
            let bidListLineNumArrayInt = bidListLineNumArray.compactMap { ($0 as? NSNumber)?.intValue }
            if userPosition == "FA" && self.bidPeriod.isFirstRoundBid(){
                let pred1 = NSPredicate(format: "bidOrder > 0")
                let pred2 = NSPredicate(format: "faNumber IN %@", bidListLineNumArrayInt)
                let subPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
                extraLinesFetchRequest.predicate = subPredicate
            }else{
                extraLinesFetchRequest.predicate = NSPredicate(format: "(bidOrder > 0) AND (number IN %@)", bidListLineNumArrayInt)
            }
            extraLinesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
            extraLinesFetch = NSFetchedResultsController(fetchRequest: extraLinesFetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
            extraLinesFetch.delegate = self
            do {
                try extraLinesFetch.performFetch()
            }catch{
                print("Error: \(error.localizedDescription)")
            }
            let array4 = extraLinesFetch.fetchedObjects
            var greatestSeqNum = 0
            for i in 0..<nonDuplicateAwards.count{
                let award = nonDuplicateAwards[i] as! AwardDetails
                let awardLineNumber = String(award.lineNum)
                let awardType = award.type
                let seqNum = award.seqNumber
                for j in 0..<self.linesFetchController.fetchedObjects!.count{
                    let line = self.linesFetchController.fetchedObjects![j]
                    let lineNumber = line.number?.stringValue
                    if lineNumber == awardLineNumber{
                        if userPosition == "FA" {
                            var faPosition = line.faPositionString
                            if awardType == "" {
                                faPosition = ""
                            }
                            if awardType == faPosition{
                                line.previousBidOrder = line.bidOrder
                                line.bidOrder = seqNum as NSNumber
                                if Int(seqNum) > greatestSeqNum {
                                    greatestSeqNum = Int(seqNum)
                                }
                            }
                        }else{
                            line.previousBidOrder = line.bidOrder
                            line.bidOrder = seqNum as NSNumber
                        }
                    }
                }
            }
            for k in 0..<extraLinesFetch.fetchedObjects!.count{
                let extraLine = extraLinesFetch.fetchedObjects![k] as! BILine
                extraLine.previousBidOrder = extraLine.bidOrder
                extraLine.bidOrder = (greatestSeqNum + k) as NSNumber
            }
            linesFetch.predicate = NSPredicate(format: "bidOrder > 0")
            linesFetch.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
            self.linesFetchController = NSFetchedResultsController(fetchRequest: linesFetch, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
            do {
                try self.linesFetchController.performFetch()
            }catch{
                print("Error fetching lines: \(error.localizedDescription)")
            }
        }else{
            let linesFetch = NSFetchRequest<BILine>(entityName: BILineEntityName)
            linesFetch.predicate = NSPredicate(format: "bidOrder > 0")
            linesFetch.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
            
            if self.bidPeriod.isBidListSortOn?.boolValue == true {
                let lineSorts = self.getSortDescriptorsForBidList()
                linesFetch.sortDescriptors = lineSorts
            }
            self.linesFetchController = NSFetchedResultsController(fetchRequest: linesFetch, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
            self.linesFetchController.delegate = self
            do{
                try self.linesFetchController.performFetch()
            }catch{
                print("Error fetching lines: \(error.localizedDescription)")
            }
            
            if self.bidPeriod.reserveEnabledForASort?.boolValue == true {
                let reserveIndexPath = IndexPath(row: self.bidPeriod.reservedLineIndexForASort!.intValue, section: 0)
                self.bidPeriod.reserveEnabledForASort = NSNumber(value: 0)
                self.bidPeriod.faReserveLineExists = NSNumber(value: 1)
//                self.addFaReserveBidLine
            }
            if self.bidPeriod.mRTEnabledForASort?.boolValue == true {
                let reserveIndexPath = IndexPath(row: self.bidPeriod.mRTLineIndexForASort!.intValue, section: 0)
                self.bidPeriod.mRTEnabledForASort = NSNumber(value: 0)
                self.bidPeriod.faMrtLineExists = NSNumber(value: 1)
//                self.addFaMRTBiddLine
            }
            // for keeping the bid order same as bid list sorted order
            var i = 0
            for line in self.linesFetchController.fetchedObjects! {
                i = i + 1
                line.bidOrder = NSNumber(value: i)
                line.previousBidOrder = NSNumber(value: i)
            }
        }
//        appdelegate.dicCurrentBidDetails set object "" forkey "ASortTurning"
        
        
        
    }
    
    @objc func sortBidAction(_ notification: Notification){
        if self.managedObjectContext == nil{
            self.managedObjectContext = AppState.shared.currentBidPeriod?.managedObjectContext
        }
        let insertionPointFetch = NSFetchRequest<BIInsertionPoint>(entityName: "InsertionPoint")
        insertionPointFetch.fetchLimit = 1
        
        let results = try? self.managedObjectContext!.fetch(insertionPointFetch)
        if results == nil {
            return
        }
        if results?.count != nil{
            insertionPoint = results?.first
        }else{
            insertionPoint = BIInsertionPoint(context: self.managedObjectContext!)
        }
        self.modifiedIndexPaths = NSMutableSet()
        self.selectedCellIndexPath = NSMutableArray()
        self.tableViewNormalView.isEditing = true
        self.tableViewNormalView.allowsMultipleSelection = false
        self.shouldShowCellMenuPopover = true
        self.navigationController?.navigationBar.backgroundColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1)
        self.createTabsForViewTypeChange()
        self.tableViewMoveDown()
        self.updateTitle()
        let dict = notification.userInfo as! [String: Any]
        let calendarData = dict["calendarData"] as? BICalendarData
        if calendarData != nil {
            self.calendarData = calendarData
        }
        self.tableViewNormalView.reloadData()
    }
    
    func createTabsForViewTypeChange(){
        
    }
    func tableViewMoveDown(){
        
    }
    func updateTitle(){
        
    }
    
    @objc func moveSelectedLinesToInsertionIndex() {
        // Move selected lines to the insertion index

        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        var selectedIndexPaths = NSMutableArray()
        selectedIndexPaths = selectedCellIndexPaths
        if selectedIndexPaths.count == 0 {
            return
        }
        let firstSelectedIndex = selectedIndexPaths[0] as? IndexPath
        let lastSelectedIndex: IndexPath? = selectedIndexPaths.lastObject as? IndexPath
        var firstRow: Int = firstSelectedIndex!.row
        var lastRow: Int? = lastSelectedIndex?.row
        // Determine the range of selected rows

        for case let ip as IndexPath in selectedIndexPaths {
            if ip.row < firstRow {
                firstRow = ip.row
            }
            if ip.row > lastRow! {
                lastRow = ip.row
            }
        }
        
        var affectedRows = self.linesArray as [Any]
        (affectedRows as NSArray).sortedArray(using: [NSSortDescriptor(key: "bidOrder", ascending: true)])
        var movedLines = [AnyHashable]() /* TODO: .reserveCapacity(selectedIndexPaths.count) */
        let removedIndexes = NSMutableIndexSet()
        var insertionIndex: Int = self.insertAbove ? self.insertionIndex : self.insertionIndex + 1
        let countOfBidLines: Int = self.linesArray.count
        // Loop through the selected lines

        for case let indexPath as IndexPath in selectedIndexPaths {
            let row: Int = indexPath.row
            let line: BILine? = affectedRows[row] as? BILine
            if let aLine = line {
                movedLines.append(aLine)
            }
            removedIndexes.add(row)
            // Attempt to preserve marker by moving it to line below (if one
            // exists below line and that line does not have a marker).
            if ((line?.markerTitle) != nil) && row < countOfBidLines - 1 {
                let nextLine: BILine? = affectedRows[row + 1] as? BILine
                if nil == nextLine?.markerTitle {
                    nextLine?.markerTitle = line?.markerTitle
                }
            }
            line?.markerTitle = nil
            // If inserting above a line that has a marker, transfer marker to
            // moved line.
            if insertAbove {
                let insertionPointLine: BILine? = affectedRows[insertionIndex] as? BILine
                if insertionPointLine?.markerTitle != nil {
                    line?.markerTitle = insertionPointLine?.markerTitle
                    insertionPointLine?.markerTitle = nil
                }
            }
            if insertionIndex >= 0 && insertionIndex < linesArray.count {
                let endLine = linesArray[insertionIndex]
                if (endLine.isFrozen != 0) {
                    line!.isFrozen = true
                }
            } else {
               print("Sorry")
            }
            
        }
        
        for deletionIndex in removedIndexes.reversed() { affectedRows.remove(at: deletionIndex) }
        let countOfLinesRemovedBelowInsertionIndex: Int = removedIndexes.countOfIndexes(in: NSRange(location: 0, length: insertionIndex))
        insertionIndex -= countOfLinesRemovedBelowInsertionIndex
        let insertedIndexes = NSIndexSet(indexesIn: NSRange(location: insertionIndex, length: selectedIndexPaths.count))
        for (objectIndex, insertionIndex) in insertedIndexes.enumerated() { affectedRows.insert((movedLines)[objectIndex], at: insertionIndex) }
        if self.insertionIndex < firstRow {
            firstRow = self.insertionIndex
        }
        if lastRow! < insertionIndex + selectedIndexPaths.count - 1 {
            lastRow = insertionIndex + selectedIndexPaths.count - 1
        }
        // Renumber the lines
        for i in firstRow...lastRow! {
            let line: BILine? = affectedRows[i] as? BILine
            line?.bidOrder = i + 1 as NSNumber
        }
        previousInsertionIndex = insertionIndex
        self.insertionIndex = self.insertionIndex + selectedIndexPaths.count - countOfLinesRemovedBelowInsertionIndex
        insertedIndexes.enumerate({(_ idx: Int, _ stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            let idxPth = IndexPath(row: idx, section: 0)
            tableViewNormalView.selectRow(at: idxPth, animated: false, scrollPosition: .none)
        })
        selectedCellIndexPaths.removeAllObjects()
        // Set undo action name.
        bidPeriod.managedObjectContext?.undoManager?.setActionName("Move Selected Line\(selectedIndexPaths.count > 1 ? "s" : "")")
        UserDefaults.standard.setValue(true, forKey: "isShouldScrollToInsertionIndex")
        self.updateBidList()
    }
    
    
    @objc func updateBidList(_ notification: Notification? = nil) {
        var isTableviewReload = true
        var notifictionFromTripTextView = false
        
        if let notification = notification {
            if notification.object is CBTripTextViewController {
                isTableviewReload = true
                notifictionFromTripTextView = true
            }
        }
        self.linesArray.removeAll()
        
        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
            linesArray.append(line)
        }
        
        var array : [NSPredicate] = []
        array.append(NSPredicate(format: "bidOrder > %@", NSNumber(integerLiteral: 0)))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        self.linesArray = (linesArray as NSArray).filtered(using: predicate) as! [BILine]
        
        let sort = NSSortDescriptor(key: "bidOrder", ascending: true)
        if bidPeriod.isBidListSortOn?.boolValue ?? false{
            let lineSorts = getSortDescriptorsForBidList()
            print(lineSorts)
            self.linesArray = (linesArray as NSArray).sortedArray(using: lineSorts ) as! [BILine]
            var tmp : Int = 0
            for case let line in  self.linesArray {
                tmp = tmp + 1
                line.bidOrder = NSNumber(integerLiteral: tmp)
                line.previousBidOrder = NSNumber(integerLiteral: tmp)
            }
            try? bidPeriod.managedObjectContext?.save()
        }
        else{
            self.linesArray = (linesArray as NSArray).sortedArray(using: [sort]) as! [BILine]
        }
        if isSubmitSort {
            self.linesArray = (linesArray as NSArray).sortedArray(using: [NSSortDescriptor(key: "submitSortOrder", ascending: true)]) as! [BILine]
        }
        DispatchQueue.main.async {
            if self.bidPeriod.isBidListSortOn?.boolValue ?? false{
                if  self.bidPeriod.getOrderedBidListSorts().count > 0{
                    self.bidPeriod.isSortBySubmitOn = false
                    self.bidPeriod.isAwardSortOn = false
                }
            }
            self.isSubmitSort = (self.bidPeriod.isSortBySubmitOn ?? 0).boolValue
            self.isAwardSort = (self.bidPeriod.isAwardSortOn ?? 0).boolValue
            
            if self.btnASort != nil {
                if self.isAwardSort || self.isSubmitSort{
                    self.btnASort.backgroundColor = CBColor.cbGreenColor
                }else{
                    self.btnASort.backgroundColor = CBColor.cbOrangeColor
                }
            }
            
            if self.tableViewNormalView != nil {
                let totalLines = CBGlobalMethods.shared.selectedBidPeriod!.lines!
                let allLines = self.linesArray
                let bidListTotal: Int = (allLines.count)
                let etopsCount = ((self.linesArray) as NSArray).value(forKey: "isETOPS")
                let etopsReserveCount = ((self.linesArray) as NSArray).value(forKey: "isETOPSRES")
                let etopsCountNumber = NSCountedSet(array: etopsCount as! [Any])
                let etopsReserveCountNumber = NSCountedSet(array: etopsReserveCount as! [Any])
                var title = "\(totalLines.count) Lines - Bid List - \(bidListTotal)"
                if (etopsCountNumber.count(for: 1) != 0) || (etopsReserveCountNumber.count(for: 1) != 0) {
                    let eCount = etopsCountNumber.count(for: 1) + etopsReserveCountNumber.count(for: 1)
                    title = "\(totalLines.count) Lines - Bid List - \(bidListTotal) - \(eCount) ETOPS"
                }
                //modified the code given below on 18/01/2024 by Kripa to fix a crash
                if let seniority: Int = self.bidPeriod.seniorityNumber as? Int{
                    let seniorityNumberString : String = String(seniority)
                    if self.bidPeriod.seniorityNumber != 0 {
                        let isEffSenSelected = UserDefaults.standard.bool(forKey: "IsEffSenSelected")
                        if isEffSenSelected {
                            let paperBidCount = self.bidPeriod.paperBidCount?.intValue ?? 0
                            let paperCountAvoidedSeniorityListPosition = seniority - paperBidCount
                            title.append(" - EffSen #\(paperCountAvoidedSeniorityListPosition)")
                        } else{
                            title += " - Sen #\(seniorityNumberString)"
                        }
                    }
                }
                self.lblBidLineCount.text = title
                
                // This condition added by Raja on 03/01/2024
                // to fix the Trip data UI issue in Normal bid list view when tap Herb / Local time button.
                if isTableviewReload{
                    if UserDefaults.standard.bool(forKey: "isSelectedCalanderView") {
                        self.tableViewNormalView.reloadData()
                        self.scrollToInsertionIndex()
                    } else {
                        if notifictionFromTripTextView == false {
                            self.tableViewNormalView.reloadData()
                            self.scrollToInsertionIndex()
                        }
                    }
                }
              
                try? self.bidPeriod.managedObjectContext?.save()
            }
            
        }
    }
    
    @objc func scrollToInsertionIndex() {
        if UserDefaults.standard.value(forKey: "isShouldScrollToInsertionIndex") != nil {
            if UserDefaults.standard.bool(forKey: "isShouldScrollToInsertionIndex") {
                let insertionBarIndexPath = IndexPath(row: self.insertionIndex, section: 0)
                if insertionBarIndexPath.row < self.tableViewNormalView.numberOfRows(inSection: 0) {
                    self.tableViewNormalView.scrollToRow(at: insertionBarIndexPath, at: .middle, animated: true)
                }
                UserDefaults.standard.setValue(false, forKey: "isShouldScrollToInsertionIndex")
            }
        }
    }
    

    
    
    func insertLines(_ lines: [BILine], faBidAllPositions: Bool) {
//        removeASortUI()
        guard !lines.isEmpty else { return }

        var insertingDirectlyBelowMarker = false
        var insertionRowLine: BILine?
        if insertionIndex < linesFetchController.fetchedObjects?.count ?? 0 {
            insertionRowLine = linesFetchController.object(at: IndexPath(row: insertionIndex, section: 0))
            insertingDirectlyBelowMarker = insertAbove && insertionRowLine?.markerTitle != nil
        }

        if insertingDirectlyBelowMarker, let insertionRowLine = insertionRowLine {
            lines[0].markerTitle = insertionRowLine.markerTitle
            insertionRowLine.markerTitle = nil
        } else if lines.count > 1 && !faBidAllPositions {
            if let lastInsertedLine = lines.last {
                var markerTitle = CBPresetsTVC.selectedPresetName(bidPeriod: bidPeriod) ?? ""
                if !markerTitle.isEmpty { markerTitle += ": " }
                markerTitle += markerTitleForMultipleInsert()
                lastInsertedLine.markerTitle = markerTitle
                let markerIndex = insertAbove ? insertionIndex + lines.count - 1 : insertionIndex + lines.count
                addedMarkerIndexPath = IndexPath(row: markerIndex, section: 0)
            }
        }

        var bidOrder = insertAbove ? insertionIndex + 1 : insertionIndex + 2
        var row = insertAbove ? insertionIndex : insertionIndex + 1

        let linesFetch: NSFetchRequest<BILine> = BILine.fetchRequest()
        linesFetch.predicate = NSPredicate(format: "bidOrder > 0")
        
        if bidPeriod.isBidListSortOn?.boolValue == true {
            linesFetch.sortDescriptors = getSortDescriptorsForBidList()
        } else {
            linesFetch.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
        }

        linesFetchController = NSFetchedResultsController(fetchRequest: linesFetch, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        linesFetchController.delegate = self

        do {
            try linesFetchController.performFetch()
        } catch {
            print("Error executing lines fetch: \(error)")
        }

        let countOfBidLines = linesFetchController.fetchedObjects?.count ?? 0
        let bidOrderOffset = lines.count
        previousInsertionIndex = insertionIndex
        insertionIndex += lines.count

        if countOfBidLines == 0 {
            bidOrder = 1
            row = countOfBidLines
            insertionIndex = lines.count - 1
        }

        for line in lines {
            line.bidOrder = NSNumber(value: bidOrder)
            bidOrder += 1

            for trip in line.trips ?? [] {
                if let trip = trip as? BITrip, trip.highlightCount?.intValue ?? 0 > 0 {
                    trip.bidListHighlighted = true
                }
            }
        }

        while row < countOfBidLines {
            let ip = IndexPath(row: row, section: 0)
            let ln = linesFetchController.object(at: ip)
            ln.bidOrder = NSNumber(value: row + bidOrderOffset + 1)
            row += 1
        }

        shouldScrollToInsertionIndex = true
        undoManager?.setActionName("Insert Line\(lines.count > 1 ? "s" : "")")

        selectedCellIndexPaths.removeAllObjects()
//        self.tableViewNormalView.delegate = self
        refreshLines()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("updateBidListCount"), object: nil)
    }
    
    func getSortDescriptorsForBidList() -> [NSSortDescriptor] {
        guard let moc = bidPeriod.managedObjectContext else { return [] }
        
        var lineSorts: [NSSortDescriptor] = []
        var userPosOrder: [NSNumber] = []
        var addedLineNumSort = false
        let standardPosOrder: [NSNumber] = [0, 1, 2, 3]  // A, B, C, D positions
        
        // --- Fetch BILineSort objects
        let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "isBidListSort == %@", NSNumber(value: true))
        
        let sortsFetchController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: moc,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        sortsFetchController.delegate = self
        self.sortsFetchController = sortsFetchController
        
        do {
            try sortsFetchController.performFetch()
        } catch {
            print("Sorts fetch failed: \(error)")
            return []
        }
        
        let fetchedSorts = sortsFetchController.fetchedObjects ?? []
        
        // --- Fetch frozen lines
        let frozenLinesRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        frozenLinesRequest.predicate = NSPredicate(format: "isFrozen == %@", NSNumber(value: true))
        frozenLinesRequest.sortDescriptors = [NSSortDescriptor(key: "isFrozen", ascending: false)]
        
        do {
            let frozenLines = try moc.fetch(frozenLinesRequest)
            if !frozenLines.isEmpty {
                lineSorts.append(NSSortDescriptor(key: "isFrozen", ascending: false))
                lineSorts.append(NSSortDescriptor(key: "frozenOrder", ascending: true))
            }
        } catch {
            print("Error executing lines fetch: \(error)")
        }
        
        // --- Create expression descriptor for "number"
        let numberExpression = NSExpression(forKeyPath: "number")
        let numberExpDescription = NSExpressionDescription()
        numberExpDescription.name = "number"
        numberExpDescription.expression = numberExpression
        numberExpDescription.expressionResultType = .integer16AttributeType
        
        // --- Build lineSorts from fetched sort descriptors
        for lineSort in fetchedSorts {
            guard let keyPath = lineSort.keyPath, !keyPath.isEmpty else { continue }
            
            if lineSort.category?.intValue == BILineSortCategory.BIPositionsLineSortCategory.rawValue {
                if !addedLineNumSort {
                    // Insert the line number sort first
                    lineSorts.append(NSSortDescriptor(key: numberExpDescription.name, ascending: true))
                    addedLineNumSort = true
                }
                if let type = lineSort.type {
                    userPosOrder.append(type)
                }
            }
            
            lineSorts.append(NSSortDescriptor(key: keyPath, ascending: lineSort.ascending?.boolValue ?? true))
        }
        
        // Fill in missing standard positions
        let remaining = standardPosOrder.filter { !userPosOrder.contains($0) }
        userPosOrder.append(contentsOf: remaining)
        self.userFaPosOrder = userPosOrder as NSArray
        
        // Fallback sort descriptors
        if fetchedSorts.isEmpty {
            lineSorts.append(NSSortDescriptor(key: "bidOrder", ascending: true))
        } else {
            lineSorts.append(NSSortDescriptor(key: numberExpDescription.name, ascending: true))
            
            if bidPeriod.isFABid() {
                lineSorts.append(NSSortDescriptor(key: "faPosition", ascending: true))
            }
        }
        
        return lineSorts
    }
    
    func markerTitleForMultipleInsert() -> String {
        guard let context = bidPeriod.managedObjectContext else {
            print("No managed object context available.")
            return ""
        }

        let markerText = NSMutableString()

        // MARK: - Fetch Filter Rules
        let filterFetch: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        filterFetch.sortDescriptors = [
            NSSortDescriptor(key: "category", ascending: true),
            NSSortDescriptor(key: "type", ascending: true)
        ]

        do {
            let filters = try context.fetch(filterFetch)

            for rule in filters {
                switch rule.category?.intValue {
                case BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue:
                    if let variables = rule.variables?["SET"] as? Set<Int> {
                        if variables.contains(BILineType.HardLine.rawValue) { markerText.append("H") }
                        if variables.contains(BILineType.ReserveLine.rawValue) { markerText.append("R") }
                        if variables.contains(BILineType.BlankLine.rawValue) { markerText.append("B") }
                        if bidPeriod.isFABid() == true && variables.contains(BILineType.MixedLine.rawValue) {
                            markerText.append("M")
                        }
                    }
                    markerText.append(" | ")

                case BIFilterRuleCategory.BIAmPmFilterRuleCategory.rawValue:
                    if let variables = rule.variables?["SET"] as? Set<Int> {
                        if variables.contains(BILineAMPM.AMLine.rawValue) { markerText.append("A") }
                        if variables.contains(BILineAMPM.PMLine.rawValue) { markerText.append("P") }
                        if bidPeriod.isFABid() == true && variables.contains(BILineAMPM.MixedAMPMLine.rawValue) {
                            markerText.append("Mx")
                        }
                    }
                    markerText.append(" | ")

                case BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue:
                    if let variables = rule.variables?["SET"] as? Set<Int> {
                        if variables.contains(BIFaReserveLineType.JnrAMres.rawValue) || variables.contains(BIFaReserveLineType.SnrAMres.rawValue) {
                            markerText.append("A")
                        }
                        if variables.contains(BIFaReserveLineType.JnrPMres.rawValue) || variables.contains(BIFaReserveLineType.SnrPMres.rawValue) {
                            markerText.append("P")
                        }
                        if bidPeriod.isFABid() == true && variables.contains(BIFaReserveLineType.JnrLateRes.rawValue) {
                            markerText.append("R")
                        }
                    }
                    markerText.append(" | ")

                case BIFilterRuleCategory.BIDaysOfWeekFilterRuleCategory.rawValue:
                    if rule.type?.intValue == BIWeekdaysFilterRuleType.BIWeekdaysCompoundType.rawValue,
                       let weekdayBits = rule.variables?["WEEKDAY_BITS"] as? UInt {
                        let days = ["S", "M", "T", "W", "Th", "F", "Sa"]
                        for i in 0..<7 {
                            if weekdayBits & (1 << i) == 0 {
                                markerText.append("\(days[i])")
                            }
                        }
                    } else {
                        let abbr = rule.abbreviation
                        let op = rule.predicateOperatorString
                        let val = rule.variables?[BIFilterRuleValueVariablesKey]
                        markerText.append("\(String(describing: abbr)) \(String(describing: op)) \(String(describing: val))")
                    }
                    markerText.append(" | ")

                case BIFilterRuleCategory.BITripLengthFilterRuleCategory.rawValue:
                    if rule.type?.intValue == BIWeekdaysFilterRuleType.BIWeekdaysCompoundType.rawValue,
                       let vars = rule.variables {
                        if (vars["TURNS_ON"] as? Bool) == true { markerText.append("T") }
                        if (vars["TWO_DAYS_ON"] as? Bool) == true { markerText.append("2") }
                        if (vars["THREE_DAYS_ON"] as? Bool) == true { markerText.append("3") }
                        if bidPeriod.isFABid() == false, (vars["FOUR_DAYS_ON"] as? Bool) == true {
                            markerText.append("4")
                        }
                        markerText.append(" | ")
                    } else{
                        let abbr = rule.abbreviation
                        let op = rule.predicateOperatorString
                        let val = rule.variables?[BIFilterRuleValueVariablesKey]
                        markerText.append("\(String(describing: abbr)) \(String(describing: op)) \(String(describing: val)) | ")
                    }

                case BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue:
                    if let city = rule.variables?[BIFilterRuleCityVariablesKey] as? String,
                       !city.isEmpty,
                       let abbr = rule.abbreviation{
                       let op = rule.predicateOperatorString
                       let val = rule.variables?[BIFilterRuleValueVariablesKey]
                        markerText.append("\(abbr) \(city) \(String(describing: op)) \(String(describing: val)) | ")
                    }

                case BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue:
                    if rule.type?.intValue != BIDeadheadsFilterRuleType.BIDeadheadsType.rawValue,
                       let city = rule.variables?[BIFilterRuleCityVariablesKey] as? String,
                       !city.isEmpty,
                       let abbr = rule.abbreviation{
                       let op = rule.predicateOperatorString
                       let val = rule.variables?[BIFilterRuleValueVariablesKey]
                        markerText.append("\(abbr) \(city) \(String(describing: op)) \(String(describing: val)) | ")
                    } else if let abbr = rule.abbreviation{
                              let op = rule.predicateOperatorString
                              let val = rule.variables?[BIFilterRuleValueVariablesKey]
                        markerText.append("\(abbr) \(String(describing: op)) \(String(describing: val)) | ")
                    }

                case BIFilterRuleCategory.BICommutingFilterRuleCategory.rawValue,
                    BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue:
                    if let abbr = rule.abbreviation {
                        markerText.append("\(abbr) | ")
                    }

                case BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue:
                    if let variables = rule.variables?["SET"] as? Set<Int> {
                        if variables.contains(BIFaPosition.FaPositionA.rawValue) { markerText.append("A") }
                        if variables.contains(BIFaPosition.FaPositionB.rawValue) { markerText.append("B") }
                        if variables.contains(BIFaPosition.FaPositionC.rawValue) { markerText.append("C") }
                        if variables.contains(BIFaPosition.FaPositionD.rawValue) { markerText.append("D") }
                        if bidPeriod.isSecondRoundBid() == true, variables.contains(BIFaPosition.FaPositionMultiple.rawValue) {
                            markerText.append("M")
                        }
                    }
                    markerText.append(" | ")

                case BIFilterRuleCategory.BIDaysOfMonthFilterRuleCategory.rawValue:
                    break // Not currently handled

                default:
                    let abbr = rule.abbreviation
                    let op = rule.predicateOperatorString
                    let val = rule.variables?[BIFilterRuleValueVariablesKey]
                    markerText.append("\(String(describing: abbr)) \(String(describing: op)) \(String(describing: val)) | ")
                }
            }
        } catch {
            print("Failed to fetch filter rules: \(error)")
        }

        // MARK: - Fetch Sort Rules
        let sortFetch: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        sortFetch.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        do {
            let sorts = try context.fetch(sortFetch)
            if !sorts.isEmpty {
                markerText.append(" Sorts:")
            }

            for sort in sorts {
                let direction = sort.ascending?.boolValue == true ? "L2H" : "H2L"

                switch sort.category?.intValue {
                case BILineSortCategory.BIStandardSortCategory.rawValue:
                    if let abbr = sort.abbreviation {
                        markerText.append("\(abbr)-\(direction) | ")
                    }

                case BILineSortCategory.BICitiesLineSortCategory.rawValue:
                    if let city = sort.city, !city.isEmpty,
                       let abbr = sort.abbreviation {
                        markerText.append("\(abbr) \(city)-\(direction) | ")
                    }

                case BILineSortCategory.BIDeadheadsLineSortCategory.rawValue:
                    if sort.type?.intValue != BIDeadheadLineSortType.BIDeadheadSortType.rawValue,
                       let city = sort.city, !city.isEmpty,
                       let abbr = sort.abbreviation {
                        markerText.append("\(abbr) \(city)-\(direction) | ")
                    } else if let abbr = sort.abbreviation {
                        markerText.append("\(abbr)-\(direction) | ")
                    }

                default:
                    break
                }
            }
        } catch {
            print("Failed to fetch sort rules: \(error)")
        }

        return markerText as String
    }
    
    @IBAction func btnFiltersAction(_ sender: Any) {
        if bidPeriod.isBidListSortOn?.boolValue ?? false {
            bidPeriod.isBidListSortOn = false
            NotificationCenter.default.post(name: NSNotification.Name("SortBidListAction"), object: self)
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        } else {
            UIView.transition(with: self.navigationController!.view, duration: 0.65, options: .transitionFlipFromRight, animations: { self.navigationController?.popViewController(animated: false)})
        }
    }
    
    
    
    @IBAction func btnActionsTapped(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "BidListActionVC") as! BidListActionVC
        vc.modalPresentationStyle = .custom
        let frame = CGRect(x: 15, y: 35, width: 0, height: 0)
        vc.showPopover(sourceView: btnActions, sourceRect: frame)
    }
    
    @IBAction func btnASortAction(_ sender: Any) {
        let sortOptionVC = UIStoryboard(name: "BidDocument", bundle: nil).instantiateViewController(withIdentifier: "CBBidListSortOptions") as! CBBidListSortOptions
        sortOptionVC.yAxis = btnASort.globalFrame!.minY
        sortOptionVC.xAxis = btnASort.globalFrame!.minX
        self.addChild(sortOptionVC)
        self.view.addSubview(sortOptionVC.view)
        sortOptionVC.view.frame = self.view.bounds
    }
    
    @IBAction func btnExpandedViewAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBExpandedBidLinesTableController") as! CBExpandedBidLinesTableController
        vc.navTitle = "Expanded Bid List"
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @IBAction func btnNormalViewAction(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "isSelectedCalanderView")
        manageViewSelection()
    }
    
    @IBAction func btnCalendarViewAction(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "isSelectedCalanderView")
        manageViewSelection()
    }
    
    func manageViewSelection(){
        var bgColor: UIColor = .white
        bgColor = .secondarySystemBackground
        if UserDefaults.standard.bool(forKey: "isSelectedCalanderView"){
            self.btnNormalView.backgroundColor = bgColor
            self.btnCalendarView.backgroundColor = .orange
        }else{
            self.btnCalendarView.backgroundColor = bgColor
            self.btnNormalView.backgroundColor = .orange
        }
    }

}

extension CBBidListVC: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.linesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            scrollToButton.setImage(UIImage(named: "down-arrow"), for: .normal)
        } else if indexPath.row == linesArray.count - 1 {
            scrollToButton.setImage(UIImage(named: "up-arrow"), for: .normal)
        }
        
        let line = self.linesArray[indexPath.row]
        if !UserDefaults.standard.bool(forKey: "isSelectedCalanderView") {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CBBidlineViewTableViewCell",for: indexPath)as! CBBidlineViewTableViewCell
            
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CBBidListCalenderViewCell",for: indexPath)as! CBBidListCalenderViewCell
        
        
        return cell
    }
}
