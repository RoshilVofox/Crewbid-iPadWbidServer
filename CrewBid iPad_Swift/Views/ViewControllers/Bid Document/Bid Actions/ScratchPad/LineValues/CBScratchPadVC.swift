//
//  CBScatchPadVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit
import CoreData

class CBScratchPadVC: BaseViewController, NSFetchedResultsControllerDelegate, UIPopoverControllerDelegate {

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
    var bidPeriod : BIBidPeriod?
    var ScratchPadCalendarData = BICalendarData()
    var calendarDay : [BICalendarDay] = []
    var trashedPredicate: NSPredicate?
    var tripTextPopover: UIPopoverPresentationController?
    var notTrashedPredicate: NSPredicate!
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
        notificationObserver()
        self.arrayLinesDetails = self.bidPeriod?.lastTrashedDetails ?? NSMutableArray()
        
        //For setting undo in bidlist
        if self.bidPeriod!.managedObjectContext!.undoManager == nil {
            self.bidPeriod!.managedObjectContext!.undoManager = UndoManager()
        }
        
        
        let moc = self.bidPeriod?.managedObjectContext
        //Filters Fetched Results Controller
        let filterFetchRequest = NSFetchRequest<BIFilterRule>(entityName: BIFilterRuleEntityName)
        filterFetchRequest.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true),NSSortDescriptor(key: "type", ascending: true)]
        filterFetchRequest.predicate = NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
        filtersFetchController = NSFetchedResultsController(fetchRequest: filterFetchRequest, managedObjectContext:moc!, sectionNameKeyPath: nil, cacheName: nil)
        filtersFetchController?.delegate = self
        try? filtersFetchController?.performFetch()
        
        //Sorts Fetched Results Controller
        let sortFetchRequest = NSFetchRequest<BILineSort>(entityName: BILineSortEntityName)
        sortFetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        sortFetchRequest.predicate = NSPredicate(format: "isBidListSort != %@", NSNumber(value: true))
        sortsFetchController = NSFetchedResultsController(fetchRequest: sortFetchRequest, managedObjectContext: moc!,sectionNameKeyPath: nil, cacheName: nil)
        sortsFetchController?.delegate = self
        try? sortsFetchController?.performFetch()
        
        //Lines Fetched Results Controller
        notTrashedPredicate = NSPredicate(format: "isTrashed == NO")
        notBidPredicate = NSPredicate(format: "bidOrder == 0")
        var subpredicates = [NSPredicate]()
        let fetched = filtersFetchController?.fetchedObjects
        subpredicates.append(contentsOf: fetched!.compactMap { $0.predicate })
        if let notBid = notBidPredicate {
            subpredicates.insert(notBid, at: 0)
        }
        if let notTrashed = notTrashedPredicate {
            subpredicates.insert(notTrashed, at: 0)
        }
        if bidPeriod!.isOverNightBulkApplied == "YES" {
            subpredicates.append(contentsOf: CBUtils.checkOvernightPredicate())
        }
        
        let lineFetch = NSFetchRequest<BILine>(entityName: BILineEntityName)
        
        let managedVacationEnabled = UserDefaults.standard.bool(forKey: kCBManageVacationEnabledKey)
        if !(self.bidPeriod!.vacationType?.count ?? 0 > 1) && managedVacationEnabled == false {
            let swaptimizerFileURL = Bundle.main.path(forResource: "FilterRulesSwaptimizer", ofType: "plist")
            let swapRulesDict = NSDictionary(contentsOfFile: swaptimizerFileURL!)
            let rules = swapRulesDict!["rules"] as? [[String: Any]]
            let types = rules?.first?["types"] as? [[String: Any]]
            var arryKeys = [String]()
            if let types = types {
                for dict in types {
                    if let key = dict["keyPath"] as? String {
                        arryKeys.append(key)
                    }
                }
            }
            let vacationFilters = NSMutableArray()
                for i in 0..<subpredicates.count {
                    let pred = subpredicates[i] as NSPredicate
                    for j in 0..<rules!.count {
                        if (pred.description).contains(arryKeys[j]){
                            vacationFilters.add(subpredicates[i])
                        }
                    }
                }
            subpredicates.removeAll { vacationFilters.contains($0) }
        }
        let bidPredicate = NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
        let combinedPredicate = NSCompoundPredicate(type: .and, subpredicates: subpredicates + [bidPredicate])
        lineFetch.predicate = combinedPredicate
        let lineSorts = updateSorts()
        lineFetch.sortDescriptors = lineSorts
        linesFetchController = NSFetchedResultsController( fetchRequest: lineFetch, managedObjectContext: moc!,sectionNameKeyPath: nil, cacheName: nil)
        linesFetchController?.delegate = self
        try? linesFetchController?.performFetch()
        self.updateTitle()
        self.fetchTrashedLinesCount()
        self.updateLines()
        self.scratchPadTableView.reloadData()
        
    }
    
    func updatingFetch() {
        let moc = self.bidPeriod?.managedObjectContext
        //Filters Fetched Results Controller
        let filterFetchRequest = NSFetchRequest<BIFilterRule>(entityName: BIFilterRuleEntityName)
        filterFetchRequest.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true),NSSortDescriptor(key: "type", ascending: true)]
        filterFetchRequest.predicate = NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
        filtersFetchController = NSFetchedResultsController(fetchRequest: filterFetchRequest, managedObjectContext:moc!, sectionNameKeyPath: nil, cacheName: nil)
        filtersFetchController?.delegate = self
        try? filtersFetchController?.performFetch()
        
        //Sorts Fetched Results Controller
        let sortFetchRequest = NSFetchRequest<BILineSort>(entityName: BILineSortEntityName)
        sortFetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        sortFetchRequest.predicate = NSPredicate(format: "isBidListSort != %@", NSNumber(value: true))
        sortsFetchController = NSFetchedResultsController(fetchRequest: sortFetchRequest, managedObjectContext: moc!,sectionNameKeyPath: nil, cacheName: nil)
        sortsFetchController?.delegate = self
        try? sortsFetchController?.performFetch()
        
        //Lines Fetched Results Controller
        notTrashedPredicate = NSPredicate(format: "isTrashed == NO")
        notBidPredicate = NSPredicate(format: "bidOrder == 0")
        var subpredicates = [NSPredicate]()
        let fetched = filtersFetchController?.fetchedObjects
        subpredicates.append(contentsOf: fetched!.compactMap { $0.predicate })
        if let notBid = notBidPredicate {
            subpredicates.insert(notBid, at: 0)
        }
        if let notTrashed = notTrashedPredicate {
            subpredicates.insert(notTrashed, at: 0)
        }
        if bidPeriod!.isOverNightBulkApplied == "YES" {
            subpredicates.append(contentsOf: CBUtils.checkOvernightPredicate())
        }
        
        let lineFetch = NSFetchRequest<BILine>(entityName: BILineEntityName)
        
        let managedVacationEnabled = UserDefaults.standard.bool(forKey: kCBManageVacationEnabledKey)
        if !(self.bidPeriod!.vacationType?.count ?? 0 > 1) && managedVacationEnabled == false {
            let swaptimizerFileURL = Bundle.main.path(forResource: "FilterRulesSwaptimizer", ofType: "plist")
            let swapRulesDict = NSDictionary(contentsOfFile: swaptimizerFileURL!)
            let rules = swapRulesDict!["rules"] as? [[String: Any]]
            let types = rules?.first?["types"] as? [[String: Any]]
            var arryKeys = [String]()
            if let types = types {
                for dict in types {
                    if let key = dict["keyPath"] as? String {
                        arryKeys.append(key)
                    }
                }
            }
            let vacationFilters = NSMutableArray()
                for i in 0..<subpredicates.count {
                    let pred = subpredicates[i] as NSPredicate
                    for j in 0..<rules!.count {
                        if (pred.description).contains(arryKeys[j]){
                            vacationFilters.add(subpredicates[i])
                        }
                    }
                }
            subpredicates.removeAll { vacationFilters.contains($0) }
        }
        let bidPredicate = NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
        let combinedPredicate = NSCompoundPredicate(type: .and, subpredicates: subpredicates + [bidPredicate])
        lineFetch.predicate = combinedPredicate
        let lineSorts = updateSorts()
        lineFetch.sortDescriptors = lineSorts
        linesFetchController = NSFetchedResultsController( fetchRequest: lineFetch, managedObjectContext: moc!,sectionNameKeyPath: nil, cacheName: nil)
        linesFetchController?.delegate = self
        try? linesFetchController?.performFetch()
    }

    @objc func updateLines(){
//        NotificationCenter.default.post(name: NSNotification.Name(kCBSyncModeChangedNotification), object: self)
        updatingFetch()
        let fetch = self.linesFetchController.fetchRequest
        var lineSorts = self.updateSorts()
        if self.bidPeriod!.isFABid(){
            let positionSort = NSSortDescriptor(key: "faPosition", ascending: true)
            lineSorts.append(positionSort)
        }
        fetch.sortDescriptors = lineSorts
        var subpredicates = (filtersFetchController?.fetchedObjects)?.compactMap { $0.predicate } ?? []
        subpredicates.insert(self.notBidPredicate, at: 0)
        subpredicates.insert(self.notTrashedPredicate, at: 0)
        let manageVacationEnabled = UserDefaults.standard.bool(forKey: kCBManageVacationEnabledKey)
        if !(self.bidPeriod?.vacationType?.count ?? 0 > 1) && manageVacationEnabled == false{
            let swaptimizerFileURL = Bundle.main.path(forResource: "FilterRulesSwaptimizer", ofType: "plist")
            let faVacFileURL = Bundle.main.path(forResource: "FilterRulesFaVacation", ofType: "plist")
            let swapRulesDict = NSDictionary(contentsOfFile: swaptimizerFileURL!)
            let faVacDict = NSDictionary(contentsOfFile: faVacFileURL!)
            var rules = swapRulesDict!["rules"] as? [[String: Any]]
            var types = rules?.first?["types"] as? [[String: Any]]
            var arryKeys = types!.compactMap { $0["keyPath"] as? String}
            rules = faVacDict!["rules"] as? [[String: Any]]
            types = rules?.first?["types"] as? [[String: Any]]
            let arryKeys2 = types!.compactMap { $0["keyPath"] as? String}
            arryKeys.append(contentsOf: arryKeys2)
            
            let vacationFilters = NSMutableArray()
            
            for i in 0..<subpredicates.count{
                let pred = subpredicates[i]
                for j in 0..<arryKeys.count{
                    if (pred.description).contains(arryKeys[j]){
                        vacationFilters.add(subpredicates[i])
                    }
                }
            }
            subpredicates.removeAll { vacationFilters.contains($0) }
        }
        if self.bidPeriod?.isOverNightBulkApplied == "YES"{
            subpredicates.append(contentsOf: CBUtils.checkOvernightPredicate())
        }
//        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        let bidPredicate = NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
        let combinedPredicate = NSCompoundPredicate(type: .and, subpredicates: subpredicates + [bidPredicate])
        fetch.predicate = combinedPredicate
        do{
            try linesFetchController.performFetch()
        }catch{
            print("Fetch Error: \(error.localizedDescription)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.fetchTrashedLinesCount()
            self.updateTitle()
            self.scratchPadTableView.reloadData()
        })
    }
    
    func updateTitle(){
        if updateScratchpadTitle{
            let linesCount = self.linesFetchController.fetchedObjects?.count
            DispatchQueue.main.async {
                self.lblScratchpadLineCount.text = "Scratchpad- \(linesCount ?? 0) Lines"
            }
        }
    }
    
    
    func notificationObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(refreshLines), name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(removedTrashLines), name: NSNotification.Name("removedLines"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(undoTrashLast), name: NSNotification.Name("undoTrashLast"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trashAll), name: NSNotification.Name("trashAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(recoverAllTrashed), name: NSNotification.Name("recoverAllTrashed"), object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(bidCellLine), name: NSNotification.Name(CBLineTableCellFABidLineNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bidCellLine), name: NSNotification.Name(CBLineTableCellBidLineNotification), object: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    //Adding line to bidlist
    @objc func bidCellLine(_ notification: Notification) {
        guard let lineToBid = notification.userInfo?[CBLineTableCellBidLineKey] as? BILine else { return }
        let lineNum = lineToBid.number!.stringValue
        let lines = self.lineBILineDict[lineNum]
        var tempLines: [BILine] = []
        if let allLines = CBGlobalMethods.shared.selectedBidPeriod?.lines {
            for case let line as BILine in allLines {
                tempLines.append(line)
            }
        }

        // Sort all lines by number
        tempLines = (tempLines as NSArray).sortedArray(using: [NSSortDescriptor(key: "number", ascending: true)]) as! [BILine]

        // Build predicates
        let predicates: [NSPredicate] = [
            NSPredicate(format: "bidOrder == %@", NSNumber(value: 0)),
            NSPredicate(format: "isTrashed == %@", NSNumber(value: false)),
            NSPredicate(format: "number == %@", lineToBid.number ?? 0)
        ]
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        // Filter lines based on predicates
        tempLines = (tempLines as NSArray).filtered(using: predicate) as! [BILine]

        // Check for lineSort with category 3
        if let bidPeriod = CBGlobalMethods.shared.selectedBidPeriod {
            for case let sort as BILineSort in bidPeriod.lineSorts?.allObjects ?? [] {
                if sort.category?.intValue == 3 {
                    positionFlag1 = 1
                }
            }
        }

        if positionFlag1 == 1 {
            let lineSorts = getSortDiscriptorsPosition()
            tempLines = (tempLines as NSArray).sortedArray(using: lineSorts) as! [BILine]
            tempLines = (tempLines as NSArray).sortedArray(using: [NSSortDescriptor(key: "number", ascending: true)]) as! [BILine]
            positionFlag1 = 0
        } else {
            tempLines = (tempLines as NSArray).sortedArray(using: [NSSortDescriptor(key: "number", ascending: true), NSSortDescriptor(key: "faPosition", ascending: true)]) as! [BILine]
        }
        if lines!.count != tempLines.count{
            if tempLines.first?.number == (lines)?.first?.number{
                tempLines = lines!
            }
        }
        if tempLines.isEmpty {
            return
        }
        // If only one FA position, insert directly
        if tempLines.count == 1 {
            let bidListVC = CBBidListVC()
            bidListVC.setupVariables()
            bidListVC.insertLines(tempLines, faBidAllPositions: false)
            NotificationCenter.default.post(name: NSNotification.Name("flipToBidList"), object: nil)
        } else {
            // More than one position – show popup menu
            var arr: [String] = tempLines.map { "Move Position \($0.faPositionString) to Bid List" }
            arr.sort()
            arr.append("Move All Positions to Bid List")

            let vc = UIStoryboard(name: "BidDocument", bundle: nil).instantiateViewController(withIdentifier: "FaMoveBidListMenu") as! FaMoveBidListMenu
            vc.array = arr
            vc.lines = tempLines
            vc.modalPresentationStyle = .popover
            if let buttonView = notification.userInfo?[CBLineTableCellButtonViewKey] as? UIView {
                let frame = CGRect(x: btnTrash.frame.origin.x - 30, y: btnTrash.frame.origin.y + 18, width: 0, height: 0)
                vc.showPopover(sourceView: buttonView, sourceRect: frame)
            }
        }
    }
    
    func bidFALine(withLines lines: NSMutableArray, bidAllPositions bidAll: Bool) {
        if bidAll {
            let bidLinesNotification = Notification(
                name: Notification.Name(CBLinesTableBidLinesFaAllNotification),
                object: self,
                userInfo: [CBLinesTableBidLinesArrayKey: lines]
            )
            NotificationCenter.default.post(bidLinesNotification)
            
        } else {
            let bidLinesNotification = Notification(
                name: Notification.Name(CBLinesTableBidLinesNotification),
                object: self,
                userInfo: [CBLinesTableBidLinesArrayKey: lines]
            )
            NotificationCenter.default.post(bidLinesNotification)
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
        let userPosOrder = NSMutableArray() /* TODO: .reserveCapacity(maxPositionsPerLine) */
        
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
        guard let context = self.bidPeriod?.managedObjectContext else { return }

        // Fetch all BILine objects for this bid period (all FA positions)
        let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
        
        do {
            let allLines = try context.fetch(fetchRequest)

            guard !allLines.isEmpty else { return }

            var trashedLineNumbers: [String] = []

            for line in allLines {
                line.isTrashed = true
                if let number = line.number?.stringValue {
                    trashedLineNumbers.append(number)
                }
            }

            let temp = (self.bidPeriod?.lastTrashedDetails as? NSMutableArray) ?? NSMutableArray()
            temp.add(trashedLineNumbers)
            self.bidPeriod?.lastTrashedDetails = temp
            self.arrayLinesDetails = temp

            self.updateLines()
        } catch {
            print("Failed to fetch all lines: \(error)")
        }
    }
    
    //Undo trash line
    @objc func undoTrashLast(){
        guard let lastObject = self.bidPeriod?.lastTrashedDetails?.lastObject else { return }

            var isItemRemoved = false
            var lineNumbersToUntrash: Set<String> = []

            if let array = lastObject as? [String] {
                // Pilot bid format: ["2"]
                lineNumbersToUntrash = Set(array)
            } else if let string = lastObject as? String {
                // FA bid format: "2A,2B,2C"
                let positions = string.components(separatedBy: ",")
                lineNumbersToUntrash = Set(positions.map { String($0.prefix { $0.isNumber }) })
            }

            for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines ?? [] {
                if let lineNum = line.number?.stringValue, lineNumbersToUntrash.contains(lineNum) {
                    line.isTrashed = NSNumber(value: false)
                    isItemRemoved = true
                }
            }

            if isItemRemoved {
                let temp: NSMutableArray = (self.bidPeriod?.lastTrashedDetails as? NSMutableArray) ?? NSMutableArray()
                temp.removeLastObject()
                self.bidPeriod?.lastTrashedDetails = temp
                self.arrayLinesDetails = temp
            }

            do {
                try self.bidPeriod?.managedObjectContext?.save()
                updateLines()
            } catch {
                print("Undo trash save error: \(error)")
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
    
    @objc func refreshLines(){
        self.updateLines()
        self.updateTitle()
        self.scratchPadTableView.reloadData()
    }
    
    //Remove trashed lines from scratchpad
    @objc func removedTrashLines(notification: NSNotification){
        if self.bidPeriod!.isFABid(){
            let lineToBid = notification.userInfo![CBLineTableCellBidLineKey] as! BILine
            let index = self.linesArray!.index(of: lineToBid)
//            let indexPath = IndexPath(row: index, section: 0)
            let line = self.linesArray!.object(at: index) as! BILine
            let faPositions = self.linePosDict![line.number!.stringValue] as! NSArray
            let lineIndex = self.linesFetchController.indexPath(forObject: line)
            let tempArray:NSMutableArray = NSMutableArray()
            for j in 0..<faPositions.count {
                let nextIndexPath = IndexPath(row: lineIndex!.row + j, section: 0)
                let faLine = self.linesFetchController.object(at: nextIndexPath)
                faLine.isTrashed = true
                tempArray.add("\(faLine.number!)\(faLine.faPositionString)")
            }
            let objDelArray:NSMutableArray = self.bidPeriod?.lastTrashedDetails as? NSMutableArray ?? NSMutableArray()
            let joinedComponents = tempArray.componentsJoined(by: ",")
            objDelArray.add(joinedComponents)
            let uniqueArray = NSOrderedSet(array: objDelArray as! [Any]).array
            self.bidPeriod?.lastTrashedDetails = NSMutableArray(array: uniqueArray)
            tempArray.removeAllObjects()
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }else{
            if let lineNumArray = notification.object as? NSArray {
                let temp : NSMutableArray = self.bidPeriod?.lastTrashedDetails as? NSMutableArray ?? NSMutableArray()
                temp.add(lineNumArray)
                self.bidPeriod?.lastTrashedDetails = temp
                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            }
        }
        try? bidPeriod?.managedObjectContext?.save()
    }
    
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
              //  if lineSort?.isBidListSort == false{
                    lineSorts.append(sort)
              //  }
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
        self.scratchPadTableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
    }
    
    //Tap gesture for refresh button in trash menu.
    @objc func trashRefreshButton(_ gesture: UITapGestureRecognizer) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshMenuController") as! RefreshMenuController
        refreshViewController.bidPeriod = bidPeriod!
        refreshViewController.lines = self.linesArray as! [BILine]
        refreshViewController.popOverType = PopoverViewType.Refresh
        refreshViewController.arrayLinesDetails = self.linesFetchController.fetchedObjects! as NSArray
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
                AlertService.showAlertForTopVC(title: "Line not found", message: "Line \(lineNumber) is not in the Scratchpad.  It is either filtered out, trashed, or in the Bid List.", actions: nil)
                return
            }
            let lineNumPred = NSPredicate(format: "number == %@", lineNumber)
            let fetchedLines = self.linesArray
            let lineArray = (fetchedLines as? [Any])?.filter { lineNumPred.evaluate(with: $0) } ?? []
            if !lineArray.isEmpty {
                let line = lineArray.first as! BILine
                let index = self.linesArray?.index(of: line)
                let lineIndexPath = NSIndexPath(row: index!, section: 0)
                if lineIndexPath.row < self.scratchPadTableView.numberOfRows(inSection: 0){
                    self.scratchPadTableView.scrollToRow(at: lineIndexPath as IndexPath, at: .middle, animated: true)
                }
            }else{
                    let num = Int(lineNumber)
                    var theLine:BILine? = nil
                    for case let line as BILine in fetchedLines! {
                        if line.number?.intValue == num{
                            theLine = line
                            break
                        }
                    }
                    if theLine != nil {
                        let index = self.linesArray?.index(of: theLine!)
                        let lineIndexPath = NSIndexPath(row: index!, section: 0)
                        if lineIndexPath.row < self.scratchPadTableView.numberOfRows(inSection: 0){
                            self.scratchPadTableView.scrollToRow(at: lineIndexPath as IndexPath, at: .middle, animated: true)
                        }
                    }else{
                        AlertService.showAlertForTopVC(title: "Line not found", message: "Line \(lineNumber) is not in the Scratchpad. It is either filtered out, trashed, or in the Bid List.", actions: nil)
                    }
                }
            
            
                
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.linesArray = NSMutableArray()
        self.linePosDict = NSDictionary()
        let linePos = NSMutableDictionary()
        let lineBILineMap = NSMutableDictionary()
        let linesArray = NSMutableArray(array: self.linesFetchController.fetchedObjects!)
        let linesToRemove = NSMutableIndexSet()
        let posArray = NSMutableArray()
        let lineObjArray = NSMutableArray()
        for index in 0..<linesArray.count {
            let line = linesArray[index] as! BILine
            if index == 0{
                posArray.add(line.faPositionString)
                lineObjArray.add(line)
            }
            if index > 0 {
                let prevLine = linesArray[index - 1] as! BILine
                if line.number?.intValue == prevLine.number?.intValue {
                    posArray.add(line.faPositionString)
                    linesToRemove.add(index)
                    lineObjArray.add(line)
                }else{
                    linePos.setValue(posArray.mutableCopy(), forKey: prevLine.number!.stringValue)
                    lineBILineMap.setValue(lineObjArray.mutableCopy(), forKey: prevLine.number!.stringValue)
                    posArray.removeAllObjects()
                    lineObjArray.removeAllObjects()
                    posArray.add(line.faPositionString)
                    lineObjArray.add(line)
                }
            }
            
            if index == linesArray.count - 1 {
                linePos.setValue(posArray.mutableCopy(), forKey: line.number!.stringValue)
                lineBILineMap.setValue(lineObjArray.mutableCopy(), forKey: line.number!.stringValue)
                posArray.removeAllObjects()
                lineObjArray.removeAllObjects()
            }
        }
        linesArray.removeObjects(at: linesToRemove as IndexSet)
        var swiftDict = [String: [BILine]]()

        for (key, value) in lineBILineMap {
            if let keyStr = key as? String,
               let valueArray = value as? NSArray {
                let bilines = valueArray.compactMap { $0 as? BILine }
                swiftDict[keyStr] = bilines
            }
        }

        self.lineBILineDict = swiftDict
        self.linePosDict = linePos
        self.linesArray = linesArray
        return linesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScratchPadTableCellTableViewCell") as! ScratchPadTableCellTableViewCell
        configureCell(cell, row: indexPath.row)
        cell.controllerDelegate = self
        cell.fromScrachpadView = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 273
    }
    
    func configureCell(_ cell:ScratchPadTableCellTableViewCell, row : Int) {
        let line = self.linesArray![row] as! BILine
        cell.lineNumberLabel.text = line.number?.stringValue
        cell.orderLabel.text = "\(row + 1)"
        cell.selectionStyle = .none
        if line.isRedEyeLine == true{
            cell.redEyeImage.isHidden = false
        }else{
            cell.redEyeImage.isHidden = true
        }
        
        cell.calendarData = ScratchPadCalendarData
        cell.calendarDaysArr = calendarDay
        cell.bidPeriod = bidPeriod!
        cell.line = line
        cell.tableView = scratchPadTableView
        cell.tripButtonActionBlock = {(_ tripButton: CBTripButton) -> Void in
            DispatchQueue.main.async {
                self.showTripTextPopover(for: tripButton)
            }}

        
        let setupCircles = true
        if (bidPeriod?.isFABid())!{
            
            if row > 0 {
                let prevLine = self.linesArray![row - 1] as! BILine
                let line = self.linesArray![row] as! BILine
                if line.number?.intValue == prevLine.number?.intValue{
                    cell.isHidden = true
                }
            }else{
                cell.isHidden = false
            }
            
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

            if line.faPositionString == "NA"{
                cell.posNAView.alpha = 1
                cell.refreshTripButtons(highlightFlag: true, calendarWidth: self.view.frame.size.width - 160)
            }else if line.faPositionString == "M"{
                cell.posMView.alpha = 1
                cell.refreshTripButtons(highlightFlag: true, calendarWidth: self.view.frame.size.width - 160)
            }else{
                
                if row > 0 {
                    let prevLine = self.linesArray![row - 1] as! BILine
                    let line = self.linesArray![row] as! BILine
                    if line.number?.intValue == prevLine.number?.intValue{
//                        setupCircles = false
                    }
                }
                
                if setupCircles{
                    cell.posAGrayView.alpha = 0.15
                    cell.posBGrayView.alpha = 0.15
                    cell.posCGrayView.alpha = 0.15
                    cell.posDGrayView.alpha = 0.15
                    
                    let faPositions = self.linePosDict![line.number!.stringValue] as! [Any]
                        for j in 0..<faPositions.count{
                            let posString = faPositions[j] as! String
                            if posString == "A" {
                                cell.setCircle(j, withPos: posString, color: CBColor.faPosAColor, isGray: false)
                            }else if posString == "B" {
                                cell.setCircle(j, withPos: posString, color: CBColor.faPosBColor, isGray: false)
                            }else if posString == "C" {
                                cell.setCircle(j, withPos: posString, color: CBColor.faPosCColor, isGray: false)
                            }else {
                                cell.setCircle(j, withPos: posString, color: CBColor.faPosDColor, isGray: false)
                            }
                        }
                    cell.refreshTripButtons(highlightFlag: true, calendarWidth: self.view.frame.size.width - 160)
                }
            }
        }else{
            let orderLabel:UILabel = cell.viewWithTag(20) as! UILabel
            orderLabel.alpha = 1
            cell.refreshTripButtons(highlightFlag: true, calendarWidth: self.view.frame.size.width - 160)
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
            let tag = 10000 + i * 10
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
            if CBLineValueTypes(rawValue: valueType) == .VacationPayDifference {
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
            let tag = 10000 + i * 10
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

extension CBScratchPadVC: CBUserFlagTableControllerDelegate {
    func changeLineUserFlagTypeTo(flagType: CBUserFlagType, selectedLine: BILine?) {
        for case let line as BILine in self.linesArray! {
            line.userFlagType = flagType.rawValue as NSNumber
        }
        try? self.bidPeriod?.managedObjectContext?.save()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    
}

