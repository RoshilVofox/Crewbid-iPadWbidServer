//
//  BILinesManager.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 23/07/25.
//

import Foundation
import CoreData


let BILinesManagerFilteredLinesValueKey = "filteredLines"
let BILinesManagerBidLinesValueKey = "bidLines"

class BILinesManager: NSObject {

    var managedObjectContext: NSManagedObjectContext
    var bidPeriod: BIBidPeriod?

    var filteredLines: NSMutableArray
    var bidLines: NSMutableArray

    var contextChangeObserver: Any?
    var lineEntityPredicate: NSPredicate?
    var filterEntityPredicate: NSPredicate?
    var sortEntityPredicate: NSPredicate?
    var filterRules: NSMutableSet
    var lineSorts: NSMutableSet
    var orderSorts: [NSSortDescriptor]
    var lineSortsEntityPredicate: NSPredicate
    var filterRulesEntityPredicate: NSPredicate
    var lineIsFilteredPredicate: NSPredicate?
    var lineIsBidPredicate: NSPredicate?
    var lineTypeSort: NSSortDescriptor
    var lineNumberSort: NSSortDescriptor

//    override init() {
//        fatalError("Use init(managedObjectContext:) instead.")
//    }

    init?(managedObjectContext context: NSManagedObjectContext?) {
        guard let context = context else {
            print("context cannot be nil")
            return nil
        }
        
        
        self.managedObjectContext = context
        
        self.orderSorts = [NSSortDescriptor(key: "order", ascending: true)]
        self.lineSortsEntityPredicate = NSPredicate(format: "entity.name == %@", BILineSortEntityName)
        self.filterRulesEntityPredicate = NSPredicate(format: "entity.name == %@", BIFilterRuleEntityName)
        self.lineTypeSort = NSSortDescriptor(key: "type", ascending: true)
        self.lineNumberSort = NSSortDescriptor(key: "number", ascending: true)
        self.filteredLines = NSMutableArray()
        self.bidLines = NSMutableArray()
        self.filterRules = NSMutableSet()
        self.lineSorts = NSMutableSet()
        super.init()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BidPeriod")
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count != 1 {
                print("No bid period or more than one period - found \(results.count) bid periods")
            }
            self.bidPeriod = results.first as? BIBidPeriod
        } catch {
            print("bid period fetch failed: \(error.localizedDescription)")
        }

        // Fetch all lines
        let lineFetch = NSFetchRequest<NSFetchRequestResult>(entityName: BILineEntityName)
        lineFetch.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        var lineResults: [Any] = []

        do {
            lineResults = try context.fetch(lineFetch)
            self.filteredLines = []
            self.bidLines = []
        } catch {
            print("fetch of lines ordered by number failed: \(error.localizedDescription)")
            return
        }

        if self.bidPeriod?.firstLineNumber == nil {
            self.bidPeriod?.firstLineNumber = 1
        }

        if let filteredLineNumbers = self.bidPeriod?.filteredLineNumbers {
            for lineNumber in filteredLineNumbers {
                let index = (lineNumber as AnyObject).intValue - (self.bidPeriod?.firstLineNumber?.intValue ?? 1)
                if index < lineResults.count {
                    if let line = lineResults[index] as? BILine {
                        self.filteredLines.add(line)
                    }
                }
            }
        }

        if let bidLineNumbers = self.bidPeriod?.bidLineNumbers {
            for lineNumber in bidLineNumbers {
                let index = (lineNumber as AnyObject).intValue - (self.bidPeriod?.firstLineNumber?.intValue ?? 1)
                if index < lineResults.count {
                    if let line = lineResults[index] as? BILine {
                        self.bidLines.add(line)
                    }
                }
            }
        }

        do {
            let ruleFetch = NSFetchRequest<NSFetchRequestResult>(entityName: BIFilterRuleEntityName)
            let ruleResults = try context.fetch(ruleFetch)
            self.filterRules = NSMutableSet(array: ruleResults.compactMap { $0 as? BIFilterRule })
        } catch {
            print("fetch for filter rules failed: \(error.localizedDescription)")
        }

