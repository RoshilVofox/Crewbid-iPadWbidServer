//
//  CBBIdListVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit
import CoreData

var kReserveMrtViewTag: Int = 76
var kReserveMrtLabelTag: Int = 333
var kSnowflakeTag: Int = 1040

class CBBidListVC: BaseViewController, NSFetchedResultsControllerDelegate, CBBidListCalenderViewCellDelegate,StartOverDelegate, CBBidLineMenuControllerDelegate  {

    
    
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
    var count = 0
    var bidListCalenderDays = [Any]()
    var bidListCalendarData = BICalendarData()
    var awardedLineNum: String!
    var bidPeriod1: BIBidPeriod?
    var isShouldScrollToInsertionIndex = false
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
    var previousInsertionIndex:Int = 0
    var shouldScrollToInsertionIndex:Bool?
    var userFaPosOrder:NSArray?
    var tripCBButton: CBTripButton!
    private var _insertionIndex: Int?
    
    var insertionIndex: Int  {
        get {
            return Int(truncating: insertionPoint!.index ?? 0)
        }
        set(newValue) {
            _insertionIndex = newValue
            insertionPoint?.index = _insertionIndex! as NSNumber
            //code to execute
        }
    }
    private var _insertAbove: Bool?
    var insertAbove: Bool{
        get {
            return insertionPoint!.above != 0
        }
        set(newValue) {
            _insertAbove = newValue
            insertionPoint?.above = _insertAbove! as NSNumber
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateTitle()
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnLine(_:)), name: NSNotification.Name(rawValue: "CBReturnLinesNotification"), object: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.standard.set(false, forKey: kCBNoAutoswitchToBids)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        lblBidLineCount.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        lblBidLineCount.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableViewNormalView.setEditing(true, animated: false)
        if UserDefaults.standard.bool(forKey: "HasSavedScrollPosition") && CBGlobalMethods.shared.isMoveAllAction == false {
            let lastRow = UserDefaults.standard.integer(forKey: "LastScrollRow")
            let lastSection = UserDefaults.standard.integer(forKey: "LastScrollSection")
            let lastIndexPath = IndexPath(row: lastRow, section: lastSection)
            
            DispatchQueue.main.async {
                if self.tableViewNormalView.numberOfRows(inSection: lastSection) > lastRow {
                    self.tableViewNormalView.scrollToRow(at: lastIndexPath, at: .middle, animated: false)
                }
            }
        }
    }
    
    @objc func labelTapped() {
        let isEffSenSelected = UserDefaults.standard.bool(forKey: "IsEffSenSelected")
        UserDefaults.standard.set(!isEffSenSelected, forKey: "IsEffSenSelected")
        updateTitle()
    }
    
    func setupVariables(){
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        self.managedObjectContext = bidPeriod.managedObjectContext
        let insertionPointFetch = NSFetchRequest<BIInsertionPoint>(entityName: "InsertionPoint")
        insertionPointFetch.fetchLimit = 1
        do {
            let results = try self.managedObjectContext!.fetch(insertionPointFetch)
            if let existingPoint = results.first {
                insertionPoint = existingPoint
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "InsertionPoint", in: bidPeriod.managedObjectContext!)
                let newPoint = BIInsertionPoint(entity: entity!, insertInto: bidPeriod.managedObjectContext)
                newPoint.index = 0
                newPoint.above = false
                insertionPoint = newPoint
                try? bidPeriod.managedObjectContext?.save()
            }
        } catch {
            print("Failed to fetch insertion point: \(error)")
        }
//        
//        let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "bidOrder > 0")
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
//
//        if self.bidPeriod.isBidListSortOn?.boolValue == true {
//            fetchRequest.sortDescriptors = getSortDescriptorsForBidList()
//        }
//
//        let controller = NSFetchedResultsController( fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
//        controller.delegate = self
//        do {
//            try controller.performFetch()
//            self.linesFetchController = controller
//        } catch {
//            print("Error executing lines fetch: \(error)")
//        }
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
        self.tableViewNormalView.delegate = self
        self.tableViewNormalView.dataSource = self
        let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTapToScrollTop(_:)))
        doubleTap.numberOfTapsRequired = 1
        lblBidLineCount.addGestureRecognizer(doubleTap)
