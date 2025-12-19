//
//  CBComutabilityRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

enum CommutabilityType: Int {
    case filter = 0
    case sort
}


class CBComutabilityRuleCell: UITableViewCell, CommutabilityCellDelegate {
    
    @IBOutlet weak var objFourthCell: UIButton!
    @IBOutlet weak var objfirstCell: UIButton!
    @IBOutlet weak var objSecondCell: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var objThirdCell: UIButton!
    @IBOutlet weak var Removecell: UIButton!
    
    var filterRule: BIFilterRule?
    var objcommutability: Commutability?
    var fourthCellValueArray: NSMutableArray?
    let context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    //firstCellbtnAction
    @IBAction func firstCellbtnAction(_ sender: Any) {
        var valuesArray = NSArray()
        valuesArray = CBUtils.commutabilitySecondCellValue() as NSArray
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshViewController.popOverType = PopoverViewType.CommutabilityFirstCell
        refreshViewController.selectedValue = (sender as! UIButton).currentTitle ?? ""
        refreshViewController.Commutabilitydelegate = self
        refreshViewController.arrCellParameters = valuesArray
        refreshViewController.modalPresentationStyle = .popover
        refreshViewController.showPopover(sourceView: objfirstCell)
    }
    
    @IBAction func secondCellbtnAction(_ sender: Any) {
        var valuesArray = NSArray()
        valuesArray = CBUtils.CommutabilityThirdCell() as NSArray
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshViewController.popOverType = PopoverViewType.CommutabilitySecondCell
        refreshViewController.selectedValue = (sender as! UIButton).currentTitle ?? ""
        refreshViewController.Commutabilitydelegate = self
        refreshViewController.arrCellParameters = valuesArray
        refreshViewController.modalPresentationStyle = .popover
        refreshViewController.showPopover(sourceView: objSecondCell)
    }
    
    @IBAction func thirdCellbtnAction(_ sender: Any) {
        var valuesArray = NSArray()
        valuesArray = CBUtils.CommutabilityFourthCell() as NSArray
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshViewController.popOverType = PopoverViewType.CommutabilityThirdCell
        refreshViewController.selectedValue = (sender as! UIButton).currentTitle ?? ""
        refreshViewController.Commutabilitydelegate = self
        refreshViewController.arrCellParameters = valuesArray
        refreshViewController.modalPresentationStyle = .popover
        refreshViewController.showPopover(sourceView: objThirdCell)
    }
    
    @IBAction func fourthCellbtnAction(_ sender: Any) {
        fourthCellValueArray?.removeAllObjects()
        fourthCellValueArray = NSMutableArray()
        var i = 5
        while i <= 100 {
            fourthCellValueArray?.add(i)
            i += 5
        }
        
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshViewController.popOverType = PopoverViewType.CommutabilityFourthCell
        refreshViewController.selectedValue = (sender as! UIButton).currentTitle ?? ""
        refreshViewController.Commutabilitydelegate = self
        refreshViewController.arrCellParameters = fourthCellValueArray!
        refreshViewController.modalPresentationStyle = .popover
        refreshViewController.showPopover(sourceView: objFourthCell)
    }
    