        do {
            let sortFetch = NSFetchRequest<NSFetchRequestResult>(entityName: BILineSortEntityName)
            let sortResults = try context.fetch(sortFetch)
            self.lineSorts = NSMutableSet(array: sortResults.compactMap { $0 as? BILineSort })
        } catch {
            print("fetch for line sorts failed: \(error.localizedDescription)")
        }

        NotificationCenter.default.addObserver(self,selector: #selector(contextDidChange(_:)),name: .NSManagedObjectContextObjectsDidChange,object: context)

        BILinesManagerFilteredLinesValueKey.withCString { keyPtr in
            self.addObserver(self, forKeyPath: BILinesManagerFilteredLinesValueKey, options: [], context: UnsafeMutableRawPointer(mutating: keyPtr))
        }

        BILinesManagerBidLinesValueKey.withCString { keyPtr in
            self.addObserver(self, forKeyPath: BILinesManagerBidLinesValueKey, options: [], context: UnsafeMutableRawPointer(mutating: keyPtr))
        }

        self.lineEntityPredicate = NSPredicate(format: "entity.name == %@", BILineEntityName)
        self.filterEntityPredicate = NSPredicate(format: "entity.name == %@", BIFilterRuleEntityName)
        self.sortEntityPredicate = NSPredicate(format: "entity.name == %@", BILineSortEntityName)
    }

    deinit {
        self.removeObserver(self, forKeyPath: BILinesManagerFilteredLinesValueKey)
        self.removeObserver(self, forKeyPath: BILinesManagerBidLinesValueKey)
        NotificationCenter.default.removeObserver(self)
    }

    
    func removeLineFromFilteredLines(_ line: BILine) {
        let index = filteredLines.index(of: line)
        if index == NSNotFound {
            print("line \(line.number?.stringValue ?? "nil") not found in filtered lines")
            return
        }
        removeObjectFromFilteredLines(at: index)
    }
    
    func moveLineFromFilteredToBidLines(_ line: BILine) {
        // Each of these methods will broadcast KVO notifications
        removeLineFromFilteredLines(line)
        addLineToBidLines(line)
    }
    
    func moveAllFilteredLinesToBidLines() {
        willChangeValue(forKey: BILinesManagerBidLinesValueKey)
        bidLines.addObjects(from: filteredLines as! [Any])
        didChangeValue(forKey: BILinesManagerBidLinesValueKey)

        removeAllFilteredLines()
    }
    
    func removeLineFromBidLines(_ line: BILine) {
        let index = bidLines.index(of: line)
        if index == NSNotFound {
            print("line \(line.number?.stringValue ?? "nil") not found in filtered lines")
            return
        }
        removeObjectFromBidLines(at: index)
    }
    
    func removeAllBidLines() {
        willChangeValue(forKey: BILinesManagerBidLinesValueKey)
        bidLines.removeAllObjects()
        didChangeValue(forKey: BILinesManagerBidLinesValueKey)
    }
    
    func moveBidLine(fromIndex: Int, toIndex: Int) {
        // If indices are the same, do nothing
        guard fromIndex != toIndex else { return }

        let moveLine = bidLines[fromIndex]
        bidLines.remove(fromIndex)
        bidLines.insert(moveLine, at: toIndex)

        // If you want to trigger any model update manually:
        // updateBidPeriodBidLineNumbers()
    }
    
    func addLineToBidLines(_ line: BILine) {
        insertObject(line, inBidLinesAt: bidLines.count)
    }
    
    func removeAllFilteredLines() {
        willChangeValue(forKey: BILinesManagerFilteredLinesValueKey)
        filteredLines.removeAllObjects()
        didChangeValue(forKey: BILinesManagerFilteredLinesValueKey)
    }

    func addLinesToBidLines(_ lines: [BILine]) {
        willChangeValue(forKey: BILinesManagerBidLinesValueKey)
        bidLines.addObjects(from: lines)
        didChangeValue(forKey: BILinesManagerBidLinesValueKey)
    }

