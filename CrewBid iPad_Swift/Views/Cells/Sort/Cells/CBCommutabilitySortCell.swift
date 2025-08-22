//
//  CBCommutabilitySortCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

class CBCommutabilitySortCell: UITableViewCell {
    
    @IBOutlet weak var CommutabilitySegmentControl: UISegmentedControl!
    @IBOutlet weak var btnTitleCommutability: UIButton!
    @IBOutlet weak var lblTitleCommutability: UIButton!
    @IBOutlet weak var btnTitle: UIButton!
    var ObjcommutabilitySort: Commutability!
    
    var lineSort1: BILineSort!
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    
    var lineSort: BILineSort? {
        set(newLineSort){
           lineSort1 = newLineSort
        }
        get {
            return lineSort1
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configurecommutabilitySortCell() {
        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.sort.rawValue)
        let results = (try? self.context!.fetch(fetchRequest)) ?? []
        if results.count > 0 {
            ObjcommutabilitySort = results[0]
            let thirdvalue = ObjcommutabilitySort.thirdCellValue!.intValue - 1
            self.CommutabilitySegmentControl.selectedSegmentIndex = thirdvalue
            let CommutabilityCity = ObjcommutabilitySort.city!
            self.lblTitleCommutability.titleLabel?.text = String(format: "Commut%% (%@)", CommutabilityCity)
            self.lblTitleCommutability.setTitle(String(format: "Commut%% (%@)", CommutabilityCity), for: .normal)
        }
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let sortRules = (CBGlobalMethods.shared.selectedBidPeriod!.lineSorts!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 9")) as! [BILineSort]
        for sort in sortRules {
            CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.delete(sort)
        }
        
        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.sort.rawValue)
        let results = (try? self.context!.fetch(fetchRequest))
        for result in results ?? [] {
            self.context!.delete(result)
        }
        fetchRequest.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.filter.rawValue)
        
        let filterFetchResults = (try? self.context!.fetch(fetchRequest)) ?? []
        if filterFetchResults.count == 0 {
            for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
                line.totalCommutes = 0
                line.commutableBacks = 0
                line.commutableFronts = 0
                line.commutabilityFront = 0
                line.commutabilityBack = 0
                line.commutabilityOverall = 0
                
                for case let trip as BITrip in line.orderedTrips{
                    trip.info?.isFullyCommutable = false
                    trip.highlightCount = 0
                }
            }
            let fetchCommuteTime: NSFetchRequest<CommuteTime> = CommuteTime.fetchRequest()
            let commuteTimes: [CommuteTime] = (try? self.context!.fetch(fetchCommuteTime)) ?? []
            for commuteTime in commuteTimes {
                self.context!.delete(commuteTime)
            }
        }
        try? self.context!.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    @IBAction func segmentControlActn(_ sender: UISegmentedControl) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let selected = NSNumber(integerLiteral: self.CommutabilitySegmentControl.selectedSegmentIndex)
        ObjcommutabilitySort.thirdCellValue = NSNumber(integerLiteral: selected.intValue + 1)
        do {
            switch selected.intValue {
            case 0:
                self.lineSort!.keyPath = "commutabilityFront"
                break
            case 1:
                self.lineSort!.keyPath = "commutabilityBack"
                break
            case 2:
                self.lineSort!.keyPath = "commutabilityOverall"
                break
            default:
                break
            }
            try CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
        } catch {
            print(error)
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshLines"), object: self)
    }
    
    @IBAction func commutabilityTitleAction(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ShowCommutabilitySortView"), object: self)
    }
}
