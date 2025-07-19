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
    var managedObjectContext:NSManagedObjectContext?
    var bidPeriod = BIBidPeriod()
    var selectedCellIndexPath = NSMutableArray()
    var awardEmpNumArray:NSMutableArray?
    var awardLineNum:String?
    //A-Sort
    var isAwardSort = false
    var isSubmitSort = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func refreshLines(){
        self.loadBidLine()
        self.tableViewNormalView.reloadData()
    }
    
    func loadBidLine(){
        if self.selectedCellIndexPath.count != 0 {
            self.selectedCellIndexPath.removeAllObjects()
        }
        
        let linesFetch = NSFetchRequest<BILine>(entityName: "BILine")
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
                var bidListArray = NSMutableArray()
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
                
            }
        }
    }
    
    
    
    
    
    func setupVariables(){

    }
    
    @objc func updateBidList(_ notification: Notification? = nil) {
        
    }
    
    @IBAction func btnFiltersAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBFilterRulesTableVC") as! CBFilterRulesTableVC
        // Check if AppData.shared.isBidListSort is true
        if AppData.shared.isBidListSort == true {
            // Remove the existing child view controller if there is one
            if let currentChildVC = self.children.first {
                currentChildVC.willMove(toParent: nil)
                currentChildVC.view.removeFromSuperview()
                currentChildVC.removeFromParent()
            }
            
            // Update the sort flag
            AppData.shared.isBidListSort = false
            
            // Post a notification
            NotificationCenter.default.post(name: NSNotification.Name("SortBidListAction"), object: self)
            
            
            // Setup the new VC
            vc.view.frame = self.view.bounds
            vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.addChild(vc)
            
            // Perform flip transition from current view to the new VC's view
            UIView.transition(with: self.view, duration: 0.65, options: .transitionFlipFromLeft,
                              animations: {
                self.view.addSubview(vc.view)
            },
                              completion: { _ in
                vc.didMove(toParent: self)
            })
        } else {
            self.navigationController?.pushViewController(vc, animated: false)
            UIView.transition(from: self.view, to: vc.view, duration: 0.65, options: [.transitionFlipFromLeft])
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CBBidListCalenderViewCell",for: indexPath)as! CBBidListCalenderViewCell
        return cell
    }
}