    @objc func contextDidChange(_ notification: Notification) {
        var needsFiltering = false
        var needsSorting = false

        guard let userInfo = notification.userInfo else { return }

        // Inserted objects
        if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
            // Inserted filter rules
            let insertedFilterRules = insertedObjects.filter { self.filterRulesEntityPredicate.evaluate(with: $0) }
            if !insertedFilterRules.isEmpty {
                self.filterRules.union(insertedFilterRules)
                needsFiltering = true
            }

            // Inserted line sorts
            let insertedLineSorts = insertedObjects.filter { self.lineSortsEntityPredicate.evaluate(with: $0) }
            if !insertedLineSorts.isEmpty {
                self.lineSorts.union(insertedLineSorts)
                needsSorting = true
            }
        }

        // Deleted objects
        if let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletedObjects.isEmpty {
            let deletedFilterRules = deletedObjects.filter { self.filterRulesEntityPredicate.evaluate(with: $0) }
            if !deletedFilterRules.isEmpty {
                self.filterRules.minus(deletedFilterRules)
                needsFiltering = true
            }

            let deletedLineSorts = deletedObjects.filter { self.lineSortsEntityPredicate.evaluate(with: $0) }
            if !deletedLineSorts.isEmpty {
                self.lineSorts.minus(deletedLineSorts)
                needsSorting = true
            }
        }

        // Updated objects
        if !needsFiltering && !needsSorting,
           let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
            
            let updatedLineSorts = updatedObjects.filter { self.lineSortsEntityPredicate.evaluate(with: $0) }
            if !updatedLineSorts.isEmpty {
                needsSorting = true
            }

            let updatedFilterRules = updatedObjects.filter { self.filterRulesEntityPredicate.evaluate(with: $0) }
            if !updatedFilterRules.isEmpty {
                needsFiltering = true
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let context = context {
            let contextKey = Unmanaged<NSString>.fromOpaque(context).takeUnretainedValue()

            if contextKey == BILinesManagerFilteredLinesValueKey as NSString {
                updateBidPeriodFilteredLineNumbers()
            } else if contextKey == BILinesManagerBidLinesValueKey as NSString {
                updateBidPeriodBidLineNumbers()
            }
        }
    }
    
    func updateBidPeriodFilteredLineNumbers() {
        let numbers = filteredLines.value(forKey: "number") as? [Any]
        bidPeriod?.filteredLineNumbers = numbers as? NSArray
    }

    func updateBidPeriodBidLineNumbers() {
        let numbers = bidLines.value(forKey: "number") as? [Any]
        bidPeriod?.bidLineNumbers = numbers as? NSArray
    }
    
    func updateFilteredLines() {
        willChangeValue(forKey: BILinesManagerFilteredLinesValueKey)

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: BILineEntityName)
        fetchRequest.predicate = self.filterRulesPredicate

        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            filteredLines.setArray(results)
            
            // Remove any lines that are already in bidLines
            filteredLines.removeObjects(in: bidLines as [AnyObject])
            