//        Notification Center
        NotificationCenter.default.addObserver(self, selector: #selector(updateBidList(_:)), name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.lineValuesToDisplayChanged(notification:)), name: Notification.Name(CBLineValuesToDisplayDidChangeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.ScrollToLine), name: NSNotification.Name(rawValue: "ScrollToLineNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.ScrollToBottom), name: NSNotification.Name(rawValue: "ScrollToBottomLineNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.ScrollToInsertion), name: NSNotification.Name(rawValue: "ScrollToInsertionLineNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.moveInsertionIndex(_:)), name: NSNotification.Name(rawValue: "CBInsertLinesAboveNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.moveInsertionIndex(_:)), name: NSNotification.Name(rawValue: "CBInsertLinesBelowNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.addMarker(_:)), name: NSNotification.Name(rawValue: "CBAddMarkerNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.editMarker(_:)), name: NSNotification.Name(rawValue: "CBEditMarkerNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deleteMarker(_:)), name: NSNotification.Name(rawValue: "CBRemoveMarkerNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.freezeTopLines(_:)), name: NSNotification.Name(rawValue: "CBFreezeLinesNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.unfreezeTopLines(_:)), name: NSNotification.Name(rawValue: "CBUnFreezeLinesNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deselectAllLines), name: NSNotification.Name(rawValue: "CBDeselectAllLinesNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.moveSelectedLinesToInsertionIndex), name: NSNotification.Name(rawValue: "CBMoveSelectedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.undo), name: NSNotification.Name(rawValue: "CBUndoNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.redo), name: NSNotification.Name(rawValue: "CBRedoNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deleteSelectedLines), name: NSNotification.Name(rawValue: "CBReturnSelectedLinesNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deleteAllLines), name: NSNotification.Name(rawValue: "CBReturnUnfrozenLinesNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.cellDidSelect(notification:)), name: Notification.Name("CBBidLineTableCellDidSelectNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.cellDidDeselect(notification:)), name: Notification.Name("CBBidLineTableCellDidDeselectNotification"), object: nil)
        self.isSubmitSort = (self.bidPeriod.isSortBySubmitOn ?? 0).boolValue
        self.isAwardSort = (self.bidPeriod.isAwardSortOn ?? 0).boolValue
        if isAwardSort{
//            loadAwardDetails()
        }
    }
    
    @objc func handleDoubleTapToScrollTop(_ sender : UITapGestureRecognizer) {
        if self.tableViewNormalView.numberOfRows(inSection: 0) > 0 {
            self.tableViewNormalView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
    func removeBidListObservers(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "refreshLines"), object: nil)
    }
    
    @objc func deselectAllLines() {
        // Deselect all selected lines

        
        //NSArray *selectedIndexPaths = self.tableView.indexPathsForSelectedRows;
        let selectedIndexPaths = selectedCellIndexPaths
        //    [[self.undoManager prepareWithInvocationTarget:self] setTableViewSelectedRowIndexPaths:selectedIndexPaths];
        //    [self.undoManager setActionName:@"Deselect All Lines"];
        // Remove cell selections.
        let visibleIndexPaths = self.tableViewNormalView.indexPathsForVisibleRows
        for case let indexPath as IndexPath in selectedIndexPaths {
            tableViewNormalView.deselectRow(at: indexPath, animated: true)
            if visibleIndexPaths?.contains(indexPath) ?? false {
                // Grab the cell that needs to be deselected
                let cell: UITableViewCell? = tableViewNormalView.cellForRow(at: indexPath)
                cell?.setSelected(false, animated: false)
                
                let bidLineCell = cell as? CBBidlineViewTableViewCell
                
                bidLineCell?.selectionToggleButton.customSelected = false
                bidLineCell?.selectionToggleButton.isHighlighted = false
                
                // Force the cell to redraw
                tableViewNormalView.beginUpdates()
                tableViewNormalView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                tableViewNormalView.endUpdates()
            }
        }
        if selectedCellIndexPaths.count == 0
        {
            tableViewNormalView.reloadData()
        }
        selectedCellIndexPaths.removeAllObjects()
        tableViewNormalView.reloadData()
    }
    
    @objc func deleteAllLines() {
        insertionIndex = 0
        insertAbove = false
        var enteredForLoop = false
    
        // Loop through the linesArray
        for line in linesArray {
            enteredForLoop = true
            // Check if the line is not frozen
            if !(line.isFrozen != 0) {
                // Check if it's a Flight Attendant bid line and delete accordingly
                if bidPeriod.isFABid() && (line.faBidLineMrt?.boolValue)! || (line.faBidLineReserve?.boolValue)! {
                    if (line.faBidLineReserve?.boolValue)! {
                        bidPeriod.faReserveLineExists = false
                    }
                    else {
                        bidPeriod.faMrtLineExists = false
                    }
                    // Remove the line from the bidLines
                    line.removeFromBidLines()
                    bidPeriod.managedObjectContext!.delete(line)
                }
                else {
                    line.removeFromBidLines()
                }
            }
            else {
                insertionIndex += 1
            }
        }
        if enteredForLoop {
            bidPeriod.managedObjectContext!.undoManager?.setActionName("Remove All Unfrozen Lines")
            if insertionIndex != 0 {
                insertionIndex -= 1
            }
            
        }
        selectedCellIndexPaths.removeAllObjects()
        self.updateBidList()
        
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    @objc func deleteSelectedLines() {
        // Remove selected lines from bid lines and renumber lines that are not
        // removed. Move insertion index up for any lines deleted at or below it.
        let selectedIndexPaths = selectedCellIndexPaths
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
        var bidOrder: Int = firstRow + 1
        var insertionIndex: Int = self.insertionIndex
        var countOfLinesRemovedBelowInsertionIndex: Int = 0
        let countOfBidLines: Int = linesArray.count
        // Loop through the linesArray

        for i in firstRow..<countOfBidLines {
            let indexPath = IndexPath(row: i, section: 0)
            let line = linesArray[i]
            // If line is selected, remove from bid group. The check that i is less
            // than or equal to last row is an optimization to prevent having to
            // check that index path is contained in selected index paths.
            let arr:NSMutableArray = NSMutableArray(array: selectedIndexPaths)
            // If line is selected, remove from bid group
            if i <= lastRow! && arr.contains(indexPath) {
                // Attempt to preserve marker by moving it to line below (if one
                // exists below line and that line does not have a marker.
                // Attempt to preserve marker by moving it to line below (if one exists below line and that line does not have a marker).

                if (line.markerTitle != nil) && i < countOfBidLines - 1 {
                    let nextLine = linesArray[i + 1]
                    if nil == nextLine.markerTitle {
                        nextLine.markerTitle = line.markerTitle
                    }
                }
                // Check if it's a Flight Attendant bid line and delete accordingly

                if ((line.faBidLineReserve?.boolValue)! || (line.faBidLineMrt?.boolValue)!) {
                    if (line.faBidLineReserve?.boolValue)! {
                        bidPeriod.faReserveLineExists = false
                        line.removeFromBidLines()
                    }
                    else {
                        bidPeriod.faMrtLineExists = false
                        line.removeFromBidLines()
                    }
                    bidPeriod.managedObjectContext!.delete(line)
                }
                else {
                    // Remove the line from the bidLines

                    line.removeFromBidLines()
                }
                if i <= insertionIndex {
                    countOfLinesRemovedBelowInsertionIndex += 1
                }
            }
            else {
                // Update bidOrder number ,lines that are not removed
                line.bidOrder = bidOrder as NSNumber
                bidOrder += 1
            }
            
        }
        // Don't allow insertion index to become negative.
        
        countOfLinesRemovedBelowInsertionIndex = countOfLinesRemovedBelowInsertionIndex > insertionIndex ? insertionIndex : countOfLinesRemovedBelowInsertionIndex
        previousInsertionIndex = insertionIndex
        insertionIndex = insertionIndex - countOfLinesRemovedBelowInsertionIndex
        bidPeriod.managedObjectContext!.undoManager?.setActionName("Remove Line\(selectedIndexPaths.count > 1 ? "s" : "")")
        selectedCellIndexPaths.removeAllObjects()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
        // self.updateBidList()
        insertionIndexUpdate()
    }
    func insertionIndexUpdate(){
        let lineCount = linesArray.count
        if !(lineCount > 0 && insertionIndex < lineCount) {
            insertionIndex = linesArray.count - 1
        }
    }
    
    @objc func undo() {
        if (bidPeriod.managedObjectContext!.undoManager?.canUndo)! && !(bidPeriod.managedObjectContext!.undoManager?.undoActionName == "") {
            bidPeriod.managedObjectContext!.undoManager?.undo()
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    @objc func redo () {
        if bidPeriod.managedObjectContext!.undoManager?.canRedo ?? false {
            bidPeriod.managedObjectContext!.undoManager?.redo()
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
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
    
    @objc func lineValuesToDisplayChanged(notification: Notification) {
        if bidPeriod.isBidListSortOn?.boolValue == true {
            let lineSorts = getSortDescriptorsForBidList()
            self.linesArray = (linesArray as NSArray).sortedArray(using: lineSorts ) as! [BILine]
        }
        try? self.bidPeriod.managedObjectContext!.save()
        self.updateBidList()
        self.tableViewNormalView.reloadData()
    }
    
    
    // Scrolls the table view to the insertion index.
    @objc func ScrollToInsertion () {
        let insertionBarIndexPath = IndexPath(row: insertionIndex, section: 0)
        if insertionBarIndexPath.row < tableViewNormalView.numberOfRows(inSection: 0) {
            tableViewNormalView.scrollToRow(at: insertionBarIndexPath, at: .middle, animated: true)
        }
    }
    
    @objc func freezeTopLines(_ notification: Notification) {
        let valueFromNotification = notification.object
        let dictValues:NSMutableDictionary = valueFromNotification as! NSMutableDictionary
        let row: Int = dictValues.value(forKey: "indexpath") as! Int
        
        // Freeze the top lines up to the specified row
        
        for j in 0...row {
            let ip = IndexPath(row: j, section: 0)
            let line = linesArray[ip.row]
            line.isFrozen = true
            line.frozenOrder = j + 1 as NSNumber
        }
        
        // Unfreeze rows below if they were previously frozen
        for j in (row + 1)..<linesArray.count {
            let ip = IndexPath(row: j, section: 0)
            let line = linesArray[ip.row]
            
            if line.isFrozen == true {
                line.isFrozen = false
                line.frozenOrder = 0
            } else {
                break // Stop once we reach a non-frozen line
            }
        }
        
        // Step 3: Renumber remaining frozen lines to keep frozenOrder compact
        var currentOrder = 0
        for line in linesArray where line.isFrozen == true {
            line.frozenOrder = NSNumber(value: currentOrder + 1)
            currentOrder += 1
        }
        
        // If the selection index was within the block of lines that was frozen, move it out.
        if insertionIndex < row + 1 {
            moveInsertionIndex(to: row, above: false)
            if insertionIndex == linesArray.count {
                insertionIndex -= 1
                moveInsertionIndex(to: insertionIndex, above: false)
            }
        }
        bidPeriod.managedObjectContext!.undoManager?.setActionName("Freeze Top Lines")
        if selectedCellIndexPaths.count > 0 {
            selectedCellIndexPaths.removeAllObjects()
        }
        tableViewNormalView.reloadData()
    }
    
    @objc func unfreezeTopLines(_ notification: Notification) {
        let obj = notification.object as! NSDictionary
        let Count = obj["indexpath"] as! Int + 1
        
        // Unfreeze the top lines up to the specified count

        for j in 0..<Count {
            let ip = IndexPath(row: j, section: 0)
            let line = linesArray[ip.row]
            if (line.isFrozen != 0) {
                line.isFrozen = false
                line.frozenOrder = NSNumber(value: 0)
            } else {
                continue
            }
        }
        bidPeriod.managedObjectContext!.undoManager?.setActionName("Unfreeze Top Lines")
        if selectedCellIndexPaths.count > 0 {
            selectedCellIndexPaths.removeAllObjects()
        }
        tableViewNormalView.reloadData()
    }
    
    func moveInsertionIndex(to index: Int, above: Bool) {
        // Moves the insertion index to the specified position above or below a line.
        // If there is no change, do nothing.
        if insertionIndex == index && insertAbove == above {
            return
        }
        // Disable undo registration temporarily

        bidPeriod.managedObjectContext?.undoManager?.disableUndoRegistration()
        
        // Store the previous insertion index

        previousInsertionIndex = insertionIndex
        // Update the insertion index and insertAbove flag

        insertionIndex = index
        insertAbove = above
        let linesCount: Int = tableViewNormalView.numberOfRows(inSection: 0)
        // Check if the insertion indices are valid, and reload the table view if necessary

        if linesCount > 0 {
            if previousInsertionIndex > linesCount - 1 && previousInsertionIndex != 0 {
                previousInsertionIndex = linesCount - 1
                tableViewNormalView.reloadData()
                return
            }
            if insertionIndex > linesCount - 1 && insertionIndex != 0 {
                insertionIndex = linesCount - 1
                tableViewNormalView.reloadData()
                return
            }
        }
        // Create an array of indexPaths to reload

        var reloadIndexPaths: [Any]? = nil
        if previousInsertionIndex == insertionIndex {
            reloadIndexPaths = [IndexPath(row: insertionIndex, section: 0)]
        } else {
            reloadIndexPaths = [IndexPath(row: previousInsertionIndex, section: 0), IndexPath(row: insertionIndex, section: 0)]
        }
        // Deselect cells at the old and new insertion indices

        for case let ip as IndexPath in reloadIndexPaths! {
            let cell: UITableViewCell? = tableViewNormalView.cellForRow(at: ip)
            cell?.setSelected(false, animated: false)
        }
        // Reload the table view with the updated insertion indices

        if let aPaths = reloadIndexPaths as? [IndexPath] {
            tableViewNormalView.reloadRows(at: aPaths, with: .automatic)
        }
        // Save changes and clear the undo manager

        bidPeriod.managedObjectContext!.processPendingChanges()
        bidPeriod.managedObjectContext!.undoManager?.removeAllActions()
    }
    
    @objc func moveInsertionIndex(_ notification: Notification) {
        // Handles the movement of the insertion index when triggered by a notification.

        let valueFromNotification = notification.object
        let dictValues:NSMutableDictionary = valueFromNotification as! NSMutableDictionary
        let index: Int = dictValues.value(forKey: "indexpath") as! Int
        let above: Bool = dictValues.value(forKey: "above") as! Bool
        
        // If there is no change, do nothing.
        if insertionIndex == index && insertAbove == above {
            return
        }
        bidPeriod.managedObjectContext!.undoManager?.disableUndoRegistration()
        
        // Store the previous insertion index

        previousInsertionIndex = insertionIndex
        // Update the insertion index and insertAbove flag

        insertionIndex = index
        insertAbove = above
        let linesCount: Int = tableViewNormalView.numberOfRows(inSection: 0)
        // Check if the insertion indices are valid, and reload the table view if necessary

        if linesCount > 0 {
            if previousInsertionIndex > linesCount - 1 && previousInsertionIndex != 0 {
                previousInsertionIndex = linesCount - 1
                tableViewNormalView.reloadData()
                return
            }
            if insertionIndex > linesCount - 1 && insertionIndex != 0 {
                insertionIndex = linesCount - 1
                tableViewNormalView.reloadData()
                return
            }
        }
        // Create an array of indexPaths to reload

        var reloadIndexPaths: [Any]? = nil
        if previousInsertionIndex == insertionIndex {
            reloadIndexPaths = [IndexPath(row: insertionIndex, section: 0)]
        } else {
            reloadIndexPaths = [IndexPath(row: previousInsertionIndex, section: 0), IndexPath(row: insertionIndex, section: 0)]
        }
        // Deselect cells at the old and new insertion indices

        for case let ip as IndexPath in reloadIndexPaths! {
            let cell: UITableViewCell? = tableViewNormalView.cellForRow(at: ip)
            cell?.setSelected(false, animated: false)
        }
        // Reload the table view with the updated insertion indices

        if let aPaths = reloadIndexPaths as? [IndexPath] {
            tableViewNormalView.reloadRows(at: aPaths, with: .automatic)
        }
        bidPeriod.managedObjectContext!.processPendingChanges()
        bidPeriod.managedObjectContext!.undoManager?.removeAllActions()
        // Save changes and clear the undo manager
            
        // Additional reload after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let aPaths = reloadIndexPaths as? [IndexPath] {
                self.tableViewNormalView.reloadRows(at: aPaths, with: .automatic)
            }
        }
    }
    
    func addReserveMRTline(indexpath: Int, isReserve: Bool) {
        removeASortUI()
        let indexPath: Int = indexpath
        // Disable undo registration temporarily

        bidPeriod.managedObjectContext?.undoManager?.disableUndoRegistration()
        let lineEntity = NSEntityDescription.entity(forEntityName: BILineEntityName, in: bidPeriod.managedObjectContext!)
        var bidOrder: Int = (indexPath) + 1
        var row: Int = indexPath
        let countOfBidLines: Int = linesArray.count
        let bidOrderOffset: Int = 1
        if 0 == countOfBidLines {
            bidOrder = 1
            row = countOfBidLines
        }
        if isReserve{
            var reserveLine: BILine?
            if let anEntity = lineEntity {
                reserveLine = BILine(entity: anEntity, insertInto: bidPeriod.managedObjectContext)
            }
            reserveLine?.faBidLineReserve = true
            reserveLine?.number = 10001
            reserveLine?.faNumber = "10001NA"
            reserveLine?.bidPeriod = bidPeriod
            // Set bid order for reserve line.
            reserveLine?.bidOrder = bidOrder as NSNumber
          
            bidPeriod.faReserveLineExists = true
        }else{
            var mrtLine: BILine? = nil
            if let anEntity = lineEntity {
                mrtLine = BILine(entity: anEntity, insertInto: bidPeriod.managedObjectContext!)
            }
            mrtLine?.faBidLineMrt = true
            mrtLine?.number = 10000
            mrtLine?.faNumber = "10000NA"
            mrtLine?.bidPeriod = bidPeriod
            // Set bid order for reserve line.
            mrtLine?.bidOrder = bidOrder as NSNumber
            // Set bid order for lines below inserted lines
          
            bidPeriod.faMrtLineExists = true
           
        }
        // Set bid order for lines below inserted lines.
        while row < countOfBidLines {
            let ln = linesArray[row]
            ln.bidOrder = row + bidOrderOffset + 1 as NSNumber
            row += 1
        }
        if insertionIndex >= (indexPath) {
            insertionIndex += 1
        }
        // Save changes and clear selected lines

        bidPeriod.managedObjectContext?.processPendingChanges()
        bidPeriod.managedObjectContext?.undoManager?.removeAllActions()
        if selectedCellIndexPaths.count >  0 {
            selectedCellIndexPaths.removeAllObjects()
            tableViewNormalView.reloadData()
        }
        // Post notifications for updates

        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("updateBidListCount"), object: nil)
    }
    
    func removeReserveMRTline(indexpath: IndexPath, isReserve: Bool) {
        // Delete a line at the given index path

        deleteLine(at: indexpath)
        
        // Clear selected lines and reload the table view

        if selectedCellIndexPaths.count > 0 {
            selectedCellIndexPaths.removeAllObjects()
            tableViewNormalView.reloadData()
        }
    }
    
    @objc func cellDidSelect(notification: Notification) {
        let dict = notification.object as! NSDictionary
        let object = dict["object"]
        print("selectedCellIndexPaths \(selectedCellIndexPaths)")
        let indexPath = dict["indexPath"] as? IndexPath
        if (object as! UITableViewCell).classForCoder.description() == "CrewBid_iPad_Swift.CBBidlineViewTableViewCell" {
            let cell = object as? CBBidlineViewTableViewCell
            if let aCell = cell {
                tableViewNormalView.selectRow(at: tableViewNormalView.indexPath(for: aCell), animated: false, scrollPosition: .none)
            }
            let arr = selectedCellIndexPaths
            if !arr.contains(indexPath!) {
                selectedCellIndexPaths.add(indexPath!)
            }
        }
        else if (object as! UITableViewCell).classForCoder.description() == "CrewBid_iPad_Swift.CBBidListCalenderViewCell" {
            let cell = object as? CBBidListCalenderViewCell
            if let aCell = cell {
                tableViewNormalView.selectRow(at: tableViewNormalView.indexPath(for: aCell), animated: false, scrollPosition: .none)
            }
            let arr = selectedCellIndexPaths
            if !arr.contains(indexPath!) {
                selectedCellIndexPaths.add(indexPath!)
            }
        }
        print("selectedCellIndexPaths \(selectedCellIndexPaths)")

    }
    
    // Handle cell deselection

    @objc func cellDidDeselect(notification: Notification) {
        let dict = notification.object as! NSDictionary
        let object = dict["object"]
        let indexPath = dict["indexPath"] as? IndexPath
        print("selectedCellIndexPaths \(selectedCellIndexPaths)")
        if (object as! UITableViewCell).classForCoder.description() == "CrewBid_iPad_Swift.CBBidlineViewTableViewCell" {
            let cell = notification.object as? CBBidlineViewTableViewCell
            if let aCell = cell {
                tableViewNormalView.deselectRow(at: tableViewNormalView.indexPath(for: aCell)!, animated: false)
            }
            let arr = selectedCellIndexPaths
            
            if arr.contains(indexPath!) {
                let index = arr.index(of: indexPath!)
                selectedCellIndexPaths.removeObject(at: index)
            }
        }
        else if (object as! UITableViewCell).classForCoder.description() == "CrewBid_iPad_Swift.CBBidListCalenderViewCell" {
            let cell = notification.object as? CBBidListCalenderViewCell
            if let aCell = cell {
                tableViewNormalView.deselectRow(at: tableViewNormalView.indexPath(for: aCell)!, animated: false)
            }
            let arr = selectedCellIndexPaths
            let index = arr.index(of: indexPath!)
            if arr.contains(indexPath!) {
                selectedCellIndexPaths.removeObject(at: index)
            }
        }
        print("selectedCellIndexPaths \(selectedCellIndexPaths)")

    }
    
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
    
    // Restore previous bid order

    private func setPreviousBidOrder() {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        // setting the pervious bid order while turning off A-Sort
        for line in linesArray {
            line.bidOrder = line.previousBidOrder
         //   line.previousBidOrder = NSNumber(integerLiteral: 0)
        }
    }
    
    @objc func addMarker(_ notification: Notification) {
        // Handles the addition of a marker when triggered by a notification.

        let valueFromNotification = notification.object
        let dictValues:NSMutableDictionary = valueFromNotification as! NSMutableDictionary
        let indexPath: IndexPath = dictValues.value(forKey: "indexpath") as! IndexPath
        bidPeriod.managedObjectContext!.undoManager?.disableUndoRegistration()
        // Retrieve the line associated with the indexPath and set its marker title to an empty string

        var line: BILine? = nil
        line = linesArray[indexPath.row]
        line?.markerTitle = ""
        // Reload the table view to allow editing of the marker text field

        self.tableViewNormalView.reloadRows(at: [indexPath], with: .none)
        // Delay to ensure that the marker text field becomes first responder after reloading

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let lineCell = self.tableViewNormalView.cellForRow(at: indexPath) as? CBBidlineViewTableViewCell
            lineCell?.beginEditingMarker()
        }
    }
    
    @objc func editMarker(_ notification: Notification) {
        // Handles the editing of a marker when triggered by a notification.

        let valueFromNotification = notification.object
        let dictValues:NSMutableDictionary = valueFromNotification as! NSMutableDictionary
        let indexPath: IndexPath = dictValues.value(forKey: "indexpath") as! IndexPath
        // Disable undo registration temporarily

        bidPeriod.managedObjectContext!.undoManager?.disableUndoRegistration()
        // Get the cell for the specified indexPath and make the marker text field first responder

        let lineCell = tableViewNormalView.cellForRow(at: indexPath) as? CBBidlineViewTableViewCell
        lineCell?.markerTextField.becomeFirstResponder()
    }
    
    @objc func deleteMarker(_ notification: Notification) {
        // Handles the deletion of a marker when triggered by a notification.

        let valueFromNotification = notification.object
        let dictValues:NSMutableDictionary = valueFromNotification as! NSMutableDictionary
        let indexPath: IndexPath = dictValues.value(forKey: "indexpath") as! IndexPath
        bidPeriod.managedObjectContext!.undoManager?.disableUndoRegistration()
        // Retrieve the line associated with the indexPath and remove its marker title

        var line: BILine? = nil
        line = linesArray[indexPath.row]
        line?.markerTitle = nil
        // Get the cell type for the row and update the cell accordingly

        let lineCell = tableViewNormalView.cellForRow(at: indexPath) as? CBBidlineViewTableViewCell
        lineCell?.cellType = cellTypeForRow(at: indexPath)
        // Save changes and clear the undo manager

        bidPeriod.managedObjectContext!.processPendingChanges()
        bidPeriod.managedObjectContext!.undoManager?.removeAllActions()
        self.tableViewNormalView.reloadRows(at: [indexPath], with: .none)
    }
    
    @objc func returnLine(_ notification: Notification?) {
        let valueFromNotification = notification?.object
        let dictValues:NSMutableDictionary = valueFromNotification as! NSMutableDictionary
        let indexPath: IndexPath = dictValues.value(forKey: "indexpath") as! IndexPath
        deleteLine(at: indexPath)
    }
    
    func deleteLine(at indexPath: IndexPath) {
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        // Renumber lines below deleted line.
        let countOfBidLines: Int = linesArray.count
        var row: Int = indexPath.row + 1
        
        while row < countOfBidLines {
            let ip = IndexPath(row: row, section: 0)
            let ln = linesArray[ip.row]
            ln.bidOrder = row as NSNumber
            row += 1
        }
        var line: BILine? = nil
        
        line = linesArray[indexPath.row]
        
        // Move marker to line below unless line is the last line in the table or
        // the following line has a marker.
        // Move marker to line below unless the line is the last line in the table or the following line has a marker

        if (line?.markerTitle != nil) && indexPath.row < countOfBidLines - 1 {
            let nextLine = linesArray[indexPath.row + 1]
            if nil == nextLine.markerTitle {
                nextLine.markerTitle = line?.markerTitle
            }
        }
        if (line?.faBidLineReserve?.boolValue)! || (line?.faBidLineMrt?.boolValue)! {
            if (line?.faBidLineReserve?.boolValue)! {
                bidPeriod.faReserveLineExists = false
            } else {
                bidPeriod.faMrtLineExists = false
            }
            bidPeriod.managedObjectContext!.delete(line!)
            try? bidPeriod.managedObjectContext?.save()
            
        } else {
            line?.removeFromBidLines()
        }
        // Move insertion index up if deleting a row that is not the first row.
        
        if indexPath.row <= insertionIndex {
            if 0 != insertionIndex {
                previousInsertionIndex = insertionIndex
                insertionIndex = insertionIndex - 1
            }
        }
        bidPeriod.managedObjectContext!.undoManager?.setActionName("Remove Line")
        selectedCellIndexPaths.removeAllObjects()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    
    @objc func ScrollToBottom () {
        let numberOfRows: Int = tableViewNormalView.numberOfRows(inSection: 0)
        if numberOfRows != 0 {
            let insertionBarIndexPath = IndexPath(row: numberOfRows - 1, section: 0)
            tableViewNormalView.scrollToRow(at: insertionBarIndexPath, at: .bottom, animated: true)
        }
    }
    
    @objc func ScrollToLine(_ notification: Notification) {
        let valueFromNotification = notification.object
        let dictValues:NSMutableDictionary = valueFromNotification as! NSMutableDictionary
        var lineNumber: String = dictValues.value(forKey: "lineNumber") as! String
        
        var indexofLine : Int? = nil
        for i in 0..<self.linesArray.count {
            let line = linesArray[i]
            if line.number!.stringValue == lineNumber {
                indexofLine = i
                break
            }
        }
        
        
        if bidPeriod.isFABid() {
            // Extract the line number from the number/position format
            for i in 0..<self.linesArray.count {
                let line = linesArray[i]
                if line.number!.stringValue == lineNumber {
                    if line.faReserveLineType == 3 || line.faReserveLineType == 2 || line.faReserveLineType == 1{
                        indexofLine = i
                        reserveScrollForFA(indexofFAReserve: i)
                        return
                    }
                }
            }
            lineNumber = lineNumber.uppercased()
            let scanner = Scanner(string: lineNumber)
            
            let validCharacters = CharacterSet(charactersIn: "0123456789ABCDM")

            if lineNumber.rangeOfCharacter(from: validCharacters.inverted) != nil {
                let alertController = UIAlertController(title: "Invalid characters entered.", message: "You must enter a combination of valid characters: 0-9 and A, B, C, D, M.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            let numCharSet = CharacterSet(charactersIn: "0123456789")
            let positionCharSet = CharacterSet(charactersIn: "ABCDM")
            _ = scanner.scanUpToCharacters(from: numCharSet)
//            scanner.scanUpToCharacters(from: numCharSet, into: nil)
            var lineNumberFA: NSString? = nil
            var position: NSString? = nil
            while !scanner.isAtEnd {
                lineNumberFA = scanner.scanCharacters(from: numCharSet) as? NSString
                position = scanner.scanCharacters(from: positionCharSet) as? NSString
//                scanner.scanCharacters(from: numCharSet, into: &lineNumberFA)
//                scanner.scanCharacters(from: positionCharSet, into: &position)
            }
            if lineNumberFA?.length == nil {
                let alertController = UIAlertController(title: "No line entered.", message: "You must enter a line number when selecting the Scroll to Line option.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            else if position?.length == nil {
                //"You must enter a position when scrolling to a line in the Bid List (but not when scrolling to a line in the Scratchpad)."
                let alertController = UIAlertController(title: "No position entered.", message: "You must enter a position when scrolling to a line in the Bid List.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            let num = Int((lineNumberFA ?? "") as String) ?? 0
            
            for i in 0..<self.linesArray.count {
                let line = linesArray[i]
                if (line.number?.intValue)! == num && (line.faPositionString == position! as String) {
                    indexofLine = i
                    break
                }
            }
            
        }
        
        
        if lineNumber.isEmpty {
            let alertController = UIAlertController(title: "No line entered.", message: "You must enter a line number when selecting the Scroll to Line option.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else if indexofLine != nil {
            if indexofLine! < tableViewNormalView.numberOfRows(inSection: 0) {
                tableViewNormalView.scrollToRow(at: IndexPath(row: indexofLine!, section: 0), at: .middle, animated: true)
            }
        }else{
            let alertController = UIAlertController(title: "Line not found.", message: "Line \(lineNumber) is not in the Bid List.  It is in the Scratchpad (if you don't see it there, it is either filtered out or trashed).", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel) {
                UIAlertAction in
            }
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    func reserveScrollForFA(indexofFAReserve : Int){
        if indexofFAReserve < tableViewNormalView.numberOfRows(inSection: 0) {
            tableViewNormalView.scrollToRow(at: IndexPath(row: indexofFAReserve, section: 0), at: .middle, animated: true)
        }
    }
    
    
    
    
    func loadBidLine(){
        self.updateTitle()
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
    
    func createTabsForViewTypeChange(){
        
    }
    func tableViewMoveDown(){
        
    }
    func updateTitle(){
        let totalLines = CBGlobalMethods.shared.selectedBidPeriod!.lines!
        let allLines = linesArray
        let bidListTotal: Int = (allLines.count)
        let etopsCount = ((self.linesArray) as NSArray).value(forKey: "isETOPS")
        let etopsReserveCount = ((self.linesArray) as NSArray).value(forKey: "isETOPSRES")
        let etopsCountNumber = NSCountedSet(array: etopsCount as! [Any])
        let etopsReserveCountNumber = NSCountedSet(array: etopsReserveCount as! [Any])
        var title = "\(totalLines.count) Lines - Bid List - \(bidListTotal) Lines"
        if (etopsCountNumber.count(for: 1) != 0) || (etopsReserveCountNumber.count(for: 1) != 0) {
            let eCount = etopsCountNumber.count(for: 1) + etopsReserveCountNumber.count(for: 1)
            title = "\(totalLines.count) Lines - Bid List - \(bidListTotal) Lines - \(eCount) ETOPS"
        }
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
        DispatchQueue.main.async { [self] in
            lblBidLineCount.adjustsFontSizeToFitWidth = true
            lblBidLineCount.text = title
            lblBidLineCount.isUserInteractionEnabled = true
            let lblTap = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
            lblBidLineCount.addGestureRecognizer(lblTap)
        }
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
    

    
    
    func insertLines(_ lines: [BILine], faBidAllPositions: Bool = false) {
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        removeASortUI()
    
        if 0 == lines.count {
            return
        }
        // Begin an undo grouping for the transaction.

        bidPeriod.managedObjectContext!.undoManager?.beginUndoGrouping()
        // If inserting above, and line at insertion row has marker, move marker to
        // first line in inserted lines.
        var insertionRowLine: BILine? = nil
        var insertingDirectlyBelowMarker: Bool = insertionIndex < linesArray.count
        if insertingDirectlyBelowMarker {
            if insertionIndex == -1 {
                insertionIndex = 0
            }
            if linesArray.count != 0 {
                if insertionIndex < linesArray.count {
                    insertionRowLine = linesArray[insertionIndex]
                }
            }
            insertingDirectlyBelowMarker = insertAbove && nil != insertionRowLine?.markerTitle
        }
        
        if insertingDirectlyBelowMarker {
            let firstInsertedLine: BILine? = lines[0]
            firstInsertedLine?.markerTitle = insertionRowLine?.markerTitle
            insertionRowLine?.markerTitle = nil
        }
        // If not inserting directly below a marker, add marker if inserting
        // multiple lines.
        else if (lines.count > 1 && !faBidAllPositions) {
            let lastInsertedLine: BILine? = lines.last
            var markerTitle = "Marker: "
            markerTitle += markerTitleForMultipleInsert()
            lastInsertedLine?.markerTitle = markerTitle
        }

        // Calculate the initial bid order and row for the inserted lines.

        
        var bidOrder: Int = insertAbove ? self.insertionIndex + 1 : self.insertionIndex + 2
        var row: Int = insertAbove ? self.insertionIndex : self.insertionIndex + 1
        let countOfBidLines: Int? = linesArray.count
        let bidOrderOffset: Int = lines.count
        previousInsertionIndex = insertionIndex
        insertionIndex += lines.count
        
        if 0 == countOfBidLines {
            bidOrder = 1
            row = countOfBidLines ?? 0
            self.insertionIndex = lines.count - 1
        }
        
        
        // Set bid order for inserted lines.
        for line1 in lines {
            let line = line1
            line.bidOrder = (bidOrder as NSNumber)
            line.previousBidOrder = (bidOrder as NSNumber)
            bidOrder += 1
        }
        
        // Set bid order for lines below inserted lines.
        while row < countOfBidLines! {
            let ln = linesArray[row]
            ln.bidOrder = row + bidOrderOffset + 1 as NSNumber
            ln.previousBidOrder = row + bidOrderOffset + 1 as NSNumber
            row += 1
        }
        
        // Should scroll to insertion index if the new insertion index will not be
        // visible in the table.
        isShouldScrollToInsertionIndex = true
        UserDefaults.standard.setValue(true, forKey: "isShouldScrollToInsertionIndex")
        // Set undo action name.
        bidPeriod.managedObjectContext!.undoManager?.setActionName("Insert Line\(lines.count > 1 ? "s" : "")")
        bidPeriod.managedObjectContext!.undoManager?.endUndoGrouping()
        
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("updateBidListCount"), object: nil)
//        guard !lines.isEmpty else { return }
//
//        var insertingDirectlyBelowMarker = self.insertionIndex < self.linesFetchController.fetchedObjects?.count ?? 0
//        var insertionRowLine: BILine?
//        if insertingDirectlyBelowMarker {
//            if insertionIndex == -1 {
//                insertionIndex = 0
//            }
//            if linesArray.count != 0 {
//                if insertionIndex < linesArray.count {
//                    insertionRowLine = linesArray[insertionIndex]
//                }
//            }
//            
//            
////            insertionRowLine = linesFetchController.object(at: IndexPath(row: insertionIndex, section: 0))
//            insertingDirectlyBelowMarker = insertAbove && insertionRowLine?.markerTitle != nil
//        }
//
//        if insertingDirectlyBelowMarker, let insertionRowLine = insertionRowLine {
//            lines[0].markerTitle = insertionRowLine.markerTitle
//            insertionRowLine.markerTitle = nil
//        } else if lines.count > 1 && !faBidAllPositions {
//            if let lastInsertedLine = lines.last {
//                var markerTitle = CBPresetsTVC.selectedPresetName(bidPeriod: bidPeriod) ?? ""
//                if !markerTitle.isEmpty { markerTitle += ": " }
//                markerTitle += markerTitleForMultipleInsert()
//                lastInsertedLine.markerTitle = markerTitle
//                let markerIndex = insertAbove ? insertionIndex + lines.count - 1 : insertionIndex + lines.count
//                addedMarkerIndexPath = IndexPath(row: markerIndex, section: 0)
//            }
//        }
//
//        var bidOrder = insertAbove ? insertionIndex + 1 : insertionIndex + 2
//        var row = insertAbove ? insertionIndex : insertionIndex + 1
//
//        let linesFetch: NSFetchRequest<BILine> = BILine.fetchRequest()
//        linesFetch.predicate = NSPredicate(format: "bidOrder > 0")
//        
//        if bidPeriod.isBidListSortOn?.boolValue == true {
//            linesFetch.sortDescriptors = getSortDescriptorsForBidList()
//        } else {
//            linesFetch.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
//        }
//
//        linesFetchController = NSFetchedResultsController(fetchRequest: linesFetch, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
//        linesFetchController.delegate = self
//
//        do {
//            try linesFetchController.performFetch()
//        } catch {
//            print("Error executing lines fetch: \(error)")
//        }
//
//        let countOfBidLines = linesFetchController.fetchedObjects?.count ?? 0
//        let bidOrderOffset = lines.count
//        previousInsertionIndex = insertionIndex
//        insertionIndex += lines.count
//
//        if countOfBidLines == 0 {
//            bidOrder = 1
//            row = countOfBidLines
//            insertionIndex = lines.count - 1
//        }
//
//        for line in lines {
//            line.bidOrder = NSNumber(value: bidOrder)
//            bidOrder += 1
//
//            for trip in line.trips ?? [] {
//                if let trip = trip as? BITrip, trip.highlightCount?.intValue ?? 0 > 0 {
//                    trip.bidListHighlighted = true
//                }
//            }
//        }
//
//        while row < countOfBidLines {
//            let ip = IndexPath(row: row, section: 0)
//            let ln = linesFetchController.object(at: ip)
//            ln.bidOrder = NSNumber(value: row + bidOrderOffset + 1)
//            row += 1
//        }
//
//        // ✅ Ensure changes are committed so scratchpad FRC updates
//        do {
//            try managedObjectContext?.save()
//        } catch {
//            print("Error saving context: \(error)")
//        }
//
//        shouldScrollToInsertionIndex = true
//        undoManager?.setActionName("Insert Line\(lines.count > 1 ? "s" : "")")
//
//        selectedCellIndexPaths.removeAllObjects()
//        refreshLines()
//        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
//        NotificationCenter.default.post(name: NSNotification.Name("updateBidListCount"), object: nil)
    }
    
    func getSortDescriptorsForBidList() -> [NSSortDescriptor] {
//        guard let moc = bidPeriod.managedObjectContext else { return [] }
//        
//        var lineSorts: [NSSortDescriptor] = []
//        var userPosOrder: [NSNumber] = []
//        var addedLineNumSort = false
//        let standardPosOrder: [NSNumber] = [0, 1, 2, 3]  // A, B, C, D positions
//        // --- Fetch BILineSort objects
//        let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
//        fetchRequest.predicate = NSPredicate(format: "isBidListSort == %@", NSNumber(value: true))
//        
//        let sortsFetchController = NSFetchedResultsController(
//            fetchRequest: fetchRequest,
//            managedObjectContext: moc,
//            sectionNameKeyPath: nil,
//            cacheName: nil
//        )
//        sortsFetchController.delegate = self
//        self.sortsFetchController = sortsFetchController
//        
//        do {
//            try sortsFetchController.performFetch()
//        } catch {
//            print("Sorts fetch failed: \(error)")
//            return []
//        }
//        
//        let fetchedSorts = sortsFetchController.fetchedObjects ?? []
//        
//        // --- Fetch frozen lines
//        let frozenLinesRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
//        frozenLinesRequest.predicate = NSPredicate(format: "isFrozen == %@", NSNumber(value: true))
//        frozenLinesRequest.sortDescriptors = [NSSortDescriptor(key: "isFrozen", ascending: false)]
//        
//        do {
//            let frozenLines = try moc.fetch(frozenLinesRequest)
//            if !frozenLines.isEmpty {
//                lineSorts.append(NSSortDescriptor(key: "isFrozen", ascending: false))
//                lineSorts.append(NSSortDescriptor(key: "frozenOrder", ascending: true))
//            }
//        } catch {
//            print("Error executing lines fetch: \(error)")
//        }
//        
//        // --- Create expression descriptor for "number"
//        let numberExpression = NSExpression(forKeyPath: "number")
//        let numberExpDescription = NSExpressionDescription()
//        numberExpDescription.name = "number"
//        numberExpDescription.expression = numberExpression
//        numberExpDescription.expressionResultType = .integer16AttributeType
//        
//        // --- Build lineSorts from fetched sort descriptors
//        for lineSort in fetchedSorts {
//            guard let keyPath = lineSort.keyPath, !keyPath.isEmpty else { continue }
//            
//            if lineSort.category?.intValue == BILineSortCategory.BIPositionsLineSortCategory.rawValue {
//                if !addedLineNumSort {
//                    // Insert the line number sort first
//                    lineSorts.append(NSSortDescriptor(key: numberExpDescription.name, ascending: true))
//                    addedLineNumSort = true
//                }
//                if let type = lineSort.type {
//                    userPosOrder.append(type)
//                }
//            }
//            
//            lineSorts.append(NSSortDescriptor(key: keyPath, ascending: lineSort.ascending?.boolValue ?? true))
//        }
//        
//        // Fill in missing standard positions
//        let remaining = standardPosOrder.filter { !userPosOrder.contains($0) }
//        userPosOrder.append(contentsOf: remaining)
//        self.userFaPosOrder = userPosOrder as NSArray
//        
//        // Fallback sort descriptors
//        if fetchedSorts.isEmpty {
//            lineSorts.append(NSSortDescriptor(key: "bidOrder", ascending: true))
//        } else {
//            lineSorts.append(NSSortDescriptor(key: numberExpDescription.name, ascending: true))
//            
//            if bidPeriod.isFABid() {
//                lineSorts.append(NSSortDescriptor(key: "faPosition", ascending: true))
//            }
//        }
//        
//        return lineSorts
        let number = NSExpression(forKeyPath: "number")
        let numberExpDescription = NSExpressionDescription()
        numberExpDescription.name = "number"
        numberExpDescription.expression = number
        numberExpDescription.expressionResultType = .integer16AttributeType
        
        // Initialize an array to store sort descriptors

        var lineSortDiscriptors = [NSSortDescriptor]()
        // Check if frozen bid list lines exist, and add sort descriptors accordingly

        if (self.bidPeriod.getFrozenBidListLines().count ) > 0 {
            lineSortDiscriptors.append(NSSortDescriptor(key: "isFrozen", ascending: false))
            lineSortDiscriptors.append(NSSortDescriptor(key: "frozenOrder", ascending: true))
        }
        // Initialize default position order
        var standardPosOrder = [0, 1, 2, 3]
        let userPosOrder = NSMutableArray() /* TODO: .reserveCapacity(maxPositionsPerLine) */
        
        // Iterate through user-defined line sorts

        for case let lineSort in self.bidPeriod.getOrderedBidListSorts(){
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

        if self.bidPeriod.getOrderedBidListSorts().count == 0 {
            lineSortDiscriptors.append(NSSortDescriptor(key: "bidOrder", ascending: true))
        } else {
            let sort = NSSortDescriptor(key: numberExpDescription.name, ascending: true)
            lineSortDiscriptors.append(sort)
            // Ensure that the lines are sorted by position if FA since the position logic depends on it
            if bidPeriod.isFABid() {
                let positionSort = NSSortDescriptor(key: "faPosition", ascending: true)
                lineSortDiscriptors.append(positionSort)
            }
        }
        
       
        return lineSortDiscriptors
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
    
    
    @IBAction func scrollToAction(_ sender: UIButton) {
        let upArrow = UIImage(named: "up-arrow")
        let downArrow = UIImage(named: "down-arrow")
        
        if linesArray.count > 0 {
            if sender.imageView?.image == upArrow {
                sender.setImage(downArrow, for: .normal)
                self.tableViewNormalView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                
            } else {
                sender.setImage(upArrow, for: .normal)
                self.tableViewNormalView.scrollToRow(at: IndexPath(row: self.linesArray.count-1, section: 0), at: .bottom, animated: true)
            }
        }
    }
    
    @IBAction func btnActionsTapped(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "BidListActionVC") as! BidListActionVC
        vc.ArrLinesDetails = self.linesArray
        vc.selectedLinesCount = selectedCellIndexPaths
        vc.delegate = self
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
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @IBAction func btnNormalViewAction(_ sender: Any) {
        self.bidPeriod.managedObjectContext!.undoManager?.removeAllActions()
        UserDefaults.standard.set(false, forKey: "isSelectedCalanderView")
        manageViewSelection()
        self.tableViewNormalView.reloadData()
    }
    
    @IBAction func btnCalendarViewAction(_ sender: Any) {
        self.bidPeriod.managedObjectContext!.undoManager?.removeAllActions()
        UserDefaults.standard.set(true, forKey: "isSelectedCalanderView")
        manageViewSelection()
        self.tableViewNormalView.reloadData()
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

    func didTappedOnCalandarView(indexPath: IndexPath) {
        tableView(self.tableViewNormalView, didSelectRowAt: indexPath)
    }
    
    
    func showTripTextPopover(for tripButton: CBTripButton) {
        
        if (self.presentedViewController is CBTripTextViewController){
            self.dismiss(animated: true)
            return
        }
        // Fetch trip text associated with the trip button

        let tripText: String = tripButton.trip!.tripText()
        // Create a trip text view controller with the trip text and button information

        let tripTextController = CBTripTextViewController.instantiateFromStoryboard(withTripText: tripText, button: tripButton) as! CBTripTextViewController
        tripTextController.modalPresentationStyle = .custom
        tripButton.setHighlighted(true)
        // Pass trip text and button information to the trip text controller

        tripTextController.tripText1 = tripText
        self.tripCBButton = tripButton
        tripTextController.button = tripButton
        tripTextController.isFromBidList = true
        tripTextController.showPopover(sourceView: tripButton)
    }
    //MARK: -Bidlist actions
    // Code for starting over action
    func startOver(){
        removeASortUI()
        self.linesArray = []
        let context = self.bidPeriod.managedObjectContext!
        // Delete all Commutability objects
        let fetchRequest1 = NSFetchRequest<NSFetchRequestResult>(entityName: "Commutability")
        if let result = try? context.fetch(fetchRequest1) as? [NSManagedObject] {
                for commute in result {
                    context.delete(commute)
                }
            }
        // Delete all OvernightBulk objects
        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "OvernightBulk")
            if let results = try? context.fetch(fetchRequest2) as? [NSManagedObject] {
                for bulk in results {
                    context.delete(bulk)
                }
            }
        // Reset the trip highlight count
        BITrip.resetTripHighlightCount(in: self.managedObjectContext!)
        self.insertionIndex = 0
        self.insertAbove = false
        
        for line in bidPeriod.orderedLines() {
            bidPeriod.faReserveLineExists = false
            bidPeriod.faMrtLineExists = false
            if bidPeriod.isFABid() && ((line.faBidLineMrt?.boolValue)! || (line.faBidLineReserve?.boolValue)!) {
                bidPeriod.managedObjectContext!.delete(line)
            }
            line.isFrozen = false
            line.frozenOrder = NSNumber(value: 0)
            line.removeFromBidLines()
            line.userFlagType = CBUserFlagType.none.rawValue as NSNumber
        }
        
        for case let sort as BILineSort in (bidPeriod.lineSorts?.allObjects ?? []){
            if (sort.lineSortKeyMap != nil) {
                bidPeriod.managedObjectContext?.delete(sort.lineSortKeyMap!)
            }
            bidPeriod.managedObjectContext?.delete(sort)
        }
        
        for case let filterRule as BIFilterRule in (bidPeriod.lineFilters?.allObjects ?? []) {
            bidPeriod.managedObjectContext?.delete(filterRule)
        }
        
        for case let line in bidPeriod.orderedLines() {
            line.userFlagType = CBUserFlagType.none.rawValue as NSNumber
        }
        
        let biReader = BIBidInfoReader()
        biReader.bidPeriod = bidPeriod
        _ = biReader.addDefaultFilterRules(context: self.managedObjectContext!)
        selectedCellIndexPaths.removeAllObjects()
        
        insertionIndex = 0
        updateTitle()
        self.tableViewNormalView.reloadData()
        
        if let nav = self.navigationController, let viewDismiss = nav.view {
            UIView.transition(with: viewDismiss,
                              duration: 0.75,
                              options: [.transitionFlipFromLeft, .curveEaseInOut],
                              animations: nil) { _ in
                nav.popViewController(animated: false)
            }
        }
        
        UserDefaults.standard.set(false, forKey: "isSelectedCalanderView")
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        NotificationCenter.default.post(name: NSNotification.Name("updateBidListCount"), object: self)
    }
    
    func configureCell(_ cell: CBBidlineViewTableViewCell, at indexPath: IndexPath) {
        let line = self.linesArray[indexPath.row]
        if (self.bidPeriod.isAwardSortOn ?? 0).boolValue {
            if (line.faBidLineMrt ?? 0).boolValue || (line.faBidLineReserve ?? 0).boolValue {
                cell.isHidden = true
            } else {
                cell.isHidden = false
            }
        } else {
            cell.isHidden = false
        }
        cell.mLblSlNo.text = "\(indexPath.row + 1)"
        cell.mLblLineNumber.text = String(describing: line.number!)
        var setupLineValues = true
        if nil == cell.backgroundView {
            cell.backgroundView = UIView(frame: cell.bounds)
            cell.backgroundView?.backgroundColor = UIColor.appColor(.contentBgColor)
            cell.calendarData = bidListCalendarData
            let objCMutableArray = NSMutableArray(array: bidListCalenderDays)
            cell.calendarDaysCount = objCMutableArray
        }
        if bidPeriod.isFABid() && line.faPosition?.intValue != BIFaPosition.FaPositionNA.rawValue {
            cell.mLblLineNumber.textColor = .white
            if line.faPosition?.intValue == BIFaPosition.FaPositionA.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosAColor
                cell.mLblLineNumber.text = cell.mLblLineNumber.text! + ("A")
            }
            else if line.faPosition?.intValue == BIFaPosition.FaPositionB.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosBColor
                cell.mLblLineNumber.text = cell.mLblLineNumber.text! + ("B")
            }
            else if line.faPosition?.intValue == BIFaPosition.FaPositionC.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosCColor
                cell.mLblLineNumber.text = cell.mLblLineNumber.text! + ("C")
            }
            else if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosDColor
                cell.mLblLineNumber.text = cell.mLblLineNumber.text! + ("D")
            } else {
                cell.positionCircleView.backgroundColor = UIColor.purple
                cell.mLblLineNumber.text = cell.mLblLineNumber.text! + ("M")
            }
            cell.positionCircleView.alpha = 1.0
            // Check if award sorting is enabled and highlight the cell if needed

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
        } else {
            cell.positionCircleView.alpha = 0.0
            // Check if award sorting is enabled and highlight the cell if needed

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
        cell.cellType = cellTypeForRow(at: indexPath)
        cell.bidPeriod = self.bidPeriod
        cell.line = line
        cell.scrollLineValue.tag = indexPath.row
        let singlePressGesture = UITapGestureRecognizer(target: self, action: #selector(self.SingleTap))
        cell.scrollLineValue.addGestureRecognizer(singlePressGesture)
        singlePressGesture.delaysTouchesBegan = true
        cell.refreshCalendar()
        let arr = selectedCellIndexPaths
        cell.selectionToggleButton.setImage(#imageLiteral(resourceName: "RadioButton-On"), for: .normal)
        if arr.contains(indexPath) {
            cell.selectButton(true)
            cell.selectionToggleButton.isSelected = true
        } else {
            cell.selectButton(false)
            cell.selectionToggleButton.isSelected = false
        }
        cell.selectionToggleButton.tag = indexPath.row
        // User flag control
        cell.userFlagControl.backgroundColor = CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType(rawValue: Int(truncating: (line.userFlagType)!))!)
        if CBUserFlagType.none.rawValue == line.userFlagType?.intValue {
            cell.userFlagControl.alpha = 1
        } else {
            cell.userFlagControl.alpha = 1
        }
        cell.backgroundView?.backgroundColor = UIColor.appColor(.contentBgColor)
        let reserveMrtLabel = cell.viewWithTag(kReserveMrtLabelTag) as? UILabel
        let reserveMrtView = cell.viewWithTag(kReserveMrtViewTag)
        if bidPeriod.isFirstRoundBid() && bidPeriod.isFABid() {
            if (line.faBidLineMrt?.boolValue)! {
                setupLineValues = false
                cell.scrollLineValue.isHidden = true
                cell.positionCircleView.isHidden = true
                cell.calendarCollectionView.isHidden = true
                cell.mLblLineNumber.isHidden = true
                reserveMrtLabel?.alpha = 1.0
                reserveMrtView?.alpha = 1.0
                reserveMrtLabel?.backgroundColor = CBColor.faPosBColor
                reserveMrtView?.backgroundColor = CBColor.faPosBColor
                cell.backgroundView?.backgroundColor = CBColor.faPosBColor
                reserveMrtLabel?.text = "MRT Line"
            }
            else if (line.faBidLineReserve?.boolValue)! {
                cell.scrollLineValue.isHidden = true
                cell.positionCircleView.isHidden = true
                cell.calendarCollectionView.isHidden = true
                cell.mLblLineNumber.isHidden = true
                reserveMrtLabel?.text = "Reserve Line"
                reserveMrtLabel?.alpha = 1.0
                reserveMrtLabel?.backgroundColor = CBColor.faPosBColor
                reserveMrtView?.alpha = 1.0
                reserveMrtView?.backgroundColor = CBColor.faPosBColor
                cell.backgroundView?.backgroundColor = CBColor.faPosBColor
                setupLineValues = false
            } else {
                cell.scrollLineValue.isHidden = false
                cell.positionCircleView.isHidden = false
                cell.calendarCollectionView.isHidden = false
                cell.mLblLineNumber.isHidden = false
                cell.backgroundView?.backgroundColor = UIColor.appColor(.contentBgColor)
                reserveMrtLabel?.alpha = 0.0
                reserveMrtView?.alpha = 0.0
            }
        } else {
            cell.scrollLineValue.isHidden = false
            cell.positionCircleView.isHidden = false
            cell.calendarCollectionView.isHidden = false
            cell.mLblLineNumber.isHidden = false
            cell.backgroundView?.backgroundColor = UIColor.appColor(.contentBgColor)
            reserveMrtLabel?.alpha = 0.0
            reserveMrtView?.alpha = 0.0
        }
        
        //Set Etops line
        if line.isETOPS?.boolValue == true
        {
            cell.mLblLineNumber.text = cell.mLblLineNumber.text! + ("e")
            let strTitle:NSString = cell.mLblLineNumber.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "e")
            let normalRange = NSRange(location: 0, length: strTitle.length - 1)
            let attributedString = NSMutableAttributedString(string: cell.mLblLineNumber.text!)
            
            if bidPeriod.isFABid() {
                
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: normalRange)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: tickRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
                }
            } else {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            }
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10.0), range: tickRange)
            cell.mLblLineNumber.attributedText = attributedString
        }
        if line.isETOPSRES?.boolValue == true {
            cell.mLblLineNumber.text = cell.mLblLineNumber.text! + ("Re")
            let strTitle:NSString = cell.mLblLineNumber.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "Re")
            let normalRange = NSRange(location: 0, length: strTitle.length - 2)
            let attributedString = NSMutableAttributedString(string: cell.mLblLineNumber.text!)
            
            if bidPeriod.isFABid() {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: normalRange)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: tickRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
                }
            } else {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            }
            //attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10.0), range: tickRange)
            cell.mLblLineNumber.attributedText = attributedString
    
        }
       else if !bidPeriod.isFABid() && bidPeriod.isSecondRoundBid() && (line.type == BILineType.MixedLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsMixed.rawValue.asNSNumber) {
            cell.mLblLineNumber.text = cell.mLblLineNumber.text! + ("mR")
            let strTitle:NSString = cell.mLblLineNumber.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "mR")
//            let normalRange = NSRange(location: 0, length: strTitle.length - 2)
            let attributedString = NSMutableAttributedString(string: cell.mLblLineNumber.text!)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            //attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10.0), range: tickRange)
            cell.mLblLineNumber.attributedText = attributedString
    
        }
        else if bidPeriod.isFABid() && bidPeriod.isSecondRoundBid() {
                    let reserveTypeSuffixMap: [NSNumber: String] = [
                        BIFaReserveLineType.SnrAMres.rawValue.asNSNumber: "sa",
                        BIFaReserveLineType.SnrPMres.rawValue.asNSNumber: "sp",
                        BIFaReserveLineType.JnrAMres.rawValue.asNSNumber: "ja",
                        BIFaReserveLineType.JnrPMres.rawValue.asNSNumber: "jp",
                        BIFaReserveLineType.JnrLateRes.rawValue.asNSNumber: "jl"
                    ]

                    if let faReserveLineType = line.faReserveLineType,
                       let suffix = reserveTypeSuffixMap[faReserveLineType] {
                        cell.mLblLineNumber.text = cell.mLblLineNumber.text! + suffix
                        let strTitle: NSString = cell.mLblLineNumber.text! as NSString
                        let tickRange: NSRange = strTitle.range(of: suffix)
//                        let normalRange = NSRange(location: 0, length: strTitle.length - 2)
                        let attributedString = NSMutableAttributedString(string: cell.mLblLineNumber.text!)
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
                        //attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
                        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10.0), range: tickRange)
                        cell.mLblLineNumber.attributedText = attributedString
                    }
                }
        
       else if line.type == BILineType.ReserveLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsReserve.rawValue.asNSNumber{
            cell.mLblLineNumber.text = cell.mLblLineNumber.text! + ("R")
            let strTitle:NSString = cell.mLblLineNumber.text! as NSString
            let tickRange: NSRange = strTitle.range(of: "R")
            let normalRange = NSRange(location: 0, length: strTitle.length - 2)
            let attributedString = NSMutableAttributedString(string: cell.mLblLineNumber.text!)
            
            if bidPeriod.isFABid() {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: normalRange)
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: tickRange)
                } else {
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
                }
            } else {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            }
            //attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: tickRange)
            attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10.0), range: tickRange)
            cell.mLblLineNumber.attributedText = attributedString
        }
        cell.handlingFreezingCondition()
        if setupLineValues {
            // Line values.
            let lineValuesKey: String = CBLineValuesMenuController.lineValuesKey(for: bidPeriod)
            let lineValuesToDisplay:NSMutableArray = NSMutableArray()
            if (UserDefaults.standard.object(forKey: lineValuesKey) != nil) {
                let arr = UserDefaults.standard.value(forKey: lineValuesKey) as! [Any]
                lineValuesToDisplay.addObjects(from: arr)
            }
            for i in 0..<lineValuesToDisplay.count {
                let tag: Int = LineValueViewTag +  i * 10
                let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
                let val = lineValuesToDisplay[i] as! Int
                let valueType = NSInteger(val)
                if lineValueView == nil {
                    print("linevalueView is nil")
                } else {
                    CBLineValuesMenuController.setLineValueView(lineValueView!, with: line, forType: CBLineValueTypes(rawValue: valueType)!, bidPeriod: bidPeriod)
                }
                lineValueView?.alpha = 1.0
                if CBLineValueTypes(rawValue: valueType) == .VacationPayDifference {
                    if line.vCBVacPay?.doubleValue as? Double ?? 0.0 > 0.0 || line.orderedTrips.count == 0 {
                        lineValueView?.alpha = 1.0
                    } else {
                        lineValueView?.alpha = 0
                    }
                } else {
                    lineValueView?.alpha = 1.0
                }
            }
            for i in lineValuesToDisplay.count..<5 {
                let tag: Int = LineValueViewTag + i * 10
                let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
                lineValueView?.alpha = 0.0
            }
        } else {
            // Set any unused lineValueViews to transparent
            for i in lineValuesToDisplay.count..<5 {
                let tag: Int = LineValueViewTag + i * 10
                let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
                lineValueView?.alpha = 0.0
            }
        }
        cell.scrollLineValue.alpha = 1.0
    }
    
    func cellTypeForRow(at indexPath: IndexPath) -> CBBidLineTableCellType {
        var cellType = CBBidLineTableCellType.cbPlainBidLineTableCellType as CBBidLineTableCellType
        var line: BILine? = nil
        line = self.linesArray[indexPath.row]
        
        if insertionIndex == indexPath.row {
            if insertAbove {
                if line?.markerTitle != nil {
                    cellType = CBBidLineTableCellType.cbMarkerInsertAboveBidLineTableCellType
                } else {
                    cellType = CBBidLineTableCellType.cbInsertAboveBidLineTableCellType
                }
            } else {
                if line?.markerTitle != nil {
                    cellType = CBBidLineTableCellType.cbMarkerInsertBelowBidLineTableCellType
                } else {
                    cellType = CBBidLineTableCellType.cbInsertBelowBidLineTableCellType
                }
            }
        } else if line?.markerTitle != nil {
            cellType = CBBidLineTableCellType.cbMarkerBidLineTableCellType
        }
        return cellType
    }
    
    
    @objc func SingleTap(sender:UITapGestureRecognizer) {
        // Create a storyboard and instantiate the 'CBBidLineMenuController' view controller

        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "CBBidLineMenuController") as! CBBidLineMenuController
        refreshViewController.delegate = self
        refreshViewController.bidPeriod = bidPeriod
        refreshViewController.modalPresentationStyle = .popover
        // Get the tapped cell's index path and tag
        let indexPath = IndexPath(row: (sender.view?.tag)!, section: 0)
        let index :Int = Int((sender.view?.tag)!)
        refreshViewController.selectedIndexpath = index
        refreshViewController.selectedIndexpathValue = indexPath
        let line = self.linesArray[indexPath.row]
        refreshViewController.isCellHasMarker = (line.markerTitle != nil) ? true : false
        refreshViewController.isCellIsFrozen = (line.isFrozen?.boolValue)!
        let isFaFirstRoundBid: Bool = bidPeriod.isFABid() && bidPeriod.isFirstRoundBid()
        refreshViewController.isFaFirstRoundBid = isFaFirstRoundBid
        refreshViewController.isFaMrtLineExists = (bidPeriod.faMrtLineExists?.boolValue)!
        refreshViewController.isFaReserveLineExists = (bidPeriod.faReserveLineExists?.boolValue)!
        refreshViewController.line = line
        refreshViewController.fromBidlist = true
        // Initialize 'newSize' with the content size of 'refreshViewController'
        var newSize: CGSize = refreshViewController.contentSizeOf
        // SCENARIO 1
        // Determine the size of the popover based on scenarios
        if (line.isFrozen != 0) {
            if refreshViewController.isCellHasMarker {
                newSize.height = 44.0 * 4 + 6.0
            } else {
                newSize.height = 44.0 * 3 + 6.0
            }
        }
        // SCENARIO 2
        else {
            if refreshViewController.isCellHasMarker {
                if isFaFirstRoundBid && !(bidPeriod.faMrtLineExists != 0) || !(bidPeriod.faReserveLineExists != 0) {
                    if !(bidPeriod.faMrtLineExists != 0) && !(bidPeriod.faReserveLineExists != 0) {
                        newSize.height = 44.0 * 9 + 4.0 * 6.0
                    } else {
                        newSize.height = 44.0 * 8 + 4.0 * 6.0
                    }
                } else {
                    newSize.height = 44.0 * 7 + 3.0 * 6.0
                }
            }
            else {
                if isFaFirstRoundBid && !(bidPeriod.faMrtLineExists != 0) || !(bidPeriod.faReserveLineExists != 0) {
                    if !(bidPeriod.faMrtLineExists != 0) && !(bidPeriod.faReserveLineExists != 0) {
                        newSize.height = 44.0 * 8 + 4.0 * 6.0
                    } else {
                        newSize.height = 44.0 * 7 + 4.0 * 6.0
                    }
                } else {
                    newSize.height = 44.0 * 6 + 3.0 * 6.0
                }
            }
        }
        // Get the cell based on whether the calendar view is selected
        let cell: UITableViewCell!
        if UserDefaults.standard.bool(forKey: "isSelectedCalanderView")  {
            cell = tableViewNormalView.cellForRow(at: indexPath) as! CBBidListCalenderViewCell
        }else {
            cell = tableViewNormalView.cellForRow(at: indexPath) as! CBBidlineViewTableViewCell
        }
        // Show the popover with an upward arrow direction
        refreshViewController.showPopover(sourceView:cell)
        refreshViewController.arrowDirection = UIPopoverArrowDirection.up
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
            cell.setMarkerText(line.markerTitle)
            cell.bidListCellCalendarDaysArr = bidListCalenderDays
            cell.selectionStyle = .none
            configureCell(cell, at: indexPath)
            cell.accessoryType = .none
            cell.showsReorderControl = true
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CBBidListCalenderViewCell",for: indexPath)as! CBBidListCalenderViewCell
        cell.setMarkerText(line.markerTitle)
        cell.delegate = self
        cell.indexPath = indexPath
        cell.bidListCellCalendarDaysArr = bidListCalenderDays
        cell.selectionStyle = .none
        configureCalenderCell(cell, at: indexPath)
        cell.accessoryType = .none
        cell.showsReorderControl = true
        cell.fromScrachpadView = true
        cell.refreshTripButtons(highlightFlag: true, calendarWidth: self.view.frame.size.width - 160)
        
        cell.tripButtonActionBlock = {(_ tripButton: CBTripButton) -> Void in
            DispatchQueue.main.async {
                self.showTripTextPopover(for: tripButton)
            }        }
        
        return cell
    }
    
    func configureCalenderCell(_ cell: CBBidListCalenderViewCell, at indexPath: IndexPath) {
        let line = self.linesArray[indexPath.row]
        
        // Check if award sorting is enabled and if the line should be hidden
        if (self.bidPeriod.isAwardSortOn ?? 0).boolValue {
            if (line.faBidLineMrt ?? 0).boolValue || (line.faBidLineReserve ?? 0).boolValue {
                cell.isHidden = true
            } else {
                cell.isHidden = false
                count += 1
            }
        } else {
            cell.isHidden = false
            count += 1
        }
      //  cell.cellNoLabel.text = "\(count)"
        cell.cellNoLabel.text = "\(indexPath.row + 1)"
        cell.lineLabel.text = String(describing: line.number!)
        var setupLineValues = true
        // Check if the background view of the cell is nil and configure it

        if nil == cell.backgroundView {
            cell.backgroundView = UIView(frame: cell.bounds)
            cell.backgroundView?.backgroundColor = UIColor.appColor(.contentBgColor)
            cell.calendarData = bidListCalendarData
            let objCMutableArray = NSMutableArray(array: bidListCalenderDays)
            cell.calendarDaysCount = objCMutableArray
        }
        // Check if it's a flight attendant bid and customize the cell accordingly

        if bidPeriod.isFABid() && line.faPosition?.intValue != BIFaPosition.FaPositionNA.rawValue {
            cell.lineLabel.textColor = .white
            if line.faPosition?.intValue == BIFaPosition.FaPositionA.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosAColor
                cell.lineLabel.text = cell.lineLabel.text! + ("A")
            } else if line.faPosition?.intValue == BIFaPosition.FaPositionB.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosBColor
                cell.lineLabel.text = cell.lineLabel.text! + ("B")
            } else if line.faPosition?.intValue == BIFaPosition.FaPositionC.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosCColor
                cell.lineLabel.text = cell.lineLabel.text! + ("C")
            } else if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                cell.positionCircleView.backgroundColor = CBColor.faPosDColor
                cell.lineLabel.text = cell.lineLabel.text! + ("D")
            } else {
                cell.positionCircleView.backgroundColor = UIColor.purple
                cell.lineLabel.text = cell.lineLabel.text! + ("M")
            }
            cell.positionCircleView.layer.cornerRadius = cell.positionCircleView.frame.height / 2
            cell.positionCircleView.alpha = 1.0
            
            // Check if award sorting is enabled and highlight the cell if needed

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
        } else {
            cell.positionCircleView.alpha = 0.0
            // Check if award sorting is enabled and highlight the cell if needed

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
        // Set cell type, bid period, and line for the cell

        cell.cellType = cellTypeForRow(at: indexPath)
        cell.bidPeriod = self.bidPeriod
        cell.line = line
        cell.refreshCalendar()
        // Check if the cell is selected and update its appearance

        let arr = selectedCellIndexPaths
        if arr.contains(indexPath) {
            cell.selectButton(true)
            cell.selectionToggleButton.isSelected = true
        } else {
            cell.selectButton(false)
            cell.selectionToggleButton.isSelected = false
        }
        // Set the tag for the selection toggle button

        cell.selectionToggleButton.tag = indexPath.row
        // Configure the user flag control
        cell.userFlagControl.backgroundColor = CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType(rawValue: Int(truncating: (line.userFlagType)!))!)
        if CBUserFlagType.none.rawValue == line.userFlagType?.intValue {
            cell.userFlagControl.alpha = 1
        } else {
            cell.userFlagControl.alpha = 1.0
        }
        // Handle cases related to MRT and Reserve Lines

        let reserveMrtLabel = cell.viewWithTag(kReserveMrtLabelTag) as? UILabel
        let reserveMrtView = cell.viewWithTag(kReserveMrtViewTag)
        
        cell.lineValuesContainerView.isHidden = false
        if bidPeriod.isFirstRoundBid() && bidPeriod.isFABid() {
            if (line.faBidLineMrt?.boolValue)! {
                cell.positionCircleView.isHidden = true
                cell.calendarCollectionView.isHidden = true
                cell.lineValuesContainerView.isHidden = true
                cell.lineLabel.isHidden = true
                reserveMrtLabel?.alpha = 1.0
                reserveMrtView?.alpha = 1.0
                reserveMrtLabel?.backgroundColor = CBColor.faPosBColor
                reserveMrtView?.backgroundColor = CBColor.faPosBColor
                cell.backgroundView?.backgroundColor = CBColor.faPosBColor
                reserveMrtLabel?.text = "MRT Line"
                setupLineValues = false
            } else if (line.faBidLineReserve?.boolValue)! {
                cell.positionCircleView.isHidden = true
                cell.calendarCollectionView.isHidden = true
                cell.lineLabel.isHidden = true
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
                cell.calendarCollectionView.isHidden = false
                cell.lineLabel.isHidden = false
                cell.contentView.backgroundColor = UIColor.appColor(.contentBgColor)
                cell.backgroundView?.backgroundColor = UIColor.appColor(.contentBgColor)
                reserveMrtLabel?.alpha = 0.0
                reserveMrtView?.alpha = 0.0
            }
        } else {
            cell.positionCircleView.isHidden = false
            cell.calendarCollectionView.isHidden = false
            cell.lineLabel.isHidden = false
            cell.backgroundView?.backgroundColor = UIColor.appColor(.contentBgColor)
            cell.contentView.backgroundColor = UIColor.appColor(.contentBgColor)
            reserveMrtLabel?.alpha = 0.0
            reserveMrtView?.alpha = 0.0
        }
        
        cell.handlingFreezingCondition()
        
        // Set Etops line
        cell.etopsTypeLabel.isHidden = true
        if line.isETOPS?.boolValue == true {
            cell.lineLabel.text = cell.lineLabel.text!
            cell.etopsTypeLabel.isHidden = false
            cell.etopsTypeLabel.text = "e"
            if bidPeriod.isFABid() {
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    cell.etopsTypeLabel.textColor = .white
                } else {
                    cell.etopsTypeLabel.textColor = .red
                }
            } else {
                cell.etopsTypeLabel.textColor = .red
            }
        }
        
        if line.isETOPSRES?.boolValue == true {
            cell.lineLabel.text = cell.lineLabel.text!
            cell.etopsTypeLabel.isHidden = false
            cell.etopsTypeLabel.text = "Re"
            if bidPeriod.isFABid() {
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    cell.etopsTypeLabel.textColor = .white
                } else {
                    cell.etopsTypeLabel.textColor = .red
                }
            } else {
                cell.etopsTypeLabel.textColor = .red
            }
        }
        else if !bidPeriod.isFABid() && bidPeriod.isSecondRoundBid() && (line.type == BILineType.MixedLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsMixed.rawValue.asNSNumber) {
            cell.lineLabel.text = cell.lineLabel.text!
            cell.etopsTypeLabel.isHidden = false
            cell.etopsTypeLabel.text = "mR"
            cell.etopsTypeLabel.textColor = .red
        }
        else if bidPeriod.isFABid() && bidPeriod.isSecondRoundBid() {
            let reserveTypeSuffixMap: [NSNumber: String] = [
                BIFaReserveLineType.SnrAMres.rawValue.asNSNumber: "sa",
                BIFaReserveLineType.SnrPMres.rawValue.asNSNumber: "sp",
                BIFaReserveLineType.JnrAMres.rawValue.asNSNumber: "ja",
                BIFaReserveLineType.JnrPMres.rawValue.asNSNumber: "jp",
                BIFaReserveLineType.JnrLateRes.rawValue.asNSNumber: "jl"
            ]
            
            if let faReserveLineType = line.faReserveLineType,
               let suffix = reserveTypeSuffixMap[faReserveLineType] {
                cell.lineLabel.text = cell.lineLabel.text!
                cell.etopsTypeLabel.isHidden = false
                cell.etopsTypeLabel.text = suffix
                cell.etopsTypeLabel.textColor = .red
            }
        }
        else if line.type == BILineType.ReserveLine.rawValue.asNSNumber || line.type == BILineType.NonEtopsReserve.rawValue.asNSNumber{
            cell.lineLabel.text = cell.lineLabel.text!
            cell.etopsTypeLabel.isHidden = false
            cell.etopsTypeLabel.text = "R"
            if bidPeriod.isFABid() {
                if line.faPosition?.intValue == BIFaPosition.FaPositionD.rawValue {
                    cell.etopsTypeLabel.textColor = .white
                } else {
                    cell.etopsTypeLabel.textColor = .red
                }
            } else {
                cell.etopsTypeLabel.textColor = .red
            }
        }
        
        if setupLineValues {
            // Line values.
            let lineValuesKey: String = CBLineValuesMenuController.lineValuesKey(for: bidPeriod)
            let lineValuesToDisplay:NSMutableArray = NSMutableArray()
            if (UserDefaults.standard.object(forKey: lineValuesKey) != nil) {
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
                let tag: Int = LineValueViewTag + i * 10
                let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
                lineValueView?.alpha = 0.0
            }
        } else {
            // Set any unused lineValueViews to transparent
            for i in lineValuesToDisplay.count..<5 {
                let tag: Int = LineValueViewTag + i * 10
                let lineValueView = cell.viewWithTag(tag) as? CBLineValueView
                lineValueView?.alpha = 0.0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "CBBidLineMenuController") as! CBBidLineMenuController
        refreshViewController.delegate = self
        refreshViewController.bidPeriod = bidPeriod
        refreshViewController.modalPresentationStyle = .popover
        let index :Int = indexPath.row
        refreshViewController.selectedIndexpath = index
        refreshViewController.selectedIndexpathValue = indexPath
        let line = self.linesArray[indexPath.row]
        refreshViewController.isCellHasMarker = (line.markerTitle != nil) ? true : false
        refreshViewController.isCellIsFrozen = (line.isFrozen?.boolValue)!
        let isFaFirstRoundBid: Bool = bidPeriod.isFABid() && bidPeriod.isFirstRoundBid()
        refreshViewController.isFaFirstRoundBid = isFaFirstRoundBid
        refreshViewController.isFaMrtLineExists = (bidPeriod.faMrtLineExists?.boolValue)!
        refreshViewController.isFaReserveLineExists = (bidPeriod.faReserveLineExists?.boolValue)!
        refreshViewController.line = line
        refreshViewController.fromBidlist = true
        var newSize: CGSize = refreshViewController.contentSizeOf
        
        // SCENARIO 1
        if (line.isFrozen != 0) {
            if refreshViewController.isCellHasMarker {
                newSize.height = 44.0 * 4 + 6.0
            } else {
                newSize.height = 44.0 * 3 + 6.0
            }
        }
        // SCENARIO 2
        else {
            if refreshViewController.isCellHasMarker {
                if isFaFirstRoundBid && !(bidPeriod.faMrtLineExists != 0) || !(bidPeriod.faReserveLineExists != 0) {
                    if !(bidPeriod.faMrtLineExists != 0) && !(bidPeriod.faReserveLineExists != 0) {
                        newSize.height = 44.0 * 9 + 4.0 * 6.0
                    } else {
                        newSize.height = 44.0 * 8 + 4.0 * 6.0
                    }
                } else {
                    newSize.height = 44.0 * 7 + 3.0 * 6.0
                }
            }
            else {
                if isFaFirstRoundBid && !(bidPeriod.faMrtLineExists != 0) || !(bidPeriod.faReserveLineExists != 0) {
                    if !(bidPeriod.faMrtLineExists != 0) && !(bidPeriod.faReserveLineExists != 0) {
                        newSize.height = 44.0 * 8 + 4.0 * 6.0
                    } else {
                        newSize.height = 44.0 * 7 + 4.0 * 6.0
                    }
                } else {
                    newSize.height = 44.0 * 6 + 3.0 * 6.0
                }
            }
        }
        let cell: UITableViewCell!
        if UserDefaults.standard.bool(forKey: "isSelectedCalanderView")  {
            cell = tableViewNormalView.cellForRow(at: indexPath) as! CBBidListCalenderViewCell
        }else {
            cell = tableViewNormalView.cellForRow(at: indexPath) as! CBBidlineViewTableViewCell
        }
        refreshViewController.showPopover(sourceView:cell)
        refreshViewController.arrowDirection = UIPopoverArrowDirection.up
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var heightForRow: CGFloat = 65;
        
        if UserDefaults.standard.bool(forKey: "isSelectedCalanderView") {
            heightForRow = kCBBidLineTableCellMainViewHeightCalendarView
        }
        
        if insertionIndex == indexPath.row {
            heightForRow += kCBBidLineTableCellInsertionHeight
        }
        if linesArray.count <=  indexPath.row {
            return 100
        }
        
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
    
    // Handle row reordering logic
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Do nothing until the move actually finishes
        if sourceIndexPath == destinationIndexPath{
            return
        }
        if isAwardSort || isSubmitSort {
            removeASortUI()
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            return
        }
        self.bidPeriod.isBidListSortOn = NSNumber(value: false)
        self.bidPeriod.deleteAllBidListSorts()
        let originRow: Int = sourceIndexPath.row
        let destRow: Int = destinationIndexPath.row
        let startLine = linesArray[sourceIndexPath.row]
        var markerTitle = [String]()
        if (startLine.isFrozen != 0) {
            tableViewNormalView.reloadData()
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
        
        if let rows = affectedRows as? [BILine] {
            for index in 0..<rows.count {
                let item = rows[index]
                print("Index: \(index), Item: \(item)")
                if item.markerTitle != nil &&  item.markerTitle != ""{
                    markerTitle.append(item.markerTitle!)
                }
                else{
                    markerTitle.append("")
                }
            }
        }
        let insertionIndex: Int = destRow
        let removedIndex: Int = originRow
        let row: Int = ind.row
        let line = affectedRows[row] as? BILine
        // Attempt to preserve marker by moving it to line below (if one
        // exists below line and that line does not have a marker).
        var oldMarkerTitle: String? = nil
        if (line?.markerTitle != nil && line?.markerTitle != "") {
            oldMarkerTitle = line?.markerTitle
        }
        line?.markerTitle = nil
        // If inserting above a line that has a marker, transfer marker to
        // moved line.
        var insertionPointLine: BILine? = affectedRows.object(at: insertionIndex) as? BILine
        if insertionPointLine?.markerTitle != nil &&  insertionPointLine?.markerTitle != ""{
            line?.markerTitle = insertionPointLine?.markerTitle
            insertionPointLine?.markerTitle = nil
        }
        affectedRows.removeObject(at: removedIndex)
        let insertedIndexes = NSIndexSet(indexesIn: NSRange(location: insertionIndex, length: insertionIndex))
        if let aLine = line {
            affectedRows.insert(aLine, at: insertionIndex)
        }

        for i in firstRow...lastRow {
            let line: BILine? = affectedRows.object(at: i) as? BILine
            line?.bidOrder = i + 1 as NSNumber
        }
        // Add the old marker to the new line at the moved line's previous row
        let newLine: BILine? = affectedRows.object(at: row) as? BILine
        if newLine?.markerTitle == nil {
            newLine?.markerTitle = oldMarkerTitle
        }
        if let rows = affectedRows as? [BILine] {
            for index in 0..<rows.count {
                let item = rows[index]
                item.markerTitle = nil
                print("Index: \(index), Item: \(item)")
                if markerTitle[index] != ""{
                    item.markerTitle = markerTitle[index]
                }
            }
        }
        previousInsertionIndex = self.insertionIndex
        if originRow > insertionIndex && destRow < insertionIndex {
            self.insertionIndex += 1
        }
        if originRow < insertionIndex && destRow > insertionIndex {
            self.insertionIndex -= 1
        }
        selectedCellIndexPaths.removeAllObjects()
        bidPeriod.managedObjectContext!.undoManager?.setActionName("Move Line")
        NotificationCenter.default.post(name: NSNotification.Name("SortBidListAction"), object: self)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
 
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        //No reordering in Freeze line
        if linesArray.count <=  indexPath.row {
            return false
        }
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
    
    //For handling the reorder UI for calendar view
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        for view in cell.subviews {
            print(view.classForCoder.description())
            if view.self.description.contains("UITableViewCellReorderControl") {
                view.removeFromSuperview()
                let width: CGFloat = 30.0
                if UserDefaults.standard.bool(forKey: "isSelectedCalanderView")  {
                    view.frame = CGRect(x: cell.frame.maxX - 25, y: 50, width: width, height: 150)
                }
                cell.addSubview(view)
                view.backgroundColor = .clear
            }
        }
    }
    
}
