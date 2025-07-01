//
//  CBWorkBlockRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBWorkBlockRuleCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueButton: UIButton!
    @IBOutlet weak var comparisonButton: UIButton!
    @IBOutlet weak var ruleTypeButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    var filterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod?
    var bacViewColor: UIColor = .white
    var modeTexttColor: UIColor = .gray
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func deleteCellAction(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        //        if (filterRule?.ruleHighlightsTrips())! {
        //            filterRule?.deHighlightTrips()
        //        }
        self.bidPeriod!.managedObjectContext!.delete(filterRule!)
        do {
            try context?.save()
        }
        catch {
            print("Error deleting object \(error.localizedDescription)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
}