            // Sort, if needed
            if filteredLines.count > 0 {
                filteredLines.sort(using: orderedLineSortDescriptors())
            }
        } catch {
            NSLog("Fetch of filtered lines failed: \(error.localizedDescription)")
        }

        didChangeValue(forKey: BILinesManagerFilteredLinesValueKey)
    }
    
    func sortFilteredLines() {
        willChangeValue(forKey: BILinesManagerFilteredLinesValueKey)
        filteredLines.sort(using: orderedLineSortDescriptors())
        didChangeValue(forKey: BILinesManagerFilteredLinesValueKey)
    }
    
    var filterRulesPredicate: NSPredicate {
        let predicates = (filterRules.allObjects as NSArray).value(forKey: "predicate") as? [NSPredicate] ?? []
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    func orderedLineSortDescriptors() -> [NSSortDescriptor] {
        var orderedLineSorts: [NSSortDescriptor] = []
        // Add lineTypeSort
        orderedLineSorts.append(lineTypeSort)
        // Convert Set to NSArray to use sortedArray(using:)
        let sortedLineSorts = (lineSorts as NSSet)
            .sortedArray(using: orderSorts) as NSArray
        // Extract sortDescriptor from each BILineSort
        if let descriptors = sortedLineSorts.value(forKey: "sortDescriptor") as? [NSSortDescriptor] {
            orderedLineSorts.append(contentsOf: descriptors)
        }
        // Add lineNumberSort
        orderedLineSorts.append(lineNumberSort)
        return orderedLineSorts
    }
    
    var countOfFilteredLines: Int {
        return filteredLines.count
    }

    func getFilteredLines(_ buffer: UnsafeMutablePointer<BILine?>, range: NSRange) {
        // Ensure filteredLines is bridged to a Swift array of BILine
        guard let array = filteredLines as? [BILine] else { return }
        let start = range.location
        let end = range.location + range.length
        guard start >= 0, end <= array.count else { return }
        let subArray = array[start..<end]
        for (index, element) in subArray.enumerated() {
            buffer[index] = element
        }
    }
    
    func insertObject(_ anObject: BILine, inFilteredLinesAt index: Int) {
        filteredLines.insert(anObject, at: index)
    }
    
    func insertFilteredLines(_ filteredLineArray: [BILine], at indexes: IndexSet) {
        let indexArray = Array(indexes).sorted(by: >) // Descending order
        for (i, index) in indexArray.enumerated() {
            guard i < filteredLineArray.count else { break }
            filteredLines.insert(filteredLineArray[i], at: index)
        }
    }
    
    func removeObjectFromFilteredLines(at index: Int) {
        filteredLines.remove(index)
    }
    
    func removeFilteredLines(at indexes: IndexSet) {
        (filteredLines as AnyObject).removeObjects(at: indexes)
    }
    
    func replaceObjectInFilteredLines(at index: Int, with object: BILine) {
        filteredLines[index] = object
    }
    
    func replaceFilteredLines(at indexes: IndexSet, with filteredLineArray: [BILine]) {
        for (i, index) in indexes.enumerated() {
            filteredLines[index] = filteredLineArray[i]
        }
    }
    
    var countOfBidLines: Int {
        return bidLines.count
    }
    
    func getBidLines(in range: NSRange) -> [BILine] {
        let nsArray = bidLines as NSArray
        let subarray = nsArray.subarray(with: range)
        return subarray as? [BILine] ?? []
    }
    
    func objectInBidLines(at index: Int) -> BILine {
        return bidLines[index] as! BILine
    }
    
    func insertObject(_ anObject: BILine, inBidLinesAt index: Int) {
        bidLines.insert(anObject, at: index)
    }
    
    func insertBidLines(_ bidLineArray: [BILine], at indexes: IndexSet) {
        for (offset, index) in indexes.enumerated() {
            bidLines.insert(bidLineArray[offset], at: index)
        }
    }
    
    func removeObjectFromBidLines(at index: Int) {
        bidLines.remove(index)
    }
    
    func removeBidLines(at indexes: IndexSet) {
        bidLines.removeObjects(at: indexes)
    }
    
    func replaceObjectInBidLines(at index: Int, with newLine: BILine) {
        bidLines[index] = newLine
    }
    
    func replaceBidLines(at indexes: IndexSet, with bidLineArray: [Any]) {
        bidLines.replaceObjects(at: indexes, with: bidLineArray)
    }
    
    var year: NSNumber? {
        return bidPeriod?.year
    }

    var month: NSNumber? {
        return bidPeriod?.month
    }

    var base: String? {
        return bidPeriod?.base
    }

    var position: BICrewPosition? {
        guard let positionType = bidPeriod?.positionType?.intValue else { return nil }
        return BICrewPosition.crewPositionforType(BICrewPositionType(rawValue: positionType)!)
    }

    var round: NSNumber? {
        return bidPeriod?.round
    }
}