    @IBAction func titleBtnAction(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("ShowCommutabilityFilterView"), object: nil)
    }
    
    func firstCellAction(_ value: Int) {
        objcommutability?.secondCellValue = value as NSNumber
        try? self.context?.save()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    func secondCellAction(_ value: Int) {
        objcommutability?.thirdCellValue = value as NSNumber
        try? self.context?.save()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func thirdCellAction(_ value: Int) {
        objcommutability?.type = value as NSNumber
        try? self.context?.save()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func fourthCellAction(_ value: Int) {
        objcommutability?.value = fourthCellValueArray?.object(at: value) as? NSNumber
        try? self.context?.save()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func configureCommutabilityCell() {
        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.filter.rawValue)
        let fetchedObjects = (try? self.context!.fetch(fetchRequest)) ?? []
        if fetchedObjects.count > 0 {
            objcommutability = fetchedObjects[0]
            
            let secondValue: Int = (objcommutability!.secondCellValue?.intValue)! - 1
            objfirstCell.setTitle(CBUtils.commutabilitySecondCellValue()[secondValue], for: .normal)
            
            let thirdValue: Int = (objcommutability!.thirdCellValue?.intValue)! - 1
            objSecondCell.setTitle(CBUtils.CommutabilityThirdCell()[thirdValue], for: .normal)
            
            let type: Int = (objcommutability!.type?.intValue)! - 1
            objThirdCell.setTitle(CBUtils.CommutabilityFourthCell()[type], for: .normal)
            var val: String? = nil
            if let aKey = objcommutability?.value {
                val = String(format: "%@%%", aKey )
            }
            objFourthCell.setTitle(val, for: .normal)
            let commutabilityCity = objcommutability?.city
            
            lblTitle.text = String(format: "Commut%% (%@)", commutabilityCity!)
//            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    @IBAction func deleteCellRow(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod!.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod!.isStateFileModifiedToSync = true
        
        let resultsFilter = ((CBGlobalMethods.shared.selectedBidPeriod!.lineFilters!.allObjects) as NSArray).filtered(using: NSPredicate(format: "category == 33")) as! [BIFilterRule]
        
        for resultFilter in resultsFilter {
            self.context?.delete(resultFilter)
        }
        
        if filterRule?.ruleHighlightsTrips() == true {
            filterRule?.deHighlightTrips()
        }
        
        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "commutableType == 0")
        let results = (try? self.context!.fetch(fetchRequest))
        for result in results ?? [] {
            self.context!.delete(result)
        }
        
        let fetchCommuteTime: NSFetchRequest<CommuteTime> = CommuteTime.fetchRequest()
        let commuteTimes: [CommuteTime] = (try? self.context!.fetch(fetchCommuteTime)) ?? []
        for commuteTime in commuteTimes {
            self.context!.delete(commuteTime)
        }
        
        fetchRequest.predicate = NSPredicate(format: "commutableType == 1")
        let resultsorts = (try? self.context!.fetch(fetchRequest))
        if resultsorts?.count == 0 {
            print("commute Sort not applied")
            for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
                line.totalCommutes = 0
                line.commutableBacks = 0
                line.commutableFronts = 0
                line.commutabilityFront = 0
                line.commutabilityBack = 0
                line.commutabilityOverall = 0
                
//                 to remove trip highlight
                var tripStartDate: Date?
                var workBlockStartDate: Date?
                var dateStatus = false

                for case let workBlock as WorkBlockList in line.orderedWorkBlocks {
                    for case let trip as BITrip in line.orderedTrips {

                        tripStartDate = getOnlyStartDateOfTrip(trip)
                        workBlockStartDate = getOnlyStartDateOfWorkBlock(workBlock.startDateTime!)

                        if let tripStartDate = tripStartDate,
                           let workBlockStartDate = workBlockStartDate {

                            dateStatus = dayDateCheck(tripStartDate, isBetween: workBlockStartDate, and: workBlock.endDateOnly!)

                            if dateStatus {
                                trip.highlightCount = NSNumber(
                                    value: (trip.highlightCount?.intValue ?? 0) - 1
                                )
                                trip.bidListHighlighted = false
                            }
                        }
                    }
                }

            }
            try? self.context?.save()
        }
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func getOnlyStartDateOfTrip(_ trip: BITrip) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        var calendarWithSettings = calendar
        calendarWithSettings.locale = Locale.current
        calendarWithSettings.timeZone = TimeZone(identifier: "GMT")!

        let dateComponents = calendarWithSettings.dateComponents(
            [.year, .month, .day],
            from: trip.startDate!
        )

        return calendarWithSettings.date(from: dateComponents)
    }

    func getOnlyStartDateOfWorkBlock(_ date: Date) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        var calendarWithSettings = calendar
        calendarWithSettings.locale = Locale.current
        calendarWithSettings.timeZone = TimeZone(identifier: "GMT")!

        let dateComponents = calendarWithSettings.dateComponents(
            [.year, .month, .day],
            from: date
        )

        return calendarWithSettings.date(from: dateComponents)
    }

    func dayDateCheck(_ date: Date, isBetween beginDate: Date, and endDate: Date) -> Bool {
        if date.compare(beginDate) == .orderedAscending {
            return false
        }

        if date.compare(endDate) == .orderedDescending {
            return false
        }

        return true
    }

}
